package com.llfbandit.tz_datetime;

import androidx.annotation.Keep;

import java.time.ZoneId;
import java.util.TimeZone;

@Keep
public class TzDatetime {
  private TzDatetime() {}

  public static String[] getAvailableTimezones() {
    return TimeZone.getAvailableIDs();
  }

  public static int getOffset(String zone, long utcDate) {
    TimeZone timeZone = TimeZone.getTimeZone(zone);
    return timeZone.getOffset(utcDate);
  }
}
