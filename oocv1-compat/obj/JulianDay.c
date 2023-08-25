#include <JulianDay.d>
#include <__oo2c.h>
#include <setjmp.h>

OOC_REAL64 JulianDay__DateToJD(OOC_INT8 day, OOC_INT8 month, OOC_INT16 year) {
  register OOC_INT64 i0,i1,i2,i3,i4;
  register OOC_REAL64 d0,d1;

  i0 = month;
  i1 = i0<3;
  if (!i1) goto l4;
  i1 = year;
  year = (i1-1);
  i0 = i0+12;
  
l4:
  i1 = year;
  i2 = JulianDay__UseGregorian;
  if (i2) goto l7;
  i3=0;
  goto l8;
l7:
  i3 = _div(i1,100);
  i3 = (2-i3)+(i3>>2);
  
l8:
  i4 = day;
  d0 = ((OOC_REAL64)(((i3+i4)+(_entier((3.6525000000000000E+2*((OOC_REAL64)(i1+4716))))))+(_entier((3.0600100000000001E+1*((OOC_REAL64)(i0+1)))))))-1.5245000000000000E+3;
  if (i2) goto l11;
  i0=0u;
  goto l13;
l11:
  d1 = JulianDay__startGregor;
  i0 = d0>=d1;
  
l13:
  if (i0) goto l15;
  return (d0-((OOC_REAL64)i3));
  goto l16;
l15:
  return d0;
l16:
  _failed_function(1537); return 0;
  ;
}

OOC_INT32 JulianDay__DateToDays(OOC_INT8 day, OOC_INT8 month, OOC_INT16 year) {
  register OOC_INT64 i0,i1,i2;
  register OOC_REAL64 d0;

  i0 = year;
  i1 = month;
  i2 = day;
  d0 = JulianDay__DateToJD(i2, i1, i0);
  return (_entier((d0-2.4000005000000000E+6)));
  ;
}

OOC_INT32 JulianDay__DateToTJD(OOC_INT8 day, OOC_INT8 month, OOC_INT16 year) {
  register OOC_INT64 i0,i1,i2;
  register OOC_REAL64 d0;

  i0 = year;
  i1 = month;
  i2 = day;
  d0 = JulianDay__DateToJD(i2, i1, i0);
  return (_entier((d0-2.4400005000000000E+6)));
  ;
}

void JulianDay__JDToDate(OOC_REAL64 jd, OOC_INT8 *day, OOC_INT8 *month, OOC_INT16 *year) {
  register OOC_INT64 i0,i1,i2;
  register OOC_REAL64 d0,d1;

  d0 = jd;
  d0 = d0+5.0000000000000000E-1;
  i0 = JulianDay__UseGregorian;
  if (i0) goto l3;
  i0=0u;
  goto l5;
l3:
  d1 = JulianDay__startGregor;
  i0 = d0>=d1;
  
l5:
  if (i0) goto l7;
  i0 = _entier((d0+1.5240000000000000E+3));
  
  goto l8;
l7:
  d1 = (OOC_REAL64)(_entier(((d0-1.8672162500000000E+6)/3.6524250000000000E+4)));
  i0 = _entier((((d0+1.5250000000000000E+3)+d1)-((OOC_REAL64)(_entier((d1/4.0000000000000000))))));
  
l8:
  i1 = _entier(((((OOC_REAL64)i0)-1.2209999999999999E+2)/3.6525000000000000E+2));
  i0 = i0-(_entier((3.6525000000000000E+2*((OOC_REAL64)i1))));
  i2 = _entier((((OOC_REAL64)i0)/3.0600100000000001E+1));
  *month = i2;
  *day = (i0-(_entier((3.0600100000000001E+1*((OOC_REAL64)i2)))));
  i0 = *month;
  i2 = i0>13;
  if (i2) goto l11;
  i0 = i0-1;
  *month = i0;
  
  goto l12;
l11:
  i0 = i0-13;
  *month = i0;
  
l12:
  i0 = i0<3;
  if (i0) goto l15;
  *year = (i1-4716);
  goto l16;
l15:
  *year = (i1-4715);
l16:
  return;
  ;
}

void JulianDay__DaysToDate(OOC_INT32 jd, OOC_INT8 *day, OOC_INT8 *month, OOC_INT16 *year) {
  register OOC_INT64 i0;

  i0 = jd;
  JulianDay__JDToDate((((OOC_REAL64)i0)+2.4000005000000000E+6), (void*)(OOC_INT64)day, (void*)(OOC_INT64)month, (void*)(OOC_INT64)year);
  return;
  ;
}

void JulianDay__TJDToDate(OOC_INT32 jd, OOC_INT8 *day, OOC_INT8 *month, OOC_INT16 *year) {
  register OOC_INT64 i0;

  i0 = jd;
  JulianDay__JDToDate((((OOC_REAL64)i0)+2.4400005000000000E+6), (void*)(OOC_INT64)day, (void*)(OOC_INT64)month, (void*)(OOC_INT64)year);
  return;
  ;
}

void JulianDay__SetGregorianStart(OOC_INT8 day, OOC_INT8 month, OOC_INT16 year) {
  register OOC_INT64 i0,i1,i2,i3;
  register OOC_REAL64 d0;

  i0 = JulianDay__UseGregorian;
  JulianDay__UseGregorian = 0u;
  i1 = day;
  i2 = month;
  i3 = year;
  d0 = JulianDay__DateToJD(i1, i2, i3);
  JulianDay__startGregor = d0;
  JulianDay__UseGregorian = i0;
  return;
  ;
}

void OOC_JulianDay_init(void) {

  JulianDay__UseGregorian = 1u;
  JulianDay__startGregor = 0.0000000000000000;
  JulianDay__SetGregorianStart(3, 9, 1752);
  return;
  ;
}

void OOC_JulianDay_destroy(void) {
}

/* --- */
