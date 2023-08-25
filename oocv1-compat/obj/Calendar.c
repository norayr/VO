#include <Calendar.d>
#include <__oo2c.h>
#include <setjmp.h>

static OOC_CHAR8 Calendar__IsValidTime(OOC_INT8 h, OOC_INT8 m, OOC_INT8 s, OOC_INT16 f) {
  register OOC_INT64 i0,i1;

  i0 = h;
  i1 = i0>=0;
  if (i1) goto l3;
  i0=0u;
  goto l5;
l3:
  i0 = i0<24;
  
l5:
  if (i0) goto l7;
  i0=0u;
  goto l9;
l7:
  i0 = m;
  i0 = i0>=0;
  
l9:
  if (i0) goto l11;
  i0=0u;
  goto l13;
l11:
  i0 = m;
  i0 = i0<60;
  
l13:
  if (i0) goto l15;
  i0=0u;
  goto l17;
l15:
  i0 = s;
  i0 = i0>=0;
  
l17:
  if (i0) goto l19;
  i0=0u;
  goto l21;
l19:
  i0 = s;
  i0 = i0<60;
  
l21:
  if (i0) goto l23;
  i0=0u;
  goto l25;
l23:
  i0 = f;
  i0 = i0>=0;
  
l25:
  if (i0) goto l27;
  i0=0u;
  goto l28;
l27:
  i0 = f;
  i0 = i0<=999;
  
l28:
  return i0;
  ;
}

static OOC_INT32 Calendar__TimeToMSec(OOC_INT8 h, OOC_INT8 m, OOC_INT8 s, OOC_INT16 f) {
  register OOC_INT64 i0,i1,i2,i3,i4;

  i0 = f;
  i1 = s;
  i2 = m;
  i3 = h;
  i4 = Calendar__IsValidTime(i3, i2, i1, i0);
  if (i4) goto l3;
  return 0;
  goto l4;
l3:
  return ((((((i3*60)+i2)*60)+i1)*1000)+i0);
l4:
  _failed_function(1758); return 0;
  ;
}

static void Calendar__MSecToTime(OOC_INT32 ms, OOC_INT8 *h, OOC_INT8 *m, OOC_INT8 *s, OOC_INT16 *f) {
  register OOC_INT64 i0,i1;

  i0 = ms;
  i1 = i0>=0;
  if (i1) goto l3;
  i1=0u;
  goto l5;
l3:
  i1 = i0<86400000;
  
l5:
  if (i1) goto l7;
  *f = 0;
  *h = 0;
  *m = 0;
  *s = 0;
  goto l8;
l7:
  i1 = _div(i0,1000);
  *f = (_mod(i0,1000));
  i0 = _div(i1,60);
  *s = (_mod(i1,60));
  *m = (_mod(i0,60));
  *h = (_div(i0,60));
l8:
  return;
  ;
}

void Calendar__SetLocalTime(struct SysClock__DateTime *c, RT0__Struct c__tag, OOC_INT8 d, OOC_INT8 m, OOC_INT16 y, OOC_INT8 h, OOC_INT8 min, OOC_INT8 s) {
  register OOC_INT64 i0;

  i0 = d;
  *(OOC_INT8*)((OOC_INT64)c+3) = i0;
  i0 = m;
  *(OOC_INT8*)((OOC_INT64)c+2) = i0;
  i0 = y;
  *(OOC_INT16*)(OOC_INT64)c = i0;
  *(OOC_INT16*)((OOC_INT64)c+8) = 0;
  i0 = s;
  *(OOC_INT8*)((OOC_INT64)c+6) = i0;
  i0 = min;
  *(OOC_INT8*)((OOC_INT64)c+5) = i0;
  i0 = h;
  *(OOC_INT8*)((OOC_INT64)c+4) = i0;
  SysClock__MakeLocalTime((void*)(OOC_INT64)c, (RT0__Struct)((OOC_INT64)c__tag));
  return;
  ;
}

void Calendar__SetUTC(struct SysClock__DateTime *c, RT0__Struct c__tag, OOC_INT8 d, OOC_INT8 m, OOC_INT16 y, OOC_INT8 h, OOC_INT8 min, OOC_INT8 s) {
  register OOC_INT64 i0;

  i0 = d;
  *(OOC_INT8*)((OOC_INT64)c+3) = i0;
  i0 = m;
  *(OOC_INT8*)((OOC_INT64)c+2) = i0;
  i0 = y;
  *(OOC_INT16*)(OOC_INT64)c = i0;
  *(OOC_INT16*)((OOC_INT64)c+8) = 0;
  i0 = s;
  *(OOC_INT8*)((OOC_INT64)c+6) = i0;
  i0 = min;
  *(OOC_INT8*)((OOC_INT64)c+5) = i0;
  i0 = h;
  *(OOC_INT8*)((OOC_INT64)c+4) = i0;
  *(OOC_INT16*)((OOC_INT64)c+10) = 0;
  *(OOC_INT8*)((OOC_INT64)c+7) = 0;
  return;
  ;
}

void Calendar__GetTimeStamp(struct SysClock__DateTime *c, RT0__Struct c__tag, const struct Time__TimeStamp *s__ref) {
  register OOC_INT64 i0,i1,i2;
  OOC_ALLOCATE_VPAR(s,Time__TimeStamp ,1)
  OOC_INT16 prev;
  auto void Calendar__GetTimeStamp_ConvertToDateTime(struct SysClock__DateTime *c, RT0__Struct c__tag, const struct Time__TimeStamp *s__ref);
    
    void Calendar__GetTimeStamp_ConvertToDateTime(struct SysClock__DateTime *c, RT0__Struct c__tag, const struct Time__TimeStamp *s__ref) {
      register OOC_INT64 i0,i1,i2;
      OOC_ALLOCATE_VPAR(s,Time__TimeStamp ,1)

      i0 = *(OOC_INT16*)((OOC_INT64)c+10);
      OOC_INITIALIZE_VPAR(s__ref,s,Time__TimeStamp ,8)
      i1 = i0<=(-32767);
      if (i1) goto l3;
      i1 = *(OOC_INT32*)((OOC_INT64)s+4);
      i0 = i1-(i0*60000);
      
      goto l4;
l3:
      i0 = *(OOC_INT32*)((OOC_INT64)s+4);
      
l4:
      i1 = *(OOC_INT32*)(OOC_INT64)s;
      i2 = i0>=86400000;
      if (i2) goto l11;
      i2 = i0<0;
      if (!i2) goto l12;
      i1 = i1-1;
      i0 = i0+86400000;
      
      goto l12;
l11:
      i1 = i1+1;
      i0 = i0-86400000;
      
l12:
      Calendar__MSecToTime(i0, (void*)((OOC_INT64)c+4), (void*)((OOC_INT64)c+5), (void*)((OOC_INT64)c+6), (void*)((OOC_INT64)c+8));
      JulianDay__DaysToDate(i1, (void*)((OOC_INT64)c+3), (void*)((OOC_INT64)c+2), (void*)(OOC_INT64)c);
      return;
      ;
    }


  OOC_INITIALIZE_VPAR(s__ref,s,Time__TimeStamp ,8)
  i0 = (OOC_INT64)c__tag;
  SysClock__GetClock((void*)(OOC_INT64)c, (RT0__Struct)i0);
  i1 = (OOC_INT64)c+10;
  i2 = *(OOC_INT16*)i1;
  prev = i2;
  Calendar__GetTimeStamp_ConvertToDateTime((void*)(OOC_INT64)c, (RT0__Struct)i0, (void*)(OOC_INT64)s);
  SysClock__MakeLocalTime((void*)(OOC_INT64)c, (RT0__Struct)i0);
  i1 = *(OOC_INT16*)i1;
  i2 = prev;
  i1 = i1!=i2;
  if (!i1) goto l4;
  Calendar__GetTimeStamp_ConvertToDateTime((void*)(OOC_INT64)c, (RT0__Struct)i0, (void*)(OOC_INT64)s);
l4:
  return;
  ;
}

void Calendar__SetTimeStamp(const struct SysClock__DateTime *c__ref, struct Time__TimeStamp *t, RT0__Struct t__tag) {
  register OOC_INT64 i0,i1,i2,i3,i4,i5;
  OOC_ALLOCATE_VPAR(c,SysClock__DateTime ,1)

  OOC_INITIALIZE_VPAR(c__ref,c,SysClock__DateTime ,12)
  i0 = *(OOC_INT8*)((OOC_INT64)c+2);
  i1 = *(OOC_INT8*)((OOC_INT64)c+3);
  i2 = *(OOC_INT16*)(OOC_INT64)c;
  i0 = JulianDay__DateToDays(i1, i0, i2);
  i1 = *(OOC_INT16*)((OOC_INT64)c+10);
  i2 = i1<=(-32767);
  if (i2) goto l3;
  i2 = *(OOC_INT8*)((OOC_INT64)c+4);
  i3 = *(OOC_INT8*)((OOC_INT64)c+5);
  i4 = *(OOC_INT8*)((OOC_INT64)c+6);
  i5 = *(OOC_INT16*)((OOC_INT64)c+8);
  i2 = Calendar__TimeToMSec(i2, i3, i4, i5);
  i1 = i2+(i1*60000);
  
  goto l4;
l3:
  i1 = *(OOC_INT8*)((OOC_INT64)c+4);
  i2 = *(OOC_INT8*)((OOC_INT64)c+5);
  i3 = *(OOC_INT8*)((OOC_INT64)c+6);
  i4 = *(OOC_INT16*)((OOC_INT64)c+8);
  i1 = Calendar__TimeToMSec(i1, i2, i3, i4);
  
l4:
  i2 = i1<0;
  if (i2) goto l11;
  i2 = i1>=86400000;
  if (i2) goto l9;
  {register OOC_INT64 h0=i0;i0=i1;i1=h0;}
  goto l12;
l9:
  i0 = i0+1;
  i1 = i1-86400000;
  {register OOC_INT64 h0=i0;i0=i1;i1=h0;}
  goto l12;
l11:
  i0 = i0-1;
  i1 = i1+86400000;
  {register OOC_INT64 h0=i0;i0=i1;i1=h0;}
l12:
  Time__InitTimeStamp((void*)(OOC_INT64)t, (RT0__Struct)((OOC_INT64)t__tag), i1, i0);
  return;
  ;
}

OOC_INT8 Calendar__DayOfWeek(const struct SysClock__DateTime *c__ref) {
  register OOC_INT64 i0;
  OOC_ALLOCATE_VPAR(c,SysClock__DateTime ,1)
  struct Time__TimeStamp t;

  OOC_INITIALIZE_VPAR(c__ref,c,SysClock__DateTime ,12)
  *(OOC_INT16*)((OOC_INT64)c+10) = (-32768);
  Calendar__SetTimeStamp((void*)(OOC_INT64)c, (void*)(OOC_INT64)&t, (RT0__Struct)((OOC_INT64)&_td_Time__TimeStamp));
  i0 = *(OOC_INT32*)(OOC_INT64)&t;
  return (_mod((_entier(((((OOC_REAL64)i0)+2.4000005000000000E+6)+1.5000000000000000))),7));
  ;
}

OOC_CHAR8 Calendar__IsLeapYear(const struct SysClock__DateTime *c__ref) {
  register OOC_INT64 i0;
  OOC_ALLOCATE_VPAR(c,SysClock__DateTime ,1)
  OOC_INT16 y;
  OOC_INT8 m;
  OOC_INT8 d;

  OOC_INITIALIZE_VPAR(c__ref,c,SysClock__DateTime ,12)
  i0 = *(OOC_INT16*)(OOC_INT64)c;
  i0 = JulianDay__DateToDays(28, 2, i0);
  JulianDay__DaysToDate((i0+1), (void*)(OOC_INT64)&d, (void*)(OOC_INT64)&m, (void*)(OOC_INT64)&y);
  i0 = m;
  return (i0==2);
  ;
}

OOC_INT8 Calendar__DaysPerMonth(const struct SysClock__DateTime *c__ref) {
  register OOC_INT64 i0;
  OOC_ALLOCATE_VPAR(c,SysClock__DateTime ,1)

  OOC_INITIALIZE_VPAR(c__ref,c,SysClock__DateTime ,12)
  i0 = *(OOC_INT8*)((OOC_INT64)c+2);
  switch (i0) {
  case 1:
  case 3:
  case 5:
  case 7:
  case 8:
  case 10:
  case 12:
    return 31;
    goto l9;
  case 2:
    i0 = Calendar__IsLeapYear((void*)(OOC_INT64)c);
    if (i0) goto l6;
    return 28;
    goto l9;
l6:
    return 29;
    goto l9;
  default:
    return 30;
    goto l9;
  }
l9:
  _failed_function(7134); return 0;
  ;
}

static void Calendar__Inc(struct SysClock__DateTime *d, RT0__Struct d__tag, OOC_INT32 days) {
  register OOC_INT64 i0,i1,i2,i3,i4;

  i0 = days;
  i1 = i0>0;
  if (!i1) goto l16;
  i1 = (OOC_INT64)d+2;
  i2 = (OOC_INT64)d+3;
  
l3_loop:
  i3 = *(OOC_INT8*)i2;
  i4 = Calendar__DaysPerMonth((void*)(OOC_INT64)d);
  i3 = (i3+1)>i4;
  if (i3) goto l6;
  i3 = *(OOC_INT8*)i2;
  *(OOC_INT8*)i2 = (i3+1);
  goto l11;
l6:
  *(OOC_INT8*)i2 = 1;
  i3 = *(OOC_INT8*)i1;
  i3 = i3+1;
  i4 = i3>12;
  if (i4) goto l9;
  *(OOC_INT8*)i1 = i3;
  goto l11;
l9:
  *(OOC_INT8*)i1 = 1;
  i3 = *(OOC_INT16*)(OOC_INT64)d;
  *(OOC_INT16*)(OOC_INT64)d = (i3+1);
l11:
  i0 = i0-1;
  i3 = i0>0;
  if (i3) goto l3_loop;
l16:
  return;
  ;
}

static void Calendar__Dec(struct SysClock__DateTime *d, RT0__Struct d__tag, OOC_INT32 days) {
  register OOC_INT64 i0,i1,i2,i3,i4;

  i0 = days;
  i1 = i0>0;
  if (!i1) goto l16;
  i1 = (OOC_INT64)d+2;
  i2 = (OOC_INT64)d+3;
  
l3_loop:
  i3 = *(OOC_INT8*)i2;
  i3 = i3-1;
  i4 = i3==0;
  if (i4) goto l6;
  *(OOC_INT8*)i2 = i3;
  
  goto l11;
l6:
  i3 = *(OOC_INT8*)i1;
  i3 = i3-1;
  i4 = i3<1;
  if (i4) goto l9;
  *(OOC_INT8*)i1 = i3;
  goto l10;
l9:
  *(OOC_INT8*)i1 = 12;
  i3 = *(OOC_INT16*)(OOC_INT64)d;
  *(OOC_INT16*)(OOC_INT64)d = (i3-1);
l10:
  i3 = Calendar__DaysPerMonth((void*)(OOC_INT64)d);
  *(OOC_INT8*)i2 = i3;
  
l11:
  i0 = i0-1;
  i3 = i0>0;
  if (i3) goto l3_loop;
l16:
  return;
  ;
}

OOC_INT16 Calendar__WeekNumber(const struct SysClock__DateTime *c__ref, OOC_INT8 startday) {
  register OOC_INT64 i0,i1,i2,i3;
  OOC_ALLOCATE_VPAR(c,SysClock__DateTime ,1)
  struct Time__TimeStamp first;
  struct Time__TimeStamp last;
  struct Time__TimeStamp t;
  auto void Calendar__WeekNumber_FindDate(struct SysClock__DateTime *c, RT0__Struct c__tag, OOC_INT8 week, OOC_INT8 DOW, const struct SysClock__DateTime *start__ref);
  auto void Calendar__WeekNumber_StartDate(OOC_INT16 year, struct Time__TimeStamp *d, RT0__Struct d__tag);
    
    void Calendar__WeekNumber_FindDate(struct SysClock__DateTime *c, RT0__Struct c__tag, OOC_INT8 week, OOC_INT8 DOW, const struct SysClock__DateTime *start__ref) {
      register OOC_INT64 i0,i1,i2,i3;
      OOC_ALLOCATE_VPAR(start,SysClock__DateTime ,1)

      OOC_INITIALIZE_VPAR(start__ref,start,SysClock__DateTime ,12)
      i0 = week;
      i1 = i0<0;
      if (i1) goto l8;
      i0 = (i0-1)*7;
      i1 = (OOC_INT64)c__tag;
      i2 = DOW;
l3_loop:
      i3 = Calendar__DayOfWeek((void*)(OOC_INT64)c);
      i3 = i3==i2;
      if (i3) goto l6;
      Calendar__Inc((void*)(OOC_INT64)c, (RT0__Struct)i1, 1);
      
      goto l3_loop;
l6:
      Calendar__Inc((void*)(OOC_INT64)c, (RT0__Struct)i1, i0);
      goto l14;
l8:
      i0 = (i0-1)*7;
      i1 = (OOC_INT64)c__tag;
      i2 = DOW;
l9_loop:
      i3 = Calendar__DayOfWeek((void*)(OOC_INT64)c);
      i3 = i3==i2;
      if (i3) goto l12;
      Calendar__Dec((void*)(OOC_INT64)c, (RT0__Struct)i1, 1);
      
      goto l9_loop;
l12:
      Calendar__Dec((void*)(OOC_INT64)c, (RT0__Struct)i1, i0);
l14:
      return;
      ;
    }

    
    void Calendar__WeekNumber_StartDate(OOC_INT16 year, struct Time__TimeStamp *d, RT0__Struct d__tag) {
      register OOC_INT64 i0,i1;
      struct SysClock__DateTime lc;

      i0 = (OOC_INT64)&_td_SysClock__DateTime;
      i1 = year;
      Calendar__SetLocalTime((void*)(OOC_INT64)&lc, (RT0__Struct)i0, 1, 1, i1, 0, 0, 0);
      i1 = startday;
      Calendar__WeekNumber_FindDate((void*)(OOC_INT64)&lc, (RT0__Struct)i0, 1, i1, (void*)(OOC_INT64)&lc);
      i1 = *(OOC_INT8*)((OOC_INT64)&lc+3);
      i1 = i1>4;
      if (!i1) goto l4;
      Calendar__Dec((void*)(OOC_INT64)&lc, (RT0__Struct)i0, 7);
l4:
      Calendar__SetTimeStamp((void*)(OOC_INT64)&lc, (void*)(OOC_INT64)d, (RT0__Struct)((OOC_INT64)d__tag));
      return;
      ;
    }


  OOC_INITIALIZE_VPAR(c__ref,c,SysClock__DateTime ,12)
  i0 = *(OOC_INT16*)(OOC_INT64)c;
  i1 = (OOC_INT64)&_td_Time__TimeStamp;
  Calendar__WeekNumber_StartDate(i0, (void*)(OOC_INT64)&first, (RT0__Struct)i1);
  i0 = *(OOC_INT16*)(OOC_INT64)c;
  Calendar__WeekNumber_StartDate((i0+1), (void*)(OOC_INT64)&last, (RT0__Struct)i1);
  Calendar__SetTimeStamp((void*)(OOC_INT64)c, (void*)(OOC_INT64)&t, (RT0__Struct)i1);
  i0 = *(OOC_INT32*)(OOC_INT64)&t;
  i2 = *(OOC_INT32*)(OOC_INT64)&first;
  i3 = i0<i2;
  if (i3) goto l7;
  i1 = *(OOC_INT32*)(OOC_INT64)&last;
  i1 = i0>=i1;
  if (i1) goto l5;
  return ((_div((i0-i2),7))+1);
  goto l8;
l5:
  return 1;
  goto l8;
l7:
  i0 = *(OOC_INT16*)(OOC_INT64)c;
  Calendar__WeekNumber_StartDate((i0-1), (void*)(OOC_INT64)&first, (RT0__Struct)i1);
  i0 = *(OOC_INT32*)(OOC_INT64)&t;
  i1 = *(OOC_INT32*)(OOC_INT64)&first;
  return ((_div((i0-i1),7))+1);
l8:
  _failed_function(7921); return 0;
  ;
}

OOC_INT16 Calendar__DayOfYear(const struct SysClock__DateTime *c__ref) {
  register OOC_INT64 i0,i1;
  OOC_ALLOCATE_VPAR(c,SysClock__DateTime ,1)
  struct SysClock__DateTime ndate;
  struct Time__TimeStamp fs;
  struct Time__TimeStamp cs;

  OOC_INITIALIZE_VPAR(c__ref,c,SysClock__DateTime ,12)
  _copy_block((OOC_INT64)c,(OOC_INT64)&ndate,12);
  *(OOC_INT8*)((OOC_INT64)&ndate+3) = 1;
  *(OOC_INT8*)((OOC_INT64)&ndate+2) = 1;
  i0 = (OOC_INT64)&_td_Time__TimeStamp;
  Calendar__SetTimeStamp((void*)(OOC_INT64)&ndate, (void*)(OOC_INT64)&fs, (RT0__Struct)i0);
  Calendar__SetTimeStamp((void*)(OOC_INT64)c, (void*)(OOC_INT64)&cs, (RT0__Struct)i0);
  i0 = *(OOC_INT32*)(OOC_INT64)&cs;
  i1 = *(OOC_INT32*)(OOC_INT64)&fs;
  return ((i0-i1)+1);
  ;
}

static void Calendar__DayOfWeekStr(const struct SysClock__DateTime *c__ref, OOC_INT16 len, OOC_CHAR8 str[], OOC_LEN str_0d) {
  register OOC_INT64 i0,i1;
  OOC_ALLOCATE_VPAR(c,SysClock__DateTime ,1)
  OOC_CHAR8 day[32];

  OOC_INITIALIZE_VPAR(c__ref,c,SysClock__DateTime ,12)
  i0 = Calendar__DayOfWeek((void*)(OOC_INT64)c);
  i0 = Locales__GetStr((18+i0), (void*)(OOC_INT64)day, 32);
  _assert(i0, 127, 10762);
  i0 = len;
  i1 = i0==0;
  if (i1) goto l3;
  Strings__Extract((void*)(OOC_INT64)day, 32, 0, i0, (void*)(OOC_INT64)str, str_0d);
  goto l4;
l3:
  _copy_8((const void*)(OOC_INT64)day,(void*)(OOC_INT64)str,str_0d);
l4:
  return;
  ;
}

static void Calendar__MonthStr(const struct SysClock__DateTime *c__ref, OOC_CHAR8 _short, OOC_CHAR8 str[], OOC_LEN str_0d) {
  register OOC_INT64 i0;
  OOC_ALLOCATE_VPAR(c,SysClock__DateTime ,1)
  OOC_CHAR8 Month[32];

  OOC_INITIALIZE_VPAR(c__ref,c,SysClock__DateTime ,12)
  i0 = *(OOC_INT8*)((OOC_INT64)c+2);
  i0 = Locales__GetStr(((25+i0)-1), (void*)(OOC_INT64)Month, 32);
  _assert(i0, 127, 11207);
  i0 = _short;
  if (i0) goto l3;
  _copy_8((const void*)(OOC_INT64)Month,(void*)(OOC_INT64)str,str_0d);
  goto l4;
l3:
  Strings__Extract((void*)(OOC_INT64)Month, 32, 0, 3, (void*)(OOC_INT64)str, str_0d);
l4:
  return;
  ;
}

static void Calendar__ExtractNumber(OOC_CHAR8 str[], OOC_LEN str_0d, OOC_INT16 *num, OOC_INT16 digits) {
  register OOC_INT64 i0,i1,i2;

  *num = 0;
  i0 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(0, str_0d, OOC_UINT8, 11555)));
  i0 = CharClass__IsNumeric(i0);
  if (i0) goto l3;
  i0=0u;
  goto l5;
l3:
  i0 = digits;
  i0 = i0>0;
  
l5:
  if (!i0) goto l16;
  i0=0;
l7_loop:
  i1 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(0, str_0d, OOC_UINT8, 11600)));
  i0 = ((10*i0)+i1)-48;
  *num = i0;
  Strings__Delete((void*)(OOC_INT64)str, str_0d, 0, 1);
  i1 = digits;
  i1 = i1-1;
  digits = i1;
  i2 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(0, str_0d, OOC_UINT8, 11555)));
  i2 = CharClass__IsNumeric(i2);
  if (i2) goto l10;
  i1=0u;
  goto l12;
l10:
  i1 = i1>0;
  
l12:
  if (i1) goto l7_loop;
l16:
  return;
  ;
}

static void Calendar__ExtractString(OOC_CHAR8 str[], OOC_LEN str_0d, OOC_INT8 len, const OOC_CHAR8 *comp__ref[], OOC_LEN comp_0d, OOC_LEN comp_1d, OOC_INT8 *m) {
  register OOC_INT64 i0,i1,i2,i3,i4,i5,i6,i7,i8,i9;
  OOC_ALLOCATE_VPAR(comp,OOC_CHAR8 ,comp_0d*comp_1d)

  i0 = comp_0d*comp_1d;
  OOC_INITIALIZE_VPAR(comp__ref,comp,OOC_CHAR8 ,i0)
  i0 = len;
  i1 = comp_1d-1;
  i2 = i0>0;
  i3=0;
l1_loop:
  if (i2) goto l4;
  i4=i1;
  goto l5;
l4:
  i4=i0;
l5:
  i5 = i3+1;
  *(OOC_UINT8*)(((OOC_INT64)comp+((_check_index(i3, comp_0d, OOC_UINT8, 11931))*comp_1d))+(_check_index(i4, comp_1d, OOC_UINT8, 11937))) = 0u;
  i6=0;
l6_loop:
  i7 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(i6, str_0d, OOC_UINT8, 12022)));
  i8 = i6+1;
  i9 = i8>i4;
  i7 = i7==0u;
  if (i7) goto l9;
  i7 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(i6, str_0d, OOC_UINT8, 12044)));
  i6 = *(OOC_UINT8*)(((OOC_INT64)comp+((_check_index(i3, comp_0d, OOC_UINT8, 12060))*comp_1d))+(_check_index(i6, comp_1d, OOC_UINT8, 12066)));
  i6 = (_cap(i7))!=(_cap(i6));
  
  goto l11;
l9:
  i6=1u;
l11:
  if (i6) goto l20;
l13:
  if (i9) goto l20;
  i6 = *(OOC_UINT8*)(((OOC_INT64)comp+((_check_index(i3, comp_0d, OOC_UINT8, 12187))*comp_1d))+(_check_index(i8, comp_1d, OOC_UINT8, 12193)));
  i6 = i6==0u;
  if (i6) goto l16;
  goto l17;
l16:
  Strings__Delete((void*)(OOC_INT64)str, str_0d, 0, i8);
  *m = i5;
  return;
l17:
  i6=i8;
  goto l6_loop;
l20:
  i3 = i5>=comp_0d;
  if (i3) goto l24;
  i3=i5;
  goto l1_loop;
l24:
  *m = 0;
  return;
  ;
}

static void Calendar__ExtractAMPM(OOC_CHAR8 str[], OOC_LEN str_0d, OOC_INT8 *hour) {
  register OOC_INT64 i0;

  i0 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(0, str_0d, OOC_UINT8, 12492)));
  i0 = (_cap(i0))==65u;
  if (i0) goto l3;
  i0=0u;
  goto l5;
l3:
  i0 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(1, str_0d, OOC_UINT8, 12512)));
  i0 = (_cap(i0))==77u;
  
l5:
  if (i0) goto l17;
  i0 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(0, str_0d, OOC_UINT8, 12563)));
  i0 = (_cap(i0))==80u;
  if (i0) goto l9;
  i0=0u;
  goto l11;
l9:
  i0 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(1, str_0d, OOC_UINT8, 12583)));
  i0 = (_cap(i0))==77u;
  
l11:
  if (!i0) goto l18;
  Strings__Delete((void*)(OOC_INT64)str, str_0d, 0, 2);
  i0 = *hour;
  i0 = i0+12;
  *hour = i0;
  i0 = i0==24;
  if (!i0) goto l18;
  *hour = 0;
  goto l18;
l17:
  Strings__Delete((void*)(OOC_INT64)str, str_0d, 0, 2);
l18:
  return;
  ;
}

static void Calendar__ExtractZone(OOC_CHAR8 str[], OOC_LEN str_0d, OOC_INT16 *zone) {
  register OOC_INT64 i0,i1,i2;
  OOC_CHAR8 TZAbbr[8];
  OOC_INT16 ccnt;

  _copy_8((const void*)(OOC_CHAR8*)"UTC",(void*)(OOC_INT64)TZAbbr,8);
  ccnt = 0;
  i0 = *(OOC_UINT8*)((OOC_INT64)TZAbbr+(_check_index(0, 8, OOC_UINT16, 12869)));
  i0 = i0!=0u;
  if (i0) goto l3;
  i0=0u;
  goto l5;
l3:
  i0 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(0, str_0d, OOC_UINT16, 12903)));
  i1 = *(OOC_UINT8*)((OOC_INT64)TZAbbr+(_check_index(0, 8, OOC_UINT16, 12889)));
  i0 = i1==(_cap(i0));
  
l5:
  if (i0) goto l7;
  i0=0;
  goto l17;
l7:
  i0=0;
l8_loop:
  i0 = i0+1;
  ccnt = i0;
  i1 = *(OOC_UINT8*)((OOC_INT64)TZAbbr+(_check_index(i0, 8, OOC_UINT16, 12869)));
  i1 = i1!=0u;
  if (i1) goto l11;
  i1=0u;
  goto l13;
l11:
  i1 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(i0, str_0d, OOC_UINT16, 12903)));
  i2 = *(OOC_UINT8*)((OOC_INT64)TZAbbr+(_check_index(i0, 8, OOC_UINT16, 12889)));
  i1 = i2==(_cap(i1));
  
l13:
  if (i1) goto l8_loop;
l17:
  i1 = *(OOC_UINT8*)((OOC_INT64)TZAbbr+(_check_index(i0, 8, OOC_UINT16, 12942)));
  i1 = i1==0u;
  if (i1) goto l20;
  *zone = (-32767);
  goto l24;
l20:
  Strings__Delete((void*)(OOC_INT64)str, str_0d, 0, i0);
  i0 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(0, str_0d, OOC_UINT8, 13020)));
  Strings__Delete((void*)(OOC_INT64)str, str_0d, 0, 1);
  Calendar__ExtractNumber((void*)(OOC_INT64)str, str_0d, (void*)(OOC_INT64)zone, 2);
  i1 = *zone;
  *zone = (i1*60);
  Calendar__ExtractNumber((void*)(OOC_INT64)str, str_0d, (void*)(OOC_INT64)&ccnt, 2);
  i1 = *zone;
  i2 = ccnt;
  i1 = i1+i2;
  *zone = i1;
  i0 = i0==43u;
  if (!i0) goto l24;
  *zone = (-i1);
l24:
  return;
  ;
}

void Calendar__TimeToStr(struct SysClock__DateTime *c, RT0__Struct c__tag, const OOC_CHAR8 pattern__ref[], OOC_LEN pattern_0d, OOC_CHAR8 dateStr[], OOC_LEN dateStr_0d) {
  register OOC_INT64 i0,i1,i2,i3,i4,i5,i6,i7,i8,i9;
  OOC_ALLOCATE_VPAR(pattern,OOC_CHAR8 ,pattern_0d)
  OOC_INT16 ccnt;
  OOC_INT16 rcnt;
  OOC_CHAR8 flag;
  OOC_CHAR8 temp[256];
  OOC_CHAR8 def[256];
  auto void Calendar__TimeToStr_AppendStr(const OOC_CHAR8 str__ref[], OOC_LEN str_0d);
  auto void Calendar__TimeToStr_AppendInt(OOC_INT16 _int, OOC_INT16 zero);
  auto OOC_INT16 Calendar__TimeToStr_TwelveHour(OOC_INT16 hour);
  auto void Calendar__TimeToStr_PutZone(OOC_INT16 zone);
    
    void Calendar__TimeToStr_AppendStr(const OOC_CHAR8 str__ref[], OOC_LEN str_0d) {
      register OOC_INT64 i0,i1,i2;
      OOC_ALLOCATE_VPAR(str,OOC_CHAR8 ,str_0d)

      OOC_INITIALIZE_VPAR(str__ref,str,OOC_CHAR8 ,str_0d)
      i0 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(0, str_0d, OOC_UINT16, 16286)));
      i0 = i0!=0u;
      if (!i0) goto l8;
      i0=0;
l3_loop:
      i1 = rcnt;
      i2 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(i0, str_0d, OOC_UINT16, 16314)));
      *(OOC_UINT8*)((OOC_INT64)dateStr+(_check_index(i1, dateStr_0d, OOC_UINT16, 16303))) = i2;
      rcnt = (i1+1);
      i0 = i0+1;
      i1 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(i0, str_0d, OOC_UINT16, 16286)));
      i1 = i1!=0u;
      if (i1) goto l3_loop;
l8:
      return;
      ;
    }

    
    void Calendar__TimeToStr_AppendInt(OOC_INT16 _int, OOC_INT16 zero) {
      register OOC_INT64 i0,i1;
      OOC_CHAR8 Temp[10];

      i0 = _int;
      IntStr__IntToStr(i0, (void*)(OOC_INT64)Temp, 10);
      i0 = Strings__Length((void*)(OOC_INT64)Temp, 10);
      i1 = zero;
      i0 = i0<i1;
      if (!i0) goto l8;
l3_loop:
      Strings__Insert((OOC_CHAR8*)"0", 2, 0, (void*)(OOC_INT64)Temp, 10);
      i0 = Strings__Length((void*)(OOC_INT64)Temp, 10);
      i0 = i0<i1;
      if (i0) goto l3_loop;
l8:
      Calendar__TimeToStr_AppendStr((void*)(OOC_INT64)Temp, 10);
      return;
      ;
    }

    
    OOC_INT16 Calendar__TimeToStr_TwelveHour(OOC_INT16 hour) {
      register OOC_INT64 i0,i1;

      i0 = hour;
      i1 = i0>12;
      if (i1) goto l7;
      i1 = i0==0;
      if (i1) goto l5;
      return i0;
      goto l8;
l5:
      return 12;
      goto l8;
l7:
      return (i0-12);
l8:
      _failed_function(16596); return 0;
      ;
    }

    
    void Calendar__TimeToStr_PutZone(OOC_INT16 zone) {
      register OOC_INT64 i0,i1;

      i0 = zone;
      i1 = i0<=(-32767);
      if (!i1) goto l3;
      return;
l3:
      i1 = i0<0;
      if (i1) goto l6;
      Calendar__TimeToStr_AppendStr((OOC_CHAR8*)"UTC-", 5);
      
      goto l7;
l6:
      Calendar__TimeToStr_AppendStr((OOC_CHAR8*)"UTC+", 5);
      i0 = _abs(i0);
      
l7:
      Calendar__TimeToStr_AppendInt((_div(i0,60)), 2);
      Calendar__TimeToStr_AppendInt((_mod(i0,60)), 2);
      return;
      ;
    }


  OOC_INITIALIZE_VPAR(pattern__ref,pattern,OOC_CHAR8 ,pattern_0d)
  ccnt = 0;
  rcnt = 0;
  i0 = *(OOC_UINT8*)((OOC_INT64)pattern+(_check_index(0, pattern_0d, OOC_UINT16, 17073)));
  i0 = i0!=0u;
  if (!i0) goto l47;
  i0 = (OOC_INT64)c__tag;
  i1 = (OOC_INT64)c+3;
  i2 = (OOC_INT64)c+2;
  i3 = (OOC_INT64)c+10;
  i4 = (OOC_INT64)c+4;
  i5 = (OOC_INT64)c+5;
  i6 = (OOC_INT64)c+6;
  i7=0;
l3_loop:
  i8 = *(OOC_UINT8*)((OOC_INT64)pattern+(_check_index(i7, pattern_0d, OOC_UINT16, 17101)));
  i8 = i8==37u;
  if (i8) goto l6;
  i8=0u;
  goto l8;
l6:
  i8 = *(OOC_UINT8*)((OOC_INT64)pattern+(_check_index((i7+1), pattern_0d, OOC_UINT16, 17123)));
  i8 = i8!=0u;
  
l8:
  if (i8) goto l10;
  i8 = rcnt;
  i9 = *(OOC_UINT8*)((OOC_INT64)pattern+(_check_index(i7, pattern_0d, OOC_UINT16, 18636)));
  *(OOC_UINT8*)((OOC_INT64)dateStr+(_check_index(i8, dateStr_0d, OOC_UINT16, 18621))) = i9;
  rcnt = (i8+1);
  i7 = i7+1;
  ccnt = i7;
  
  goto l42;
l10:
  i7 = i7+1;
  i8 = *(OOC_UINT8*)((OOC_INT64)pattern+(_check_index(i7, pattern_0d, OOC_UINT16, 17159)));
  switch (i8) {
  case 99u:
    i7 = Locales__GetStr(39, (void*)(OOC_INT64)temp, 256);
    flag = i7;
    _assert(i7, 127, 17236);
    Calendar__TimeToStr((void*)(OOC_INT64)c, (RT0__Struct)i0, (void*)(OOC_INT64)temp, 256, (void*)(OOC_INT64)def, 256);
    Calendar__TimeToStr_AppendStr((void*)(OOC_INT64)def, 256);
    goto l41;
  case 120u:
    i7 = Locales__GetStr(38, (void*)(OOC_INT64)temp, 256);
    flag = i7;
    _assert(i7, 127, 17368);
    Calendar__TimeToStr((void*)(OOC_INT64)c, (RT0__Struct)i0, (void*)(OOC_INT64)temp, 256, (void*)(OOC_INT64)def, 256);
    Calendar__TimeToStr_AppendStr((void*)(OOC_INT64)def, 256);
    goto l41;
  case 88u:
    i7 = Locales__GetStr(37, (void*)(OOC_INT64)temp, 256);
    flag = i7;
    _assert(i7, 127, 17500);
    Calendar__TimeToStr((void*)(OOC_INT64)c, (RT0__Struct)i0, (void*)(OOC_INT64)temp, 256, (void*)(OOC_INT64)def, 256);
    Calendar__TimeToStr_AppendStr((void*)(OOC_INT64)def, 256);
    goto l41;
  case 37u:
    Calendar__TimeToStr_AppendStr((OOC_CHAR8*)"%", 2);
    goto l41;
  case 68u:
    i7 = *(OOC_INT8*)i1;
    Calendar__TimeToStr_AppendInt(i7, 0);
    goto l41;
  case 100u:
    i7 = *(OOC_INT8*)i1;
    Calendar__TimeToStr_AppendInt(i7, 2);
    goto l41;
  case 106u:
    i7 = Calendar__DayOfYear((void*)(OOC_INT64)c);
    Calendar__TimeToStr_AppendInt(i7, 3);
    goto l41;
  case 66u:
    Calendar__MonthStr((void*)(OOC_INT64)c, 0u, (void*)(OOC_INT64)def, 256);
    Calendar__TimeToStr_AppendStr((void*)(OOC_INT64)def, 256);
    goto l41;
  case 98u:
    Calendar__MonthStr((void*)(OOC_INT64)c, 1u, (void*)(OOC_INT64)def, 256);
    Calendar__TimeToStr_AppendStr((void*)(OOC_INT64)def, 256);
    goto l41;
  case 109u:
    i7 = *(OOC_INT8*)i2;
    Calendar__TimeToStr_AppendInt(i7, 2);
    goto l41;
  case 85u:
    i7 = Calendar__WeekNumber((void*)(OOC_INT64)c, 0);
    Calendar__TimeToStr_AppendInt(i7, 2);
    goto l41;
  case 87u:
    i7 = Calendar__WeekNumber((void*)(OOC_INT64)c, 1);
    Calendar__TimeToStr_AppendInt(i7, 2);
    goto l41;
  case 121u:
    i7 = *(OOC_INT16*)(OOC_INT64)c;
    Calendar__TimeToStr_AppendInt((_mod(i7,100)), 2);
    goto l41;
  case 89u:
    i7 = *(OOC_INT16*)(OOC_INT64)c;
    Calendar__TimeToStr_AppendInt(i7, 0);
    goto l41;
  case 65u:
    Calendar__DayOfWeekStr((void*)(OOC_INT64)c, 0, (void*)(OOC_INT64)def, 256);
    Calendar__TimeToStr_AppendStr((void*)(OOC_INT64)def, 256);
    goto l41;
  case 97u:
    Calendar__DayOfWeekStr((void*)(OOC_INT64)c, 3, (void*)(OOC_INT64)def, 256);
    Calendar__TimeToStr_AppendStr((void*)(OOC_INT64)def, 256);
    goto l41;
  case 119u:
    i7 = Calendar__DayOfWeek((void*)(OOC_INT64)c);
    Calendar__TimeToStr_AppendInt(i7, 0);
    goto l41;
  case 90u:
    i7 = *(OOC_INT16*)i3;
    Calendar__TimeToStr_PutZone(i7);
    goto l41;
  case 72u:
    i7 = *(OOC_INT8*)i4;
    Calendar__TimeToStr_AppendInt(i7, 2);
    goto l41;
  case 73u:
    i7 = *(OOC_INT8*)i4;
    i7 = Calendar__TimeToStr_TwelveHour(i7);
    Calendar__TimeToStr_AppendInt(i7, 2);
    goto l41;
  case 105u:
    i7 = *(OOC_INT8*)i4;
    i7 = Calendar__TimeToStr_TwelveHour(i7);
    Calendar__TimeToStr_AppendInt(i7, 0);
    goto l41;
  case 112u:
    i7 = *(OOC_INT8*)i4;
    i7 = i7>=12;
    if (i7) goto l36;
    Calendar__TimeToStr_AppendStr((OOC_CHAR8*)"AM", 3);
    goto l41;
l36:
    Calendar__TimeToStr_AppendStr((OOC_CHAR8*)"PM", 3);
    goto l41;
  case 77u:
    i7 = *(OOC_INT8*)i5;
    Calendar__TimeToStr_AppendInt(i7, 2);
    goto l41;
  case 83u:
    i7 = *(OOC_INT8*)i6;
    Calendar__TimeToStr_AppendInt(i7, 2);
    goto l41;
  default:
    i8 = rcnt;
    *(OOC_UINT8*)((OOC_INT64)dateStr+(_check_index(i8, dateStr_0d, OOC_UINT16, 18523))) = 37u;
    i7 = *(OOC_UINT8*)((OOC_INT64)pattern+(_check_index(i7, pattern_0d, OOC_UINT16, 18560)));
    *(OOC_UINT8*)((OOC_INT64)dateStr+(_check_index((i8+1), dateStr_0d, OOC_UINT16, 18543))) = i7;
    goto l41;
  }
l41:
  i7 = ccnt;
  i7 = i7+2;
  ccnt = i7;
  
l42:
  i8 = *(OOC_UINT8*)((OOC_INT64)pattern+(_check_index(i7, pattern_0d, OOC_UINT16, 17073)));
  i8 = i8!=0u;
  if (i8) goto l3_loop;
l47:
  i0 = rcnt;
  *(OOC_UINT8*)((OOC_INT64)dateStr+(_check_index(i0, dateStr_0d, OOC_UINT16, 18689))) = 0u;
  return;
  ;
}

OOC_CHAR8 Calendar__StrToTime(struct SysClock__DateTime *c, RT0__Struct c__tag, const OOC_CHAR8 dateStr__ref[], OOC_LEN dateStr_0d, const OOC_CHAR8 pattern__ref[], OOC_LEN pattern_0d) {
  register OOC_INT64 i0,i1,i2,i3,i4,i5,i6;
  OOC_ALLOCATE_VPAR(dateStr,OOC_CHAR8 ,dateStr_0d)
  OOC_ALLOCATE_VPAR(pattern,OOC_CHAR8 ,pattern_0d)
  Calendar__StrToTime_ShortString Months[12];
  Calendar__StrToTime_ShortString Days[7];
  OOC_INT16 decade;
  OOC_CHAR8 lp[80];
  OOC_CHAR8 err;
  OOC_INT8 d;
  OOC_INT8 m;
  OOC_INT16 y;
  OOC_INT8 s;
  OOC_INT8 min;
  OOC_INT8 h;
  OOC_INT16 z;
  OOC_CHAR8 token;
  OOC_CHAR8 temp[80];
  OOC_INT16 inumb;
  OOC_INT8 snumb;
  auto void Calendar__StrToTime_NextToken(void);
  auto void Calendar__StrToTime_InitMonths(void);
  auto void Calendar__StrToTime_InitDays(void);
    
    void Calendar__StrToTime_NextToken(void) {
      register OOC_INT64 i0,i1;

      i0 = *(OOC_UINT8*)((OOC_INT64)lp+(_check_index(0, 80, OOC_UINT8, 20014)));
      i0 = i0==37u;
      if (i0) goto l10;
      i0 = (
      _cmp8((const void*)(OOC_INT64)lp,(const void*)(OOC_CHAR8*)"\000"))!=0;
      if (i0) goto l5;
      token = 0u;
      goto l11;
l5:
      i0 = *(OOC_UINT8*)((OOC_INT64)lp+(_check_index(0, 80, OOC_UINT8, 20093)));
      i1 = *(OOC_UINT8*)((OOC_INT64)dateStr+(_check_index(0, dateStr_0d, OOC_UINT8, 20104)));
      i0 = i0!=i1;
      if (!i0) goto l8;
      err = 1u;
l8:
      Strings__Delete((void*)(OOC_INT64)lp, 80, 0, 1);
      Strings__Delete((void*)(OOC_INT64)dateStr, dateStr_0d, 0, 1);
      token = 32u;
      goto l11;
l10:
      i0 = *(OOC_UINT8*)((OOC_INT64)lp+(_check_index(1, 80, OOC_UINT8, 20036)));
      token = i0;
      Strings__Delete((void*)(OOC_INT64)lp, 80, 0, 2);
l11:
      return;
      ;
    }

    
    void Calendar__StrToTime_InitMonths(void) {
      register OOC_INT64 i0,i1;

      i0=0;
l1_loop:
      i1 = err;
      if (i1) goto l4;
      i1 = Locales__GetStr((25+i0), (void*)((OOC_INT64)Months+((_check_index(i0, 12, OOC_UINT16, 20362))*32)), 32);
      i1 = !i1;
      
      goto l5;
l4:
      i1=1u;
l5:
      err = i1;
      i0 = i0+1;
      i1 = i0<=11;
      if (i1) goto l1_loop;
l9:
      return;
      ;
    }

    
    void Calendar__StrToTime_InitDays(void) {
      register OOC_INT64 i0,i1;

      i0=0;
l1_loop:
      i1 = err;
      if (i1) goto l4;
      i1 = Locales__GetStr((18+i0), (void*)((OOC_INT64)Days+((_check_index(i0, 7, OOC_UINT16, 20501))*32)), 32);
      i1 = !i1;
      
      goto l5;
l4:
      i1=1u;
l5:
      err = i1;
      i0 = i0+1;
      i1 = i0<=6;
      if (i1) goto l1_loop;
l9:
      return;
      ;
    }


  OOC_INITIALIZE_VPAR(dateStr__ref,dateStr,OOC_CHAR8 ,dateStr_0d)
  OOC_INITIALIZE_VPAR(pattern__ref,pattern,OOC_CHAR8 ,pattern_0d)
  _copy_8((const void*)(OOC_CHAR8*)"",(void*)((OOC_INT64)Months+((_check_index(0, 12, OOC_UINT8, 20783))*32)),32);
  _copy_8((const void*)(OOC_CHAR8*)"",(void*)((OOC_INT64)Days+((_check_index(0, 7, OOC_UINT8, 20796))*32)),32);
  i0 = (OOC_INT64)c__tag;
  SysClock__GetClock((void*)(OOC_INT64)c, (RT0__Struct)i0);
  i1 = *(OOC_INT16*)(OOC_INT64)c;
  decade = ((_div(i1,100))*100);
  _copy_8((const void*)(OOC_INT64)pattern,(void*)(OOC_INT64)lp,80);
  err = 0u;
  d = 1;
  m = 1;
  y = 1970;
  s = 0;
  min = 0;
  h = 0;
  z = (-32767);
l1_loop:
  Calendar__StrToTime_NextToken();
  i1 = token;
  switch (i1) {
  case 99u:
    i1 = err;
    if (i1) goto l6;
    i1 = Locales__GetStr(39, (void*)(OOC_INT64)temp, 80);
    i1 = !i1;
    
    goto l7;
l6:
    i1=1u;
l7:
    err = i1;
    Strings__Insert((void*)(OOC_INT64)temp, 80, 0, (void*)(OOC_INT64)lp, 80);
    goto l43;
  case 120u:
    i1 = err;
    if (i1) goto l11;
    i1 = Locales__GetStr(38, (void*)(OOC_INT64)temp, 80);
    i1 = !i1;
    
    goto l12;
l11:
    i1=1u;
l12:
    err = i1;
    Strings__Insert((void*)(OOC_INT64)temp, 80, 0, (void*)(OOC_INT64)lp, 80);
    goto l43;
  case 88u:
    i1 = err;
    if (i1) goto l16;
    i1 = Locales__GetStr(37, (void*)(OOC_INT64)temp, 80);
    i1 = !i1;
    
    goto l17;
l16:
    i1=1u;
l17:
    err = i1;
    Strings__Insert((void*)(OOC_INT64)temp, 80, 0, (void*)(OOC_INT64)lp, 80);
    goto l43;
  case 68u:
  case 100u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&inumb, 2);
    i1 = inumb;
    d = i1;
    goto l43;
  case 106u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&inumb, 3);
    goto l43;
  case 66u:
    Calendar__StrToTime_InitMonths();
    Calendar__ExtractString((void*)(OOC_INT64)dateStr, dateStr_0d, 0, (void*)(OOC_INT64)Months, 12, 32, (void*)(OOC_INT64)&m);
    goto l43;
  case 98u:
    Calendar__StrToTime_InitMonths();
    Calendar__ExtractString((void*)(OOC_INT64)dateStr, dateStr_0d, 3, (void*)(OOC_INT64)Months, 12, 32, (void*)(OOC_INT64)&m);
    goto l43;
  case 109u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&inumb, 2);
    i1 = inumb;
    m = i1;
    goto l43;
  case 85u:
  case 87u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&inumb, 2);
    goto l43;
  case 121u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&y, 2);
    i1 = y;
    i2 = decade;
    y = (i1+i2);
    goto l43;
  case 89u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&y, 4);
    goto l43;
  case 65u:
    Calendar__StrToTime_InitDays();
    Calendar__ExtractString((void*)(OOC_INT64)dateStr, dateStr_0d, 0, (void*)(OOC_INT64)Days, 7, 32, (void*)(OOC_INT64)&snumb);
    goto l43;
  case 97u:
    Calendar__StrToTime_InitDays();
    Calendar__ExtractString((void*)(OOC_INT64)dateStr, dateStr_0d, 3, (void*)(OOC_INT64)Days, 7, 32, (void*)(OOC_INT64)&snumb);
    goto l43;
  case 37u:
    Strings__Delete((void*)(OOC_INT64)dateStr, dateStr_0d, 0, 1);
    goto l43;
  case 90u:
    Calendar__ExtractZone((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&z);
    goto l43;
  case 72u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&inumb, 2);
    i1 = inumb;
    h = i1;
    goto l43;
  case 73u:
  case 105u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&inumb, 2);
    i1 = inumb;
    h = i1;
    goto l43;
  case 112u:
    Calendar__ExtractAMPM((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&h);
    goto l43;
  case 77u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&inumb, 2);
    i1 = inumb;
    min = i1;
    goto l43;
  case 83u:
    Calendar__ExtractNumber((void*)(OOC_INT64)dateStr, dateStr_0d, (void*)(OOC_INT64)&inumb, 2);
    i1 = inumb;
    s = i1;
    goto l43;
  default:
    i2 = i1!=0u;
    if (i2) goto l38;
    i1=0u;
    goto l40;
l38:
    i1 = i1!=32u;
    
l40:
    if (!i1) goto l43;
    err = 1u;
    goto l43;
  }
l43:
  i1 = token;
  i1 = i1==0u;
  if (!i1) goto l1_loop;
l47:
  i1 = y;
  i1 = i1<=0;
  if (!i1) goto l50;
  y = 1;
  err = 1u;
l50:
  i1 = m;
  i2 = i1<1;
  if (i2) goto l53;
  i1 = i1>12;
  
  goto l55;
l53:
  i1=1u;
l55:
  if (!i1) goto l57;
  m = 1;
  err = 1u;
l57:
  i1 = d;
  i2 = i1<1;
  if (i2) goto l60;
  i1 = i1>31;
  
  goto l62;
l60:
  i1=1u;
l62:
  if (!i1) goto l64;
  d = 1;
  err = 1u;
l64:
  i1 = h;
  i2 = i1<0;
  if (i2) goto l67;
  i1 = i1>23;
  
  goto l69;
l67:
  i1=1u;
l69:
  if (!i1) goto l71;
  h = 0;
  err = 1u;
l71:
  i1 = min;
  i2 = i1<0;
  if (i2) goto l74;
  i1 = i1>59;
  
  goto l76;
l74:
  i1=1u;
l76:
  if (!i1) goto l78;
  min = 0;
  err = 1u;
l78:
  i1 = s;
  i2 = i1<0;
  if (i2) goto l81;
  i1 = i1>59;
  
  goto l83;
l81:
  i1=1u;
l83:
  if (!i1) goto l85;
  s = 0;
  err = 1u;
l85:
  i1 = s;
  i2 = min;
  i3 = h;
  i4 = d;
  i5 = m;
  i6 = y;
  Calendar__SetLocalTime((void*)(OOC_INT64)c, (RT0__Struct)i0, i4, i5, i6, i3, i2, i1);
  i0 = z;
  i1 = i0!=(-32767);
  if (!i1) goto l88;
  *(OOC_INT16*)((OOC_INT64)c+10) = i0;
l88:
  i0 = err;
  return (!i0);
  ;
}

static void Calendar__Test(void) {
  register OOC_INT64 i0,i1,i2,i3,i4;
  OOC_CHAR8 s[80];
  struct SysClock__DateTime d;

  i0 = Locales__ALL;
  Locales__Set(i0, (OOC_CHAR8*)"", 1, (void*)(OOC_INT64)s, 80);
  i0 = Locales__GetStr(38, (void*)(OOC_INT64)s, 80);
  if (!i0) goto l3;
  Out__String((OOC_CHAR8*)"Default date format = ", 23);
  Out__String((void*)(OOC_INT64)s, 80);
  Out__Ln();
l3:
  i0 = Locales__GetStr(37, (void*)(OOC_INT64)s, 80);
  if (!i0) goto l6;
  Out__String((OOC_CHAR8*)"Default time format = ", 23);
  Out__String((void*)(OOC_INT64)s, 80);
  Out__Ln();
l6:
  i0 = Locales__GetStr(39, (void*)(OOC_INT64)s, 80);
  if (!i0) goto l9;
  Out__String((OOC_CHAR8*)"Default both format = ", 23);
  Out__String((void*)(OOC_INT64)s, 80);
  Out__Ln();
l9:
  i0 = (OOC_INT64)&_td_SysClock__DateTime;
  SysClock__GetClock((void*)(OOC_INT64)&d, (RT0__Struct)i0);
  Out__String((OOC_CHAR8*)"Current DST is ", 16);
  i1 = (OOC_INT64)&d+7;
  i2 = *(OOC_INT8*)i1;
  Out__Int(i2, 0);
  Out__Ln();
  Out__String((OOC_CHAR8*)"Current zone offset ", 21);
  i2 = (OOC_INT64)&d+10;
  i3 = *(OOC_INT16*)i2;
  Out__Int(i3, 0);
  Out__Ln();
  Calendar__TimeToStr((void*)(OOC_INT64)&d, (RT0__Struct)i0, (OOC_CHAR8*)"%A, %D %b, %Y", 14, (void*)(OOC_INT64)s, 80);
  Out__String((OOC_CHAR8*)"Pattern: `%A, %D %b, %Y\047 = ", 28);
  Out__String((void*)(OOC_INT64)s, 80);
  Out__Ln();
  Calendar__TimeToStr((void*)(OOC_INT64)&d, (RT0__Struct)i0, (OOC_CHAR8*)"Today is %c", 12, (void*)(OOC_INT64)s, 80);
  Out__String((OOC_CHAR8*)"Pattern: `%c\047 = ", 17);
  Out__String((void*)(OOC_INT64)s, 80);
  Out__Ln();
  i3 = Calendar__StrToTime((void*)(OOC_INT64)&d, (RT0__Struct)i0, (void*)(OOC_INT64)s, 80, (OOC_CHAR8*)"Today is %c", 12);
  i3 = !i3;
  if (!i3) goto l12;
  Out__String((OOC_CHAR8*)"Error detected...", 18);
  Out__Ln();
l12:
  Calendar__TimeToStr((void*)(OOC_INT64)&d, (RT0__Struct)i0, (OOC_CHAR8*)"Workweek = %W", 14, (void*)(OOC_INT64)s, 80);
  Out__String((void*)(OOC_INT64)s, 80);
  Out__Ln();
  Calendar__TimeToStr((void*)(OOC_INT64)&d, (RT0__Struct)i0, (OOC_CHAR8*)"12-hour time = %i:%M:%S%p", 26, (void*)(OOC_INT64)s, 80);
  Out__String((void*)(OOC_INT64)s, 80);
  Out__Ln();
  Calendar__TimeToStr((void*)(OOC_INT64)&d, (RT0__Struct)i0, (OOC_CHAR8*)"van Acken (weird pattern): %%c", 31, (void*)(OOC_INT64)s, 80);
  Out__String((void*)(OOC_INT64)s, 80);
  Out__Ln();
  i3 = Calendar__StrToTime((void*)(OOC_INT64)&d, (RT0__Struct)i0, (void*)(OOC_INT64)s, 80, (OOC_CHAR8*)"Full date: %A, %B %D, %Y, %j days from year start", 50);
  i3 = !i3;
  if (!i3) goto l15;
  Out__String((OOC_CHAR8*)"Intentional error detected...", 30);
  Out__Ln();
l15:
  SysClock__GetClock((void*)(OOC_INT64)&d, (RT0__Struct)i0);
  Calendar__TimeToStr((void*)(OOC_INT64)&d, (RT0__Struct)i0, (OOC_CHAR8*)"Full date: %A, %B %D, %Y, %j days from year start", 50, (void*)(OOC_INT64)s, 80);
  Out__String((void*)(OOC_INT64)s, 80);
  Out__Ln();
  i3 = Calendar__StrToTime((void*)(OOC_INT64)&d, (RT0__Struct)i0, (void*)(OOC_INT64)s, 80, (OOC_CHAR8*)"Full date: %A, %B %D, %Y, %j days from year start", 50);
  i3 = !i3;
  if (!i3) goto l18;
  Out__String((OOC_CHAR8*)"Error detected...", 18);
  Out__Ln();
l18:
  Out__String((OOC_CHAR8*)"Checking DST functions...", 26);
  Out__Ln();
  i3 = (OOC_INT64)&d+2;
  *(OOC_INT8*)i3 = 12;
  SysClock__MakeLocalTime((void*)(OOC_INT64)&d, (RT0__Struct)i0);
  Out__String((OOC_CHAR8*)"December DST is ", 17);
  i4 = *(OOC_INT8*)i1;
  Out__Int(i4, 0);
  Out__Ln();
  Out__String((OOC_CHAR8*)"December zone offset ", 22);
  i4 = *(OOC_INT16*)i2;
  Out__Int(i4, 0);
  Out__Ln();
  *(OOC_INT8*)i3 = 7;
  SysClock__MakeLocalTime((void*)(OOC_INT64)&d, (RT0__Struct)i0);
  Out__String((OOC_CHAR8*)"August DST is ", 15);
  i3 = *(OOC_INT8*)i1;
  Out__Int(i3, 0);
  Out__Ln();
  Out__String((OOC_CHAR8*)"August zone offset ", 20);
  i3 = *(OOC_INT16*)i2;
  Out__Int(i3, 0);
  Out__Ln();
  i3=1900;
l19_loop:
  *(OOC_INT16*)(OOC_INT64)&d = i3;
  SysClock__MakeLocalTime((void*)(OOC_INT64)&d, (RT0__Struct)i0);
  Out__Int(i3, 0);
  Out__String((OOC_CHAR8*)" DST is ", 9);
  i4 = *(OOC_INT8*)i1;
  Out__Int(i4, 0);
  Out__String((OOC_CHAR8*)"; zone offset ", 15);
  i4 = *(OOC_INT16*)i2;
  Out__Int(i4, 0);
  Out__Ln();
  i3 = i3+1;
  i4 = i3<=2100;
  if (i4) goto l19_loop;
l23:
  *(OOC_INT16*)(OOC_INT64)&d = 2100;
  SysClock__MakeLocalTime((void*)(OOC_INT64)&d, (RT0__Struct)i0);
  Out__String((OOC_CHAR8*)"2100 DST is ", 13);
  i0 = *(OOC_INT8*)i1;
  Out__Int(i0, 0);
  Out__Ln();
  Out__String((OOC_CHAR8*)"2100 zone offset ", 18);
  i0 = *(OOC_INT16*)i2;
  Out__Int(i0, 0);
  Out__Ln();
  return;
  ;
}

void OOC_Calendar_init(void) {

  return;
  ;
}

void OOC_Calendar_destroy(void) {
}

/* --- */
