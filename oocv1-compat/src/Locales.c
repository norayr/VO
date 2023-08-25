/*	$Id: Locales.c,v 1.1 2003/05/03 08:20:52 tteuling Exp $	*/
#include <limits.h>
#include <locale.h>
#include <time.h>

#include "__oo2c.h"
#include "Locales.d"

static struct tm Locales__base;


void Locales__RecoverPattern_ReplacePattern(const OOC_CHAR8* pattern, OOC_LEN pattern_0d,
                                           OOC_CHAR8* str, OOC_LEN str_0d) {
  int i;
  OOC_BOOLEAN found;
  OOC_INT16 pos;
  OOC_CHAR8 src[132];

  i = strftime((char*)src, 132, (const char*)pattern, &Locales__base);
  Strings__FindNext((const OOC_CHAR8*)src, 132, (const OOC_CHAR8*)str, str_0d, 
		   0, &found, &pos);
  if (found) {
    i = Strings__Length(src, 132);
    Strings__Delete(str, str_0d, pos, (short int)i);
    Strings__Insert(pattern, pattern_0d, pos, str, str_0d);
  }
}

void Locales__RecoverPattern(OOC_CHAR8* str, OOC_LEN str_0d) {
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%A", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%a", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%B", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%b", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%d", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%H", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%I", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%j", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%m", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%M", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%p", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%S", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%U", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%W", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%w", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%Y", 3, str, str_0d);
  Locales__RecoverPattern_ReplacePattern((const OOC_CHAR8*)"%y", 3, str, str_0d);
}

OOC_BOOLEAN Locales__GetStr(OOC_INT32 id, OOC_CHAR8* ls, OOC_LEN ls_0d) {
  OOC_CHAR8* str;
  struct tm tp;
  struct lconv *loc;
  OOC_INT32 ret;

  if (id<Locales__daysOfWeek) {
    /* use the C localization information */
    loc=localeconv();
    switch (id) {
      case (Locales__decimalPoint):      str=(OOC_CHAR8*)loc->decimal_point; break;
      case (Locales__thousandsSep):      str=(OOC_CHAR8*)loc->thousands_sep; break;
      case (Locales__grouping):          str=(OOC_CHAR8*)loc->grouping; break;
      case (Locales__intCurrencySymbol): str=(OOC_CHAR8*)loc->int_curr_symbol; break;
      case (Locales__currencySymbol):    str=(OOC_CHAR8*)loc->currency_symbol; break;
      case (Locales__monDecimalPoint):   str=(OOC_CHAR8*)loc->mon_decimal_point; break;
      case (Locales__monThousandsSep):   str=(OOC_CHAR8*)loc->mon_thousands_sep; break;
      case (Locales__monGrouping):       str=(OOC_CHAR8*)loc->mon_grouping; break;
      case (Locales__positiveSign):      str=(OOC_CHAR8*)loc->positive_sign; break;
      case (Locales__negativeSign):      str=(OOC_CHAR8*)loc->negative_sign; break;
      default:                          return 0; break;
    }
    _copy_8(str, ls, ls_0d);
  } else if (id<Locales__months) {
    /* use the strftime routine to get the day strings */
    tp = Locales__base;
    tp.tm_wday=id-Locales__daysOfWeek;
    tp.tm_mday+=tp.tm_wday;
    ret=strftime((char*)ls, ls_0d, "%A", &tp);
  } else if (id<Locales__defTimeFormat) {
    /* use the strftime routine to get the month strings */
    tp = Locales__base;
    tp.tm_mon=id-Locales__months;
    ret=strftime((char*)ls, ls_0d, "%B", &tp);
  } else if (id==Locales__defTimeFormat) {
    tp = Locales__base;
    ret=strftime((char*)ls, ls_0d, "%X", &tp);
    Locales__RecoverPattern(ls, ls_0d);        
  } else if (id==Locales__defDateFormat) {
    tp = Locales__base;
    ret=strftime((char*)ls, ls_0d, "%x", &tp);
    Locales__RecoverPattern(ls, ls_0d); 
  } else if (id==Locales__defBothFormat) {
    tp = Locales__base;
    ret=strftime((char*)ls, ls_0d, "%c", &tp);
    Locales__RecoverPattern(ls, ls_0d); 
  } else {
    return 0;
  };
  return 1;
}

OOC_INT32 Locales__GetInt(OOC_INT32 id) {
  struct lconv *loc;

  loc=localeconv();
  switch (id) {
    case (Locales__intFracDigits): return loc->int_frac_digits; break;
    case (Locales__fracDigits):    return loc->frac_digits; break;
    case (Locales__pCSPrecedes):   return loc->p_cs_precedes; break;
    case (Locales__pSepBySpace):   return loc->p_sep_by_space; break;
    case (Locales__nCSPrecedes):   return loc->n_cs_precedes; break;
    case (Locales__nSepBySpace):   return loc->n_sep_by_space; break;
    case (Locales__pSignPosn):     return loc->p_sign_posn; break;
    case (Locales__nSignPosn):     return loc->n_sign_posn; break;
    default:                      return (-2147483647-1); break;
  }
}

void Locales__Set(OOC_INT32 category, const OOC_CHAR8* name, OOC_LEN name_0d, 
		 OOC_CHAR8* old, OOC_LEN old_0d) {
  char* oloc;

  oloc = setlocale(category, (const char*)name);
  if (oloc) {
    _copy_8(oloc, old, old_0d);
  } else {
    _copy_8("", old, old_0d);
  }
}

void OOC_Locales_init(void) {
  /* initialize a base date = Sunday, 22 Dec 1996, 16:02:03 */
  Locales__base.tm_sec=3; Locales__base.tm_min=2; Locales__base.tm_hour=16;
  Locales__base.tm_mday=22; Locales__base.tm_mon=11; Locales__base.tm_year=96;
  Locales__base.tm_wday=0;

  /* valid definitions for all OSes */
  Locales__ALL = LC_ALL;
  Locales__COLLATE = LC_COLLATE;
  Locales__CTYPE = LC_CTYPE;
  Locales__MONETARY = LC_MONETARY;
  Locales__NUMERIC = LC_NUMERIC;
  Locales__TIME = LC_TIME;

  /* initialize the error procedure pointer */
  Locales__GetText = NULL;
}
