#include <Strings2.oh>
#include <Strings.oh>

/* run-time meta data */
static RT0__ModuleDesc _mid;
RT0__StructDesc _td_Strings2__130 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Strings2__443 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Strings2__765 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 2, 2, (1<<RT0__flagAtomic), RT0__strArray };
RT0__StructDesc _td_Strings2__913 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Strings2__1349 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Strings2__1808 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
RT0__StructDesc _td_Strings2__1871 = { (RT0__Struct[]){&RT0__char}, NULL, NULL, &_mid, NULL, 1, 1, (1<<RT0__flagAtomic), RT0__strOpenArray };
static RT0__ModuleDesc _mid = { (OOC_CHAR8*)"Strings2", (RT0__Struct[]) { NULL }, 0 };

extern void OOC_Strings2_open(RT0__Module client) {
  if (_mid.openCount == 0) {
    OOC_Strings_open(&_mid);
    OOC_RT0_open(&_mid);
    OOC_Object_open(&_mid);
    OOC_Exception_open(&_mid);

    RT0__RegisterModule(&_mid);
    OOC_Strings2_init();
  }
  _mid.openCount++;
}
extern void OOC_Strings2_close(RT0__Module client) {
  _mid.openCount--;
  if (_mid.openCount == 0) { 
    OOC_Strings2_destroy();
    RT0__UnregisterModule(&_mid);

    OOC_Strings_close(&_mid);
    OOC_RT0_close(&_mid);
    OOC_Object_close(&_mid);
    OOC_Exception_close(&_mid);
  }
}

/* --- */
