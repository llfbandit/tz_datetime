#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <time.h>
#include <pthread.h>

// Timezone list is parsed from Android's packed tzdata binary.
// UTC offset is computed via POSIX localtime_r() with a mutex-guarded setenv("TZ").
// No ICU dependency: ucal_* is not exposed through the NDK.

static pthread_mutex_t tz_mutex = PTHREAD_MUTEX_INITIALIZER;

static const char* const kTzdataPaths[] = {
    "/apex/com.android.tzdata/etc/tz/tzdata",  // API 29+ (mainline)
    "/system/usr/share/zoneinfo/tzdata",       // API 21-28 fallback
    nullptr,
};

static uint32_t read_be32(FILE* f) {
    uint8_t b[4];
    if (fread(b, 1, 4, f) != 4) return 0;
    return ((uint32_t)b[0] << 24) | ((uint32_t)b[1] << 16) |
           ((uint32_t)b[2] << 8)  |  (uint32_t)b[3];
}

static FILE* open_tzdata() {
    for (int i = 0; kTzdataPaths[i]; ++i) {
        FILE* f = fopen(kTzdataPaths[i], "rb");
        if (f) return f;
    }
    return nullptr;
}

static inline time_t ms_to_sec(int64_t ms) {
    return static_cast<time_t>(ms >= 0 ? ms / 1000 : (ms - 999) / 1000);
}

// Returns tm_gmtoff in milliseconds for the given UTC time.
// Precondition: TZ is already set and tzset() called; tz_mutex must be held.
static int32_t gmtoff_ms_unsafe(int64_t utc_ms) {
    time_t t = ms_to_sec(utc_ms);
    struct tm tm_info = {};
    localtime_r(&t, &tm_info);
    return static_cast<int32_t>(tm_info.tm_gmtoff * 1000);
}

extern "C" {

// Returns the total UTC offset (raw + DST) in milliseconds for zone_id at utc_millis.
int32_t tz_get_offset(const char* zone_id, int64_t utc_millis) {
    pthread_mutex_lock(&tz_mutex);

    const char* old_tz = getenv("TZ");
    bool had_tz = (old_tz != nullptr);
    char* saved = had_tz ? strdup(old_tz) : nullptr;

    setenv("TZ", zone_id, 1);
    tzset();

    time_t t = ms_to_sec(utc_millis);
    struct tm tm_info = {};
    localtime_r(&t, &tm_info);
    const int32_t offset_ms = static_cast<int32_t>(tm_info.tm_gmtoff * 1000);

    if (had_tz) {
        setenv("TZ", saved, 1);
        free(saved);
    } else {
        unsetenv("TZ");
    }
    tzset();

    pthread_mutex_unlock(&tz_mutex);
    return offset_ms;
}

// Returns all available timezone IDs as a newline-delimited UTF-8 string.
// Sets *out_length to the byte length (excluding null terminator).
// Caller must free the returned pointer with tz_free_buffer.
//
// tzdata index entry layout (52 bytes each):
//   char  name[40]  — timezone ID, null-padded
//   int32 offset    — big-endian, byte offset into data section
//   int32 length    — big-endian, byte length of TZif data
//   int32 rawOffset — big-endian, raw UTC offset in seconds (unused here)
char* tz_get_timezones(int32_t* out_length) {
    *out_length = 0;

    FILE* f = open_tzdata();
    if (!f) return nullptr;

    // Header: "tzdata" (6) + version (6) = 12 bytes, then three big-endian int32s.
    char header[12];
    if (fread(header, 1, 12, f) != 12 || strncmp(header, "tzdata", 6) != 0) {
        fclose(f);
        return nullptr;
    }

    const uint32_t index_offset = read_be32(f);
    const uint32_t data_offset  = read_be32(f);

    if (data_offset <= index_offset) { fclose(f); return nullptr; }

    const int count = static_cast<int>((data_offset - index_offset) / 52);
    if (count <= 0) { fclose(f); return nullptr; }

    if (fseek(f, static_cast<long>(index_offset), SEEK_SET) != 0) {
        fclose(f);
        return nullptr;
    }

    // First pass: compute required buffer size.
    int32_t total = 0;
    for (int i = 0; i < count; ++i) {
        char name[41] = {};
        if (fread(name, 1, 40, f) != 40) break;
        fseek(f, 12, SEEK_CUR);
        total += static_cast<int32_t>(strlen(name)) + 1;  // +1 for '\n'
    }

    if (total <= 0) { fclose(f); return nullptr; }

    char* buf = static_cast<char*>(malloc(static_cast<size_t>(total) + 1));
    if (!buf) { fclose(f); return nullptr; }

    // Second pass: fill buffer.
    fseek(f, static_cast<long>(index_offset), SEEK_SET);
    char* ptr = buf;
    for (int i = 0; i < count; ++i) {
        char name[41] = {};
        if (fread(name, 1, 40, f) != 40) break;
        fseek(f, 12, SEEK_CUR);
        const size_t len = strlen(name);
        memcpy(ptr, name, len);
        ptr += len;
        *ptr++ = '\n';
    }
    *ptr = '\0';

    fclose(f);
    *out_length = static_cast<int32_t>(ptr - buf);
    return buf;
}

void tz_free_buffer(void* ptr) {
    free(ptr);
}

// Converts a wall-clock time (expressed as UTC epoch millis, i.e. treating the
// local components as if they were UTC) to the true UTC microseconds since epoch
// for zone_id.  Handles spring-forward gaps via binary search; sub-ms precision
// is preserved through the `us` (microseconds) parameter.
int64_t tz_local_to_utc_micros(const char* zone_id, int64_t local_as_utc_ms, int32_t us) {
    pthread_mutex_lock(&tz_mutex);

    const char* old_tz = getenv("TZ");
    bool had_tz = (old_tz != nullptr);
    char* saved = had_tz ? strdup(old_tz) : nullptr;
    setenv("TZ", zone_id, 1);
    tzset();

    const int32_t local_offset = gmtoff_ms_unsafe(local_as_utc_ms);
    const int64_t adjusted     = local_as_utc_ms - local_offset;
    const int32_t adj_offset   = gmtoff_ms_unsafe(adjusted);
    int64_t result_ms          = local_as_utc_ms - adj_offset;

    if (local_offset != adj_offset) {
        const int32_t result_offset = gmtoff_ms_unsafe(result_ms);
        if (result_offset != adj_offset) {
            // Spring-forward gap: binary-search for the first post-gap instant.
            // post_gap_offset is the larger (new) offset; determine lo/hi sides.
            const int32_t post_gap = local_offset > adj_offset ? local_offset : adj_offset;
            int64_t lo, hi;
            if (adj_offset == post_gap) {
                lo = result_ms; hi = adjusted;
            } else {
                lo = adjusted;  hi = result_ms;
            }
            while (hi - lo > 1000) {
                const int64_t mid = lo + (hi - lo) / 2;
                if (gmtoff_ms_unsafe(mid) == post_gap) {
                    hi = mid;
                } else {
                    lo = mid;
                }
            }
            result_ms = hi;
        }
    }

    if (had_tz) {
        setenv("TZ", saved, 1);
        free(saved);
    } else {
        unsetenv("TZ");
    }
    tzset();

    pthread_mutex_unlock(&tz_mutex);
    return result_ms * 1000LL + static_cast<int64_t>(us);
}

} // extern "C"
