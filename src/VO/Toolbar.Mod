MODULE VO:Toolbar;

  (**
    Implements @otype{Toolbar}.
  *)

  (*
    A layout group, that layouts a number of buttons horizontaly.
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


IMPORT D := VO:Base:Display,
       F := VO:Base:Frame,
       U := VO:Base:Util,

       G := VO:Object;


TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 equalSize* : BOOLEAN;
               END;

  Toolbar*     = POINTER TO ToolbarDesc;
  ToolbarDesc* = RECORD(G.GroupDesc)
                   (**
                     A special group object for toolbar buttons.
                   *)
                   mWidth : LONGINT;
                 END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.none);
    ELSE
      p.frame:=F.CreateFrame(F.single3DOut);
    END;
    p.equalSize:=TRUE;
  END Initialize;

  PROCEDURE (t : Toolbar) Init*;

  BEGIN
    t.Init^;

    t.SetPrefs(prefs);

    t.mWidth:=0;
  END Init;

  PROCEDURE (t : Toolbar) CalcSize*;

  VAR
    object : G.Object;

  BEGIN
    t.width:=0;
    t.height:=0;

    t.mWidth:=0;

    object:=t.list;
    WHILE object#NIL DO
      object.CalcSize;
      t.height:=U.MaxLong(t.height,object.oHeight);
      t.mWidth:=U.MaxLong(t.mWidth,object.oWidth);
      INC(t.width,object.oWidth);

      object:=object.next;
    END;

    IF t.prefs(Prefs).equalSize THEN
      t.width:=t.count*t.mWidth;
    END;

    t.minWidth:=t.width;
    t.minHeight:=t.height;

    t.CalcSize^;
  END CalcSize;

  PROCEDURE (t : Toolbar) Layout*;

  VAR
    object : G.Object;
    pos    : LONGINT;

  BEGIN
    pos:=t.x;
    object:=t.list;
    WHILE object#NIL DO
      IF t.prefs(Prefs).equalSize THEN
        object.Resize(t.mWidth,t.height);
      ELSE
        object.Resize(-1,t.height);
      END;
      object.Move(pos,t.y + (t.height-object.oHeight) DIV 2);
      INC(pos,object.oWidth);
      object:=object.next;
    END;

    t.Layout^;
  END Layout;

  PROCEDURE CreateToolbar*():Toolbar;

  VAR
    toolbar : Toolbar;

  BEGIN
    NEW(toolbar);
    toolbar.Init;

    RETURN toolbar;
  END CreateToolbar;

BEGIN
  NEW(prefs);
  prefs.Init;

END VO:Toolbar.