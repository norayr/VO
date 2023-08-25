MODULE VO:Image:ImageStream:QTImageStream [INTERFACE "C";  
  LINK 
    FILE "QTImageStream.cpp"; 
    LIB "stdc++"; 
<* IF HAVE_PACKAGE_CARBON=TRUE THEN *>
    FRAMEWORK "Carbon"; 
    FRAMEWORK "QuickTime" 
<* END *>

<* IF HAVE_PACKAGE_WINDOWS=TRUE THEN *>
    LIB "qtmlClient"
<* END *>
END];

IMPORT 
  VO:Image:ImageStream;

PROCEDURE NewMovieInputStream* (name : ARRAY OF CHAR) : ImageStream.InputStream;

PROCEDURE NewDigitiserInputStream* (name : ARRAY OF CHAR; w, h : LONGINT) : ImageStream.InputStream;

END VO:Image:ImageStream:QTImageStream.

