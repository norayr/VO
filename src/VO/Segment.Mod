(**
   A simple segment display.
**)

MODULE VO:Segment;

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
       U   := VO:Base:Util,

       G   := VO:Object,

       str := Strings;

CONST
  charSpace = 2;

TYPE
  Prefs*       = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc*   = RECORD (G.PrefsDesc)
                 END;

  LineDesc     = RECORD
                   x1,y1,x2,y2 : SHORTINT; (* 0..100 *)
                 END;

  Letter       = POINTER TO ARRAY OF LineDesc;

  Segment*     = POINTER TO SegmentDesc;
  SegmentDesc* = RECORD (G.ImageDesc)
                   foreground : D.Color;
                   chars      : LONGINT;
                   string     : U.Text;
                 END;

VAR
  prefs* : Prefs;
  font-  : ARRAY 256 OF Letter;
  char   : INTEGER;

  PROCEDURE (s : Segment) Init*;

  BEGIN
    s.Init^;

    s.foreground:=D.blackColor;
    s.chars:=1;
    NEW(s.string,2);
  END Init;

  PROCEDURE (s : Segment) SetStringWidth*(width : LONGINT);

  VAR
    help : U.Text;

  BEGIN
    s.chars:=width;
    NEW(help,width+1);
    COPY(s.string^,help^);
    s.string:=help;
  END SetStringWidth;

  (**
    Set the new text to display. Redraws the object if its visible.
  **)

  PROCEDURE (s : Segment) SetString*(string : ARRAY OF CHAR);

  BEGIN
    COPY(string,s.string^);
    IF s.visible THEN
      s.Redraw;
    END;
  END SetString;

  (**
    Set the new text to display widthout redrawing the object.
  **)

  PROCEDURE (s : Segment) StoreString*(string : ARRAY OF CHAR);

  BEGIN
    COPY(string,s.string^);
  END StoreString;

  PROCEDURE (s : Segment) SetForeground*(color : D.Color);

  BEGIN
    s.foreground:=color;
  END SetForeground;

  PROCEDURE (s : Segment) CalcSize*;

  BEGIN
    s.width:=s.chars*D.display.spaceWidth DIV 2+(s.chars-1)*charSpace;
    s.height:=D.display.spaceHeight;

    s.width:=U.MaxLong(s.width,8);
    s.height:=U.MaxLong(s.height,8);

    s.minWidth:=s.width;
    s.minHeight:=s.height;

    s.CalcSize^;
  END CalcSize;

  PROCEDURE (s : Segment) Draw*(x,y,w,h : LONGINT);

  VAR
    pos,start,
    i,charWidth : LONGINT;
    letter      : Letter;
    draw        : D.DrawInfo;

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    draw:=s.GetDrawInfo();

    s.DrawBackground(s.x,s.y,s.width,s.height);

    charWidth:=(s.width-(s.chars-1)*charSpace) DIV s.chars;

    start:=s.x+(s.width-s.chars*charWidth-(s.chars-1)*charSpace) DIV 2;

    draw.PushForeground(s.foreground);
    FOR i:=0 TO str.Length(s.string^)-1 DO
      letter:=font[ORD(s.string[i])];
      IF letter#NIL THEN
        FOR pos:=0 TO LEN(letter^)-1 DO
          draw.DrawLine(start+(letter[pos].x1*(charWidth-1)) DIV 100,
                        s.y+(letter[pos].y1*(s.height-1)) DIV 100,
                        start+(letter[pos].x2*(charWidth-1)) DIV 100,
                        s.y+(letter[pos].y2*(s.height-1)) DIV 100);
        END;
      END;
      INC(start,charWidth+charSpace);
    END;
    draw.PopForeground;
  END Draw;

  PROCEDURE CreateSegment*():Segment;

  VAR
    segment : Segment;

  BEGIN
    NEW(segment);
    segment.Init;

    RETURN segment;
  END CreateSegment;

BEGIN
  NEW(prefs);
  prefs.Init;

  char:=ORD("0");
  NEW(font[char],4);
  font[char][0].x1:=0;
  font[char][0].y1:=0;
  font[char][0].x2:=100;
  font[char][0].y2:=0;

  font[char][1].x1:=100;
  font[char][1].y1:=0;
  font[char][1].x2:=100;
  font[char][1].y2:=100;

  font[char][2].x1:=100;
  font[char][2].y1:=100;
  font[char][2].x2:=0;
  font[char][2].y2:=100;

  font[char][3].x1:=0;
  font[char][3].y1:=100;
  font[char][3].x2:=0;
  font[char][3].y2:=0;

  char:=ORD("1");
  NEW(font[char],1);
  font[char][0].x1:=100;
  font[char][0].y1:=0;
  font[char][0].x2:=100;
  font[char][0].y2:=100;

  char:=ORD("2");
  NEW(font[char],5);
  font[char][0].x1:=0;
  font[char][0].y1:=0;
  font[char][0].x2:=100;
  font[char][0].y2:=0;

  font[char][1].x1:=100;
  font[char][1].y1:=0;
  font[char][1].x2:=100;
  font[char][1].y2:=50;

  font[char][2].x1:=100;
  font[char][2].y1:=50;
  font[char][2].x2:=0;
  font[char][2].y2:=50;

  font[char][3].x1:=0;
  font[char][3].y1:=50;
  font[char][3].x2:=0;
  font[char][3].y2:=100;

  font[char][4].x1:=0;
  font[char][4].y1:=100;
  font[char][4].x2:=100;
  font[char][4].y2:=100;

  char:=ORD("3");
  NEW(font[char],5);
  font[char][0].x1:=0;
  font[char][0].y1:=0;
  font[char][0].x2:=100;
  font[char][0].y2:=0;

  font[char][1].x1:=100;
  font[char][1].y1:=0;
  font[char][1].x2:=100;
  font[char][1].y2:=50;

  font[char][2].x1:=100;
  font[char][2].y1:=50;
  font[char][2].x2:=0;
  font[char][2].y2:=50;

  font[char][3].x1:=100;
  font[char][3].y1:=50;
  font[char][3].x2:=100;
  font[char][3].y2:=100;

  font[char][4].x1:=0;
  font[char][4].y1:=100;
  font[char][4].x2:=100;
  font[char][4].y2:=100;

  char:=ORD("4");
  NEW(font[char],4);
  font[char][0].x1:=0;
  font[char][0].y1:=0;
  font[char][0].x2:=0;
  font[char][0].y2:=50;

  font[char][1].x1:=100;
  font[char][1].y1:=0;
  font[char][1].x2:=100;
  font[char][1].y2:=50;

  font[char][2].x1:=0;
  font[char][2].y1:=50;
  font[char][2].x2:=100;
  font[char][2].y2:=50;

  font[char][3].x1:=100;
  font[char][3].y1:=50;
  font[char][3].x2:=100;
  font[char][3].y2:=100;

  char:=ORD("5");
  NEW(font[char],5);
  font[char][0].x1:=0;
  font[char][0].y1:=0;
  font[char][0].x2:=100;
  font[char][0].y2:=0;

  font[char][1].x1:=0;
  font[char][1].y1:=0;
  font[char][1].x2:=0;
  font[char][1].y2:=50;

  font[char][2].x1:=100;
  font[char][2].y1:=50;
  font[char][2].x2:=0;
  font[char][2].y2:=50;

  font[char][3].x1:=100;
  font[char][3].y1:=50;
  font[char][3].x2:=100;
  font[char][3].y2:=100;

  font[char][4].x1:=0;
  font[char][4].y1:=100;
  font[char][4].x2:=100;
  font[char][4].y2:=100;

  char:=ORD("6");
  NEW(font[char],5);
  font[char][0].x1:=0;
  font[char][0].y1:=50;
  font[char][0].x2:=0;
  font[char][0].y2:=100;

  font[char][1].x1:=0;
  font[char][1].y1:=0;
  font[char][1].x2:=0;
  font[char][1].y2:=50;

  font[char][2].x1:=100;
  font[char][2].y1:=50;
  font[char][2].x2:=0;
  font[char][2].y2:=50;

  font[char][3].x1:=100;
  font[char][3].y1:=50;
  font[char][3].x2:=100;
  font[char][3].y2:=100;

  font[char][4].x1:=0;
  font[char][4].y1:=100;
  font[char][4].x2:=100;
  font[char][4].y2:=100;

  char:=ORD("7");
  NEW(font[char],2);
  font[char][0].x1:=0;
  font[char][0].y1:=0;
  font[char][0].x2:=100;
  font[char][0].y2:=0;

  font[char][1].x1:=100;
  font[char][1].y1:=0;
  font[char][1].x2:=100;
  font[char][1].y2:=100;

  char:=ORD("8");
  NEW(font[char],5);
  font[char][0].x1:=0;
  font[char][0].y1:=0;
  font[char][0].x2:=100;
  font[char][0].y2:=0;

  font[char][1].x1:=0;
  font[char][1].y1:=50;
  font[char][1].x2:=100;
  font[char][1].y2:=50;

  font[char][2].x1:=0;
  font[char][2].y1:=100;
  font[char][2].x2:=100;
  font[char][2].y2:=100;

  font[char][3].x1:=100;
  font[char][3].y1:=0;
  font[char][3].x2:=100;
  font[char][3].y2:=100;

  font[char][4].x1:=0;
  font[char][4].y1:=0;
  font[char][4].x2:=0;
  font[char][4].y2:=100;

  char:=ORD("9");
  NEW(font[char],5);
  font[char][0].x1:=0;
  font[char][0].y1:=0;
  font[char][0].x2:=100;
  font[char][0].y2:=0;

  font[char][1].x1:=0;
  font[char][1].y1:=50;
  font[char][1].x2:=100;
  font[char][1].y2:=50;

  font[char][2].x1:=0;
  font[char][2].y1:=100;
  font[char][2].x2:=100;
  font[char][2].y2:=100;

  font[char][3].x1:=100;
  font[char][3].y1:=0;
  font[char][3].x2:=100;
  font[char][3].y2:=100;

  font[char][4].x1:=0;
  font[char][4].y1:=0;
  font[char][4].x2:=0;
  font[char][4].y2:=50;

  char:=ORD("%");
  NEW(font[char],9);
  font[char][0].x1:=0;
  font[char][0].y1:=100;
  font[char][0].x2:=100;
  font[char][0].y2:=0;

  font[char][1].x1:=0;
  font[char][1].y1:=0;
  font[char][1].x2:=0;
  font[char][1].y2:=20;

  font[char][2].x1:=0;
  font[char][2].y1:=20;
  font[char][2].x2:=20;
  font[char][2].y2:=20;

  font[char][3].x1:=20;
  font[char][3].y1:=20;
  font[char][3].x2:=0;
  font[char][3].y2:=20;

  font[char][4].x1:=0;
  font[char][4].y1:=20;
  font[char][4].x2:=0;
  font[char][4].y2:=0;

  font[char][5].x1:=80;
  font[char][5].y1:=80;
  font[char][5].x2:=80;
  font[char][5].y2:=100;

  font[char][6].x1:=80;
  font[char][6].y1:=100;
  font[char][6].x2:=100;
  font[char][6].y2:=100;

  font[char][7].x1:=100;
  font[char][7].y1:=100;
  font[char][7].x2:=80;
  font[char][7].y2:=100;

  font[char][8].x1:=80;
  font[char][8].y1:=100;
  font[char][8].x2:=80;
  font[char][8].y2:=80;

  char:=ORD(":");
  NEW(font[char],8);
  font[char][0].x1:=44;
  font[char][0].y1:=25;
  font[char][0].x2:=56;
  font[char][0].y2:=25;

  font[char][1].x1:=56;
  font[char][1].y1:=25;
  font[char][1].x2:=56;
  font[char][1].y2:=38;

  font[char][2].x1:=56;
  font[char][2].y1:=38;
  font[char][2].x2:=44;
  font[char][2].y2:=38;

  font[char][3].x1:=44;
  font[char][3].y1:=38;
  font[char][3].x2:=44;
  font[char][3].y2:=25;

  font[char][4].x1:=44;
  font[char][4].y1:=62;
  font[char][4].x2:=56;
  font[char][4].y2:=62;

  font[char][5].x1:=56;
  font[char][5].y1:=62;
  font[char][5].x2:=56;
  font[char][5].y2:=75;

  font[char][6].x1:=56;
  font[char][6].y1:=75;
  font[char][6].x2:=44;
  font[char][6].y2:=75;

  font[char][7].x1:=44;
  font[char][7].y1:=75;
  font[char][7].x2:=44;
  font[char][7].y2:=62;

  char:=ORD(".");
  NEW(font[char],4);
  font[char][0].x1:=89;
  font[char][0].y1:=88;
  font[char][0].x2:=100;
  font[char][0].y2:=88;

  font[char][1].x1:=100;
  font[char][1].y1:=88;
  font[char][1].x2:=100;
  font[char][1].y2:=100;

  font[char][2].x1:=100;
  font[char][2].y1:=100;
  font[char][2].x2:=89;
  font[char][2].y2:=100;

  font[char][3].x1:=89;
  font[char][3].y1:=100;
  font[char][3].x2:=89;
  font[char][3].y2:=88;
END VO:Segment.