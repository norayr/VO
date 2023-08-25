(**
   Implements horizontal and vertical scrollers.

  TODO
  * Support for prior, next, home, end
**)

MODULE VO:Scroller;

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

IMPORT D  := VO:Base:Display,
       E  := VO:Base:Event,
       F  := VO:Base:Frame,
       IB := VO:Base:Image,
       O  := VO:Base:Object,
       VB := VO:Base:VecImage,

       A  := VO:Model:Adjustment,

       B  := VO:Button,
       G  := VO:Object,
       I  := VO:Image,
       K  := VO:Knob,
       PA := VO:Panel;


CONST
(*  repeatTimeOut = 75000;*) (* Time between button repeat *)

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 up*,
                 down*,
                 left*,
                 right* : IB.Image;
               END;

  Scroller*     = POINTER TO ScrollerDesc;
  ScrollerDesc* = RECORD (G.GadgetDesc)
                    panel      : PA.Panel;
                    knob       : K.Knob;
                    adjustment : A.Adjustment;
                    vert       : BOOLEAN;
                  END;
VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.frame:=F.CreateFrame(F.none);

    IF D.display.displayType=D.displayTypeTextual THEN
      p.up:=IB.CreateVecImage(VB.simpleUp);
      p.down:=IB.CreateVecImage(VB.simpleDown);
      p.left:=IB.CreateVecImage(VB.simpleLeft);
      p.right:=IB.CreateVecImage(VB.simpleRight);
    ELSE
      p.up:=IB.CreateVecImage(VB.w95Up);
      p.down:=IB.CreateVecImage(VB.w95Down);
      p.left:=IB.CreateVecImage(VB.w95Left);
      p.right:=IB.CreateVecImage(VB.w95Right);
    END;
  END Initialize;


  PROCEDURE (s : Scroller) Init*;

  BEGIN
    s.Init^;

    s.SetPrefs(prefs);

    s.SetFlags({G.canFocus});

    s.vert:=TRUE;

    s.adjustment:=NIL;

    s.panel:=NIL;

    s.knob:=K.CreateKnob();
    s.knob.SetFlags({G.horizontalFlex,G.verticalFlex});
  END Init;

  PROCEDURE (s : Scroller) Set*(vert : BOOLEAN);

  BEGIN
    s.vert:=vert;

    s.knob.Set(vert);
  END Set;

  PROCEDURE (s : Scroller) SetOffset*(offset : LONGINT);

  BEGIN
    s.knob.SetOffset(offset);
  END SetOffset;

  PROCEDURE (s : Scroller) SetModel*(model : O.Model);

  BEGIN
    IF s.adjustment#NIL THEN
      s.UnattachModel(s.adjustment.GetTopModel());
      s.UnattachModel(s.adjustment.GetVisibleModel());
      s.UnattachModel(s.adjustment.GetTotalModel())
    END;
    IF (model#NIL) & (model IS A.Adjustment) THEN
      s.adjustment:=model(A.Adjustment);
      s.AttachModel(s.adjustment.GetTopModel());
      s.AttachModel(s.adjustment.GetVisibleModel());
      s.AttachModel(s.adjustment.GetTotalModel());
    END;

    s.knob.SetModel(model);
  END SetModel;

  PROCEDURE (s : Scroller) ModelAccepted * (m : O.Model):BOOLEAN;

  (**
    This function is used to check if an argument to SetModel
    was successfully accepted.
   *)

  BEGIN
    RETURN m=s.adjustment
  END ModelAccepted;

  PROCEDURE (s : Scroller) CalcSize*;

    PROCEDURE CreateButton(action : LONGINT):B.Button;

    VAR
      button    : B.Button;
      image     : I.Image;
      converter : O.ActionConverter;

    BEGIN
      button:=B.CreateButton();
      button.SetType(B.small);
      IF s.vert THEN
        button.SetFlags({G.horizontalFlex});
      ELSE
        button.SetFlags({G.verticalFlex});
      END;
      button.SetPulse(TRUE);

      image:=I.CreateImage();
      image.SetFlags({G.horizontalFlex,G.verticalFlex});
      IF action=K.decAction THEN
        IF s.vert THEN
          image.SetImage(s.prefs(Prefs).up);
        ELSE
          image.SetImage(s.prefs(Prefs).left);
        END;
      ELSE
        image.SetFlags({G.horizontalFlex,G.verticalFlex});
        IF s.vert THEN
          image.SetImage(s.prefs(Prefs).down);
        ELSE
          image.SetImage(s.prefs(Prefs).right);
        END;
      END;
      button.SetImage(image);

      NEW(converter);
      converter.destination:=s.knob;
      converter.action:=action;
      button.AddHandler(converter,B.pressedMsg);

      RETURN button;
    END CreateButton;

  BEGIN
    s.panel:=PA.CreatePanel();
    s.panel.SetParent(s);

    IF ~s.CanFocus() THEN
      s.knob.RemoveFlags({G.canFocus});
    END;

    IF s.vert THEN
      s.panel.Set(PA.vertical);
      s.panel.SetFlags({G.verticalFlex});
    ELSE
      s.panel.Set(PA.horizontal);
      s.panel.SetFlags({G.horizontalFlex});
    END;

    s.panel.Add(CreateButton(K.decAction));
    s.panel.Add(CreateButton(K.incAction));

    s.panel.Add(s.knob);

    s.panel.Add(CreateButton(K.decAction));
    s.panel.Add(CreateButton(K.incAction));

    s.panel.CalcSize;

    s.minWidth:=s.panel.oMinWidth;
    s.minHeight:=s.panel.oMinHeight;

    s.width:=s.panel.oWidth;
    s.height:=s.panel.oHeight;

    s.CalcSize^;
  END CalcSize;

  PROCEDURE (s : Scroller) HandleMouseEvent*(event : E.MouseEvent;
                                             VAR grab : G.Object):BOOLEAN;

  BEGIN
    IF ~s.visible OR s.disabled THEN
      RETURN FALSE;
    ELSE
      RETURN s.panel.HandleMouseEvent(event,grab);
    END;
  END HandleMouseEvent;

  PROCEDURE (s : Scroller) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    s.panel.MoveResize(s.x,s.y,s.width,s.height);
    s.panel.Move(s.panel.oX,s.panel.oY);
    s.panel.Draw(x,y,w,h);

    IF s.disabled THEN
      s.DrawDisabled;
    END;
  END Draw;

  PROCEDURE (s : Scroller) Hide*;

  BEGIN
    IF s.visible THEN
      s.panel.Hide;
      s.Hide^;
    END;
  END Hide;

  PROCEDURE CreateScroller*():Scroller;

  VAR
    scroller : Scroller;

  BEGIN
    NEW(scroller);
    scroller.Init;

    RETURN scroller;
  END CreateScroller;

  PROCEDURE CreateHScroller*():Scroller;

  VAR
    scroller : Scroller;

  BEGIN
    scroller:=CreateScroller();
    scroller.Set(FALSE);

    RETURN scroller;
  END CreateHScroller;

  PROCEDURE CreateVScroller*():Scroller;

  VAR
    scroller : Scroller;

  BEGIN
    scroller:=CreateScroller();
    scroller.Set(TRUE);

    RETURN scroller;
  END CreateVScroller;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Scroller.