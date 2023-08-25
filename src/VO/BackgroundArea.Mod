MODULE VO:BackgroundArea;

  (**
    Implements @otype{BackgroundArea}.
  *)

(*
    Implements a colored area.
    Copyright (C) 2002 Tim Teulings (rael@edge.ping.de)

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


  BackgroundArea*     = POINTER TO BackgroundAreaDesc;
  BackgroundAreaDesc* = RECORD (O.ImageDesc)
                          (**
                            Implements an object that draws a empty area using a
                            defined background. Usefull for a button image,
                            when you want some kind of palette button.
                          *)
                          background : O.Background;
                        END;

VAR
  prefs : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.frame:=F.CreateFrame(F.double);
  END Initialize;

  PROCEDURE (c : BackgroundArea) Init*;

  BEGIN
    c.Init^;

    c.SetPrefs(prefs);

    c.background:=NIL;
  END Init;

  PROCEDURE (c : BackgroundArea) SetBackground*(background : O.Background);

    (**
      Set the color the object should have..
    *)

  BEGIN
    IF background#NIL THEN
      c.background:=background.Copy();
    ELSE
      c.background :=NIL;
    END;

    IF c.visible THEN
      c.Redraw;
    END;
  END SetBackground;

  PROCEDURE (c : BackgroundArea) CalcSize*;

  BEGIN
    c.width:=4;
    c.height:=4;
    c.minWidth:=c.width;
    c.minHeight:=c.height;

    c.CalcSize^;
  END CalcSize;

  PROCEDURE (c : BackgroundArea) Draw* (x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~c.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    c.Draw^(x,y,w,h);

    draw:=c.GetDrawInfo();

    IF c.background#NIL THEN
      c.background.DrawRelObject(draw,c,c.x,c.y,c.width,c.height);
    ELSE
      c.DrawBackground(c.x,c.y,c.width,c.height);
      draw.PushForeground(D.blackColor);
      draw.DrawLine(c.x,c.y,c.x+c.width-1,c.y+c.height-1);
      draw.DrawLine(c.x+c.width-1,c.y,c.x,c.y+c.height-1);
      draw.PopForeground;
    END;
  END Draw;

  PROCEDURE CreateBackgroundArea*():BackgroundArea;

    (**
      Creates a new instance of @otype{BackgroundArea}.
    *)

  VAR
    backgroundArea : BackgroundArea;

  BEGIN
    NEW(backgroundArea);
    backgroundArea.Init;

    RETURN backgroundArea;
  END CreateBackgroundArea;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:BackgroundArea.