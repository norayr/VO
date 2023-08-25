#include <JulianDay.oh>
#define JulianDay__daysPerYear 3.6525000000000000E+2
#define JulianDay__daysPerMonth 3.0600100000000001E+1
OOC_CHAR8 JulianDay__UseGregorian;
static OOC_REAL64 JulianDay__startGregor;

/* run-time meta data */
static RT0__ModuleDesc _mid;
static RT0__ModuleDesc _mid = { (OOC_CHAR8*)"JulianDay", (RT0__Struct[]) { NULL }, 0 };

extern void OOC_JulianDay_open(RT0__Module client) {
  if (_mid.openCount == 0) {
    OOC_RT0_open(&_mid);
    OOC_Object_open(&_mid);
    OOC_Exception_open(&_mid);

    RT0__RegisterModule(&_mid);
    OOC_JulianDay_init();
  }
  _mid.openCount++;
}
extern void OOC_JulianDay_close(RT0__Module client) {
  _mid.openCount--;
  if (_mid.openCount == 0) { 
    OOC_JulianDay_destroy();
    RT0__UnregisterModule(&_mid);

    OOC_RT0_close(&_mid);
    OOC_Object_close(&_mid);
    OOC_Exception_close(&_mid);
  }
}

/* --- */
