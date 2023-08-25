MODULE VO:OS:Curses:Display;

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
       E    := VO:Base:Event,
       O    := VO:Base:Object,
       U    := VO:Base:Util,

       EO   := VO:OS:Curses:Event,

       P    := VO:Prefs:Base,

               ChannelFDWrapper,

       S    := IO:Select,

      Codec := XML:UnicodeCodec,
<* PUSH; Warnings:=FALSE *>
               XML:UnicodeCodec:Latin1,
               Latin9,
<* POP *>
  (*       a    := Xatom,*)

               Curses,

               ADT:ArrayList,
               Ascii,
               C,
       c    := Calendar,
               IO,
               Err,
               Object,
       sc   := SysClock,
       t    := Time;


(* ============== Implementation classes ============== *)

CONST
  driverName = "Curses";

  (* Size of the various stack arrays *)
  initialStackSize   = 30;
  stackSizeIncrement = 30;

  unicodeEncoding* = "iso10646-1";

  foreground = "white";
  background = "black";

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
              END;

(*  PointArray   = ARRAY 256 OF X11.XPoint;*)

  Window*      = POINTER TO WindowDesc;

  Display*     = POINTER TO DisplayDesc;
  DisplayDesc* = RECORD (D.DisplayDesc)
                    (* windowing information *)
                    currentWin   : Window;

                    selectObject,
                    querySelectObject : D.Object;

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

                    exit         : BOOLEAN;

                    multiClickTime : LONGINT;

                    (* for speed up *)
(*                    pointArray    : PointArray;*)
                   bufferUCS2    : POINTER TO ARRAY OF LONGCHAR;

                   top           : Curses.Window;
                   windowStack   : ArrayList.ArrayList(Window);
                 END;

  Bitmap*     = POINTER TO BitmapDesc;
  BitmapDesc* = RECORD (D.BitmapDesc)
(*                    pixmap- : X11.Pixmap;*)
                  END;

  DrawInfo*     = POINTER TO DrawInfoDesc;

  ClipRegion    = POINTER TO ARRAY OF BOOLEAN;

  ClipEntryDesc = RECORD
                    region  : ClipRegion;
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

  PenDash       = POINTER TO PenDashDesc;
  PenDashDesc   = RECORD
                    next : PenDash;
                    list : POINTER TO ARRAY OF CHAR;
                    mode : LONGINT;
                  END;

  Pattern       = POINTER TO PatternDesc;
  PatternDesc   = RECORD
                    next    : Pattern;
                    width,
                    height  : LONGINT;
                    pattern : U.Text;
                    mode    : LONGINT;
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

                    dashStack    : PenDash;
                    patternStack : Pattern;
                    modeStack    : DrawMode;

                    window       : Window;
                    clipRegion   : ClipRegion;
                  END;

  WindowDesc* = RECORD (D.WindowImplDesc)
                  draw        : DrawInfo;
                  grab,
                  exit        : BOOLEAN;

                  (* For double click *)
                  oldButton,
                  lastButton,
                  thisButton  : EO.ButtonEventDesc;
                  oldPress,
                  lastPress,
                  thisPress   : LONGINT;

                  frame       : Curses.Window;
                  window      : Curses.Window;
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

  PROCEDURE (p : DisplayPrefs) Init*;

    (**
      Initializes an instance.
    *)

  VAR
    x : LONGINT;

  BEGIN
    p.Init^;

    IF D.display.colorMode=D.monochromeMode THEN
      p.colors[D.backgroundColorIndex]:=background;
      p.colors[D.tableBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.tableBackground2ColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.tableTextColorIndex]:=foreground;
      p.colors[D.textBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.buttonBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.textColorIndex]:=foreground;
      p.colors[D.shineColorIndex]:=foreground;
      p.colors[D.halfShineColorIndex]:=p.colors[D.shineColorIndex];
      p.colors[D.halfShadowColorIndex]:=p.colors[D.shineColorIndex];
      p.colors[D.shadowColorIndex]:=p.colors[D.shineColorIndex];
      p.colors[D.fillColorIndex]:=foreground;
      p.colors[D.fillTextColorIndex]:=background;
      p.colors[D.warnColorIndex]:=p.colors[D.textColorIndex];
      p.colors[D.disabledColorIndex]:=background;
      p.colors[D.focusColorIndex]:=p.colors[D.textColorIndex];
      p.colors[D.blackColorIndex]:=background;
      p.colors[D.whiteColorIndex]:=foreground;
      p.colors[D.helpBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
    ELSE
      p.colors[D.backgroundColorIndex]:="black";
      p.colors[D.tableBackgroundColorIndex]:="black";
      p.colors[D.tableBackground2ColorIndex]:=p.colors[D.tableBackgroundColorIndex];
      p.colors[D.tableTextColorIndex]:="white";
      p.colors[D.textBackgroundColorIndex]:=p.colors[D.backgroundColorIndex];
      p.colors[D.buttonBackgroundColorIndex]:="black";
      p.colors[D.textColorIndex]:="white";
      p.colors[D.shineColorIndex]:="white";
      p.colors[D.halfShineColorIndex]:=p.colors[D.shineColorIndex];
      p.colors[D.halfShadowColorIndex]:=p.colors[D.shineColorIndex];
      p.colors[D.shadowColorIndex]:=p.colors[D.shineColorIndex];
      p.colors[D.fillColorIndex]:="white";
      p.colors[D.fillTextColorIndex]:="black";
      p.colors[D.warnColorIndex]:="white";
      p.colors[D.disabledColorIndex]:="black";
      p.colors[D.focusColorIndex]:="white";
      p.colors[D.blackColorIndex]:="black";
      p.colors[D.whiteColorIndex]:="white";
      p.colors[D.helpBackgroundColorIndex]:="black";
    END;

    p.localeCodecFactory:=Codec.GetFactory("ISO-8859-1");
    p.localeCodec:=p.localeCodecFactory.NewCodec();

    FOR x:=0 TO D.fontCount-1 DO
      p.fonts[x]:=factory.CreateFont();

      p.fonts[x].name:=NIL;
      p.fonts[x].features:={D.fontHeight};
      p.fonts[x].pixelHeight:=1;
    END;

    (*p.contextTimer:=2500*)
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
    font.height:=1;
    font.descent:=1;
    font.ascent:=0;
  END Init;

  PROCEDURE (font : Font) Load*():D.Font;

  BEGIN
    RETURN NIL;
  END Load;

  PROCEDURE (font : Font) TextWidth*(text : ARRAY OF CHAR; length : LONGINT; style : SET):LONGINT;

  BEGIN
    RETURN length;
  END TextWidth;

  PROCEDURE (font : Font) LongTextWidth*(text : ARRAY OF LONGCHAR; length : LONGINT; style : SET):LONGINT;

  BEGIN
    RETURN length;
  END LongTextWidth;

  PROCEDURE (font : Font) StrWidth*(text : STRING; style : SET):LONGINT;

  BEGIN
    RETURN text.length;
  END StrWidth;

  PROCEDURE (font : Font) TextExtent*(text : ARRAY OF CHAR;
                                      length : LONGINT; style : SET;
                                    VAR extent : D.FontExtentDesc);

  BEGIN
    extent.lbearing:=0;
    extent.rbearing:=length;
    extent.width:=length;
    extent.ascent:=0;
    extent.descent:=1;
    extent.height:=1;
  END TextExtent;

  PROCEDURE (font : Font) LongTextExtent*(text : ARRAY OF LONGCHAR;
                                          length : LONGINT; style : SET;
                                          VAR extent : D.FontExtentDesc);

  BEGIN
    extent.lbearing:=0;
    extent.rbearing:=length;
    extent.width:=length;
    extent.ascent:=0;
    extent.descent:=1;
    extent.height:=1;
  END LongTextExtent;

  PROCEDURE (font : Font) StrExtent*(text : STRING;
                                     style : SET;
                                     VAR extent : D.FontExtentDesc);

  BEGIN
    extent.lbearing:=0;
    extent.rbearing:=text.length;
    extent.width:=text.length;
    extent.ascent:=0;
    extent.descent:=1;
    extent.height:=1;
  END StrExtent;

  PROCEDURE (font : Font) Free*;

  BEGIN
  END Free;

  (* -------- drawinfo stuff ------------- *)

  PROCEDURE (d : DrawInfo) DrawChar(x,y : LONGINT; char : CHAR);

  BEGIN
    IF (y>=0) & (y<d.window.height) &
      (x>=0) & (x<d.window.width) &
      d.clipRegion[y*d.window.width+x] THEN
      d.window.window.MoveAddChar(x,y,char);
    END;
  END DrawChar;

  (* ----------- Clipping ---------------- *)

  PROCEDURE (d : DrawInfo) RecalcClipRegion;
    (**
      Recalces the current clipping regions by analysing the
      current clipping stack.
    *)

  VAR
    pos    : LONGINT;
    region : ClipRegion;
    i      : LONGINT;

  BEGIN
    NEW(region,d.window.width*d.window.height);

    FOR i:=0 TO LEN(region^)-1 DO
      region[i]:=d.clipStack[d.clipPos].region[i];
    END;

    pos:=d.clipPos-1;
    WHILE pos>=0 DO

      FOR i:=0 TO LEN(region^)-1 DO
        IF ~d.clipStack[pos].region[i] THEN
          region[i]:=FALSE;
        END;
      END;

      DEC(pos);
    END;

    d.clipRegion:=region;
  END RecalcClipRegion;

  PROCEDURE (VAR c : ClipEntryDesc) Init(draw : DrawInfo);
  (**
    Initializes a clip entry object.
  *)

  VAR
    i : LONGINT;

  BEGIN
    c.draw:=draw;

    NEW(c.region,c.draw.window.width*c.draw.window.height);
    FOR i:=0 TO LEN(c.region^)-1 DO
      c.region[i]:=FALSE;
    END;
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
    i,j : LONGINT;

  BEGIN
    FOR i:=x TO x+width-1 DO
      FOR j:=y TO y+height-1 DO
        c.region[j*c.draw.window.width+i]:=TRUE;
      END;
    END;

    c.draw.RecalcClipRegion;
  END Add;

  PROCEDURE (VAR c : ClipEntryDesc) Sub(x,y,width,height : LONGINT);
  (**
    adds the given rectangle to the current clip entry.
  *)

  VAR
    i,j : LONGINT;

  BEGIN
    FOR i:=x TO x+width-1 DO
      FOR j:=y TO y+height-1 DO
        c.region[j*c.draw.window.width+i]:=FALSE;
      END;
    END;

    c.draw.RecalcClipRegion;
  END Sub;

  PROCEDURE (VAR c : ClipEntryDesc) Free;
  (**
    Frees the given clip entry.
  *)

  BEGIN
    c.region:=NIL;
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
    d.clipRegion:=d.clipStack[0].region;
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

  PROCEDURE (d : DrawInfo) Init(window : Window);
  (**
    Initialize an instance of the  DrawInfo class.
  *)

  BEGIN
    d.window:=window;
    d.clipRegion:=NIL;

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
    d.dashStack:=NIL;
    d.patternStack:=NIL;
    d.modeStack:=NIL;

    d.PushBackground(D.backgroundColor);
  END Init;

  PROCEDURE (d : DrawInfo) Deinit;
  (**
    Deinitializes the drawInfo
  *)

  BEGIN
    d.PopBackground;

    ASSERT(d.fPenPos=-1);
    ASSERT(d.bPenPos=-1);
    ASSERT(d.fontPos=-1);
    ASSERT(d.dashStack=NIL);
    ASSERT(d.clipPos=-1);
    ASSERT(d.patternStack=NIL);
    ASSERT(d.modeStack=NIL);
  END Deinit;

  PROCEDURE (d : DrawInfo) ResetMode;

  VAR
    style : SET;
    fg,
    bg    : LONGINT;

  BEGIN
    IF (d.fPenPos>=0) THEN
      fg:=d.fPenStack[d.fPenPos].color;
    ELSE
      fg:=D.textColor;
    END;

    IF (d.bPenPos>=0) THEN
      bg:=d.bPenStack[d.bPenPos].color;
    ELSE
      bg:=D.backgroundColor;
    END;

    style:={Curses.normalStyle};
    IF d.fontPos>=0 THEN
      IF D.underlined IN d.fontStack[d.fontPos].style THEN
        style:={Curses.underlineStyle};
      ELSIF D.bold IN d.fontStack[d.fontPos].style THEN
        style:={Curses.boldStyle};
      ELSIF D.italic IN d.fontStack[d.fontPos].style THEN
        style:={Curses.standoutStyle};
      END;
    END;

    IF D.display.colorMode=D.monochromeMode THEN
      IF (fg=D.textColor) & (bg=D.textColor) THEN
        INCL(style,Curses.reverseStyle);
        d.window.window.SetMode(style,fg); (* Hmmm *)
      ELSIF (fg=D.textColor) & (bg=D.backgroundColor) THEN
        d.window.window.SetMode(style,fg);
      ELSIF (fg=D.backgroundColor) & (bg=D.textColor) THEN
        INCL(style,Curses.reverseStyle);
        d.window.window.SetMode(style,fg);
      ELSE
        (* Hmmm *)
        d.window.window.SetMode(style,fg);
      END;
    ELSE
      d.window.window.SetMode(style,fg+bg*(D.display.colorDepth*2));
    END;
  END ResetMode;

  PROCEDURE (d : DrawInfo) GetForeground(attr : SET; color : LONGINT):LONGINT;

  BEGIN
    IF Curses.reverseStyle IN attr THEN
      RETURN color DIV (D.display.colorDepth*2);
    ELSE
      RETURN color MOD (D.display.colorDepth*2);
    END;
  END GetForeground;

  PROCEDURE (d : DrawInfo) GetBackground(attr : SET; color : LONGINT):LONGINT;

  BEGIN
    IF Curses.reverseStyle IN attr THEN
      RETURN color MOD (D.display.colorDepth*2);
    ELSE
      RETURN color DIV (D.display.colorDepth*2);
    END;
  END GetBackground;

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

      d.ResetMode;
    END;
  END PushFont;

  PROCEDURE (d : DrawInfo) PopFont*;

  BEGIN
    IF d.fontStack[d.fontPos].count>1 THEN
      DEC(d.fontStack[d.fontPos].count);
    ELSE
      DEC(d.fontPos);

      d.ResetMode;
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
    i     : LONGINT;
    color : LONGINT;
    char  : CHAR;
    attr  : SET;

  BEGIN
    FOR i:=0 TO length-1 DO
      d.window.window.Move(x+i,y);
      d.window.window.ReadChar(char,attr,color);
      d.PushBackground(d.GetBackground(attr,color));

      IF ORD(text[i])<256 THEN
        d.DrawChar(x+i,y,CHR(ORD(text[i])));
      ELSE
        d.DrawChar(x+i,y,"?");
      END;

      d.PopBackground;
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

  VAR
    i : LONGINT;

  BEGIN
    FOR i:=0 TO length-1 DO
      IF ORD(text[i])<256 THEN
        d.DrawChar(x+i,y,CHR(ORD(text[i])));
      ELSE
        d.DrawChar(x+i,y,"?");
      END;
    END;
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

      d.ResetMode;
    END;
  END PushForeground;

  PROCEDURE (d : DrawInfo) PopForeground*;

  BEGIN
    IF d.fPenStack[d.fPenPos].count>1 THEN
      DEC(d.fPenStack[d.fPenPos].count);
    ELSE
      DEC(d.fPenPos);

      d.ResetMode;
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

      d.ResetMode;
    END;
  END PushBackground;

  PROCEDURE (d : DrawInfo) PopBackground*;

  BEGIN
    IF d.bPenStack[d.bPenPos].count>1 THEN
      DEC(d.bPenStack[d.bPenPos].count);
    ELSE
      DEC(d.bPenPos);

      d.ResetMode;
    END;
  END PopBackground;

  PROCEDURE (d : DrawInfo) PushStyle*(size, mode : LONGINT);

  BEGIN
    (* not supported *)
  END PushStyle;

  PROCEDURE (d : DrawInfo) PopStyle*;

  BEGIN
    (* not supported *)
  END PopStyle;

  PROCEDURE (d : DrawInfo) PushDash*(dashList : ARRAY OF CHAR; mode : LONGINT);

(*  VAR
    dash   : PenDash;
    size,
    cap,
    join,x : LONGINT;*)

  BEGIN
(*    NEW(dash);
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
    d.dashStack:=dash;*)
  END PushDash;

  PROCEDURE (d : DrawInfo) PopDash*;

(*  VAR
    size,
    cap,
    join : LONGINT;*)

  BEGIN
(*    d.dashStack:=d.dashStack.next;

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
    END;*)
  END PopDash;

  PROCEDURE (d : DrawInfo) PushPattern*(pattern : ARRAY OF CHAR; width, height : LONGINT; mode : LONGINT);

  VAR
    pat : Pattern;
    x   : LONGINT;

  BEGIN
    NEW(pat);
    pat.width:=width;
    pat.height:=height;
    NEW(pat.pattern,width*height);
    FOR x:=0 TO width*height-1 DO
      pat.pattern[x]:=pattern[x];
    END;
    pat.mode:=mode;

    pat.next:=d.patternStack;
    d.patternStack:=pat;
  END PushPattern;

  PROCEDURE (d : DrawInfo) PopPattern*;

  BEGIN
    d.patternStack:=d.patternStack.next;
  END PopPattern;

  PROCEDURE (d : DrawInfo) PushBitmap*(bitmap : D.Bitmap; mode : LONGINT);

(*  VAR
    pat : Pattern;*)

  BEGIN
(*    NEW(pat);
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
    d.patternStack:=pat;*)
  END PushBitmap;

  PROCEDURE (d : DrawInfo) PopBitmap*;

  BEGIN
(*    d.patternStack:=d.patternStack.next;
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
    END;*)
  END PopBitmap;

  (* Drawing functions *)

  PROCEDURE (d : DrawInfo) DrawPoint*(x,y : LONGINT);

  BEGIN
    d.PushBackground(d.fPenStack[d.fPenPos].color);

    d.DrawChar(x,y," ");

    d.PopBackground;
  END DrawPoint;

  PROCEDURE (d : DrawInfo) DrawLine*(x1,y1,x2,y2 : LONGINT);

  VAR
    i : LONGINT;

  BEGIN
    d.PushBackground(d.fPenStack[d.fPenPos].color);

    IF y1=y2 THEN (* horizontal line *)
      IF x1<=x2 THEN
        FOR i:=x1 TO x2 DO
          d.DrawChar(i,y1," ");
        END;
      ELSE
        FOR i:=x2 TO x1 DO
          d.DrawChar(i,y1," ");
        END;
      END;
    ELSIF x1=x2 THEN (* vertical line *)
      IF y1<=y2 THEN
        FOR i:=y1 TO y2 DO
          d.DrawChar(x1,i," ");
        END;
      ELSE
        FOR i:=y2 TO y1 DO
          d.DrawChar(x1,i," ");
        END;
      END;
    ELSE
      (* TODO *)
    END;

    d.PopBackground;
  END DrawLine;

  PROCEDURE (d : DrawInfo) DrawRectangle*(x,y,width,height : LONGINT);

  VAR
    i     : LONGINT;
    attr  : SET;
    color : LONGINT;
    char  : CHAR;

  BEGIN
    d.DrawChar(x,y,Curses.boxTL);
    d.window.window.Move(x,y);
    d.window.window.ReadChar(char,attr,color);
    INCL(attr,Curses.altCharStyle);
    d.window.window.SetMode(attr,color);

    (* Draw corners *)
    d.DrawChar(x,y,Curses.boxTL);
    d.DrawChar(x+width-1,y,Curses.boxTR);
    d.DrawChar(x,y+height-1,Curses.boxBL);
    d.DrawChar(x+width-1,y+height-1,Curses.boxBR);

    FOR i:=y+1 TO y+height-2 DO
      d.DrawChar(x,i,Curses.vLine);
    END;

    FOR i:=x+1 TO x+width-2 DO
      d.DrawChar(i,y,Curses.hLine);
    END;

    FOR i:=y+1 TO y+height-2 DO
      d.DrawChar(x+width-1,i,Curses.vLine);
    END;

    FOR i:=x+1 TO x+width-2 DO
      d.DrawChar(i,y+height-1,Curses.hLine);
    END;
  END DrawRectangle;

  PROCEDURE (d : DrawInfo) FillRectangle*(x,y,width,height : LONGINT);

  VAR
    i,j : LONGINT;

  BEGIN
    d.PushBackground(d.fPenStack[d.fPenPos].color);

    IF d.patternStack#NIL THEN
      FOR j:=y TO y+height-1 DO
        FOR i:=x TO x+width-1 DO
          d.DrawChar(i,j,d.patternStack.pattern[0]);
        END;
      END;
    ELSE
      FOR j:=y TO y+height-1 DO
        FOR i:=x TO x+width-1 DO
          d.DrawChar(i,j," ");
        END;
      END;
    END;

    d.PopBackground;
  END FillRectangle;

  PROCEDURE (d : DrawInfo) FillRectangleAlpha*(alpha : LONGINT; x,y,width,height : LONGINT);

  BEGIN
    d.FillRectangle(x,y,width,height);
  END FillRectangleAlpha;

  PROCEDURE (d : DrawInfo) InvertRectangle*(x,y,width,height : LONGINT);

  VAR
    i,j   : LONGINT;
    color : LONGINT;
    char  : CHAR;
    attr  : SET;
    fg,bg : LONGINT;

  BEGIN
    FOR j:=y TO y+height-1 DO
      FOR i:=x TO x+width-1 DO
        d.window.window.Move(i,j);
        d.window.window.ReadChar(char,attr,color);
        fg:=d.GetForeground(attr,color);
        bg:=d.GetBackground(attr,color);
        d.PushForeground(bg);
        d.PushBackground(fg);
        d.DrawChar(i,j,char);
        d.PopBackground;
        d.PopForeground;
      END;
    END;

    d.ResetMode;
  END InvertRectangle;

  PROCEDURE (d : DrawInfo) DrawArc*(x,y,width,height,angle1,angle2 : LONGINT);

  BEGIN
(*    X11.XDrawArc(D.display(Display).display,d.window,d.gc,x,y,width-1,height-1,angle1,angle2);*)
  END DrawArc;

  PROCEDURE (d : DrawInfo) FillArc*(x,y,width,height,angle1,angle2 : LONGINT);

  BEGIN
(*    X11.XFillArc(D.display(Display).display,d.window,d.gc,x,y,width,height,angle1,angle2);*)
  END FillArc;

  PROCEDURE (d : DrawInfo) FillPolygon*(points : ARRAY OF D.PointDesc;
                                        count : LONGINT);

  BEGIN
(*    (*D.display(Display).EnlargePointArray(count);*)
    FOR x:=0 TO count-1 DO
      D.display(Display).pointArray[x].x:=SHORT(points[x].x);
      D.display(Display).pointArray[x].y:=SHORT(points[x].y);
    END;
    (*    X11.XFillPolygon(D.display(Display).display,d.window,d.gc,D.display(Display).pointArray^,count,X11.Complex,X11.CoordModeOrigin);*)
    X11.XFillPolygon(D.display(Display).display,d.window,d.gc,D.display(Display).pointArray,count,X11.Complex,X11.CoordModeOrigin);*)
  END FillPolygon;

  PROCEDURE (d : DrawInfo) CopyArea*(sX,sY,width,height,dX,dY : LONGINT);

  TYPE
    PointDesc = RECORD
                  char  : CHAR;
                  style : SET;
                  color : LONGINT;
                END;

  VAR
    buffer : POINTER TO ARRAY OF PointDesc;
    i,j,k  : LONGINT;

  BEGIN
    NEW(buffer,width*height);

    i:=0;
    FOR j:=sY TO sY+height-1 DO
      FOR k:=sX TO sX+width-1 DO
        d.window.window.Move(k,j);
        d.window.window.ReadChar(buffer[i].char,buffer[i].style,buffer[i].color);
        INC(i);
      END;
    END;

    i:=0;
    FOR j:=dY TO dY+height-1 DO
      FOR k:=dX TO dX+width-1 DO
        d.window.window.SetMode(buffer[i].style,buffer[i].color);
        d.DrawChar(k,j,buffer[i].char);
        INC(i);
      END;
    END;

    d.ResetMode;
  END CopyArea;

  PROCEDURE (d : DrawInfo) CopyFromBitmap*(bitmap : D.Bitmap;
                                               sX,sY,width,height,dX,dY : LONGINT);

  BEGIN
(*    X11.XCopyArea(D.display(Display).display,
                  bitmap(Bitmap).pixmap,
                  d.window,
                  d.gc,
                  sX,sY,width,height,dX,dY);*)
  END CopyFromBitmap;

  PROCEDURE (d : DrawInfo) CopyToBitmap*(sX,sY,width,height,dX,dY : LONGINT;
                                             bitmap : D.Bitmap);

  BEGIN
(*    X11.XSetGraphicsExposures(D.display(Display).display,d.gc,X11.True);
    X11.XCopyArea(D.display(Display).display,
                  bitmap(Bitmap).pixmap,d.window,d.gc,
                  sX,sY,width,height,dX,dY);
    X11.XSetGraphicsExposures(D.display(Display).display,d.gc,X11.False);*)
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

  PROCEDURE (d : Display) GetFontList*():D.FontList;

  BEGIN
    RETURN NIL;
  END GetFontList;

  (* -------- color stuff of D.display ------------- *)

  PROCEDURE (d : Display) AllocateColor8*(r,g,b : SHORTINT;
                                          default : D.Color;
                                          VAR color : D.Color);

  BEGIN
    color:=default;
  END AllocateColor8;

  PROCEDURE (d : Display) AllocateColor16*(r,g,b : INTEGER;
                                           default : D.Color;
                                          VAR color : D.Color);

  BEGIN
    color:=default;
  END AllocateColor16;

  PROCEDURE (d : Display) AllocateColor32*(r,g,b : LONGINT;
                                           default : D.Color;
                                           VAR color : D.Color);

  BEGIN
    color:=default;
  END AllocateColor32;

  PROCEDURE (d : Display) AllocateNamedColor*(name : ARRAY OF CHAR;
                                              default : D.Color;
                                              VAR color : D.Color);

  BEGIN
    IF D.display.colorMode=D.monochromeMode THEN
      IF name="black" THEN
        color:=Curses.colorBlack;
      ELSIF name="white" THEN
        color:=Curses.colorWhite;
      ELSE
        color:=default;
      END;
    ELSE
      IF name="black" THEN
        color:=Curses.colorBlack;
      ELSIF name="red" THEN
        color:=Curses.colorRed;
      ELSIF name="green" THEN
        color:=Curses.colorGreen;
      ELSIF name="yellow" THEN
        color:=Curses.colorYellow;
      ELSIF name="blue" THEN
        color:=Curses.colorBlue;
      ELSIF name="magenta" THEN
        color:=Curses.colorMagenta;
      ELSIF name="cyan" THEN
        color:=Curses.colorCyan;
      ELSIF name="white" THEN
        color:=Curses.colorWhite;
      ELSE
        color:=default;
      END;
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

  BEGIN
    RETURN NIL;
(*    bitmap:=factory.CreateBitmap();
    bitmap(Bitmap).pixmap:=X11.XCreatePixmap(d.display,
                                             X11.XDefaultRootWindow(d.display),
                                             width,
                                             height,d.colorDepth);

    IF bitmap(Bitmap).pixmap=0 THEN
      RETURN NIL;
    END;

    bitmap.draw:=factory.CreateDrawInfo();
    bitmap.draw(DrawInfo).Init(bitmap(Bitmap).pixmap);

    bitmap.width:=width;
    bitmap.height:=height;
*)
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
(*    X11.XFreePixmap(d.display,bitmap(Bitmap).pixmap);*)
  END FreeBitmap;

  PROCEDURE (d : Display) Open*():BOOLEAN;

  VAR
    i          : LONGINT;
    fg,bg      : C.shortint;
    prefs      : DisplayPrefs;
    name       : STRING;
    tmp        : Object.CharsLatin1;
    colors     : ARRAY D.colorCount OF D.Color;

  BEGIN
    d.driverName:=driverName;

    d.top:=Curses.Open();

    IF d.top=NIL THEN
      Err.String("Cannot open terminal"); Err.Ln;
      RETURN FALSE;
    END;

    d.colorDepth:=1;
    d.colorMode:=D.monochromeMode;

    IF Curses.HasColors() THEN
      Curses.EnableColors;
      IF Curses.GetColorPairCount()>=64 THEN
        d.colorMode:=D.colorMode;
        d.colorDepth:=4;
      END;
    END;

    Curses.ShowCursor(FALSE);
    Curses.SetEcho(FALSE);
    Curses.SetCBreak(TRUE);
    (*Curses.SetRaw(TRUE);*)
    Curses.SetNl(FALSE);

(*
    Image.factory.Init(d);
*)
    Curses.GetSize(d.scrWidth,d.scrHeight);

    d.displayType:=D.displayTypeTextual;

    IF d.scrWidth<=640 THEN
      d.displaySize:=D.displaySizeTiny;
    ELSIF d.scrWidth<1024 THEN
      d.displaySize:=D.displaySizeSmall;
    ELSIF d.scrWidth<1280 THEN
      d.displaySize:=D.displaySizeNormal;
    ELSE
      d.displaySize:=D.displaySizeHuge;
    END;

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
      D.prefsCallback.ReadDisplayTheme;
    END;

    FOR fg:=0 TO 7 DO (* Foreground *)
      FOR bg:=0 TO 7 DO (* Background *)
        Curses.SetColorPair(SHORT((D.display.colorDepth*2))*bg+fg,fg,bg);
      END;
    END;

    i:=0;
    FOR i:=0 TO D.colorCount-1 DO
      d.AllocateNamedColor(D.prefs.colors[i],Curses.colorWhite,colors[i]);
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

    d.spaceHeight:=1;
    d.spaceWidth:=1;

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
(*    d.selClearPend:=FALSE;

    d.dragging:=FALSE;
    d.dragObject:=NIL;
*)
    d.multiClickTime:=2;

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

    d.windowStack:=NEW(ArrayList.ArrayList(Window),100);

    RETURN TRUE;
  END Open;

  PROCEDURE (d : Display) SetMultiClickTime*(t : LONGINT);
  BEGIN
    IF t>0 THEN d.multiClickTime:=t END;
  END SetMultiClickTime;

  PROCEDURE (d : Display) Beep*;

  BEGIN
    Curses.Beep;
    Curses.Flash;
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
    d.exit:=TRUE;
  END Exit;

  PROCEDURE (d : Display) ReinitWindows*;

  VAR
    x   : LONGINT;
    win : Window;

  BEGIN
    FOR x:=0 TO d.windowStack.size-1 DO
      win:=d.windowStack.Get(x);
      win.interface.ReinitWindow;
    END;
  END ReinitWindows;

  PROCEDURE (d : Display) Close*;

  VAR
    w : Window;
    x : LONGINT;

  BEGIN
    d.selector.Close;

    FOR x:=0 TO d.windowStack.size-1 DO
      w:=d.windowStack.Get(x);
(*
      Err.String("Warning: window ");
      IF w.title#NIL THEN
        Err.String(w.title^);
      END;
      Err.String(" not explicitely closed"); Err.Ln;
*)
      w.interface.Close;
    END;

    (* Freeing all preferences *)
    P.Free;

    (* No need to free colors *)
    (* No need to free fonts *)

(*
<* IF USE_VO_IMAGE=TRUE THEN *>
    Image.factory.Deinit(d);
<* END *>
*)
    d.top.Close;
    Curses.Close;
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

  PROCEDURE (w : Window) HandleEvent*(event : E.Event):BOOLEAN;

  BEGIN
    RETURN FALSE;
  END HandleEvent;

  PROCEDURE (d : Display) GetEvent;

  VAR
    e     : Curses.Event;
    event : E.Event;
    meta,
    click : BOOLEAN;
    char  : CHAR;
    sec,
    usec  : LONGINT;

  BEGIN
    ASSERT(d.currentWin#NIL);

    meta:=FALSE;
    e:=d.currentWin.window.GetEvent();
    IF d.currentWin.window.IsKeyEvent(e) THEN
      d.currentWin.window.ConvertToKeyEvent(e,char);
      IF char=Ascii.esc THEN
        meta:=TRUE;
        e:=d.currentWin.window.GetEvent();
      END;
    END;

(*    IF d.contextTimer.active THEN
      IF (e.type=X11.ButtonPress) OR (e.type=X11.ButtonRelease) OR (e.type=X11.MotionNotify) OR
        (e.type=X11.KeyPress) OR (e.type=X11.KeyRelease) THEN
        d.RemoveTimer(d.contextTimer);
        IF d.contextHelp THEN
          d.AddTimer(d.contextTimer);
        END;
      END;
    END;
*)

    IF d.currentWin#NIL THEN

      click:=FALSE;
      event:=EO.GetEvent(e,d.currentWin.window,meta);

      WITH
        event : E.KeyEvent DO
      | event : E.ButtonEvent DO
        DEC(event.x,d.currentWin.x);
        DEC(event.y,d.currentWin.y);

        IF event.type<0 THEN
          click:=TRUE;
          event.type:=E.mouseDown;
        END;

        IF event.type=E.mouseDown THEN
          d.currentWin.oldButton:=d.currentWin.lastButton;
          d.currentWin.oldPress:=d.currentWin.lastPress;
          d.currentWin.lastButton:=d.currentWin.thisButton;
          d.currentWin.lastPress:=d.currentWin.thisPress;
          d.currentWin.thisButton:=event(EO.ButtonEvent)^;

          IF sc.GetTimeOfDay(sec,usec)=0 THEN
            d.currentWin.thisPress:=sec;
          ELSE
            INC(d.currentWin.thisPress);
          END;
        END;

      ELSE
      END;

      WHILE event#NIL DO

        (* Event loop *)
        REPEAT
          event.reUse:=FALSE;
          IF ~d.currentWin.HandleEvent(event) THEN
            IF d.currentWin.interface.HandleEvent(event) THEN END;
          END;
        UNTIL (event.reUse=FALSE) OR (d.currentWin=NIL);

        WITH
          event : E.KeyEvent DO
          IF event.type=E.keyDown THEN
            (* Generate a fake key up event *)
            event.type:=E.keyUp;
          ELSE
            event:=NIL;
          END;
        | event : E.ButtonEvent DO
          IF click THEN
            (* Generate a fake mouse up event *)
            event.type:=E.mouseUp;
            click:=FALSE;
          ELSE
            event:=NIL;
          END;

        ELSE
          event:=NIL;
        END;

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

  PROCEDURE (d : Display) RefreshWindows;

  VAR
    x : LONGINT;
    w : Window;

  BEGIN
    FOR x:=0 TO d.windowStack.size-1 DO
      w:=d.windowStack.Get(x);
      IF w.frame#NIL THEN
        w.frame.Refresh;
      END;
      w.window.Refresh;
    END;

    Curses.Update;
  END RefreshWindows;

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
      d.CheckSleeps;

      IF ~d.Wait() THEN
        d.GetEvent;
      END;

      d.CheckTimers;

      d.RefreshWindows;

      IF d.exit THEN
        EXIT;
      END;
    END;
  END EventLoop;

  PROCEDURE (w : Window) Init*;

  BEGIN
    w.Init^;

    w.grab:=FALSE;
    w.exit:=TRUE;

    w.oldPress:=0;
    w.lastPress:=0;
    w.thisPress:=0;

    w.frame:=NIL;
    w.window:=NIL;
  END Init;

  PROCEDURE (w : Window) SetTitle*(name : STRING);

  VAR
    x     : LONGINT;
    tmp   : U.Text;
    tmp1  : Object.CharsLatin1;
    title : STRING;

  BEGIN
    w.SetTitle^(name);

    IF w.IsOpen() & (w.frame#NIL) THEN

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
        tmp1:=title.CharsLatin1();
        NEW(tmp,title.length+1);
        COPY(tmp1^,tmp^);
      | title : Object.String16 DO
        (* This is a hack! *)
        NEW(tmp,title.length+1);
        FOR x:=0 TO title.length-1 DO
          tmp[x]:=CHR(ORD(title.CharAt(x)));
        END;
        tmp[x]:=0X;
      ELSE
        NEW(tmp,1);
        tmp[0]:=0X;
      END;

      w.frame.MoveAddChar(1,0," ");
      w.frame.AddString(tmp^);
      w.frame.AddChar(" ");
      w.frame.Refresh;
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

  BEGIN
    D.display(Display).StopContextHelp;
    (* TODO *)
  END GrabOn;

  PROCEDURE (w : Window) GrabOff;
  (**
    Releases the grab of the mouse cursor and the keyboard.
  *)

  BEGIN
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
    draw : D.DrawInfo;

  BEGIN
    (* Non-modal windows are not allowed! *)
    ASSERT((w.parent#NIL) OR (D.display(Display).windowStack.size=0));

    IF ~w.Open^() THEN
      RETURN FALSE;
    END;

    IF w.type=D.windowTypeMain THEN
      (* Resize the window to the maximum *)
      w.width:=U.MinLong(w.maxWidth,D.display.scrWidth);
      w.height:=U.MinLong(w.maxHeight,D.display.scrHeight);
      w.interface.OnResized(w.width,w.height);
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

    NEW(w.frame);
    IF w.frame.Open(w.x-1,w.y-1,w.width+2,w.height+2) THEN
      w.frame.SetBackground(D.backgroundColor," ");
      w.frame.Border;
    ELSE
      w.frame:=NIL;
    END;

    NEW(w.window);
    IF w.window.Open(w.x,w.y,w.width,w.height) THEN
      w.window.SetDelay(FALSE);
      w.window.SetMeta(TRUE);
      w.window.SetKeyPad(TRUE);
      w.window.SetScrollLock(FALSE);
      w.window.SetBackground(D.backgroundColor," ");
      w.window.Clear;
    ELSE
      IF w.frame#NIL THEN
        w.frame.Close;
      END;
      RETURN FALSE;
    END;

    draw:=factory.CreateDrawInfo();
    w.draw:=draw(DrawInfo);
    w.draw.Init(w);

(*    w.draw.InstallClip(0,0,D.display.scrWidth,D.display.scrHeight);*)
    w.draw.InstallClip(0,0,w.width,w.height);

    D.display(Display).windowStack.Append(w);

    (* Sending initial refresh event *)
    w.window.SetBackground(D.backgroundColor," ");
    w.window.Clear;
    w.interface.OnMaped();
    w.interface.OnRedraw(0,0,w.width,w.height);
    w.interface.OnFocusIn();

    w.SetTitle(w.GetTitle());

    D.display(Display).RefreshWindows;

    D.display(Display).currentWin:=w;

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

    w.Close^;

    IF w.IsOpen() & (w.window#NIL) THEN
      w.draw.FreeLastClip;
      w.draw.Deinit;
      w.window.Close;
      w.window:=NIL;
      IF w.frame#NIL THEN
        w.frame.Close;
        w.frame:=NIL;
      END;

      w.interface.OnFocusOut;
      w.interface.OnUnmaped;
    END;

    D.display(Display).windowStack.Remove(D.display(Display).windowStack.size-1);

    IF w.parent#NIL THEN
      D.display(Display).currentWin:=w.parent(Window);

      D.display(Display).currentWin.interface.OnFocusIn;
      (* For some reason Curses does not refresh the parent window *)
      D.display(Display).currentWin.interface.OnRedraw(0,0,
                                                       D.display(Display).currentWin.width,
                                                       D.display(Display).currentWin.height);
    ELSE
      D.display(Display).currentWin:=NIL;
    END;

    D.display(Display).RefreshWindows;
  END Close;

  PROCEDURE (w : Window) GetMousePos*(VAR rx, ry, wx, wy : LONGINT);

(*  VAR
    root,
    child  : X11.Window;
    bmask  : X11.ulongmask;*)

  BEGIN
(*    IF X11.XQueryPointer(D.display(Display).display,w.window,root,child,rx,ry,wx,wy,bmask)=X11.False THEN
      Err.String("Can't get cursorpos"); Err.Ln;
    END;*)
  END GetMousePos;

  PROCEDURE (w : Window) EventLoop*;

  BEGIN
    ASSERT(w.exit);

    w.exit:=FALSE;

    w.DisableParents;

    LOOP
      D.display(Display).CheckSleeps;

      IF ~D.display(Display).Wait() THEN
        D.display(Display).GetEvent;
      END;

      D.display(Display).CheckTimers;

      D.display(Display).RefreshWindows;

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
          & (w.lastPress - w.thisPress <= D.display(Display).multiClickTime);
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

END VO:OS:Curses:Display.