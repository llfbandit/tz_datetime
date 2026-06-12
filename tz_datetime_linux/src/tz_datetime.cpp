#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <time.h>
#include <pthread.h>

// UTC offset is computed via POSIX localtime_r() with a mutex-guarded setenv("TZ").
// /usr/share/zoneinfo/ is used implicitly by the C library when TZ is set to a zone ID.

static pthread_mutex_t tz_mutex = PTHREAD_MUTEX_INITIALIZER;

// Returns tm_gmtoff in milliseconds for the given UTC time.
// Precondition: TZ is already set and tzset() called; tz_mutex must be held.
static inline time_t ms_to_sec(int64_t ms) {
    return static_cast<time_t>(ms >= 0 ? ms / 1000 : (ms - 999) / 1000);
}

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
