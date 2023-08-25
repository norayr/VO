MODULE VO:ColorArea;

  (**
    Implements @otype{ColorArea}.
  *)

(*
    Implements a colored area.
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

IMPORT D := VO:Base:Display,
       F := VO:Base:Frame,

       O := VO:Object;

TYPE
  Prefs*         = POINTER TO PrefsDesc;
  PrefsDesc*     = RECORD (O.PrefsDesc)
                   END;


  ColorArea*     = POINTER TO ColorAreaDesc;
  ColorAreaDesc* = RECORD (O.ImageDesc)
                     (**
                       Just a plain area with a given color. Usefull for a
                       button image, when you want some kind of palette button.
                     *)
                     color : D.Color;
                   END;

VAR
  prefs : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.none);
    ELSE
      p.frame:=F.CreateFrame(F.double);
    END;
  END Initialize;

  PROCEDURE (c : ColorArea) Init*;

  BEGIN
    c.Init^;

    c.SetPrefs(prefs);

    c.color:=D.textColor;
  END Init;

  PROCEDURE (c : ColorArea) SetColor*(color : D.Color);

  (**
    Sets the color of the area.
  *)


  BEGIN
    c.color:=color;
    IF c.visible THEN
      c.Redraw;
    END;
  END SetColor;

  PROCEDURE (c : ColorArea) CalcSize*;

  BEGIN
    IF D.display.displayType=D.displayTypeTextual THEN
      c.width:=1;
      c.height:=1;
    ELSE
      c.width:=4;
      c.height:=4;
    END;
    c.minWidth:=c.width;
    c.minHeight:=c.height;

    c.CalcSize^;
  END CalcSize;

  PROCEDURE (c : ColorArea) Draw* (x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~c.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    c.Draw^(x,y,w,h);

    draw:=c.GetDrawInfo();

    draw.PushForeground(c.color);
    draw.FillRectangle(c.x,c.y,c.width,c.height);
    draw.PopForeground;
  END Draw;

  PROCEDURE CreateColorArea*():ColorArea;

    (**
      Creates a new instance of @otype{ColorArea}.
    *)

  VAR
    colorArea : ColorArea;

  BEGIN
    NEW(colorArea);
    colorArea.Init;

    RETURN colorArea;
  END CreateColorArea;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:ColorArea.