dnl Process this file with autoconf to produce a configure script.
AC_PREREQ(2.53)
AC_INIT(VisualOberon,0.0,tim@teulings.org)
AC_CONFIG_SRCDIR(src/VisualOberonLib.Mod)

AC_SUBST(OFLAGS)

dnl checks for programs
AC_PATH_PROG(OOC,oo2c,oo2c)

OOC_CHECK_LIB(m,sin,,,)
OOC_CHECK_LIB(z,gzopen,,,)

OOC_CHECK_LIB_INC(png,png_get_valid,[png.h],[],[-lm -lz])
OOC_CHECK_LIB_INC(jpeg,jpeg_read_scanlines,[jpeglib.h],[],)
OOC_CHECK_LIB_INC(tiff,TIFFOpen,[tiffio.h],[],[-lz -lm -ljpeg])
OOC_CHECK_LIB_INC(gif,DGifOpenFileName,[gif_lib.h],[],[])

OOC_TEST_PACKAGE(libX11,ooc_have_package_x11)
OOC_TEST_PACKAGE(libCurses,ooc_have_package_curses)
OOC_TEST_PACKAGE(libCarbon,ooc_have_package_carbon)
OOC_TEST_PACKAGE(libWindows,ooc_have_package_windows)

dnl Create output files.
AC_CONFIG_FILES([Makefile pkginfo.xml])
AC_OUTPUT
