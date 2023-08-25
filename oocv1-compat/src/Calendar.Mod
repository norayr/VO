(*	$Id: Calendar.Mod,v 1.1 2003/05/03 08:20:52 tteuling Exp $	*)
MODULE Calendar;

(*
    Calendar - routines to manipulate dates/times.       
    Copyright (C) 1996, 1997 Michael Griebling
 
    This module is free software; you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 2 of the
    License, or (at your option) any later version.
 
    This module is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.
 
    You should have received a copy of the GNU Lesser General Public
    License along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*)

IMPORT CI:=CharClass, T:=Time, SC:=SysClock, JD:=JulianDay, S:=Strings, 
       IntStr, L:=Locales, Out;

CONST 
  (* days of the week *)
  sunday* = 0; monday* = 1; tuesday* = 2; wednesday* = 3;
  thursday* = 4; friday* = 5; saturday* = 6;
  
  (* months of the year *)
  january* = 1; february* = 2; march* = 3; april* = 4;
  may* = 5; june* = 6; july* = 7; august* = 8;
  september* = 9; october* = 10; november* = 11; december* = 12;

  (* when debugging this module *)
  DEBUG = FALSE;

(* ------------------------------------------------------------- *)
(* Internal conversion functions *)

PROCEDURE IsValidTime (h, m, s: SHORTINT; f: INTEGER) : BOOLEAN;
BEGIN
  RETURN (h>=0) & (h<24) &
         (m>=0) & (m<60) &
         (s>=0) & (s<60) &
         (f>=0) & (f<=SC.maxSecondParts)
END IsValidTime;

PROCEDURE TimeToMSec (h, m, s: SHORTINT; f: INTEGER) : LONGINT;
(* Converts the time to the number of milliseconds since 00:00 
   local time or 0 on invalid input times. *)
BEGIN
  IF IsValidTime(h, m, s, f) THEN 
    RETURN ((h*60+m)*60+s)*1000+f
  ELSE
    RETURN 0
  END
END TimeToMSec;

PROCEDURE MSecToTime (ms: LONGINT; VAR h, m, s: SHORTINT; VAR f: INTEGER);
(* Converts the milliseconds since 00:00 to a local time.
   Pre: 0<=m<8.64E7; 
   Post: h, m, s are set to the 24-hour time; f is milliseconds < 1000
*)
BEGIN
  IF (ms>=0) & (ms<T.msecPerDay) THEN 
    f:=SHORT(ms MOD 1000); ms:=ms DIV 1000; 
    s:=SHORT(SHORT(ms MOD 60)); ms:=ms DIV 60;
    m:=SHORT(SHORT(ms MOD 60));
    h:=SHORT(SHORT(ms DIV 60))
  ELSE
    f:=0; h:=0; m:=0; s:=0
  END
END MSecToTime;


(* ------------------------------------------------------------- *)
(* Various initialization functions *)

PROCEDURE SetLocalTime* (VAR c: SC.DateTime; d, m: SHORTINT; y: INTEGER; 
		         h, min, s: SHORTINT);
(* Initialize the calendar `c' with the local date from `d' days, `m' months,
   `y' years; and the local time from `h' hours, `min' minutes, and
   `s' seconds.  Where:

       y > 0; 1<=m<=12; 1<=d<=31; 0<=h<24; 0<=min<60; 0<=s<60 
		
   The `c.zone' will be set to the number of minutes needed to add
   to local time to obtain UTC.  The `c.summerTimeFlag' will be set
   to 1 when daylight savings time is in effect and 0 otherwise. *)
BEGIN
  (* initialize the calendar *)
  c.day:=d; c.month:=m; c.year:=y;
  c.fractions:=0; c.second:=s; c.minute:=min; c.hour:=h;
  
  (* obtain the time zone and dst mode *)
  SC.MakeLocalTime(c)  
END SetLocalTime;

PROCEDURE SetUTC* (VAR c: SC.DateTime; d, m: SHORTINT; y: INTEGER; 
		   h, min, s: SHORTINT);
(* Initialize the calendar `c' with the UTC date from `d' days, `m' months,
   `y' years; and the UTC time from `h' hours, `min' minutes, and
   `s' seconds.  Where:

       y > 0; 1<=m<=12; 1<=d<=31; 0<=h<24; 0<=min<60; 0<=s<60 
		
   Both `c.zone' and the `c.summerTimeFlag' will be set to 0. *)
BEGIN
  (* initialize the calendar *)
  c.day:=d; c.month:=m; c.year:=y;
  c.fractions:=0; c.second:=s; c.minute:=min; c.hour:=h;
  c.zone:=0; c.summerTimeFlag:=0 
END SetUTC;

(* ------------------------------------------------------------- *)
(* SC.DateTime/TimeStamp conversion functions *)

PROCEDURE GetTimeStamp* (VAR c: SC.DateTime; s: T.TimeStamp);
(* Initialize the calendar from the time stamp `s'.  The `c.zone' 
   will be set to the number of minutes needed to add to local 
   time to obtain UTC.  The `c.summerTimeFlag' will be set to 1 
   when daylight savings time is in effect and 0 otherwise. *)
  VAR
    prev: INTEGER;
    
  PROCEDURE ConvertToDateTime (VAR c: SC.DateTime; s: T.TimeStamp);
  (* pre: `c.zone' holds the desired time zone.  *)
  VAR
    ms, days: LONGINT;
  BEGIN  
    (* adjust for the time zone *)  
    IF c.zone<=SC.unknownZone THEN ms:=s.msecs 
    ELSE ms:=s.msecs-c.zone*T.msecPerMin
    END;

    (* check for overflows *)
    days:=s.days;
    IF ms>=T.msecPerDay THEN INC(days); DEC(ms, T.msecPerDay)
    ELSIF ms<0 THEN DEC(days); INC(ms, T.msecPerDay) 
    END;

    (* convert to a local date/time *)   
    MSecToTime(ms, c.hour, c.minute, c.second, c.fractions);
    JD.DaysToDate(days, c.day, c.month, c.year)
  END ConvertToDateTime;

BEGIN
  (* get first estimate of the time zone of `s' *)
  SC.GetClock(c); 
  prev:=c.zone;   (* save this for later comparison *)
  
  (* convert, assuming the time zone `c.zone' is correct *)
  ConvertToDateTime(c, s);
  
  (* now check which time zone is active for date/time we have just calculated;
     we are done if our first estimate was correct; otherwise we have to adjust
     the time zone and convert again; since there are just two possible zones
     over the year and `prev' obviously was the wrong choice, `c.zone' is the 
     correct value *)
  SC.MakeLocalTime(c);
  IF (c.zone # prev) THEN
    ConvertToDateTime(c, s)
  END
END GetTimeStamp;

PROCEDURE SetTimeStamp* (c: SC.DateTime; VAR t: T.TimeStamp);
(* Converts the calendar date in `c' to a TimeStamp in `t'. *)
VAR
  days, ms: LONGINT;
BEGIN
  (* adjust for the time zone *)  
  days:=JD.DateToDays(c.day, c.month, c.year);    
  IF c.zone<=SC.unknownZone THEN 
    ms:=TimeToMSec(c.hour, c.minute, c.second, c.fractions)
  ELSE 
    ms:=TimeToMSec(c.hour, c.minute, c.second, c.fractions)+c.zone*T.msecPerMin
  END;

  (* check for overflows *)
  IF ms<0 THEN DEC(days); INC(ms, T.msecPerDay) 
  ELSIF ms>=T.msecPerDay THEN INC(days); DEC(ms, T.msecPerDay)
  END;

  (* initialize the TimeStamp *)
  T.InitTimeStamp(t, days, ms)
END SetTimeStamp;


(* ------------------------------------------------------------- *)
(* Date selector functions *)

PROCEDURE DayOfWeek* (c: SC.DateTime): SHORTINT;
(* Returns the day of week of `c' where
       0 - Sunday
       1 - Monday
       .
       .
       .
       6 - Saturday 
 *)
VAR
  t: T.TimeStamp;
BEGIN
  c.zone:=SC.localTime;  (* need to have day of week locally *)
  SetTimeStamp(c,t);     (* convert to UTC days since startMJD is also UTC *)
  RETURN SHORT(SHORT(ENTIER(t.days+JD.startMJD+1.5) MOD 7))
END DayOfWeek;

PROCEDURE IsLeapYear* (c: SC.DateTime): BOOLEAN;
VAR
  d, m: SHORTINT; y: INTEGER;
BEGIN
  JD.DaysToDate(JD.DateToDays(28, 2, c.year)+1, d, m, y);
  RETURN (m = february)
END IsLeapYear;

PROCEDURE DaysPerMonth* (c: SC.DateTime): SHORTINT;
BEGIN
  CASE c.month OF
  |  1, 3, 5, 7, 8, 10, 12: RETURN 31
  |  2: IF IsLeapYear (c) THEN RETURN 29 ELSE RETURN 28 END
  |  ELSE RETURN 30
  END
END DaysPerMonth;

PROCEDURE Inc (VAR d: SC.DateTime; days: LONGINT);
BEGIN
  WHILE days>0 DO    
    IF d.day+1>DaysPerMonth(d) THEN d.day:=1;
      IF d.month+1>december THEN d.month:=january; INC(d.year)
      ELSE INC(d.month)
      END
    ELSE INC(d.day)
    END;
    DEC(days)
  END
END Inc;

PROCEDURE Dec (VAR d: SC.DateTime; days: LONGINT);
BEGIN
  WHILE days>0 DO    
    IF d.day-1=0 THEN
      IF d.month-1<january THEN d.month:=december; DEC(d.year)
      ELSE DEC(d.month)
      END;
      d.day:=DaysPerMonth(d)
    ELSE DEC(d.day)
    END;
    DEC(days)
  END
END Dec;

PROCEDURE WeekNumber* (c: SC.DateTime; startday: SHORTINT) : INTEGER;
(* Return the week number this week belongs to starting the count at `startday'
   which takes values of 0-Sunday, 1-Monday, etc.  The first week of a month
   is recognized as having 4 or more days where each week begins on `startday'. *)
VAR
  first, last, t: T.TimeStamp;
  
  PROCEDURE FindDate (VAR c: SC.DateTime; week, DOW: SHORTINT; start: SC.DateTime);
  (* Sets `c' to the first date which is a certain `DOW' where 0-Sunday, etc
     and falling in the nth week where n is given by `week' and starting with the
     `start' date.  When `week' is negative, the `DOW' falling in the nth
     last week beginning at the date in `start' will be returned.
     Valid ranges of inputs are: week#0, 0<=DOW<7.     
     For example: to find the 3rd Sunday in December 1996, week=3, DOW=0, 
     start=1 Dec 1996. The returned date `c' will be 15 Dec 1996.  Also
     to find the 2nd last Monday in December 1996, the arguments become
     week=-2, DOW=1, start=31 Dec 1996.  The returned `c' will be 23 Dec 1996. *)
  BEGIN
    IF week<0 THEN
      LOOP 
        IF DayOfWeek(c)=DOW THEN Dec(c, (week-1)*7); EXIT END;
        Dec(c, 1)
      END    
    ELSE
      LOOP 
        IF DayOfWeek(c)=DOW THEN Inc(c, (week-1)*7); EXIT END;
        Inc(c, 1)
      END
    END
  END FindDate;

  PROCEDURE StartDate (year: INTEGER; VAR d: T.TimeStamp);
  VAR
    lc: SC.DateTime;
  BEGIN
    SetLocalTime(lc, 1, january, year, 0, 0, 0);
    FindDate(lc, 1, startday, lc);
    IF lc.day>4 THEN Dec(lc, 7) END;  (* start in prev. week *)
    SetTimeStamp(lc, d)
  END StartDate;
  
BEGIN  
  (* first determine the date corresponding to `startday' *)
  StartDate(c.year, first);
  
  (* also find the start date for the next year *)
  StartDate(c.year+1, last);
  
  (* how many weeks between `Date' and `first' *) 
  SetTimeStamp(c, t);
  IF t.days<first.days THEN
    (* count the weeks from previous year's start *)
    StartDate(c.year-1, first);
    RETURN SHORT((t.days-first.days) DIV 7)+1
  ELSIF t.days>=last.days THEN 
    (* Date is in the start of the following year *)
    RETURN 1
  ELSE
    (* Date is in this year *)
    RETURN SHORT((t.days-first.days) DIV 7)+1   
  END
END WeekNumber;

PROCEDURE DayOfYear* (c: SC.DateTime): INTEGER;
(* Return day of year where Jan 1st would be 1 *)
VAR ndate: SC.DateTime; fs, cs: T.TimeStamp;
BEGIN
  ndate:=c; ndate.day:=1; ndate.month:=january;
  SetTimeStamp(ndate,fs); SetTimeStamp(c,cs);
  RETURN SHORT(cs.days - fs.days + 1);
END DayOfYear;


PROCEDURE DayOfWeekStr (c: SC.DateTime; len: INTEGER; VAR str: ARRAY OF CHAR);
(* Returns a localized day of week string for the date in `c' with a length
   of `len' characters. *)
VAR
  day: ARRAY 32 OF CHAR; flag: BOOLEAN;
BEGIN
  flag:=L.GetStr(L.daysOfWeek+DayOfWeek(c), day);
  ASSERT(flag); (* localized day of week *)
  IF len=0 THEN COPY(day, str)
  ELSE S.Extract(day, 0, len, str)
  END
END DayOfWeekStr;

PROCEDURE MonthStr (c: SC.DateTime; short: BOOLEAN; VAR str: ARRAY OF CHAR);
(* Returns a localized month string for the date in `c' using three
   characters when `short' is TRUE and the full month otherwise. *)
VAR
  Month: ARRAY 32 OF CHAR; flag: BOOLEAN;
BEGIN
  flag:=L.GetStr(L.months+c.month-1, Month);
  ASSERT(flag);
  IF short THEN S.Extract(Month, 0, 3, str)
  ELSE COPY(Month, str)
  END
END MonthStr;

(* ------------------------------------------------------------- *)
(* local string conversion assistance functions *)

PROCEDURE ExtractNumber (VAR str: ARRAY OF CHAR; VAR num: INTEGER; digits: INTEGER);
BEGIN
  num:=0;
  WHILE CI.IsNumeric(str[0]) & (digits>0) DO 
    num:=10*num+ORD(str[0])-ORD('0'); S.Delete(str, 0, 1); DEC(digits) 
  END  
END ExtractNumber;

PROCEDURE ExtractString (VAR str: ARRAY OF CHAR; len: SHORTINT; comp: ARRAY OF ARRAY OF CHAR; VAR m: SHORTINT);
VAR ccnt, wcnt, max: SHORTINT;
BEGIN
  wcnt:=0;
  LOOP
    ccnt:=0; IF len>0 THEN max:=len ELSE max:=SHORT(SHORT(LEN(comp,1)))-1 END;
    comp[wcnt][max]:=0X;  (* terminate string so we match shorter strings *)
    LOOP
      IF (str[ccnt]=0X) OR (CAP(str[ccnt])#CAP(comp[wcnt][ccnt])) THEN EXIT (* inner loop *) END;
      INC(ccnt);
      IF ccnt>max THEN EXIT (* inner loop *) END;
      IF comp[wcnt][ccnt]=0X THEN S.Delete(str, 0, ccnt); m:=wcnt+1; RETURN END (* exit both loops *)
    END;
    INC(wcnt);
    IF wcnt>=LEN(comp) THEN EXIT (* outer loop *) END
  END;
  m:=0  (* not found *)
END ExtractString;

PROCEDURE ExtractAMPM (VAR str: ARRAY OF CHAR; VAR hour: SHORTINT);
BEGIN
  IF (CAP(str[0])='A') & (CAP(str[1])='M') THEN S.Delete(str, 0, 2)
  ELSIF (CAP(str[0])='P') & (CAP(str[1])='M') THEN 
    S.Delete(str, 0, 2); INC(hour, 12);
    IF hour=24 THEN hour:=0 END
  END
END ExtractAMPM;

PROCEDURE ExtractZone (VAR str: ARRAY OF CHAR; VAR zone: INTEGER);
VAR
  TZAbbr: ARRAY 8 OF CHAR; ccnt: INTEGER; neg: BOOLEAN;
BEGIN
  TZAbbr:="UTC"; ccnt:=0;
  WHILE (TZAbbr[ccnt]#0X) & (TZAbbr[ccnt]=CAP(str[ccnt])) DO INC(ccnt) END; 
  IF TZAbbr[ccnt]=0X THEN (* found time zone *)
    S.Delete(str, 0, ccnt); 
    neg:=str[0]="+"; S.Delete(str, 0, 1);
    ExtractNumber(str, zone, 2); zone:=zone*60;
    ExtractNumber(str, ccnt, 2); INC(zone, ccnt);
    IF neg THEN zone:=-zone END
  ELSE zone:=SC.unknownZone
  END
END ExtractZone;


(* ------------------------------------------------------------- *)
(* String conversion functions *)

PROCEDURE TimeToStr* (VAR c: SC.DateTime; pattern: ARRAY OF CHAR; 
                      VAR dateStr: ARRAY OF CHAR);
(* 
     This function is similar to the `sprintf' function but the 
     conversion specifications that can appear in the format template 
     `pattern' are specialized for printing components of the date and 
     time `c' according to the locale currently specified for time 
     conversion.

     Ordinary characters appearing in the `pattern' are copied to the
     output string `dateStr'; this can include multibyte character
     sequences.  Conversion specifiers are introduced by a `%'
     character, and are replaced in the output string as follows:

    `%a'  The abbreviated weekday name according to the current locale.
    `%A'  The full weekday name according to the current locale.
    `%b'  The abbreviated month name according to the current locale.
    `%B'  The full month name according to the current locale.
    `%c'  The preferred date and time representation for the current
          locale.
    `%d'  The day of the month as a decimal number (range `01' to `31').
    `%D'  The day of the month as above but no leading zero.
    `%H'  The hour as a decimal number, using a 24-hour clock (range
          `00' to `23').
    `%I'  The hour as a decimal number, using a 12-hour clock (range
          `01' to `12').
     %i'  The hour as a decimal number, using a 12-hour clock with
          no leading zero.
    `%j'  The day of the year as a decimal number (range `001' to
          `366').
    `%m'  The month as a decimal number (range `01' to `12').
    `%M'  The minute as a decimal number.
    `%p'  Either `am' or `pm', according to the given time value; or the
          corresponding strings for the current locale.
    `%S'  The second as a decimal number.
    `%U'  The week number of the current year as a decimal number,
          starting with the first Sunday as the first day of the first
          week.
    `%W'  The week number of the current year as a decimal number,
          starting with the first Monday as the first day of the first
          week.
    `%w'  The day of the week as a decimal number, Sunday being `0'.
    `%x'  The preferred date representation for the current locale, but
          without the time.
    `%X'  The preferred time representation for the current locale, but
          with no date.
    `%y'  The year as a decimal number, but without a century (range
          `00' to `99').
    `%Y'  The year as a decimal number, including the century.
    `%Z'  The time zone or name or abbreviation (empty if the time zone
          can't be determined).
    `%%'  A literal `%' character.

   Therefore the pattern "%A, %D %b %Y" produces "Sunday, 12 Oct 1993" *)
CONST
  Lead0=2; 
VAR
  def, temp: ARRAY 256 OF CHAR;
  ccnt, rcnt: INTEGER;
  flag: BOOLEAN;
  
  PROCEDURE AppendStr (str: ARRAY OF CHAR);
  VAR c: INTEGER;
  BEGIN
    c:=0; 
    WHILE str[c]#0X DO dateStr[rcnt]:=str[c]; INC(rcnt); INC(c) END
  END AppendStr;
  
  PROCEDURE AppendInt (int, zero: INTEGER);
  VAR
    Temp : ARRAY 10 OF CHAR;
  BEGIN
    IntStr.IntToStr(int, Temp);
    WHILE S.Length(Temp) < zero DO S.Insert("0", 0, Temp) END; 
    AppendStr(Temp)
  END AppendInt;
  
  PROCEDURE TwelveHour (hour: INTEGER) : INTEGER;
  BEGIN
    IF hour>12 THEN RETURN hour-12
    ELSIF hour=0 THEN RETURN 12
    ELSE RETURN hour
    END  
  END TwelveHour;

  PROCEDURE PutZone (zone: INTEGER);
  BEGIN
    IF zone<=SC.unknownZone THEN RETURN END;
    IF zone<0 THEN
      AppendStr("UTC+"); zone:=ABS(zone)
    ELSE AppendStr("UTC-")
    END;
    AppendInt(zone DIV 60, Lead0);
    AppendInt(zone MOD 60, Lead0)
  END PutZone;
  
BEGIN
  ccnt:=0; rcnt:=0;
  WHILE pattern[ccnt]#0X DO
    IF (pattern[ccnt]='%') & (pattern[ccnt+1]#0X) THEN
      CASE pattern[ccnt+1] OF
      | 'c': flag:=L.GetStr(L.defBothFormat, temp);
             ASSERT(flag);
             TimeToStr(c, temp, def); AppendStr(def)
      | 'x': flag:=L.GetStr(L.defDateFormat, temp);
             ASSERT(flag);
             TimeToStr(c, temp, def); AppendStr(def)
      | 'X': flag:=L.GetStr(L.defTimeFormat, temp);
             ASSERT(flag);
             TimeToStr(c, temp, def); AppendStr(def)
      | '%': AppendStr("%")
      | 'D': AppendInt(c.day, 0)
      | 'd': AppendInt(c.day, Lead0)
      | 'j': AppendInt(DayOfYear(c), Lead0+1)
      | 'B': MonthStr(c, FALSE, def); AppendStr(def)
      | 'b': MonthStr(c, TRUE, def); AppendStr(def)
      | 'm': AppendInt(c.month, Lead0)
      | 'U': AppendInt(WeekNumber(c, sunday), Lead0)
      | 'W': AppendInt(WeekNumber(c, monday), Lead0)
      | 'y': AppendInt(c.year MOD 100, Lead0)
      | 'Y': AppendInt(c.year, 0)
      | 'A': DayOfWeekStr(c, 0, def); AppendStr(def)
      | 'a': DayOfWeekStr(c, 3, def); AppendStr(def)
      | 'w': AppendInt(DayOfWeek(c), 0)
      | 'Z': PutZone(c.zone)
      | 'H': AppendInt(c.hour, Lead0)
      | 'I': AppendInt(TwelveHour(c.hour), Lead0)
      | 'i': AppendInt(TwelveHour(c.hour), 0)
      | 'p': IF c.hour>=12 THEN AppendStr("PM") ELSE AppendStr("AM") END
      | 'M': AppendInt(c.minute, Lead0)
      | 'S': AppendInt(c.second, Lead0)
      | ELSE dateStr[rcnt]:='%'; dateStr[rcnt+1]:=pattern[ccnt+1]
      END;
      INC(ccnt, 2)
    ELSE
      dateStr[rcnt]:=pattern[ccnt]; INC(rcnt); INC(ccnt)
    END
  END;
  dateStr[rcnt]:=0X
END TimeToStr;

PROCEDURE StrToTime* (VAR c: SC.DateTime; dateStr: ARRAY OF CHAR; 
                      pattern: ARRAY OF CHAR) : BOOLEAN;
(* Converts a day/time string `dateStr' into a date in `c' using
   the template contained in `pattern'.  Pattern definitions are the
   same as in the TimeToStr procedure.  This routine is not
   case-sensitive to months and days of the week.  An unspecified time
   or date is assumed as the zero time/date, respectively; after
   adjustment for the current time zone.  Incomplete times will assume
   the zero time for missing time elements.  Incomplete dates will
   assume the first day (if the day is omitted); the first month (if
   the month is omitted); and the zero year (if the year is omitted).
   Any other information such as the day of the week and the week
   number will be ignored.  The pattern "%A, %D %b %Y" is required to
   parse "Sunday, 12 Oct 1993".
   
   Successful parse of the `dateStr' according to the `pattern' will
   return TRUE. *)

TYPE
  ShortString = ARRAY 32 OF CHAR;
   
VAR
  token: CHAR; lp, temp: ARRAY 80 OF CHAR; 
  inumb, decade: INTEGER; snumb: SHORTINT;
  err: BOOLEAN;
  d, m, s, min, h: SHORTINT;
  y, z: INTEGER;
  Months: ARRAY 12 OF ShortString;
  Days: ARRAY 7 OF ShortString;
  
  PROCEDURE NextToken;
  BEGIN
    IF lp[0]='%' THEN token:=lp[1]; S.Delete(lp, 0, 2)
    ELSIF lp#0X THEN 
      IF lp[0]#dateStr[0] THEN err:=TRUE END; (* mismatch *)
      S.Delete(lp, 0, 1); S.Delete(dateStr, 0, 1); token:=' '
    ELSE token:=0X
    END
  END NextToken;

  PROCEDURE InitMonths;
  VAR i: INTEGER;
  BEGIN
    FOR i:=0 TO 11 DO err:=err OR ~L.GetStr(L.months+i, Months[i]) END
  END InitMonths;

  PROCEDURE InitDays;
  VAR i: INTEGER;
  BEGIN
    FOR i:=0 TO 6 DO err:=err OR ~L.GetStr(L.daysOfWeek+i, Days[i]) END
  END InitDays;  

BEGIN
  (* basic approach is to look for either words or numbers depending
     on the expected parse token and then decode the received word as
     a month or a day of week string and numbers are decoded according
     to their parse token. *)
  Months[0]:=""; Days[0]:="";
  SC.GetClock(c);  (* get current date/time, time zone, daylight savings *)
  decade:=(c.year DIV 100) * 100;      (* set decade *)
  COPY(pattern, lp); err:=FALSE;       (* assume no errors initially *)
  d:=1; m:=january; y:=1970;
  s:=0; min:=0; h:=0; z:=SC.unknownZone;
  REPEAT
    NextToken;
    CASE token OF
    | 'c': err:=err OR ~L.GetStr(L.defBothFormat, temp); S.Insert(temp, 0, lp)
    | 'x': err:=err OR ~L.GetStr(L.defDateFormat, temp); S.Insert(temp, 0, lp)
    | 'X': err:=err OR ~L.GetStr(L.defTimeFormat, temp); S.Insert(temp, 0, lp)
    | 'D','d': ExtractNumber(dateStr, inumb, 2); d:=SHORT(inumb)
    | 'j': ExtractNumber(dateStr, inumb, 3) (* ignore *)
    | 'B': InitMonths; ExtractString(dateStr, 0, Months, m)
    | 'b': InitMonths; ExtractString(dateStr, 3, Months, m)
    | 'm': ExtractNumber(dateStr, inumb, 2); m:=SHORT(inumb)
    | 'U','W': ExtractNumber(dateStr, inumb, 2) (* ignore *)
    | 'y': ExtractNumber(dateStr, y, 2); INC(y, decade)
    | 'Y': ExtractNumber(dateStr, y, 4)
    | 'A': InitDays; ExtractString(dateStr, 0, Days, snumb) (* ignore *)
    | 'a': InitDays; ExtractString(dateStr, 3, Days, snumb) (* ignore *)
    | '%': S.Delete(dateStr, 0, 1)
    | 'Z': ExtractZone(dateStr, z)
    | 'H': ExtractNumber(dateStr, inumb, 2); h:=SHORT(inumb)
    | 'I','i': ExtractNumber(dateStr, inumb, 2); h:=SHORT(inumb)
    | 'p': ExtractAMPM(dateStr, h)
    | 'M': ExtractNumber(dateStr, inumb, 2); min:=SHORT(inumb)
    | 'S': ExtractNumber(dateStr, inumb, 2); s:=SHORT(inumb)
    | ELSE IF (token#0X)&(token#' ') THEN err:=TRUE END  (* unrecognized token *)
    END;
  UNTIL token=0X;
  
  (* attempt to fix up the date *)
  IF y<=0 THEN y:=1; err:=TRUE END;
  IF (m<january) OR (m>december) THEN m:=january; err:=TRUE END;
  IF (d<1) OR (d>31) THEN d:=1; err:=TRUE END;
  IF (h<0) OR (h>23) THEN h:=0; err:=TRUE END;
  IF (min<0) OR (min>59) THEN min:=0; err:=TRUE END;
  IF (s<0) OR (s>59) THEN s:=0; err:=TRUE END;

  (* finally set the date *)
  SetLocalTime(c, d, m, y, h, min, s);
  IF z#SC.unknownZone THEN c.zone:=z END;
  RETURN ~err
END StrToTime;

PROCEDURE Test;
VAR s: ARRAY 80 OF CHAR; d: SC.DateTime; i: INTEGER;
BEGIN
  L.Set(L.ALL, "", s);
  IF L.GetStr(L.defDateFormat, s) THEN
    Out.String("Default date format = "); Out.String(s); Out.Ln
  END;
  IF L.GetStr(L.defTimeFormat, s) THEN
    Out.String("Default time format = "); Out.String(s); Out.Ln
  END;
  IF L.GetStr(L.defBothFormat, s) THEN
    Out.String("Default both format = "); Out.String(s); Out.Ln
  END;
  SC.GetClock(d);
  Out.String("Current DST is "); Out.Int(d.summerTimeFlag, 0); Out.Ln;
  Out.String("Current zone offset "); Out.Int(d.zone, 0); Out.Ln;
  TimeToStr(d, "%A, %D %b, %Y", s); Out.String("Pattern: `%A, %D %b, %Y' = "); Out.String(s); Out.Ln;
  TimeToStr(d, "Today is %c", s); Out.String("Pattern: `%c' = "); Out.String(s); Out.Ln; 
  IF ~StrToTime(d, s, "Today is %c") THEN Out.String("Error detected..."); Out.Ln END;
  TimeToStr(d, "Workweek = %W", s); Out.String(s); Out.Ln;
  TimeToStr(d, "12-hour time = %i:%M:%S%p", s); Out.String(s); Out.Ln;
  TimeToStr(d, "van Acken (weird pattern): %%c", s); Out.String(s); Out.Ln;  
  IF ~StrToTime(d, s, "Full date: %A, %B %D, %Y, %j days from year start") THEN
    Out.String("Intentional error detected..."); Out.Ln
  END;
  SC.GetClock(d);
  TimeToStr(d, "Full date: %A, %B %D, %Y, %j days from year start", s); Out.String(s); Out.Ln;
  IF ~StrToTime(d, s, "Full date: %A, %B %D, %Y, %j days from year start") THEN
    Out.String("Error detected..."); Out.Ln
  END;
  
  Out.String("Checking DST functions..."); Out.Ln;
  d.month:=12; SC.MakeLocalTime(d);
  Out.String("December DST is "); Out.Int(d.summerTimeFlag, 0); Out.Ln;
  Out.String("December zone offset "); Out.Int(d.zone, 0); Out.Ln;  
  
  d.month:=7; SC.MakeLocalTime(d);
  Out.String("August DST is "); Out.Int(d.summerTimeFlag, 0); Out.Ln;
  Out.String("August zone offset "); Out.Int(d.zone, 0); Out.Ln;
    
  FOR i:=1900 TO 2100 DO   
    d.year:=i; SC.MakeLocalTime(d);
    Out.Int(i, 0); Out.String(" DST is "); Out.Int(d.summerTimeFlag, 0);
    Out.String("; zone offset "); Out.Int(d.zone, 0); Out.Ln; 
  END;
  
  d.year:=2100; SC.MakeLocalTime(d);
  Out.String("2100 DST is "); Out.Int(d.summerTimeFlag, 0); Out.Ln;
  Out.String("2100 zone offset "); Out.Int(d.zone, 0); Out.Ln;    
END Test;

BEGIN 
  IF DEBUG THEN Test END
END Calendar.
