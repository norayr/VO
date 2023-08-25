(**
   A simple boolean/radio button with a selected and an unselected state.
**)

MODULE VO:State;

(*
    A simple state gadget.
    Copyright (C) 20001  Tim Teulings (rael@edge.ping.de)

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
       I  := VO:Base:Image,
       O  := VO:Base:Object,
       V  := VO:Base:VecImage,

       VM := VO:Model:Value,

       G  := VO:Object;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 image* : I.Image;
               END;


  State*     = POINTER TO StateDesc;
  StateDesc* = RECORD (G.GadgetDesc)
                 (**
                   Implementation of a bool gadget.
                 *)
                 image    : I.Image;
                 model-   : VM.ValueModel;
                 index,
                 tmpState : LONGINT;
               END;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.textButton);
    END;

    p.image:=I.CreateVecImage(V.none);
  END Initialize;

  PROCEDURE (b : State) Init*;

  BEGIN
    b.Init^;

    b.SetFlags({G.canFocus});

    b.model:=NIL;

    b.index:=1;
(*    b.image:=NIL;
    b.selImage:=NIL;*)
  END Init;

  PROCEDURE (b : State) SetPrefs*(prefs : G.Prefs);

  BEGIN
    b.SetPrefs^(prefs);

    b.image:=prefs(Prefs).image;
  END SetPrefs;

  PROCEDURE (b : State) IsIn(x,y : LONGINT):BOOLEAN;

  BEGIN
    RETURN b.PointIsIn(x,y) OR ((b.labelObject#NIL) & (b.labelObject.PointIsIn(x,y)));
  END IsIn;

  PROCEDURE (b : State) SetModel*(model : O.Model);

  BEGIN
    IF b.model#NIL THEN
      b.UnattachModel(b.model);
    END;
    IF (model#NIL) & (model IS VM.ValueModel) THEN
      b.model:=model(VM.ValueModel);
      b.AttachModel(b.model);
    ELSE
      b.model:=NIL;
    END;
  END SetModel;

  PROCEDURE (b : State) SetIndex*(index : LONGINT);

  BEGIN
    b.index:=index;
  END SetIndex;

  PROCEDURE (b : State) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=b.model
  END ModelAccepted;


  PROCEDURE (b : State) CalcSize*;

  BEGIN
    (*
      If the label has a custom way for displaying a focus frame
      we delegate the focus displaying to the label.
    *)
    IF (b.labelObject#NIL) & ~b.labelObject.StdFocus() & b.MayFocus() THEN
      b.RemoveFlags({G.stdFocus});
      b.labelObject.SetFlags({G.mayFocus});
    END;

    b.minWidth:=b.image.width;
    b.minHeight:=b.image.height;
    b.width:=b.minWidth;
    b.height:=b.minHeight;

    b.CalcSize^;
  END CalcSize;

  PROCEDURE (b : State) OnClick*;

  BEGIN
    IF b.model.type=VM.boolean THEN
      IF b.tmpState=0 THEN
        b.model.SetBoolean(TRUE);
      ELSE
        b.model.SetBoolean(FALSE);
      END;
    ELSIF b.model.type=VM.longint THEN
      b.model.SetLongint(b.index);
    END;
  END OnClick;

  PROCEDURE (b : State) HandleMouseEvent*(event : E.MouseEvent;
                                         VAR grab : G.Object):BOOLEAN;

  BEGIN
    IF ~b.visible OR b.disabled OR (b.model=NIL) OR b.model.IsNull() THEN
      RETURN FALSE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown)
      & b.IsIn(event.x,event.y) & (event.button=E.button1) THEN
        b.tmpState:=b.model.GetLongint();
        b.OnClick;

        grab:=b;
        RETURN TRUE;
      ELSIF (event.type=E.mouseUp) & (event.button=E.button1) THEN
        IF b.IsIn(event.x,event.y) THEN
          b.OnClick;
        END;

        grab:=NIL;
        RETURN TRUE;
      END;
    | event : E.MotionEvent DO
      IF grab#NIL THEN
        IF b.IsIn(event.x,event.y) THEN
          b.OnClick;
        ELSE
          b.model.SetLongint(b.tmpState);
        END;
        RETURN TRUE;
      END;
    ELSE
    END;
    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (b : State) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  BEGIN
    IF event.type=E.keyDown THEN
      IF (event.key=E.space) & (b.model#NIL) THEN
        b.tmpState:=b.model.GetLongint();
        b.OnClick;
        RETURN TRUE;
      END;
    END;
    RETURN FALSE;
  END HandleKeyEvent;

  PROCEDURE (b : State) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~b.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    b.Draw^(x,y,w,h);

    draw:=b.GetDrawInfo();

(*    IF b.disabled & (G.canDisable IN b.image.flags) THEN
      INCL(draw.mode,D.disabled);
    END;*)

    IF b.image.alpha THEN
      b.DrawBackground(b.x,b.y,b.width,b.height);
    END;

    IF (b.model#NIL) & ~b.model.IsNull() & (b.model.GetLongint()=b.index) THEN
      draw.mode:={D.selected};
    ELSE
      draw.mode:={};
    END;

    b.image.Draw(draw,b.x,b.y,b.width,b.height);

    draw.mode:={};

    (* This is a dirty hack *)
(*    IF b.disabled & ~((b.image IS I.VecImage) & (b.image(I.VecImage).image.type=V.led)) (*& ~(G.canDisable IN b.image.flags)*) THEN
      b.DrawDisabled;
    END;*)
  END Draw;

  PROCEDURE (b : State) DrawFocus*;

  BEGIN
    (* If our image can draw a keyboard focus, delegate it *)
    IF (b.labelObject#NIL) & ~b.labelObject.StdFocus() THEN
      b.labelObject.DrawFocus;
    ELSE
      (* Delegate drawing to the baseclass *)
      b.DrawFocus^;
    END;
  END DrawFocus;

  PROCEDURE (b : State) HideFocus*;

  BEGIN
    (* If our image can draw a keyboard focus, delegate it *)
    IF (b.labelObject#NIL) & ~b.labelObject.StdFocus() THEN
      b.labelObject.HideFocus;
    ELSE
      (* Delegate drawing to the baseclass *)
      b.HideFocus^;
    END;
  END HideFocus;

  PROCEDURE (b : State) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF b.visible THEN
      b.Redraw;
    END;
  END Resync;

  PROCEDURE CreateState*(): State;

  VAR
    state : State;

  BEGIN
    NEW(state);
    state.Init;

    RETURN state;
  END CreateState;

END VO:State.