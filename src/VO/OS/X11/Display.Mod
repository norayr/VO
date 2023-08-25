MODULE VO:OS:X11:Display;

(*
    Implementation Classes for visualisation.
    Copyright (C) 2000  Tim Teulings (rael@edge.ping.de)

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


IMPORT s    := SYSTEM,

       D    := VO:Base:Display,
       DD   := VO:Base:DragDrop,
       E    := VO:Base:Event,
       O    := VO:Base:Object,
       U    := VO:Base:Util,

       EO   := VO:OS:X11:Event,

       P    := VO:Prefs:Base,

               ChannelFDWrapper,

       S    := IO:Select,

      Codec := XML:UnicodeCodec,
<* PUSH; Warnings:=FALSE *>
               XML:UnicodeCodec:Latin1,
               XML:UnicodeCodec:UTF8,
               Latin9,
<* POP *>
               C,
       c    := Calendar,
       co   := IntStr,
               IO,
               Err,
               Object,
               Out,
       sc   := SysClock,
       str  := Strings,
       str2 := Strings2,
       t    := Time,

               VO:Image:Image,

               X11:X11,

<* IF HAVE_LIB_XFT2=TRUE THEN *>
       Xft:=   X11:Xft2,
               X11:Xrender,
<* ELSIF HAVE_LIB_XFT=TRUE THEN *>
               X11:Xft,
               X11:Xrender,
<* END *>

<* IF HAVE_LIB_FONTCONFIG=TRUE THEN *>
       fc   := fontconfig,
<* END *>

       a    := X11:Xatom,
       xu   := X11:Xutil;


(* ============== Implementation classes ============== *)

CONST
  driverName = "X11";

  (* Size of the various stack arrays *)
  initialStackSize   = 30;
  stackSizeIncrement = 30;

  (* constants for Xdnd *)

  XDND_VERSION = 3;

  sleepCursor = 150; (* from /usr/include/X11/cursorFont.h *)
  popCursor   =  94;
  dndCursor   =  50;

  unicodeEncoding* = "iso10646-1";

  atomAtom                   =  0;
  deleteProtAtom             =  1;
  wmStateAtom                =  2;
  XdndAwareAtom              =  3;
  XdndEnterAtom              =  4;
  XdndLeaveAtom              =  5;
  XdndPositionAtom           =  6;
  XdndStatusAtom             =  7;
  XdndFinishedAtom           =  8;
  XdndDropAtom               =  9;
  XdndActionCopyAtom         = 10;
  XdndActionMoveAtom         = 11;
  XdndActionLinkAtom         = 12;
  XdndActionAskAtom          = 13;
  XdndActionPrivateAtom      = 14;
  XdndActionListAtom         = 15;
  XdndSelectionAtom          = 16;
  XdndTypeListAtom           = 17;
  dropAtom                   = 18;
  selectionAtom              = 19;
  compoundTextAtom           = 20;
  clipboardAtom              = 21;
  clipBufferAtom             = 22;
  netWMNameAtom              = 23;
  netWMWindowTypeAtom        = 24;
  netWMWindowTypeDesktopAtom = 25;
  netWMWindowTypeToolbarAtom = 26;
  netWMWindowTypeMenuAtom    = 27;
  netWMWindowTypeUtilityAtom = 28;
  netWMWindowTypeSplashAtom  = 29;
  netWMWindowTypeDialogAtom  = 30;
  netWMWindowTypeNormalAtom  = 31;
  utf8StringAtom             = 32;
  xEmbedAtom                 = 33;

  atomCount                  = 34;

TYPE
  AtomName        = ARRAY 30 OF CHAR;

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
                      key    : IO.SelectionKey; (** Internal key for registration to the selctor *)
                      object : O.MsgObject;
                    END;

  Font*     = POINTER TO FontDesc;
  FontDesc* = RECORD (D.FontDesc)
                fullName     : U.Text;
                loaded       : BOOLEAN;
                fonts        : ARRAY D.maxStyleNum OF X11.XFontStructPtr;
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
                xftfonts     : ARRAY D.maxStyleNum OF Xft.XftFontPtr;
<* END *>
                useCount     : LONGINT;
              END;

  (*  PointArray = POINTER TO ARRAY OF X11.XPoint;*)
  PointArray   = ARRAY 256 OF X11.XPoint;

  Window*      = POINTER TO WindowDesc;

  Display*     = POINTER TO DisplayDesc;
  DisplayDesc* = RECORD (D.DisplayDesc)
                   scrNum-      : LONGINT;

                   display-     : X11.DisplayPtr;
                   visual*      : X11.VisualPtr;
                   colorMap*    : X11.Colormap;
                   xim-         : X11.XIM;

                   (* various cursors *)
                   sleepCursor,
                   popCursor,
                   dndCursor,
                   copyCursor,
                   moveCursor,
                   linkCursor   : X11.Cursor;

                   (* fonts *)
                   fonts        : Font;

                   atoms        : ARRAY atomCount OF X11.Atom;

                   (* windowing information *)
                   winList,
                   currentWin   : Window;

                   (* selection stuff *)
                   selectObject,
                   querySelectObject,
                   queryClipboardObject : D.Object;
                   selClearPend : BOOLEAN;

                   (* timeouts *)
                   timerList    : Timer;
                   contextTimer : D.Timer; (** The @code{Timer} for context help *)
                   contextHelp  : BOOLEAN;

                   (* sleep stuff *)
                   sleepList    : Sleep;

                   (* fd stuff *)

                   channelList  : Channel;

                   fdChannel    : ChannelFDWrapper.Channel;
                   selector     : IO.Selector;

                   (* Xdnd stuff *)
                   dropWindow   : X11.Window;

                   clipboard    : STRING;  (* Our clipboard buffer *)
                   appWindow    : X11.Window;

                   (* general DnD *)
                   dragObject   : D.Object;
                   dragInfo     : DD.DnDDataInfo;
                   dndAction    : LONGINT;
                   dragX,dragY  : LONGINT; (* x,y coord of the drag start point *)
                   dragging,               (* we are currently dragging (not handled yet) *)
                   dragStart    : BOOLEAN; (* Button down, check for dragging on mouse move *)

                   exit         : BOOLEAN;

                   multiClickTime : X11.Time;

                   (* for speed up *)
                   pointArray    : PointArray;
                   bufferUCS2    : POINTER TO ARRAY OF LONGCHAR;
                 END;

  Bitmap*     = POINTER TO BitmapDesc;
  BitmapDesc* = RECORD (D.BitmapDesc)
                    pixmap- : X11.Pixmap;
                  END;

  DrawInfo* = POINTER TO DrawInfoDesc;

  ClipEntryDesc = RECORD
                    region  : xu.Region;
                    draw    : DrawInfo;
                  END;


  PenColorDesc  = RECORD
                    color : D.Color;
                    count : LONGINT;
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
                    pixMap : X11.Pixmap;
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
                        window-      : X11.Window;
                        gc-          : X11.GC;
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
                        xftgc-       : Xft.XftDrawPtr;
<* END *>
                      END;

  WindowDesc* = RECORD (D.WindowImplDesc)
                  last,next   : Window;
                  window      : X11.Window;
                  xic-        : X11.XIC;

                  draw        : DrawInfo;
                  grab,
                  exit        : BOOLEAN;

                  (* For double click *)
                  oldButton,
                  lastButton,
                  thisButton  : EO.ButtonEventDesc;
                  oldPress,
                  lastPress,
                  thisPress   : X11.Time;
                END;

  FactoryImpl*      = POINTER TO FactoryImplDesc;
  FactoryImplDesc*  = RECORD (D.FactoryDesc)
                      END;

  DisplayPrefs     = POINTER TO DisplayPrefsDesc;
  DisplayPrefsDesc = RECORD (D.DisplayPrefsDesc)
                     END;

VAR
  factory-       : FactoryImpl;

  atomNames      : ARRAY atomCount OF AtomName;

  (* copy cursor *)
  copyCursorData,
  copyMaskData   : ARRAY 30 OF CHAR;

  moveCursorData,
  moveMaskData   : ARRAY 26 OF CHAR;

  linkCursorData,
  linkMaskData   : ARRAY 34 OF CHAR;

  timerMsg       : D.TimerMsg;

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
    ELSIF D.display.colorMode=D.greyScaleMode THEN
      p.colors[D.backgroundColorIndex]:="grey70";
      p.colors[D.tableBackgroundColorIndex]:="white";
      p.colors[D.tableBackground2ColorIndex]:="grey95";
      p.colors[D.textBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.buttonBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.tableTextColorIndex]:="black";
      p.colors[D.textColorIndex]:="black";
      p.colors[D.shineColorIndex]:="grey95";
      p.colors[D.halfShineColorIndex]:="grey82";
      p.colors[D.halfShadowColorIndex]:="grey45";
      p.colors[D.shadowColorIndex]:="grey20";
      p.colors[D.fillColorIndex]:="grey60";
      p.colors[D.fillTextColorIndex]:="black";
      p.colors[D.warnColorIndex]:="grey92";
      p.colors[D.disabledColorIndex]:="grey20";
      p.colors[D.focusColorIndex]:="grey30";
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
        NEW(p.fonts[x].name,str.Length("helvetica")+1);
        COPY("helvetica",p.fonts[x].name^);
      ELSE
        NEW(p.fonts[x].name,str.Length("courier")+1);
        COPY("courier",p.fonts[x].name^);
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
  END Init;

(*  PROCEDURE (d : Display) EnlargePointArray(len : LONGINT);

  BEGIN
    IF (d.pointArray=NIL) OR (LEN(d.pointArray^)<len) THEN
      NEW(d.pointArray,len);
    END;
  END EnlargePointArray;*)

  PROCEDURE (d : Display) EnlargeUCS2Buffer(len : LONGINT);

  BEGIN
    IF (d.bufferUCS2=NIL) OR (LEN(d.bufferUCS2^)<len) THEN
      NEW(d.bufferUCS2,len);
    END;
  END EnlargeUCS2Buffer;

  PROCEDURE (d : Display) SetUTF8Property(window : Window;
                                          property : X11.Atom;
                                          value : STRING);

  VAR
    string : Object.String16;
    buffer : U.Text;
    src,
    dest   : LONGINT;
    cval   : LONGINT;

  BEGIN
    string:=value.ToString16();
    NEW(buffer,value.length*4+1); (* Cannot get worse ;-) *)

    src:=0;
    dest:=0;

    (* This is from from XML:UnicodeCodec:UTF8 in the standard library *)
    WHILE src<value.length DO
      IF (string.CharAt(src)<80X) THEN          (* 1 byte encoding *)
        buffer[dest]:=SHORT(SHORT(string.CharAt(src)));
        INC(src); INC(dest)
      ELSIF (string.CharAt(src)<0800X) THEN     (* 2 byte encoding *)
        buffer[dest]:=CHR (192+ORD (string.CharAt(src)) DIV 64);
        buffer[dest+1]:=CHR (128+ORD (string.CharAt(src)) MOD 64);
        INC(src); INC(dest,2)
      ELSIF (0D800X<=string.CharAt(src)) & (string.CharAt(src)<0DC00X) THEN
        (* high level surrogate area: should be followed by low level;
          this is mapped to a 4 byte encoding *)
        IF (0DC00X<=string.CharAt(src+1)) & (string.CharAt(src+1)<0E000X) THEN
          cval := ORD(string.CharAt(src)) MOD 1024*1024 +
          ORD(string.CharAt(src+1)) MOD 1024 + 10000H;
          buffer[dest]:=CHR (0F0H + ASH (cval, -3*6));
          buffer[dest+1]:=CHR (ASH (cval, -2*6) MOD 64 + 128);
          buffer[dest+2]:=CHR (ASH (cval, -1*6) MOD 64 + 128);
          buffer[dest+3]:=CHR (cval MOD 64 + 128);
          INC(src,2); INC(dest,4)
        ELSE  (* high surrogate not followed by low surrogate *)
          RETURN;
        END
      ELSIF (0DC00X<=string.CharAt(src)) & (string.CharAt(src)<0E000X) OR
            (string.CharAt(src)>=0FFFEX) THEN
        (* character from low surrogate area, or invalid char: error *)
        RETURN;
      ELSE                               (* 3 byte encoding *)
        cval:=ORD(string.CharAt(src));
        buffer[dest]:=CHR (0E0H + ASH (cval, -2*6));
        buffer[dest+1]:=CHR (ASH (cval, -1*6) MOD 64 + 128);
        buffer[dest+2]:=CHR (cval MOD 64 + 128);
        INC(src);INC(dest,3)
      END
    END;
    buffer[dest]:=0X;

    X11.XChangeProperty(d.display,
                        window.window,
                        property,
                        D.display(Display).atoms[utf8StringAtom],8,
                        X11.PropModeReplace,
                        buffer^,dest);

  END SetUTF8Property;

  PROCEDURE (d : Display) SetAtomProperty(window : Window;
                                          property : X11.Atom;
                                          value : X11.Atom);

  VAR
    tmp : ARRAY SIZE(X11.Atom) OF CHAR;

  BEGIN
    s.MOVE(s.ADR(value),s.ADR(tmp),SIZE(X11.Atom));

    X11.XChangeProperty(d.display,
                        window.window,
                        property,
                        D.display(Display).atoms[atomAtom],32,
                        X11.PropModeReplace,
                        tmp,1);

  END SetAtomProperty;

  PROCEDURE (d : Display) SendNetSystemTrayRequestDock(window : X11.Window);

  VAR
    selWin  : X11.Window;
    trayEvt : X11.XEvent;

  BEGIN
    selWin:=X11.XGetSelectionOwner(d.display,
                                   X11.XInternAtom(d.display,
                                                   "_NET_SYSTEM_TRAY_S0",X11.False));
    IF selWin#0 THEN
      trayEvt.xclient.type:=X11.ClientMessage;
      trayEvt.xclient.window:=selWin;
      trayEvt.xclient.message_type:=X11.XInternAtom(d.display,
                                                    "_NET_SYSTEM_TRAY_OPCODE",
                                                    X11.False);
      trayEvt.xclient.format:=32;
      trayEvt.xclient.data.l[0]:=X11.CurrentTime;
      trayEvt.xclient.data.l[1]:=0;
      trayEvt.xclient.data.l[2]:=window;
      trayEvt.xclient.data.l[3]:=0;
      trayEvt.xclient.data.l[4]:=0;
      IF X11.XSendEvent(D.display(Display).display,
                        selWin,
                        X11.False,
                        X11.NoEventMask,
                        s.VAL(X11.XEventPtr,s.ADR(trayEvt)))#0 THEN
      END;
    END;
  END SendNetSystemTrayRequestDock;

(*  PROCEDURE (d : Display) SendNetSystemTrayBaloonMessage(window : X11.Window);

  VAR
    selWin  : X11.Window;
    trayEvt : X11.XEvent;

  BEGIN
    selWin:=X11.XGetSelectionOwner(d.display,
                                   X11.XInternAtom(d.display,
                                                   "_NET_SYSTEM_TRAY_S0",X11.False));
    IF selWin#0 THEN
      trayEvt.xclient.type:=X11.ClientMessage;
      trayEvt.xclient.window:=selWin;
      trayEvt.xclient.message_type:=X11.XInternAtom(d.display,
                                                    "_NET_SYSTEM_TRAY_OPCODE",
                                                    X11.False);
      trayEvt.xclient.format:=32;
      trayEvt.xclient.data.l[0]:=X11.CurrentTime;
      trayEvt.xclient.data.l[1]:=1;
      trayEvt.xclient.data.l[2]:=0;
      trayEvt.xclient.data.l[3]:=4;
      trayEvt.xclient.data.l[4]:=0;
      IF X11.XSendEvent(D.display(Display).display,
                        selWin,
                        X11.False,
                        X11.NoEventMask,
                        s.VAL(X11.XEventPtr,s.ADR(trayEvt)))#0 THEN
      END;

      trayEvt.xclient.message_type:=X11.XInternAtom(d.display,
                                                    "_NET_SYSTEM_TRAY_DATA",
                                                    X11.False);
      trayEvt.xclient.window:=window;
      trayEvt.xclient.format:=8;
      trayEvt.xclient.data.b[0]:="H";
      trayEvt.xclient.data.b[1]:="a";
      trayEvt.xclient.data.b[2]:="l";
      trayEvt.xclient.data.b[3]:="l";
      trayEvt.xclient.data.b[4]:="o";
      trayEvt.xclient.data.b[5]:=0X;
      IF X11.XSendEvent(D.display(Display).display,
                        selWin,
                        X11.False,
                        X11.NoEventMask,
                        s.VAL(X11.XEventPtr,s.ADR(trayEvt)))#0 THEN
      END;

    END;
  END SendNetSystemTrayBaloonMessage;*)

(* ============== Implementation classes ============== *)

  PROCEDURE XFree(pointer : s.PTR);

    (**
      Frees memory allocated using X11 if the pointer is not @code{NIL}.
    *)

  BEGIN
    IF pointer#NIL THEN
      X11.XFree(s.VAL(LONGINT,pointer));
    END;
  END XFree;

  (* -------- font stuff ------------- *)

  PROCEDURE (font : Font) GetFontPos(style : SET):LONGINT;

    (**
      Returns the offset in the font array, that corresponds to the given style.
      uses @oproc{D.StyleToPos}.

      NOTE
      GetFontPos tries to find a "close" font if a font with the given style bits
      does not exist. Currently it sees italic and slanted as equal, so if no italic
      font does exist, it tries a slanted one and vice versa.
    *)

  VAR
    x : LONGINT;

  BEGIN
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    x:=D.StyleToPos(style);

    IF font.xftfonts[x]#NIL THEN
      RETURN x;
    END;

    IF D.slanted IN style THEN
      EXCL(style,D.slanted);
      INCL(style,D.italic);
    ELSIF D.italic IN style THEN
      EXCL(style,D.italic);
      INCL(style,D.slanted);
    END;

    x:=D.StyleToPos(style);
    IF font.xftfonts[x]#NIL THEN
      RETURN x;
    END;

    EXCL(style,D.slanted);
    EXCL(style,D.italic);

    IF font.xftfonts[0]#NIL THEN
      RETURN 0;
    END;

<* END *>
    x:=D.StyleToPos(style);

    IF font.fonts[x]#NIL THEN
      RETURN x;
    END;

    IF D.slanted IN style THEN
      EXCL(style,D.slanted);
      INCL(style,D.italic);
    ELSIF D.italic IN style THEN
      EXCL(style,D.italic);
      INCL(style,D.slanted);
    END;

    x:=D.StyleToPos(style);
    IF font.fonts[x]#NIL THEN
      RETURN x;
    END;

    EXCL(style,D.slanted);
    EXCL(style,D.italic);

    RETURN 0;
  END GetFontPos;

  PROCEDURE (font : Font) TextWidth*(text: ARRAY OF CHAR; length : LONGINT; style : SET):LONGINT;

  VAR
    sEnd,dEnd : LONGINT;

  BEGIN
    D.display(Display).EnlargeUCS2Buffer(length+1);
    D.prefs.localeCodec.Decode(text,0,length,D.display(Display).bufferUCS2^,0,length+1,sEnd,dEnd);
    D.display(Display).bufferUCS2[dEnd]:=0X;

    RETURN font.LongTextWidth(D.display(Display).bufferUCS2^,dEnd,style);
  END TextWidth;

  PROCEDURE (font : Font) LongTextWidth*(text : ARRAY OF LONGCHAR; length : LONGINT; style : SET):LONGINT;

  VAR
    x,pos : LONGINT;
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    info  : Xrender.XGlyphInfo;
<* END *>

  BEGIN
    pos:=font.GetFontPos(style);
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    IF font.xftfonts[pos]#NIL THEN
      Xft.XftTextExtents16(D.display(Display).display,
                           font.xftfonts[pos],
                           text,length,info);
      RETURN info.xOff;
    END;
<* END *>

    IF D.systemByteOrder=D.littleEndian THEN
      FOR x:=0 TO length-1 DO
        IF ORD(text[x])#0 THEN
          text[x]:=CHR(((ORD(text[x]) MOD 256)*256) + (ORD(text[x]) DIV 256));
        END;
      END;
    END;

    RETURN X11.XTextWidth16(font.fonts[pos],text,length);
  END LongTextWidth;

  PROCEDURE (font : Font) StrWidth*(text : STRING; style : SET):LONGINT;

  VAR
    tmp  : Object.CharsLatin1;
    tmp2 : Object.CharsUTF16;

  BEGIN
    WITH
      text : Object.String8 DO
      tmp:=text.CharsLatin1();
      RETURN font.TextWidth(tmp^,text.length,style);
    | text : Object.String16 DO
      tmp2:=text.CharsUTF16();
      RETURN font.LongTextWidth(tmp2^,text.length,style);
    END;
  END StrWidth;

  PROCEDURE (font : Font) TextExtent*(text : ARRAY OF CHAR;
                                      length : LONGINT; style : SET;
                                      VAR extent : D.FontExtentDesc);

  VAR
    sEnd,dEnd : LONGINT;

  BEGIN
    D.display(Display).EnlargeUCS2Buffer(length+1);
    D.prefs.localeCodec.Decode(text,0,length,D.display(Display).bufferUCS2^,0,length+1,sEnd,dEnd);
    D.display(Display).bufferUCS2[dEnd]:=0X;

    font.LongTextExtent(D.display(Display).bufferUCS2^,dEnd,style,extent);
  END TextExtent;

  PROCEDURE (font : Font) LongTextExtent*(text : ARRAY OF LONGCHAR;
                                          length : LONGINT; style : SET;
                                          VAR extent : D.FontExtentDesc);

  VAR
    a,b,c,
    pos   : LONGINT;
    char  : X11.XCharStruct;
    x     : LONGINT;
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    info  : Xrender.XGlyphInfo;
<* END *>

  BEGIN
    pos:=font.GetFontPos(style);
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    IF font.xftfonts[pos]#NIL THEN
      Xft.XftTextExtents16(D.display(Display).display,
                           font.xftfonts[pos],
                           text,length,info);
      extent.width:=info.xOff;
      extent.height:=info.height;
      extent.lbearing:=-info.x;
      extent.rbearing:=-info.x+info.width;
      extent.ascent:=info.y;
      extent.descent:=info.height-info.y;
      RETURN;
    END;
<* END *>

    IF D.systemByteOrder=D.littleEndian THEN
      FOR x:=0 TO LEN(text)-1 DO
        IF ORD(text[x])#0 THEN
          text[x]:=CHR(((ORD(text[x]) MOD 256)*256) + (ORD(text[x]) DIV 256));
        END;
      END;
    END;

    X11.XTextExtents16(font.fonts[pos],text,length,a,b,c,char);
    extent.lbearing:=char.lbearing;
    extent.rbearing:=char.rbearing;
    extent.width:=char.width;
    extent.ascent:=char.ascent;
    extent.descent:=char.descent;
    extent.height:=char.ascent+char.descent;
  END LongTextExtent;

  PROCEDURE (font : Font) StrExtent*(text : STRING;
                                     style : SET;
                                     VAR extent : D.FontExtentDesc);

  VAR
    tmp  : Object.CharsLatin1;
    tmp2 : Object.CharsUTF16;

  BEGIN
    WITH
      text : Object.String8 DO
      tmp:=text.CharsLatin1();
      font.TextExtent(tmp^,text.length,style,extent);
    | text : Object.String16 DO
      tmp2:=text.CharsUTF16();
      font.LongTextExtent(tmp2^,text.length,style,extent);
    END;
  END StrExtent;

  PROCEDURE (font : Font) Init*;

  (**
    Initialize a font object.
  *)

  VAR
    x : LONGINT;

  BEGIN
    font.Init^;

    font.last:=NIL;
    font.next:=NIL;

    font.loaded:=FALSE;
    font.features:={};
    font.useCount:=0;

    FOR x:=0 TO LEN(font.fonts)-1 DO
      font.fonts[x]:=NIL;
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
      font.xftfonts[x]:=NIL;
<* END *>
    END;
  END Init;

  PROCEDURE GetFontElement(VAR source : ARRAY OF CHAR;
                           pos : INTEGER;
                           VAR string : ARRAY OF CHAR);

  VAR
    x1,x2 : INTEGER;

  BEGIN
    x1:=0;
    WHILE (source[x1]#0X) & (pos>0) DO
      IF source[x1]="-" THEN
        DEC(pos);
      END;
      INC(x1);
    END;

    x2:=x1;
    WHILE (source[x2+1]#0X) & (source[x2+1]#"-") DO
      INC(x2);
    END;

    str.Extract(source,x1,x2-x1+1,string);
  END GetFontElement;

  PROCEDURE (font : Font) InitFromFontName(name : ARRAY OF CHAR);

  VAR
    buffer,
    buffer2 : ARRAY 256 OF CHAR;
    res     : co.ConvResults;

  BEGIN
    GetFontElement(name,1,buffer);
    GetFontElement(name,2,buffer2);
    NEW(font.name,str.Length(buffer2)+1);
    COPY(buffer2,font.name^);
    INCL(font.features,D.fontName);

    GetFontElement(name,5,buffer);
    IF buffer="normal" THEN
      font.setWidth:=D.fontNormal;
      INCL(font.features,D.fontSetWidth);
    ELSIF buffer="semicondensed" THEN
      font.setWidth:=D.fontCondensed;
      INCL(font.features,D.fontSetWidth);
    ELSIF buffer="narrow" THEN
      font.setWidth:=D.fontNarrow;
      INCL(font.features,D.fontSetWidth);
    ELSIF buffer="double" THEN
      font.setWidth:=D.fontDouble;
      INCL(font.features,D.fontSetWidth);
    END;

    GetFontElement(name,7,buffer);
    IF buffer#"*" THEN
      co.StrToInt(buffer,font.pixelHeight,res);
      IF res=co.strAllRight THEN
        INCL(font.features,D.fontHeight);
      ELSE
        Err.String("Cannot extract height/7: ");
        Err.String(name);
        Err.Ln;
      END;
    END;

    GetFontElement(name,8,buffer);
    IF buffer#"*" THEN
      co.StrToInt(buffer,font.pointHeight,res);
      IF res=co.strAllRight THEN
        INCL(font.features,D.fontPointHeight);
      ELSE
        Err.String("Cannot extract pointHeight/8: ");
        Err.String(name);
        Err.Ln;
      END;
    END;

    GetFontElement(name,11,buffer);
    IF buffer="p" THEN
      font.spacing:=D.fontProportional;
      INCL(font.features,D.fontSpacing);
    ELSIF buffer="m" THEN
      font.spacing:=D.fontFixed;
      INCL(font.features,D.fontSpacing);
    END;

    GetFontElement(name,12,buffer);
    IF buffer#"*" THEN
      co.StrToInt(buffer,font.avWidth,res);
      IF res=co.strAllRight THEN
        INCL(font.features,D.fontAvWidth);
      ELSE
        Err.String("Cannot extract avWidth/12: ");
        Err.String(name);
        Err.Ln;
      END;
    END;

    GetFontElement(name,13,buffer);
    GetFontElement(name,14,buffer2);
    NEW(font.charSet,str.Length(buffer)+1+str.Length(buffer2)+1);
    COPY(buffer,font.charSet^);
    str.Append("-",font.charSet^);
    str.Append(buffer2,font.charSet^);
    INCL(font.features,D.fontCharSet);

(*    IF info#NIL THEN
      font.ascent:=info.ascent;
      INCL(font.features,fontAscent);

      font.descent:=info.descent;
      INCL(font.features,fontDescent);
    END;*)

  END InitFromFontName;

  PROCEDURE (font : Font) LoadFont(name: ARRAY OF CHAR;
                                   full : BOOLEAN):BOOLEAN;
  (**
    Loads the given font. First tries to find an ressource entry
    with the given name and load the font stored there before falling
    back to the given default.

    This method is X11 specific.
  *)

  VAR
    help : ARRAY 256 OF CHAR;

    PROCEDURE ConvertField(VAR source : ARRAY OF CHAR;
                           pos : INTEGER;
                           string : ARRAY OF CHAR);

    VAR
      x1,x2 : INTEGER;

    BEGIN
      x1:=0;
      WHILE (source[x1]#0X) & (pos>0) DO
        IF source[x1]="-" THEN
          DEC(pos);
        END;
        INC(x1);
      END;

      x2:=x1;
      WHILE (source[x2+1]#0X) & (source[x2+1]#"-") DO
        INC(x2);
      END;

      str.Delete(source,x1,x2-x1+1);
      str.Insert(string,x1,source);
    END ConvertField;

  BEGIN
    IF ~full THEN
      font.InitFromFontName(name);

      NEW(font.fullName,str.Length(name)+1);
      COPY(name,font.fullName^);

      font.fonts[0]:=X11.XLoadQueryFont(D.display(Display).display,name);
      IF font.fonts[0]=NIL THEN
      ELSE
(*        IF ~(D.fontHeight IN font.features) THEN*)
          font.height:=font.fonts[0].ascent+font.fonts[0].descent;
(*        ELSE
          font.height:=font.pixelHeight;
        END;*)
        font.ascent:=font.fonts[0].ascent;
        font.descent:=font.fonts[0].descent;
        RETURN TRUE;
      END;

<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
      font.xftfonts[0]:=Xft.XftFontOpenXlfd(D.display(Display).display,
                                            D.display(Display).scrNum,
                                            name);
      IF font.xftfonts[0]=NIL THEN
      ELSE
(*        IF ~(D.fontHeight IN font.features) THEN*)
          font.height:=font.xftfonts[0].ascent+font.xftfonts[0].descent;
(*        ELSE
          font.height:=font.pixelHeight;
        END;*)
        font.ascent:=font.xftfonts[0].ascent;
        font.descent:=font.xftfonts[0].descent;
        RETURN TRUE;
      END;
<* END *>

      RETURN FALSE;

    ELSE
      font.loaded:=TRUE;
      font.useCount:=1;

      (*font.features:={D.fontHeight,D.fontAscent,D.fontDescent};*)

      IF str2.Match("-*-*-medium-r-*-*-*-*-*-*-*-*-*-*",name) THEN

<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
        IF font.xftfonts[0]#NIL THEN

          COPY(font.fullName^,help);
          ConvertField(help,3,"bold");
          font.xftfonts[D.StyleToPos({D.bold})]:=Xft.XftFontOpenXlfd(D.display(Display).display,
                                                                     D.display(Display).scrNum,
                                                                     help);

          (* italic *)
          COPY(font.fullName^,help);
          ConvertField(help,4,"i");
          font.xftfonts[D.StyleToPos({D.italic})]:=Xft.XftFontOpenXlfd(D.display(Display).display,
                                                                       D.display(Display).scrNum,
                                                                       help);

          (* slanted *)
          COPY(font.fullName^,help);
          ConvertField(help,4,"o");
          font.xftfonts[D.StyleToPos({D.slanted})]:=Xft.XftFontOpenXlfd(D.display(Display).display,
                                                                        D.display(Display).scrNum,
                                                                        help);

          (* bold+italic *)
          COPY(font.fullName^,help);
          ConvertField(help,3,"bold");
          ConvertField(help,4,"i");
          font.xftfonts[D.StyleToPos({D.bold,D.italic})]:=Xft.XftFontOpenXlfd(D.display(Display).display,
                                                                              D.display(Display).scrNum,
                                                                              help);

          (* bold+slanted *)
          COPY(font.fullName^,help);
          ConvertField(help,3,"bold");
          ConvertField(help,4,"o");
          font.xftfonts[D.StyleToPos({D.bold,D.slanted})]:=Xft.XftFontOpenXlfd(D.display(Display).display,
                                                                               D.display(Display).scrNum,
                                                                               help);
          RETURN TRUE;
        END;
<* END *>

        (* bold *)
        COPY(font.fullName^,help);
        ConvertField(help,3,"bold");
        font.fonts[D.StyleToPos({D.bold})]:=X11.XLoadQueryFont(D.display(Display).display,help);

        (* italic *)
        COPY(font.fullName^,help);
        ConvertField(help,4,"i");
        font.fonts[D.StyleToPos({D.italic})]:=X11.XLoadQueryFont(D.display(Display).display,help);

        (* slanted *)
        COPY(font.fullName^,help);
        ConvertField(help,4,"o");
        font.fonts[D.StyleToPos({D.slanted})]:=X11.XLoadQueryFont(D.display(Display).display,help);

        (* bold+italic *)
        COPY(font.fullName^,help);
        ConvertField(help,3,"bold");
        ConvertField(help,4,"i");
        font.fonts[D.StyleToPos({D.bold,D.italic})]:=X11.XLoadQueryFont(D.display(Display).display,help);

        (* bold+slanted *)
        COPY(font.fullName^,help);
        ConvertField(help,3,"bold");
        ConvertField(help,4,"o");
        font.fonts[D.StyleToPos({D.bold,D.slanted})]:=X11.XLoadQueryFont(D.display(Display).display,help);
      END;
    END;
    RETURN TRUE;
  END LoadFont;

  PROCEDURE (d : Display) AddFont(font : Font);

  BEGIN
    font.last:=NIL;
    font.next:=d.fonts;
    IF d.fonts#NIL THEN
      d.fonts.last:=font;
    END;
    d.fonts:=font;
  END AddFont;

  PROCEDURE (font : Font) Load*():D.Font;
    (**
      Loads the font. The OS specific font will be matched by evaluating the
      handed features. Every font loaded must be free using Free.

      RETURNS
      If the font can be loaded the method returns a new instance of font that
      must be used for future uses exspecially when calling Free.
    *)

  VAR
    name   : ARRAY 256 OF CHAR;
    buffer : ARRAY 20 OF CHAR;
    f      : D.Font;

  BEGIN
    name:="-*-";

    (* name *)
    IF D.fontName IN font.features THEN
      str.Append(font.name^,name);
    ELSE
      str.Append("*",name);
    END;

    str.Append("-medium-r-",name);

    (* setWidth *)
    IF D.fontSetWidth IN font.features THEN
      CASE font.setWidth OF
        D.fontNormal:
          str.Append("normal",name);
      | D.fontCondensed:
          str.Append("semicondensed",name);
      | D.fontNarrow:
          str.Append("narrow",name);
      | D.fontDouble:
          str.Append("double",name);
      END;
    ELSE
      str.Append("*",name);
    END;

    str.Append("--",name);

    (* height *)
    IF D.fontHeight IN font.features THEN
      co.IntToStr(font.pixelHeight,buffer);
      str.Append(buffer,name);
    ELSE
      str.Append("*",name);
    END;

    str.Append("-",name);

    (* pointHeight *)
    IF D.fontPointHeight IN font.features THEN
      co.IntToStr(font.pointHeight,buffer);
      str.Append(buffer,name);
    ELSE
      str.Append("*",name);
    END;

    str.Append("-",name);

    (* horizRes *)
    str.Append("*-",name);

    (* vertRes *)
    str.Append("*-",name);

    (* spacing *)
    IF D.fontSpacing IN font.features THEN
      CASE font.spacing OF
        D.fontFixed:
          str.Append("m",name);
      | D.fontProportional:
          str.Append("p",name);
      END;
    ELSE
      str.Append("*",name);
    END;

    str.Append("-",name);

    (* avWidth *)
    IF D.fontAvWidth IN font.features THEN
      co.IntToStr(font.avWidth,buffer);
      str.Append(buffer,name);
    ELSE
      str.Append("*",name);
    END;

    str.Append("-",name);
    IF D.fontCharSet IN font.features THEN
      str.Append(font.charSet^,name);
    ELSE
      str.Append("*",name);
    END;

    f:=D.display(Display).fonts;
    WHILE (f#NIL) & ~str2.Match(name,f(Font).fullName^) DO
      IF f(Font).next#NIL THEN
        f:=f(Font).next(Font);
      ELSE
        f:=NIL;
      END;
    END;

    IF f#NIL THEN
      INC(f(Font).useCount);
      RETURN f;
    END;

    IF font.LoadFont(name,FALSE) THEN
      D.display(Display).AddFont(font);
      RETURN font;
    ELSE
      RETURN NIL;
    END;
  END Load;

  PROCEDURE (font : Font) Free*;

  VAR
    x : LONGINT;

  BEGIN
    DEC(font.useCount);

    IF font.useCount<=0 THEN
      FOR x:=0 TO LEN(font.fonts)-1 DO
        IF font.fonts[x]#NIL THEN
          X11.XFreeFont(D.display(Display).display,font.fonts[x]);
        END;
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
        IF font.xftfonts[x]#NIL THEN
          Xft.XftFontClose(D.display(Display).display,font.xftfonts[x]);
        END;
<* END *>
      END;

      IF font=D.display(Display).fonts THEN
        IF font.next#NIL THEN
          D.display(Display).fonts:=font.next(Font);
          D.display(Display).fonts.last:=NIL;
        END;
      ELSE
        IF font.last#NIL THEN
          font.last.next:=font.next;
        END;
        IF font.next#NIL THEN
          font.next.last:=font.last;
        END;
      END;
    END;
  END Free;

  (* -------- drawinfo stuff ------------- *)

  (* ----------- Clipping ---------------- *)

  PROCEDURE (d : DrawInfo) RecalcClipRegion;
    (**
      Recalces the current clipping regions by analysing the
      current clipping stack.
    *)

  VAR
    pos    : LONGINT;
    region : xu.Region;

  BEGIN
    region:=xu.XCreateRegion();
    xu.XUnionRegion(d.clipStack[d.clipPos].region,region,region);
    pos:=d.clipPos-1;
    WHILE pos>=0 DO
      xu.XIntersectRegion(d.clipStack[pos].region,region,region);
      DEC(pos);
    END;
    xu.XSetRegion(D.display(Display).display,d.gc,region);

<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    Xft.XftDrawSetClip(d.xftgc,region);
<* END *>
    xu.XDestroyRegion(region);
  END RecalcClipRegion;

  PROCEDURE (VAR c : ClipEntryDesc) Init(draw : DrawInfo);
  (**
    Initializes a clip entry object.
  *)

  BEGIN
    c.region:=xu.XCreateRegion();
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
    rect : X11.XRectanglePtr;

  BEGIN
    s.NEW(rect,SIZE(X11.XRectangle));
    rect.x:=SHORT(x);
    rect.y:=SHORT(y);
    rect.width:=SHORT(width);
    rect.height:=SHORT(height);
    xu.XUnionRectWithRegion(rect,c.region,c.region);
    c.draw.RecalcClipRegion;
  END Add;

  PROCEDURE (VAR c : ClipEntryDesc) Sub(x,y,width,height : LONGINT);
  (**
    adds the given rectangle to the current clip entry.
  *)

  VAR
    rect   : X11.XRectanglePtr;
    region : xu.Region;

  BEGIN
    s.NEW(rect,SIZE(X11.XRectangle));
    rect.x:=SHORT(x);
    rect.y:=SHORT(y);
    rect.width:=SHORT(width);
    rect.height:=SHORT(height);

    region:=xu.XCreateRegion();
    xu.XUnionRectWithRegion(rect,region,region);
    xu.XSubtractRegion(c.region,region,c.region);
    xu.XDestroyRegion(region);

    c.draw.RecalcClipRegion;
  END Sub;

  PROCEDURE (VAR c : ClipEntryDesc) Free;
  (**
    Frees the given clip entry.
  *)

  BEGIN
    xu.XDestroyRegion(c.region);
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
    xu.XSetRegion(D.display(Display).display,d.gc,d.clipStack[0].region);
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
    rect : X11.XRectangle;

  BEGIN
    xu.XClipBox(d.clipStack[d.clipPos].region,rect);
    x:=rect.x;
    y:=rect.y;
    w:=rect.width;
    h:=rect.height;
  END GetClipRegion;

  PROCEDURE (d : DrawInfo) FreeLastClip*;

  BEGIN
    d.clipStack[d.clipPos].Free;
    DEC(d.clipPos);
    IF d.clipPos>=0 THEN
      d.clipStack[d.clipPos].Install;
    END;
  END FreeLastClip;

  PROCEDURE (d : DrawInfo) Init(window : X11.Drawable);
  (**
    Initialize an instance of the  DrawInfo class.
  *)

  VAR
    mask   : X11.ulongmask;
    values : X11.XGCValues;

  BEGIN
    d.window:=window;
    mask:={};
    d.gc:=X11.XCreateGC(D.display(Display).display,window,mask,values);
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    d.xftgc:=Xft.XftDrawCreate(D.display(Display).display,
                               window,
                               D.display(Display).visual,
                               D.display(Display).colorMap);
    IF d.xftgc=NIL THEN
      Err.String("Cannot get Xft.Draw!"); Err.Ln;
    END;

<* END *>
    X11.XSetArcMode(D.display(Display).display,d.gc,X11.ArcPieSlice);
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

<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    Xft.XftDrawDestroy(d.xftgc);
<* END *>
    X11.XFreeGC(D.display(Display).display,d.gc);
  END Deinit;

  PROCEDURE (d : DrawInfo) PushFont*(font : D.Font; style : SET);

  VAR
    help      : FontStack;
    pos       : LONGINT;
    sysHandle : X11.XFontStructPtr;

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

      IF ~font(Font).loaded THEN
        IF font(Font).LoadFont(font(Font).fullName^,TRUE) THEN END;
      END;

      d.fontStack[d.fontPos].font:=font(Font);
      d.fontStack[d.fontPos].style:=style;
      d.fontStack[d.fontPos].count:=1;

      pos:=font(Font).GetFontPos(style);
      IF font(Font).fonts[pos]#NIL THEN
        sysHandle:=font(Font).fonts[pos];
        X11.XSetFont(D.display(Display).display,d.gc,sysHandle.fid);
      END;
    END;
  END PushFont;

  PROCEDURE (d : DrawInfo) PopFont*;

  VAR
    pos       : LONGINT;
    sysHandle : X11.XFontStructPtr;
    font      : D.Font;

  BEGIN
    IF d.fontStack[d.fontPos].count>1 THEN
      DEC(d.fontStack[d.fontPos].count);
    ELSE
      DEC(d.fontPos);
      IF d.fontPos>=0 THEN
        font:=d.fontStack[d.fontPos].font;

        pos:=font(Font).GetFontPos(d.fontStack[d.fontPos].style);
        IF font(Font).fonts[pos]#NIL THEN
          sysHandle:=font(Font).fonts[pos];
          X11.XSetFont(D.display(Display).display,d.gc,sysHandle.fid);
        END;
      END;
    END;
  END PopFont;

  PROCEDURE (d : DrawInfo) DrawString*(x,y : LONGINT; text : ARRAY OF CHAR; length : LONGINT);

  VAR
    sEnd,dEnd : LONGINT;

  BEGIN
    D.display(Display).EnlargeUCS2Buffer(length+1);
    D.prefs.localeCodec.Decode(text,0,length,D.display(Display).bufferUCS2^,0,length+1,sEnd,dEnd);
    D.display(Display).bufferUCS2[dEnd]:=0X;

    d.DrawLongString(x,y,D.display(Display).bufferUCS2^,dEnd);
  END DrawString;

  PROCEDURE (d : DrawInfo) DrawLongString*(x,y : LONGINT; text : ARRAY OF LONGCHAR; length : LONGINT);

  VAR
    i       : LONGINT;
    handled : BOOLEAN;
    extent  : D.FontExtentDesc;
    font    : Font;
    a,b,c   : LONGINT;
    char    : X11.XCharStruct;
    pos     : LONGINT;
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    color   : Xft.XftColor;
    xcolor  : X11.XColor;
    info    : Xrender.XGlyphInfo;
<* END *>

  BEGIN
    handled:=FALSE;
    pos:=d.fontStack[d.fontPos].font.GetFontPos(d.fontStack[d.fontPos].style);
    font:=d.fontStack[d.fontPos].font;

<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
    IF d.fontStack[d.fontPos].font.xftfonts[0]#NIL THEN
      xcolor.pixel:=d.fPenStack[d.fPenPos].color;
      X11.XQueryColor(D.display(Display).display,D.display(Display).colorMap,xcolor);
      color.pixel:=d.fPenStack[d.fPenPos].color;
      color.color.red:=xcolor.red;
      color.color.blue:=xcolor.blue;
      color.color.green:=xcolor.green;
      color.color.alpha:=-1;

      Xft.XftDrawString16(d.xftgc,color,font.xftfonts[pos],x,y,text,length);
      handled:=TRUE;
    END;
<* END *>

    IF ~handled THEN
      IF D.systemByteOrder=D.littleEndian THEN
        FOR i:=0 TO LEN(text)-1 DO
          IF ORD(text[i])#0 THEN
            text[i]:=LONGCHR(((ORD(text[i]) MOD 256)*256) + (ORD(text[i]) DIV 256));
          END;
        END;
      END;

      X11.XDrawString16(D.display(Display).display,d.window,d.gc,x,y,text,length);
      handled:=TRUE;
    END;

    (* Under X11 we must draw a line manually for underlined text *)

    IF D.underlined IN d.fontStack[d.fontPos].style THEN
      handled:=FALSE;
<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>
      IF d.fontStack[d.fontPos].font.xftfonts[0]#NIL THEN
        Xft.XftTextExtents16(D.display(Display).display,
                             font.xftfonts[pos],
                             text,length,info);
        extent.width:=info.width;
        extent.height:=info.height;
        extent.lbearing:=-info.x;
        extent.rbearing:=info.xOff;
        extent.ascent:=info.y;
        extent.descent:=info.height-info.y;
        handled:=TRUE;
      END;
<* END *>
      IF ~handled THEN
        X11.XTextExtents16(font.fonts[pos],text,length,a,b,c,char);
        extent.lbearing:=char.lbearing;
        extent.rbearing:=char.rbearing;
        extent.width:=char.width;
        extent.ascent:=char.ascent;
        extent.descent:=char.descent;
        extent.height:=char.ascent+char.descent;
      END;

      d.DrawLine(x,y,x+extent.width,y);

    END;
  END DrawLongString;

  PROCEDURE (d : DrawInfo) DrawFillString*(x,y : LONGINT; text : ARRAY OF CHAR; length : LONGINT);

  VAR
    sEnd,dEnd : LONGINT;

  BEGIN
    D.display(Display).EnlargeUCS2Buffer(length+1);
    D.prefs.localeCodec.Decode(text,0,length,D.display(Display).bufferUCS2^,0,length+1,sEnd,dEnd);
    D.display(Display).bufferUCS2[dEnd]:=0X;

    d.DrawFillLongString(x,y,D.display(Display).bufferUCS2^,dEnd);
  END DrawFillString;

  PROCEDURE (d : DrawInfo) DrawFillLongString*(x,y : LONGINT; text : ARRAY OF LONGCHAR; length : LONGINT);

  VAR i : LONGINT;

  BEGIN
    IF D.systemByteOrder=D.littleEndian THEN
      FOR i:=0 TO LEN(text)-1 DO
        IF ORD(text[i])#0 THEN
          text[i]:=LONGCHR(((ORD(text[i]) MOD 256)*256) + (ORD(text[i]) DIV 256));
        END;
      END;
    END;

    X11.XDrawImageString16(D.display(Display).display,d.window,d.gc,x,y,text,length);
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

      X11.XSetForeground(D.display(Display).display,d.gc,color);
    END;
  END PushForeground;

  PROCEDURE (d : DrawInfo) PopForeground*;

  BEGIN
    IF d.fPenStack[d.fPenPos].count>1 THEN
      DEC(d.fPenStack[d.fPenPos].count);
    ELSE
      DEC(d.fPenPos);
      IF d.fPenPos>=0 THEN
        X11.XSetForeground(D.display(Display).display,d.gc,
                           d.fPenStack[d.fPenPos].color);
      END;
    END;
  END PopForeground;

  PROCEDURE (d : DrawInfo) PushDrawMode*(mode : LONGINT);

  VAR
    m     : DrawMode;
    xMode : INTEGER;

  BEGIN
    NEW(m);
    m.mode:=mode;
    CASE mode OF
      D.copy:
        xMode:=X11.GXcopy;
    | D.invert:
        xMode:=X11.GXinvert;
    END;
    X11.XSetFunction(D.display(Display).display,d.gc,xMode);
    m.next:=d.modeStack;
    d.modeStack:=m;
  END PushDrawMode;

  PROCEDURE (d : DrawInfo) PopDrawMode*;

  VAR
   xMode : INTEGER;

  BEGIN
    d.modeStack:=d.modeStack.next;
    IF d.modeStack#NIL THEN
      CASE d.modeStack.mode OF
        D.copy:
          xMode:=X11.GXcopy;
      | D.invert:
          xMode:=X11.GXinvert;
      END;
      X11.XSetFunction(D.display(Display).display,d.gc,xMode);
    ELSE
      X11.XSetFunction(D.display(Display).display,d.gc,X11.GXcopy);
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

      X11.XSetBackground(D.display(Display).display,d.gc,color);
    END;
  END PushBackground;

  PROCEDURE (d : DrawInfo) PopBackground*;

  BEGIN
    IF d.bPenStack[d.bPenPos].count>1 THEN
      DEC(d.bPenStack[d.bPenPos].count);
    ELSE
      DEC(d.bPenPos);
      IF d.bPenPos>=0 THEN
        X11.XSetBackground(D.display(Display).display,d.gc,
                           d.bPenStack[d.bPenPos].color);
      END;
    END;
  END PopBackground;

  PROCEDURE (d : DrawInfo) PushStyle*(size, mode : LONGINT);

  VAR
    pen  : PenStyle;
    lMode : LONGINT;

  BEGIN
    NEW(pen);
    pen.size:=size;
    pen.mode:=mode;
    IF mode=D.roundPen THEN
      pen.cap:=X11.CapRound;
      pen.join:=X11.JoinRound;
    ELSE
      pen.cap:=X11.CapButt;
      pen.join:=X11.JoinBevel;
    END;

    IF d.dashStack#NIL THEN
      lMode:=d.dashStack.mode;
    ELSE
      lMode:=X11.LineSolid;
    END;

    X11.XSetLineAttributes(D.display(Display).display,d.gc,pen.size,lMode,pen.cap,pen.join);
    pen.next:=d.styleStack;
    d.styleStack:=pen;

  END PushStyle;

  PROCEDURE (d : DrawInfo) PopStyle*;

  VAR
    mode : LONGINT;

  BEGIN
    d.styleStack:=d.styleStack.next;

    IF d.dashStack#NIL THEN
      mode:=d.dashStack.mode;
    ELSE
      mode:=X11.LineSolid;
    END;

    IF d.styleStack#NIL THEN
      X11.XSetLineAttributes(D.display(Display).display,d.gc,d.styleStack.size,mode,d.styleStack.cap,d.styleStack.join);
    ELSE
      X11.XSetLineAttributes(D.display(Display).display,d.gc,0,mode,X11.CapButt,X11.JoinBevel);
    END;
  END PopStyle;

  PROCEDURE (d : DrawInfo) PushDash*(dashList : ARRAY OF CHAR; mode : LONGINT);

  VAR
    dash   : PenDash;
    size,
    cap,
    join,x : LONGINT;

  BEGIN
    NEW(dash);
    dash.next:=NIL;
    NEW(dash.list,LEN(dashList));
    FOR x:=0 TO LEN(dashList)-1 DO
      dash.list[x]:=dashList[x];
    END;

    IF mode=D.fMode THEN
      dash.mode:=X11.LineOnOffDash;
    ELSE
      dash.mode:=X11.LineDoubleDash;
    END;

    IF d.styleStack#NIL THEN
      size:=d.styleStack.size;
      cap:=d.styleStack.cap;
      join:=d.styleStack.join;
    ELSE
      size:=0;
      cap:=X11.CapButt;
      join:=X11.JoinBevel;
    END;

    X11.XSetLineAttributes(D.display(Display).display,d.gc,size,dash.mode,cap,join);
    X11.XSetDashes(D.display(Display).display,d.gc,0,dash.list^,LEN(dashList));

    dash.next:=d.dashStack;
    d.dashStack:=dash;
  END PushDash;

  PROCEDURE (d : DrawInfo) PopDash*;

  VAR
    size,
    cap,
    join : LONGINT;

  BEGIN
    d.dashStack:=d.dashStack.next;

    IF d.styleStack#NIL THEN
      size:=d.styleStack.size;
      cap:=d.styleStack.cap;
      join:=d.styleStack.join;
    ELSE
      size:=0;
      cap:=X11.CapButt;
      join:=X11.JoinBevel;
    END;


    IF d.dashStack#NIL THEN
      X11.XSetLineAttributes(D.display(Display).display,d.gc,size,d.dashStack.mode,cap,join);
    ELSE
      X11.XSetLineAttributes(D.display(Display).display,d.gc,0,X11.LineSolid,X11.CapButt,X11.JoinBevel);
    END;
  END PopDash;

  PROCEDURE (d : DrawInfo) PushPattern*(pattern : ARRAY OF CHAR; width, height : LONGINT; mode : LONGINT);

  VAR
    pat : Pattern;

  BEGIN
    NEW(pat);
    pat.pixMap:=X11.XCreateBitmapFromData(D.display(Display).display,
                    X11.XRootWindow(D.display(Display).display,D.display(Display).scrNum),
                    pattern,width,height);
    IF pat.pixMap=0 THEN
      Err.String("Cannot create pimap!");Err.Ln;
    END;
    pat.mode:=mode;

    X11.XSetStipple(D.display(Display).display,d.gc,pat.pixMap);
    CASE mode OF
      D.fgPattern:
        X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillStippled);
    | D.fbPattern:
        X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillOpaqueStippled);
    ELSE
      Err.String("Unsuported patternMode!"); Err.Ln;
    END;
    pat.next:=d.patternStack;
    d.patternStack:=pat;
  END PushPattern;

  PROCEDURE (d : DrawInfo) PopPattern*;

  BEGIN
    X11.XFreePixmap(D.display(Display).display,d.patternStack.pixMap);
    d.patternStack:=d.patternStack.next;
    IF d.patternStack#NIL THEN

      CASE d.patternStack.mode OF
        D.fgPattern:
          X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillStippled);
      | D.fbPattern:
          X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillOpaqueStippled);
      ELSE
       Err.String("Unsuported patternMode!"); Err.Ln;
      END;
      X11.XSetStipple(D.display(Display).display,d.gc,d.patternStack.pixMap);

    ELSE
      X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillSolid);
    END;
  END PopPattern;

  PROCEDURE (d : DrawInfo) PushBitmap*(bitmap : D.Bitmap; mode : LONGINT);

  VAR
    pat : Pattern;

  BEGIN
    NEW(pat);
    pat.pixMap:=bitmap(Bitmap).pixmap;
    pat.mode:=mode;

    X11.XSetStipple(D.display(Display).display,d.gc,pat.pixMap);
    CASE mode OF
      D.fgPattern:
        X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillStippled);
    | D.fbPattern:
        X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillOpaqueStippled);
    ELSE
      Err.String("Unsuported patternMode!"); Err.Ln;
    END;
    pat.next:=d.patternStack;
    d.patternStack:=pat;
  END PushBitmap;

  PROCEDURE (d : DrawInfo) PopBitmap*;

  BEGIN
    d.patternStack:=d.patternStack.next;
    IF d.patternStack#NIL THEN

      CASE d.patternStack.mode OF
        D.fgPattern:
          X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillStippled);
      | D.fbPattern:
          X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillOpaqueStippled);
      ELSE
       Err.String("Unsuported patternMode!"); Err.Ln;
      END;
      X11.XSetStipple(D.display(Display).display,d.gc,d.patternStack.pixMap);

    ELSE
      X11.XSetFillStyle(D.display(Display).display,d.gc,X11.FillSolid);
    END;
  END PopBitmap;

  (* Drawing functions *)

  PROCEDURE (d : DrawInfo) DrawPoint*(x,y : LONGINT);

  BEGIN
    X11.XDrawPoint(D.display(Display).display,d.window,d.gc,x,y);
  END DrawPoint;

  PROCEDURE (d : DrawInfo) DrawPointWithColor*(x,y : LONGINT; color : D.Color);

  BEGIN
    <*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>
    X11.XSetForeground(D.display(Display).display,d.gc,color);
    X11.XDrawPoint(D.display(Display).display,d.window,d.gc,x,y);
    IF d.fPenPos>=0 THEN
      X11.XSetForeground(D.display(Display).display,d.gc,
                         d.fPenStack[d.fPenPos].color);
    END;
    <* POP *>
  END DrawPointWithColor;

  PROCEDURE (d : DrawInfo) DrawLine*(x1,y1,x2,y2 : LONGINT);

  BEGIN
    X11.XDrawLine(D.display(Display).display,d.window,d.gc,x1,y1,x2,y2);
  END DrawLine;

  PROCEDURE (d : DrawInfo) DrawRectangle*(x,y,width,height : LONGINT);

  BEGIN
    d.DrawLine(x,y+height-1,x,y+1);
    d.DrawLine(x,y,x+width-1,y);
    d.DrawLine(x+width-1,y+1,x+width-1,y+height-1);
    d.DrawLine(x+width-1,y+height-1,x,y+height-1);
  END DrawRectangle;

  PROCEDURE (d : DrawInfo) FillRectangle*(x,y,width,height : LONGINT);

  BEGIN
    X11.XFillRectangle(D.display(Display).display,d.window,d.gc,x,y,width,height);
  END FillRectangle;

  PROCEDURE (d : DrawInfo) FillRectangleAlpha*(alpha : LONGINT; x,y,width,height : LONGINT);

<* IF (HAVE_LIB_XFT=TRUE) OR (HAVE_LIB_XFT2=TRUE) THEN *>

  VAR
    color  : Xft.XftColor;
    xcolor : X11.XColor;

  BEGIN
    xcolor.pixel:=d.fPenStack[d.fPenPos].color;
    X11.XQueryColor(D.display(Display).display,D.display(Display).colorMap,xcolor);

    color.pixel:=d.fPenStack[d.fPenPos].color;
    color.color.red:=xcolor.red;
    color.color.blue:=xcolor.blue;
    color.color.green:=xcolor.green;
    color.color.alpha:=SHORT(alpha);
    Xft.XftDrawRect(d.xftgc,color,x,y,width,height);

<* ELSE *>

  BEGIN
    X11.XFillRectangle(D.display(Display).display,d.window,d.gc,x,y,width,height);

<* END *>

  END FillRectangleAlpha;

  PROCEDURE (d : DrawInfo) InvertRectangle*(x,y,width,height : LONGINT);

  BEGIN
    d.PushDrawMode(D.invert);
    d.FillRectangle(x,y,width,height);
    d.PopDrawMode;
  END InvertRectangle;

  PROCEDURE (d : DrawInfo) DrawArc*(x,y,width,height,angle1,angle2 : LONGINT);

  BEGIN
    X11.XDrawArc(D.display(Display).display,d.window,d.gc,x,y,width-1,height-1,angle1,angle2);
  END DrawArc;

  PROCEDURE (d : DrawInfo) FillArc*(x,y,width,height,angle1,angle2 : LONGINT);

  BEGIN
    X11.XFillArc(D.display(Display).display,d.window,d.gc,x,y,width,height,angle1,angle2);
  END FillArc;

  PROCEDURE (d : DrawInfo) FillPolygon*(points : ARRAY OF D.PointDesc;
                                        count : LONGINT);

  VAR
    x : LONGINT;

  BEGIN
    (*D.display(Display).EnlargePointArray(count);*)
    FOR x:=0 TO count-1 DO
      D.display(Display).pointArray[x].x:=SHORT(points[x].x);
      D.display(Display).pointArray[x].y:=SHORT(points[x].y);
    END;
    (*    X11.XFillPolygon(D.display(Display).display,d.window,d.gc,D.display(Display).pointArray^,count,X11.Complex,X11.CoordModeOrigin);*)
    X11.XFillPolygon(D.display(Display).display,d.window,d.gc,D.display(Display).pointArray,count,X11.Complex,X11.CoordModeOrigin);
  END FillPolygon;

  PROCEDURE (d : DrawInfo) CopyArea*(sX,sY,width,height,dX,dY : LONGINT);

  BEGIN
    X11.XSetGraphicsExposures(D.display(Display).display,d.gc,X11.True);
    X11.XCopyArea(D.display(Display).display,d.window,d.window,d.gc,
                  sX,sY,width,height,dX,dY);
    X11.XSetGraphicsExposures(D.display(Display).display,d.gc,X11.False);
  END CopyArea;

  PROCEDURE (d : DrawInfo) CopyFromBitmap*(bitmap : D.Bitmap;
                                           sX,sY,width,height,dX,dY : LONGINT);

    (**
      Copy the rectangle @oparam{sY}, @oparam{sY}-@oparam{width}, @oparam{height}
      to the current DrawInfo starting at position @oparam{dX}, @oparam{dY}.
    *)

  BEGIN
    X11.XCopyArea(D.display(Display).display,
                  bitmap(Bitmap).pixmap,
                  d.window,
                  d.gc,
                  sX,sY,width,height,dX,dY);
  END CopyFromBitmap;

  PROCEDURE (d : DrawInfo) CopyToBitmap*(sX,sY,width,height,dX,dY : LONGINT;
                                         bitmap : D.Bitmap);

  BEGIN
    X11.XSetGraphicsExposures(D.display(Display).display,d.gc,X11.True);
    X11.XCopyArea(D.display(Display).display,
                  d.window,bitmap(Bitmap).pixmap,bitmap.draw(DrawInfo).gc,
                  sX,sY,width,height,dX,dY);
    X11.XSetGraphicsExposures(D.display(Display).display,d.gc,X11.False);
  END CopyToBitmap;

  (* ------------ Data Exchange stuff --------------- *)

  (**
    Initializes an Data object.
  *)

(*  PROCEDURE (data : Data) Init*;

  BEGIN
    data.type:=none;
    data.length:=0;

    data.string:=NIL;
    data.ints:=NIL;
    data.longs:=NIL;

    data.xData:=NIL;
  END Init;

  PROCEDURE (data : Data) Free*;

  BEGIN
    IF data.xData#NIL THEN
      XFree(data.xData);
    END;
  END Free;

  PROCEDURE (data : Data) InitFromX(window : Window; event : X11.XSelectionEvent):BOOLEAN;

  VAR
    retType     : X11.Atom;
    retFormat,
    itemsReturn,
    bytesLeft   : LONGINT;
    delete      : X11.Bool;

  BEGIN
    data.Init;

    IF event.property=X11.None THEN
      Err.String("Selection denied"); Err.Ln;
      RETURN FALSE;
    END;

    IF window.display.dragging THEN
      delete:=X11.False;
    ELSE
      delete:=X11.True;
    END;

    IF X11.XGetWindowProperty(window.display.display,
        event.requestor,event.property,0,MAX(LONGINT),delete,
        X11.AnyPropertyType,retType,retFormat,itemsReturn,bytesLeft,
        data.xData)#X11.Success THEN
        Err.String("Cannot get property"); Err.Ln;
        RETURN FALSE;
    END;

    IF retType=X11.None THEN
      RETURN FALSE;
    END;

    CASE retType OF
      a.XA_STRING: data.type:=text;
    ELSE
      RETURN FALSE;
    END;

    CASE retFormat OF
       8: NEW(data.string,itemsReturn+1);
          s.MOVE(s.VAL(LONGINT,data.xData),
                 s.VAL(LONGINT,data.string),itemsReturn);
          data.string[itemsReturn]:=0X;

          Err.String(">>"); Err.String(data.string^); Err.String("<<"); Err.Ln;

    | 16: NEW(data.ints,itemsReturn+1);
          s.MOVE(s.VAL(LONGINT,data.xData),
                 s.VAL(LONGINT,data.ints),itemsReturn*2);
    | 32: NEW(data.longs,itemsReturn+1);
          s.MOVE(s.VAL(LONGINT,data.xData),
                 s.VAL(LONGINT,data.longs),itemsReturn*4);
    END;

    data.length:=itemsReturn;

    IF window.display.dragging THEN
      Err.String("Finishing drop selection"); Err.Ln;
      X11.XConvertSelection(window.display.display,
                            window.display.dSelection,
                            window.display.dndSuccess,
                            window.display.xSelection,
                            window.window,X11.CurrentTime);
      window.display.dragging:=FALSE;
    END;

    RETURN TRUE;
  END InitFromX;

  PROCEDURE (data : Data) InitToX(VAR event : X11.XSelectionEvent):BOOLEAN;

  VAR
    retType     : X11.Atom;
    retFormat,
    itemsReturn,
    bytesLeft   : LONGINT;

  BEGIN
    IF (event.target=a.XA_STRING) & (data.string#NIL) THEN

      IF X11.XGetWindowProperty(event.display,
        event.requestor,event.property,0,MAX(LONGINT),X11.False,
        event.target,retType,retFormat,itemsReturn,bytesLeft,
        data.xData)#X11.Success THEN
          Err.String("Cannot get property"); Err.Ln;
          RETURN FALSE;
      END;

      X11.XChangeProperty(event.display,event.requestor,event.property,
                          a.XA_STRING,8,
                          X11.PropModeReplace,data.string^,
                          str.Length(data.string^));
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END InitToX;*)

  PROCEDURE (d : Display) GetWindowOnScreen(VAR rX,rY,cX,cY : LONGINT):X11.Window;
  (**
    Returns the window currently under the mouse pointer. It also returns the
    screen relative and window relative mouse coordinates.
  *)

  VAR
    help,rW,cW  : LONGINT;
    dragWin     : X11.Window;
    mask        : SET;

    retType     : X11.Atom;
    retFormat,
    itemsReturn,
    bytesLeft   : LONGINT;
    data        : C.string;

  BEGIN
    dragWin:=0;
    data:=NIL;
    itemsReturn:=0;

    IF X11.XQueryPointer(d.display,X11.XRootWindow(d.display,0),
                         rW,cW,rX,rY,cX,cY,mask)=X11.True THEN

      WHILE (rW#0) & (dragWin=0) & (cW#0) & (rW#cW) DO
        IF (X11.XGetWindowProperty(d.display,
                                   cW,d.atoms[wmStateAtom],0,MAX(LONGINT),X11.False,
                                   X11.AnyPropertyType,retType,retFormat,itemsReturn,
                                   bytesLeft,data)=X11.Success) & (retType#X11.None) THEN
          dragWin:=cW;
        END;

        IF rW#0 THEN
          help:=cW;
          IF X11.XTranslateCoordinates(d.display,
                                       rW,cW,cX,cY,cX,cY,cW)=X11.True THEN
            rW:=help;
          ELSE
            Err.String("Cannot convert coordinates!"); Err.Ln;
            rW:=0;
          END;
        END;
      END;
    END;
    RETURN dragWin;
  END GetWindowOnScreen;

  PROCEDURE (d : Display) GetWindow(window : X11.Window):Window;
  (**
    Get the VO window matching the given X11 window.
  *)

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
    IF d.contextTimer.active THEN
      d.RemoveTimer(d.contextTimer);
    END;
    d.AddTimer(d.contextTimer);
    d.contextHelp:=TRUE;
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

  PROCEDURE (d : Display) GetFontList*():D.FontList;

  VAR
    count,
    x,y,
    size     : LONGINT;
    names    : C.charPtr2d;
    name     : D.FontName;
    field,
    field2   : D.FontName;
    res      : co.ConvResults;

    list     : D.FontList;
    foundry  : D.FontFoundry;
    family   : D.FontFamily;
    encoding : D.FontEncoding;
    fSize    : D.FontSize;

<* IF HAVE_LIB_FONTCONFIG=TRUE THEN *>
    config   : fc.FcConfigPtr;
    pattern,
    pattern2 : fc.FcPatternPtr;
    set,
    set2     : fc.FcFontSetPtr;
    oSet,
    oSet2    : fc.FcObjectSetPtr;
    buffer,
    buffer2  : fc.FcChar8Ptr;
    z        : LONGINT;
    fName    : D.FontName;
<* ELSIF HAVE_LIB_XFT=TRUE THEN *>
    fName    : D.FontName;
    set,
    set2     : Xft.XftFontSetPtr;
    z,t      : LONGINT;
    tmp      : C.string;
<* END *>

  BEGIN
    NEW(list);
    list.families:=NIL;

    names:=X11.XListFonts(d.display,"-*-*-medium-r-*--*-*-*-*-*-*-*-*",
                          MAX(INTEGER),count);

    IF (names#NIL) & (count>0) THEN

      FOR x:=0 TO count-1 DO
        y:=0;
        WHILE names[x][y]#0X DO
          name[y]:=names[x][y];
          INC(y);
        END;
        name[y]:=0X;

        GetFontElement(name,2,field);

        y:=0;
        WHILE field[y]#0X DO
          IF (y=0) OR (field[y-1]=" ") THEN
            field[y]:=CAP(field[y]);
          END;
          INC(y);
        END;
        family:=list.GetOrCreateFamily(field);

        GetFontElement(name,1,field);

        IF field="" THEN
          field:="X11";
        END;

        foundry:=family.GetOrCreateFoundry(field);

        GetFontElement(name,13,field);
        GetFontElement(name,14,field2);
        str.Append("-",field);
        str.Append(field2,field);

        encoding:=foundry.GetOrCreateEncoding(field);

        GetFontElement(name,7,field);
        IF field#"*" THEN
          co.StrToInt(field,size,res);

          IF size#0 THEN
            IF ~encoding.anySize THEN
              fSize:=encoding.GetOrCreateSize(size);
            END;
          ELSE
            encoding.anySize:=TRUE;
            encoding.sizes:=NIL;
          END;
        END;

      END;
    END;

    X11.XFreeFontNames(names);

<* IF HAVE_LIB_FONTCONFIG=TRUE THEN *>
    config:=fc.FcInitLoadConfigAndFonts();

    oSet:=fc.FcObjectSetCreate();
    fc.FcObjectSetAdd(oSet,fc.FC_FOUNDRY);

    oSet2:=fc.FcObjectSetCreate();
    fc.FcObjectSetAdd(oSet2,fc.FC_FAMILY);

    pattern:=fc.FcPatternCreate();

    set:=fc.FcFontList(config,pattern,oSet);

    FOR x:=0 TO set.nfont-1 DO
      IF fc.FcPatternGetString(set.fonts[x],fc.FC_FOUNDRY,0,buffer)=0 THEN
        z:=0;
        WHILE buffer[z]#0X DO
          fName[z]:=buffer[z];
          INC(z);
        END;
        fName[z]:=0X;

        pattern2:=fc.FcPatternCreate();
        IF fc.FcPatternAddString(pattern2,fc.FC_FOUNDRY,buffer^) THEN END;
        set2:=fc.FcFontList(config,pattern2,oSet2);
        fc.FcPatternDestroy(pattern2);
      ELSE
        fName:="Xft";
        set2:=fc.FcFontList(config,pattern,oSet2);
      END;

      FOR y:=0 TO set2.nfont-1 DO
        IF fc.FcPatternGetString(set2.fonts[y],fc.FC_FAMILY,0,buffer2)=0 THEN
          z:=0;
          WHILE buffer2[z]#0X DO
            IF (z=0) OR (buffer2[z-1]=" ") THEN
              name[z]:=CAP(buffer2[z]);
            ELSE
              name[z]:=buffer2[z];
            END;
            INC(z);
          END;
          name[z]:=0X;

          family:=list.GetOrCreateFamily(name);

          foundry:=family.GetOrCreateFoundry(fName);
          encoding:=foundry.GetOrCreateEncoding(unicodeEncoding);
        END;
      END;

      fc.FcFontSetDestroy(set2);
    END;

    fc.FcFontSetDestroy(set);
    <* ELSIF HAVE_LIB_XFT=TRUE THEN *>

    set:=Xft.XftListFonts(D.display(Display).display,
                          D.display(Display).scrNum,
                          NIL,
                          Xft.XFT_FOUNDRY,
                          NIL);

    IF set#NIL THEN
      FOR x:=0 TO set.nfont-1 DO
        IF Xft.XftPatternGetString(set.fonts[x],Xft.XFT_FOUNDRY,0,tmp)=0 THEN
          z:=0;
          WHILE tmp[z]#0X DO
            fName[z]:=tmp[z];
            INC(z);
          END;
          fName[z]:=0X;

          set2:=Xft.XftListFonts(D.display(Display).display,
                                 D.display(Display).scrNum,
                                 Xft.XFT_FOUNDRY,Xft.XftTypeString,s.ADR(fName[0]),
                                 NIL,
                                 Xft.XFT_FAMILY,
                                 Xft.XFT_ENCODING,
                                 NIL);
        ELSE
          fName:="Xft";
          set2:=Xft.XftListFonts(D.display(Display).display,
                                 D.display(Display).scrNum,
                                 NIL,
                                 Xft.XFT_FAMILY,
                                 Xft.XFT_ENCODING,
                                 NIL);
        END;

        FOR y:=0 TO set2.nfont-1 DO
          IF Xft.XftPatternGetString(set2.fonts[y],Xft.XFT_FAMILY,0,tmp)=0 THEN
            z:=0;
            WHILE tmp[z]#0X DO
              IF (z=0) OR (name[z-1]=" ") THEN
                name[z]:=CAP(tmp[z]);
              ELSE
                name[z]:=tmp[z];
              END;
              INC(z);
            END;
            name[z]:=0X;

            family:=list.GetOrCreateFamily(name);
            foundry:=family.GetOrCreateFoundry(fName);

            t:=0;
            WHILE Xft.XftPatternGetString(set2.fonts[y],Xft.XFT_ENCODING,t,tmp)=0 DO
              z:=0;
              WHILE tmp[z]#0X DO
                name[z]:=tmp[z];
                INC(z);
              END;
              name[z]:=0X;

              encoding:=foundry.GetOrCreateEncoding(name);

              INC(t);
            END;
          END;
        END;

        Xft.XftFontSetDestroy(set2);

      END;

      Xft.XftFontSetDestroy(set);
    END;

<* END *>

    RETURN list;
  END GetFontList;

  (* -------- color stuff of D.display ------------- *)

  PROCEDURE (d : Display) AllocateColor8*(r,g,b : SHORTINT;
                                          default : D.Color;
                                          VAR color : D.Color);

  VAR
    xcolor : X11.XColor;

  BEGIN
    (*
      Scaling down color values from 31 bit to 16 bit,
      because X11 only supports 16 color values.
    *)
    xcolor.red:=r*256;
    xcolor.green:=g*256;
    xcolor.blue:=b*256;

    IF X11.XAllocColor(d.display,d.colorMap,xcolor)=0 THEN
      xcolor.pixel:=default;
      X11.XQueryColor(d.display,d.colorMap,xcolor);
      IF X11.XAllocColor(d.display,d.colorMap,xcolor)=0 THEN
        ASSERT(FALSE);
      END;
    END;
    color:=xcolor.pixel;
  END AllocateColor8;

  PROCEDURE (d : Display) AllocateColor16*(r,g,b : INTEGER;
                                           default : D.Color;
                                          VAR color : D.Color);

  VAR
    xcolor : X11.XColor;

  BEGIN
    (*
      Scaling down color values from 31 bit to 16 bit,
      because X11 only supports 16 color values.
    *)
    xcolor.red:=r;
    xcolor.green:=g;
    xcolor.blue:=b;

    IF X11.XAllocColor(d.display,d.colorMap,xcolor)=0 THEN
      xcolor.pixel:=default;
      X11.XQueryColor(d.display,d.colorMap,xcolor);
      IF X11.XAllocColor(d.display,d.colorMap,xcolor)=0 THEN
        ASSERT(FALSE);
      END;
    END;
    color:=xcolor.pixel;
  END AllocateColor16;

  PROCEDURE (d : Display) AllocateColor32*(r,g,b : LONGINT;
                                           default : D.Color;
                                           VAR color : D.Color);

  VAR
    xcolor : X11.XColor;

  BEGIN
    (*
      Scaling down color values from 31 bit to 16 bit,
      because X11 only supports 16 color values.
    *)
    xcolor.red:=SHORT(r DIV 32768);
    xcolor.green:=SHORT(g DIV 32768);
    xcolor.blue:=SHORT(b DIV 32768);

    IF X11.XAllocColor(d.display,d.colorMap,xcolor)=0 THEN
      xcolor.pixel:=default;
      X11.XQueryColor(d.display,d.colorMap,xcolor);
      IF X11.XAllocColor(d.display,d.colorMap,xcolor)=0 THEN
        ASSERT(FALSE);
      END;
    END;
    color:=xcolor.pixel;
  END AllocateColor32;

  PROCEDURE (d : Display) AllocateNamedColor*(name : ARRAY OF CHAR;
                                              default : D.Color;
                                            VAR color : D.Color);
  VAR
    exact,xcolor : X11.XColor;

  BEGIN
    IF X11.XLookupColor(d.display,d.colorMap,name,exact,xcolor)#0 THEN
      IF X11.XAllocColor(d.display,d.colorMap,xcolor)=0 THEN
        ASSERT(FALSE);
      END;
      color:=xcolor.pixel;
    ELSE
      xcolor.pixel:=default;
      X11.XQueryColor(d.display,d.colorMap,xcolor);
      IF X11.XAllocColor(d.display,d.colorMap,xcolor)=0 THEN
        ASSERT(FALSE);
      END;
      color:=xcolor.pixel;
    END;
  END AllocateNamedColor;

  PROCEDURE (d : Display) IsAllocatedColor*(color : D.Color):BOOLEAN;

  BEGIN
    RETURN TRUE; (*color>=0;*)
  END IsAllocatedColor;

  PROCEDURE (d : Display) FreeColor*(color : D.Color);

  VAR
    pixel : ARRAY 1 OF LONGINT;

  BEGIN
    pixel[0]:=color;
    X11.XFreeColors(d.display,d.colorMap,pixel,1,0);
  END FreeColor;

  (* ------------ Display ----------------- *)

  PROCEDURE (d : Display) AddTimer*(timer : D.Timer);

  VAR
    help  : Timer;
    dt    : sc.DateTime;
    time  : t.TimeStamp;

  BEGIN
    ASSERT(~timer.active);

    sc.GetClock(dt);
    c.SetTimeStamp(dt,time);

    time.Add(timer.interval);

    timer.SetTime(time);

    IF (d.timerList=NIL) OR (timer.time.Cmp(d.timerList.time)<=0) THEN
      timer(Timer).next:=d.timerList;
      d.timerList:=timer(Timer);
    ELSE
      help:=d.timerList;
      WHILE (help.next#NIL) & (help.next.time.Cmp(timer.time)<0) DO
        help:=help.next;
      END;
      timer(Timer).next:=help.next;
      help.next:=timer(Timer);
    END;

    timer.Activate;
  END AddTimer;

  PROCEDURE (d : Display) RemoveTimer*(timer : D.Timer);

  VAR
    help,
    last : Timer;

  BEGIN
    ASSERT(timer.active);

    timer.Deactivate;

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

    entry.key:=channel.RegisterWithSelector(d.selector,ops,NIL);

    RETURN entry;
  END AddChannel;

  PROCEDURE (d : Display) RemoveChannel*(channel : D.Channel);

  VAR
    help,
    last : Channel;

  BEGIN
    IF channel(Channel).key#NIL THEN
      channel(Channel).key.Cancel;
      channel(Channel).key:=NIL;
    END;

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
    bitmap : D.Bitmap;

  BEGIN
    bitmap:=D.factory.CreateBitmap();
    bitmap(Bitmap).pixmap:=X11.XCreatePixmap(d.display,
                                             X11.XDefaultRootWindow(d.display),
                                             width,
                                             height,d.colorDepth);

    IF bitmap(Bitmap).pixmap=0 THEN
      RETURN NIL;
    END;

    bitmap.draw:=D.factory.CreateDrawInfo();
    bitmap.draw(DrawInfo).Init(bitmap(Bitmap).pixmap);

    bitmap.width:=width;
    bitmap.height:=height;

    RETURN bitmap;
  END CreateBitmap;

  PROCEDURE (d : Display) CreateBitmapPattern*(pattern : ARRAY OF CHAR; width, height : LONGINT):D.Bitmap;

  VAR
    bitmap : D.Bitmap;

  BEGIN
    bitmap:=D.factory.CreateBitmap();
    bitmap(Bitmap).pixmap:=X11.XCreateBitmapFromData(d.display,
                                                     X11.XRootWindow(d.display,d.scrNum),
                                                     pattern,width,height);
    IF bitmap(Bitmap).pixmap=0 THEN
      RETURN NIL;
    END;

    bitmap.draw:=D.factory.CreateDrawInfo();
    bitmap.draw(DrawInfo).Init(bitmap(Bitmap).pixmap);

    bitmap.width:=width;
    bitmap.height:=height;

    RETURN bitmap;
  END CreateBitmapPattern;

  PROCEDURE (d : Display) FreeBitmap*(bitmap : D.Bitmap);

  BEGIN
    X11.XFreePixmap(d.display,bitmap(Bitmap).pixmap);
  END FreeBitmap;

  PROCEDURE (d : Display) Open*():BOOLEAN;

  VAR
    result     : C.string;
    i,j        : LONGINT;
    exactColor : X11.XColor;
    error      : BOOLEAN;
    pixel      : ARRAY 1 OF LONGINT;
    colors     : ARRAY D.colorCount OF X11.XColor;
    prefs      : DisplayPrefs;
    name       : STRING;
    tmp        : Object.CharsLatin1;

    PROCEDURE CreatePixmapCursor(bit1,bit2 : C.address; w,h : LONGINT):X11.Cursor;

    VAR
      pix1,pix2   : X11.Pixmap;
      cursor      : X11.Cursor;
      white,black : X11.XColor;

    BEGIN
      pix1:=X11.XCreatePixmapFromBitmapData(d.display,X11.XRootWindow(d.display,d.scrNum),
                                            bit1,w,h,
                                            X11.XBlackPixel(d.display,d.scrNum),
                                            X11.XWhitePixel(d.display,d.scrNum),1);

      pix2:=X11.XCreatePixmapFromBitmapData(d.display,X11.XRootWindow(d.display,d.scrNum),
                                            bit2,w,h,
                                            X11.XWhitePixel(d.display,d.scrNum),
                                            X11.XBlackPixel(d.display,d.scrNum),1);

      IF (pix1#0) & (pix2#0) THEN
        white.pixel:=D.whiteColor;
        X11.XQueryColor(d.display,d.colorMap,white);
        black.pixel:=D.blackColor;
        X11.XQueryColor(d.display,d.colorMap,black);

        cursor:=X11.XCreatePixmapCursor(d.display,pix1,pix2,
                                        white,
                                        black,
                                        w DIV 2,h DIV 2);
      ELSE
        cursor:=0;
      END;

      IF pix1#0 THEN
        X11.XFreePixmap(d.display,pix1);
      END;
      IF pix2#0 THEN
        X11.XFreePixmap(d.display,pix2);
      END;

      RETURN cursor;
    END CreatePixmapCursor;

  BEGIN
    d.driverName:=driverName;

    d.displayName:="";
    result:=X11.XDisplayName(NIL);
    IF result#NIL THEN
      COPY(result^,d.displayName);
    END;

    d.display:=X11.XOpenDisplay(d.displayName);
    IF d.display=NIL THEN
      RETURN FALSE;
    END;

    d.scrNum:=X11.XDefaultScreen(d.display);
    d.visual:=X11.XDefaultVisual(d.display,d.scrNum);
    IF d.visual=NIL THEN
      Err.String("Cannot get visual!"); Err.Ln;
      RETURN FALSE;
    END;
    d.colorDepth:=X11.XDefaultDepth(d.display,d.scrNum);
    d.colorMap:=X11.XDefaultColormap(d.display,d.scrNum);

    Image.Probe(d);

    d.scrWidth:=X11.XDisplayWidth(d.display,d.scrNum);
    d.scrHeight:=X11.XDisplayHeight(d.display,d.scrNum);

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

    d.xim:=X11.XOpenIM(d.display,0,"",""); (* TODO: Add d.appName *)
    IF d.xim=NIL THEN
      Err.String("Cannot open im"); Err.Ln;
      RETURN FALSE;
    END;

    IF (d.visual.class=X11.GrayScale)
    OR (d.visual.class=X11.StaticGray) THEN
      IF d.colorDepth=1 THEN
        d.colorMode:=D.monochromeMode;
      ELSE
        d.colorMode:=D.greyScaleMode;
      END;
    ELSIF (d.visual.class=X11.PseudoColor)
    OR (d.visual.class=X11.StaticColor)
    OR (d.visual.class=X11.DirectColor)
    OR (d.visual.class=X11.TrueColor) THEN
      d.colorMode:=D.colorMode;
    ELSE
      Err.String("Unsupported visual class!"); Err.Ln;
      RETURN FALSE;
    END;

    d.appWindow:=X11.XCreateSimpleWindow(d.display,
                                         X11.XRootWindow(d.display,d.scrNum),
                                         0,0,
                                         10,10,
                                         0,0,0);

    IF d.appWindow=0 THEN
      Err.String("Cannot create hidden application window!"); Err.Ln;
      RETURN FALSE;
    END;

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

    REPEAT
      error:=FALSE;
      i:=0;
      WHILE (i<D.colorCount) & ~error DO
        IF X11.XLookupColor(d.display,
                            d.colorMap,
                            D.prefs.colors[i],
                            exactColor,
                            colors[i])=0 THEN
          X11.XCloseDisplay(d.display);
          Err.String("Cannot parse color '");
          Err.String(D.prefs.colors[i]); Err.String("'"); Err.Ln;
          error:=TRUE;
        END;
        IF X11.XAllocColor(d.display,d.colorMap,colors[i])=0 THEN
          Err.String("Cannot allocate color '");
          Err.String(D.prefs.colors[i]); Err.String("'"); Err.Ln;
          error:=TRUE;
        END;
        INC(i);
      END;

      IF error THEN
        FOR j:=0 TO i-2 DO
          pixel[0]:=colors[j].pixel;
          X11.XFreeColors(d.display,d.colorMap,pixel,1,0);
        END;
        DEC(d.colorMode);
        IF d.colorMode=D.greyScaleMode THEN
          prefs.EvaluateColor;
        ELSIF d.colorMode=D.monochromeMode THEN
          prefs.EvaluateColor;
        END;
      END;

    UNTIL ~error OR (d.colorMode<0);

    IF d.colorMode<0 THEN
      Err.String("cannot allocate enough colors, giving up"); Err.Ln;
      X11.XCloseDisplay(d.display);
      RETURN FALSE;
    END;

    D.backgroundColor       := colors[D.backgroundColorIndex].pixel;
    D.tableBackgroundColor  := colors[D.tableBackgroundColorIndex].pixel;
    D.tableBackground2Color := colors[D.tableBackground2ColorIndex].pixel;
    D.tableTextColor        := colors[D.tableTextColorIndex].pixel;
    D.textBackgroundColor   := colors[D.textBackgroundColorIndex].pixel;
    D.buttonBackgroundColor := colors[D.buttonBackgroundColorIndex].pixel;
    D.textColor             := colors[D.textColorIndex].pixel;
    D.shineColor            := colors[D.shineColorIndex].pixel;
    D.halfShineColor        := colors[D.halfShineColorIndex].pixel;
    D.halfShadowColor       := colors[D.halfShadowColorIndex].pixel;
    D.shadowColor           := colors[D.shadowColorIndex].pixel;
    D.fillColor             := colors[D.fillColorIndex].pixel;
    D.fillTextColor         := colors[D.fillTextColorIndex].pixel;
    D.warnColor             := colors[D.warnColorIndex].pixel;
    D.disabledColor         := colors[D.disabledColorIndex].pixel;
    D.focusColor            := colors[D.focusColorIndex].pixel;
    D.blackColor            := colors[D.blackColorIndex].pixel;
    D.whiteColor            := colors[D.whiteColorIndex].pixel;
    D.helpBackgroundColor   := colors[D.helpBackgroundColorIndex].pixel;

    d.fonts:=NIL;
    FOR i:=0 TO D.fontCount-1 DO

      INCL(D.prefs.fonts[i].features,D.fontCharSet);
      NEW(D.prefs.fonts[i].charSet,str.Length(unicodeEncoding)+1);
      COPY(unicodeEncoding,D.prefs.fonts[i].charSet^);


      d.font[i]:=D.prefs.fonts[i].Load();
      IF d.font[i]=NIL THEN
        Err.String("Cannot load font '");
        Err.String(D.prefs.fonts[i].name^);
        Err.String(", ");
        Err.LongInt(D.prefs.fonts[i].pointHeight,0);
        Err.String("'"); Err.Ln;
        (* TODO: Free colors *)
        X11.XCloseDisplay(d.display);
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

    FOR i:=0 TO atomCount-1 DO
      d.atoms[i]:=X11.XInternAtom(d.display,atomNames[i],X11.False);
    END;

    d.sleepCursor:=X11.XCreateFontCursor(d.display,sleepCursor);
    IF d.sleepCursor=0 THEN
      Err.String("Cannot get sleep cursor!"); Err.Ln;
      X11.XCloseDisplay(d.display);
      RETURN FALSE;
    END;

    d.popCursor:=X11.XCreateFontCursor(d.display,popCursor);
    IF d.popCursor=0 THEN
      Err.String("Cannot get popup cursor!"); Err.Ln;
      X11.XFreeCursor(d.display,d.sleepCursor);
      X11.XCloseDisplay(d.display);
      RETURN FALSE;
    END;

    d.dndCursor:=X11.XCreateFontCursor(d.display,dndCursor);
    IF d.dndCursor=0 THEN
      Err.String("Cannot get drag & drop cursor!"); Err.Ln;
      X11.XFreeCursor(d.display,d.sleepCursor);
      X11.XFreeCursor(d.display,d.popCursor);
      X11.XCloseDisplay(d.display);
      RETURN FALSE;
    END;

    d.copyCursor:=CreatePixmapCursor(s.ADR(copyCursorData),s.ADR(copyMaskData),14,15);
    IF d.copyCursor=0 THEN
      Err.String("Cannot create copy cursor"); Err.Ln;
      X11.XFreeCursor(d.display,d.sleepCursor);
      X11.XFreeCursor(d.display,d.popCursor);
      X11.XFreeCursor(d.display,d.dndCursor);
      X11.XCloseDisplay(d.display);
      RETURN FALSE;
    END;

    d.moveCursor:=CreatePixmapCursor(s.ADR(moveCursorData),s.ADR(moveMaskData),11,13);
    IF d.moveCursor=0 THEN
      Err.String("Cannot create move cursor"); Err.Ln;
      X11.XFreeCursor(d.display,d.sleepCursor);
      X11.XFreeCursor(d.display,d.popCursor);
      X11.XFreeCursor(d.display,d.dndCursor);
      X11.XFreeCursor(d.display,d.copyCursor);
      X11.XCloseDisplay(d.display);
      RETURN FALSE;
    END;

    d.linkCursor:=CreatePixmapCursor(s.ADR(linkCursorData),s.ADR(linkMaskData),15,17);
    IF d.linkCursor=0 THEN
      Err.String("Cannot create move cursor"); Err.Ln;
      X11.XFreeCursor(d.display,d.sleepCursor);
      X11.XFreeCursor(d.display,d.popCursor);
      X11.XFreeCursor(d.display,d.dndCursor);
      X11.XFreeCursor(d.display,d.copyCursor);
      X11.XFreeCursor(d.display,d.moveCursor);
      X11.XCloseDisplay(d.display);
      RETURN FALSE;
    END;


    d.winList:=NIL;
    d.exit:=TRUE;
    d.currentWin:=NIL;

    d.timerList:=NIL;
    d.contextTimer:=D.factory.CreateTimer();
    d.contextTimer.SetSecs(D.prefs.contextTimer DIV 1000,D.prefs.contextTimer MOD 1000);
    d.contextTimer.SetObject(d);
    d.contextHelp:=TRUE;

    d.sleepList:=NIL;
    d.channelList:=NIL;

    d.selector:=S.Open();
    NEW(d.fdChannel);
    ChannelFDWrapper.Init(d.fdChannel,d.display.fd);
    IF d.fdChannel.RegisterWithSelector(d.selector,{IO.opRead},NIL)#NIL THEN END;

    d.selectObject:=NIL;
    d.querySelectObject:=NIL;
    d.queryClipboardObject:=NIL;
    d.clipboard:=NIL;
    d.selClearPend:=FALSE;

    d.dragging:=FALSE;
    d.dragObject:=NIL;

    d.multiClickTime:=200;

    (*    d.pointArray:=NIL;*)

    P.Initialize(D.prefs);
    IF D.prefsCallback#NIL THEN
      D.prefsCallback.ReadOtherPrefs;
      D.prefsCallback.ReadOtherTheme;
      D.prefsCallback.Free;
    END;

    (* To speed up things a little bit :-) *)
    d.bufferUCS2:=NIL;
    d.EnlargeUCS2Buffer(1024);

    RETURN TRUE;
  END Open;

  PROCEDURE (d : Display) SetMultiClickTime*(t : LONGINT);
  BEGIN
    IF t>0 THEN d.multiClickTime:=t END;
  END SetMultiClickTime;

  PROCEDURE (d : Display) Flush;
  (**
    Flushes all pending events. makes only sense for asnsycronous
    windowing systems like X11.
  *)

  BEGIN
    X11.XSync(d.display,X11.False);
  END Flush;

  PROCEDURE (d : Display) Beep*;

  BEGIN
    X11.XBell(d.display,100);
  END Beep;

  (* X11 selection handling *)

  PROCEDURE (d : Display) RegisterSelection*(object : D.Object;
                                             window : D.Window):BOOLEAN;

  BEGIN
    IF d.selectObject#object THEN

      IF (d.selectObject#NIL) THEN
        d.selectObject.Deselect;
        d.selectObject:=NIL;
      END;

      X11.XSetSelectionOwner(d.display,a.XA_PRIMARY,window.impl(Window).window,X11.CurrentTime);
      d.selectObject:=object;
      RETURN TRUE;
    ELSE
      RETURN TRUE;
    END;
  END RegisterSelection;

  PROCEDURE (d : Display) CancelSelection*;

  BEGIN
    ASSERT(d.selectObject#NIL);
    d.selClearPend:=TRUE;
    X11.XSetSelectionOwner(d.display,a.XA_PRIMARY,X11.None,X11.CurrentTime);
    d.selectObject.Deselect;
    d.selectObject:=NIL;
  END CancelSelection;

  PROCEDURE (d : Display) QuerySelection*(window: D.Window;
                                          object: D.Object;
                                          type: LONGINT):BOOLEAN;

  VAR
    propType : X11.Atom;

  BEGIN
    CASE type OF
      D.text: propType:=a.XA_STRING;
    ELSE
      RETURN FALSE;
    END;

    X11.XConvertSelection(d.display,
                          a.XA_PRIMARY,propType,
                          d.atoms[selectionAtom],
                          window.impl(Window).window,
                          X11.CurrentTime);

    d.querySelectObject:=object;
    RETURN TRUE;
  END QuerySelection;

  (* X11 clipboard handling *)

  PROCEDURE (d : Display) SetClipboard*(content : STRING):BOOLEAN;

  BEGIN
    d.clipboard:=content;
    X11.XSetSelectionOwner(d.display,d.atoms[clipboardAtom],d.appWindow,X11.CurrentTime);

    RETURN TRUE;
  END SetClipboard;


  PROCEDURE (d : Display) GetClipboard*(object: D.Object):BOOLEAN;

  VAR
    dndData  : DD.DnDStringData;
    propType : X11.Atom;

  BEGIN
    IF d.clipboard#NIL THEN
      NEW(dndData);
      dndData.string:=d.clipboard;
      IF object#NIL THEN
        IF object.HandleDrop(dndData,DD.insert) THEN
          (* nothing to do *)
        ELSE
          d.Beep;
        END;
      END;

      RETURN TRUE;
    ELSE
      propType:=a.XA_STRING;
      d.queryClipboardObject:=object;
      X11.XConvertSelection(d.display,
                            d.atoms[clipboardAtom],propType,
                            d.atoms[clipBufferAtom],
                            d.appWindow,
                            X11.CurrentTime);
      RETURN TRUE;
    END;
  END GetClipboard;

  PROCEDURE (d : Display) ClearClipboard*;

  BEGIN
    IF d.clipboard#NIL THEN
      d.selClearPend:=TRUE;
      X11.XSetSelectionOwner(d.display,d.atoms[clipboardAtom],X11.None,X11.CurrentTime);
      d.clipboard:=NIL;
    END;
  END ClearClipboard;

  PROCEDURE (d : Display) PutBackEvent*(event : E.Event; destWin : D.Window);

  VAR
    x11Event : X11.XEvent;

  BEGIN
    EO.GetX11Event(event,x11Event);
    x11Event.xany.window:=destWin.impl(Window).window;
    IF X11.XSendEvent(d.display,destWin.impl(Window).window,X11.True,X11.NoEventMask,
                     s.VAL(X11.XEventPtr,s.ADR(x11Event)))=0 THEN
      Err.String("Cannot resend event!"); Err.Ln;
    END;
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
    w    : Window;
    font : Font;

  BEGIN
    IF d.selectObject#NIL THEN
      d.CancelSelection;
    END;
    d.ClearClipboard;

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

    (* Freeing colors *)

(*    IF d.userColor#NIL THEN
      x:=0;
      FOR x:=0 TO LEN(d.userColor^)-1 DO
        (* TODO: Free colors *)
(*        IF d.userColor[x].useCount>0 THEN
          Err.String("Color ");
          Err.LongInt(d.userColor[x].color.red,0);
          Err.String(" ");
          Err.LongInt(d.userColor[x].color.green,0);
          Err.String(" ");
          Err.LongInt(d.userColor[x].color.blue,0);
          Err.String(" ");
          Err.String("not explicitely freed"); Err.Ln;
        END;*)
      END;
    END;
*)
    (* Freeing fonts *)
    font:=d.fonts;
    WHILE font#NIL DO
      font.useCount:=0;
      font.Free;
      IF font.next#NIL THEN
        font:=font.next(Font);
      ELSE
        font:=NIL;
      END;
    END;

    IF d.sleepCursor#0 THEN
      X11.XFreeCursor(d.display,d.sleepCursor);
    END;

    IF Image.factory#NIL THEN
      Image.factory.Deinit(d);
      Image.factory:=NIL;
    END;

    X11.XDestroyWindow(D.display(Display).display,d.appWindow);

    IF d.xim#NIL THEN
      IF X11.XCloseIM(d.xim)#0 THEN END;
    END;

    IF d.display#NIL THEN
      X11.XCloseDisplay(d.display);
    END;
  END Close;

  PROCEDURE (d : Display) Receive*(message : O.Message);

  BEGIN
    WITH
      message : D.ExitMsg DO
        d.Exit;
    | message : D.TimerMsg DO
      IF d.currentWin#NIL THEN
        IF (message.timer=d.contextTimer) THEN
          d.currentWin.interface.OnContextHelp;
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

  PROCEDURE (d : Display) HandleXSelectionNotify(event : X11.XSelectionEvent);
  (**
    Handle the XSelecitionNotify of X11. A SelectionNotify gets send
    as a result of our request for the selection value. The event states
    where one can get the selection value from.
  *)

  VAR
    retType     : X11.Atom;
    retFormat,
    itemsReturn,
    bytesLeft   : LONGINT;
    data        : C.string;
    dndData     : DD.DnDStringData;
    queryObject : D.Object;
    text        : U.Text;

  BEGIN
    IF event.property=X11.None THEN
      RETURN;
    END;

    IF X11.XGetWindowProperty(d.display,
                              event.requestor,event.property,0,MAX(LONGINT),X11.True,
                              X11.AnyPropertyType,
                              retType,retFormat,itemsReturn,bytesLeft,
                              data)#X11.Success THEN
      Out.String("Cannot get property data"); Out.Ln;
      RETURN;
    END;

    IF retType=X11.None THEN
      Out.String("Illegal property data type"); Out.Ln;
      RETURN;
    END;

    dndData:=NIL;
    IF (retType=a.XA_STRING) & (retFormat=8) THEN
      text:=U.CStringToText(data);

      NEW(dndData);
      dndData.string:=Object.NewLatin1(text^);
    END;

    IF dndData=NIL THEN
      Err.String("Unsupported drop datatype"); Err.Ln;
      RETURN;
    END;

    IF event.property=d.atoms[selectionAtom] THEN
      queryObject:=d.querySelectObject;
      d.querySelectObject:=NIL;
      IF queryObject#NIL THEN
        IF ~queryObject.HandleDrop(dndData,DD.insert) THEN
          d.Beep;
        END;
      END;
    ELSIF event.property=d.atoms[clipBufferAtom] THEN
      queryObject:=d.queryClipboardObject;
      d.queryClipboardObject:=NIL;

      IF queryObject#NIL THEN
        IF ~queryObject.HandleDrop(dndData,DD.insert) THEN
          d.Beep;
        END;
      END;
    ELSE
      Err.String("XSelectionNotification for: ");
      Err.LongInt(event.property,0);
      Err.Ln;
      Err.String("Drop result: ");
      text:=U.CStringToText(data);
      Err.String(text^);
      Err.Ln;
    END;
  END HandleXSelectionNotify;

  PROCEDURE (d : Display) HandleXSelectionRequest(event : X11.XSelectionRequestEvent);
  (**
    handle XSelectionrequest of X11. A SelectionRequest gets send when some application
    wants the selection value and your window has registered the selection. We
    ask the object which has registered the selection for the selection value
    and return a notify message to the requestor.
  *)

  VAR
    data        : DD.DnDData;
    selNotify   : X11.XEvent;
    retType     : X11.Atom;
    retFormat,
    itemsReturn,
    bytesLeft   : LONGINT;
    string      : C.string;
    text        : STRING;
    tmp         : Object.CharsLatin1;

  BEGIN
    selNotify.xselection.type:=X11.SelectionNotify;
    selNotify.xselection.display:=event.display;
    selNotify.xselection.requestor:=event.requestor;
    selNotify.xselection.selection:=event.selection;
    selNotify.xselection.target:=event.target;
    selNotify.xselection.property:=event.property;
    selNotify.xselection.time:=event.time;

    text:=NIL;

    IF (event.target=a.XA_STRING) OR (event.target=d.atoms[compoundTextAtom]) THEN
      IF event.selection=a.XA_PRIMARY THEN
        IF d.selectObject#NIL THEN
          data:=d.selectObject.GetDragData(D.text,D.none,D.copy);
          IF (data#NIL) & (data IS DD.DnDStringData) THEN
            text:=data(DD.DnDStringData).string;
          END;
        END;
      ELSIF event.selection=d.atoms[clipboardAtom] THEN
        IF (d.clipboard#NIL) THEN
          text:=d.clipboard;
        END;
      ELSE
        Err.String("Recieved a request for an unknown selection: ");
        Err.LongInt(event.selection,0);Err.Ln;
      END;
    END;

    IF text#NIL THEN
      WITH text : Object.String8 DO
        tmp:=text.CharsLatin1();
      ELSE
        tmp:=NIL;
      END;
    ELSE
      tmp:=NIL;
    END;

    IF tmp#NIL THEN
      string:=s.VAL(C.string,tmp);
      IF X11.XGetWindowProperty(event.display,
                                event.requestor,
                                event.property,
                                0,
                                MAX(LONGINT),
                                X11.False,
                                event.target,
                                retType,
                                retFormat,
                                itemsReturn,
                                bytesLeft,
                                string)#X11.Success THEN
        selNotify.xselection.property:=X11.None;
      ELSE
        X11.XChangeProperty(event.display,event.requestor,event.property,
                            a.XA_STRING,8,
                            X11.PropModeReplace,tmp^,
                            text.length);
      END;
    ELSE
      selNotify.xselection.property:=X11.None;
    END;

    IF X11.XSendEvent(selNotify.xselection.display,
                      selNotify.xselection.requestor,
                      X11.True,
                      X11.NoEventMask,
                      s.VAL(X11.XEventPtr,s.ADR(selNotify)))=0 THEN
      Err.String("Error sending selection notify"); Err.Ln;
    END;
  END HandleXSelectionRequest;

  PROCEDURE (w : Window) HandleDrag(event : E.MotionEvent):BOOLEAN;
  (**
    Called when some drag action should be started.
  *)

  VAR
    x11Event : X11.XEvent;

  BEGIN
    D.display(Display).dragStart:=FALSE;

    IF w.modalCount=0 THEN
      D.display(Display).dragObject:=w.interface.GetDnDObject(D.display(Display).dragX,
                                                              D.display(Display).dragY,TRUE);
      IF D.display(Display).dragObject#NIL THEN
        NEW(D.display(Display).dragInfo);
        D.display(Display).dragInfo.Init;
        D.display(Display).dragObject.GetDragInfo(D.display(Display).dragInfo);

        D.display(Display).StopContextHelp;

        (* Calculation action *)
        IF event.qualifier*E.keyMask=E.shiftMask THEN
          D.display(Display).dndAction:=DD.move;
          X11.XDefineCursor(D.display(Display).display,
                            w.window,
                            D.display(Display).moveCursor);
        ELSIF event.qualifier*E.keyMask=E.controlMask THEN
          D.display(Display).dndAction:=DD.copy;
          X11.XDefineCursor(D.display(Display).display,
                            w.window,
                            D.display(Display).copyCursor);
        ELSIF event.qualifier*E.keyMask=E.shiftMask+E.controlMask THEN
          D.display(Display).dndAction:=DD.link;
          X11.XDefineCursor(D.display(Display).display,
                            w.window,
                            D.display(Display).linkCursor);
        ELSE
          D.display(Display).dndAction:=DD.default;
          X11.XDefineCursor(D.display(Display).display,
                            w.window,
                            D.display(Display).dndCursor);
        END;

        EO.GetX11Event(event,x11Event);
        D.display(Display).dropWindow:=x11Event.xmotion.window;
        RETURN TRUE;
      END;
    END;
    RETURN FALSE;
  END HandleDrag;

  PROCEDURE (w : Window) HandleDragDrop(event : E.Event):BOOLEAN;
  (**
    Called when a drop action should be handled.
  *)

  VAR
    dragWin    : X11.Window;
    rX,rY,
    cX,cY      : LONGINT;
    return     : BOOLEAN;
    window     : D.WindowImpl;
    dropObject : D.Object;
    dragData   : DD.DnDData;
    group,type : LONGINT;

  BEGIN
    return:=FALSE;
    D.display(Display).dragStart:=FALSE;

    IF (D.display(Display).dropWindow#0) THEN

      D.display(Display).RestartContextHelp;

      dragWin:=D.display(Display).GetWindowOnScreen(rX,rY,cX,cY);
      IF dragWin#0 THEN
        window:=D.display(Display).GetWindow(dragWin);
        IF window#NIL THEN
          dropObject:=window.interface.GetDnDObject(cX,cY,FALSE);
          IF (window(Window).modalCount=0)
          & (dropObject#NIL) & (dropObject#D.display(Display).dragObject) THEN
            IF dropObject.GetDropDataType(D.display(Display).dragInfo,
                                          group,type,D.display(Display).dndAction) THEN
              dragData:=D.display(Display).dragObject.GetDragData(group,type,D.display(Display).dndAction);
              IF dragData#NIL THEN
                IF dropObject.HandleDrop(dragData,D.display(Display).dndAction) THEN
                  (* nothing to do yet*)
                ELSE
                  D.display.Beep;
                END;
              END;
            END;
            return:=TRUE;
          END;
        ELSE
          Err.String("End external drag -> drop"); Err.Ln;
          (*w.HandleMotifDragDrop(dragWin,rX,rY,event.event.xbutton);*)
        END;
      END;
      X11.XUndefineCursor(D.display(Display).display,w.window);
      D.display(Display).dropWindow:=0;
      D.display(Display).dragObject:=NIL;
    END;

    RETURN return;
  END HandleDragDrop;

  PROCEDURE (w : Window) GetXY(VAR x,y : LONGINT);

  VAR
    retAttr : X11.XWindowAttributes;
    root,
    parent,
    current : X11.Window;
    childs  : X11.WindowPtr1d;
    count   : LONGINT;

  BEGIN
    x:=0;
    y:=0;

    current:=w.window;

    IF X11.XQueryTree(D.display(Display).display,
                      current,root,parent,childs,count)#0 THEN
      XFree(childs);
      WHILE current#root DO
        IF X11.XGetWindowAttributes(D.display(Display).display,current,retAttr)#0 THEN
          INC(x,retAttr.x+retAttr.border_width);
          INC(y,retAttr.y+retAttr.border_width);
        END;
        current:=parent;
        IF X11.XQueryTree(D.display(Display).display,current,root,parent,childs,count)#0 THEN
          XFree(childs);
        END;
      END;
    END;
  END GetXY;

  PROCEDURE (w : Window) HandleEvent*(event : E.Event):BOOLEAN;

  VAR
    x,y,
    width,
    height      : LONGINT;
    name        : C.string;
    text        : U.Text;
    msg         : X11.XClientMessageEvent;

    retType     : X11.Atom;
    retFormat,
    itemsReturn,
    bytesLeft   : LONGINT;
    xData       : C.string;
    data        : POINTER TO ARRAY OF LONGINT;
    x11Event    : X11.XEvent;

  BEGIN
    EO.GetX11Event(event,x11Event);

    CASE x11Event.type OF
      X11.ClientMessage:
        IF (x11Event.xclient.data.l[0]=D.display(Display).atoms[deleteProtAtom])
        & (w.modalCount=0) THEN
          w.interface.OnClosePressed;
        ELSIF (x11Event.xclient.message_type=D.display(Display).atoms[XdndEnterAtom]) THEN
          Out.String("XDND Enter"); Out.Ln;
          Out.String("XID: "); Out.Hex(x11Event.xclient.data.l[0],0); Out.Ln;
          Out.String("Protokoll: "); Out.LongInt(s.VAL(SHORTINT,x11Event.xclient.data.b[7]),0); Out.Ln;

          FOR x:=2 TO 4 DO
            name:=X11.XGetAtomName(D.display(Display).display,x11Event.xclient.data.l[x]);
            IF name#NIL THEN
              Out.String("Datatype: ");
              text:=U.CStringToText(name);
              Out.String(text^); Out.Ln;
            END;
          END;

          IF x11Event.xclient.data.b[4]#0X THEN (* TODO: fix *)
            IF X11.XGetWindowProperty(D.display(Display).display,
                                      x11Event.xclient.data.l[0],
                                      D.display(Display).atoms[XdndTypeListAtom],
                                      0,
                                      MAX(LONGINT),
                                      X11.False,
                                      D.display(Display).atoms[atomAtom],
                                      retType,
                                      retFormat,
                                      itemsReturn,
                                      bytesLeft,
                                      xData)#X11.Success THEN
              Err.String("Cannot get property"); Err.Ln;
            ELSE
              NEW(data,itemsReturn);
              s.MOVE(s.VAL(LONGINT,xData),s.VAL(LONGINT,data),SIZE(LONGINT)*itemsReturn);
              XFree(xData);
              FOR x:=0 TO itemsReturn-1 DO
                name:=X11.XGetAtomName(D.display(Display).display,data[x]);
                IF name#NIL THEN
                  Out.String("Datatype: ");
                  text:=U.CStringToText(name);
                  Out.String(text^); Out.Ln;
                END;
              END;
            END;
          END;

          Out.Ln;

        ELSIF (x11Event.xclient.message_type=D.display(Display).atoms[XdndLeaveAtom]) THEN
          Out.String("XDND Leave"); Out.Ln;
          Out.String("XID: "); Out.Hex(x11Event.xclient.data.l[0],0); Out.Ln;
          Out.Ln;

        ELSIF (x11Event.xclient.message_type=D.display(Display).atoms[XdndPositionAtom]) THEN
          Out.String("XDND Position"); Out.Ln;
          Out.String("XID: "); Out.Hex(x11Event.xclient.data.l[0],0); Out.Ln;
          Out.String("X: "); Out.LongInt(x11Event.xclient.data.s[5],0); Out.Ln;
          Out.String("Y: "); Out.LongInt(x11Event.xclient.data.s[4],0); Out.Ln;

          IF x11Event.xclient.data.l[4]=D.display(Display).atoms[XdndActionMoveAtom] THEN
            Out.String("action move"); Out.Ln;
          ELSIF x11Event.xclient.data.l[4]=D.display(Display).atoms[XdndActionCopyAtom] THEN
            Out.String("action copy"); Out.Ln;
          ELSIF x11Event.xclient.data.l[4]=D.display(Display).atoms[XdndActionLinkAtom] THEN
            Out.String("action link"); Out.Ln;
          END;
          Out.Ln;

          msg.type:=X11.ClientMessage;
          msg.format:=32;
          msg.display:=D.display(Display).display;
          msg.window:=x11Event.xclient.data.l[0];
          msg.message_type:=D.display(Display).atoms[XdndStatusAtom];
          msg.data.l[0]:=w.window;
          msg.data.l[1]:=3;
          msg.data.s[4]:=0; (* y *)
          msg.data.s[5]:=0; (* x *)
          msg.data.s[6]:=0; (* h *)
          msg.data.s[7]:=0; (* w *)
          msg.data.l[4]:=D.display(Display).atoms[XdndActionCopyAtom];

          IF X11.XSendEvent(D.display(Display).display,
                            x11Event.xclient.data.l[0],
                            X11.False,X11.NoEventMask,
                            s.VAL(X11.XEventPtr,s.ADR(msg)))=0 THEN
            Out.String("Could not send XDNDStatus message"); Out.Ln;
          END;


        ELSIF (x11Event.xclient.message_type=D.display(Display).atoms[XdndStatusAtom]) THEN
          Out.String("XDND Status"); Out.Ln;

        ELSIF (x11Event.xclient.message_type=D.display(Display).atoms[XdndDropAtom]) THEN
          Out.String("XDND Drop"); Out.Ln;

          msg.type:=X11.ClientMessage;
          msg.format:=32;
          msg.display:=D.display(Display).display;
          msg.window:=w.window;
          msg.message_type:=D.display(Display).atoms[XdndFinishedAtom];
          msg.data.l[0]:=w.window;
          msg.data.l[1]:=0;

          X11.XConvertSelection(D.display(Display).display,
                                D.display(Display).atoms[XdndSelectionAtom],
                                297, (* text/plain *)
                                D.display(Display).atoms[dropAtom],
                                w.window,
                                x11Event.xclient.data.l[2]);

(*          dropObject:=window.GetDnDObject(cX,cY,FALSE);
                IF dropObject.HandleDrop(dragData,D.display.dndAction) THEN*)

(*          IF X11.XSendEvent(D.display.display,
                            x11Event.xclient.data.l[0],
                            X11.False,X11.NoEventMask,
                            s.VAL(X11.XEventPtr,s.ADR(msg)))=0 THEN
            Out.String("Could not send XDNDStatus message"); Out.Ln;
          END;*)

        ELSIF (x11Event.xclient.message_type=D.display(Display).atoms[XdndFinishedAtom]) THEN
          Out.String("XDND Finished"); Out.Ln;
          Out.String("XID: "); Out.Hex(x11Event.xclient.data.l[0],0); Out.Ln;
          Out.Ln;
        ELSIF (x11Event.xclient.message_type=D.display(Display).atoms[xEmbedAtom]) THEN
          Err.String("Got XEMBED message: ");
          Err.LongInt(x11Event.xclient.data.l[1],0);
          Err.Char(" ");
          Err.LongInt(x11Event.xclient.data.l[2],0);
          Err.Ln;
        ELSE
          Out.String("Unknown client message: ");
          Out.LongInt(x11Event.xclient.message_type,0); Out.Ln;
        END;
    | X11.ConfigureNotify:
      REPEAT
      UNTIL X11.XCheckTypedWindowEvent(D.display(Display).display,
                                       w.window,X11.ConfigureNotify,
                                       x11Event)#X11.True;

        w.GetXY(w.x,w.y);
        IF (x11Event.xconfigure.width#w.width)
        OR (x11Event.xconfigure.height#w.height) THEN
          w.width:=x11Event.xconfigure.width;  (* Where get they set the first time? *)
          w.height:=x11Event.xconfigure.height;
          w.interface.OnResized(x11Event.xconfigure.width -x11Event.xconfigure.border_width,
                                x11Event.xconfigure.height-x11Event.xconfigure.border_width);
        END;
    | X11.Expose:
      w.draw.InstallClip(x11Event.xgraphicsexpose.x,x11Event.xgraphicsexpose.y,
                         x11Event.xgraphicsexpose.width,x11Event.xgraphicsexpose.height);

      WHILE X11.XCheckTypedWindowEvent(D.display(Display).display,
                                       w.window,X11.Expose,
                                       x11Event)=X11.True DO
        w.draw.AddRegion(x11Event.xgraphicsexpose.x,x11Event.xgraphicsexpose.y,
                         x11Event.xgraphicsexpose.width,x11Event.xgraphicsexpose.height);
      END;
      w.draw.GetClipRegion(x,y,width,height);
      w.interface.OnRedraw(x,y,width,height);
      w.draw.FreeLastClip;
    | X11.GraphicsExpose:
      w.draw.InstallClip(x11Event.xgraphicsexpose.x,x11Event.xgraphicsexpose.y,
                         x11Event.xgraphicsexpose.width,x11Event.xgraphicsexpose.height);

      WHILE X11.XCheckTypedWindowEvent(D.display(Display).display,
                                       w.window,X11.GraphicsExpose,
                                       x11Event)=X11.True DO
        w.draw.AddRegion(x11Event.xgraphicsexpose.x,x11Event.xgraphicsexpose.y,
                         x11Event.xgraphicsexpose.width,x11Event.xgraphicsexpose.height);
      END;
      w.draw.GetClipRegion(x,y,width,height);
      w.interface.OnRedraw(x,y,width,height);
      w.draw.FreeLastClip;
    | X11.CreateNotify:
    | X11.ReparentNotify:
    | X11.MappingNotify:
        X11.XRefreshKeyboardMapping(s.VAL(X11.XMappingEventPtr,s.ADR(x11Event)));
    | X11.UnmapNotify:
        w.interface.OnUnmaped;
    | X11.MapNotify:
      w.GetXY(w.x,w.y);
      w.interface.OnMaped;
    | X11.FocusIn:
      X11.XSetICFocus(w.xic);
      IF ~w.grab THEN
        D.display(Display).StartContextHelp;
      END;
      w.interface.OnFocusIn;
    | X11.FocusOut:
      IF ~w.grab THEN
        D.display(Display).StopContextHelp;
      END;
      w.interface.OnFocusOut;
      X11.XUnsetICFocus(w.xic);
    | X11.EnterNotify:
        w.interface.OnMouseEntered;
    | X11.LeaveNotify:
        w.interface.OnMouseLeft;
    | X11.VisibilityNotify:
        IF x11Event.xvisibility.state>0 THEN
          w.interface.OnHidden;
        END;
    | X11.ButtonPress:
        IF (x11Event.xbutton.button=E.dragDropButton) THEN
          D.display(Display).dragStart:=TRUE;
          D.display(Display).dragX:=x11Event.xbutton.x;
          D.display(Display).dragY:=x11Event.xbutton.y;
        END;

        w.oldButton:=w.lastButton;
        w.oldPress:=w.lastPress;
        w.lastButton:=w.thisButton;
        w.lastPress:=w.thisPress;
        w.thisButton:=event(EO.ButtonEvent)^;
        w.thisPress:=x11Event.xbutton.time;
        IF w.modalCount=0 THEN
          RETURN FALSE;
        ELSE
          RETURN TRUE;
        END;
    | X11.ButtonRelease:
        IF (x11Event.xbutton.type=X11.ButtonRelease)
        & (x11Event.xbutton.button=E.dragDropButton) THEN
          IF w.HandleDragDrop(event) THEN
            RETURN TRUE;
          END;
        END;
        IF w.modalCount=0 THEN
          RETURN FALSE;
        ELSE
          RETURN TRUE;
        END;
    | X11.MotionNotify:
        IF (event(E.MotionEvent).qualifier*E.buttonMask={E.dragDropButton})
         & (D.display(Display).dragStart) THEN
          IF   (x11Event.xmotion.x>D.display(Display).dragX+D.display.spaceWidth DIV 2)
            OR (x11Event.xmotion.x<D.display(Display).dragX-D.display.spaceWidth DIV 2)
            OR (x11Event.xmotion.y>D.display(Display).dragY+D.display.spaceHeight DIV 2)
            OR (x11Event.xmotion.y<D.display(Display).dragY-D.display.spaceHeight DIV 2) THEN
            IF w.HandleDrag(event(E.MotionEvent)) THEN
              RETURN TRUE;
            END;
          END;
        END;
        IF w.modalCount=0 THEN
          RETURN FALSE;
        ELSE
          RETURN TRUE;
        END;
    ELSE
      IF w.modalCount=0 THEN
        RETURN FALSE;
      ELSE
        RETURN TRUE;
      END;
    END;

    RETURN TRUE;
  END HandleEvent;

  PROCEDURE (d : Display) GetEvent;

  VAR
    e     : X11.XEvent;
    event : E.Event;

  BEGIN
    X11.XNextEvent(d.display,e);

    IF X11.XFilterEvent(s.VAL(X11.XEventPtr,s.ADR(e)),0)#0 THEN
      RETURN;
    END;

    IF d.contextTimer.active THEN
      IF (e.type=X11.ButtonPress) OR (e.type=X11.ButtonRelease) OR (e.type=X11.MotionNotify) OR
        (e.type=X11.KeyPress) OR (e.type=X11.KeyRelease) THEN
        d.RestartContextHelp;
      END;
    END;

    CASE e.type OF
    | X11.SelectionClear:
      IF ~d.selClearPend THEN
        IF e.xselectionclear.selection=a.XA_PRIMARY THEN
          IF d.selectObject#NIL THEN
            d.selectObject.Deselect;
            d.selectObject:=NIL;
          END;
        ELSIF e.xselectionclear.selection=d.atoms[clipboardAtom] THEN
          d.clipboard:=NIL;
        ELSE
          Err.String("Catched SelectionClear event for unknown selection");Err.Ln;
        END;
      ELSE
        D.display(Display).selClearPend:=FALSE;
      END;
      RETURN;
    | X11.SelectionNotify:
      D.display(Display).HandleXSelectionNotify(e.xselection);
      RETURN;
    | X11.SelectionRequest:
      D.display(Display).HandleXSelectionRequest(e.xselectionrequest);
      RETURN;
    ELSE
    END;

    d.currentWin:=d.GetWindow(e.xany.window);

    IF d.currentWin#NIL THEN

      event:=EO.GetEvent(e,d.currentWin.xic);
      IF event#NIL THEN
        REPEAT
          event.reUse:=FALSE;
          IF ~d.currentWin.HandleEvent(event) THEN
            IF d.currentWin.interface.HandleEvent(event) THEN END;
          END;
        UNTIL event.reUse=FALSE;
      END;
    END;
  END GetEvent;

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

  BEGIN
    LOOP
      TRY
        d.GetNextTimer(interval);

        sec:=interval.dayInt*(t.msecPerDay DIV t.msecPerSec)+interval.msecInt DIV 1000;
        usec:=(interval.msecInt MOD 1000)*1000;

        IF (sec<0) OR (usec<0) THEN
          sec:=0;
          usec:=0;
        END;

        d.fdChannel.ResetReadyOps();

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
        Err.String("select: error!"); Err.Ln;
        RETURN TRUE;
      END;
    END;
  END Wait;

  PROCEDURE (d : Display) EventLoop*;

  BEGIN
    ASSERT(d.exit);

    d.exit:=FALSE;

    LOOP
      IF d.sleepList#NIL THEN
        IF X11.XEventsQueued(d.display,X11.QueuedAlready)=0 THEN
          d.CheckSleeps;
          d.CheckTimers;
        ELSE
          d.GetEvent;
        END;
      ELSE
        IF X11.XEventsQueued(d.display,X11.QueuedAlready)=0 THEN
          IF X11.XEventsQueued(d.display,X11.QueuedAfterFlush)=0 THEN
            d.CheckTimers;
            IF d.Wait() THEN
              d.CheckTimers;
            END;
          ELSE
            d.CheckTimers;
          END;
        ELSE
          d.CheckTimers;
        END;
      END;

      IF X11.XEventsQueued(d.display,X11.QueuedAfterReading)>0 THEN

        d.GetEvent;

        d.CheckTimers;

      END;

      IF d.exit THEN
        EXIT;
      END;

    END;
  END EventLoop;

  PROCEDURE (w : Window) Init*;

  BEGIN
    w.Init^;

    w.last:=NIL;
    w.next:=NIL;

    w.window:=0;

    w.grab:=FALSE;
    w.exit:=TRUE;

    w.oldPress:=0;
    w.lastPress:=0;
    w.thisPress:=0;
  END Init;

  PROCEDURE (w : Window) SetTitle*(name : STRING);

  VAR
    str8 : Object.String8;
    tmp  : Object.CharsLatin1;

  BEGIN
    w.SetTitle^(name);

    IF w.window#0 THEN
      str8:=name.ToString8("?");
      tmp:=str8.CharsLatin1();
      X11.XStoreName(D.display(Display).display,w.window,tmp^);

      D.display(Display).SetUTF8Property(w,
                                         D.display(Display).atoms[netWMNameAtom],
                                         name);
    END;
  END SetTitle;

  PROCEDURE (w : Window) GetDrawInfo*():D.DrawInfo;

  BEGIN
    RETURN w.draw;
  END GetDrawInfo;

  PROCEDURE (w : Window) Resize*(width,height : LONGINT);

  BEGIN
    w.Resize^(width,height);

    X11.XResizeWindow(D.display(Display).display,w.window,width,height);
  END Resize;

  PROCEDURE (w : Window) GrabOn;
  (**
    Grabs the mouse cursor and keyboard.
  *)

  BEGIN
    D.display(Display).StopContextHelp;
    IF X11.XGrabPointer(D.display(Display).display,w.window,X11.False,
                         X11.ButtonPressMask
                        +X11.ButtonReleaseMask
                        +X11.PointerMotionMask
                        +X11.PointerMotionHintMask
                        +X11.LeaveWindowMask
                        +X11.EnterWindowMask
                        +X11.StructureNotifyMask
                        +X11.VisibilityChangeMask
                        +X11.FocusChangeMask
                        +X11.ButtonMotionMask,
                        X11.GrabModeAsync,
                        X11.GrabModeAsync,
                        X11.None,
                        D.display(Display).popCursor,
                        X11.CurrentTime)#X11.GrabSuccess THEN
      Err.String("Can't grab cursor"); Err.Ln;
    END;
    IF X11.XGrabKeyboard(D.display(Display).display,w.window,X11.False,
                         X11.GrabModeAsync,
                         X11.GrabModeAsync,
                         X11.CurrentTime)#X11.GrabSuccess THEN
      Err.String("Can't grab cursor"); Err.Ln;
    END;
  END GrabOn;

  PROCEDURE (w : Window) GrabOff;
  (**
    Releases the grab of the mouse cursor and the keyboard.
  *)

  BEGIN
    X11.XUngrabPointer(D.display(Display).display,X11.CurrentTime);
    X11.XUngrabKeyboard(D.display(Display).display,X11.CurrentTime);
    D.display(Display).RestartContextHelp;
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

  PROCEDURE (w : Window) InternalOpen():BOOLEAN;

  VAR
    sHints     : xu.XSizeHintsPtr;
    wHints     : xu.XWMHintsPtr;
    attr       : X11.XSetWindowAttributes;
    window     : D.Window;
    parent     : X11.Window;
    draw       : D.DrawInfo;
    deleteProt : ARRAY 1 OF X11.Atom;

  BEGIN
    sHints:=xu.XAllocSizeHints();
    wHints:=xu.XAllocWMHints();

    IF (sHints=NIL) OR (wHints=NIL) THEN
      XFree(sHints);
      XFree(wHints);
    END;

    attr.colormap:=D.display(Display).colorMap;
(*    attr.background_pixmap:=X11.None;
    attr.background_pixel:=D.display(Display).GetX11Color(w.background);*)
(*    attr.border_pixel:=w.background;*)
  (*  attr.backing_store:=X11.NotUseful; (* Give a little boost *)*)
    attr.bit_gravity:=X11.NorthWestGravity;
    attr.event_mask:= X11.KeyPressMask
                     +X11.KeyReleaseMask
                     +X11.ExposureMask
                     +X11.StructureNotifyMask
                     +X11.ButtonPressMask
                     +X11.ButtonReleaseMask
                     +X11.ButtonMotionMask
                     +X11.PointerMotionMask
                     +X11.FocusChangeMask;

    CASE w.type OF
      D.windowTypeMenu,
      D.windowTypePopup,
      D.windowTypeSplash:
      attr.override_redirect:=X11.True;
      attr.save_under:=X11.True;
    ELSE
      attr.override_redirect:=X11.False;
      attr.save_under:=X11.False;
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

(*    IF w.parent=NIL THEN*)
      parent:=X11.XRootWindow(D.display(Display).display,
                              D.display(Display).scrNum);
(*    ELSE
      parent:=w.parent(Window).window;
    END;*)

    w.window:=X11.XCreateWindow(D.display(Display).display,
                                parent,
                                w.x,w.y,
                                w.width,w.height,
                                0,
                                X11.CopyFromParent,
                                X11.InputOutput,
                                D.display(Display).visual^,
(*                                 X11.CWBackPixmap
                                +X11.CWBackPixel*)
                                X11.CWBorderPixel
                                +X11.CWBitGravity
(*                                +X11.CWBackingStore*)
                                +X11.CWOverrideRedirect
                                +X11.CWSaveUnder
                                +X11.CWEventMask
                                +X11.CWColormap,
                                attr);

    IF w.window=0 THEN
      XFree(sHints);
      XFree(wHints);
      RETURN FALSE;
    END;

    w.xic:=X11.XCreateIC(D.display(Display).xim,
                         X11.XNInputStyle,X11.XIMPreeditNothing+X11.XIMStatusNothing,
                         X11.XNClientWindow,w.window,
                         X11.XNFocusWindow,w.window,
                         NIL);
    IF w.xic=NIL THEN
      XFree(sHints);
      XFree(wHints);
      X11.XDestroyWindow(D.display(Display).display,w.window);
      RETURN FALSE;
    END;

    w.SetTitle(w.GetTitle());

    sHints.flags:=xu.PMinSize+xu.PMaxSize;
    sHints.min_width:=w.minWidth;
    sHints.max_width:=w.maxWidth;
    sHints.min_height:=w.minHeight;
    sHints.max_height:=w.maxHeight;

    wHints.initial_state:=xu.NormalState;
    wHints.input:=1;
    wHints.flags:=xu.StateHint+xu.InputHint+xu.WindowGroupHint;

    window:=w.GetTopWindow();
    IF w.type=D.windowTypeMenu THEN
      (* That would not work with menues *)
      window:=NIL;
    END;

    IF window#NIL THEN
      wHints.window_group:=window.impl(Window).window;
    ELSE
      wHints.window_group:=w.window;
    END;

    IF window#NIL THEN
      X11.XSetTransientForHint(D.display(Display).display,
                               w.window,
                               window.impl(Window).window);
    END;

    xu.XSetWMProperties(D.display(Display).display,
                        w.window,
                        NIL,
                        NIL,
                        NIL,0,
                        sHints,
                        wHints,
                        NIL);

    XFree(sHints);
    XFree(wHints);

    deleteProt[0]:=D.display(Display).atoms[deleteProtAtom];
    IF X11.XSetWMProtocols(D.display(Display).display,
                           w.window,
                           deleteProt,1)=0 THEN
      X11.XDestroyWindow(D.display(Display).display,w.window);
      XFree(sHints);
      XFree(wHints);
    END;

    (* We mark the windows as Xdnd aware *)

    D.display(Display).SetAtomProperty(w,D.display(Display).atoms[XdndAwareAtom],XDND_VERSION);

    CASE w.type OF
      D.windowTypeToolbar:
      D.display(Display).SetAtomProperty(w,D.display(Display).atoms[netWMWindowTypeAtom],
                                         D.display(Display).atoms[netWMWindowTypeToolbarAtom]);
    | D.windowTypeMenu:
      D.display(Display).SetAtomProperty(w,D.display(Display).atoms[netWMWindowTypeAtom],
                                         D.display(Display).atoms[netWMWindowTypeMenuAtom]);
    | D.windowTypePopup:
      D.display(Display).SetAtomProperty(w,D.display(Display).atoms[netWMWindowTypeAtom],
                                         D.display(Display).atoms[netWMWindowTypeMenuAtom]);
    | D.windowTypeUtility:
      D.display(Display).SetAtomProperty(w,D.display(Display).atoms[netWMWindowTypeAtom],
                                         D.display(Display).atoms[netWMWindowTypeUtilityAtom]);
    | D.windowTypeSplash:
      D.display(Display).SetAtomProperty(w,D.display(Display).atoms[netWMWindowTypeAtom],
                                         D.display(Display).atoms[netWMWindowTypeSplashAtom]);
    | D.windowTypeSysTray:
      D.display(Display).SendNetSystemTrayRequestDock(w.window);
      (*D.display(Display).SendNetSystemTrayBaloonMessage(w.window);*)
    | D.windowTypeDialog:
      D.display(Display).SetAtomProperty(w,D.display(Display).atoms[netWMWindowTypeAtom],
                                         D.display(Display).atoms[netWMWindowTypeDialogAtom]);
    | D.windowTypeMain:
      D.display(Display).SetAtomProperty(w,D.display(Display).atoms[netWMWindowTypeAtom],
                                         D.display(Display).atoms[netWMWindowTypeNormalAtom]);
    END;

    draw:=D.factory.CreateDrawInfo();
    w.draw:=draw(DrawInfo);
    w.draw.Init(w.window);

    w.draw.InstallClip(0,0,D.display.scrWidth,D.display.scrHeight);

    D.display(Display).AddWindow(w);

    RETURN TRUE;
  END InternalOpen;

  PROCEDURE (w : Window) Open*():BOOLEAN;

  BEGIN
    IF ~w.Open^() THEN
      RETURN FALSE;
    END;

    IF ~w.InternalOpen() THEN
      RETURN FALSE;
    END;

    X11.XMapWindow(D.display(Display).display,w.window);

    IF w.grab THEN
      w.GrabOn;
    END;

    RETURN TRUE;
  END Open;

  PROCEDURE (w : Window) Close*;

  VAR
    e : X11.XEvent;

  BEGIN
    IF w.grab THEN
      w.GrabOff;
    END;

    IF w.IsOpen() & (w.window#0) THEN
      IF w.parent#NIL THEN
        X11.XSetInputFocus(D.display(Display).display,w.parent(Window).window,
                           X11.RevertToParent,X11.CurrentTime);
      ELSE
        X11.XSetInputFocus(D.display(Display).display,X11.PointerRoot,
                           X11.RevertToParent,X11.CurrentTime);
      END;
      X11.XUnmapWindow(D.display(Display).display,w.window);
    END;

    IF w.IsOpen() & (w.window#0) THEN
      REPEAT
        X11.XWindowEvent(D.display(Display).display,w.window,
                         X11.StructureNotifyMask,e);
      UNTIL e.type=X11.UnmapNotify;
    END;

    w.interface.OnUnmaped;

    IF w.window#0 THEN
      w.draw.FreeLastClip;
      w.draw.Deinit;
      IF w.xic#NIL THEN
        X11.XDestroyIC(w.xic);
        w.xic:=NIL;
      END;
      X11.XDestroyWindow(D.display(Display).display,w.window);
      w.window:=0;
    END;

    D.display(Display).RemoveWindow(w);

    w.Close^;
  END Close;

  PROCEDURE (w : Window) GetMousePos*(VAR rx, ry, wx, wy : LONGINT);

  VAR
    root,
    child  : X11.Window;
    bmask  : X11.ulongmask;

  BEGIN
    IF X11.XQueryPointer(D.display(Display).display,w.window,root,child,rx,ry,wx,wy,bmask)=X11.False THEN
      Err.String("Can't get cursorpos"); Err.Ln;
    END;
  END GetMousePos;

  PROCEDURE (w : Window) EventLoop*;

  BEGIN
    ASSERT(w.exit);

    w.exit:=FALSE;

    w.DisableParents;

    LOOP
      IF D.display(Display).sleepList#NIL THEN
        IF X11.XEventsQueued(D.display(Display).display,X11.QueuedAlready)=0 THEN
          D.display(Display).CheckSleeps;
          D.display(Display).CheckTimers;
        ELSE
          D.display(Display).GetEvent;
        END;
      ELSE
        IF X11.XEventsQueued(D.display(Display).display,X11.QueuedAlready)=0 THEN
          IF X11.XEventsQueued(D.display(Display).display,X11.QueuedAfterFlush)=0 THEN
            D.display(Display).CheckTimers;
            IF D.display(Display).Wait() THEN
              D.display(Display).CheckTimers;
            END;
          ELSE
            D.display(Display).CheckTimers;
          END;
        ELSE
          D.display(Display).CheckTimers;
        END;
      END;

      IF X11.XEventsQueued(D.display(Display).display,X11.QueuedAfterReading)>0 THEN

        D.display(Display).GetEvent;

        D.display(Display).CheckTimers;

      END;
      IF w.exit THEN
        EXIT;
      END;
    END;

    w.EnableParents;
  END EventLoop;

  PROCEDURE (w : Window) Enable*;

  BEGIN
    w.Enable^;

    IF w.modalCount=0 THEN
      X11.XUndefineCursor(D.display(Display).display,w.window);
    END;
  END Enable;

  PROCEDURE (w : Window) Disable*;

  BEGIN
    w.Disable^;

    IF w.modalCount=1 THEN
      X11.XDefineCursor(D.display(Display).display,
                        w.window,
                        D.display(Display).sleepCursor);
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
          & (ABS(w.lastButton.x-w.thisButton.x)<5)
          & (ABS(w.lastButton.y-w.thisButton.y)<5)
          & (w.thisPress - w.lastPress <= D.display(Display).multiClickTime);
  END IsDoubleClicked;

  PROCEDURE (w : Window) IsTrippleClicked*():BOOLEAN;

  BEGIN
    RETURN (w.oldButton.type = w.lastButton.type)
          & (w.oldButton.qualifier = w.lastButton.qualifier)
          & (ABS(w.oldButton.x-w.lastButton.x)<5)
          & (ABS(w.oldButton.y-w.lastButton.y)<5)
          & (w.lastPress - w.oldPress <= D.display(Display).multiClickTime)

          & (w.lastButton.type = w.thisButton.type)
          & (w.lastButton.qualifier = w.thisButton.qualifier)
          & (ABS(w.lastButton.x-w.thisButton.x)<5)
          & (ABS(w.lastButton.y-w.thisButton.y)<5)
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

    f.SetPriority(10);
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

  SetDefault;

  atomNames[atomAtom]:="ATOM";
  atomNames[deleteProtAtom]:="WM_DELETE_WINDOW";
  atomNames[wmStateAtom]:="WM_STATE";
  atomNames[XdndAwareAtom]:="XdndAware";
  atomNames[XdndEnterAtom]:="XdndEnter";
  atomNames[XdndLeaveAtom]:="XdndLeave";
  atomNames[XdndPositionAtom]:="XdndPosition";
  atomNames[XdndStatusAtom]:="XdndStatus";
  atomNames[XdndFinishedAtom]:="XdndFinished";
  atomNames[XdndDropAtom]:="XdndDrop";
  atomNames[XdndActionCopyAtom]:="XdndActionCopy";
  atomNames[XdndActionMoveAtom]:="XdndActionMove";
  atomNames[XdndActionLinkAtom]:="XdndActionLink";
  atomNames[XdndActionAskAtom]:="XdndActionAsk";
  atomNames[XdndActionPrivateAtom]:="XdndActionPrivate";
  atomNames[XdndActionListAtom]:="XdndActionList";
  atomNames[XdndSelectionAtom]:="XdndSelection";
  atomNames[XdndTypeListAtom]:="XdndTypeList";
  atomNames[dropAtom]:="_VISUALOBERON_DROP_DATA";
  atomNames[selectionAtom]:="_VISUALOBERON_SELECTION_DATA";
  atomNames[compoundTextAtom]:="COMPOUND_TEXT";
  atomNames[clipboardAtom]:="CLIPBOARD";
  atomNames[clipBufferAtom]:="_VISUALOBERON_CLIPBOARD_DATA";
  atomNames[netWMNameAtom]:="_NET_WM_NAME";
  atomNames[netWMWindowTypeAtom]:="_NET_WM_WINDOW_TYPE";
  atomNames[netWMWindowTypeDesktopAtom]:="_NET_WM_WINDOW_TYPE_DESKTOP";
  atomNames[netWMWindowTypeToolbarAtom]:="_NET_WM_WINDOW_TYPE_TOOLBAR";
  atomNames[netWMWindowTypeMenuAtom]:="_NET_WM_WINDOW_TYPE_MENU";
  atomNames[netWMWindowTypeUtilityAtom]:="_NET_WM_WINDOW_TYPE_UTILITY";
  atomNames[netWMWindowTypeSplashAtom]:="_NET_WM_WINDOW_TYPE_SPLASH";
  atomNames[netWMWindowTypeDialogAtom]:="_NET_WM_WINDOW_TYPE_DIALOG";
  atomNames[netWMWindowTypeNormalAtom]:="_NET_WM_WINDOW_TYPE_NORMAL";
  atomNames[utf8StringAtom]:="UTF8_STRING";
  atomNames[xEmbedAtom]:="_XEMBED";

  copyCursorData[ 0]:=000X;
  copyCursorData[ 1]:=000X;
  copyCursorData[ 2]:=0FEX;
  copyCursorData[ 3]:=003X;
  copyCursorData[ 4]:=002X;
  copyCursorData[ 5]:=002X;
  copyCursorData[ 6]:=002X;
  copyCursorData[ 7]:=01EX;
  copyCursorData[ 8]:=072X;
  copyCursorData[ 9]:=012X;
  copyCursorData[10]:=002X;
  copyCursorData[11]:=012X;
  copyCursorData[12]:=072X;
  copyCursorData[13]:=012X;
  copyCursorData[14]:=002X;
  copyCursorData[15]:=012X;
  copyCursorData[16]:=072X;
  copyCursorData[17]:=012X;
  copyCursorData[18]:=002X;
  copyCursorData[19]:=012X;
  copyCursorData[20]:=002X;
  copyCursorData[21]:=012X;
  copyCursorData[22]:=0FEX;
  copyCursorData[23]:=013X;
  copyCursorData[24]:=010X;
  copyCursorData[25]:=010X;
  copyCursorData[26]:=0F0X;
  copyCursorData[27]:=01FX;
  copyCursorData[28]:=000X;
  copyCursorData[29]:=000X;

  copyMaskData[ 0]:=0FFX;
  copyMaskData[ 1]:=007X;
  copyMaskData[ 2]:=0FFX;
  copyMaskData[ 3]:=007X;
  copyMaskData[ 4]:=0FFX;
  copyMaskData[ 5]:=03FX;
  copyMaskData[ 6]:=0FFX;
  copyMaskData[ 7]:=03FX;
  copyMaskData[ 8]:=0FFX;
  copyMaskData[ 9]:=03FX;
  copyMaskData[10]:=0FFX;
  copyMaskData[11]:=03FX;
  copyMaskData[12]:=0FFX;
  copyMaskData[13]:=03FX;
  copyMaskData[14]:=0FFX;
  copyMaskData[15]:=03FX;
  copyMaskData[16]:=0FFX;
  copyMaskData[17]:=03FX;
  copyMaskData[18]:=0FFX;
  copyMaskData[19]:=03FX;
  copyMaskData[20]:=0FFX;
  copyMaskData[21]:=03FX;
  copyMaskData[22]:=0FFX;
  copyMaskData[23]:=03FX;
  copyMaskData[24]:=0FFX;
  copyMaskData[25]:=03FX;
  copyMaskData[26]:=0F8X;
  copyMaskData[27]:=03FX;
  copyMaskData[28]:=0F8X;
  copyMaskData[29]:=03FX;

  moveCursorData[ 0]:=000X;
  moveCursorData[ 1]:=000X;
  moveCursorData[ 2]:=0FEX;
  moveCursorData[ 3]:=003X;
  moveCursorData[ 4]:=002X;
  moveCursorData[ 5]:=002X;
  moveCursorData[ 6]:=002X;
  moveCursorData[ 7]:=002X;
  moveCursorData[ 8]:=072X;
  moveCursorData[ 9]:=002X;
  moveCursorData[10]:=002X;
  moveCursorData[11]:=002X;
  moveCursorData[12]:=072X;
  moveCursorData[13]:=002X;
  moveCursorData[14]:=002X;
  moveCursorData[15]:=002X;
  moveCursorData[16]:=072X;
  moveCursorData[17]:=002X;
  moveCursorData[18]:=002X;
  moveCursorData[19]:=002X;
  moveCursorData[20]:=002X;
  moveCursorData[21]:=002X;
  moveCursorData[22]:=0FEX;
  moveCursorData[23]:=003X;
  moveCursorData[24]:=000X;
  moveCursorData[25]:=000X;

  moveMaskData[ 0]:=0FFX;
  moveMaskData[ 1]:=007X;
  moveMaskData[ 2]:=0FFX;
  moveMaskData[ 3]:=007X;
  moveMaskData[ 4]:=0FFX;
  moveMaskData[ 5]:=007X;
  moveMaskData[ 6]:=0FFX;
  moveMaskData[ 7]:=007X;
  moveMaskData[ 8]:=0FFX;
  moveMaskData[ 9]:=007X;
  moveMaskData[10]:=0FFX;
  moveMaskData[11]:=007X;
  moveMaskData[12]:=0FFX;
  moveMaskData[13]:=007X;
  moveMaskData[14]:=0FFX;
  moveMaskData[15]:=007X;
  moveMaskData[16]:=0FFX;
  moveMaskData[17]:=007X;
  moveMaskData[18]:=0FFX;
  moveMaskData[19]:=007X;
  moveMaskData[20]:=0FFX;
  moveMaskData[21]:=007X;
  moveMaskData[22]:=0FFX;
  moveMaskData[23]:=007X;
  moveMaskData[24]:=0FFX;
  moveMaskData[25]:=007X;

  linkCursorData[ 0]:=000X;
  linkCursorData[ 1]:=000X;
  linkCursorData[ 2]:=0FEX;
  linkCursorData[ 3]:=003X;
  linkCursorData[ 4]:=002X;
  linkCursorData[ 5]:=02AX;
  linkCursorData[ 6]:=002X;
  linkCursorData[ 7]:=002X;
  linkCursorData[ 8]:=072X;
  linkCursorData[ 9]:=022X;
  linkCursorData[10]:=002X;
  linkCursorData[11]:=002X;
  linkCursorData[12]:=072X;
  linkCursorData[13]:=022X;
  linkCursorData[14]:=002X;
  linkCursorData[15]:=002X;
  linkCursorData[16]:=072X;
  linkCursorData[17]:=03EX;
  linkCursorData[18]:=002X;
  linkCursorData[19]:=022X;
  linkCursorData[20]:=002X;
  linkCursorData[21]:=02EX;
  linkCursorData[22]:=0FEX;
  linkCursorData[23]:=023X;
  linkCursorData[24]:=000X;
  linkCursorData[25]:=021X;
  linkCursorData[26]:=000X;
  linkCursorData[27]:=02DX;
  linkCursorData[28]:=000X;
  linkCursorData[29]:=021X;
  linkCursorData[30]:=000X;
  linkCursorData[31]:=03FX;
  linkCursorData[32]:=000X;
  linkCursorData[33]:=000X;

  linkMaskData[ 0]:=0FFX;
  linkMaskData[ 1]:=007X;
  linkMaskData[ 2]:=0FFX;
  linkMaskData[ 3]:=07FX;
  linkMaskData[ 4]:=0FFX;
  linkMaskData[ 5]:=07FX;
  linkMaskData[ 6]:=0FFX;
  linkMaskData[ 7]:=07FX;
  linkMaskData[ 8]:=0FFX;
  linkMaskData[ 9]:=077X;
  linkMaskData[10]:=0FFX;
  linkMaskData[11]:=077X;
  linkMaskData[12]:=0FFX;
  linkMaskData[13]:=077X;
  linkMaskData[14]:=0FFX;
  linkMaskData[15]:=07FX;
  linkMaskData[16]:=0FFX;
  linkMaskData[17]:=07FX;
  linkMaskData[18]:=0FFX;
  linkMaskData[19]:=07FX;
  linkMaskData[20]:=0FFX;
  linkMaskData[21]:=07FX;
  linkMaskData[22]:=0FFX;
  linkMaskData[23]:=07FX;
  linkMaskData[24]:=0FFX;
  linkMaskData[25]:=07FX;
  linkMaskData[26]:=080X;
  linkMaskData[27]:=07FX;
  linkMaskData[28]:=080X;
  linkMaskData[29]:=07FX;
  linkMaskData[30]:=080X;
  linkMaskData[31]:=07FX;
  linkMaskData[32]:=080X;
  linkMaskData[33]:=07FX;

END VO:OS:X11:Display.