MODULE VO:Button;

  (**
    Implements @otype{Button}.
  *)

  (*
    Implements a button.
    Copyright (C) 1997 Tim Teulings (rael@edge.ping.de)

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

IMPORT BG  := VO:Base:Background,
       D   := VO:Base:Display,
       E   := VO:Base:Event,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,
       Z   := VO:Base:Size,

       G   := VO:Object,
       T   := VO:Text,
       W   := VO:Window,

              Object;


CONST
  (* Types *)

  normal  * = 0; (** normal button *)
  small   * = 1; (** a smaller button to be used for example as part of a scroll bar *)
  image   * = 2; (** A button that holds a n image. *)
  toolBar * = 3; (** a tool bar button *)

  (* short cut modes *)

  none*    = 0;
  return*  = 1;
  escape*  = 2;
  default* = 3;

  (* actions *)

  pressedMsg * = 0; (** The constant for the PressedMsg.
                       A PressedMsg will be generated everytime
                       our button gets pressed.
                     *)

  repeatTimer = 50; (** Time between button repeat *)

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 bgReturn*,
                 bgDefault*,
                 bgEscape*    : G.Background;
                 hSpace*,
                 vSpace*      : Z.SizeDesc;
                 returnFrame*,
                 defaultFrame*,
                 escapeFrame*,
                 sFrame*,
                 iFrame*,
                 tFrame*      : F.Frame; (** the frame to use for the button *)
                 gridDisable* : BOOLEAN;
               END;


  Button*     = POINTER TO ButtonDesc;
  ButtonDesc* = RECORD (G.GadgetDesc)
                  (**
                    Implements a powerfull general purpose button class with
                    "action on press" semantic. The button label can either be
                    text or any other class derived from @otype{G.Object}.

                    The button can be on of a number of types that slidly differ
                    in their apearance.

                    Instead of the "one action on press" semantic, it can be
                    configured to retrigger until the button is deselected again.
                  *)
                  image      : G.Object; (** The label of the button *)
                  timer      : D.Timer;  (** @otype{D.Timer}  for pulse-mode *)
                  font       : D.Font;   (** Special font for the button *)
                  type       : LONGINT;  (** Type. *)
                  state,                 (** The state of the button. TRUE when currently selected *)
                  active,
                  pulse      : BOOLEAN;  (** send permanent pressed Msg on ButtonDown and none on ButtonUp *)
                  shortCut   : UCS4CHAR;
                  scMode     : LONGINT;
                  scAssigned : BOOLEAN;
                END;


  (* messages *)

  PressedMsg*     = POINTER TO PressedMsgDesc;
  PressedMsgDesc* = RECORD (O.MessageDesc)
                      (**
                        The PressedMsg generated everytime the button get clicked.
                      *)
                    END;


VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackground();
    p.background(BG.Background).SetFill(BG.normal,BG.CreatePlainFillByColorIndex(D.buttonBackgroundColorIndex));
    p.background(BG.Background).SetFill(BG.selected,BG.CreatePlainFillByColorIndex(D.fillColorIndex));

    IF D.display.displayType=D.displayTypeTextual THEN
      p.bgEscape:=BG.CreateBackground();
      p.bgEscape(BG.Background).SetFill(BG.normal,BG.CreatePlainFillByColorIndex(D.buttonBackgroundColorIndex));
      p.bgEscape(BG.Background).SetFill(BG.selected,BG.CreatePlainFillByColorIndex(D.fillColorIndex));

      p.bgReturn:=BG.CreateBackground();
      p.bgReturn(BG.Background).SetFill(BG.normal,BG.CreatePlainFillByColorIndex(D.buttonBackgroundColorIndex));
      p.bgReturn(BG.Background).SetFill(BG.selected,BG.CreatePlainFillByColorIndex(D.fillColorIndex));

      p.bgDefault:=BG.CreateBackground();
      p.bgDefault(BG.Background).SetFill(BG.normal,BG.CreatePlainFillByColorIndex(D.buttonBackgroundColorIndex));
      p.bgDefault(BG.Background).SetFill(BG.selected,BG.CreatePlainFillByColorIndex(D.fillColorIndex));
    ELSE
      p.bgEscape:=BG.CreateBackground();
      p.bgEscape(BG.Background).SetFill(BG.normal,BG.CreatePlainFillByColorIndex(D.warnColorIndex));
      p.bgEscape(BG.Background).SetFill(BG.selected,BG.CreatePlainFillByColorIndex(D.fillColorIndex));

      p.bgReturn:=BG.CreateBackground();
      p.bgReturn(BG.Background).SetFill(BG.normal,BG.CreatePlainFillByColorIndex(D.fillColorIndex));
      p.bgReturn(BG.Background).SetFill(BG.selected,BG.CreatePlainFillByColorIndex(D.fillColorIndex));

      p.bgDefault:=BG.CreateBackground();
      p.bgDefault(BG.Background).SetFill(BG.normal,BG.CreatePlainFillByColorIndex(D.fillColorIndex));
      p.bgDefault(BG.Background).SetFill(BG.selected,BG.CreatePlainFillByColorIndex(D.fillColorIndex));
    END;

    p.hSpace.Init;
    p.vSpace.Init;
    p.hSpace.SetSize(Z.softUnitP,50);
    p.vSpace.SetSize(Z.softUnitP,50);

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.textButton);
      p.sFrame:=p.frame;
      p.iFrame:=p.frame;
      p.tFrame:=p.frame;
      p.returnFrame:=p.frame;
      p.defaultFrame:=p.frame;
      p.escapeFrame:=p.frame;
    ELSE
      p.frame:=F.CreateFrame(F.double3DOut);
      p.sFrame:=F.CreateFrame(F.single3DOut);
      p.iFrame:=p.frame;
      p.tFrame:=p.frame;
      p.returnFrame:=p.frame;
      p.defaultFrame:=p.frame;
      p.escapeFrame:=p.frame;
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.gridDisable:=FALSE;
    ELSE
      p.gridDisable:=TRUE;
    END;
  END Initialize;

  PROCEDURE (b : Button) Init*;

  BEGIN
    b.Init^;          (* We *must* call Init of our baseclass first *)

    b.SetPrefs(prefs);

    b.timer:=D.factory.CreateTimer();
    b.timer.SetSecs(0,repeatTimer);
    b.timer.SetObject(b);

    b.SetFlags({G.canFocus}); (* We can handle keyboard focus *)
                                         (* We can handle shortcuts *)
    b.type:=normal;   (* Normally we use normal button frames *)
    b.pulse:=FALSE;   (* normaly one pressedMsg on mousebutton up *)
    b.font:=D.normalFont; (* Just the global default font fo the button label *)

    (* There is no default image *)
    b.image:=NIL;

    (* The button is by default unpressed *)
    b.state:=FALSE;
    b.active:=FALSE;

    b.shortCut:=0X;   (* No shortcut key *)
    b.scMode:=none; (* No special key for keyboard shortcut *)
    b.scAssigned:=TRUE;
  END Init;

  PROCEDURE (b : Button) SetFont*(font : D.Font);

  (**
    Set a new font to be used by the button gadget.
  *)

  BEGIN
    ASSERT(font#NIL);
    b.font:=font;
  END SetFont;

  PROCEDURE (b : Button) SetImage*(image : G.Object);
  (**
    Use this method if you do not want text displayed in the button but
    an external initialized image.
  *)

  BEGIN
    b.image:=image;
    b.image.SetParent(b);
  END SetImage;

  PROCEDURE (b : Button) SetString*(string : STRING);
  (**
    Call this method if you want the given text to be displayed in
    the button.

    This creates an instance of @otype{T.Text} using the given text
    and sets it as button label.
  *)

  VAR
    text : T.Text;

  BEGIN
    text:=T.CreateText(); (* Allocate a VOText.Text object for displaying text *)
    text.SetParent(b);
    text.SetFlags({G.horizontalFlex,G.verticalFlex}); (* Our text should be resizeable in all directions *)
    text.SetDefaultAdjustment(T.centered);
    text.SetDefaultFont({},b.font);
    text.SetString(string);
    b.image:=text;                  (* Use it as our image *)
  END SetString;

  PROCEDURE (b : Button) SetLabelString*(string : STRING);
  (**
    Call this method if you want the given text to be displayed in
    the button and want the button to interpret the given string
    regarding shortcuts.

    This creates simply an VOText.Text instance for Button.image.

    Use a @code{*} for "default OK button semantic", a @code{^} for
    "default cancle button" semantic and @code{#} for an general defualt
    button (likely used, if only one button is available).

    Use a @code{_} the mark the next character as shortcut.
  *)

  VAR
    sc,x,
    length : LONGINT;

  BEGIN
    sc:=-1;

    length:=string.length;
    x:=0;
    WHILE x<length DO
      CASE string.CharAt(x) OF
      | "_" :
        IF x+1<length THEN
          sc:=x;
          b.shortCut:=string.CharAt(x+1);
        END;
      | "*" : b.scMode:=return;
      | "^" : b.scMode:=escape;
      | "#" : b.scMode:=default;
      ELSE
      END;
      INC(x);
    END;

    IF (sc>=0) OR (b.scMode#none) THEN
      IF sc>=0 THEN
        string:=string.Substring(0,sc)+
        "\eu"+string.Substring(sc+1,sc+2)+
        "\en"+string.Substring(sc+2,length);
      END;

      IF b.scMode#none THEN
        CASE b.scMode OF
          return:
          string:=string.Substring(0,string.length-1)+"\eR";
        | escape:
          string:=string.Substring(0,string.length-1)+"\eE";
        | default:
          string:=string.Substring(0,string.length-1)+"\eD";
        END;
      END;

      IF (b.shortCut#0X) OR (b.scMode#none) THEN
        b.scAssigned:=FALSE;
      END;
    END;

    b.SetString(string);
  END SetLabelString;

  PROCEDURE (b : Button) SetShortcut*(char : UCS4CHAR);

  BEGIN
    b.shortCut:=char;
    IF b.shortCut#0X THEN
      b.scAssigned:=FALSE;
    END;
  END SetShortcut;

  PROCEDURE (b : Button) SetShortcutMode*(mode : LONGINT);

  BEGIN
    b.scMode:=mode;
    IF b.scMode#none THEN
      b.scAssigned:=FALSE;
    END;
  END SetShortcutMode;

  PROCEDURE (b : Button) SetType*(type : LONGINT);
  (**
    We can define special types of buttons. Currently supported are
    @oconst{normal}, @oconst{small}, @oconst{image} and @oconst{toolBar}.
  *)

  BEGIN
    b.type:=type;
  END SetType;

  PROCEDURE (b : Button) SetPulse*(pulse : BOOLEAN);
  (**
    Is pulsemode is true, the button sends permanent @oconst{pressedMsg} on
    mouse button down and none on the final button up.

    This is usefull for buttons in a scroller or similar.
  *)

  BEGIN
    b.pulse:=pulse;
  END SetPulse;

  PROCEDURE (b : Button) GetDnDObject*(x,y : LONGINT; drag : BOOLEAN):G.Object;

  BEGIN
    IF b.visible & b.PointIsIn(x,y) & (b.image#NIL) THEN
      RETURN b.image.GetDnDObject(x,y,drag);
    ELSE
      RETURN NIL;
    END;
  END GetDnDObject;

  PROCEDURE (b : Button) CalcSize*;

  BEGIN
    (*
      We check, if the image can show some kind of frame. If so, we do not display
      the frame ourself, but delegate it to the image.
    *)

    IF (b.image#NIL) & ~b.image.StdFocus() & b.MayFocus() THEN
      b.RemoveFlags({G.stdFocus});
      b.image.SetFlags({G.mayFocus});
    END;

    (* Let the frame calculate its size *)
    CASE b.type OF
      normal:
      CASE b.scMode OF
        return:
        b.SetObjectFrame(b.prefs(Prefs).returnFrame);
      | escape:
        b.SetObjectFrame(b.prefs(Prefs).escapeFrame);
      | default:
        b.SetObjectFrame(b.prefs(Prefs).defaultFrame);
      ELSE
        b.SetObjectFrame(b.prefs(Prefs).frame);
      END;
    | small:
      b.SetObjectFrame(b.prefs(Prefs).sFrame);
    | image:
      b.SetObjectFrame(b.prefs(Prefs).iFrame);
    | toolBar:
      b.SetObjectFrame(b.prefs(Prefs).tFrame);
    END;

    (* Set background depending of mode *)
    CASE b.scMode OF
      return:  b.SetBackgroundObject(b.prefs(Prefs).bgReturn);
    | escape:  b.SetBackgroundObject(b.prefs(Prefs).bgEscape);
    | default: b.SetBackgroundObject(b.prefs(Prefs).bgDefault);
    ELSE
      (*        b.SetBackgroundObject(b.prefs(Prefs).background);*)
    END;

    (*
      Our size is the size of the frame plus a little space we want to have
      to have between the frame and the image.
    *)
    b.width:=b.prefs(Prefs).hSpace.GetSize()*2;
    b.height:=b.prefs(Prefs).vSpace.GetSize()*2;

    (* Our minimal size is equal to the normal size *)
    b.minWidth:=b.width;
    b.minHeight:=b.height;

    IF b.image#NIL THEN
      (*
        Now we let the image calculate its bounds and simply add its size
        to the size of the button.
      *)
      b.image.CalcSize;
      INC(b.width,b.image.oWidth);
      INC(b.height,b.image.oHeight);
      INC(b.minWidth,b.image.oMinWidth);
      INC(b.minHeight,b.image.oMinHeight);
    END;

    (* We *must* call CalcSize of our superclass! *)
    b.CalcSize^;
  END CalcSize;

  PROCEDURE (b : Button) HandleMouseEvent*(event : E.MouseEvent;
                                           VAR grab : G.Object):BOOLEAN;

  VAR
    pressed : PressedMsg; (* We want to create a pressedMsg
                             when we found out we got pressed *)
    redraw  : BOOLEAN;

  BEGIN
    (* It makes no sense to get the focus if we are currently not visible *)
    IF ~b.visible OR b.disabled THEN
      RETURN FALSE;
    END;

    (*
      When the left mousebutton gets pressed without any qualifier
      in the bounds of our button...
    *)

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & b.PointIsIn(event.x,event.y)
       & (event.button=E.button1) THEN
        IF ~b.state THEN
          (* We change our state to pressed and redisplay ourself *)
          b.state:=TRUE;
          b.Redraw;

          IF b.pulse THEN
            NEW(pressed);
            b.Send(pressed,pressedMsg);
            D.display.AddTimer(b.timer);
          END;

          (*
            Since we want the focus for waiting for buttonup we return
            a pointer to ourself.
          *)
          grab:=b;
          RETURN TRUE;
        ELSE
          (* We change our state to pressed and redisplay ourself *)
          b.state:=TRUE;
          b.Redraw;

          IF b.pulse THEN
            NEW(pressed);
            b.Send(pressed,pressedMsg);
            D.display.AddTimer(b.timer);
          END;
        END;
      ELSIF (event.type=E.mouseUp) & (event.button=E.button1) THEN
        (* We get unselected again and must redisplay ourself *)
        b.state:=FALSE;
        b.Redraw;

        (*
          Clean up and remove possibly remaining timer event.
        *)
        IF b.timer.active THEN
          D.display.RemoveTimer(b.timer);
        END;

        grab:=NIL;

        (*
          If the users released the left mousebutton over our bounds we really
          got selected.
        *)
        IF b.PointIsIn(event.x,event.y) & ~b.pulse THEN
          (*
            We create a PressedMsg and send it away.
            Button.Send (inherited from Object) does the managing
            of the possible attached handlers for use.
          *)
          (* Action: Button pressed *)
          NEW(pressed);
          b.Send(pressed,pressedMsg);
        END;

        IF ~b.PointIsIn(event.x,event.y) THEN
          IF b.active THEN
            b.active:=FALSE;
            b.Redraw;
          END;
        END;
      END;
    | event : E.MotionEvent DO
      redraw:=FALSE;
      IF b.PointIsIn(event.x,event.y) THEN
        IF grab=b THEN
          IF ~b.state THEN
            b.state:=TRUE;
            redraw:=TRUE;
          END;

          IF ~b.active THEN
            b.active:=TRUE;
            redraw:=TRUE;
          END;
        END;
      ELSE
        IF grab=b THEN
          IF b.state THEN
            b.state:=FALSE;
            redraw:=TRUE;
          END;

          IF b.active THEN
            b.active:=FALSE;
            redraw:=TRUE;
          END;
        END;
      END;

      IF redraw THEN
        b.Redraw;
      END;

    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (b : Button) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  VAR
    pressed : PressedMsg; (* We want to create a pressedMsg
                             when we found out we got pressed *)

  BEGIN
    IF event.type=E.keyDown THEN
      IF event.key=E.space THEN
        b.state:=TRUE;
        b.Redraw;
        (* TODO: Add some delay here *)
        b.state:=FALSE;
        b.Redraw;
        NEW(pressed);
        b.Send(pressed,pressedMsg);
        RETURN TRUE;
      END;
    END;
    RETURN FALSE;
  END HandleKeyEvent;

  PROCEDURE (b : Button) Layout*;

  BEGIN
   (*
      We tell the image to resize themself to
      our current bounds. Our bounds could have changed
      because Resize may have been called by some layout-objects
      between Button.CalcSize and Button.Draw.
    *)

    IF b.image#NIL THEN
      b.image.Resize(b.width-b.prefs(Prefs).hSpace.GetSize()*2,
                     b.height-b.prefs(Prefs).vSpace.GetSize()*2);
      b.image.Move(b.x+(b.width-b.image.oWidth) DIV 2,
                   b.y+(b.height-b.image.oHeight) DIV 2);
    END;

    b.Layout^;
  END Layout;

  PROCEDURE (b : Button) Draw*(x,y,w,h : LONGINT);

  VAR
    draw   : D.DrawInfo;
    window : D.Window;

  BEGIN
    IF ~b.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    draw:=b.GetDrawInfo();

    (*
      Set the correct draw mode before calling the baseclass,
      since the baseclass draw the object frame.
    *)
    IF b.active & ~b.state THEN
      draw.mode:={D.activated};
    ELSIF b.state THEN
      draw.mode:={D.selected};
    ELSE
      draw.mode:={};
    END;

    b.Draw^(x,y,w,h); (* We must call Draw of our superclass *)

    IF b.image#NIL THEN
      (*
        We fill the entier region with the background color, extracting
        the region that will be covered by the image object.
      *)

      draw.InstallClip(x,y,w,h);
      draw.SubRegion(b.image.oX,b.image.oY,b.image.oWidth,b.image.oHeight);
      b.DrawBackground(b.x,b.y,b.width,b.height);
      draw.FreeLastClip;

      (*
        Draw the image.
      *)

      b.image.Draw(x,y,w,h);

    ELSE
      b.DrawBackground(b.x,b.y,b.width,b.height);
    END;

    draw.mode:={};

    IF b.disabled & (b.prefs(Prefs).gridDisable OR ~(G.canDisable IN b.image.flags)) THEN
      b.DrawDisabled;
    END;

    IF ~b.scAssigned THEN
      window:=b.GetWindow();
      WITH window : W.Window DO
        IF b.shortCut#0X THEN
          window.RegisterShortcut(b,{},Object.NewUCS4Char(b.shortCut),0,NIL);
          window.RegisterShortcut(b,E.altMask,Object.NewUCS4Char(b.shortCut),0,NIL);
          b.scAssigned:=TRUE;
        END;

        IF b.scMode=return THEN
          window.RegisterCommitShortcut(b,0,NIL);
          b.scAssigned:=TRUE;
        ELSIF b.scMode=escape THEN
          window.RegisterCancelShortcut(b,0,NIL);
          b.scAssigned:=TRUE;
        ELSIF b.scMode=default THEN
          window.RegisterDefaultShortcut(b,0,NIL);
          b.scAssigned:=TRUE;
        END;
      END;
    END;
  END Draw;

  PROCEDURE (b : Button) DrawFocus*;

  VAR
    draw : D.DrawInfo;

  BEGIN
    (* If our image can draw a keyboard focus, delegate it *)
    IF (b.image#NIL) & ~b.image.StdFocus() THEN
      draw:=b.GetDrawInfo();

      IF b.state THEN
        draw.mode:={D.selected};
      ELSE
        draw.mode:={};
      END;
      b.image.DrawFocus;
      draw.mode:={};
    ELSE
      (* Delegate drawing to the baseclass *)
      b.DrawFocus^;
    END;
  END DrawFocus;

  PROCEDURE (b : Button) HideFocus*;

  VAR
    draw : D.DrawInfo;

  BEGIN
    (* If our image can draw a keyboard focus, delegate it *)
    IF (b.image#NIL) & ~b.image.StdFocus() THEN

      draw:=b.GetDrawInfo();
      IF b.state THEN
        draw.mode:={D.selected};
      ELSE
        draw.mode:={};
      END;
      b.image.HideFocus;
      draw.mode:={};
    ELSE
      (* Delegate drawing to the baseclass *)
      b.HideFocus^;
    END;
  END HideFocus;

  PROCEDURE (b : Button) Hide*;

  BEGIN
    IF b.visible THEN
      IF b.image#NIL THEN
        (* Hide the image *)
        b.image.Hide;
      END;
      (* hide the frame *)
      b.Hide^;
    END;
  END Hide;

  PROCEDURE (b : Button) Receive*(message : O.Message);

  VAR
    pressed : PressedMsg; (* We want to create a pressedMsg
                             when we found out we got pressed *)

  BEGIN
    WITH
      message : D.TimerMsg DO
      IF b.state THEN
        (*
          Time to send a new pressed message.
        *)
        NEW(pressed);
        b.Send(pressed,pressedMsg);
        D.display.AddTimer(b.timer);
      END;
    |  message : W.ShortcutMsg DO
      IF message.state=W.shortcutPressed THEN
        b.state:=TRUE;
        b.Redraw;
      ELSE
        b.state:=FALSE;
        b.Redraw;
        IF message.state=W.shortcutReleased THEN
          NEW(pressed);
          b.Send(pressed,pressedMsg);
        END;
      END;
    ELSE
      b.Receive^(message);
    END;
  END Receive;

  PROCEDURE CreateButton*():Button;

    (**
      Creates a new instance of @otype{Button}.
    *)

  VAR
    button : Button;

  BEGIN
    NEW(button);
    button.Init;

    RETURN button;
  END CreateButton;

BEGIN
  NEW(prefs);
  prefs.Init;

END VO:Button.