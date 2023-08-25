MODULE VO:OS:Windows:Display;

(*
    Implementation Classes for visualisation.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

    This module is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with VisualOberon. If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)


IMPORT D    := VO:Base:Display,
       DD   := VO:Base:DragDrop,
       E    := VO:Base:Event,
       O    := VO:Base:Object,
       U    := VO:Base:Util,

       EO   := VO:OS:Windows:Event,

       P    := VO:Prefs:Base,

               VO:Image:Image,

               ChannelFDWrapper,

       S    := IO:Select,

      Codec := XML:UnicodeCodec,
<* PUSH; Warnings:=FALSE *>
               XML:UnicodeCodec:Latin1,
               Latin9,
<* POP *>

       W    := Windows,

       c    := Calendar,
               IO,
               Log,
               Object,
       sc   := SysClock,
       str  := Strings,
       t    := Time,
       RealMath,
       Ascii,
       Exception, ADT:StringBuffer,
       SYSTEM;

(* ============== Implementation classes ============== *)

CONST
  driverName = "Windows";

  (* Size of the various stack arrays *)
  initialStackSize   = 30;
  stackSizeIncrement = 30;

  unicodeEncoding* = "iso10646-1";

TYPE
  Sleep           = POINTER TO SleepDesc;
  SleepDesc       = RECORD (D.SleepDesc)
                      (**
                        This is the class, sleep information are stored in.
                        @code{VO:OS:Display.Display} builds a sorted list of
                        @code{Sleep}s to store all current sleep callbacks in it.
                      *)
                      next   : Sleep;
                      object : O.MsgObject;
                    END;

  Timer           = POINTER TO TimerDesc;
  TimerDesc       = RECORD (D.TimerDesc)
                      next : Timer; (** All @code{Timer}s are single linked and ordered.*)
                      timer : W.UINT;
                    END;


  Channel         = POINTER TO ChannelDesc;
  ChannelDesc     = RECORD (D.ChannelDesc)
                      (**
                        This structure holds information about channels the main
                        event loop should wait for. The display object notifies
                        the given object if the handed channel becomes available
                        (currently this means, there is some data in the channel
                        that can be read, the event loop engine may support event
                        sending on channel getting available for writing in the
                        future, too).
                      *)
                      next   : Channel;
                      object : O.MsgObject;
                    END;

  FontStyle = POINTER TO FontStyleDesc;
  FontStyleDesc = RECORD
                (* per-style font data *)
                hFont : W.HFONT;
                metrics : W.TEXTMETRICA;
              END;

  Font*     = POINTER TO FontDesc;

  FontDesc* = RECORD (D.FontDesc)
                styles : ARRAY D.maxStyleNum OF FontStyle;
              END;

  PointArray   = POINTER TO ARRAY OF W.POINT;

  Window*      = POINTER TO WindowDesc;

  Display*     = POINTER TO DisplayDesc;
  DisplayDesc* = RECORD (D.DisplayDesc)
                    instance     : W.HINSTANCE;
                    hdc-          : W.HDC;

                    (* windowing information *)
                    winList,
                    currentWin   : Window;

                    selectObject,
                    querySelectObject : D.Object;

                    (* timeouts *)
                    timerList    : Timer;
                    contextTimer : D.Timer; (** The @code{Timer} for context help *)
                    refreshTimer : D.Timer; (** The @code{Timer} for optimized refreshing *)
                    contextHelp  : BOOLEAN;

                    (* sleep stuff *)
                    sleepList    : Sleep;

                    (* fd stuff *)
                    channelList  : Channel;

                    fdChannel    : ChannelFDWrapper.Channel;
                    selector     : IO.Selector;

                    exit         : BOOLEAN;

                    fontList : D.FontList;

                    multiClickTime : LONGINT;

                    (* for speed up *)
                    pointArray    : PointArray;
                    bufferUCS2    : POINTER TO ARRAY OF LONGCHAR;
                 END;

  Bitmap*     = POINTER TO BitmapDesc;
  BitmapDesc* = RECORD (D.BitmapDesc)
                      bitmap- : W.HBITMAP;
                      dc - : W.HDC;
                  END;

  DrawInfo*     = POINTER TO DrawInfoDesc;

  ClipEntryDesc = RECORD
                    region  : W.HRGN;
                    draw : DrawInfo;
                  END;


  PenColorDesc  = RECORD
                    color : D.Color;
                    count : LONGINT;
                    brush : W.HBRUSH;
                    pen   : W.HPEN;
                  END;

  DrawMode      = POINTER TO DrawModeDesc;
  DrawModeDesc  = RECORD
                    next : DrawMode;
                    mode : LONGINT;
                  END;

  PenStyle      = POINTER TO PenStyleDesc;
  PenStyleDesc  = RECORD
                    next  : PenStyle;
                    size,
                    mode,
                    cap,
                    join  : LONGINT;
                  END;

  PenDash       = POINTER TO PenDashDesc;
  PenDashDesc   = RECORD
                    next : PenDash;
                    list : POINTER TO ARRAY OF CHAR;
                    mode : LONGINT;
                  END;

  Pattern       = POINTER TO PatternDesc;
  PatternDesc   = RECORD
                    next   : Pattern;
                    pixMap : W.HBITMAP;
                    mode   : LONGINT;
                  END;

  FontEntryDesc = RECORD
                    font  : Font;
                    style : SET;
                    count : LONGINT;
                  END;

  ClipStack = POINTER TO ARRAY OF ClipEntryDesc;
  PenStack  = POINTER TO ARRAY OF PenColorDesc;
  FontStack = POINTER TO ARRAY OF FontEntryDesc;

  DrawInfoDesc* = RECORD (D.DrawInfoDesc)
                    clipStack    : ClipStack;
                    clipPos      : LONGINT;

                    fPenStack    : PenStack;
                    fPenPos      : LONGINT;

                    bPenStack    : PenStack;
                    bPenPos      : LONGINT;

                    fontStack    : FontStack;
                    fontPos      : LONGINT;

                    styleStack   : PenStyle;
                    dashStack    : PenDash;
                    patternStack : Pattern;
                    modeStack    : DrawMode;

                    dc-          : W.HDC;

                    dashStyle : POINTER TO ARRAY OF W.DWORD;
                  END;

  WindowDesc* = RECORD (D.WindowImplDesc)
                  last,next      : Window;

                  draw           : DrawInfo;
                  grab,
                  exit           : BOOLEAN;

                  (* For double click *)
                  oldButton,
                  lastButton,
                  thisButton     : EO.ButtonEventDesc;

                  oldPress,
                  lastPress,
                  thisPress      : LONGINT;
                  window         : W.HWND;

                  wOff,hOff,
                  wDelta,hDelta  : LONGINT; (* border of window *)
                  drawn : BOOLEAN;  (* window has been drawn *)
                  queueFocus : BOOLEAN;  (* focus event is queued to be sent following redraw. *)
                END;

  FactoryImpl*      = POINTER TO FactoryImplDesc;
  FactoryImplDesc*  = RECORD (D.FactoryDesc)
                      END;

  DisplayPrefs     = POINTER TO DisplayPrefsDesc;
  DisplayPrefsDesc = RECORD (D.DisplayPrefsDesc)
                       refreshTimer : LONGINT;
                     END;

VAR
  class  : W.WNDCLASS;
  factory- : FactoryImpl;

  timerMsg : D.TimerMsg;

  (* Misc utilities *)

  (* convert a null-terminated character array into STRING. LPSTR points to an
     array with no length descriptor, so this cannot directly be used where
     strings are normally allowed. *)

  PROCEDURE CopyWin32String(result : W.LPSTR) : STRING;
  VAR
    i : LONGINT;
    buf : StringBuffer.StringBuffer;
  BEGIN
    buf := StringBuffer.New("");
    i := 0;
    WHILE result[i] # 0X DO
      buf.AppendLatin1Char(result[i]);
      INC(i);
    END;
    RETURN buf.ToString();
  END CopyWin32String;

  (* Print description of Win32 error *)

  PROCEDURE Error* (msg : ARRAY OF CHAR);
  VAR
    result : W.LPSTR;
    error : LONGINT;
    code : LONGINT;
  BEGIN
    result := NIL;
    Log.String("Error", msg);
    error := W.GetLastError();
    Log.Hex("Win32 code", error);
    code := W.FormatMessageA(
      W.FORMAT_MESSAGE_ALLOCATE_BUFFER + W.FORMAT_MESSAGE_FROM_SYSTEM + W.FORMAT_MESSAGE_IGNORE_INSERTS,
      0,
      error,
      W.LANG_NEUTRAL + W.SUBLANG_DEFAULT * 1024,    (* default language *)
      SYSTEM.VAL(W.LPSTR, SYSTEM.ADR(result)),
      0,
      NIL );
    IF code # 0 THEN
      Log.Object("Message", CopyWin32String(result));
      code := W.LocalFree(SYSTEM.VAL(LONGINT, result));
    END;
  END Error;

  PROCEDURE RGB(r,g,b : LONGINT):W.COLORREF;
  BEGIN
    RETURN b*256*256+g*256+r;
  END RGB;

  PROCEDURE LOWORD(long : W.LONG):W.LONG;
  BEGIN
    RETURN long MOD (256*256);
  END LOWORD;

  PROCEDURE HIWORD(long : W.LONG):W.LONG;
  BEGIN
    RETURN long DIV (256*256);
  END HIWORD;

  PROCEDURE TOLONG(i : HUGEINT) : LONGINT;
  BEGIN
    RETURN SHORT(i);
  END TOLONG;

  PROCEDURE (p : DisplayPrefs) EvaluateColor;
  BEGIN
    IF D.display.colorMode=D.monochromeMode THEN
      p.colors[D.backgroundColorIndex]:="white";
      p.colors[D.tableBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.tableBackground2ColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.textBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.buttonBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.tableTextColorIndex]:="black";
      p.colors[D.halfShineColorIndex]:="black";
      p.colors[D.halfShadowColorIndex]:="black";
      p.colors[D.textColorIndex]:="black";
      p.colors[D.shineColorIndex]:="black";
      p.colors[D.shadowColorIndex]:="black";
      p.colors[D.fillColorIndex]:="black";
      p.colors[D.fillTextColorIndex]:="white";
      p.colors[D.warnColorIndex]:="black";
      p.colors[D.disabledColorIndex]:="black";
      p.colors[D.focusColorIndex]:="black";
      p.colors[D.blackColorIndex]:="black";
      p.colors[D.whiteColorIndex]:="white";
      p.colors[D.helpBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
    ELSE
      p.colors[D.backgroundColorIndex]:="grey70";
      p.colors[D.tableBackgroundColorIndex]:="white";
      p.colors[D.tableBackground2ColorIndex]:="grey95";
      p.colors[D.tableTextColorIndex]:="black";
      p.colors[D.textBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.buttonBackgroundColorIndex]:=p.colors[D.textBackgroundColorIndex];
      p.colors[D.textColorIndex]:="black";
      p.colors[D.shineColorIndex]:="grey95";
      p.colors[D.halfShineColorIndex]:="grey82";
      p.colors[D.halfShadowColorIndex]:="grey45";
      p.colors[D.shadowColorIndex]:="grey20";
      p.colors[D.fillColorIndex]:="royal blue";
      p.colors[D.fillTextColorIndex]:="white";
      p.colors[D.warnColorIndex]:="red";
      p.colors[D.disabledColorIndex]:="grey20";
      p.colors[D.focusColorIndex]:="grey30";
      p.colors[D.blackColorIndex]:="black";
      p.colors[D.whiteColorIndex]:="white";
      p.colors[D.helpBackgroundColorIndex]:="light yellow";
    END;
  END EvaluateColor;

  PROCEDURE (p : DisplayPrefs) Init*;

    (**
      Initializes an instance.
    *)

  CONST
    ProportionalFontName = "MS Sans Serif";
    FixedFontName = "Courier New";

  VAR
    x : LONGINT;

  BEGIN
    p.Init^;

    p.EvaluateColor;

    p.localeCodecFactory:=Codec.GetFactory("ISO-8859-1");
    p.localeCodec:=p.localeCodecFactory.NewCodec();

    FOR x:=0 TO D.fontCount-1 DO
      p.fonts[x]:=D.factory.CreateFont();

      p.fonts[x].features:={D.fontName,D.fontHeight,D.fontCharSet};

      IF (x>=D.tinyFontIndex) & (x<=D.HUGEFontIndex) THEN
        NEW(p.fonts[x].name,str.Length(ProportionalFontName)+1);
        COPY(ProportionalFontName,p.fonts[x].name^);
      ELSE
        NEW(p.fonts[x].name,str.Length(FixedFontName)+1);
        COPY(FixedFontName,p.fonts[x].name^);
      END;

      NEW(p.fonts[x].charSet,str.Length(unicodeEncoding)+1);
      COPY(unicodeEncoding,p.fonts[x].charSet^);
    END;

    p.fonts[D.tinyFontIndex].pixelHeight:=8;
    p.fonts[D.scriptFontIndex].pixelHeight:=8;
    p.fonts[D.footnoteFontIndex].pixelHeight:=10;
    p.fonts[D.smallFontIndex].pixelHeight:=10;
    p.fonts[D.normalFontIndex].pixelHeight:=12;
    p.fonts[D.largeFontIndex].pixelHeight:=14;
    p.fonts[D.LargeFontIndex].pixelHeight:=18;
    p.fonts[D.LARGEFontIndex].pixelHeight:=18;
    p.fonts[D.hugeFontIndex].pixelHeight:=24;
    p.fonts[D.HUGEFontIndex].pixelHeight:=28;
    p.fonts[D.smallFixedFontIndex].pixelHeight:=10;
    p.fonts[D.fixedFontIndex].pixelHeight:=13;
    p.fonts[D.hugeFixedFontIndex].pixelHeight:=14;

    p.contextTimer:=2500;
    p.refreshTimer:=0;
  END Init;

  PROCEDURE (d : Display) EnlargeUCS2Buffer(len : LONGINT);

  BEGIN
    IF (d.bufferUCS2=NIL) OR (LEN(d.bufferUCS2^)<len) THEN
      NEW(d.bufferUCS2,len);
    END;
  END EnlargeUCS2Buffer;

  PROCEDURE (d : Display) EnlargePointArray(len : LONGINT);
  BEGIN
    IF (d.pointArray=NIL) OR (LEN(d.pointArray^)<len) THEN
      NEW(d.pointArray,len);
    END;
  END EnlargePointArray;

  PROCEDURE (d : Display) CopyPoints(VAR in : ARRAY OF D.PointDesc; count : LONGINT);
    VAR
      i : LONGINT;
      array : PointArray;
    BEGIN
      d.EnlargePointArray(count);
      FOR i := 0 TO count-1 DO
        d.pointArray[i].x := in[i].x;
        d.pointArray[i].y := in[i].y;
      END;
    END CopyPoints;


  (* -------- font stuff ------------- *)

  PROCEDURE (font : Font) Init*;
  VAR i : LONGINT;
  BEGIN
    font.height:=1;
    font.descent:=1;
    font.ascent:=0;

    FOR i := 0 TO D.maxStyleNum - 1 DO
      font.styles[i] := NIL;
    END;
  END Init;

  PROCEDURE (font : Font) GetStyle*(style : SET) : FontStyle;
  VAR
    info  : W.LOGFONT;
    hFont : W.HFONT;
    pos : LONGINT;
    d : Display;
    s : FontStyle;
    old : W.HGDIOBJ;
  BEGIN
    pos := SYSTEM.VAL(LONGINT, style * D.styleMask);
    s := font.styles[pos];
    IF (s # NIL) THEN
      IF (s.hFont # 0) THEN RETURN s ELSE RETURN NIL END;
    END;

    NEW(s);
    font.styles[pos] := s;
    s.hFont := 0;

    (* Initialisation of default fields *)
    info.lfHeight:=0;
    info.lfWidth:=0;
    info.lfEscapement:=0;
    info.lfOrientation:=0;
    info.lfWeight:=W.FW_NORMAL;
    info.lfItalic:=0X;
    info.lfUnderline:=0X;
    info.lfStrikeOut:=0X;
    info.lfCharSet:=CHR(W.DEFAULT_CHARSET);
    info.lfOutPrecision:=CHR(W.OUT_DEFAULT_PRECIS);
    info.lfClipPrecision:=CHR(W.CLIP_DEFAULT_PRECIS);
    info.lfQuality:=CHR(W.DEFAULT_QUALITY);
    info.lfPitchAndFamily:=CHR(W.DEFAULT_PITCH);
    info.lfFaceName[0]:=0X;

    IF D.fontHeight IN font.features THEN
      info.lfHeight := font.pixelHeight;
    END;
    IF D.fontName IN font.features THEN
      (* FIXME. Check length < 32 *)
      COPY(font.name^, info.lfFaceName);
    END;
    IF D.bold IN style THEN
      info.lfWeight := W.FW_BOLD;
    END;
    IF style * {D.italic, D.slanted} # {} THEN
      info.lfItalic:= 1X;
    END;
    IF D.underlined IN style THEN
      info.lfUnderline := 1X;
    END;

    hFont := W.CreateFontIndirectA(info);
    IF hFont # 0 THEN
      d := D.display(Display);
      old := W.SelectObject(d.hdc, hFont);
      IF W.GetTextMetricsA(d.hdc, s.metrics)=0 THEN
        Log.LongInt("Failed to get font metrics", W.GetLastError());
      ELSE
        s.hFont := hFont;
        (* HACK: each style's metrics may be different *)
        font.height:=s.metrics.tmHeight;
        font.ascent:=s.metrics.tmAscent;
        font.descent:=s.metrics.tmDescent;
      END;
      old := W.SelectObject(d.hdc, old);
    END;
    RETURN s;
  END GetStyle;

  PROCEDURE (font : Font) Load*():D.Font;
  BEGIN
    IF font.GetStyle({}) # NIL THEN
      RETURN font
    ELSE
      RETURN NIL
    END
  END Load;

  PROCEDURE (font : Font) TextWidth*(text : ARRAY OF CHAR; length : LONGINT; style : SET):LONGINT;

  VAR
    size : W.SIZE;
    d : Display;
    old : W.HGDIOBJ;
    s : FontStyle;
  BEGIN
    s := font.GetStyle(style);
    IF (s # NIL) THEN
      d := D.display(Display);
      old := W.SelectObject(d.hdc, s.hFont);
      IF W.GetTextExtentPoint32A(d.hdc,text,length,size)#0 THEN END;
      old := W.SelectObject(d.hdc, old);
      RETURN size.cx;
    ELSE
      RETURN 0;
    END;
  END TextWidth;

  PROCEDURE (font : Font) LongTextWidth*(text : ARRAY OF LONGCHAR; length : LONGINT; style : SET):LONGINT;
  VAR
    size : W.SIZE;
    d : Display;
    old : W.HGDIOBJ;
    s : FontStyle;
  BEGIN
    s := font.GetStyle(style);
    IF (s # NIL) THEN
      d := D.display(Display);
      old := W.SelectObject(d.hdc, s.hFont);
      IF W.GetTextExtentPoint32W(d.hdc,text,length,size)#0 THEN END;
      old := W.SelectObject(d.hdc, old);
      RETURN size.cx;
    ELSE
      RETURN 0;
    END;
  END LongTextWidth;

  PROCEDURE (font : Font) StrWidth*(text : STRING; style : SET):LONGINT;
  VAR
    str8  : Object.CharsLatin1;
    str16 : Object.CharsUTF16;
  BEGIN
    WITH text
      : Object.String8 DO
      str8:=text.CharsLatin1();
      RETURN font.TextWidth(str8^,text.length,style);
    | text : Object.String16 DO
      str16:=text.CharsUTF16();
      RETURN font.LongTextWidth(str16^,text.length,style);
    END;
  END StrWidth;

  PROCEDURE (font : Font) TextExtent*(text : ARRAY OF CHAR;
                                      length : LONGINT; style : SET;
                                    VAR extent : D.FontExtentDesc);
  VAR
    size : W.SIZE;
    d : Display;
    old : W.HGDIOBJ;
    s : FontStyle;
  BEGIN
    s := font.GetStyle(style);
    IF (s # NIL) THEN
      d := D.display(Display);
      old := W.SelectObject(d.hdc, s.hFont);
      IF W.GetTextExtentPoint32A(d.hdc,text,length,size)#0 THEN END;
      extent.lbearing:=0;
      extent.rbearing:=size.cx;
      extent.width:=size.cx;
      extent.height:=size.cy;
      extent.ascent:=s.metrics.tmAscent;
      extent.descent:=s.metrics.tmDescent;
      old := W.SelectObject(d.hdc, old);
    ELSE
    END;
  END TextExtent;

  PROCEDURE (font : Font) LongTextExtent*(text : ARRAY OF LONGCHAR;
                                          length : LONGINT; style : SET;
                                          VAR extent : D.FontExtentDesc);

  VAR
    size : W.SIZE;
    d : Display;
    old : W.HGDIOBJ;
    s : FontStyle;
  BEGIN
    s := font.GetStyle(style);
    IF (s # NIL) THEN
      d := D.display(Display);
      old := W.SelectObject(d.hdc, s.hFont);
      IF W.GetTextExtentPoint32W(d.hdc,text,length,size)#0 THEN END;
      extent.lbearing:=0;
      extent.rbearing:=size.cx;
      extent.width:=size.cx;
      extent.height:=size.cy;
      extent.ascent:=s.metrics.tmAscent;
      extent.descent:=s.metrics.tmDescent;
      old := W.SelectObject(d.hdc, old);
    ELSE
    END;
  END LongTextExtent;

  PROCEDURE (font : Font) StrExtent*(text : STRING;
                                     style : SET;
                                     VAR extent : D.FontExtentDesc);
  VAR
    str8  : Object.CharsLatin1;
    str16 : Object.CharsUTF16;
  BEGIN
    WITH text
      : Object.String8 DO
      str8:=text.CharsLatin1();
      font.TextExtent(str8^,text.length,style, extent);
    | text : Object.String16 DO
      str16:=text.CharsUTF16();
      font.LongTextExtent(str16^,text.length,style, extent);
    END;
  END StrExtent;

  PROCEDURE (font : Font) Free*;

  BEGIN
  END Free;

  (* -------- drawinfo stuff ------------- *)

  PROCEDURE (d : DrawInfo) DrawChar(x,y : LONGINT; char : CHAR);

  BEGIN
    (* TODO *)
  END DrawChar;

  (* ----------- Clipping ---------------- *)

  PROCEDURE (d : DrawInfo) RecalcClipRegion;
    (**
      Recalces the current clipping regions by analysing the
      current clipping stack.
    *)

  VAR
    pos     : LONGINT;
    region  : W.HRGN;
    created : BOOLEAN;

  BEGIN
    region:=0;
    pos:=0;
    created:=FALSE;
    IF d.clipPos>=0 THEN
      WHILE pos<=d.clipPos DO
        IF d.clipStack[pos].region#0 THEN
          IF ~created THEN
            region:=W.CreateRectRgn(0,0,0,0);
            IF W.CombineRgn(region,d.clipStack[pos].region,0,W.RGN_COPY)#0 THEN END;
            created:=TRUE;
          ELSE
            IF W.CombineRgn(region,region,d.clipStack[pos].region,W.RGN_AND)#0 THEN END;
          END;
        END;
        INC(pos);
      END;
    END;

    IF W.SelectClipRgn(d.dc,region)#0 THEN END;
    IF region#0 THEN
      IF W.DeleteObject(region)#0 THEN END;
    END;
  END RecalcClipRegion;

  PROCEDURE (VAR c : ClipEntryDesc) Init(draw : DrawInfo);
  (**
    Initializes a clip entry object.
  *)

  BEGIN
    c.region:=0;
    c.draw:=draw;
  END Init;

  PROCEDURE (VAR c : ClipEntryDesc) Install;
  (**
    Recalcs the clipping rectangle.
  *)

  BEGIN
    c.draw.RecalcClipRegion;
  END Install;

  PROCEDURE (VAR c : ClipEntryDesc) Add(x,y,width,height : LONGINT);
  (**
    adds the given rectangle to the current clip entry.
  *)

   VAR
    region : W.HRGN;

  (* Without the "-1" on width and height, the clipping rectangle
     seems to be too small. I wonder why... *)
  BEGIN
    IF c.region=0 THEN
      c.region:=W.CreateRectRgn(x,y,x+width(*-1*),y+height(*-1*));
    ELSE
      region:=W.CreateRectRgn(x,y,x+width(*-1*),y+height(*-1*));
      IF W.CombineRgn(c.region,c.region,region,W.RGN_OR)#0 THEN END;
      IF W.DeleteObject(region)#0 THEN END;
    END;
    c.draw.RecalcClipRegion;
  END Add;

  PROCEDURE (VAR c : ClipEntryDesc) Sub(x,y,width,height : LONGINT);
  (**
    adds the given rectangle to the current clip entry.
  *)

  BEGIN
    c.draw.RecalcClipRegion;
  END Sub;

  PROCEDURE (VAR c : ClipEntryDesc) Free;
  (**
    Frees the given clip entry.
  *)

  BEGIN
    IF c.region#0 THEN
      IF W.DeleteObject(c.region)#0 THEN END;
    END;
  END Free;

  PROCEDURE (d : DrawInfo) InstallClip*(x,y,w,h : LONGINT);

  VAR
    help : ClipStack;
    pos  : LONGINT;

  BEGIN
    IF d.clipPos>=LEN(d.clipStack^)-1 THEN
      NEW(help,LEN(d.clipStack^)+stackSizeIncrement);
      FOR pos:=0 TO LEN(d.clipStack^)-1 DO
        help[pos]:=d.clipStack[pos];
      END;
      d.clipStack:=help;
    END;
    INC(d.clipPos);

    d.clipStack[d.clipPos].Init(d);
    d.clipStack[d.clipPos].Install;

    d.clipStack[d.clipPos].Add(x,y,w,h);
  END InstallClip;

  PROCEDURE (d : DrawInfo) FreeClip*;
  BEGIN
    Log.Msg("FreeClip");
  END FreeClip;

  PROCEDURE (d : DrawInfo) ReinstallClip*;

  BEGIN
    IF d.clipPos>=0 THEN
      d.clipStack[d.clipPos].Install;
    END;
  END ReinstallClip;

  PROCEDURE (d : DrawInfo) AddRegion*(x,y,width,height : LONGINT);

  BEGIN
    d.clipStack[d.clipPos].Add(x,y,width,height);
  END AddRegion;

  PROCEDURE (d : DrawInfo) SubRegion*(x,y,width,height : LONGINT);

  BEGIN
    d.clipStack[d.clipPos].Sub(x,y,width,height);
  END SubRegion;

  PROCEDURE (d : DrawInfo) GetClipRegion*(VAR x,y,w,h : LONGINT);
  VAR
    rect : W.RECT;

  BEGIN
    IF W.GetClipBox(d.dc,rect)#0 THEN END;
    x:=rect.left;
    y:=rect.top;
    w:=rect.right-rect.left+1;
    h:=rect.bottom-rect.top+1;
  END GetClipRegion;

  PROCEDURE (d : DrawInfo) FreeLastClip*;

  BEGIN
    d.clipStack[d.clipPos].Free;
    DEC(d.clipPos);
    IF d.clipPos>=0 THEN
      d.clipStack[d.clipPos].Install;
    END;
  END FreeLastClip;

  PROCEDURE (d : DrawInfo) Init(dc : W.HDC);
  (**
    Initialize an instance of the  DrawInfo class.
  *)

  BEGIN
    d.dc := dc;

    IF W.SetTextAlign(d.dc,W.TA_BASELINE+W.TA_LEFT)#0 THEN END;
    IF W.SetMapMode(d.dc,W.MM_TEXT)#0 THEN END;

    d.mode:={};

    (* The array stacks *)
    d.fPenPos:=-1;
    NEW(d.fPenStack,initialStackSize);
    d.bPenPos:=-1;
    NEW(d.bPenStack,initialStackSize);
    d.fontPos:=-1;
    NEW(d.fontStack,initialStackSize);
    d.clipPos:=-1;
    NEW(d.clipStack,initialStackSize);

    (* The list stacks *)
    d.styleStack:=NIL;
    d.dashStack:=NIL;
    d.patternStack:=NIL;
    d.modeStack:=NIL;

    NEW(d.dashStyle, 8);
  END Init;

  PROCEDURE (d : DrawInfo) Deinit;
  (**
    Deinitializes the drawInfo
  *)

  BEGIN
    ASSERT(d.fPenPos=-1);
    ASSERT(d.bPenPos=-1);
    ASSERT(d.fontPos=-1);
    ASSERT(d.styleStack=NIL);
    ASSERT(d.dashStack=NIL);
    ASSERT(d.clipPos=-1);
    ASSERT(d.patternStack=NIL);
    ASSERT(d.modeStack=NIL);
  END Deinit;

  PROCEDURE (d : DrawInfo) RecalculatePen;
  TYPE PtrLongInt = POINTER TO ARRAY OF LONGINT;
  VAR
    size : LONGINT;
    info : W.LOGBRUSH;
    mode : LONGINT;
    i, lenStyle : LONGINT;

  BEGIN
    IF d.fPenPos<0 THEN RETURN END;
    IF d.fPenStack[d.fPenPos].pen#0 THEN
      IF W.DeleteObject(d.fPenStack[d.fPenPos].pen)#0 THEN END;
    END;

    IF d.styleStack#NIL THEN
      size:=d.styleStack.size;
      IF d.styleStack.mode=D.roundPen THEN
        mode:=W.PS_ENDCAP_ROUND+W.PS_JOIN_ROUND;
      ELSE
        mode:=W.PS_ENDCAP_FLAT+W.PS_JOIN_BEVEL;
      END;
    ELSE
      size:=1;
      mode:=W.PS_ENDCAP_FLAT+W.PS_JOIN_BEVEL;
    END;

    info.lbStyle:=W.BS_SOLID;
    info.lbColor:=d.fPenStack[d.fPenPos].color;
    info.lbHatch:=0;
    IF d.dashStack#NIL THEN
      (* Copy dash list from CHAR array to W.DWORD array *)
      lenStyle := LEN(d.dashStack.list^);
      IF lenStyle > LEN(d.dashStyle^) THEN
        NEW(d.dashStyle, lenStyle);
      END;
      FOR i := 0 TO lenStyle - 1 DO
        d.dashStyle[i] := ORD(d.dashStack.list[i]);
      END;
      d.fPenStack[d.fPenPos].pen:=W.ExtCreatePen(W.PS_GEOMETRIC+W.PS_USERSTYLE+mode,
                                                 size,
                                                 info,
                                                 lenStyle,
                                                 d.dashStyle[0]);
    ELSE
      d.fPenStack[d.fPenPos].pen:=W.ExtCreatePen(W.PS_GEOMETRIC+mode,
                                                 size,info,0,NIL);
    END;
    IF W.SelectObject(d.dc,d.fPenStack[d.fPenPos].pen)#0 THEN END;
  END RecalculatePen;

  PROCEDURE (d : DrawInfo) RecalculateBrush;
  BEGIN
    IF d.bPenPos < 0 THEN RETURN END;
    IF d.bPenStack[d.bPenPos].brush#0 THEN
      IF W.DeleteObject(d.bPenStack[d.bPenPos].brush)#0 THEN END;
    END;

    IF d.patternStack#NIL THEN
      d.bPenStack[d.bPenPos].brush:=W.CreatePatternBrush(d.patternStack.pixMap);
    ELSE
      d.bPenStack[d.bPenPos].brush:=W.CreateSolidBrush(d.bPenStack[d.bPenPos].color);
    END;

    IF W.SelectObject(d.dc,d.bPenStack[d.bPenPos].brush)#0 THEN END;
    IF W.SetBkColor(d.dc,d.bPenStack[d.bPenPos].color)#0 THEN END;
  END RecalculateBrush;

  PROCEDURE (d : DrawInfo) RecalculateBg;

  BEGIN
    IF ((d.patternStack#NIL) & (d.patternStack.mode=D.fgPattern))
    OR ((d.dashStack#NIL) & (d.dashStack.mode=D.fMode)) THEN
      IF W.SetBkMode(d.dc,W.TRANSPARENT)#0 THEN END;
    ELSE
      IF W.SetBkMode(d.dc,W.OPAQUE)#0 THEN END;
    END;
  END RecalculateBg;

  PROCEDURE (d : DrawInfo) PushFont*(font : D.Font; style : SET);
  VAR
    help : FontStack;
    pos  : LONGINT;
    dFont : Font;
    s : FontStyle;
    old : W.HGDIOBJ;
  BEGIN
    IF d.fontPos>=LEN(d.fontStack^)-1 THEN
      NEW(help,LEN(d.fontStack^)+stackSizeIncrement);
      FOR pos:=0 TO LEN(d.fontStack^)-1 DO
        help[pos]:=d.fontStack[pos];
      END;
      d.fontStack:=help;
    END;
    IF (d.fontPos>=0) & (d.fontStack[d.fontPos].font=font)
    &  (d.fontStack[d.fontPos].style=style) THEN
      INC(d.fontStack[d.fontPos].count);
    ELSE
      INC(d.fontPos);

      dFont := font(Font);
      d.fontStack[d.fontPos].font:=dFont;
      d.fontStack[d.fontPos].style:=style;
      d.fontStack[d.fontPos].count:=1;

      s := dFont.GetStyle(style);
      IF (s # NIL) THEN
        old := W.SelectObject(d.dc, s.hFont)
      END;
    END;
  END PushFont;

  PROCEDURE (d : DrawInfo) PopFont*;
  VAR
    s : FontStyle;
    old : W.HGDIOBJ;
  BEGIN
    IF d.fontStack[d.fontPos].count>1 THEN
      DEC(d.fontStack[d.fontPos].count);
    ELSE
      DEC(d.fontPos);
    END;
    IF d.fontPos >= 0 THEN
      s := d.fontStack[d.fontPos].font.GetStyle(d.fontStack[d.fontPos].style);
      IF (s # NIL) THEN
        old := W.SelectObject(d.dc, s.hFont)
      END;
    END;
  END PopFont;

  PROCEDURE (d : DrawInfo) DrawString*(x,y : LONGINT; text : ARRAY OF CHAR; length : LONGINT);
  VAR
    old : W.HGDIOBJ;
  BEGIN
    old:=W.SetBkMode(d.dc,W.TRANSPARENT);
    IF W.TextOutA(d.dc,x,y,text,length)#0 THEN END;
    old:=W.SetBkMode(d.dc,old);
  END DrawString;

  PROCEDURE (d : DrawInfo) DrawLongString*(x,y : LONGINT; text : ARRAY OF LONGCHAR; length : LONGINT);
  VAR
    old : W.HGDIOBJ;
  BEGIN
    old:=W.SetBkMode(d.dc,W.TRANSPARENT);
    IF W.TextOutW(d.dc,x,y,text,length)#0 THEN END;
    old:=W.SetBkMode(d.dc,old);
  END DrawLongString;

  PROCEDURE (d : DrawInfo) DrawFillString*(x,y : LONGINT; text : ARRAY OF CHAR; length : LONGINT);
  VAR
    old : W.HGDIOBJ;
  BEGIN
    old:=W.SetBkMode(d.dc,W.OPAQUE);
    IF W.TextOutA(d.dc,x,y,text,length)#0 THEN END;
    old:=W.SetBkMode(d.dc,old);
  END DrawFillString;

  PROCEDURE (d : DrawInfo) DrawFillLongString*(x,y : LONGINT; text : ARRAY OF LONGCHAR; length : LONGINT);
  VAR
    old : W.HGDIOBJ;
  BEGIN
    old:=W.SetBkMode(d.dc,W.OPAQUE);
    IF W.TextOutW(d.dc,x,y,text,length)#0 THEN END;
    old:=W.SetBkMode(d.dc,old);
  END DrawFillLongString;

  PROCEDURE (d : DrawInfo) PushForeground*(color : D.Color);

  VAR
    help : PenStack;
    pos  : LONGINT;

  BEGIN
    IF d.fPenPos>=LEN(d.fPenStack^)-1 THEN
      NEW(help,LEN(d.fPenStack^)+stackSizeIncrement);
      FOR pos:=0 TO LEN(d.fPenStack^)-1 DO
        help[pos]:=d.fPenStack[pos];
      END;
      d.fPenStack:=help;
    END;

    IF (d.fPenPos>=0) & (d.fPenStack[d.fPenPos].color=color) THEN
      INC(d.fPenStack[d.fPenPos].count);
    ELSE
      INC(d.fPenPos);

      d.fPenStack[d.fPenPos].color:=color;
      d.fPenStack[d.fPenPos].count:=1;
      d.RecalculatePen;
      IF W.SetTextColor(d.dc,color)#0 THEN END;
    END;
  END PushForeground;

  PROCEDURE (d : DrawInfo) PopForeground*;

  BEGIN
    IF d.fPenStack[d.fPenPos].count>1 THEN
      DEC(d.fPenStack[d.fPenPos].count);
    ELSE
      DEC(d.fPenPos);
      IF d.fPenPos >= 0 THEN
        IF W.SetTextColor(d.dc,d.fPenStack[d.fPenPos].color)#0 THEN END;
        d.RecalculatePen;
      END;
    END;
  END PopForeground;

  PROCEDURE SetMode(d : DrawInfo; mode : LONGINT);
  BEGIN
    CASE mode OF
      D.copy:
        IF W.SetROP2(d.dc, W.R2_COPYPEN)#0 THEN END;
    | D.invert:
        IF W.SetROP2(d.dc, W.R2_NOT)#0 THEN END;
    END;
  END SetMode;

  PROCEDURE (d : DrawInfo) PushDrawMode*(mode : LONGINT);
  VAR m : DrawMode;
  BEGIN
    NEW(m);
    m.mode:=mode;
    SetMode(d, mode);
    m.next:=d.modeStack;
    d.modeStack:=m;
  END PushDrawMode;

  PROCEDURE (d : DrawInfo) PopDrawMode*;
  BEGIN
    d.modeStack:=d.modeStack.next;
    IF d.modeStack#NIL THEN
      SetMode(d, d.modeStack.mode);
    ELSE
      SetMode(d, D.copy);
    END;
  END PopDrawMode;


  PROCEDURE (d : DrawInfo) PushBackground*(color : D.Color);

  VAR
    help : PenStack;
    pos  : LONGINT;

  BEGIN
    IF d.bPenPos>=LEN(d.bPenStack^)-1 THEN
      NEW(help,LEN(d.bPenStack^)+stackSizeIncrement);
      FOR pos:=0 TO LEN(d.bPenStack^)-1 DO
        help[pos]:=d.bPenStack[pos];
      END;
      d.bPenStack:=help;
    END;
    IF (d.bPenPos>=0) & (d.bPenStack[d.bPenPos].color=color) THEN
      INC(d.bPenStack[d.bPenPos].count);
    ELSE
      INC(d.bPenPos);

      d.bPenStack[d.bPenPos].color:=color;
      d.bPenStack[d.bPenPos].count:=1;
      d.RecalculateBrush;
    END;
  END PushBackground;

  PROCEDURE (d : DrawInfo) PopBackground*;

  BEGIN
    IF d.bPenStack[d.bPenPos].count>1 THEN
      DEC(d.bPenStack[d.bPenPos].count);
    ELSE
      DEC(d.bPenPos);
      IF d.bPenPos>=0 THEN
        d.RecalculateBrush;
      END;
    END;
  END PopBackground;

  PROCEDURE (d : DrawInfo) PushStyle*(size, mode : LONGINT);
  VAR
    pen  : PenStyle;

  BEGIN
    NEW(pen);
    pen.size:=size;
    pen.mode:=mode;

    pen.next:=d.styleStack;
    d.styleStack:=pen;

    d.RecalculatePen;
  END PushStyle;

  PROCEDURE (d : DrawInfo) PopStyle*;
  BEGIN
    d.styleStack:=d.styleStack.next;
    d.RecalculatePen;
  END PopStyle;

  PROCEDURE (d : DrawInfo) PushDash*(dashList : ARRAY OF CHAR; mode : LONGINT);
  VAR
    dash : PenDash;
    x    : LONGINT;

  BEGIN
    NEW(dash);
    dash.next:=NIL;
    NEW(dash.list,LEN(dashList));
    FOR x:=0 TO LEN(dashList)-1 DO
      dash.list[x]:=dashList[x];
    END;

    dash.mode:=mode;

    dash.next:=d.dashStack;
    d.dashStack:=dash;

    d.RecalculatePen;
    d.RecalculateBg;
  END PushDash;

  PROCEDURE (d : DrawInfo) PopDash*;
  BEGIN
    d.dashStack:=d.dashStack.next;

    d.RecalculatePen;
    d.RecalculateBg;
  END PopDash;

  PROCEDURE (d : DrawInfo) PushPattern*(pattern : ARRAY OF CHAR; width, height : LONGINT; mode : LONGINT);

  VAR
    pat : Pattern;

  BEGIN
    NEW(pat);

    pat.pixMap:=W.CreateBitmap(width,height,1,1,SYSTEM.VAL(LONGINT,SYSTEM.ADR(pattern)));
    IF pat.pixMap=0 THEN
      Log.Msg("Cannot create pimap!");
    END;
    pat.mode:=mode;
    pat.next:=d.patternStack;
    d.patternStack:=pat;

    d.RecalculateBrush;
    d.RecalculateBg;
  END PushPattern;

  PROCEDURE (d : DrawInfo) PopPattern*;

  BEGIN
    IF W.DeleteObject(d.patternStack.pixMap)#0 THEN END;
    d.patternStack:=d.patternStack.next;

    d.RecalculateBrush;
    d.RecalculateBg;
  END PopPattern;

  PROCEDURE (d : DrawInfo) PushBitmap*(bitmap : D.Bitmap; mode : LONGINT);
  VAR
    pat : Pattern;
  BEGIN
    NEW(pat);
    pat.pixMap:=bitmap(Bitmap).bitmap;
    pat.mode:=mode;
    pat.next:=d.patternStack;
    d.patternStack:=pat;

    d.RecalculateBrush;
    d.RecalculateBg;
  END PushBitmap;

  PROCEDURE (d : DrawInfo) PopBitmap*;
  BEGIN
    d.patternStack:=d.patternStack.next;
    d.RecalculateBrush;
    d.RecalculateBg;
  END PopBitmap;

  (* Drawing functions *)

  PROCEDURE (d : DrawInfo) DrawPoint*(x,y : LONGINT);
  BEGIN
    IF W.SetPixel(d.dc,x,y,d.fPenStack[d.fPenPos].color)#0 THEN END;
  END DrawPoint;

  PROCEDURE (d : DrawInfo) DrawLine*(x1,y1,x2,y2 : LONGINT);
  VAR
    old : W.POINT;
  BEGIN
    IF W.MoveToEx(d.dc,x1,y1,old)#0 THEN END;
    IF W.LineTo(d.dc,x2,y2)#0 THEN END;
    IF W.SetPixel(d.dc,x2,y2,d.fPenStack[d.fPenPos].color)#0 THEN END;
  END DrawLine;

  PROCEDURE (d : DrawInfo) DrawRectangle*(x,y,width,height : LONGINT);
  VAR x1, y1 : LONGINT; res : W.BOOL;
  BEGIN
    x1 := x + width - 1;
    y1 := y + height - 1;
    res := W.MoveToEx(d.dc, x, y, NIL);
    res := W.LineTo(d.dc, x1, y);
    res := W.LineTo(d.dc, x1, y1);
    res := W.LineTo(d.dc, x, y1);
    res := W.LineTo(d.dc, x, y);
  END DrawRectangle;

  PROCEDURE (d : DrawInfo) FillRectangle*(x,y,width,height : LONGINT);
  VAR
    brush : W.HBRUSH;
    rect  : W.RECT;
  BEGIN
    IF (d.patternStack#NIL) & (d.bPenPos>=0) THEN
      brush:=d.bPenStack[d.bPenPos].brush;
    ELSE
      brush:=W.CreateSolidBrush(d.fPenStack[d.fPenPos].color);
    END;
    (* brush:=W.CreateSolidBrush(d.fPenStack[d.fPenPos].color); *)

    rect.left:=x;
    rect.top:=y;
    rect.right:=x+width;
    rect.bottom:=y+height;
    IF ((d.patternStack#NIL) & (d.patternStack.mode=D.fgPattern)) THEN
      IF W.PatBlt(d.dc,x,y,width,height,0FA0089H)#0 THEN END;
    ELSE
      IF W.FillRect(d.dc,rect,brush)#0 THEN END;
    END;

    IF d.patternStack=NIL THEN
      IF W.DeleteObject(brush)#0 THEN END;
    END;
  END FillRectangle;

  PROCEDURE (d : DrawInfo) FillRectangleAlpha*(alpha : LONGINT; x,y,width,height : LONGINT);

  BEGIN
    d.FillRectangle(x,y,width,height);
  END FillRectangleAlpha;

  PROCEDURE (d : DrawInfo) InvertRectangle*(x,y,width,height : LONGINT);

  BEGIN
  END InvertRectangle;

  PROCEDURE (d : DrawInfo) DrawArc*(x,y,width,height,angle1,angle2 : LONGINT);
  VAR
    a,b   : REAL;
    sx,sy,
    ex,ey : LONGINT;
    t     : LONGINT;
  BEGIN
    IF (angle1=0) & (angle2=360*64) THEN
      IF W.Arc(d.dc,x,y,x+width,y+height,0,0,0,0)#0 THEN END;
    ELSE
      (* Transformation to windows: absolute angle *)
      angle2:=angle1+angle2;

      (* Swap angles, if necessary *)
      IF angle1>angle2 THEN
        t:=angle2;
        angle2:=angle1;
        angle1:=t;
      END;

      (* Calculate radials *)
      a:=((angle1 DIV 64)*RealMath.pi)/180.0;
      b:=((angle2 DIV 64)*RealMath.pi)/180.0;

      sx:=x+ width DIV 2  +ENTIER(100*RealMath.cos(a));
      sy:=y+ height DIV 2 -ENTIER(100*RealMath.sin(a));
      ex:=x+ width DIV 2  +ENTIER(100*RealMath.cos(b));
      ey:=y+ height DIV 2 -ENTIER(100*RealMath.sin(b));

      IF W.Arc(d.dc,x,y,x+width,y+height,sx,sy,ex,ey)#0 THEN END;
    END;
  END DrawArc;

  PROCEDURE (d : DrawInfo) FillArc*(x,y,width,height,angle1,angle2 : LONGINT);
  VAR
    brush,old : W.HBRUSH;
    a,b       : REAL;
    sx,sy,
    ex,ey     : LONGINT;
    t         : LONGINT;

  BEGIN
    brush:=W.CreateSolidBrush(d.fPenStack[d.fPenPos].color);
    old:=W.SelectObject(d.dc,brush);

    IF (angle1=0) & (angle2=360*64) THEN
      IF W.Ellipse(d.dc,x,y,x+width,y+height)#0 THEN END;
    ELSE
      (* Transformation to windows: absolute angle *)
      angle2:=angle1+angle2;

      (* Swap angles, if necessary *)
      IF angle1>angle2 THEN
        t:=angle2;
        angle2:=angle1;
        angle1:=t;
      END;

      (* Calculate radials *)
      a:=((angle1 DIV 64)*RealMath.pi)/180.0;
      b:=((angle2 DIV 64)*RealMath.pi)/180.0;

      sx:=x+ width DIV 2  +ENTIER(100*RealMath.cos(a));
      sy:=y+ height DIV 2 -ENTIER(100*RealMath.sin(a));
      ex:=x+ width DIV 2  +ENTIER(100*RealMath.cos(b));
      ey:=y+ height DIV 2 -ENTIER(100*RealMath.sin(b));

      IF W.Pie(d.dc,x,y,x+width,y+height,sx,sy,ex,ey)#0 THEN END;
    END;

    IF W.SelectObject(d.dc,old)#0 THEN END;
    IF W.DeleteObject(brush)#0 THEN END;
  END FillArc;

  PROCEDURE (d : DrawInfo) FillPolygon*(points : ARRAY OF D.PointDesc;
                                        count : LONGINT);
   VAR
    brush,old : W.HBRUSH;
    wpoints : PointArray;
    res : W.BOOL;
    i : LONGINT;
    dd : Display;

  BEGIN
    dd := D.display(Display);
    brush:=W.CreateSolidBrush(d.fPenStack[d.fPenPos].color);
    old:=W.SelectObject(d.dc,brush);

    dd.CopyPoints(points, count);
    res := W.Polygon(d.dc, dd.pointArray[0], count);
    res := W.SelectObject(d.dc,old);
    res := W.DeleteObject(brush);
  END FillPolygon;

  PROCEDURE (d : DrawInfo) CopyArea*(sX,sY,width,height,dX,dY : LONGINT);
  BEGIN
    IF W.BitBlt(d.dc,dX,dY,width,height,d.dc,sX,sY,W.SRCCOPY)#0 THEN END;
  END CopyArea;

  PROCEDURE (d : DrawInfo) CopyFromBitmap*(bitmap : D.Bitmap;
                                               sX,sY,width,height,dX,dY : LONGINT);

  VAR
    b : Bitmap;
  BEGIN
    b := bitmap(Bitmap);
    IF W.BitBlt(d.dc, dX, dY, width, height,
      b.dc, sX, sY, W.SRCCOPY) # W.TRUE THEN
      Error("CopyFromBitmap");
    END;
  END CopyFromBitmap;

  PROCEDURE (d : DrawInfo) CopyToBitmap*(sX,sY,width,height,dX,dY : LONGINT;
                                             bitmap : D.Bitmap);
  VAR
    b : Bitmap;
  BEGIN
    b := bitmap(Bitmap);
    IF W.BitBlt(b.dc, dX, dY, width, height,
      d.dc, sX, sY, W.SRCCOPY) # W.TRUE THEN
      Error("CopyToBitmap");
    END;
  END CopyToBitmap;

  (* ------------ Data Exchange stuff --------------- *)

  PROCEDURE (d : Display) StopContextHelp;
  (**
    Call this method if you want the Display to stop generating
    QuickHelp calls to windows. This is necessesarry, if you are
    opening a QuickHelp and don't want to have a second after the
    second timeout.
  *)

  BEGIN
    IF d.contextHelp THEN
      d.contextHelp:=FALSE;
      IF d.contextTimer.active THEN
        d.RemoveTimer(d.contextTimer);
      END;
    END;
  END StopContextHelp;

  PROCEDURE (d : Display) RestartContextHelp;
    (**
      Restart the generation of QuickHelp calls to windows stoped
      with Display.StopContextHelp.
    *)

  BEGIN
    IF ~d.contextHelp THEN
      d.AddTimer(d.contextTimer);
      d.contextHelp:=TRUE;
    END;
  END RestartContextHelp;

  PROCEDURE (d : Display) StartContextHelp;

    (**
      Restart the generation of QuickHelp calls to windows stoped
      with Display.StopContextHelp.
    *)

  BEGIN
    IF ~d.contextHelp THEN
      d.AddTimer(d.contextTimer);
      d.contextHelp:=TRUE;
    END;
  END StartContextHelp;

  PROCEDURE (d : Display) AddWindow(w : Window);
  (**
    Adds window to the internal list of windows.
  *)

  BEGIN
    IF d.winList#NIL THEN
      w.last:=NIL;
      w.next:=d.winList;
      d.winList.last:=w;
    ELSE
      w.last:=NIL;
      w.next:=NIL;
    END;
    d.winList:=w;
  END AddWindow;

  PROCEDURE (d : Display) RemoveWindow(w : Window);
  (**
    Removes window from the internal list of windows.
  *)

  BEGIN
    IF d.winList=w THEN
      d.winList:=d.winList.next;
    END;

    IF w.last#NIL THEN
      w.last.next:=w.next;
    END;

    IF w.next#NIL THEN
      w.next.last:=w.last;
    END;
  END RemoveWindow;

  PROCEDURE FontEnumProcA ["Pascal"] (VAR lpelf : W.ENUMLOGFONTA; VAR lpntm : W.NEWTEXTMETRICA; fontType : LONGINT; lparam : W.LPARAM) : LONGINT;
  VAR
    d : Display;
    family : D.FontFamily;
    foundry : D.FontFoundry;
    encoding : D.FontEncoding;
  BEGIN
    d := SYSTEM.VAL(Display, lparam);
    family := d.fontList.GetOrCreateFamily(lpelf.elfFullName);
    foundry := family.GetOrCreateFoundry("Win32");
    encoding := foundry.GetOrCreateEncoding(unicodeEncoding);
    RETURN 1;
  END FontEnumProcA;

  PROCEDURE (d : Display) GetFontList*():D.FontList;
  VAR res : LONGINT;
  BEGIN
    NEW(d.fontList);
    d.fontList.families := NIL;
    res := W.EnumFontFamiliesA(d.hdc, NIL,
      SYSTEM.VAL(W.FARPROC, FontEnumProcA), SYSTEM.VAL(W.LPARAM, d));
    RETURN d.fontList;
  END GetFontList;

  (* -------- color stuff of D.display ------------- *)

  PROCEDURE (d : Display) AllocateColor8*(r,g,b : SHORTINT;
                                          default : D.Color;
                                          VAR color : D.Color);

  BEGIN
    color:=RGB(r, g, b);
  END AllocateColor8;

  PROCEDURE (d : Display) AllocateColor16*(r,g,b : INTEGER;
                                           default : D.Color;
                                          VAR color : D.Color);
  CONST scale = 256;
  BEGIN
    color:=RGB(r DIV scale, g DIV scale, b DIV scale);
  END AllocateColor16;

  PROCEDURE (d : Display) AllocateColor32*(r,g,b : LONGINT;
                                           default : D.Color;
                                           VAR color : D.Color);
  CONST scale = 256 * 256 * 256;
  BEGIN
    color:=RGB(r DIV scale, g DIV scale, b DIV scale);
  END AllocateColor32;

  PROCEDURE (d : Display) AllocateNamedColor*(name : ARRAY OF CHAR;
                                              default : D.Color;
                                              VAR color : D.Color);
  BEGIN
    IF name="black" THEN
      color:=0;
    ELSIF name="red" THEN
      color:=RGB(0FFH, 0, 0);
    ELSIF name="green" THEN
      color:=RGB(0, 0FFH, 0);
    ELSIF name="yellow" THEN
      color:=RGB(0FFH, 0FFH, 0);
    ELSIF name="blue" THEN
      color:=RGB(0, 0, 0FFH);
    ELSIF name="magenta" THEN
      color:=RGB(0FFH, 0, 0FFH);
    ELSIF name="cyan" THEN
      color:=RGB(0, 0FFH, 0FFH);
    ELSIF name="white" THEN
      color:=RGB(0FFH, 0FFH, 0FFH);
    ELSIF name="grey" THEN
      color:=RGB(0AAH, 0AAH, 0AAH);
    ELSIF name="grey70" THEN
      color:=RGB(0B3H, 0B3H, 0B3H);
    ELSIF name="grey95" THEN
      color:=RGB(0F2H, 0F2H, 0F2H);
    ELSIF name="grey82" THEN
      color:=RGB(0D1H, 0D1H, 0D1H);
    ELSIF name="grey45" THEN
      color:=RGB(073H, 073H, 073H);
    ELSIF name="grey20" THEN
      color:=RGB(033H, 033H, 033H);
    ELSIF name="grey60" THEN
      color:=RGB(099H, 099H, 099H);
    ELSIF name="grey92" THEN
      color:=RGB(0EBH, 0EBH, 0EBH);
    ELSIF name="grey30" THEN
      color:=RGB(04DH, 04DH, 04DH);
    ELSIF name="royal blue" THEN
      color:=RGB(041H, 069H, 0E1H);
    ELSIF name="light yellow" THEN
      color:=RGB(0FFH, 0FFH, 0E0H);
    ELSIF name="orange" THEN
      color:=RGB(0FFH, 0A5H, 00H);
    ELSIF name="dim grey" THEN
      color:=RGB(069H, 069H, 069H);
    ELSIF name="yellow4" THEN
      color:=RGB(08BH, 08BH, 00H);
    ELSIF name="Dark slate grey" THEN
      color:=RGB(02FH, 04FH, 04FH);
    ELSIF name="SteelBlue" THEN
      color:=RGB(046H, 08CH, 0B8H);
    ELSIF name="purple" THEN
      color:=RGB(0B8H, 082H, 0F0H);
    ELSIF name="aquamarine" THEN
      color:=RGB(07FH, 0FFH, 0C8H);
    ELSIF name="palegreen" THEN
      color:=RGB(098H, 0FFH, 098H);
(*    ELSIF name="MediumPurple" THEN
      color:=009270A*)
    ELSE
(*      Err.String("Unknown color: ");Err.String(name);Err.Ln;*)
      color:=default;
    END;
  END AllocateNamedColor;

  PROCEDURE (d : Display) IsAllocatedColor*(color : D.Color):BOOLEAN;

  BEGIN
    RETURN TRUE; (*color>=0;*)
  END IsAllocatedColor;

  PROCEDURE (d : Display) FreeColor*(color : D.Color);

  BEGIN
  END FreeColor;

  (* ------------ Display ----------------- *)

(* GetSystemTime has resolution approx 10ms (Win2K).
Run-time library via SysClock is only 1s resolution.
TODO: Replace SysClock with this function for mingw *)

  PROCEDURE GetTime(VAR d : sc.DateTime);
  VAR
    t : W.SYSTEMTIME;
  BEGIN
    W.GetSystemTime(t);
    d.year := t.wYear;
    d.month := SHORT(t.wMonth);
    d.day := SHORT(t.wDay);
    d.hour := SHORT(t.wHour);
    d.minute := SHORT(t.wMinute);
    d.second := SHORT(t.wSecond);
    d.fractions := t.wMilliseconds;
  END GetTime;

(* Timer identifier is in "idEvent". Fire and remove the
timer with the given identifier. *)

  PROCEDURE TimerProc ["Pascal"] (hWnd : W.HWND; uMsg : W.UINT; idEvent : W.UINT; dwTime : W.DWORD);
  VAR
    current,
    help     : Timer;
  BEGIN
    current:=D.display(Display).timerList;
    WHILE current#NIL DO
      IF current.timer = idEvent THEN
        timerMsg.timer:=current;
        help:=current.next;
        D.display(Display).RemoveTimer(current);
        current.object.Receive(timerMsg);
        current:=help;
      ELSE
        current:=current.next;
      END;
    END;
  END TimerProc;

  PROCEDURE (d : Display) AddTimer*(timer : D.Timer);

  VAR
    help  : Timer;
    dt    : sc.DateTime;
    time  : t.TimeStamp;
    thisTimer : Timer;
  BEGIN
    thisTimer := timer(Timer);
    ASSERT(~thisTimer.active);

    GetTime(dt);
    c.SetTimeStamp(dt,time);

    time.Add(thisTimer.interval);

    thisTimer.SetTime(time);

    IF (d.timerList=NIL) OR (thisTimer.time.Cmp(d.timerList.time)<=0) THEN
      thisTimer.next:=d.timerList;
      d.timerList:=thisTimer;
    ELSE
      help:=d.timerList;
      WHILE (help.next#NIL) & (help.next.time.Cmp(thisTimer.time)<0) DO
        help:=help.next;
      END;
      thisTimer.next:=help.next;
      help.next:=thisTimer;
    END;

    thisTimer.Activate;

    thisTimer.timer := W.SetTimer(
      0,
      0,
      thisTimer.interval.dayInt*t.msecPerDay +
        thisTimer.interval.msecInt,
      SYSTEM.VAL(W.FARPROC, TimerProc));
  END AddTimer;

  PROCEDURE (d : Display) RemoveTimer*(timer : D.Timer);

  VAR
    help,
    last : Timer;
    res : W.BOOL;
  BEGIN
    ASSERT(timer.active);

    timer.Deactivate;

    IF timer(Timer).timer # 0 THEN
      res := W.KillTimer(0, timer(Timer).timer);
    END;

    IF d.timerList=NIL THEN
      RETURN;
    END;

    IF d.timerList=timer THEN
      d.timerList:=d.timerList.next;
      RETURN;
    END;

    help:=d.timerList.next;
    last:=d.timerList;
    WHILE (help#NIL) & (help#timer) DO
      last:=help;
      help:=help.next;
    END;
    IF help#NIL THEN
      last.next:=help.next;
    END;
  END RemoveTimer;

  PROCEDURE (d : Display) AddSleep*(object : O.MsgObject):Sleep;

  VAR
    sleep : Sleep;

  BEGIN
    NEW(sleep);
    sleep.object:=object;

    sleep.next:=d.sleepList;
    d.sleepList:=sleep;

    RETURN sleep;
  END AddSleep;

  PROCEDURE (d : Display) RemoveSleep*(sleep : D.Sleep);

  VAR
    help,
    last : Sleep;

  BEGIN
    IF d.sleepList=NIL THEN
      RETURN;
    END;

    IF d.sleepList=sleep THEN
      d.sleepList:=d.sleepList.next;
      RETURN;
    END;

    help:=d.sleepList.next;
    last:=d.sleepList;
    WHILE (help#NIL) & (help#sleep) DO
      last:=help;
      help:=help.next;
    END;
    IF help#NIL THEN
      last.next:=help.next;
    END;
  END RemoveSleep;

  PROCEDURE (d : Display) AddChannel*(channel : IO.Channel;
                                      ops : SET;
                                      object : O.MsgObject):Channel;

  VAR
    entry : Channel;

  BEGIN
    NEW(entry);
    entry.channel:=channel;
    entry.object:=object;

    entry.next:=d.channelList;
    d.channelList:=entry;

    IF channel.RegisterWithSelector(d.selector,ops,NIL)#NIL THEN END;

    RETURN entry;
  END AddChannel;

  PROCEDURE (d : Display) RemoveChannel*(channel : D.Channel);

  VAR
    help,
    last : Channel;

  BEGIN
    IF d.channelList=NIL THEN
      RETURN;
    END;

    IF d.channelList=channel THEN
      d.channelList:=d.channelList.next;
      RETURN;
    END;

    help:=d.channelList.next;
    last:=d.channelList;
    WHILE (help#NIL) & (help#channel) DO
      last:=help;
      help:=help.next;
    END;
    IF help#NIL THEN
      last.next:=help.next;
    END;
  END RemoveChannel;

  PROCEDURE (d : Display) CreateBitmap*(width, height : LONGINT):D.Bitmap;

  VAR
    b : Bitmap; bitmap : D.Bitmap;
    draw : D.DrawInfo;
    dc : W.HDC;
    bmp : W.HBITMAP;
    origBitmap : W.HGDIOBJ;
    res : W.BOOL;
  BEGIN
    bitmap:=factory.CreateBitmap();
    b := bitmap(Bitmap);

    dc := W.CreateCompatibleDC(d.hdc);
    IF dc # 0 THEN
      bmp := W.CreateCompatibleBitmap(d.hdc, width, height);
      IF bmp # 0 THEN
        b.bitmap := bmp;
        b.dc := dc;
        origBitmap := W.SelectObject(dc, bmp);

        draw:=factory.CreateDrawInfo();
        draw(DrawInfo).Init(dc);

        b.draw := draw;
        b.width:=width;
        b.height:=height;
        RETURN b;
      ELSE
        res := W.DeleteDC(dc);
      END;
    END;
    RETURN NIL;
  END CreateBitmap;

  PROCEDURE (d : Display) CreateBitmapPattern*(pattern : ARRAY OF CHAR; width, height : LONGINT):D.Bitmap;

  VAR
    b : Bitmap; bitmap : D.Bitmap;
    draw : D.DrawInfo;
    dc : W.HDC;
    bmp : W.HBITMAP;
    origBitmap : W.HGDIOBJ;
    res : W.BOOL;

  BEGIN
    bitmap:=factory.CreateBitmap();
    b := bitmap(Bitmap);

    dc := W.CreateCompatibleDC(d.hdc);
    IF dc # 0 THEN
      bmp := W.CreateBitmap(width, height, 1, 1, SYSTEM.VAL(LONGINT,SYSTEM.ADR(pattern)));
      IF bmp # 0 THEN
        b.bitmap := bmp;
        b.dc := dc;
        origBitmap := W.SelectObject(dc, bmp);

        draw:=factory.CreateDrawInfo();
        draw(DrawInfo).Init(dc);

        b.draw := draw;
        b.width:=width;
        b.height:=height;
        RETURN b;
      ELSE
        res := W.DeleteDC(dc);
      END;
    END;
    RETURN NIL;
  END CreateBitmapPattern;

  PROCEDURE (d : Display) FreeBitmap*(bitmap : D.Bitmap);
  VAR
    res : W.BOOL;
    b : Bitmap;
  BEGIN
    b := bitmap(Bitmap);
    res := W.DeleteObject(b.bitmap);
    res := W.DeleteDC(b.dc);
  END FreeBitmap;

  PROCEDURE (d : Display) GetWindow(window : W.HWND):Window;

  VAR
    help : Window;

  BEGIN
    help:=d.winList;
    WHILE help#NIL DO
      IF help.window=window THEN
        RETURN help;
      END;
      help:=help.next;
    END;
    RETURN NIL;
  END GetWindow;

  PROCEDURE MessageHandler ["Pascal"] (wnd : W.HWND; msg : W.UINT; wParam : W.WPARAM; lParam : W.LPARAM) : W.LRESULT;

  VAR
    display : Display;
    w       : Window;
    ps      : W.PAINTSTRUCT;
    dc      : W.HDC;
    mm      : W.LPMINMAXINFO;
    pos     : W.LPWINDOWPOS;
    event   : E.Event;
    winMsg  : W.MSG;

  BEGIN
    display:=SYSTEM.VAL(Display,W.GetWindowLongA(wnd,TOLONG(W.GWL_USERDATA)));
    IF display=NIL THEN
      RETURN W.DefWindowProcA(wnd, msg, wParam, lParam);
    END;

    w:=display.GetWindow(wnd);
    IF w = NIL THEN
      (* one of our windows, but not registered with the display *)
      (* Log.Msg("Which window?"); *)
      RETURN W.DefWindowProcA(wnd, msg, wParam, lParam);
    END;

    CASE msg OF
      W.WM_CLOSE:
      w.interface.OnClosePressed;
      RETURN 0;
    | W.WM_PAINT:
      dc := W.BeginPaint(wnd, ps);
      w.draw.InstallClip(ps.rcPaint.left,ps.rcPaint.top,
                       ps.rcPaint.right-ps.rcPaint.left+1,
                       ps.rcPaint.bottom-ps.rcPaint.top+1);
      w.interface.OnRedraw(ps.rcPaint.left,ps.rcPaint.top,
               ps.rcPaint.right-ps.rcPaint.left+1,
               ps.rcPaint.bottom-ps.rcPaint.top+1);
      w.draw.FreeLastClip;
      IF W.EndPaint(wnd, ps)#0 THEN END;

      (* HACK: If we received focus before our window is
         drawn, send one focus message after first drawing
         the window *)
      w.drawn := TRUE;
      IF w.queueFocus THEN
        w.interface.OnFocusIn();
      END;

      RETURN 0;
    | W.WM_LBUTTONDOWN,
      W.WM_LBUTTONUP,
      W.WM_MBUTTONDOWN,
      W.WM_MBUTTONUP,
      W.WM_RBUTTONDOWN,
      W.WM_RBUTTONUP,
      W.WM_MOUSEMOVE,
      W.WM_KEYDOWN,
      W.WM_KEYUP,
      W.WM_SYSKEYDOWN,
      W.WM_SYSKEYUP:
        winMsg.lParam := lParam;
        winMsg.wParam := wParam;
        winMsg.message := msg;
        event:=EO.GetEvent(winMsg);
        IF event # NIL THEN
          WITH event : E.ButtonEvent DO
            IF event.type = E.mouseDown THEN
              w.oldButton:=w.lastButton;
              w.oldPress:=w.lastPress;
              w.lastButton:=w.thisButton;
              w.lastPress:=w.thisPress;
              w.thisButton:=event(EO.ButtonEvent)^;
              w.thisPress:=W.GetTickCount();
            END
          | event:E.MotionEvent DO
          ELSE
          END
        END;
        REPEAT
          event.reUse:=FALSE;
          IF w.interface.HandleEvent(event) THEN END;
        UNTIL event.reUse=FALSE;
        RETURN 0;
    | W.WM_ACTIVATE:
      IF LOWORD(wParam)=W.WA_INACTIVE THEN
        w.interface.OnFocusOut;
      ELSE
        IF w.drawn THEN
          w.interface.OnFocusIn;
        ELSE
          (* Window has not been drawn. Queue event. *)
          w.queueFocus := TRUE;
        END;
      END;
      RETURN 0;
    | W.WM_SHOWWINDOW:
      IF wParam=0 THEN
        w.interface.OnUnmaped;
      ELSE
        w.interface.OnMaped;
      END;
      RETURN 0;
    | W.WM_GETMINMAXINFO:
      (* TODO: rethink everything *)
      mm:=SYSTEM.VAL(W.LPMINMAXINFO,lParam);
      mm.ptMinTrackSize.x:=w.minWidth+w.wDelta;
      mm.ptMinTrackSize.y:=w.minHeight+w.hDelta;
      IF w.maxWidth>=D.display.scrWidth THEN
        mm.ptMaxTrackSize.x:=W.GetSystemMetrics(W.SM_CXFULLSCREEN)+w.wDelta;
      ELSE
        mm.ptMaxTrackSize.x:=w.maxWidth+w.wDelta;
      END;
      IF w.maxHeight>=D.display.scrHeight THEN
        mm.ptMaxTrackSize.y:=W.GetSystemMetrics(W.SM_CYFULLSCREEN)+w.hDelta;
      ELSE
        mm.ptMaxTrackSize.y:=w.maxHeight+w.hDelta;
      END;
      RETURN 0;
    | W.WM_WINDOWPOSCHANGED:
      pos:=SYSTEM.VAL(W.LPWINDOWPOS,lParam);
      w.x:=pos.x+w.wOff;
      w.y:=pos.y+w.hOff;
      IF (pos.cx-w.wDelta#w.width) OR (pos.cy-w.hDelta#w.height) THEN
        w.width:=pos.cx-w.wDelta; (* TODO: check width/height/clip rect *)
        w.height:=pos.cy-w.hDelta;
        w.draw.FreeLastClip;
        w.draw.InstallClip(0,0,w.width,w.height);
        w.interface.OnResized(w.width,w.height);
      END;
      RETURN 0;
    ELSE
      RETURN W.DefWindowProcA(wnd, msg, wParam, lParam);
    END;
  END MessageHandler;


  PROCEDURE (d : Display) Open*():BOOLEAN;

  CONST
    iconId = 1;

  VAR
    i          : LONGINT;
    prefs      : DisplayPrefs;
    name       : STRING;
    tmp        : Object.CharsLatin1;
    colors     : ARRAY D.colorCount OF D.Color;
    brush  : W.HBRUSH;
    res        : W.BOOL;

  BEGIN
    d.driverName:=driverName;

(*    d.name:="";
    i:=LEN(d.name);
    IF W.GetComputerNameA(d.name,i)=0 THEN
      Err.String("Cannot get computer name"); Err.Ln;
    END;
*)
    d.instance:=W.GetModuleHandleA(NIL);
    IF d.instance=0 THEN
      Log.Msg("Cannot get module handle");
      RETURN FALSE;
    END;

    d.hdc:=W.CreateDCA("DISPLAY",NIL,NIL,NIL);
    IF d.instance=0 THEN
      Log.Msg("Cannot get display dc");
      RETURN FALSE;
    END;
    IF W.SetTextAlign(d.hdc,W.TA_BASELINE+W.TA_LEFT)#0 THEN END;

    Image.Probe(d);

    brush:=W.CreateSolidBrush(D.backgroundColor);

    class.hCursor := W.LoadCursorA(0, SYSTEM.VAL(W.LPCSTR, TOLONG(W.IDC_ARROW)));
    class.hIcon := W.LoadIconA(d.instance, SYSTEM.VAL(W.LPCSTR, TOLONG(iconId)));
    class.lpszMenuName := NIL;
    class.lpszClassName := SYSTEM.VAL(W.LPCSTR, SYSTEM.ADR(class));
    class.hbrBackground := 0 (*brush*) (*W.GetStockObject(W.LTGRAY_BRUSH)*);
    class.style := W.CS_VREDRAW + W.CS_HREDRAW;
    class.hInstance := d.instance;
    class.lpfnWndProc := SYSTEM.VAL(W.WNDPROC, SYSTEM.ADR(MessageHandler));
    class.cbClsExtra := 0;
    class.cbWndExtra := 0;
    res := W.RegisterClassA(class);

    d.scrWidth:=W.GetSystemMetrics(W.SM_CXSCREEN);
    d.scrHeight:=W.GetSystemMetrics(W.SM_CYSCREEN);

    d.displayType:=D.displayTypeGraphical;

    IF d.scrWidth<=640 THEN
      d.displaySize:=D.displaySizeTiny;
    ELSIF d.scrWidth<1024 THEN
      d.displaySize:=D.displaySizeSmall;
    ELSIF d.scrWidth<1280 THEN
      d.displaySize:=D.displaySizeNormal;
    ELSE
      d.displaySize:=D.displaySizeHuge;
    END;

    d.colorMode:=D.colorMode;

    D.smallChess:=d.CreateBitmapPattern(D.disablePattern,D.disableWidth,D.disableHeight);
    D.bigChess:=d.CreateBitmapPattern(D.bigChessPattern,D.bigChessWidth,D.bigChessHeight);

    NEW(prefs);
    prefs.Init;
    D.prefs:=prefs;
    D.prefs.Initialize;

    IF D.prefsCallback#NIL THEN
      name:=d.appName;
      WITH name : Object.String8 DO
        tmp:=name.CharsLatin1();
        D.prefsCallback.LoadPrefs(tmp^);
      ELSE
        D.prefsCallback.LoadPrefs("");
      END;
      D.prefsCallback.ReadDisplayPrefs;
      IF D.prefs.theme#"" THEN
        D.prefsCallback.LoadTheme(Object.NewLatin1(D.prefs.theme));
        D.prefsCallback.ReadDisplayTheme;
      END;
    END;

    FOR i:=0 TO D.colorCount-1 DO
      d.AllocateNamedColor(D.prefs.colors[i],0,colors[i]);
    END;

    D.backgroundColor       := colors[D.backgroundColorIndex];
    D.tableBackgroundColor  := colors[D.tableBackgroundColorIndex];
    D.tableBackground2Color := colors[D.tableBackground2ColorIndex];
    D.tableTextColor        := colors[D.tableTextColorIndex];
    D.textBackgroundColor   := colors[D.textBackgroundColorIndex];
    D.buttonBackgroundColor := colors[D.buttonBackgroundColorIndex];
    D.textColor             := colors[D.textColorIndex];
    D.shineColor            := colors[D.shineColorIndex];
    D.halfShineColor        := colors[D.halfShineColorIndex];
    D.halfShadowColor       := colors[D.halfShadowColorIndex];
    D.shadowColor           := colors[D.shadowColorIndex];
    D.fillColor             := colors[D.fillColorIndex];
    D.fillTextColor         := colors[D.fillTextColorIndex];
    D.warnColor             := colors[D.warnColorIndex];
    D.disabledColor         := colors[D.disabledColorIndex];
    D.focusColor            := colors[D.focusColorIndex];
    D.blackColor            := colors[D.blackColorIndex];
    D.whiteColor            := colors[D.whiteColorIndex];
    D.helpBackgroundColor   := colors[D.helpBackgroundColorIndex];

    FOR i:=0 TO D.fontCount-1 DO
      d.font[i]:=factory.CreateFont();

(*      INCL(D.prefs.fonts[i].features,D.fontCharSet);
      NEW(D.prefs.fonts[i].charSet,str.Length(unicodeEncoding)+1);
      COPY(unicodeEncoding,D.prefs.fonts[i].charSet^);
*)

      d.font[i]:=D.prefs.fonts[i].Load();
      IF d.font[i]=NIL THEN
        Log.String("Cannot load font:", D.prefs.fonts[i].name^);
        Log.LongInt("  height:", D.prefs.fonts[i].pointHeight);
        (* TODO: Free colors *)
        (*X11.XCloseDisplay(d.display);*)
        RETURN FALSE;
      END;
    END;

    D.tinyFont:=d.font[D.tinyFontIndex];
    D.scriptFont:=d.font[D.scriptFontIndex];
    D.footnoteFont:=d.font[D.footnoteFontIndex];
    D.smallFont:=d.font[D.smallFontIndex];
    D.normalFont:=d.font[D.normalFontIndex];
    D.largeFont:=d.font[D.largeFontIndex];
    D.LargeFont:=d.font[D.LargeFontIndex];
    D.LARGEFont:=d.font[D.LARGEFontIndex];
    D.hugeFont:=d.font[D.hugeFontIndex];
    D.HUGEFont:=d.font[D.HUGEFontIndex];

    D.smallFixedFont:=d.font[D.smallFixedFontIndex];
    D.fixedFont:=d.font[D.fixedFontIndex];
    D.hugeFixedFont:=d.font[D.hugeFixedFontIndex];

    d.spaceHeight:=(D.fixedFont.height+D.normalFont.height) DIV 4;
    d.spaceWidth:=d.spaceHeight;

    d.winList:=NIL;
    d.exit:=TRUE;
    d.currentWin:=NIL;

    d.timerList:=NIL;
    d.contextTimer:=D.factory.CreateTimer();
    d.contextTimer.SetSecs(D.prefs.contextTimer DIV 1000,D.prefs.contextTimer MOD 1000);
    d.contextTimer.SetObject(d);
    d.contextHelp:=TRUE;

    d.refreshTimer:=D.factory.CreateTimer();
    d.refreshTimer.SetSecs(D.prefs(DisplayPrefs).refreshTimer DIV 1000,D.prefs(DisplayPrefs).refreshTimer MOD 1000);
    d.refreshTimer.SetObject(d);

    d.sleepList:=NIL;
    d.channelList:=NIL;

    d.selector:=S.Open();
    (* NEW(d.fdChannel);
    ChannelFDWrapper.Init(d.fdChannel,0);
    IF d.fdChannel.RegisterWithSelector(d.selector,{IO.opRead},NIL)#NIL THEN END;
    *)
    d.selectObject:=NIL;
    d.querySelectObject:=NIL;
(*    d.selClearPend:=FALSE;

    d.dragging:=FALSE;
    d.dragObject:=NIL;
*)
    d.multiClickTime:=200;

    P.Initialize(D.prefs);
    IF D.prefsCallback#NIL THEN
      D.prefsCallback.ReadOtherPrefs;
      D.prefsCallback.ReadOtherTheme;
      D.prefsCallback.Free;
    END;

    (* To speed up things a little bit :-) *)
    d.bufferUCS2:=NIL;
    d.EnlargeUCS2Buffer(1024);
    d.pointArray := NIL;
    d.EnlargePointArray(64);
    RETURN TRUE;
  END Open;

  PROCEDURE (d : Display) SetMultiClickTime*(t : LONGINT);
  BEGIN
    IF t>0 THEN d.multiClickTime:=t END;
  END SetMultiClickTime;

  PROCEDURE (d : Display) Beep*;

  BEGIN
  END Beep;

  PROCEDURE (d : Display) RegisterSelection*(object : D.Object;
                                             window : D.Window):BOOLEAN;

  BEGIN
    IF d.selectObject#object THEN

      IF (d.selectObject#NIL) THEN
        d.selectObject.Deselect;
        d.selectObject:=NIL;
      END;

(*      X11.XSetSelectionOwner(d.display,a.XA_PRIMARY,window.impl(Window).window,X11.CurrentTime);*)
      d.selectObject:=object;
    END;

    RETURN TRUE;
  END RegisterSelection;

  PROCEDURE (d : Display) CancelSelection*;

  BEGIN
    ASSERT(d.selectObject#NIL);
(*    d.selClearPend:=TRUE;
    X11.XSetSelectionOwner(d.display,a.XA_PRIMARY,X11.None,X11.CurrentTime);*)
    d.selectObject.Deselect;
    d.selectObject:=NIL;
  END CancelSelection;

  PROCEDURE (d : Display) QuerySelection*(window: D.Window;
                                          object: D.Object;
                                          type: LONGINT):BOOLEAN;

(*  VAR
    propType : X11.Atom;
*)
  BEGIN
    Log.Msg("Cannot QuerySelection");
(*    CASE type OF
      D.text: propType:=a.XA_STRING;
    ELSE
      RETURN FALSE;
    END;

    X11.XConvertSelection(d.display,
                          a.XA_PRIMARY,propType,
                          d.xSelection,
                          window.impl(Window).window,
                          X11.CurrentTime);
*)
    d.querySelectObject:=object;
    RETURN TRUE;
(*    RETURN FALSE;*)
  END QuerySelection;

(* Translate string into a Win32 global text structure. Line
breaks are converted to CR-LF. Result may be 8- or 16-bit
text, although the conversion is just based on casting the
character data type and may be wrong in many cases.

TODO: Investigate conversions using OOC string codecs. *)

  PROCEDURE CopyStringToGlobal(content : STRING; unicode : BOOLEAN) : W.HGLOBAL;
  VAR
    dest8 : W.LPCSTR;
    dest16 : W.LPCWSTR;
    i, pos : LONGINT;
    hMem : W.HGLOBAL;
    length : LONGINT;
    size : LONGINT;
    ch : UCS4CHAR;
    res : W.BOOL;

    PROCEDURE AppendChar(ch : UCS4CHAR);
    BEGIN
      IF unicode THEN
        dest16[pos] := SHORT(ch);
      ELSE
        dest8[pos] := SHORT(SHORT(ch));
      END;
      INC(pos);
    END AppendChar;

  BEGIN
    length := content.length;
    FOR i := 0 TO content.length-1 DO
      IF content.CharAt(i) = Ascii.lf THEN
        INC(length);
      END;
    END;

    size := length + 1;
    IF unicode THEN size := size * 2 END;
    hMem := W.GlobalAlloc(W.GMEM_MOVEABLE + W.GMEM_DDESHARE, size);
    IF hMem # 0 THEN
      dest8 := SYSTEM.VAL(W.LPCSTR, W.GlobalLock(hMem));
      dest16 := SYSTEM.VAL(W.LPCWSTR, dest8);
      IF dest8 # NIL THEN
        pos := 0;
        FOR i := 0 TO content.length-1 DO
          ch := content.CharAt(i);
          IF ch = Ascii.lf THEN AppendChar(Ascii.cr) END;
          AppendChar(ch);
        END;
        AppendChar(0X);
      END;
      res := W.GlobalUnlock(hMem);
    END;
    RETURN hMem;
  END CopyStringToGlobal;

(* Put text into the clipboard in TEXT, OEMTEXT and
UNICODETEXT formats. It seems that applications expect one
or the other format. In any case, if the same text is not
available for both formats things get very confusing. *)

  PROCEDURE (d : Display) SetClipboard*(content : STRING):BOOLEAN;
  VAR
    hClip : W.HANDLE;
    res : W.BOOL;
  BEGIN
    IF W.OpenClipboard(0) # W.FALSE THEN
      hClip := W.SetClipboardData(W.CF_TEXT,
        CopyStringToGlobal(content, FALSE));
      hClip := W.SetClipboardData(W.CF_OEMTEXT,
        CopyStringToGlobal(content, FALSE));
      hClip := W.SetClipboardData(W.CF_UNICODETEXT,
        CopyStringToGlobal(content, TRUE));
      res := W.CloseClipboard();
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END SetClipboard;

  PROCEDURE (d : Display) GetClipboard*(object: D.Object):BOOLEAN;

  VAR
    dndData  : DD.DnDStringData;
    text     : U.Text;
    length : LONGINT;
    src, dest : LONGINT;
    hClip : W.HGLOBAL;
    data : W.LPCSTR;
    res : W.BOOL;

  BEGIN
    IF W.OpenClipboard(0) # W.FALSE THEN
      hClip := W.GetClipboardData(W.CF_TEXT);
      IF hClip # 0 THEN
        data := SYSTEM.VAL(W.LPCSTR, W.GlobalLock(hClip));
        IF data # NIL THEN
          res := W.GlobalUnlock(hClip);

          (* compute length after translation *)
          src := 0; length := 0;
          WHILE data[src] # 0X DO
            IF data[src] # Ascii.cr THEN INC(length) END;
            INC(src);
          END;

          (* translate text *)
          NEW(text, length + 1);
          src := 0; dest := 0;
          WHILE data[src] # 0X DO
            IF data[src] # Ascii.cr THEN
              text[dest] := data[src]; INC(dest);
            END;
            INC(src);
          END;
          ASSERT(dest = length);
          text[dest] := 0X;

          res := W.GlobalUnlock(hClip);

          NEW(dndData);
          dndData.string:=Object.NewLatin1(text^);

          IF ~object.HandleDrop(dndData,DD.insert) THEN
            d.Beep;
          END;
        END;
      END;
      res := W.CloseClipboard();
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;

  END GetClipboard;

  PROCEDURE (d : Display) ClearClipboard*;

  BEGIN
  END ClearClipboard;

  PROCEDURE (d : Display) PutBackEvent*(event : E.Event; destWin : D.Window);

(*  VAR
    x11Event : X11.XEvent;
*)
  BEGIN
    Log.Msg("Cannot PutBackEvent");
(*    EO.GetX11Event(event,x11Event);
    x11Event.xany.window:=destWin.impl(Window).window;
    IF X11.XSendEvent(d.display,destWin.impl(Window).window,X11.True,X11.NoEventMask,
                     s.VAL(X11.XEventPtr,s.ADR(x11Event)))=0 THEN
      Err.String("Cannot resend event!"); Err.Ln;
    END;*)
  END PutBackEvent;

  PROCEDURE (d : Display) Exit*;

  BEGIN
    ASSERT(~d.exit);
    d.exit:=TRUE;
  END Exit;

  PROCEDURE (d : Display) ReinitWindows*;

  VAR
    win : D.WindowImpl;

  BEGIN
    win:=d.winList;
    WHILE win#NIL DO
      win.interface.ReinitWindow;
      win:=win(Window).next;
    END;
  END ReinitWindows;

  PROCEDURE (d : Display) Close*;

  VAR
    w : Window;

  BEGIN
    d.selector.Close;

    w:=d.winList;
    WHILE w#NIL DO
(*
      Err.String("Warning: window ");
      IF w.title#NIL THEN
        Err.String(w.title^);
      END;
      Err.String(" not explicitely closed"); Err.Ln;
*)
      w.interface.Close;
      w:=d.winList;
    END;

    (* Freeing all preferences *)
    P.Free;

    (* No need to free colors *)
    (* No need to free fonts *)

    IF Image.factory#NIL THEN
      Image.factory.Deinit(d);
      Image.factory:=NIL;
    END;
  END Close;

  PROCEDURE (d : Display) Receive*(message : O.Message);

  VAR
    x,y,
    width,
    height : LONGINT;

  BEGIN
    WITH
      message : D.ExitMsg DO
        d.Exit;
    | message : D.TimerMsg DO
      IF d.currentWin#NIL THEN
        IF (message.timer=d.contextTimer) THEN
          d.currentWin.interface.OnContextHelp;
        ELSIF message.timer=d.refreshTimer THEN
          d.currentWin.draw.GetClipRegion(x,y,width,height);
          d.currentWin.interface.OnRedraw(x,y,width,height);
          d.currentWin.draw.FreeLastClip;
        END;
      END;
    ELSE
    END;
  END Receive;

  PROCEDURE (d : Display) CheckSleeps;
  (**
    Check the list of registered sleeps and send a message for every elapsed
    timeout.
  *)

  VAR
    sleep : Sleep;
    msg   : D.SleepMsg;

  BEGIN
    sleep:=d.sleepList;
    WHILE sleep#NIL DO
      NEW(msg);
      msg.sleep:=sleep;
      sleep.object.Receive(msg);
      sleep:=sleep.next;
    END;
  END CheckSleeps;

  PROCEDURE (d : Display) CheckTimers;
  (**
    Check the list of registered timeouts and send a message for every elapsed
    timeout.
  *)

  VAR
    timer,
    help   : Timer;
    dt     : sc.DateTime;
    time   : t.TimeStamp;

  BEGIN
    sc.GetClock(dt);
    c.SetTimeStamp(dt,time);

    timer:=d.timerList;
    WHILE timer#NIL DO
      IF (timer.time.Cmp(time)<0) THEN
        timerMsg.timer:=timer;
        help:=timer.next;
        d.RemoveTimer(timer);
        timer.object.Receive(timerMsg);
        timer:=help;
      ELSE
        timer:=timer.next;
      END;
    END;
  END CheckTimers;

(*
  PROCEDURE (w : Window) HandleEvent*(event : E.Event):BOOLEAN;

  BEGIN
    RETURN FALSE;
  END HandleEvent;
*)

  PROCEDURE (entry : Channel) SendNotify;
  (**
    Check the list of registered file notifier and send a message for every
    notifier matching the file descriptor.
  *)

  VAR
    msg : D.ChannelMsg;

  BEGIN
    NEW(msg);
    msg.channel:=entry;
    entry.object.Receive(msg);
    entry:=entry.next;
  END SendNotify;

  PROCEDURE (d : Display) GetNextTimer(VAR interval : t.Interval);
  (**
    Return the next pending future time event. If there is no event pending it
    will return a event 10 seconds in the future.
  *)

  VAR
    dt   : sc.DateTime;
    time : t.TimeStamp;

  BEGIN
    IF d.timerList#NIL THEN

      sc.GetClock(dt);
      c.SetTimeStamp(dt,time);
      d.timerList.time.Delta(time,interval);
    ELSE
      t.InitInterval(interval,0,30*1000);
    END;
  END GetNextTimer;

  PROCEDURE (d : Display) Wait():BOOLEAN;

    (**
      Waits for certain events to happen:
      * A X11 event occurs
      * Timer run out

      Returns TRUE, if the wait exceeds the given timeout, else FALSE, if Wait
      returned because an X11 event is available.

      File descriptors getting available will be handled internaly. In this
      case a notification will be send and the wait will be restarted.
    *)

  VAR
    channel  : Channel;
    key      : IO.SelectionKey;
    sec,usec : LONGINT;
    res      : LONGINT;
    interval : t.Interval;
    e : Exception.Exception;

  BEGIN
    RETURN FALSE;
    LOOP
      TRY
        d.GetNextTimer(interval);

        sec:=interval.dayInt*(t.msecPerDay DIV t.msecPerSec)+interval.msecInt DIV 1000;
        usec:=(interval.msecInt MOD 1000)*1000;

        IF (sec<0) OR (usec<0) THEN
          sec:=0;
          usec:=0;
        END;

        (* d.fdChannel.ResetReadyOps(); *)

        res:=d.selector.Select(sec,usec);
        IF res=0 THEN
          RETURN TRUE;
        ELSE
          key:=d.selector.NextKey();
          WHILE key#NIL DO
            IF key.channel=d.fdChannel THEN
              RETURN FALSE;
            ELSE
              channel:=d.channelList;
              WHILE channel#NIL DO
                IF key.channel=channel.channel THEN
                  channel.SendNotify;
                END;
                channel:=channel.next;
              END;
            END;

            key:=d.selector.NextKey();
          END;
        END;
      CATCH IO.Error:
        e := Exception.Current();
        Log.Object("Select error!", e.GetMessage());
        RETURN TRUE;
      END;
    END;
  END Wait;


  PROCEDURE (d : Display) GetEvent;
  VAR
    msg      : W.MSG;
    lRes     : W.LONG;
    bRes     : W.BOOL;

  BEGIN
    lRes:=W.GetMessageA(msg, 0, 0, 0);

    IF lRes=0 THEN
      d.Exit;
      RETURN;
    ELSIF lRes#-1 THEN
      bRes := W.TranslateMessage(msg);
      lRes := W.DispatchMessageA(msg);
    ELSE
      (* some error *)
      RETURN;
    END;

(*
    d.currentWin:=d.GetWindow(msg.hwnd);

    IF d.currentWin#NIL THEN
        event:=EO.GetEvent(msg);
        REPEAT
          event.reUse:=FALSE;
          IF d.currentWin.interface.HandleEvent(event) THEN END;
        UNTIL event.reUse=FALSE;
    END;
*)
(*    IF d.contextHelp THEN
      d.timeOut:=d.AddTimeOut(contextTimeOutSec,contextTimeOutMil,d);
    END;
*)
  END GetEvent;


  PROCEDURE (d : Display) EventLoop*;
  BEGIN
    ASSERT(d.exit);

    d.exit:=FALSE;

    LOOP
      d.GetEvent();
      IF d.exit THEN
        EXIT
      END
    END;
  END EventLoop;

  PROCEDURE (w : Window) Init*;

  BEGIN
    w.Init^;

    w.last:=NIL;
    w.next:=NIL;

    w.grab:=FALSE;
    w.exit:=TRUE;

    w.oldPress:=0;
    w.lastPress:=0;
    w.thisPress:=0;

    w.window:=0;

    w.drawn := FALSE;
    w.queueFocus := FALSE;
  END Init;

  PROCEDURE (w : Window) SetTitle*(name : STRING);

  VAR
    tmp   : Object.CharsLatin1;
    tmp2  : Object.CharsUTF16;
    title : STRING;

  BEGIN
    w.SetTitle^(name);

    IF w.IsOpen() THEN

      CASE w.type OF
        D.windowTypeMenu,
        D.windowTypePopup,
        D.windowTypeSplash:
        RETURN;
      ELSE
      END;

      title:=w.GetTitle();
      WITH
        title : Object.String8 DO
        tmp := title.CharsLatin1();
        IF W.SetWindowTextA(w.window,SYSTEM.VAL(W.PCHAR, tmp))#0 THEN END;
      | title : Object.String16 DO
        tmp2 := title.CharsUTF16();
        IF W.SetWindowTextW(w.window,SYSTEM.VAL(W.PWCHAR, tmp2))#0 THEN END;

      END;
    END;
  END SetTitle;

  PROCEDURE (w : Window) GetDrawInfo*():D.DrawInfo;

  BEGIN
    RETURN w.draw;
  END GetDrawInfo;

  PROCEDURE (w : Window) Resize*(width,height : LONGINT);

  BEGIN
    w.Resize^(width,height);

    (*X11.XResizeWindow(D.display(Display).display,w.window,width,height);*)
  END Resize;

  PROCEDURE (w : Window) GrabOn;
  (**
    Grabs the mouse cursor and keyboard.
  *)
  VAR prevCapture : W.HWND;
  BEGIN
    (* D.display(Display).StopContextHelp; *)
    prevCapture := W.SetCapture(w.window);
  END GrabOn;

  PROCEDURE (w : Window) GrabOff;
  (**
    Releases the grab of the mouse cursor and the keyboard.
  *)
  BEGIN
    IF W.ReleaseCapture() = W.TRUE THEN END;
    (* D.display(Display).RestartContextHelp; *)
  END GrabOff;

  PROCEDURE (w : Window) Grab*(grab : BOOLEAN);

  BEGIN
    IF w.grab=grab THEN
      RETURN;
    END;

    IF ~w.IsOpen() THEN
      w.grab:=grab;
    ELSE
      IF grab THEN
        w.GrabOn;
      ELSE
        w.GrabOff;
      END;
      w.grab:=grab;
    END;
  END Grab;

  PROCEDURE (w : Window) Open*():BOOLEAN;

  VAR
    rect   : W.RECT;
    flags  : LONGINT;
    x,y    : LONGINT;
    parent : W.HWND;
    draw : D.DrawInfo;

  BEGIN
    IF ~w.Open^() THEN
      RETURN FALSE;
    END;

    CASE w.horizontalPos OF
      D.centerOnParent:
        IF w.parent#NIL THEN
          w.x:=w.parent.x+(w.parent.width-w.width) DIV 2
        ELSE
          w.x:=(D.display.scrWidth-w.width) DIV 2;
        END;
    | D.osPos,
      D.centerOnScreen:
        w.x:=(D.display.scrWidth-w.width) DIV 2;
    ELSE
    END;

    CASE w.verticalPos OF
      D.centerOnParent:
        IF w.parent#NIL THEN
          w.y:=w.parent.y+(w.parent.height-w.height) DIV 2
        ELSE
          w.y:=(D.display.scrHeight-w.height) DIV 2;
        END;
    | D.osPos,
      D.centerOnScreen:
        w.y:=(D.display.scrHeight-w.height) DIV 2;
    ELSE
    END;

    CASE w.type OF
      D.windowTypeMenu,
      D.windowTypePopup,
      D.windowTypeSplash:
      flags:=TOLONG(W.WS_POPUP);
    ELSE
      IF (w.minWidth#w.maxWidth) OR (w.minHeight#w.maxHeight) THEN
        flags:=W.WS_OVERLAPPEDWINDOW;
      ELSE
        flags:=W.WS_OVERLAPPED + W.WS_SYSMENU + W.WS_CAPTION +
        W.WS_MAXIMIZEBOX + W.WS_MINIMIZEBOX;
      END;
    END;

    rect.left:=w.x;
    rect.top:=w.y;
    rect.right:=w.x+w.width-1;
    rect.bottom:=w.y+w.height-1;
    IF W.AdjustWindowRectEx(rect,flags,W.FALSE,0)#0 THEN END;

    w.wOff:=w.x-rect.left;
    w.hOff:=w.y-rect.top;
    w.wDelta:=(rect.right-rect.left+1)-w.width;
    w.hDelta:=(rect.bottom-rect.top+1)-w.height;

(*
    w.wOff := 0;
    w.hOff := 0;
    w.wDelta := 0;
    w.hDelta := 0;
*)
    IF w.horizontalPos=D.osPos THEN
      x:=TOLONG(W.CW_USEDEFAULT);
    ELSE
      x:=rect.left;
    END;

    IF w.verticalPos=D.osPos THEN
      y:=TOLONG(W.CW_USEDEFAULT);
    ELSE
      y:=rect.top;
    END;

    IF w.parent#NIL THEN
      parent:=w.parent(Window).window;
    ELSE
      parent:=0;
    END;

    w.window := W.CreateWindowExA(0,SYSTEM.VAL(W.LPCSTR, SYSTEM.ADR(class)),
                                  NIL,
                                  flags,
                                  x,y,
                                  rect.right-rect.left+1,
                                  rect.bottom-rect.top+1,
                                  parent, 0, D.display(Display).instance, 0);

    IF W.SetWindowLongA(w.window,TOLONG(W.GWL_USERDATA),SYSTEM.VAL(W.LONG,D.display))#0 THEN END;

    w.SetTitle(w.GetTitle());

    draw:=factory.CreateDrawInfo();
    w.draw:=draw(DrawInfo);
    w.draw.Init(W.GetDC(w.window));

(*    w.draw.InstallClip(0,0,D.display.scrWidth,D.display.scrHeight);*)
    w.draw.InstallClip(0,0,w.width,w.height);

    D.display(Display).AddWindow(w);
    D.display(Display).currentWin:=w;

    IF W.ShowWindow(w.window,W.SW_SHOWNORMAL)#0 THEN END;

    IF w.grab THEN
      w.GrabOn;
    END;

    RETURN TRUE;
  END Open;

  PROCEDURE (w : Window) Close*;
  VAR hWnd : W.HWND;
  BEGIN
    IF w.grab THEN
      w.GrabOff;
    END;

(*
    IF W.ShowWindow(w.window,W.SW_HIDE)#0 THEN END; *)

    IF w.IsOpen() & (w.window#0) THEN
      hWnd := w.window;
      IF w.draw.clipPos # -1 THEN
        w.draw.FreeLastClip;
      END;
      w.draw.Deinit;

(* DestroyWindow will send a deactivate message, which for
   pop-up menus in turn invokes Close. To avoid reentrancy,
   we clear the window handle before closing the window. *)

      w.window := 0;

(* Destroying the active window SEEMS to NOT always activate
   the parent. Perhaps there is a reason for this. For now,
   we explicitly activate the parent before closing. *)

      IF (w.parent # NIL) THEN
        IF W.SetActiveWindow(w.parent(Window).window) # 0 THEN END;
      END;

      IF W.DestroyWindow(hWnd)#0 THEN END;
    END;

    D.display(Display).RemoveWindow(w);

    w.Close^;
  END Close;

  PROCEDURE (w : Window) GetMousePos*(VAR rx, ry, wx, wy : LONGINT);
  VAR
    cursorPos : W.POINT;
    rect : W.RECT;
  BEGIN
    IF W.GetCursorPos(cursorPos) = W.TRUE THEN
      rx := cursorPos.x;
      ry := cursorPos.y;
      IF W.GetWindowRect(w.window, rect) = W.TRUE THEN
        wx := rx - rect.left - w.wOff;
        wy := ry - rect.top - w.hOff;
      ELSE
        Error("GetWindowRect");
      END;
    ELSE
      Error("GetCursorPos");
    END;
  END GetMousePos;

  PROCEDURE (w : Window) EventLoop*;
  VAR
    d : Display;
  BEGIN
    d := D.display(Display);
    ASSERT(w.exit);

    w.exit:=FALSE;

    w.DisableParents;

    LOOP
      d.GetEvent;
      IF w.exit THEN
        EXIT
      END
    END;

    w.EnableParents;
  END EventLoop;

  PROCEDURE (w : Window) Enable*;
  VAR res : W.BOOL;
  BEGIN
    w.Enable^;
    res := W.EnableWindow(w.window, 1);
    IF w.modalCount=0 THEN
      (*X11.XUndefineCursor(D.display(Display).display,w.window);*)
    END;
  END Enable;

  PROCEDURE (w : Window) Disable*;
  VAR res : W.BOOL;
  BEGIN
    w.Disable^;
    res := W.EnableWindow(w.window, 0);
    IF w.modalCount=1 THEN
      (*X11.XDefineCursor(D.display(Display).display,
                        w.window,
                        D.display(Display).sleepCursor);*)
    END;
  END Disable;

  PROCEDURE (w : Window) IsInEventLoop*():BOOLEAN;

  BEGIN
    RETURN ~w.exit;
  END IsInEventLoop;

  PROCEDURE (w : Window) IsDoubleClicked*():BOOLEAN;
  BEGIN
    RETURN (w.lastButton.type = w.thisButton.type)
          & (w.lastButton.qualifier = w.thisButton.qualifier)
          & (ABS(w.lastButton.x-w.thisButton.x)<1)
          & (ABS(w.lastButton.y-w.thisButton.y)<1)
          & (w.thisPress - w.lastPress <= D.display(Display).multiClickTime);
  END IsDoubleClicked;

  PROCEDURE (w : Window) IsTrippleClicked*():BOOLEAN;

  BEGIN
    RETURN (w.oldButton.type = w.lastButton.type)
          & (w.oldButton.qualifier = w.lastButton.qualifier)
          & (ABS(w.oldButton.x-w.lastButton.x)<1)
          & (ABS(w.oldButton.y-w.lastButton.y)<1)
          & (w.lastPress - w.oldPress <= D.display(Display).multiClickTime)

          & (w.lastButton.type = w.thisButton.type)
          & (w.lastButton.qualifier = w.thisButton.qualifier)
          & (ABS(w.lastButton.x-w.thisButton.x)<1)
          & (ABS(w.lastButton.y-w.thisButton.y)<1)
          & (w.thisPress - w.lastPress <= D.display(Display).multiClickTime);
  END IsTrippleClicked;

  PROCEDURE (w : Window) Exit*;

  BEGIN
    ASSERT(~w.exit);

    w.exit:=TRUE;
  END Exit;

  (* ------------ object factory --------------- *)

  PROCEDURE (f : FactoryImpl) Init*;

  BEGIN
    f.Init^;

    f.driverName:=driverName;

    f.SetPriority(0);
  END Init;

  PROCEDURE (f : FactoryImpl) CreateFont*():D.Font;

  VAR
    font : Font;

  BEGIN
    NEW(font);
    font.Init;

    RETURN font;
  END CreateFont;

  PROCEDURE (f : FactoryImpl) CreateDrawInfo*():D.DrawInfo;

  VAR
    draw : DrawInfo;

  BEGIN
    NEW(draw);

    RETURN draw;
  END CreateDrawInfo;

  PROCEDURE (f : FactoryImpl) CreateWindowImpl*():D.WindowImpl;

  VAR
    window : Window;

  BEGIN
    NEW(window);
    window.Init;

    RETURN window;
  END CreateWindowImpl;

  PROCEDURE (f : FactoryImpl) CreateDisplay*():D.Display;

  VAR
    display : Display;

  BEGIN
    NEW(display);
    display.Init;

    RETURN display;
  END CreateDisplay;

  PROCEDURE (f : FactoryImpl) CreateBitmap*():D.Bitmap;

  VAR
    bitmap : Bitmap;

  BEGIN
    NEW(bitmap);

    RETURN bitmap;
  END CreateBitmap;

  PROCEDURE (f : FactoryImpl) CreateTimer*():D.Timer;

  VAR
    timer : Timer;

  BEGIN
    NEW(timer);
    timer.Init;

    RETURN timer;
  END CreateTimer;

  PROCEDURE SetDefault*;

  BEGIN
    D.SetFactory(factory);
  END SetDefault;

BEGIN
  NEW(timerMsg);

  NEW(factory);
  factory.Init;
END VO:OS:Windows:Display.
