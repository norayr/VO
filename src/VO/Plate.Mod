MODULE VO:Plate;

  (**
    Implements @otype{Plate}.
  *)

  (*
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
       Z  := VO:Base:Size,

       G  := VO:Object;


TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hSpace*,
                 vSpace* : Z.SizeDesc;
               END;

  Plate*     = POINTER TO PlateDesc;
  PlateDesc* = RECORD (G.LayoutDesc)
                 (**
                   A simple group with one child. The group just puts a
                   little bit, defineable space around the object. Usefull,
                   if you want an object enbedded with a little space and
                   with background color set.
                   **)
                 object      : G.Object;
                 horizSpace,
                 vertSpace   : LONGINT;
               END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.backgroundColorIndex));

    p.hSpace.Init;
    p.vSpace.Init;
    p.hSpace.SetSize(Z.unitP,50);
    p.vSpace.SetSize(Z.unitP,50);
  END Initialize;

  PROCEDURE (p : Plate) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.object:=NIL;
  END Init;

  PROCEDURE (p : Plate) VisitChildren*(VAR visitor : G.VisitorDesc;
                                       onlyVisible : BOOLEAN):BOOLEAN;

  BEGIN
    IF p.object#NIL THEN
      IF ~visitor.Visit(p.object) THEN
        RETURN FALSE;
      END;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (p : Plate) Add*(object : G.Object);

    (**
      Add the object to present.

      NOTE
      Plate only support one object. Repeatetly calling
      add will overwrite this object with the new one.
    *)

  BEGIN
    p.object:=object;
    p.object.SetParent(p);
  END Add;

  PROCEDURE (p : Plate) CalcSize*;

  BEGIN
    p.horizSpace:=2*p.prefs(Prefs).hSpace.GetSize();
    p.vertSpace:=2*p.prefs(Prefs).vSpace.GetSize();

    p.width:=p.horizSpace;
    p.height:=p.vertSpace;

    IF p.object#NIL THEN
      p.object.CalcSize;
      INC(p.width,p.object.oWidth);
      INC(p.height,p.object.oHeight);
    END;

    p.minWidth:=p.width;
    p.minHeight:=p.height;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : Plate) Layout*;

  BEGIN
    IF p.object#NIL THEN
      p.object.Resize(p.width-p.horizSpace,
                      p.height-p.vertSpace);
      p.object.Move(p.x+(p.width-p.object.oWidth) DIV 2,
                    p.y+(p.height-p.object.oHeight) DIV 2);
    END;

    p.Layout^;
  END Layout;

  PROCEDURE CreatePlate*():Plate;

  VAR
    plate : Plate;

  BEGIN
    NEW(plate);
    plate.Init;

    RETURN plate;
  END CreatePlate;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Plate.