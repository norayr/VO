(**
   Just some amount of invisible space hidden in the endless
   number of dimensions of the univers.
**)

MODULE VO:Space;

(*
    Implements a "space" object.
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

IMPORT Z := VO:Base:Size,
       G := VO:Object;

CONST
  micro*  = 1;
  small*  = 2;
  normal* = 3;
  huge*   = 4;

TYPE
  Prefs*     = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  Space*     = POINTER TO SpaceDesc;
  SpaceDesc* = RECORD (G.ImageDesc)
                 vert : BOOLEAN;
                 size : LONGINT;
               END;
VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hSize.SetSize(Z.unit,1);
    p.vSize.SetSize(Z.unit,1);
  END Initialize;

  PROCEDURE (s : Space) Init*;

  BEGIN
    s.Init^;

    s.SetPrefs(prefs);

    s.vert:=FALSE;
    s.size:=normal;
  END Init;


  PROCEDURE (s : Space) Set*(vert : BOOLEAN; size : LONGINT);

  BEGIN
    s.vert:=vert;
    s.size:=size;
  END Set;

  PROCEDURE (s : Space) CalcSize*;

  BEGIN
    s.width:=0;
    s.height:=0;

    IF s.vert THEN
      CASE s.size OF
        micro:
          s.height:=s.prefs(Prefs).vSize.GetSize() DIV 4;
      | small:
          s.height:=s.prefs(Prefs).vSize.GetSize() DIV 2;
      | normal:
          s.height:=s.prefs(Prefs).vSize.GetSize();
      | huge:
          s.height:=2*s.prefs(Prefs).vSize.GetSize();
      END;

      IF s.height=0 THEN
        s.height:=1;
      END;
    ELSE
      CASE s.size OF
        micro:
          s.width:=s.prefs(Prefs).hSize.GetSize() DIV 4;
      | small:
          s.width:=s.prefs(Prefs).hSize.GetSize() DIV 2;
      | normal:
          s.width:=s.prefs(Prefs).hSize.GetSize();
      | huge:
          s.width:=2*s.prefs(Prefs).hSize.GetSize();
      END;

      IF s.width=0 THEN
        s.width:=1;
      END;
    END;

    s.minWidth:=s.width;
    s.minHeight:=s.height;

    s.CalcSize^;
  END CalcSize;

  PROCEDURE (s : Space) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    s.DrawBackground(s.x,s.y,s.width,s.height);
  END Draw;

  PROCEDURE CreateSpace*():Space;

  VAR
    space : Space;

  BEGIN
    NEW(space);
    space.Init;

    RETURN space;
  END CreateSpace;

  PROCEDURE CreateHSpace*():Space;

  VAR
    space : Space;

  BEGIN
    space:=CreateSpace();
    space.Set(FALSE,normal);
    space.SetFlags({G.verticalFlex});

    RETURN space;
  END CreateHSpace;

  PROCEDURE CreateVSpace*():Space;

  VAR
    space : Space;

  BEGIN
    space:=CreateSpace();
    space.Set(TRUE,normal);
    space.SetFlags({G.horizontalFlex});

    RETURN space;
  END CreateVSpace;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Space.