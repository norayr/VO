(**
   Implements horizontal and vertical sliders.

  TODO
  * No highlighting of arrows, should change
**)

MODULE VO:Slider;

(*
    Implements a scroll gadget.
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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

IMPORT BG := VO:Base:Background,
       D  := VO:Base:Display,
       E  := VO:Base:Event,
       F  := VO:Base:Frame,
       IB := VO:Base:Image,
       O  := VO:Base:Object,
       U  := VO:Base:Util,
       VB := VO:Base:VecImage,
       Z  := VO:Base:Size,

       VM := VO:Model:Value,

       G  := VO:Object,
       I  := VO:Image,
       S  := VO:Scale;

CONST
  movedMsg     * = 0;
  moveStartMsg * = 1; (* ActionMsg *)
  moveEndMsg   * = 2; (* ActionMsg *)

TYPE
  Prefs*     = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc* = RECORD (G.PrefsDesc)
                 boxFrame*  : F.Frame;
                 hKnob*,
                 vKnob*     : IB.Image;
                 hSpace*,
                 vSpace*    : Z.SizeDesc;
                 hFill*,
                 vFill*     : G.Background;
               END;


  Slider*     = POINTER TO SliderDesc;
  SliderDesc* = RECORD (G.GadgetDesc)
                  knob        : I.Image;
                  frame       : F.Frame;
                  scale       : S.Scale;
                  from,to     : LONGINT;
                  offset,corr : LONGINT;
                  pos         : VM.ValueModel;
                  vert,
                  selected    : BOOLEAN;
                  useScale    : BOOLEAN;
                END;

  (* messages *)

  MovedMsg*     = POINTER TO MovedMsgDesc;

  (**
    The PressedMsg generated everytime the button get clicked.
  **)

  MovedMsgDesc* = RECORD (O.MessageDesc)
                    model* : VM.ValueModel;
                  END;

VAR
  prefs* : Prefs;
  action : O.Action;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.boxFrame:=F.CreateFrame(F.none);
      p.vKnob:=IB.CreateVecImage(VB.simpleKnob);
      p.hKnob:=IB.CreateVecImage(VB.simpleKnob);
    ELSE
      p.boxFrame:=F.CreateFrame(F.double3DIn);
      p.vKnob:=IB.CreateVecImage(VB.vSlider);
      p.hKnob:=IB.CreateVecImage(VB.hSlider);
    END;
    p.hSpace.Init;
    p.vSpace.Init;
    p.hSpace.SetSize(Z.softUnit,1);
    p.vSpace.SetSize(Z.softUnit,1);
    p.hFill:=BG.CreateBackground();
    p.hFill(BG.Background).SetFill(BG.normal,BG.CreatePlainFillByColorIndex(D.fillColorIndex));
    p.hFill(BG.Background).SetFill(BG.selected,BG.CreatePlainFillByColorIndex(D.fillColorIndex));

    p.vFill:=BG.CreateBackground();
    p.vFill(BG.Background).SetFill(BG.normal,BG.CreatePlainFillByColorIndex(D.fillColorIndex));
    p.vFill(BG.Background).SetFill(BG.selected,BG.CreatePlainFillByColorIndex(D.fillColorIndex));
  END Initialize;

  PROCEDURE (s : Slider) Init*;

  BEGIN
    s.Init^;

    s.SetPrefs(prefs);

    s.SetFlags({G.canFocus});

    s.vert:=TRUE;
    s.useScale:=TRUE;

    s.pos:=NIL;
    s.scale:=NIL;

    s.frame:=s.prefs(Prefs).boxFrame;

    s.selected:=FALSE;

    s.from:=0;
    s.to:=100;
  END Init;

  (**
    Set the direction (horizontal or vertical) of the slider.
  **)

  PROCEDURE (s : Slider) Set*(vert : BOOLEAN);

  BEGIN
    s.vert:=vert;
  END Set;

  (**
    Define, if we should use a scale, or not..
  **)

  PROCEDURE (s : Slider) UseScale*(use : BOOLEAN);

  BEGIN
    s.useScale:=use;
  END UseScale;

  (**
    Set the minimal and maximal value of the slider.
  **)

  PROCEDURE (s : Slider) SetRange*(from,to : LONGINT);

  BEGIN
    IF (s.from#from) OR (s.to#to) THEN
      s.from:=from;
      s.to:=to;
      IF s.visible THEN
        s.Redraw;
      END;
    END;
  END SetRange;

  (**
    Set the integer model to the slider. The slider will
    always represent the value of the model.
  **)

  PROCEDURE (s : Slider) SetModel*(pos : O.Model);

  BEGIN
    IF s.pos#NIL THEN
      s.UnattachModel(s.pos);
    END;
    IF (pos#NIL) & (pos IS VM.ValueModel) THEN
      s.pos:=pos(VM.ValueModel);
      s.AttachModel(pos);
    ELSE
      s.pos:=NIL;
    END;
  END SetModel;

  (**
    This function is used to check if an argument to SetModel
    was successfully accepted.
   **)

  PROCEDURE (s : Slider) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=s.pos
  END ModelAccepted;

  PROCEDURE (s : Slider) CalcSize*;

  BEGIN
    s.knob:=I.CreateImage();
    s.knob.SetParent(s);
    s.knob.SetFlags({G.horizontalFlex,G.verticalFlex});

    IF s.vert THEN
      s.knob.SetImage(s.prefs(Prefs).vKnob);
    ELSE
      s.knob.SetImage(s.prefs(Prefs).hKnob);
    END;

    IF ~s.knob.StdFocus() & s.MayFocus() THEN
      s.RemoveFlags({G.stdFocus});
      s.knob.SetFlags({G.mayFocus});
    END;

    s.knob.CalcSize;

    IF s.vert THEN
      s.width:=s.knob.oWidth;
      s.height:=3*s.width;
      s.offset:=s.knob.oHeight DIV 2;
    ELSE
      s.height:=s.knob.oHeight;
      s.width:=3*s.height;
      s.offset:=s.knob.oWidth DIV 2;
    END;

    IF s.useScale THEN
      s.scale:=S.CreateScale();
      s.scale.SetParent(s);
      s.scale.SetDirection(s.vert);
      s.scale.SetInterval(s.from,s.to);
      s.scale.SetFlags({G.horizontalFlex,G.verticalFlex});
      s.scale.CalcSize;

      IF s.vert THEN
        INC(s.width,s.scale.width);
        s.height:=U.MaxLong(s.height,s.scale.height);
        INC(s.width,s.prefs(Prefs).hSpace.GetSize());
      ELSE
        INC(s.height,s.scale.height);
        s.width:=U.MaxLong(s.width,s.scale.width);
        INC(s.height,s.prefs(Prefs).vSpace.GetSize());
      END;
    END;

    INC(s.width,s.frame.leftBorder+s.frame.rightBorder);
    INC(s.height,s.frame.topBorder+s.frame.bottomBorder);

    IF s.vert THEN
      INC(s.offset,s.frame.topBorder);
    ELSE
      INC(s.offset,s.frame.leftBorder);
    END;

    s.minWidth:=s.width;
    s.minHeight:=s.height;

    s.CalcSize^;
  END CalcSize;

  PROCEDURE (s : Slider) DrawKnob;

  VAR
    kStart,
    bSize,
    offset : LONGINT;
    draw   : D.DrawInfo;

  BEGIN
    IF s.vert THEN
      IF s.useScale THEN
        offset:=s.scale.width+s.prefs(Prefs).hSpace.GetSize();
      ELSE
        offset:=0;
      END;

      INC(offset,s.frame.leftBorder);

      bSize:=s.height-2*s.offset-1;
    ELSE
      IF s.useScale THEN
        offset:=s.scale.height+s.prefs(Prefs).vSpace.GetSize();
      ELSE
        offset:=0;
      END;

      INC(offset,s.frame.topBorder);

      bSize:=s.width-2*s.offset-1;
    END;


    IF (s.pos=NIL) OR s.pos.IsNull() THEN
      s.knob.Hide;

      IF s.vert THEN
        s.DrawBackground(s.x+offset,
                         s.y+s.frame.topBorder,
                         s.knob.oWidth,
                         bSize);
      ELSE
        s.DrawBackground(s.x+s.frame.leftBorder,
                         s.y+offset,
                         bSize,
                         s.knob.oHeight);
      END;
      RETURN;
    END;

    draw:=s.GetDrawInfo();

    IF s.knob.visible THEN
      s.knob.Hide;
    END;

    IF s.selected THEN
      draw.mode:={D.selected};
    END;

    IF s.vert THEN

      IF s.to=s.from THEN
        kStart:=s.frame.topBorder;
      ELSE
        kStart:=bSize-U.RoundDiv((s.pos.GetLongint()-s.from)*bSize,s.to-s.from)+s.frame.topBorder;
      END;


      s.DrawBackground(s.x+offset,s.y+s.frame.topBorder,s.knob.oWidth,kStart);
      s.knob.Move(s.x+offset,s.y+kStart);
      s.knob.Draw(s.oX,s.oY,s.oWidth,s.oHeight);

      s.prefs(Prefs).vFill.DrawRelObject(draw,s,
                                         s.x+offset,
                                         s.y+kStart+s.knob.oHeight,
                                         s.knob.oWidth,
                                         s.height-s.frame.bottomBorder-kStart-s.knob.oHeight);
    ELSE
      IF s.to=s.from THEN
        kStart:=s.frame.leftBorder;
      ELSE
        kStart:=U.RoundDiv((s.pos.GetLongint()-s.from)*bSize,s.to-s.from)+s.frame.leftBorder;
      END;

      s.prefs(Prefs).hFill.DrawRelObject(draw,s,
                                         s.x+s.frame.leftBorder,
                                         s.y+offset,
                                         kStart,
                                         s.knob.oHeight);

      s.knob.Move(s.x+kStart,s.y+offset);
      s.knob.Draw(s.oX,s.oY,s.oWidth,s.oHeight);
      s.DrawBackground(s.x+kStart+s.knob.oWidth,
                       s.y+offset,
                       s.width-s.frame.rightBorder-kStart-s.knob.oWidth,
                       s.knob.oHeight);
    END;
    draw.mode:={};
  END DrawKnob;

  PROCEDURE (s : Slider) OnMoved;

  VAR
    moved : MovedMsg;

  BEGIN
    NEW(moved);
    moved.model:=s.pos;
    s.Send(moved,movedMsg);
  END OnMoved;

  PROCEDURE (s : Slider) Dec;

  BEGIN
    IF s.pos.GetLongint()>s.from THEN
      s.pos.Dec;
      s.OnMoved;
    END;
  END Dec;

  PROCEDURE (s : Slider) Inc;

  BEGIN
    IF s.pos.GetLongint()<s.to THEN
      s.pos.Inc;
      s.OnMoved;
    END;
  END Inc;

  PROCEDURE (s : Slider) HandleMouseMovement(x,y : LONGINT);

  VAR
    new : LONGINT;

  BEGIN
    IF s.vert THEN
      new:=s.to-(y-s.y-s.corr)*(s.to-s.from+1) DIV (s.height-2*s.offset)+s.from;
    ELSE
      new:=(x-s.x-s.corr)*(s.to-s.from+1) DIV (s.width-2*s.offset)+s.from;
    END;
    IF (new>=s.from) & (new<=s.to) THEN
      s.pos.SetLongint(new);
    ELSIF new<s.from THEN
      s.pos.SetLongint(s.from);
    ELSIF new>s.to THEN
      s.pos.SetLongint(s.to);
    END;
  END HandleMouseMovement;

  PROCEDURE (s : Slider) HandleMouseEvent*(event : E.MouseEvent;
                                           VAR grab : G.Object):BOOLEAN;

  BEGIN
    IF ~s.visible OR s.disabled THEN
      RETURN FALSE;
    END;

    IF (s.pos=NIL) OR s.pos.IsNull() THEN
      RETURN FALSE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & s.PointIsIn(event.x,event.y) THEN
        IF (event.button=E.button1) THEN
          IF s.knob.PointIsIn(event.x,event.y) THEN

            IF s.vert THEN
              s.corr:=event.y-s.knob.y;
            ELSE
              s.corr:=event.x-s.knob.x;
            END;
            s.selected:=TRUE;
            s.DrawKnob;

            action.action:=moveStartMsg;
            s.Send(action,O.actionMsg);

          ELSE
            IF s.vert THEN
              IF event.y<s.knob.y THEN
                s.Inc;
              ELSIF event.y>s.knob.y+s.knob.oHeight THEN
                s.Dec;
              END;
            ELSE
              IF event.x<s.knob.x THEN
                s.Dec;
              ELSIF event.x>s.knob.x+s.knob.oWidth THEN
                s.Inc;
              END;
            END;
          END;

          grab:=s;
        ELSIF (event.button=E.button4) THEN
          s.Dec;
        ELSIF (event.button=E.button5) THEN
          s.Inc;
        END;

        RETURN TRUE;

      ELSIF (event.type=E.mouseUp) & (event.button=E.button1) THEN
        IF s.selected THEN
          s.HandleMouseMovement(event.x,event.y);
          s.selected:=FALSE;
        END;

        s.DrawKnob;
        s.OnMoved;

        action.action:=moveEndMsg;
        s.Send(action,O.actionMsg);

        grab:=NIL;
        RETURN TRUE;
      END;
    | event : E.MotionEvent DO
      IF s.selected THEN
        s.HandleMouseMovement(event.x,event.y);
        RETURN TRUE;
      END;
    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (s : Slider) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  VAR
    old,
    tmp    : LONGINT;
    moved  : MovedMsg;

  BEGIN
    IF (event.type=E.keyDown) & (s.pos#NIL) THEN
      old:=s.pos.GetLongint();
      IF (s.vert & (event.key=E.down)) OR (~s.vert & (event.key=E.left)) THEN
        s.Dec;
      ELSIF (s.vert & (event.key=E.up)) OR (~s.vert & (event.key=E.right)) THEN
        s.Inc;
      ELSIF event.key=E.home THEN
        s.pos.SetLongint(s.from);
      ELSIF event.key=E.end THEN
        s.pos.SetLongint(s.to);
      ELSIF event.key=E.next THEN
        tmp:=old;
        DEC(tmp,(s.to-s.from+1) DIV 10);
        IF tmp<s.from THEN
          tmp:=s.from;
        END;
        s.pos.SetLongint(tmp);
      ELSIF event.key=E.prior THEN
        tmp:=old;
        INC(tmp,(s.to-s.from+1) DIV 10);
        IF tmp>s.to THEN
          tmp:=s.to;
        END;
        s.pos.SetLongint(tmp);
      ELSE
        RETURN FALSE;
      END;

      (* We have changed the value of the model *)
      IF old#s.pos.GetLongint() THEN
        NEW(moved);
        moved.model:=s.pos;
        s.Send(moved,movedMsg);
      END;
      RETURN TRUE;
    END;
    RETURN FALSE;
  END HandleKeyEvent;

  PROCEDURE (s : Slider) Layout*;

  BEGIN
    IF s.useScale THEN
      IF s.vert THEN
        s.scale.MoveResize(s.x,s.y+s.offset,-1,s.height-2*s.offset);
      ELSE
        s.scale.MoveResize(s.x+s.offset,s.y,s.width-2*s.offset,-1);
      END;
    END;

    s.Layout^;
  END Layout;

  PROCEDURE (s : Slider) Draw*(x,y,w,h : LONGINT);

  VAR
    draw    : D.DrawInfo;
    fOffset,
    fSize   : LONGINT;

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    draw:=s.GetDrawInfo();

    IF s.useScale THEN
      IF s.vert THEN
        fOffset:=s.scale.oWidth+s.prefs(Prefs).hSpace.GetSize();
        fSize:=s.knob.oWidth+s.frame.leftBorder+s.frame.rightBorder;
      ELSE
        fOffset:=s.scale.oHeight+s.prefs(Prefs).vSpace.GetSize();
        fSize:=s.knob.oHeight+s.frame.topBorder+s.frame.bottomBorder;
      END;
    ELSE
      fOffset:=0;
      IF s.vert THEN
        fSize:=s.knob.oWidth+s.frame.leftBorder+s.frame.rightBorder;
      ELSE
        fSize:=s.knob.oHeight+s.frame.topBorder+s.frame.bottomBorder;
      END;
    END;

    draw.InstallClip(x,y,w,h);
    IF s.useScale THEN
      draw.SubRegion(s.scale.oX,s.scale.oY,s.scale.oWidth,s.scale.oHeight);
    END;

    IF s.vert THEN
      draw.SubRegion(s.x+fOffset,s.y,fSize,s.height);
    ELSE
      draw.SubRegion(s.x,s.y+fOffset,s.width,fSize);
    END;

    s.DrawBackground(s.x,s.y,s.width,s.height);
    draw.FreeLastClip;

    IF s.useScale THEN
      s.scale.Draw(x,y,w,h);
    END;

    IF s.vert THEN
      s.frame.Draw(draw,s.x+fOffset,s.y,fSize,s.height);
    ELSE
      s.frame.Draw(draw,s.x,s.y+fOffset,s.width,fSize);
    END;

    s.DrawKnob;

    IF s.disabled THEN
      s.DrawDisabled;
    END;
  END Draw;

  PROCEDURE (s : Slider) Hide*;

  BEGIN
    IF s.visible THEN
      s.knob.Hide;
      s.Hide^;
    END;
  END Hide;

  PROCEDURE (s : Slider) DrawFocus*;

  BEGIN
    IF ~s.knob.StdFocus() THEN
      s.knob.DrawFocus;
      IF s.selected THEN (* little hack, to get the knob selected when it display the focus *)
        s.DrawKnob;
      END;
    ELSE
      (* Delegate drawing to the baseclass *)
      s.DrawFocus^;
    END;
  END DrawFocus;

  PROCEDURE (s : Slider) HideFocus*;

  BEGIN
    IF ~s.knob.StdFocus() THEN
      s.knob.HideFocus;
    ELSE
      (* Delegate drawing to the baseclass *)
      s.HideFocus^;
    END;
  END HideFocus;

  PROCEDURE (s : Slider) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF s.visible & ~s.disabled THEN
      s.DrawKnob;
    END;
  END Resync;

  PROCEDURE CreateSlider*():Slider;

  VAR
    slider : Slider;

  BEGIN
    NEW(slider);
    slider.Init;

    RETURN slider;
  END CreateSlider;

  PROCEDURE CreateHSlider*():Slider;

  VAR
    slider : Slider;

  BEGIN
    slider:=CreateSlider();
    slider.Set(FALSE);

    RETURN slider;
  END CreateHSlider;

  PROCEDURE CreateVSlider*():Slider;

  VAR
    slider : Slider;

  BEGIN
    slider:=CreateSlider();
    slider.Set(TRUE);

    RETURN slider;
  END CreateVSlider;

BEGIN
  NEW(prefs);
  prefs.Init;

  NEW(action);
END VO:Slider.