#include <Calendar.oh>
#include <CharClass.oh>
#include <JulianDay.oh>
#include <Strings.oh>
#include <IntStr.oh>
#include <Locales.oh>
#include <Out.oh>
#define Calendar__DEBUG OOC_FALSE
static OOC_CHAR8 Calendar__IsValidTime(OOC_INT8 h, OOC_INT8 m, OOC_INT8 s, OOC_INT16 f);
static OOC_INT32 Calendar__TimeToMSec(OOC_INT8 h, OOC_INT8 m, OOC_INT8 s, OOC_INT16 f);
static void Calendar__MSecToTime(OOC_INT32 ms, OOC_INT8 *h, OOC_INT8 *m, OOC_INT8 *s, OOC_INT16 *f);
static void Calendar__Inc(struct SysClock__DateTime *d, RT0__Struct d__tag, OOC_INT32 days);
static void Calendar__Dec(struct SysClock__DateTime *d, RT0__Struct d__tag, OOC_INT32 days);
static void Calendar__DayOfWeekStr(const struct SysClock__DateTime *c__ref, OOC_INT16 len, OOC_CHAR8 str[], OOC_LEN str_0d);
static void Calendar__MonthStr(const struct SysClock__DateTime *c__ref, OOC_CHAR8 _short, OOC_CHAR8 str[], OOC_LEN str_0d);
static void Calendar__ExtractNumber(OOC_CHAR8 str[], OOC_LEN str_0d, OOC_INT16 *num, OOC_INT16 digits);
static void Calendar__ExtractString(OOC_CHAR8 str[], OOC_LEN str_0d, OOC_INT8 len, const OOC_CHAR8 *comp__ref[], OOC_LEN comp_0d, OOC_LEN comp_1d, OOC_INT8 *m);
static void Calendar__ExtractAMPM(OOC_CHAR8 str[], OOC_LEN str_0d, OOC_INT8 *hour);
static void Calendar__ExtractZone(OOC_CHAR8 str[], OOC_LEN str_0d, OOC_INT16 *zone);
static void Calendar__Test(void);
typedef OOC_CHAR8 Calendar__StrToTime_ShortString[32];

/* run-time meta data */
static RT0__ModuleDesc _mid;
RT0__StructDesc _td_Calendar__10541 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__10671 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 32, 32, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Calendar__10956 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__11121 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 32, 32, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Calendar__11464 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__11711 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__11756 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__11747 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 2, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__12437 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__12727 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__12776 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 8, 8, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Calendar__13387 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__13438 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__16130 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 256, 256, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Calendar__16220 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__16422 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 10, 10, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Calendar__18767 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__18814 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Calendar__StrToTime_ShortString = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, (OOC_CHAR8*)"ShortString", 32, 32, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Calendar__19780 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 80, 80, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Calendar__19914 = { (RT0__Struct[]){&_td_Calendar__StrToTime_ShortString}, NULL, NULL, &_mid, NULL, 384, 12, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Calendar__19947 = { (RT0__Struct[]){&_td_Calendar__StrToTime_ShortString}, NULL, NULL, &_mid, NULL, 224, 7, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Calendar__22925 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 80, 80, (1<<RT0__flagAtomic), RT0__strArray };
static RT0__ModuleDesc _mid = { (OOC_CHAR8*)"Calendar", (RT0__Struct[]) { NULL }, 0 };

extern void OOC_Calendar_open(RT0__Module client) {
  if (_mid.openCount == 0) {
    OOC_CharClass_open(&_mid);
    OOC_Time_open(&_mid);
    OOC_SysClock_open(&_mid);
    OOC_JulianDay_open(&_mid);
    OOC_Strings_open(&_mid);
    OOC_IntStr_open(&_mid);
    OOC_Locales_open(&_mid);
    OOC_Out_open(&_mid);
    OOC_RT0_open(&_mid);
    OOC_Object_open(&_mid);
    OOC_Exception_open(&_mid);

    RT0__RegisterModule(&_mid);
    OOC_Calendar_init();
  }
  _mid.openCount++;
}
extern void OOC_Calendar_close(RT0__Module client) {
  _mid.openCount--;
  if (_mid.openCount == 0) { 
    OOC_Calendar_destroy();
    RT0__UnregisterModule(&_mid);

    OOC_CharClass_close(&_mid);
    OOC_Time_close(&_mid);
    OOC_SysClock_close(&_mid);
    OOC_JulianDay_close(&_mid);
    OOC_Strings_close(&_mid);
    OOC_IntStr_close(&_mid);
    OOC_Locales_close(&_mid);
    OOC_Out_close(&_mid);
    OOC_RT0_close(&_mid);
    OOC_Object_close(&_mid);
    OOC_Exception_close(&_mid);
  }
}

/* --- */
