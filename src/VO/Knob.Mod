MODULE VO:Knob;

  (**
    Implements @otype{Knob}.
  *)

  (*
    Implements a knob widget to be used in scroll gadget.
    Copyright (C) 2000 Tim Teulings (rael@edge.ping.de)

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

       A  := VO:Model:Adjustment,

       G  := VO:Object,
       I  := VO:Image;


CONST
  decAction* = 0;
  incAction* = 1;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hKnob*,
                 vKnob*        : IB.Image;
                 hBackground*,
                 vBackground*  : G.Background;
                 hFrame*,
                 vFrame*       : F.Frame;
               END;

  Knob*     = POINTER TO KnobDesc;
  KnobDesc* = RECORD (G.GadgetDesc)
                (**
                  Implements the knob part of a scrollbar. You can use this object
                  directly if you know what you do (need such beast as part
                  of a new control), but if you want to have a simple scrollbar,
                  simple use @code{VO:Scroller}.

                  It epects an instance of @otype{A.Adjustment} as an model.
                *)
                knob       : I.Image;
                offset     : LONGINT; (** offset of the mouse relative to the knob start during mouse selection *)
                corr       : LONGINT; (** corrective offset to fix model values not starting with 0 *)
                adjustment : A.Adjustment;
                vert       : BOOLEAN;
              END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.backgroundColorIndex));
    ELSE
      p.background:=BG.CreateBackgroundByFill(BG.CreatePatternFillByIndex(D.bigChess,D.halfShineColorIndex,D.shineColorIndex));
    END;

    p.hBackground:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.backgroundColorIndex));
    p.vBackground:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.backgroundColorIndex));

    p.frame:=F.CreateFrame(F.none);
    IF D.display.displayType=D.displayTypeTextual THEN
      p.hKnob:=IB.CreateVecImage(VB.simpleKnob);
      p.vKnob:=IB.CreateVecImage(VB.simpleKnob);
    ELSE
      p.hKnob:=IB.CreateVecImage(VB.w95Knob);
      p.vKnob:=IB.CreateVecImage(VB.w95Knob);
    END;

    p.hFrame:=F.CreateFrame(F.none);
    p.vFrame:=F.CreateFrame(F.none);
  END Initialize;

  PROCEDURE (k : Knob) Init*;

  BEGIN
    k.Init^;

    k.SetPrefs(prefs);

    k.SetFlags({G.canFocus});

    k.vert:=TRUE;

    k.adjustment:=NIL;

    k.offset:=0;

    k.corr:=0;

    k.knob:=I.CreateImage();
    k.knob.SetParent(k);
    k.knob.SetFlags({G.horizontalFlex,G.verticalFlex});
  END Init;

  PROCEDURE (k : Knob) Set*(vert : BOOLEAN);

    (**
      Set the direction of the knob.
    *)

  BEGIN
    k.vert:=vert;
  END Set;

  PROCEDURE (k : Knob) SetOffset*(offset : LONGINT);

    (**
      Don't use it!
    *)

  BEGIN
    k.corr:=offset;
  END SetOffset;

  PROCEDURE (k : Knob) DrawKnob;

  VAR
    kSize,
    kStart,
    bSize   : LONGINT;
    draw    : D.DrawInfo;

  BEGIN
    draw:=k.GetDrawInfo();

    IF k.vert THEN
      bSize:=k.height;
    ELSE
      bSize:=k.width;
    END;

    IF (k.adjustment#NIL) & k.adjustment.IsValid()
      & ~(k.adjustment.GetVisible()=k.adjustment.GetTotal()) THEN

      IF k.adjustment.GetTotal()+k.corr=0 THEN
        kSize:=bSize;
        kStart:=0;
      ELSE
        kSize:=U.RoundDiv((bSize*k.adjustment.GetVisible()),k.adjustment.GetTotal()+k.corr);
        kStart:=U.RoundDiv(bSize*(k.adjustment.GetTop()+k.corr-1),k.adjustment.GetTotal()+k.corr);
      END;

      IF k.vert THEN
        IF kSize<k.knob.oMinWidth THEN
          kSize:=k.knob.oMinWidth;
        END;
      ELSE
        IF kSize<k.knob.oMinHeight THEN
          kSize:=k.knob.oMinHeight;
        END;
      END;

      IF kSize>bSize THEN
        kSize:=bSize;
      END;

      IF kStart+kSize>bSize THEN
        kStart:=bSize-kSize;
      END;

      IF k.vert THEN
        k.knob.MoveResize(k.x,k.y+kStart,k.width,kSize);
      ELSE
        k.knob.MoveResize(k.x+kStart,k.y,kSize,k.height);
      END;
      k.knob.Draw(k.oX,k.oY,k.oWidth,k.oHeight);

      IF k.vert THEN
        k.DrawBackground(k.x,k.y,k.width,k.knob.oY-k.y);

        k.DrawBackground(k.x,k.knob.oY+k.knob.oHeight,
                         k.width,bSize-k.knob.oHeight-kStart);
      ELSE
        k.DrawBackground(k.x,k.y,k.knob.oX-k.x,k.height);

        k.DrawBackground(k.knob.oX+k.knob.oWidth,k.y,
                         bSize-k.knob.oWidth-kStart,k.height);
      END;

    ELSE (* no models *)
      IF k.vert THEN
        k.DrawBackground(k.x,k.y,k.width,bSize);
      ELSE
        k.DrawBackground(k.x,k.y,bSize,k.height);
      END;
    END;
  END DrawKnob;

  PROCEDURE (k : Knob) SetModel*(model : O.Model);

  BEGIN
    IF k.adjustment#NIL THEN
      k.UnattachModel(k.adjustment.GetTopModel());
      k.UnattachModel(k.adjustment.GetVisibleModel());
      k.UnattachModel(k.adjustment.GetTotalModel())
    END;
    IF (model#NIL) & (model IS A.Adjustment) THEN
      k.adjustment:=model(A.Adjustment);
      k.AttachModel(k.adjustment.GetTopModel());
      k.AttachModel(k.adjustment.GetVisibleModel());
      k.AttachModel(k.adjustment.GetTotalModel());
    END;
  END SetModel;

  PROCEDURE (k : Knob) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=k.adjustment
  END ModelAccepted;


  PROCEDURE (k : Knob) CalcSize*;

  BEGIN
    IF k.vert THEN
      k.knob.SetImage(k.prefs(Prefs).vKnob);
      k.knob.SetBackgroundObject(k.prefs(Prefs).vBackground);
      k.knob.SetObjectFrame(k.prefs(Prefs).vFrame);
    ELSE
      k.knob.SetImage(k.prefs(Prefs).hKnob);
      k.knob.SetBackgroundObject(k.prefs(Prefs).hBackground);
      k.knob.SetObjectFrame(k.prefs(Prefs).hFrame);
    END;
    k.knob.CalcSize;

    IF k.vert THEN
      k.width:=k.knob.oWidth;
      k.height:=k.knob.oWidth;
    ELSE
      k.width:=k.knob.oHeight;
      k.height:=k.knob.oHeight;
    END;

    k.minWidth:=k.width;
    k.minHeight:=k.height;

    k.CalcSize^;
  END CalcSize;

  PROCEDURE (k : Knob) HandleMouseMovement(x,y : LONGINT);

  VAR
    new : LONGINT;

  BEGIN
    IF k.vert THEN
      new:=k.adjustment.GetTop()+k.corr
      +((y-k.knob.oY-k.offset)*(k.adjustment.GetTotal()+k.corr)) DIV k.height + 1;
      IF (new>0) & (new<=k.adjustment.GetTotal()+k.corr-k.adjustment.GetVisible()+1) THEN
        k.adjustment.SetTop(new);
      ELSIF new<=0 THEN
        k.adjustment.SetTop(1-k.corr);
      ELSE
        k.adjustment.SetTop(k.adjustment.GetTotal()+k.corr-k.adjustment.GetVisible()+1);
      END;
    ELSE
      new:=k.adjustment.GetTop()+k.corr
      +((x-k.knob.oX-k.offset)*(k.adjustment.GetTotal()+k.corr)) DIV k.width + 1;
      IF (new>0) & (new<=k.adjustment.GetTotal()+k.corr-k.adjustment.GetVisible()+1) THEN
        k.adjustment.SetTop(new);
      ELSIF new<=0 THEN
        k.adjustment.SetTop(1-k.corr);
      ELSE
        k.adjustment.SetTop(k.adjustment.GetTotal()+k.corr-k.adjustment.GetVisible()+1);
      END;
    END;
  END HandleMouseMovement;

  PROCEDURE (k : Knob) HandleMouseEvent*(event : E.MouseEvent;
                                         VAR grab : G.Object):BOOLEAN;

  BEGIN
    IF ~k.visible OR k.disabled THEN
      RETURN FALSE;
    END;

    IF (k.adjustment=NIL) OR ~k.adjustment.IsValid()
      OR (k.adjustment.GetVisible()=k.adjustment.GetTotal()) THEN
      RETURN FALSE;
    END;


    WITH event : E.ButtonEvent DO

      IF (event.type=E.mouseDown) & k.PointIsIn(event.x,event.y)
      & (event.button=E.button1) THEN
        IF k.knob.PointIsIn(event.x,event.y) THEN
          IF k.vert THEN
            k.offset:=event.y-k.knob.oY;
          ELSE
            k.offset:=event.x-k.knob.oX;
          END;
          grab:=k;
          k.Redraw;
        ELSE
          IF k.vert THEN
            IF event.y<k.knob.oY THEN
              IF k.adjustment.GetTop()+k.corr>k.adjustment.GetVisible() THEN
                k.adjustment.SetTop(k.adjustment.GetTop()-k.adjustment.GetVisible());
              ELSE
                k.adjustment.SetTop(1-k.corr);
              END;
            ELSIF event.y>k.knob.oY+k.knob.oHeight THEN
              IF k.adjustment.GetTop()+k.corr+k.adjustment.GetVisible()<k.adjustment.GetTotal()-k.adjustment.GetVisible()+1 THEN
                k.adjustment.SetTop(k.adjustment.GetTop()+k.adjustment.GetVisible());
              ELSE
                k.adjustment.SetTop(k.adjustment.GetTotal()-k.corr-k.adjustment.GetVisible()+1);
              END;
            END;
          ELSE
            IF event.x<k.knob.oX THEN
              IF k.adjustment.GetTop()+k.corr>k.adjustment.GetVisible() THEN
                k.adjustment.SetTop(k.adjustment.GetTop()-k.adjustment.GetVisible());
              ELSE
                k.adjustment.SetTop(1-k.corr);
              END;
            ELSIF event.x>k.knob.oX+k.knob.oWidth THEN
              IF k.adjustment.GetTop()+k.corr+k.adjustment.GetVisible()<k.adjustment.GetTotal()-k.adjustment.GetVisible()+1 THEN
                k.adjustment.SetTop(k.adjustment.GetTop()+k.adjustment.GetVisible());
              ELSE
                k.adjustment.SetTop(k.adjustment.GetTotal()-k.adjustment.GetVisible()-k.corr+1);
              END;
            END;
          END;

        END;
        RETURN TRUE;
      ELSIF (event.type=E.mouseUp) & (event.button=E.button1) THEN
        IF grab#NIL THEN
          k.HandleMouseMovement(event.x,event.y);
        END;

        grab:=NIL;
        RETURN TRUE;
      END;
    | event : E.MotionEvent DO
      IF grab#NIL THEN
        k.HandleMouseMovement(event.x,event.y);
        RETURN TRUE;
      END;
    ELSE
    END;
    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (k : Knob) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  BEGIN
    IF event.type=E.keyDown THEN
      IF k.vert & (event.key=E.up) THEN
        IF k.adjustment.GetTop()+k.corr>1 THEN
          k.adjustment.DecTop;
        END;
      ELSIF k.vert & (event.key=E.down) THEN
        IF k.adjustment.GetTop()+k.corr<=k.adjustment.GetTotal()+k.corr-k.adjustment.GetVisible() THEN
          k.adjustment.IncTop;
        END;
      ELSIF ~k.vert & (event.key=E.left) THEN
        IF k.adjustment.GetTop()+k.corr>1 THEN
          k.adjustment.DecTop;
        END;
      ELSIF ~k.vert & (event.key=E.left) THEN
        IF k.adjustment.GetTop()+k.corr<=k.adjustment.GetTotal()+k.corr-k.adjustment.GetVisible() THEN
          k.adjustment.IncTop;
        END;
      ELSE
        RETURN FALSE;
      END;
      RETURN TRUE;
    END;
    RETURN FALSE;
  END HandleKeyEvent;

  PROCEDURE (k : Knob) Receive*(message : O.Message);

  BEGIN
    WITH
      message : O.Action DO
        IF message.action=decAction THEN
          IF (k.adjustment#NIL) & (k.adjustment.GetTop()+k.corr>1) THEN
            k.adjustment.DecTop;
          END;
        ELSIF message.action=incAction THEN
          IF (k.adjustment#NIL)
          &  (k.adjustment.GetTop()+k.corr<=k.adjustment.GetTotal()+k.corr-k.adjustment.GetVisible()) THEN
            k.adjustment.IncTop;
          END;
        END;
    ELSE
      k.Receive^(message);
    END;
  END Receive;

  PROCEDURE (k : Knob) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~k.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    k.Draw^(x,y,w,h);

    k.DrawKnob;

    IF k.disabled THEN
      k.DrawDisabled;
    END;
  END Draw;

  PROCEDURE (k : Knob) Hide*;

  BEGIN
    IF k.visible THEN
      k.knob.Hide;
      k.Hide^;
    END;
  END Hide;

  PROCEDURE (k : Knob) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF k.visible & ~k.disabled THEN
      k.DrawKnob;
    END;
  END Resync;

  PROCEDURE CreateKnob*():Knob;

    (**
      Creates a new instance of @otype{Knob}.
    *)

  VAR
    knob : Knob;

  BEGIN
    NEW(knob);
    knob.Init;

    RETURN knob;
  END CreateKnob;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Knob.