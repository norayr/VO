(**
   A simple segment display.
**)

MODULE VO:Segment7;

(*
    A simple segment display.
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

IMPORT D   := VO:Base:Display,

       G   := VO:Object;

CONST
  zero*   =    0;
  one*    =    1;
  two*    =    2;
  three*  =    3;
  four*   =    4;
  five*   =    5;
  six*    =    6;
  seven*  =    7;
  eight*  =    8;
  nine*   =    9;
  line*   =   10;
  none*   =   11;

  images  = 1000;

  double* = 1000;


TYPE
  Prefs*        = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc*    = RECORD (G.PrefsDesc)
                  END;

  Coords        = ARRAY 7,6 OF LONGINT;
  Digits        = ARRAY 12 OF SET;

  Segment7*     = POINTER TO Segment7Desc;
  Segment7Desc* = RECORD (G.ImageDesc)
                    onColor,
                    offColor : D.Color;
                    value    : LONGINT;
                  END;

VAR
  prefs* : Prefs;
  kx,ky  : Coords;
  d      : Digits;

  PROCEDURE (s : Segment7) Init*;

  BEGIN
    s.Init^;

    s.onColor:=D.blackColor;
    s.offColor:=D.backgroundColor;
    s.value:=line;
  END Init;

  PROCEDURE (s : Segment7) DrawSegment;

  VAR
    dx,dy,
    i,j,
    xp,yp  : LONGINT;
    points : ARRAY 7 OF D.PointDesc;
    draw   : D.DrawInfo;

  BEGIN
    draw:=s.GetDrawInfo();

    IF s.value<images THEN
      dx:=s.width DIV 10;
      dy:=s.height DIV 18;

      xp:=s.x+(s.width-dx*10) DIV 2;
      yp:=s.y+(s.height-dy*18) DIV 2;

      FOR i:=0 TO 6 DO
        IF i IN d[s.value] THEN
          draw.PushForeground(s.onColor);
        ELSE
          draw.PushForeground(s.offColor);
        END;
        points[0].x:=SHORT(xp+dx*kx[i][0]);
        points[0].y:=SHORT(yp+dy*ky[i][0]);
        FOR j:=1 TO 5 DO
          points[j].x:=SHORT(xp+dx*kx[i][j]);
          points[j].y:=SHORT(yp+dy*ky[i][j]);
        END;
        points[6].x:=SHORT(xp+dx*kx[i][0]);
        points[6].y:=SHORT(yp+dy*ky[i][0]);
        draw.FillPolygon(points,7);
        draw.PopForeground;
      END;
  (*    draw.DrawLine(s.x,s.y+0,    s.x+10*dx,s.y+10*dy);
      draw.DrawLine(s.x,s.y+8*dy, s.x+10*dx,s.y+18*dy);
      draw.DrawLine(s.x,s.y+10*dy,s.x+10*dx,s.y);
      draw.DrawLine(s.x,s.y+18*dy,s.x+10*dx,s.y+8*dy);*)
    ELSE
      CASE s.value OF
        double:
          draw.PushForeground(s.onColor);
          draw.FillRectangle(s.x+s.width DIV 3,s.y+s.height DIV 5,
                             s.width DIV 3, s.height DIV 5);
          draw.FillRectangle(s.x+s.width DIV 3,s.y+s.height-1-2*(s.height DIV 5),
                             s.width DIV 3, s.height DIV 5);
          draw.PopForeground;
      END;
    END;
  END DrawSegment;

  PROCEDURE (s : Segment7) SetOnColor*(color : D.Color);

  BEGIN
    s.onColor:=color;
    IF s.visible THEN
      s.DrawSegment;
    END;
  END SetOnColor;

  PROCEDURE (s : Segment7) SetOffColor*(color : D.Color);

  BEGIN
    s.offColor:=color;
    IF s.visible THEN
      s.DrawSegment;
    END;
  END SetOffColor;

  PROCEDURE (s : Segment7) SetValue*(value : LONGINT);

  BEGIN
    IF s.value#value THEN
      s.value:=value;
      IF s.visible THEN
        s.DrawSegment;
      END;
    END;
  END SetValue;

  PROCEDURE (s : Segment7) CalcSize*;

  BEGIN
(*    s.width:=3*display.spaceWidth;
    s.height:=5*display.spaceHeight;*)

    s.width:=10;
    s.height:=18;

    s.minWidth:=s.width;
    s.minHeight:=s.height;

    s.CalcSize^;
  END CalcSize;

  PROCEDURE (s : Segment7) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    s.DrawBackground(s.x,s.y,s.width,s.height);

    s.DrawSegment;
  END Draw;

  PROCEDURE CreateSegment7*():Segment7;

  VAR
    segment7 : Segment7;

  BEGIN
    NEW(segment7);
    segment7.Init;

    RETURN segment7;
  END CreateSegment7;

BEGIN
  NEW(prefs);
  prefs.Init;

  kx[0,0]:=1;
  kx[0,1]:=2;
  kx[0,2]:=8;
  kx[0,3]:=9;
  kx[0,4]:=8;
  kx[0,5]:=2;

  kx[1,0]:=9;
  kx[1,1]:=10;
  kx[1,2]:=10;
  kx[1,3]:=9;
  kx[1,4]:=8;
  kx[1,5]:=8;

  kx[2,0]:=9;
  kx[2,1]:=10;
  kx[2,2]:=10;
  kx[2,3]:=9;
  kx[2,4]:=8;
  kx[2,5]:=8;

  kx[3,0]:=1;
  kx[3,1]:=2;
  kx[3,2]:=8;
  kx[3,3]:=9;
  kx[3,4]:=8;
  kx[3,5]:=2;

  kx[4,0]:=1;
  kx[4,1]:=2;
  kx[4,2]:=2;
  kx[4,3]:=1;
  kx[4,4]:=0;
  kx[4,5]:=0;

  kx[5,0]:=1;
  kx[5,1]:=2;
  kx[5,2]:=2;
  kx[5,3]:=1;
  kx[5,4]:=0;
  kx[5,5]:=0;

  kx[6,0]:=1;
  kx[6,1]:=2;
  kx[6,2]:=8;
  kx[6,3]:=9;
  kx[6,4]:=8;
  kx[6,5]:=2;

  ky[0,0]:=1;
  ky[0,1]:=0;
  ky[0,2]:=0;
  ky[0,3]:=1;
  ky[0,4]:=2;
  ky[0,5]:=2;

  ky[1,0]:=1;
  ky[1,1]:=2;
  ky[1,2]:=8;
  ky[1,3]:=9;
  ky[1,4]:=8;
  ky[1,5]:=2;

  ky[2,0]:=9;
  ky[2,1]:=10;
  ky[2,2]:=16;
  ky[2,3]:=17;
  ky[2,4]:=16;
  ky[2,5]:=10;

  ky[3,0]:=17;
  ky[3,1]:=16;
  ky[3,2]:=16;
  ky[3,3]:=17;
  ky[3,4]:=18;
  ky[3,5]:=18;

  ky[4,0]:=9;
  ky[4,1]:=10;
  ky[4,2]:=16;
  ky[4,3]:=17;
  ky[4,4]:=16;
  ky[4,5]:=10;

  ky[5,0]:=1;
  ky[5,1]:=2;
  ky[5,2]:=8;
  ky[5,3]:=9;
  ky[5,4]:=8;
  ky[5,5]:=2;

  ky[6,0]:=9;
  ky[6,1]:=8;
  ky[6,2]:=8;
  ky[6,3]:=9;
  ky[6,4]:=10;
  ky[6,5]:=10;

  d[ 0]:={0,1,2,3,4,5};
  d[ 1]:={1,2};
  d[ 2]:={0,1,3,4,6};
  d[ 3]:={0,1,2,3,6};
  d[ 4]:={1,2,5,6};
  d[ 5]:={0,2,3,5,6};
  d[ 6]:={0,2,3,4,5,6};
  d[ 7]:={0,1,2};
  d[ 8]:={0,1,2,3,4,5,6};
  d[ 9]:={0,1,2,3,5,6};
  d[10]:={6};
  d[11]:={};

END VO:Segment7.