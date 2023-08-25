MODULE ObsoleteTest;

IMPORT (* Not obsolete, but not currently part of the library *)
       D := VO:Plot,

       (* not obsolete, but not part of the shared library *)
       E := VO:ClipTest,
       F := VO:DrawTest,

       Out;

BEGIN
  Out.String("Works :-)"); Out.Ln;
END ObsoleteTest.
