#include <LibOOCv1Compat.oh>
#include <Calendar.oh>
#include <JulianDay.oh>
#include <Locales.oh>
#include <Strings2.oh>

/* run-time meta data */
static RT0__ModuleDesc _mid;
static RT0__ModuleDesc _mid = { (OOC_CHAR8*)"LibOOCv1Compat", (RT0__Struct[]) { NULL }, 0 };

extern void OOC_LibOOCv1Compat_open(RT0__Module client) {
  if (_mid.openCount == 0) {
    OOC_Calendar_open(&_mid);
    OOC_JulianDay_open(&_mid);
    OOC_Locales_open(&_mid);
    OOC_Strings2_open(&_mid);
    OOC_RT0_open(&_mid);
    OOC_Object_open(&_mid);
    OOC_Exception_open(&_mid);

    RT0__RegisterModule(&_mid);
    OOC_LibOOCv1Compat_init();
  }
  _mid.openCount++;
}
extern void OOC_LibOOCv1Compat_close(RT0__Module client) {
  _mid.openCount--;
  if (_mid.openCount == 0) { 
    OOC_LibOOCv1Compat_destroy();
    RT0__UnregisterModule(&_mid);

    OOC_Calendar_close(&_mid);
    OOC_JulianDay_close(&_mid);
    OOC_Locales_close(&_mid);
    OOC_Strings2_close(&_mid);
    OOC_RT0_close(&_mid);
    OOC_Object_close(&_mid);
    OOC_Exception_close(&_mid);
  }
}

/* --- */
