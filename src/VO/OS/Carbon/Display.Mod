MODULE VO:OS:Carbon:Display;

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

       EO   := VO:OS:Carbon:Event,

       P    := VO:Prefs:Base,

               VO:Image:Image,

               ChannelFDWrapper,

       S    := IO:Select,

      Codec := XML:UnicodeCodec,
<* PUSH; Warnings:=FALSE *>
               XML:UnicodeCodec:Latin1,
               Latin9,
<* POP *>
  (*       a    := Xatom,*)

               Carbon,
               CarbonWrapper,

               Ascii,
       c    := Calendar,
               IO,
               Err,
               Files,
               Object,
       str  := Strings,
       sc   := SysClock,
               TextRider,
       t    := Time,
               SYSTEM;


(* ============== Implementation classes ============== *)

CONST
  driverName = "Carbon";

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
                      next  : Timer; (** All @code{Timer}s are single linked and ordered.*)
                      timer : Carbon.EventLoopTimerRef;
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

  Font*     = POINTER TO FontDesc;
  FontDesc* = RECORD (D.FontDesc)
                lbearing : LONGINT;
                handle   : Carbon.FMFontFamily;
                atsu     : Carbon.ATSUFontID;
                layout   : Carbon.ATSUTextLayout;
                styles   : ARRAY D.maxStyleNum OF Carbon.ATSUStyle;
              END;

(*  PointArray   = ARRAY 256 OF X11.XPoint;*)

  Window*      = POINTER TO WindowDesc;

  Display*     = POINTER TO DisplayDesc;
  DisplayDesc* = RECORD (D.DisplayDesc)
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

                   multiClickTime : LONGINT;

                   bufferUCS2    : POINTER TO ARRAY OF LONGCHAR;

                   fontScratch   : Carbon.GWorldPtr;

                   colorSpace-   : Carbon.CGColorSpaceRef;
                   grab          : Window;
                 END;

  Bitmap*       = POINTER TO BitmapDesc;
  BitmapDesc* =   RECORD (D.BitmapDesc)
                    world : Carbon.GWorldPtr;
                  END;

  DrawInfo*     = POINTER TO DrawInfoDesc;

  ClipEntryDesc = RECORD
                    region  : Carbon.RgnHandle;
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
                    mode(*,
                    cap,
                    join*)  : LONGINT;
                  END;

  PenDash       = POINTER TO PenDashDesc;
  PenDashDesc   = RECORD
                    next    : PenDash;
                    pattern : Carbon.Pattern;
                    mode    : LONGINT;
                  END;

  Pattern       = POINTER TO PatternDesc;
  PatternDesc   = RECORD
                    next    : Pattern;
                    mode    : LONGINT;
                    pattern : Carbon.Pattern;
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

                    port-        : Carbon.CGrafPtr;
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

                  window         : Carbon.WindowPtr;
                  tracking       : Carbon.MouseTrackingRef;
                END;

  FactoryImpl*      = POINTER TO FactoryImplDesc;
  FactoryImplDesc*  = RECORD (D.FactoryDesc)
                      END;

  DisplayPrefs     = POINTER TO DisplayPrefsDesc;
  DisplayPrefsDesc = RECORD (D.DisplayPrefsDesc)
                     END;

VAR
  factory- : FactoryImpl;

  timerMsg : D.TimerMsg;

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
        NEW(p.fonts[x].name,str.Length("Helvetica")+1);
        COPY("Helvetica",p.fonts[x].name^);
      ELSE
        NEW(p.fonts[x].name,str.Length("Courier")+1);
        COPY("Courier",p.fonts[x].name^);
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

  PROCEDURE (d : Display) EnlargeUCS2Buffer(len : LONGINT);

  BEGIN
    IF (d.bufferUCS2=NIL) OR (LEN(d.bufferUCS2^)<len) THEN
      NEW(d.bufferUCS2,len);
    END;
  END EnlargeUCS2Buffer;

  (* -------- font stuff ------------- *)

  PROCEDURE (font : Font) Init*;


  BEGIN
    font.Init^;

    font.last:=NIL;
    font.next:=NIL;

    font.handle:=0;
    font.atsu:=0;
  END Init;

  PROCEDURE (font : Font) SetFont(port : Carbon.CGrafPtr; style : SET);

    (**
      Assign the given font settings to the internal scratch world
      for further evaluation.
    *)

  VAR
    face : Carbon.StyleParameter;

  BEGIN
    Carbon.SetGWorld(port,NIL);

    face:=0;
    IF D.bold IN style THEN
      INC(face,Carbon.bold);
    END;

    IF (D.italic IN style) OR (D.slanted IN style) THEN
      INC(face,Carbon.italic);
    END;

    IF D.underlined IN style THEN
      INC(face,Carbon.underline);
    END;

    Carbon.TextFont(font.handle);
    Carbon.TextSize(SHORT(font.pixelHeight));
    Carbon.TextFace(face);
  END SetFont;

  PROCEDURE (font : Font) Load*():D.Font;

  VAR
    metric : Carbon.FontInfo;
    name   : ARRAY 256 OF CHAR;
    x      : LONGINT;
    tags   : ARRAY 6 OF Carbon.ATSUAttributeTag;
    sizes  : ARRAY 6 OF Carbon.ByteCount;
    values : ARRAY 6 OF Carbon.ATSUAttributeValuePtr;

    size   : Carbon.Fixed;
    caret  : Carbon.Boolean;
    bold,
    italic,
    underline : Carbon.Boolean;
    style  : SET;

  BEGIN
    (* Class ic Quickdraw font handling *)
    x:=0;
    WHILE font.name[x]#0X DO
      name[x+1]:=font.name[x];
      INC(x);
    END;
    name[0]:=CHR(x);

    font.handle:=Carbon.FMGetFontFamilyFromName(SYSTEM.VAL(Carbon.Ptr,SYSTEM.ADR(name)));

    font.SetFont(D.display(Display).fontScratch,{});

    Carbon.GetFontInfo(SYSTEM.VAL(Carbon.AutoPtr_FontInfo,SYSTEM.ADR(metric)));

    font.lbearing:=metric.leading;
    font.height:=metric.ascent+metric.descent(*font.pixelHeight*);
    font.descent:=metric.descent;
    font.ascent:=metric.ascent;

    (* ATSU font handling *)

    IF Carbon.ATSUFindFontFromName(SYSTEM.VAL(Carbon.Ptr,font.name),
                                   x,
                                   Carbon.kFontFullName,(*Carbon.kFontNoNameCode*)
                                   -1(*Carbon.kFontNoPlattformCode*),
                                   -1(*Carbon.kFontNoScriptCode*),
                                   -1(*Carbon.kFontNoLanguageCode*),
                                   font.atsu)#Carbon.noErr THEN
      Err.String("Cannot load font!"); Err.Ln;
    END;

    tags[0]:=Carbon.kATSUSizeTag;
    tags[1]:=Carbon.kATSUFontTag;
    tags[2]:=Carbon.kATSUNoCaretAngleTag;
    tags[3]:=Carbon.kATSUQDBoldfaceTag;
    tags[4]:=Carbon.kATSUQDItalicTag;
    tags[5]:=Carbon.kATSUQDUnderlineTag;

    sizes[0]:=SIZE(Carbon.Fixed);
    sizes[1]:=SIZE(Carbon.ATSUFontID);
    sizes[2]:=SIZE(Carbon.Boolean);
    sizes[3]:=SIZE(Carbon.Boolean);
    sizes[4]:=SIZE(Carbon.Boolean);
    sizes[5]:=SIZE(Carbon.Boolean);

    size:=Carbon.Long2Fix(font.pixelHeight);
    caret:=1X;

    values[0]:=SYSTEM.VAL(Carbon.ATSUAttributeValuePtr,SYSTEM.ADR(size));
    values[1]:=SYSTEM.VAL(Carbon.ATSUAttributeValuePtr,SYSTEM.ADR(font.atsu));
    values[2]:=SYSTEM.VAL(Carbon.ATSUAttributeValuePtr,SYSTEM.ADR(caret));
    values[3]:=SYSTEM.VAL(Carbon.ATSUAttributeValuePtr,SYSTEM.ADR(bold));
    values[4]:=SYSTEM.VAL(Carbon.ATSUAttributeValuePtr,SYSTEM.ADR(italic));
    values[5]:=SYSTEM.VAL(Carbon.ATSUAttributeValuePtr,SYSTEM.ADR(underline));

    FOR x:=0 TO LEN(font.styles)-1 DO
      style:=SYSTEM.VAL(SET,x);

      IF D.bold IN style THEN
        bold:=1X;
      ELSE
        bold:=0X;
      END;

      IF (D.italic IN style) OR (D.slanted IN style) THEN
        italic:=1X;
      ELSE
        italic:=0X;
      END;

      IF D.underlined IN style THEN
        underline:=1X;
      ELSE
        underline:=0X;
      END;

      IF Carbon.ATSUCreateStyle(font.styles[x])#Carbon.noErr THEN
        Err.String("Cannot create style"); Err.Ln;
      END;

      IF Carbon.ATSUSetAttributes(font.styles[x],
                                  6,
                                  tags,
                                  sizes,
                                  values)#Carbon.noErr THEN
        Err.String("Cannot set style attributes"); Err.Ln;
      END;
    END;

    IF Carbon.ATSUCreateTextLayout(font.layout)#Carbon.noErr THEN
      Err.String("Cannot create layout"); Err.Ln;
    END;

    (*font.loaded:=TRUE;*)

(*    font.features:={};*)
(*    font.useCount:=0;*)

    RETURN font;
  END Load;

  PROCEDURE (font : Font) TextWidth*(text [NO_COPY]: ARRAY OF CHAR; length : LONGINT; style : SET):LONGINT;

  BEGIN
    font.SetFont(D.display(Display).fontScratch,style);

    RETURN Carbon.TextWidth(SYSTEM.VAL(Carbon.LogicalAddress,SYSTEM.ADR(text)),
                            0,SHORT(length));

(*    D.display(Display).EnlargeUCS2Buffer(length+1);
    D.prefs.localeCodec.Decode(text,0,length,D.display(Display).bufferUCS2^,0,length+1,sEnd,dEnd);
    D.display(Display).bufferUCS2[dEnd]:=0X;

    RETURN font.LongTextWidth(D.display(Display).bufferUCS2^,dEnd,style);*)
  END TextWidth;

  PROCEDURE (font : Font) LongTextWidth*(text : ARRAY OF LONGCHAR; length : LONGINT; style : SET):LONGINT;

  VAR
    bound : ARRAY 1 OF Carbon.ATSTrapezoid;
    count : Carbon.ItemCount;

  BEGIN
    Carbon.SetGWorld(D.display(Display).fontScratch,NIL);

    IF length=0 THEN
      RETURN 0;
    END;

    IF Carbon.ATSUSetTextPointerLocation(font.layout,
                                         SYSTEM.VAL(Carbon.UniCharPtr,SYSTEM.ADR(text[0])),
                                         0,length,length)#Carbon.noErr THEN
      Err.String("Cannot set text pointer"); Err.Ln;
    END;

    IF Carbon.ATSUSetRunStyle(font.layout,
                              font.styles[D.StyleToPos(style)],
                              0,length)#Carbon.noErr THEN
      Err.String("Cannot set run style"); Err.Ln;
    END;

    bound[0].upperLeft.x:=0;
    bound[0].upperLeft.y:=0;
    IF Carbon.ATSUGetGlyphBounds(font.layout,
                                 0,0,
                                 0,length,
                                 Carbon.kATSUseDeviceOrigins,
                                 1,
                                 bound,
                                 count)#Carbon.noErr THEN
      Err.String("Cannot calculate text bounds"); Err.Ln;
    END;

    RETURN Carbon.Fix2Long(bound[0].upperRight.x-bound[0].upperLeft.x);
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

  PROCEDURE (font : Font) TextExtent*(text [NO_COPY]: ARRAY OF CHAR;
                                      length : LONGINT; style : SET;
                                    VAR extent : D.FontExtentDesc);

  BEGIN
    extent.lbearing:=font.lbearing;
    extent.rbearing:=font.TextWidth(text,length,style);
    extent.width:=extent.rbearing;
    extent.ascent:=font.ascent;
    extent.descent:=font.descent;
    extent.height:=font.height;

(*
    D.display(Display).EnlargeUCS2Buffer(length+1);
    D.prefs.localeCodec.Decode(text,0,length,D.display(Display).bufferUCS2^,0,length+1,sEnd,dEnd);
    D.display(Display).bufferUCS2[dEnd]:=0X;

    font.LongTextExtent(D.display(Display).bufferUCS2^,dEnd,style,extent);*)
  END TextExtent;

  PROCEDURE (font : Font) LongTextExtent*(text [NO_COPY] : ARRAY OF LONGCHAR;
                                          length : LONGINT; style : SET;
                                          VAR extent : D.FontExtentDesc);

  VAR
    bound : ARRAY 1 OF Carbon.ATSTrapezoid;
    count : Carbon.ItemCount;

  BEGIN
    Carbon.SetGWorld(D.display(Display).fontScratch,NIL);

    IF Carbon.ATSUSetTextPointerLocation(font.layout,
                                         SYSTEM.VAL(Carbon.UniCharPtr,SYSTEM.ADR(text[0])),
                                         0,length,length)#Carbon.noErr THEN
      Err.String("Cannot set text pointer"); Err.Ln;
    END;

    IF Carbon.ATSUSetRunStyle(font.layout,
                              font.styles[D.StyleToPos(style)],
                              0,length)#Carbon.noErr THEN
      Err.String("Cannot set run style"); Err.Ln;
    END;

    bound[0].upperLeft.x:=0;
    bound[0].upperLeft.y:=0;
    IF Carbon.ATSUGetGlyphBounds(font.layout,
                                 0,0,
                                 0,length,
                                 Carbon.kATSUseDeviceOrigins,
                                 1,
                                 bound,
                                 count)#Carbon.noErr THEN
      Err.String("Cannot calculate text bounds"); Err.Ln;
    END;

    IF length=0 THEN
      extent.lbearing:=0;
      extent.rbearing:=0;
      extent.width:=0;
    ELSE
      extent.lbearing:=Carbon.Fix2Long(-bound[0].upperLeft.x);
      extent.rbearing:=Carbon.Fix2Long(bound[0].upperRight.x-bound[0].upperLeft.x);
      extent.width:=extent.lbearing+Carbon.Fix2Long(bound[0].upperRight.x-bound[0].upperLeft.x);
    END;
    extent.ascent:=Carbon.Fix2Long(-bound[0].upperLeft.y);
    extent.descent:=Carbon.Fix2Long(bound[0].lowerLeft.y);
    extent.height:=Carbon.Fix2Long(bound[0].lowerLeft.y-bound[0].upperLeft.y);
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
      font.TextExtent(str8^,text.length,style,extent);
    | text : Object.String16 DO
      str16:=text.CharsUTF16();
      font.LongTextExtent(str16^,text.length,style,extent);
    END;
  END StrExtent;

  PROCEDURE (font : Font) Free*;

  BEGIN
    (*
      TODO:

      Free Styles
      Free layout
    *)
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
    region : Carbon.RgnHandle;

  BEGIN
    region:=Carbon.NewRgn();
    Carbon.UnionRgn(d.clipStack[d.clipPos].region,region,region);
    pos:=d.clipPos-1;
    WHILE pos>=0 DO
      Carbon.SectRgn(d.clipStack[pos].region,region,region);
      DEC(pos);
    END;
    Carbon.SetGWorld(d.port,NIL);
    Carbon.SetClip(region);
    Carbon.DisposeRgn(region);
  END RecalcClipRegion;

  PROCEDURE (VAR c : ClipEntryDesc) Init(draw : DrawInfo);
  (**
    Initializes a clip entry object.
  *)

  BEGIN
    c.draw:=draw;

    c.region:=Carbon.NewRgn();
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
    region : Carbon.RgnHandle;

  BEGIN
    region:=Carbon.NewRgn();
    Carbon.SetRectRgn(region,
                      SHORT(x),SHORT(y),
                      SHORT(x+width),SHORT(y+height));
    Carbon.UnionRgn(c.region,region,c.region);
    Carbon.DisposeRgn(region);
    c.draw.RecalcClipRegion;
  END Add;

  PROCEDURE (VAR c : ClipEntryDesc) Sub(x,y,width,height : LONGINT);
  (**
    adds the given rectangle to the current clip entry.
  *)

  VAR
    region : Carbon.RgnHandle;

  BEGIN
    region:=Carbon.NewRgn();
    Carbon.SetRectRgn(region,
                      SHORT(x),SHORT(y),
                      SHORT(x+width),SHORT(y+height));
    Carbon.DiffRgn(c.region,region,c.region);
    Carbon.DisposeRgn(region);
    c.draw.RecalcClipRegion;
  END Sub;

  PROCEDURE (VAR c : ClipEntryDesc) Free;
  (**
    Frees the given clip entry.
  *)

  BEGIN
    Carbon.DisposeRgn(c.region);
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
    Carbon.SetClip(d.clipStack[0].region);
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

(*  VAR
    rect : X11.XRectangle;*)

  BEGIN
(*    xu.XClipBox(d.clipStack[d.clipPos].region,rect);
    x:=rect.x;
    y:=rect.y;
    w:=rect.width;
    h:=rect.height;*)
  END GetClipRegion;

  PROCEDURE (d : DrawInfo) FreeLastClip*;

  BEGIN
    d.clipStack[d.clipPos].Free;
    DEC(d.clipPos);
    IF d.clipPos>=0 THEN
      d.clipStack[d.clipPos].Install;
    END;
  END FreeLastClip;

  PROCEDURE (d : DrawInfo) Init(port : Carbon.CGrafPtr);
  (**
    Initialize an instance of the  DrawInfo class.
  *)

  BEGIN
    d.port:=port;

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
  END Deinit;

  PROCEDURE (d : DrawInfo) PushFont*(font : D.Font; style : SET);

  VAR
    help : FontStack;
    pos  : LONGINT;

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

      d.fontStack[d.fontPos].font:=font(Font);
      d.fontStack[d.fontPos].style:=style;
      d.fontStack[d.fontPos].count:=1;

      d.fontStack[d.fontPos].font.SetFont(d.port,style);
    END;
  END PushFont;

  PROCEDURE (d : DrawInfo) PopFont*;

  BEGIN
    IF d.fontStack[d.fontPos].count>1 THEN
      DEC(d.fontStack[d.fontPos].count);
    ELSE
      DEC(d.fontPos);

      IF d.fontPos>=0 THEN
        d.fontStack[d.fontPos].font.SetFont(d.port,
                                            d.fontStack[d.fontPos].style);
      END;
    END;
  END PopFont;

  PROCEDURE (d : DrawInfo) DrawString*(x,y : LONGINT; text [NO_COPY]: ARRAY OF CHAR; length : LONGINT);

  BEGIN
    Carbon.SetGWorld(d.port,NIL);
    Carbon.MoveTo(SHORT(x),SHORT(y));
    Carbon.DrawText(SYSTEM.VAL(Carbon.LogicalAddress,SYSTEM.ADR(text)),
                    0,SHORT(length));

(*    D.display(Display).EnlargeUCS2Buffer(length+1);
    D.prefs.localeCodec.Decode(text,0,length,D.display(Display).bufferUCS2^,0,length+1,sEnd,dEnd);
    D.display(Display).bufferUCS2[dEnd]:=0X;

    d.DrawLongString(x,y,D.display(Display).bufferUCS2^,dEnd);*)
  END DrawString;

  PROCEDURE (d : DrawInfo) DrawLongString*(x,y : LONGINT; text [NO_COPY] : ARRAY OF LONGCHAR; length : LONGINT);

  BEGIN
    Carbon.SetGWorld(d.port,NIL);

    IF Carbon.ATSUSetTextPointerLocation(d.fontStack[d.fontPos].font.layout,
                                         SYSTEM.VAL(Carbon.UniCharPtr,SYSTEM.ADR(text[0])),
                                         0,length,length)#Carbon.noErr THEN
      Err.String("Cannot set text pointer"); Err.Ln;
    END;

    IF Carbon.ATSUSetRunStyle(d.fontStack[d.fontPos].font.layout,
                              d.fontStack[d.fontPos].font.styles[D.StyleToPos(d.fontStack[d.fontPos].style)],
                              0,length)#Carbon.noErr THEN
      Err.String("Cannot set run style"); Err.Ln;
    END;

    IF Carbon.ATSUDrawText(d.fontStack[d.fontPos].font.layout,
                           0,length,
                           Carbon.Long2Fix(x),
                           Carbon.Long2Fix(y))#Carbon.noErr THEN
      Err.String("Cannot draw layout"); Err.Ln;
    END;
  END DrawLongString;

  PROCEDURE (d : DrawInfo) DrawFillString*(x,y : LONGINT; text [NO_COPY]: ARRAY OF CHAR; length : LONGINT);

  BEGIN
    d.PushForeground(d.bPenStack[d.fPenPos].color);
    d.FillRectangle(x+d.fontStack[d.fontPos].font.lbearing,
                    y-d.fontStack[d.fontPos].font.ascent,
                    d.fontStack[d.fontPos].font.TextWidth(text,length,
                                                          d.fontStack[d.fontPos].style),
                    d.fontStack[d.fontPos].font.height);
    d.PopForeground;

    d.DrawString(x,y,text,length);
  END DrawFillString;

  PROCEDURE (d : DrawInfo) DrawFillLongString*(x,y : LONGINT; text [NO_COPY] : ARRAY OF LONGCHAR; length : LONGINT);

  BEGIN
    d.PushForeground(d.bPenStack[d.fPenPos].color);
    d.FillRectangle(x+d.fontStack[d.fontPos].font.lbearing,
                    y-d.fontStack[d.fontPos].font.ascent,
                    d.fontStack[d.fontPos].font.LongTextWidth(text,length,
                                                              d.fontStack[d.fontPos].style),
                    d.fontStack[d.fontPos].font.height);
    d.PopForeground;

    d.DrawLongString(x,y,text,length);
  END DrawFillLongString;

  PROCEDURE (d : DrawInfo) SetForeground(color : D.Color);

  VAR
    rgb : Carbon.RGBColor;

  BEGIN
    rgb.red  :=SHORT(((color DIV 256) DIV 256)*256);
    rgb.green:=SHORT(((color DIV 256) MOD 256)*256);
    rgb.blue :=SHORT((color MOD 256)*256);

    Carbon.SetGWorld(d.port,NIL);
    Carbon.RGBForeColor(SYSTEM.VAL(Carbon.RGBColorPtr,SYSTEM.ADR(rgb)));
  END SetForeground;

  PROCEDURE (d : DrawInfo) SetBackground(color : D.Color);

  VAR
    rgb : Carbon.RGBColor;

  BEGIN
    rgb.red  :=SHORT(((color DIV 256) DIV 256)*256);
    rgb.green:=SHORT(((color DIV 256) MOD 256)*256);
    rgb.blue :=SHORT((color MOD 256)*256);

    Carbon.SetGWorld(d.port,NIL);
    Carbon.RGBBackColor(SYSTEM.VAL(Carbon.RGBColorPtr,SYSTEM.ADR(rgb)));
  END SetBackground;

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

      d.SetForeground(color);
    END;
  END PushForeground;

  PROCEDURE (d : DrawInfo) PopForeground*;

  BEGIN
    IF d.fPenStack[d.fPenPos].count>1 THEN
      DEC(d.fPenStack[d.fPenPos].count);
    ELSE
      DEC(d.fPenPos);

      IF d.fPenPos>=0 THEN
        d.SetForeground(d.fPenStack[d.fPenPos].color);
      END;
    END;
  END PopForeground;

  PROCEDURE (d : DrawInfo) PushDrawMode*(mode : LONGINT);

  VAR
    m  : DrawMode;

  BEGIN
    NEW(m);
    m.mode:=mode;
    m.next:=d.modeStack;
    d.modeStack:=m;
  END PushDrawMode;

  PROCEDURE (d : DrawInfo) PopDrawMode*;

  BEGIN
    d.modeStack:=d.modeStack.next;
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

      d.SetBackground(color);
    END;
  END PushBackground;

  PROCEDURE (d : DrawInfo) PopBackground*;

  BEGIN
    IF d.bPenStack[d.bPenPos].count>1 THEN
      DEC(d.bPenStack[d.bPenPos].count);
    ELSE
      DEC(d.bPenPos);

      IF d.bPenPos>=0 THEN
        d.SetBackground(d.bPenStack[d.bPenPos].color);
      END;
    END;
  END PopBackground;

  PROCEDURE (d : DrawInfo) PushStyle*(size, mode : LONGINT);

  VAR
    pen  : PenStyle;
(*    lMode : LONGINT;*)

  BEGIN
    NEW(pen);
    pen.size:=size;
    pen.mode:=mode;
    IF mode=D.roundPen THEN
(*      pen.cap:=X11.CapRound;
      pen.join:=X11.JoinRound;*)
    ELSE
(*      pen.cap:=X11.CapButt;
      pen.join:=X11.JoinBevel;*)
    END;

(*    IF d.dashStack#NIL THEN
      lMode:=d.dashStack.mode;
    ELSE
      lMode:=X11.LineSolid;
    END;*)

    Carbon.SetGWorld(d.port,NIL);
    IF pen.size<2 THEN
      Carbon.PenSize(1,1);
    ELSE
      Carbon.PenSize(SHORT(pen.size),SHORT(pen.size));
    END;

    pen.next:=d.styleStack;
    d.styleStack:=pen;
  END PushStyle;

  PROCEDURE (d : DrawInfo) PopStyle*;

(*  VAR
    mode : LONGINT;*)

  BEGIN
    d.styleStack:=d.styleStack.next;

    Carbon.SetGWorld(d.port,NIL);
    IF d.styleStack#NIL THEN
      IF d.styleStack.size<2 THEN
        Carbon.PenSize(1,1);
      ELSE
        Carbon.PenSize(SHORT(d.styleStack.size),SHORT(d.styleStack.size));
      END;
    ELSE
      Carbon.PenSize(1,1);
    END;

(*    IF d.dashStack#NIL THEN
      mode:=d.dashStack.mode;
    ELSE
      mode:=X11.LineSolid;
    END;
 *)
  END PopStyle;

  PROCEDURE (d : DrawInfo) PushDash*(dashList : ARRAY OF CHAR;
                                     mode : LONGINT);

  VAR
    dash   : PenDash;
    i,j,k  : LONGINT;
    black  : BOOLEAN;
    pat    : INTEGER;
(*    size,
    cap,
    join,x : LONGINT;*)

  BEGIN
    NEW(dash);
    dash.mode:=mode;

    (* Caculate a line of the pattern *)
    i:=0;
    j:=0;
    black:=TRUE;
    pat:=0;
    WHILE (i<8) DO
      k:=ORD(dashList[j]);
      WHILE (k>0) & (i<8) DO
        IF black THEN
          pat:=pat*2+1;
        ELSE
          pat:=pat*2;
        END;
        DEC(k);
        INC(i);
      END;
      black:=~black;
      j:=(j+1) MOD LEN(dashList);
    END;

    (* Now map horizontal pattern line to vertical *)
    i:=0;
    j:=0;
    black:=TRUE;
    WHILE i<8 DO
      k:=ORD(dashList[j]);
      WHILE (k>0) & (i<8) DO
        IF black THEN
          dash.pattern.pat[i]:=CHR(pat);
        ELSE
          dash.pattern.pat[i]:=CHR(255-pat);
        END;
        DEC(k);
        INC(i);
      END;
      black:=~black;
      j:=(j+1) MOD LEN(dashList);
    END;

    dash.next:=d.dashStack;
    d.dashStack:=dash;
  END PushDash;

  PROCEDURE (d : DrawInfo) PopDash*;

  BEGIN
    d.dashStack:=d.dashStack.next;
  END PopDash;

  PROCEDURE (d : DrawInfo) PushPattern*(pattern : ARRAY OF CHAR;
                                        width, height : LONGINT;
                                        mode : LONGINT);
  VAR
    pat : Pattern;

  BEGIN
    NEW(pat);
    pat.mode:=mode;
    IF Carbon.GetQDGlobalsGray(SYSTEM.VAL(Carbon.ConstPatternParam,
                                          SYSTEM.ADR(pat.pattern)))#NIL THEN
    END;
    pat.next:=d.patternStack;
    d.patternStack:=pat;
  END PushPattern;

  PROCEDURE (d : DrawInfo) PopPattern*;

  BEGIN
    d.patternStack:=d.patternStack.next;
  END PopPattern;

  PROCEDURE (d : DrawInfo) PushBitmap*(bitmap : D.Bitmap; mode : LONGINT);

  VAR
    pat : Pattern;

  BEGIN
    NEW(pat);
    (*pat.pixMap:=bitmap(Bitmap).pixmap;*)
    pat.mode:=mode;
    IF Carbon.GetQDGlobalsGray(SYSTEM.VAL(Carbon.ConstPatternParam,
                                          SYSTEM.ADR(pat.pattern)))#NIL THEN
    END;
    pat.next:=d.patternStack;
    d.patternStack:=pat;
  END PushBitmap;

  PROCEDURE (d : DrawInfo) PopBitmap*;

  BEGIN
    d.patternStack:=d.patternStack.next;
  END PopBitmap;

  (* Drawing functions *)

  PROCEDURE (d : DrawInfo) DrawPoint*(x,y : LONGINT);

  VAR
    rgb : Carbon.RGBColor;

  BEGIN
    rgb.red  :=SHORT(((d.fPenStack[d.fPenPos].color DIV 256) DIV 256)*256);
    rgb.green:=SHORT(((d.fPenStack[d.fPenPos].color DIV 256) MOD 256)*256);
    rgb.blue :=SHORT((d.fPenStack[d.fPenPos].color MOD 256)*256);

    Carbon.SetGWorld(d.port,NIL);
    Carbon.SetCPixel(SHORT(x),
                     SHORT(y),
                     SYSTEM.VAL(Carbon.RGBColorPtr,SYSTEM.ADR(rgb)));
  END DrawPoint;

  PROCEDURE (d : DrawInfo) DrawLine*(x1,y1,x2,y2 : LONGINT);

  VAR
    pattern : Carbon.Pattern;

  BEGIN
    Carbon.SetGWorld(d.port,NIL);

    IF d.dashStack#NIL THEN
      Carbon.PenPat(SYSTEM.VAL(Carbon.ConstPatternParam,
                               SYSTEM.ADR(d.dashStack.pattern)));
      IF d.dashStack.mode=D.fMode THEN
        Carbon.PenMode(Carbon.srcOr);
        Carbon.MoveTo(SHORT(x1),SHORT(y1));
        Carbon.LineTo(SHORT(x2),SHORT(y2));
        Carbon.PenMode(Carbon.srcCopy);
      ELSE
        Carbon.MoveTo(SHORT(x1),SHORT(y1));
        Carbon.LineTo(SHORT(x2),SHORT(y2));
      END;

      IF Carbon.GetQDGlobalsBlack(SYSTEM.VAL(Carbon.ConstPatternParam,
                                             SYSTEM.ADR(pattern)))#NIL THEN
      END;
      Carbon.PenPat(SYSTEM.VAL(Carbon.ConstPatternParam,SYSTEM.ADR(pattern)));
    ELSE
      Carbon.MoveTo(SHORT(x1),SHORT(y1));
      Carbon.LineTo(SHORT(x2),SHORT(y2));
    END;
  END DrawLine;

  PROCEDURE (d : DrawInfo) DrawRectangle*(x,y,width,height : LONGINT);

  VAR
    rect : Carbon.Rect;

  BEGIN
    rect.top   :=SHORT(y);
    rect.left  :=SHORT(x);
    rect.bottom:=SHORT(rect.top+height);
    rect.right :=SHORT(rect.left+width);

    Carbon.SetGWorld(d.port,NIL);
    Carbon.FrameRect(SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)));
  END DrawRectangle;

  PROCEDURE (d : DrawInfo) FillRectangle*(x,y,width,height : LONGINT);

  VAR
    rect    : Carbon.Rect;
    pattern : Carbon.Pattern;

  BEGIN
    rect.top   :=SHORT(y);
    rect.left  :=SHORT(x);
    rect.bottom:=SHORT(rect.top+height);
    rect.right :=SHORT(rect.left+width);

    Carbon.SetGWorld(d.port,NIL);

    IF d.patternStack#NIL THEN
      Carbon.PenPat(SYSTEM.VAL(Carbon.ConstPatternParam,
                               SYSTEM.ADR(d.patternStack.pattern)));

      IF d.patternStack.mode=D.fgPattern THEN
        Carbon.PenMode(Carbon.srcOr);
        Carbon.PaintRect(SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)));
        Carbon.PenMode(Carbon.srcCopy);
      ELSE
        Carbon.PaintRect(SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)));
      END;

      IF Carbon.GetQDGlobalsBlack(SYSTEM.VAL(Carbon.ConstPatternParam,
                                             SYSTEM.ADR(pattern)))#NIL THEN
      END;
      Carbon.PenPat(SYSTEM.VAL(Carbon.ConstPatternParam,SYSTEM.ADR(pattern)));
    ELSE
      Carbon.PaintRect(SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)));
    END;
  END FillRectangle;

  PROCEDURE (d : DrawInfo) FillRectangleAlpha*(alpha : LONGINT; x,y,width,height : LONGINT);

  BEGIN
    d.FillRectangle(x,y,width,height);
  END FillRectangleAlpha;

  PROCEDURE (d : DrawInfo) InvertRectangle*(x,y,width,height : LONGINT);

  VAR
    rect : Carbon.Rect;

  BEGIN
    rect.top   :=SHORT(y);
    rect.left  :=SHORT(x);
    rect.bottom:=SHORT(rect.top+height);
    rect.right :=SHORT(rect.left+width);

    Carbon.SetGWorld(d.port,NIL);
    Carbon.InvertRect(SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)));
  END InvertRectangle;

  PROCEDURE (d : DrawInfo) DrawArc*(x,y,width,height,angle1,angle2 : LONGINT);

  VAR
    rect : Carbon.Rect;
    a,b  : INTEGER;

  BEGIN
    rect.top   :=SHORT(y);
    rect.left  :=SHORT(x);
    rect.bottom:=SHORT(rect.top+height);
    rect.right :=SHORT(rect.left+width);

    a:=SHORT(angle1+angle2) DIV 64;
    b:=SHORT(angle2) DIV 64;

    a:=(450-a) MOD 360;

    Carbon.SetGWorld(d.port,NIL);
    Carbon.FrameArc(SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)),a,b);
  END DrawArc;

  PROCEDURE (d : DrawInfo) FillArc*(x,y,width,height,angle1,angle2 : LONGINT);

  VAR
    rect : Carbon.Rect;
    a,b  : INTEGER;

  BEGIN
    rect.top   :=SHORT(y);
    rect.left  :=SHORT(x);
    rect.bottom:=SHORT(rect.top+height);
    rect.right :=SHORT(rect.left+width);

    a:=SHORT(angle1+angle2) DIV 64;
    b:=SHORT(angle2) DIV 64;

    a:=(450-a) MOD 360;

    Carbon.SetGWorld(d.port,NIL);
    Carbon.PaintArc(SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)),a,b);
  END FillArc;

  PROCEDURE (d : DrawInfo) FillPolygon*(points : ARRAY OF D.PointDesc;
                                        count : LONGINT);

  VAR
    handle : Carbon.PolyHandle;
    x      : LONGINT;

  BEGIN
    Carbon.SetGWorld(d.port,NIL);
    handle:=Carbon.OpenPoly();

    FOR x:=0 TO count-1 DO
      Carbon.LineTo(SHORT(points[x].x),SHORT(points[x].y));
    END;
    Carbon.LineTo(SHORT(points[0].x),SHORT(points[0].y));
    Carbon.ClosePoly;
    Carbon.PaintPoly(handle[0]);
  END FillPolygon;

  PROCEDURE (d : DrawInfo) CopyArea*(sX,sY,width,height,dX,dY : LONGINT);

  VAR
    screen : Carbon.BitMapPtr;
    source,
    dest   : Carbon.Rect;

  BEGIN
    Carbon.SetGWorld(d.port,NIL);

    screen:=Carbon.GetPortBitMapForCopyBits(d.port);

    source.top:=SHORT(sY);
    source.left:=SHORT(sX);
    source.bottom:=source.top+SHORT(height);
    source.right:=source.left+SHORT(width);

    dest.top:=SHORT(dY);
    dest.left:=SHORT(dX);
    dest.bottom:=dest.top+SHORT(height);
    dest.right:=dest.left+SHORT(width);

    d.PushForeground(D.blackColor);
    Carbon.CopyBits(screen,screen,
                    SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(source)),
                    SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(dest)),
                    Carbon.srcCopy,NIL);
    d.PopForeground;
  END CopyArea;

  PROCEDURE (d : DrawInfo) CopyFromBitmap*(bitmap : D.Bitmap;
                                           sX,sY,width,height,dX,dY : LONGINT);

  VAR
    sScr,
    dScr   : Carbon.BitMapPtr;
    source,
    dest   : Carbon.Rect;
    point  : Carbon.Point;
    hdl    : Carbon.PixMapHandle;

  BEGIN
    sScr:=Carbon.GetPortBitMapForCopyBits(bitmap(Bitmap).world);

    point.h:=SHORT(sX);
    point.v:=SHORT(sY);

    source.top:=point.v;
    source.left:=point.h;
    source.bottom:=source.top+SHORT(height);
    source.right:=source.left+SHORT(width);

    dScr:=Carbon.GetPortBitMapForCopyBits(d.port);

    point.h:=SHORT(dX);
    point.v:=SHORT(dY);

    dest.top:=point.v;
    dest.left:=point.h;
    dest.bottom:=dest.top+SHORT(height);
    dest.right:=dest.left+SHORT(width);

    d.PushForeground(D.blackColor);
    hdl:=Carbon.GetGWorldPixMap(bitmap(Bitmap).world);
    IF Carbon.LockPixels(hdl[0])#0X THEN
      Carbon.CopyBits(sScr,dScr,
                      SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(source)),
                      SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(dest)),
                      Carbon.srcCopy,NIL);
      Carbon.UnlockPixels(hdl[0]);
    END;
    d.PopForeground;
  END CopyFromBitmap;

  PROCEDURE (d : DrawInfo) CopyToBitmap*(sX,sY,width,height,dX,dY : LONGINT;
                                             bitmap : D.Bitmap);

  VAR
    sScr,
    dScr   : Carbon.BitMapPtr;
    source,
    dest   : Carbon.Rect;
    point  : Carbon.Point;
    hdl    : Carbon.PixMapHandle;

  BEGIN
    sScr:=Carbon.GetPortBitMapForCopyBits(d.port);

    point.h:=SHORT(sX);
    point.v:=SHORT(sY);

    source.top:=point.v;
    source.left:=point.h;
    source.bottom:=source.top+SHORT(height);
    source.right:=source.left+SHORT(width);

    dScr:=Carbon.GetPortBitMapForCopyBits(bitmap(Bitmap).world);

    point.h:=SHORT(dX);
    point.v:=SHORT(dY);

    dest.top:=point.v;
    dest.left:=point.h;
    dest.bottom:=dest.top+SHORT(height);
    dest.right:=dest.left+SHORT(width);

    d.PushForeground(D.blackColor);
    hdl:=Carbon.GetGWorldPixMap(bitmap(Bitmap).world);
    IF Carbon.LockPixels(hdl[0])#0X THEN
      Carbon.CopyBits(sScr,dScr,
                      SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(source)),
                      SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(dest)),
                      Carbon.srcCopy,NIL);
      Carbon.UnlockPixels(hdl[0]);
    END;
    d.PopForeground;
  END CopyToBitmap;

  (* ------------ Data Exchange stuff --------------- *)

  PROCEDURE (d : Display) GetWindow(window : Carbon.WindowPtr):Window;
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
(*    IF d.contextHelp THEN
      d.contextHelp:=FALSE;
      IF d.contextTimer.active THEN
        d.RemoveTimer(d.contextTimer);
      END;
    END;*)
  END StopContextHelp;

  PROCEDURE (d : Display) RestartContextHelp;
    (**
      Restart the generation of QuickHelp calls to windows stoped
      with Display.StopContextHelp.
    *)

  BEGIN
    (*
      IF d.contextTimer.active THEN
        d.RemoveTimer(d.contextTimer);
      END;
      d.AddTimer(d.contextTimer);
      d.contextHelp:=TRUE;*)
  END RestartContextHelp;

  PROCEDURE (d : Display) StartContextHelp;

    (**
      Restart the generation of QuickHelp calls to windows stoped
      with Display.StopContextHelp.
    *)

  BEGIN
(*    IF ~d.contextHelp THEN
      d.AddTimer(d.contextTimer);
      d.contextHelp:=TRUE;
    END;*)
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

  BEGIN
    RETURN NIL;
  END GetFontList;

  (* -------- color stuff of D.display ------------- *)

  PROCEDURE RGB(r,g,b : LONGINT):LONGINT;

  BEGIN
    RETURN r*256*256+g*256+b;
  END RGB;

  PROCEDURE (d : Display) AllocateColor8*(r,g,b : SHORTINT;
                                          default : D.Color;
                                          VAR color : D.Color);

  VAR
    R,G,B : LONGINT;

  BEGIN
    R:=r;
    IF R<0 THEN
      R:=256+R;
    END;

    G:=g;
    IF G<0 THEN
      G:=256+G;
    END;

    B:=b;
    IF B<0 THEN
      B:=256+B;
    END;

    color:=RGB(R,G,B);
  END AllocateColor8;

  PROCEDURE (d : Display) AllocateColor16*(r,g,b : INTEGER;
                                           default : D.Color;
                                          VAR color : D.Color);

  CONST
    scale = 256;

  BEGIN
    d.AllocateColor8(SHORT(r DIV scale),
                     SHORT(g DIV scale),
                     SHORT(b DIV scale),default,color);
  END AllocateColor16;

  PROCEDURE (d : Display) AllocateColor32*(r,g,b : LONGINT;
                                           default : D.Color;
                                           VAR color : D.Color);
  CONST
    scale = 256*256*256;

  BEGIN
    d.AllocateColor8(SHORT(SHORT(r DIV scale)),
                     SHORT(SHORT(g DIV scale)),
                     SHORT(SHORT(b DIV scale)),default,color);
  END AllocateColor32;

  PROCEDURE (d : Display) AllocateNamedColor*(name : ARRAY OF CHAR;
                                              default : D.Color;
                                              VAR color : D.Color);

  VAR
    r,g,b : LONGINT;

  BEGIN
    IF D.GetRGB32ByColorName(name,r,g,b) THEN
      d.AllocateColor32(r,g,b,default,color);
      RETURN;
    ELSIF name="royal blue" THEN
      color:=004169E1H;
    ELSIF name="light yellow" THEN
      color:=00FFFFE0H;
    ELSIF name="orange" THEN
      color:=00FFA500H;
    ELSIF name="dim grey" THEN
      color:=00696969H;
    ELSIF name="yellow4" THEN
      color:=008B8B00H;
    ELSIF name="Dark slate grey" THEN
      color:=002F4F4FH;
    ELSIF name="SteelBlue" THEN
      color:=00468CB8H;
    ELSIF name="purple" THEN
      color:=00B820F0H;
    ELSIF name="aquamarine" THEN
      color:=007FFFC8H;
    ELSIF name="palegreen" THEN
      color:=0098FF98H;
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


  PROCEDURE TimerHandler(event : Carbon.EventLoopTimerRef;
                         data : Carbon.LogicalAddress);

  VAR
    timer,
    current,
    help     : Timer;

  BEGIN
    timer:=SYSTEM.VAL(Timer,data);

    current:=D.display(Display).timerList;
    WHILE current#NIL DO
      IF current=timer THEN
        timerMsg.timer:=timer;
        help:=timer.next;
        D.display(Display).RemoveTimer(timer);
        timer.object.Receive(timerMsg);
        current:=help;
      ELSE
        current:=current.next;
      END;
    END;
  END TimerHandler;

  PROCEDURE (d : Display) AddTimer*(timer : D.Timer);

  VAR
    help  : Timer;
    dt    : sc.DateTime;
    time  : t.TimeStamp;
    main  : Carbon.EventLoopRef;
    tUPP  : Carbon.EventLoopTimerUPP;

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

    main:=Carbon.GetMainEventLoop();
    tUPP:=Carbon.NewEventLoopTimerUPP(TimerHandler);
    IF Carbon.InstallEventLoopTimer(main,
                                    (timer.interval.dayInt*t.msecPerDay+
                                    timer.interval.msecInt) DIV t.msecPerSec,
                                    0,
                                    tUPP,
                                    SYSTEM.VAL(Carbon.LogicalAddress,timer),
                                    timer(Timer).timer)#Carbon.noErr THEN
      Err.String("Error creating timer!"); Err.Ln;
    END;
  END AddTimer;

  PROCEDURE (d : Display) RemoveTimer*(timer : D.Timer);

  VAR
    help,
    last : Timer;

  BEGIN
    ASSERT(timer.active);

    timer.Deactivate;

    IF Carbon.RemoveEventLoopTimer(timer(Timer).timer)#Carbon.noErr THEN
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
    bitmap : D.Bitmap;
    rect   : Carbon.Rect;

  BEGIN
    bitmap:=factory.CreateBitmap();
    rect.left:=0;
    rect.top:=0;
    rect.right:=SHORT(width);
    rect.bottom:=SHORT(height);

    IF Carbon.NewGWorld(bitmap(Bitmap).world,
                        0,
                        SYSTEM.VAL(Carbon.RectPtr,
                                   SYSTEM.ADR(rect)),
                        NIL,NIL,0)#0 THEN

      RETURN NIL;
    END;

    bitmap.draw:=factory.CreateDrawInfo();
    bitmap.draw(DrawInfo).Init(bitmap(Bitmap).world);

    bitmap.width:=width;
    bitmap.height:=height;

    RETURN bitmap;
  END CreateBitmap;

  PROCEDURE (d : Display) CreateBitmapPattern*(pattern : ARRAY OF CHAR; width, height : LONGINT):D.Bitmap;

  VAR
    bitmap : D.Bitmap;

  BEGIN
    bitmap:=factory.CreateBitmap();
(*    bitmap(Bitmap).pixmap:=X11.XCreateBitmapFromData(d.display,
                                                     X11.XRootWindow(d.display,d.scrNum),
                                                     pattern,width,height);
    IF bitmap(Bitmap).pixmap=0 THEN
      RETURN NIL;
    END;

    bitmap.draw:=factory.CreateDrawInfo();
    bitmap.draw(DrawInfo).Init(bitmap(Bitmap).pixmap);

    bitmap.width:=width;
    bitmap.height:=height;
*)
    RETURN bitmap;
  END CreateBitmapPattern;

  PROCEDURE (d : Display) FreeBitmap*(bitmap : D.Bitmap);

  BEGIN
    Carbon.DisposeGWorld(bitmap(Bitmap).world);
  END FreeBitmap;

  PROCEDURE (d : Display) Open*():BOOLEAN;

  VAR
    i          : LONGINT;
    prefs      : DisplayPrefs;
    name       : STRING;
    tmp        : Object.CharsLatin1;
    colors     : ARRAY D.colorCount OF D.Color;
    region     : Carbon.RgnHandle;
    rect       : Carbon.Rect;
    file       : Files.File;
    res        : Files.Result;
    writer     : TextRider.Writer;

  BEGIN
    d.driverName:=driverName;

    file:=Files.New("/tmp/VisualOberon.err",{Files.write},res);
    writer:=TextRider.ConnectWriter(file);
    Err.SetWriter(writer);

    Carbon.InitCursor;

    IF Carbon.SetAntiAliasedTextEnabled(1X,11)=Carbon.noErr THEN
    END;

    d.colorSpace:=Carbon.CGColorSpaceCreateDeviceRGB();
    d.colorDepth:=24;

    Image.Probe(d);

    IF Carbon.DMGetDeskRegion(region)#Carbon.noErr THEN
      Err.String("Cannot get desktop region"); Err.Ln;
      RETURN FALSE;
    END;

    IF Carbon.GetRegionBounds(region,SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)))=NIL THEN
      Err.String("Cannot get screen rect"); Err.Ln;
      RETURN FALSE;
    END;

    d.scrWidth:=rect.right-rect.left;
    d.scrHeight:=rect.bottom-rect.top;

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

    rect.left:=0;
    rect.top:=0;
    rect.right:=10;
    rect.bottom:=10;

    IF Carbon.NewGWorld(d.fontScratch,
                        0,
                        SYSTEM.VAL(Carbon.RectPtr,
                                   SYSTEM.ADR(rect)),
                        NIL,NIL,0)#0 THEN
      Err.String("Cannot create font scratch!"); Err.Ln;
    END;

    FOR i:=0 TO D.fontCount-1 DO
      d.font[i]:=factory.CreateFont();

(*      INCL(D.prefs.fonts[i].features,D.fontCharSet);
      NEW(D.prefs.fonts[i].charSet,str.Length(unicodeEncoding)+1);
      COPY(unicodeEncoding,D.prefs.fonts[i].charSet^);
*)

      d.font[i]:=D.prefs.fonts[i].Load();
      IF d.font[i]=NIL THEN
        Err.String("Cannot load font '");
        Err.String(D.prefs.fonts[i].name^);
        Err.String(", ");
        Err.LongInt(D.prefs.fonts[i].pointHeight,0);
        Err.String("'"); Err.Ln;
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

    d.sleepList:=NIL;
    d.channelList:=NIL;

    d.selector:=S.Open();
    NEW(d.fdChannel);
    ChannelFDWrapper.Init(d.fdChannel,0);
    IF d.fdChannel.RegisterWithSelector(d.selector,{IO.opRead},NIL)#NIL THEN END;

    d.selectObject:=NIL;
    d.querySelectObject:=NIL;
    d.grab:=NIL;
(*    d.selClearPend:=FALSE;

    d.dragging:=FALSE;
    d.dragObject:=NIL;
*)
    d.multiClickTime:=2;

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

  PROCEDURE (d : Display) Beep*;

  BEGIN
(*    Curses.Beep;
    Curses.Flash;*)
  END Beep;

  PROCEDURE (d : Display) RegisterSelection*(object : D.Object;
                                             window : D.Window):BOOLEAN;

  BEGIN
    IF d.selectObject#object THEN

      IF (d.selectObject#NIL) THEN
        d.selectObject.Deselect;
        d.selectObject:=NIL;
      END;

      d.selectObject:=object;
    END;

    RETURN TRUE;
  END RegisterSelection;

  PROCEDURE (d : Display) CancelSelection*;

  BEGIN
    ASSERT(d.selectObject#NIL);
    d.selectObject.Deselect;
    d.selectObject:=NIL;
  END CancelSelection;

  PROCEDURE (d : Display) QuerySelection*(window : D.Window;
                                          object : D.Object;
                                          type   : LONGINT):BOOLEAN;

  BEGIN
    RETURN FALSE;
  END QuerySelection;

  PROCEDURE (d : Display) SetClipboard*(content : STRING):BOOLEAN;

  VAR
    txt8  : Object.CharsLatin1;
    text  : U.Text;
    scrap : Carbon.ScrapRef;
    x     : LONGINT;
    res   : Carbon.OSStatus;

  BEGIN
    Err.String("Setclipboard called!");Err.Ln;Err.Flush;
    WITH content : Object.String8 DO
      txt8:=content.CharsLatin1();
      NEW(text,content.length+1);
      COPY(txt8^,text^);
      FOR x:=0 TO content.length-1 DO
        IF text[x]=Ascii.lf THEN
          text[x]:=Ascii.cr;
        END;
      END;

      IF Carbon.ClearCurrentScrap()#Carbon.noErr THEN
        Err.String("Cannot clear curretn scrap");Err.Ln;Err.Flush;
        RETURN FALSE;
      END;

      IF Carbon.GetCurrentScrap(scrap)#Carbon.noErr THEN
        Err.String("Cannot get current scrap");Err.Ln;Err.Flush;
        RETURN FALSE;
      END;

      res:=Carbon.PutScrapFlavor(scrap,
                                 Carbon.kScrapFlavorTypeText,
                                 0,
                                 content.length,
                                 SYSTEM.VAL(Carbon.LogicalAddress,text));
      IF res#Carbon.noErr THEN
        Err.String("Cannot set clip: ");
        Err.LongInt(res,0);Err.Ln;Err.Flush;
        RETURN FALSE;
      END;

      RETURN TRUE;
    ELSE
      Err.String("Wrong string type!");Err.Ln;Err.Flush;
      RETURN FALSE;
    END;
  END SetClipboard;

  PROCEDURE (d : Display) GetClipboard*(object: D.Object):BOOLEAN;

  VAR
    scrap    : Carbon.ScrapRef;
    flavor   : Carbon.ScrapFlavorFlags;
    size     : Carbon.Size;
    dndData  : DD.DnDStringData;
    text     : U.Text;
    x        : LONGINT;

  BEGIN
    IF Carbon.GetCurrentScrap(scrap)#Carbon.noErr THEN
      RETURN FALSE;
    END;

    IF Carbon.GetScrapFlavorFlags(scrap,Carbon.kScrapFlavorTypeText,flavor)#Carbon.noErr THEN
      RETURN FALSE;
    END;

    IF Carbon.GetScrapFlavorSize(scrap,Carbon.kScrapFlavorTypeText,size)#Carbon.noErr THEN
      RETURN FALSE;
    END;

    NEW(text,size+1);

    IF Carbon.GetScrapFlavorData(scrap,Carbon.kScrapFlavorTypeText,size,
                                 SYSTEM.VAL(Carbon.LogicalAddress,text))#Carbon.noErr THEN
      RETURN FALSE;
    END;
    text[size]:=0X;

    FOR x:=0 TO size-1 DO
      IF text[x]=Ascii.cr THEN
        text[x]:=Ascii.lf;
      END;
    END;

    NEW(dndData);
    dndData.string:=Object.NewLatin1(text^);

    IF ~object.HandleDrop(dndData,DD.insert) THEN
      d.Beep;
    END;

    RETURN TRUE;
  END GetClipboard;

  PROCEDURE (d : Display) ClearClipboard*;

  BEGIN
    IF Carbon.ClearCurrentScrap()#Carbon.noErr THEN
    END;
  END ClearClipboard;

  PROCEDURE (d : Display) PutBackEvent*(event : E.Event; destWin : D.Window);

(*  VAR
    x11Event : X11.XEvent;
*)
  BEGIN
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
    Carbon.QuitApplicationEventLoop;
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
    Carbon.DisposeGWorld(d.fontScratch);

    IF Image.factory#NIL THEN
      Image.factory.Deinit(d);
      Image.factory:=NIL;
    END;

    Carbon.CGColorSpaceRelease(d.colorSpace);
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

  PROCEDURE (d : Display) HandleEvent(carbon : Carbon.EventRef);

  VAR
    event : E.Event;
    time  : Carbon.EventTime;

  BEGIN
    IF d.currentWin#NIL THEN
      Carbon.SetGWorld(d.currentWin.draw.port,NIL); (* GetEvent uses port sensitive functions *)
      event:=EO.GetEvent(carbon);
      IF event#NIL THEN

        WITH
          event : E.ButtonEvent DO
          IF event.type=E.mouseDown THEN
            d.currentWin.oldButton:=d.currentWin.lastButton;
            d.currentWin.oldPress:=d.currentWin.lastPress;
            d.currentWin.lastButton:=d.currentWin.thisButton;
            d.currentWin.lastPress:=d.currentWin.thisPress;
            d.currentWin.thisButton:=event(EO.ButtonEvent)^;

            time:=Carbon.GetEventTime(event(EO.ButtonEvent).event);
            d.currentWin.thisPress:=ENTIER(time*10);
          END;

          (* restarting context timer on user input *)
          d.RestartContextHelp;

        | event : E.KeyEvent DO

          (* restarting context timer on user input *)
          d.RestartContextHelp;

        ELSE
        END;

        REPEAT
          event.reUse:=FALSE;
          IF d.grab#NIL THEN
            IF d.grab.interface.HandleEvent(event) THEN END;
          ELSE
            IF d.currentWin.interface.HandleEvent(event) THEN END;
          END;
        UNTIL event.reUse=FALSE;
      END;
    END;
  END HandleEvent;

  PROCEDURE EventHandler(nextHandler : Carbon.EventHandlerCallRef;
                         event : Carbon.EventRef;
                         data : Carbon.LogicalAddress):Carbon.OSStatus;

  VAR
    res    : Carbon.OSStatus;
    window : Window;
    rect   : Carbon.Rect;
    point  : Carbon.Point;
(*    track  : Carbon.MouseTrackingResult;*)

  BEGIN
    window:=SYSTEM.VAL(Window,data);
    D.display(Display).currentWin:=window;

    CASE Carbon.GetEventClass(event) OF

      Carbon.kEventClassWindow:

      CASE Carbon.GetEventKind(event) OF
        Carbon.kEventWindowClose:
        IF (window.modalCount=0) THEN
          window.interface.OnClosePressed;
        END;

        RETURN Carbon.noErr;
      | Carbon.kEventWindowDrawContent:
        window.interface.OnRedraw(0,0,window.width,window.height);
      | Carbon.kEventWindowShowing:
        window.interface.OnMaped();
      | Carbon.kEventWindowHidden:
        window.interface.OnUnmaped();
      | Carbon.kEventWindowActivated:
        IF ~window.grab THEN
          D.display(Display).StartContextHelp;
        END;
        window.interface.OnFocusIn();
      | Carbon.kEventWindowDeactivated:
        IF ~window.grab THEN
          D.display(Display).StopContextHelp;
        END;
        window.interface.OnFocusOut;
      | Carbon.kEventWindowBoundsChanged:
        IF Carbon.GetEventParameter(event,
                                    Carbon.kEventParamCurrentBounds,
                                    Carbon.typeQDRectangle,
                                    NIL,
                                    SIZE(Carbon.Rect),
                                    NIL,
                                    SYSTEM.VAL(LONGINT,SYSTEM.ADR(rect)))=0 THEN
          window.x:=rect.left;
          window.y:=rect.top;

          IF (window.width#rect.right-rect.left+1) OR
            (window.height#rect.bottom-rect.top+1) THEN

            window.width:=rect.right-rect.left+1;
            window.height:=rect.bottom-rect.top+1;
            window.draw.FreeLastClip;
            window.draw.InstallClip(0,0,window.width,window.height);
            window.interface.OnResized(window.width,window.height);
          END;
        END;
      | Carbon.kEventWindowFocusAcquired:
        IF ~window.grab THEN
          D.display(Display).StartContextHelp;
        END;
        window.interface.OnFocusIn();
      | Carbon.kEventWindowFocusRelinquish:
        IF ~window.grab THEN
          D.display(Display).StopContextHelp;
        END;
        window.interface.OnFocusOut;
      | Carbon.kEventWindowGetMinimumSize:
        point.h:=SHORT(window.minWidth);
        point.v:=SHORT(window.minHeight);

        IF Carbon.SetEventParameter(event,
                                    Carbon.kEventParamDimensions,
                                    Carbon.typeQDPoint,
                                    SIZE(Carbon.Point),
                                    SYSTEM.VAL(LONGINT,SYSTEM.ADR(point)))=0 THEN
          RETURN Carbon.noErr;
        END;
      | Carbon.kEventWindowGetMaximumSize:
        point.h:=SHORT(window.maxWidth);
        point.v:=SHORT(window.maxHeight);

        (* Calculation of max bounds seems to be broken currently *)
        IF point.h<0 THEN
          point.h:=MAX(INTEGER);
        END;
        IF point.v<0 THEN
          point.v:=MAX(INTEGER);
        END;

        IF Carbon.SetEventParameter(event,
                                    Carbon.kEventParamDimensions,
                                    Carbon.typeQDPoint,
                                    SIZE(Carbon.Point),
                                    SYSTEM.VAL(LONGINT,SYSTEM.ADR(point)))=0 THEN
          RETURN Carbon.noErr;
        END;
      ELSE
      END;

    | Carbon.kEventClassMouse:

      IF window.modalCount=0 THEN
        CASE Carbon.GetEventKind(event) OF
          Carbon.kEventMouseDown:

          CASE window.type OF
            D.windowTypePopup,
            D.windowTypeSplash:
            IF Carbon.SetUserFocusWindow(window.window)#Carbon.noErr THEN
              Err.String("Cannot set keboard focus!"); Err.Ln;
            END;
          ELSE
          END;

          D.display(Display).HandleEvent(event);
        | Carbon.kEventMouseUp:
          D.display(Display).HandleEvent(event);
        | Carbon.kEventMouseMoved:
          D.display(Display).HandleEvent(event);
        | Carbon.kEventMouseDragged:
          D.display(Display).HandleEvent(event);
        | Carbon.kEventMouseEntered:
          window.interface.OnMouseEntered;
        | Carbon.kEventMouseExited:
          window.interface.OnMouseLeft;
(*          Err.String("Tracking..."); Err.Ln;
          REPEAT
            IF Carbon.TrackMouseLocation(window.draw.port,
                                         SYSTEM.VAL(Carbon.PointPtr,SYSTEM.ADR(point)),
                                         track)=Carbon.noErr THEN
              Err.String("Track: ");
              Err.LongInt(track,0);Err.Ln;
              Err.LongInt(point.h,0);Err.Char("x");Err.LongInt(point.v,0);Err.Ln;
            END;
          UNTIL track=Carbon.kMouseTrackingMouseDown;
          Err.String("Tracking (done)"); Err.Ln;*)
        ELSE
          Err.String("Mouse EventKind: ");
          Err.Hex(Carbon.GetEventKind(event),8); Err.Ln;
        END;
      END;

    | Carbon.kEventClassKeyboard:

      IF window.modalCount=0 THEN
        CASE Carbon.GetEventKind(event) OF
          Carbon.kEventRawKeyDown,
          Carbon.kEventRawKeyRepeat,
          Carbon.kEventRawKeyUp:
          D.display(Display).HandleEvent(event);
        ELSE
          Err.String("Key ");
          Err.String("EventKind: ");
          Err.Hex(Carbon.GetEventKind(event),8);
          Err.Ln;
        END;
      END;

    ELSE
    END;

    res:=Carbon.CallNextEventHandler(nextHandler,event);
    RETURN Carbon.noErr;
  END EventHandler;

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

  PROCEDURE (d : Display) EventLoop*;

  BEGIN

    ASSERT(d.exit);

    d.exit:=FALSE;

    Carbon.RunApplicationEventLoop();
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

    w.window:=NIL;
    w.tracking:=NIL;
  END Init;

  PROCEDURE (w : Window) SetTitle*(name : STRING);

  VAR
    x      : LONGINT;
    tmp    : U.Text;
    tmp8   : Object.CharsLatin1;
    title  : STRING;
    string : Carbon.CFStringRef;

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
        tmp8:=title.CharsLatin1();

        string:=Carbon.CFStringCreateWithCString(NIL,
                                                 SYSTEM.VAL(Carbon.Ptr,tmp8),
                                                 Carbon.kCFStringEncodingISOLatin1);

      | title : Object.String16 DO
        NEW(tmp,title.length+1);
        FOR x:=0 TO title.length-1 DO
          tmp[x]:=CHR(ORD(title.CharAt(x)));
        END;
        tmp[x]:=0X;

        string:=Carbon.CFStringCreateWithCString(NIL,
                                                 SYSTEM.VAL(Carbon.Ptr,tmp),
                                                 Carbon.kCFStringEncodingISOLatin1);

(*        tmp16:=title.CharsUTF16();
        string:=Carbon.CFStringCreateWithCharacters(NIL,
                                                    SYSTEM.VAL(Carbon.UniChar,tmp16[0]),
                                                    title.length);*)
      END;

      IF Carbon.SetWindowTitleWithCFString(w.window,string)=Carbon.noErr THEN
      END;

      Carbon.CFRelease(SYSTEM.VAL(Carbon.CFTypeRef,string));
    END;
  END SetTitle;

  PROCEDURE (w : Window) GetDrawInfo*():D.DrawInfo;

  BEGIN
    RETURN w.draw;
  END GetDrawInfo;

  PROCEDURE (w : Window) Resize*(width,height : LONGINT);

  BEGIN
    w.Resize^(width,height);

    Carbon.SizeWindow(w.window,SHORT(width),SHORT(height),1X);
  END Resize;

  PROCEDURE (w : Window) GrabOn;

  VAR
    region : Carbon.RgnHandle;
    id     : Carbon.MouseTrackingRegionID;
    res    : Carbon.OSStatus;

  BEGIN
    D.display(Display).StopContextHelp;


    (* TODO *)
    IF Carbon.DMGetDeskRegion(region)#Carbon.noErr THEN
      Err.String("Cannot get desktop region"); Err.Ln;
      RETURN;
    END;

    id.signature:=0F0F0F0FH;
    id.id:=-1;

    res:=CarbonWrapper.CreateMouseTrackingRegion(w.window,
                                                 region,
                                                 NIL,
                                                 Carbon.kMouseTrackingOptionsGlobalClip,
                                                 id,
                                                 0,
                                                 NIL,
                                                 w.tracking);
    IF res#Carbon.noErr THEN
      Err.String("Cannot create mouse tracking region: ");
      Err.Hex(res,0); Err.Char(" "); Err.LongInt(res,0); Err.Ln;
    ELSE
      D.display(Display).grab:=w;
    END;
  END GrabOn;

  PROCEDURE (w : Window) GrabOff;
  (**
    Releases the grab of the mouse cursor and the keyboard.
  *)

  BEGIN
    IF Carbon.ReleaseMouseTrackingRegion(w.tracking)#0 THEN
    END;

    D.display(Display).grab:=NIL;

    (* TODO *)
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

  PROCEDURE (w : Window) Open*():BOOLEAN;

  VAR
    draw      : D.DrawInfo;
    rect      : Carbon.Rect;
    res       : LONGINT;
    handler   : Carbon.EventHandlerUPP;
    targetRef : Carbon.EventTargetRef;
    spec      : ARRAY 20 OF Carbon.EventTypeSpec;

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

    rect.top := SHORT(w.y);
    rect.left := SHORT(w.x);
    rect.bottom := SHORT(w.y+w.height-1);
    rect.right := SHORT(w.x+w.width-1);

    CASE w.type OF
      D.windowTypeMenu,
      D.windowTypePopup,
      D.windowTypeSplash:
      res:=Carbon.CreateNewWindow(Carbon.kHelpWindowClass,
                                  Carbon.kWindowStandardHandlerAttribute,
                                  SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)),
                                  w.window);
    ELSE
      res:=Carbon.CreateNewWindow(Carbon.kDocumentWindowClass,
                                  Carbon.kWindowStandardDocumentAttributes+
                                  Carbon.kWindowStandardHandlerAttribute+
                                  Carbon.kWindowLiveResizeAttribute,
                                  SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)),
                                  w.window);
    END;

    IF res#0 THEN
      Err.String("Error creating: ");
      Err.Hex(res,8); Err.Char(" ");
      Err.LongInt(res,0);
      Err.Ln;
      RETURN FALSE
    END;

    Carbon.SetPortWindowPort(w.window);

    Carbon.PenNormal() ;
    Carbon.PenSize(1,1);

    targetRef:=Carbon.GetWindowEventTarget(w.window);
    IF Carbon.InstallStandardEventHandler(targetRef)=0 THEN END;

    spec[ 0].eventClass:=Carbon.kEventClassWindow;
    spec[ 0].eventKind:=Carbon.kEventWindowDrawContent;

    spec[ 1].eventClass:=Carbon.kEventClassWindow;
    spec[ 1].eventKind:=Carbon.kEventWindowShowing;

    spec[ 2].eventClass:=Carbon.kEventClassWindow;
    spec[ 2].eventKind:=Carbon.kEventWindowHidden;

    spec[ 3].eventClass:=Carbon.kEventClassWindow;
    spec[ 3].eventKind:=Carbon.kEventWindowActivated;

    spec[ 4].eventClass:=Carbon.kEventClassWindow;
    spec[ 4].eventKind:=Carbon.kEventWindowDeactivated;

    spec[ 5].eventClass:=Carbon.kEventClassWindow;
    spec[ 5].eventKind:=Carbon.kEventWindowClose;

    spec[ 6].eventClass:=Carbon.kEventClassWindow;
    spec[ 6].eventKind:=Carbon.kEventWindowBoundsChanged;

    spec[ 7].eventClass:=Carbon.kEventClassWindow;
    spec[ 7].eventKind:=Carbon.kEventWindowFocusAcquired;

    spec[ 8].eventClass:=Carbon.kEventClassWindow;
    spec[ 8].eventKind:=Carbon.kEventWindowFocusRelinquish;

    spec[ 9].eventClass:=Carbon.kEventClassWindow;
    spec[ 9].eventKind:=Carbon.kEventWindowGetMinimumSize;

    spec[10].eventClass:=Carbon.kEventClassWindow;
    spec[10].eventKind:=Carbon.kEventWindowGetMaximumSize;

    spec[11].eventClass:=Carbon.kEventClassMouse;
    spec[11].eventKind:=Carbon.kEventMouseUp;

    spec[12].eventClass:=Carbon.kEventClassMouse;
    spec[12].eventKind:=Carbon.kEventMouseDown;

    spec[13].eventClass:=Carbon.kEventClassMouse;
    spec[13].eventKind:=Carbon.kEventMouseMoved;

    spec[14].eventClass:=Carbon.kEventClassMouse;
    spec[14].eventKind:=Carbon.kEventMouseDragged;

    spec[15].eventClass:=Carbon.kEventClassMouse;
    spec[15].eventKind:=Carbon.kEventMouseEntered;

    spec[16].eventClass:=Carbon.kEventClassMouse;
    spec[16].eventKind:=Carbon.kEventMouseExited;

    spec[17].eventClass:=Carbon.kEventClassKeyboard;
    spec[17].eventKind:=Carbon.kEventRawKeyDown;

    spec[18].eventClass:=Carbon.kEventClassKeyboard;
    spec[18].eventKind:=Carbon.kEventRawKeyRepeat;

    spec[19].eventClass:=Carbon.kEventClassKeyboard;
    spec[19].eventKind:=Carbon.kEventRawKeyUp;

    handler:=Carbon.NewEventHandlerUPP(EventHandler);
    IF Carbon.InstallEventHandler(targetRef,handler,LEN(spec),
                                  SYSTEM.VAL(Carbon.AutoPtr_EventTypeSpec,
                                             SYSTEM.ADR(spec[0])),
                                  SYSTEM.VAL(LONGINT,w),
                                  NIL)=0 THEN END;

    w.SetTitle(w.GetTitle());

    draw:=factory.CreateDrawInfo();
    w.draw:=draw(DrawInfo);
    w.draw.Init(Carbon.GetWindowPort(w.window));

    w.draw.InstallClip(0,0,w.width,w.height);

    D.display(Display).AddWindow(w);
    D.display(Display).currentWin:=w;

    Carbon.ShowWindow(w.window);

    CASE w.type OF
      D.windowTypePopup,
      D.windowTypeSplash:
      IF Carbon.SetUserFocusWindow(w.window)#Carbon.noErr THEN
        Err.String("Cannot set keboard focus!"); Err.Ln;
      END;
    ELSE
    END;

    IF w.grab THEN
      w.GrabOn;
    END;

    RETURN TRUE;
  END Open;

  PROCEDURE (w : Window) Close*;

  BEGIN
    IF w.grab THEN
      w.GrabOff;
    END;

(*    w.interface.OnFocusOut;*)

    Carbon.HideWindow(w.window);

    w.Close^;

    IF w.IsOpen() & (w.window#NIL) THEN
      w.draw.FreeLastClip;
      w.draw.Deinit;
      Carbon.DisposeWindow(w.window);
      w.window:=NIL;
    END;

    D.display(Display).RemoveWindow(w);
  END Close;

  PROCEDURE (w : Window) GetMousePos*(VAR rx, ry, wx, wy : LONGINT);

  VAR
    point : Carbon.Point;

  BEGIN
    Carbon.SetGWorld(w.draw.port,NIL);
    Carbon.GetMouse(SYSTEM.VAL(Carbon.PointPtr,SYSTEM.ADR(point)));
    wx:=point.h;
    wy:=point.v;
    rx:=w.x+wx;
    ry:=w.y+ry;
  END GetMousePos;

  PROCEDURE (w : Window) EventLoop*;

  BEGIN
    ASSERT(w.exit);

    w.exit:=FALSE;

    w.DisableParents;

    IF Carbon.RunAppModalLoopForWindow(w.window)=0 THEN END;

    w.EnableParents;
  END EventLoop;

  PROCEDURE (w : Window) Enable*;

  BEGIN
    w.Enable^;

    IF w.modalCount=0 THEN
      (*X11.XUndefineCursor(D.display(Display).display,w.window);*)
    END;
  END Enable;

  PROCEDURE (w : Window) Disable*;

  BEGIN
    w.Disable^;

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

    IF Carbon.QuitAppModalLoopForWindow(w.window)=0 THEN END;
  END Exit;

  (* ------------ object factory --------------- *)

  PROCEDURE (f : FactoryImpl) Init*;

  BEGIN
    f.Init^;

    f.driverName:=driverName;

    f.SetPriority(20);
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

END VO:OS:Carbon:Display.
