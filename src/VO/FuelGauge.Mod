MODULE VO:FuelGauge;

  (**
    Implements @otype{FuelGauge}.
  *)

  (*
    A fuelgauge.
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

IMPORT BG := VO:Base:Background,
       D  := VO:Base:Display,
       F  := VO:Base:Frame,
       IB := VO:Base:Image,
       O  := VO:Base:Object,
       U  := VO:Base:Util,
       VB := VO:Base:VecImage,
       Z  := VO:Base:Size,

       V  := VO:Model:Value,

       I  := VO:Image,
       G  := VO:Object;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hImage*,
                 vImage*       : IB.Image;
                 hBackground*,
                 vBackground*  : G.Background;
                 hFrame*,
                 vFrame*       : F.Frame;

                 width*,
                 height*       : Z.SizeDesc;
               END;

  FuelGauge*     = POINTER TO FuelGaugeDesc;
  FuelGaugeDesc* = RECORD (G.ImageDesc)
                     (**
                       An object that shows some kind of percentual level meter.

                       The object expects an instance of @otype{V.IntModel}
                       as model.
                     *)
                     image    : I.Image;      (** The fuel image *)
                     current  : V.ValueModel; (** model for the current value *)
                     min,                     (** minimum value of the model *)
                     max      : LONGINT;      (** maximum value of the model *)
                     vertical : BOOLEAN;
                   END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.textButton);
    ELSE
      p.frame:=F.CreateFrame(F.double3DIn);
    END;

    p.width.Init;
    p.height.Init;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.width.SetSize(Z.unit,1);
      p.height.SetSize(Z.unit,1);
    ELSE
      p.width.SetSize(Z.unit,3);
      p.height.SetSize(Z.unit,3);
    END;

    p.hBackground:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.fillColorIndex));
    p.vBackground:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.fillColorIndex));

    p.hImage:=IB.CreateVecImage(VB.none);
    p.vImage:=IB.CreateVecImage(VB.none);
    p.hFrame:=F.CreateFrame(F.none);
    p.vFrame:=F.CreateFrame(F.none);
  END Initialize;

  PROCEDURE (f : FuelGauge) Init*;

  BEGIN
    f.Init^;

    f.SetPrefs(prefs);

    f.current:=NIL;

    f.min:=0;
    f.max:=100;
    f.vertical:=FALSE;

    f.image:=I.CreateImage();
    f.image.SetParent(f);
    f.image.SetFlags({G.horizontalFlex,G.verticalFlex});
  END Init;

  PROCEDURE (f : FuelGauge) SetDirection*(vertical : BOOLEAN);

    (**
      Set the direction of the @otype{FuelGauge}. If @oparam{vertical}
      is @code{TRUE}, it is vertical (from bottom to top),
      else horizontal (from left to right).
    *)

  BEGIN
    f.vertical:=vertical;
  END SetDirection;

  PROCEDURE (f : FuelGauge) SetRange*(min,max : LONGINT);

  (**
    Set the minimal and maximal value the fuel gauge should display.

    NOTE
    The image currently does not cut down the value to the given range,
    so be carefull.
  *)

  BEGIN
    IF (f.min#min) OR (f.max#max) THEN
      f.min:=min;
      f.max:=max;
      IF f.visible THEN
        f.Redraw;
      END;
    END;
  END SetRange;

  PROCEDURE (f : FuelGauge) SetModel*(model : O.Model);

  BEGIN
    IF f.current#NIL THEN
      f.UnattachModel(f.current);
    END;
    IF (model#NIL) & (model IS V.ValueModel) THEN
      f.current:=model(V.ValueModel);
      f.AttachModel(f.current);
      IF f.visible THEN
        f.Redraw;
      END;
    ELSE
      f.current:=NIL;
    END;
  END SetModel;

  PROCEDURE (f : FuelGauge) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=f.current
  END ModelAccepted;


  PROCEDURE (f : FuelGauge) CalcSize*;

  BEGIN
    IF f.vertical THEN
      f.image.SetImage(f.prefs(Prefs).hImage);
      f.image.SetBackgroundObject(f.prefs(Prefs).hBackground);
      f.image.SetObjectFrame(f.prefs(Prefs).hFrame);
    ELSE
      f.image.SetImage(f.prefs(Prefs).vImage);
      f.image.SetBackgroundObject(f.prefs(Prefs).vBackground);
      f.image.SetObjectFrame(f.prefs(Prefs).vFrame);
    END;

    f.image.CalcSize;

    IF f.vertical THEN
      f.minWidth:=U.MaxLong(f.image.oWidth,f.prefs(Prefs).width.GetSize());
      f.width:=U.MaxLong(f.image.oWidth,f.prefs(Prefs).width.GetSize());
      f.minHeight:=f.image.oHeight;
      f.height:=f.image.oHeight;
    ELSE
      f.minWidth:=f.image.oWidth;
      f.width:=f.image.oWidth;
      f.minHeight:=U.MaxLong(f.image.oHeight,f.prefs(Prefs).height.GetSize());
      f.height:=U.MaxLong(f.image.oHeight,f.prefs(Prefs).height.GetSize());
    END;

    f.CalcSize^;
  END CalcSize;

  PROCEDURE (f : FuelGauge) Draw*(x,y,w,h : LONGINT);

  VAR
    size : LONGINT;
    draw : D.DrawInfo;

  BEGIN
    IF ~f.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    f.Draw^(x,y,w,h);

    draw:=f.GetDrawInfo();

    IF f.vertical THEN
      IF f.current#NIL THEN
        size:=((f.height)*f.current.GetLongint()-f.min) DIV (f.max-f.min);
      ELSE
        size:=0;
      END;
      f.DrawBackground(f.x,f.y,f.width,f.height-size);
      f.image.MoveResize(f.x,f.y+f.height-size,f.width,size);
    ELSE
      IF f.current#NIL THEN
        size:=((f.width)*f.current.GetLongint()-f.min) DIV (f.max-f.min);
      ELSE
        size:=0;
      END;
      f.image.MoveResize(f.x,f.y,size,f.height);
      f.DrawBackground(f.x+size,f.y,f.width-size,f.height);
    END;
    f.image.Draw(f.oX,f.oY,f.oWidth,f.oHeight);
  END Draw;

  PROCEDURE (f : FuelGauge) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF f.visible THEN
      f.Redraw;
    END;
  END Resync;

  PROCEDURE CreateFuelGauge*():FuelGauge;

    (**
      Creates a new instance of @otype{FuelGauge}.
    *)

  VAR
    fuelGauge : FuelGauge;

  BEGIN
    NEW(fuelGauge);
    fuelGauge.Init;

    RETURN fuelGauge;
  END CreateFuelGauge;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:FuelGauge.