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

extern "C" {

// Returns the total UTC offset (raw + DST) in milliseconds for zone_id at utc_millis.
int32_t tz_get_offset(const char* zone_id, int64_t utc_millis) {
    pthread_mutex_lock(&tz_mutex);

    const char* old_tz = getenv("TZ");
    bool had_tz = (old_tz != nullptr);
    char* saved = had_tz ? strdup(old_tz) : nullptr;

    setenv("TZ", zone_id, 1);
    tzset();

    time_t t = static_cast<time_t>(utc_millis / 1000);
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

} // extern "C"
