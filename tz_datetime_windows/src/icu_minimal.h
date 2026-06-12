#pragma once
#include <stdint.h>

typedef uint16_t UChar;
typedef double UDate;
typedef int32_t UErrorCode;
typedef struct UCalendar UCalendar;
typedef struct UEnumeration UEnumeration;

UCalendar* ucal_open(const UChar* zoneID, int32_t len, const char* locale, int32_t type, UErrorCode* status);
void ucal_close(UCalendar* cal);
void ucal_setMillis(UCalendar* cal, UDate date, UErrorCode* status);
int32_t ucal_get(const UCalendar* cal, int32_t field, UErrorCode* status);
UEnumeration* ucal_openTimeZones(UErrorCode* ec);
int32_t uenum_count(UEnumeration* en, UErrorCode* status);
const UChar* uenum_unext(UEnumeration* en, int32_t* resultLength, UErrorCode* status);
void uenum_close(UEnumeration* en);
