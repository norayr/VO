#include <Strings2.d>
#include <__oo2c.h>
#include <setjmp.h>

void Strings2__AppendChar(OOC_CHAR8 ch, OOC_CHAR8 dst[], OOC_LEN dst_0d) {
  register OOC_INT64 i0,i1;

  i0 = Strings__Length((void*)(OOC_INT64)dst, dst_0d);
  i1 = i0<(dst_0d-1);
  if (!i1) goto l3;
  i1 = ch;
  *(OOC_UINT8*)((OOC_INT64)dst+(_check_index(i0, dst_0d, OOC_UINT16, 324))) = i1;
  *(OOC_UINT8*)((OOC_INT64)dst+(_check_index((i0+1), dst_0d, OOC_UINT16, 346))) = 0u;
l3:
  return;
  ;
}

void Strings2__InsertChar(OOC_CHAR8 ch, OOC_INT16 pos, OOC_CHAR8 dst[], OOC_LEN dst_0d) {
  register OOC_INT64 i0;
  OOC_CHAR8 src[2];

  i0 = ch;
  *(OOC_UINT8*)((OOC_INT64)src+(_check_index(0, 2, OOC_UINT8, 797))) = i0;
  *(OOC_UINT8*)((OOC_INT64)src+(_check_index(1, 2, OOC_UINT8, 811))) = 0u;
  i0 = pos;
  Strings__Insert((void*)(OOC_INT64)src, 2, i0, (void*)(OOC_INT64)dst, dst_0d);
  return;
  ;
}

OOC_INT16 Strings2__PosChar(OOC_CHAR8 ch, const OOC_CHAR8 str__ref[], OOC_LEN str_0d) {
  register OOC_INT64 i0,i1,i2;
  OOC_ALLOCATE_VPAR(str,OOC_CHAR8 ,str_0d)

  OOC_INITIALIZE_VPAR(str__ref,str,OOC_CHAR8 ,str_0d)
  i0 = ch;
  i1=0;
l1_loop:
  i2 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(i1, str_0d, OOC_UINT16, 1181)));
  i2 = i2==i0;
  if (!i2) goto l3;
  goto l8;
l3:
  i2 = *(OOC_UINT8*)((OOC_INT64)str+(_check_index(i1, str_0d, OOC_UINT16, 1229)));
  i2 = i2==0u;
  if (!i2) goto l5;
  goto l6;
l5:
  i1 = i1+1;
  
  goto l1_loop;
l6:
  return (-1);
  
  goto l1_loop;
l8:
  return i1;
  
  goto l1_loop;
l11:
  ;
}

OOC_CHAR8 Strings2__Match(const OOC_CHAR8 pat__ref[], OOC_LEN pat_0d, const OOC_CHAR8 s__ref[], OOC_LEN s_0d) {
  register OOC_INT64 i0;
  OOC_ALLOCATE_VPAR(pat,OOC_CHAR8 ,pat_0d)
  OOC_ALLOCATE_VPAR(s,OOC_CHAR8 ,s_0d)
  OOC_INT16 lenPattern;
  OOC_INT16 lenSource;
  auto OOC_CHAR8 Strings2__Match_RecMatch(OOC_CHAR8 src[], OOC_LEN src_0d, OOC_INT16 posSrc, OOC_CHAR8 pat[], OOC_LEN pat_0d, OOC_INT16 posPat);
    
    OOC_CHAR8 Strings2__Match_RecMatch(OOC_CHAR8 src[], OOC_LEN src_0d, OOC_INT16 posSrc, OOC_CHAR8 pat[], OOC_LEN pat_0d, OOC_INT16 posPat) {
      register OOC_INT64 i0,i1,i2,i3,i4;

l1_loop:
      i0 = posSrc;
      i1 = lenSource;
      i2 = i0==i1;
      if (i2) goto l4;
      i2=0u;
      goto l6;
l4:
      i2 = lenPattern;
      i3 = posPat;
      i2 = i3==i2;
      
l6:
      if (!i2) goto l7;
      goto l39;
l7:
      i2 = lenPattern;
      i3 = posPat;
      i4 = i3==i2;
      if (!i4) goto l9;
      goto l37;
l9:
      i4 = *(OOC_UINT8*)((OOC_INT64)pat+(_check_index(i3, pat_0d, OOC_UINT16, 2254)));
      i4 = i4==42u;
      if (i4) goto l20;
      i1 = *(OOC_UINT8*)((OOC_INT64)pat+(_check_index(i3, pat_0d, OOC_UINT16, 2586)));
      i1 = i1!=63u;
      if (i1) goto l14;
      i1=0u;
      goto l16;
l14:
      i1 = *(OOC_UINT8*)((OOC_INT64)pat+(_check_index(i3, pat_0d, OOC_UINT16, 2608)));
      i2 = *(OOC_UINT8*)((OOC_INT64)src+(_check_index(i0, src_0d, OOC_UINT16, 2622)));
      i1 = i1!=i2;
      
l16:
      if (!i1) goto l17;
      goto l18;
l17:
      posSrc = (i0+1);
      posPat = (i3+1);
      goto l1_loop;
l18:
      return 0u;
      goto l1_loop;
l20:
      i2 = i3==(i2-1);
      if (!i2) goto l22;
      goto l34;
l22:
      i2 = i0<=i1;
      if (i2) goto l24;
      goto l33;
l24:
      i2 = i3+1;
      
l25_loop:
      i3 = Strings2__Match_RecMatch((void*)(OOC_INT64)src, src_0d, i0, (void*)(OOC_INT64)pat, pat_0d, i2);
      if (!i3) goto l28;
      return 1u;
l28:
      i0 = i0+1;
      i3 = i0<=i1;
      if (i3) goto l25_loop;
l33:
      return 0u;
      goto l1_loop;
l34:
      return 1u;
      goto l1_loop;
l37:
      return 0u;
      goto l1_loop;
l39:
      return 1u;
      goto l1_loop;
l42:
      ;
    }


  OOC_INITIALIZE_VPAR(pat__ref,pat,OOC_CHAR8 ,pat_0d)
  OOC_INITIALIZE_VPAR(s__ref,s,OOC_CHAR8 ,s_0d)
  i0 = Strings__Length((void*)(OOC_INT64)pat, pat_0d);
  lenPattern = i0;
  i0 = Strings__Length((void*)(OOC_INT64)s, s_0d);
  lenSource = i0;
  i0 = Strings2__Match_RecMatch((void*)(OOC_INT64)s, s_0d, 0, (void*)(OOC_INT64)pat, pat_0d, 0);
  return i0;
  ;
}

void OOC_Strings2_init(void) {

  return;
  ;
}

void OOC_Strings2_destroy(void) {
}

/* --- */
