#pragma once
#include <stdint.h>

typedef long CFIndex;
typedef unsigned long CFOptionFlags;
typedef unsigned char Boolean;
typedef uint16_t UniChar;
typedef double CFTimeInterval;
typedef CFTimeInterval CFAbsoluteTime;
typedef const void* CFTypeRef;
typedef const struct CFAllocator* CFAllocatorRef;
typedef const struct CFString* CFStringRef;
typedef const struct CFArray* CFArrayRef;
typedef const struct CFTimeZone* CFTimeZoneRef;

typedef struct {
  CFIndex location;
  CFIndex length;
} CFRange;

void* CFAllocatorAllocate(CFAllocatorRef allocator, CFIndex size, CFOptionFlags hint);
void CFAllocatorDeallocate(CFAllocatorRef allocator, void* ptr);
void CFRelease(CFTypeRef cf);
CFIndex CFArrayGetCount(CFArrayRef theArray);
const void* CFArrayGetValueAtIndex(CFArrayRef theArray, CFIndex idx);
CFStringRef CFStringCreateWithCharacters(CFAllocatorRef alloc, const UniChar* chars, CFIndex numChars);
CFIndex CFStringGetLength(CFStringRef theString);
void CFStringGetCharacters(CFStringRef theString, CFRange range, UniChar* buffer);
CFTimeZoneRef CFTimeZoneCreateWithName(CFAllocatorRef allocator, CFStringRef name, Boolean tryAbbrev);
CFArrayRef CFTimeZoneCopyKnownNames(void);
CFTimeInterval CFTimeZoneGetSecondsFromGMT(CFTimeZoneRef tz, CFAbsoluteTime at);
