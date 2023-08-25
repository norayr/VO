MODULE VO:Line;

  (**
    Implements @otype{Line}.
  *)

  (*
    Implemnets a line.
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

IMPORT I  := VO:Base:Image,
       VB := VO:Base:VecImage,

       G  := VO:Object;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hLine*,
                 vLine* : I.Image;
               END;

  Line*      = POINTER TO LineDesc;
  LineDesc*  = RECORD (G.ObjectDesc)
                 (**
                   Simply draws vertical or horizontal lines. Usefull for visually
                   seperating groups of objects. There is extra space added.
                 *)
                 vert  : BOOLEAN;
                 image : I.Image;
                 size  : SHORTINT;
               END;

VAR
  prefs : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hLine:=I.CreateVecImage(VB.hLineIn3D);
    p.vLine:=I.CreateVecImage(VB.vLineIn3D);
  END Initialize;

  PROCEDURE (l : Line) Init*;

  BEGIN
    l.Init^;

    l.SetPrefs(prefs);

    l.vert:=FALSE;
    l.size:=100;
    l.image:=NIL;
  END Init;

  PROCEDURE ( l : Line) Set*(vert : BOOLEAN; size : SHORTINT);

  (**
    Specify direction (vertical or horizontal) and the size of the line.
    Size spezifies the size of the line within its bounds in procent. E.g.,
    if you specify 50 the line will always have half the size of its bounds.
    The line will be displayed centered withing its bounds will be displayed
    centered.
  *)

  BEGIN
    l.vert:=vert;
    IF (l.size<=0) OR (l.size>100) THEN
      l.size:=100;
    ELSE
      l.size:=size;
    END;
  END Set;

  PROCEDURE (l : Line) CalcSize*;

  BEGIN
    IF l.vert THEN
      l.image:=l.prefs(Prefs).vLine;
    ELSE
      l.image:=l.prefs(Prefs).hLine;
    END;
    l.minWidth:=l.image.width;
    l.minHeight:=l.image.height;

    IF l.vert THEN
      l.maxWidth:=l.minWidth;
    ELSE
      l.maxHeight:=l.minHeight;
    END;

    l.width:=l.minWidth;
    l.height:=l.minHeight;

    l.CalcSize^;
  END CalcSize;
(*
  PROCEDURE (l : Line) Layout*;

  BEGIN
    IF l.vert THEN
      l.image.Resize(l.width,(l.height*l.size) DIV 100);
    ELSE
      l.image.Resize((l.width*l.size) DIV 100,l.height);
    END;
    l.image.Move(l.x+(l.width-l.image.oWidth) DIV 2,
                 l.y+(l.height-l.image.oHeight) DIV 2);

    l.Layout^;
  END Layout;
*)
  PROCEDURE (l : Line) Draw*(x,y,w,h : LONGINT);

  VAR
    start,
    length : LONGINT;

  BEGIN
    IF ~l.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    l.Draw^(x,y,w,h);

    IF l.vert THEN
      length:=(l.height*l.size) DIV 100;
      start:=l.y+(l.height-length) DIV 2;
      IF length<l.height THEN
        l.DrawBackground(l.x,l.y,l.width,start-l.y);
        l.DrawBackground(l.x,
                         start+length,
                         l.width,
                         l.height-length-(start-l.y));
      END;
      l.image.Draw(l.GetDrawInfo(),l.x,start,l.width,length);
    ELSE
      length:=(l.width*l.size) DIV 100;
      start:=l.x+(l.width-length) DIV 2;
      IF length<l.width THEN
        l.DrawBackground(l.x,l.y,start-l.x,l.height);
        l.DrawBackground(start+length,l.y,l.width-length-(start-l.x),l.height);
      END;
      l.image.Draw(l.GetDrawInfo(),start,l.y,length,l.height);
    END;
  END Draw;

  PROCEDURE CreateLine*():Line;

    (**
      Creates a new instance of @otype{Line}.
    *)

  VAR
    line : Line;

  BEGIN
    NEW(line);
    line.Init;

    RETURN line;
  END CreateLine;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Line.