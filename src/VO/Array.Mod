MODULE VO:Array;

  (**
    Implements @otype{Array}.
  *)

  (*
    Implements a grid like layouting group.
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

IMPORT U := VO:Base:Util,
       Z := VO:Base:Size,

       G := VO:Object;


TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hSpace*,
                 vSpace* : Z.SizeDesc;
               END;


  Array*     = POINTER TO ArrayDesc;
  ArrayDesc* = RECORD(G.GroupDesc)
                 (**
                   A layout group that arranges all it children in an
                   two-dimensional array.
                 *)
                 sWidth,
                 sHeight     : LONGINT;
                 horiz,
                 vert        : LONGINT;
                 horizSpace,
                 vertSpace   : BOOLEAN;
               END;

VAR
  prefs* : Prefs;

  PROCEDURE Count(Zahl, Div : LONGINT):LONGINT;

  BEGIN
    IF Zahl MOD Div#0 THEN
      RETURN (Zahl DIV Div)+1;
    ELSE
      RETURN Zahl DIV Div;
    END;
  END Count;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hSpace.Init;
    p.vSpace.Init;
    p.hSpace.SetSize(Z.unit,1);
    p.vSpace.SetSize(Z.unit,1);
  END Initialize;

  PROCEDURE (a : Array) Init*;

  BEGIN
    a.Init^;

    a.SetPrefs(prefs);

    a.horizSpace:=FALSE;
    a.vertSpace:=FALSE;
  END Init;

  PROCEDURE (a : Array) Set*(count : LONGINT; horiz : BOOLEAN);

    (**
      Set the number of rows or coloums depending on the value
      of @oparam{horiz}.
    *)

  BEGIN
    IF horiz THEN
      a.horiz:=count;
      a.vert:=0;
    ELSE
      a.horiz:=0;
      a.vert:=count;
    END;
  END Set;

  PROCEDURE (a : Array) SetHorizontalSpace*(space : BOOLEAN);

    (**
      Defines, if there should be horizontal space between
      the elements or not.
    *)

  BEGIN
    a.horizSpace:=space;
  END SetHorizontalSpace;

  PROCEDURE (a : Array) SetVerticalSpace*(space : BOOLEAN);

    (**
      Defines, if there should be vertical space between
      the elements or not.
    *)

  BEGIN
    a.vertSpace:=space;
  END SetVerticalSpace;

  PROCEDURE (a : Array) SetSpace*(horiz, vert : BOOLEAN);

    (**
      Defines, if there should be horizontal or vertical spaces between
      the elements or not.
    *)

  BEGIN
    a.horizSpace:=horiz;
    a.vertSpace:=vert;
  END SetSpace;

  PROCEDURE (a : Array) CalcSize*;

  VAR
    object  : G.Object;
    x,y     : LONGINT;
    mw,mh   : LONGINT;

  BEGIN
    a.sWidth:=0;
    a.sHeight:=0;
    mw:=0;
    mh:=0;
    object:=a.list;
    WHILE object#NIL DO

      object.CalcSize;

      a.sWidth:=U.MaxLong(a.sWidth,object.oWidth);
      a.sHeight:=U.MaxLong(a.sHeight,object.oHeight);
      mw:=U.MaxLong(mw,object.oMinWidth);
      mh:=U.MaxLong(mh,object.oMinHeight);

      object:=object.next;
    END;

    IF a.horiz#0 THEN
      IF a.horizSpace THEN
        y:=(a.horiz-1)*a.prefs(Prefs).hSpace.GetSize();
      ELSE
        y:=0;
      END;
      a.width:=a.horiz*a.sWidth+y;
      a.minWidth:=a.horiz*mw+y;

      x:=Count(a.count,a.horiz);
      IF a.vertSpace THEN
        y:=(x-1)*a.prefs(Prefs).vSpace.GetSize();
      ELSE
        y:=0;
      END;
      a.height:=x*a.sHeight+y;
      a.minHeight:=x*mh+y;

    ELSE
      IF a.vertSpace THEN
        y:=(a.vert-1)*a.prefs(Prefs).vSpace.GetSize();
      ELSE
        y:=0;
      END;
      a.height:=a.vert*a.sHeight+y;
      a.minHeight:=a.vert*mh+y;

      x:=Count(a.count,a.vert);
      IF a.horizSpace THEN
        y:=(x-1)*a.prefs(Prefs).hSpace.GetSize();
      ELSE
        y:=0;
      END;
      a.width:=x*a.sWidth+y;
      a.minWidth:=x*mw+y;
    END;

    a.CalcSize^;
  END CalcSize;

  PROCEDURE (a : Array) Layout*;

  VAR
    hCount,
    vCount    : LONGINT;
    object    : G.Object;
    xp,yp,h,w,
    xPos,yPos : LONGINT;

  BEGIN
    IF a.horiz#0 THEN
      hCount:=a.horiz;
      vCount:=Count(a.count,a.horiz);
    ELSE
      hCount:=Count(a.count,a.vert);
      vCount:=a.vert;
    END;

    IF a.horizSpace THEN
      h:=(hCount-1)*a.prefs(Prefs).hSpace.GetSize();
    ELSE
      h:=0;
    END;
    a.sWidth:=(a.width-h) DIV hCount;

    IF a.vertSpace THEN
      w:=(vCount-1)*a.prefs(Prefs).vSpace.GetSize();
    ELSE
      w:=0;
    END;
    a.sHeight:=(a.height-w) DIV vCount;

    object:=a.list;
    WHILE object#NIL DO
      object.Resize(a.sWidth,a.sHeight);
      object:=object.next;
    END;

    xPos:=1;
    yPos:=1;
    xp:=a.x+(a.width-hCount*a.sWidth-w) DIV 2;
    yp:=a.y+(a.height-vCount*a.sHeight-h) DIV 2;
    object:=a.list;
    WHILE object#NIL DO
      object.Move(xp + (a.sWidth-object.oWidth) DIV 2,
                  yp + (a.sHeight-object.oHeight) DIV 2);

      IF (xPos=hCount) & (vCount#yPos) THEN
        IF a.vertSpace THEN
          INC(yp,a.prefs(Prefs).vSpace.GetSize());
        END;
        INC(yp,a.sHeight);
        INC(yPos);
        xPos:=1;
        xp:=a.x+(a.width-hCount*a.sWidth-w) DIV 2;
      ELSIF hCount#xPos THEN
        IF a.horizSpace THEN
          INC(xp,a.prefs(Prefs).hSpace.GetSize());
        END;
        INC(xp,a.sWidth);
        INC(xPos);
      END;

      object:=object.next;
    END;

    a.Layout^;
  END Layout;

  PROCEDURE CreateArray*(): Array;

    (**
      Creates a new instance of @otype{Array}.
    *)

  VAR
    array : Array;

  BEGIN
    NEW(array);
    array.Init;

    RETURN array;
  END CreateArray;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Array.