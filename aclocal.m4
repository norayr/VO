# OOC_CHECK_LIB(LIBRARY, FUNCTION,
#               [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND],
#               [OTHER-LIBRARIES])
# ------------------------------------------------------
#
# This macro is a wrapper around AC_CHECK_LIB that additionally
# sets the variable `ooc_have_lib_LIBRARY' to TRUE or FALSE, depending
# on the outcome.  AC_SUBST is called on `ooc_have_lib_LIBRARY'.
AC_DEFUN(OOC_CHECK_LIB,
[AC_CHECK_LIB([$1],[$2],[$3],[$4],[$5])
if test "$ac_cv_lib_$1_$2" = yes; then
   ooc_have_lib_$1=TRUE
else
   ooc_have_lib_$1=FALSE
fi
AC_SUBST(ooc_have_lib_$1)])

# OOC_CHECK_LIB_INC(LIBRARY, FUNCTION, HEADER, INCLUDES,
#                   [OTHER-LIBRARIES])
# ------------------------------------------------------
#
# This macro is a wrapper around AC_CHECK_LIB that additionally
# sets the variable `ooc_have_lib_LIBRARY' to TRUE or FALSE, depending
# on the outcome.  AC_SUBST is called on `ooc_have_lib_LIBRARY'.
AC_DEFUN(OOC_CHECK_LIB_INC,
[ooc_have_lib_$1=FALSE
AC_CHECK_LIB([$1],[$2],[],[],[$5])
if test "$ac_cv_lib_$1_$2" = yes; then
   AC_CHECK_HEADERS([$3],[ooc_have_lib_$1=TRUE],[],[$4])
fi
AC_SUBST(ooc_have_lib_$1)])

# OOC_TEST_PACKAGE(PACKAGE, VARIABLE)
# Checks, if an oo2c package is installed or not
AC_DEFUN(OOC_TEST_PACKAGE,
[AC_MSG_CHECKING(for package '$1')
ooc_call='$OOC --package-installed [$1]'
if AC_TRY_EVAL(ooc_call); then
AC_MSG_RESULT([yes])
AC_SUBST($2,[TRUE])
else
AC_MSG_RESULT([no])
AC_SUBST($2,[FALSE])
fi
])
