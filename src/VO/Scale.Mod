MODULE VO:Scale;

  (**
    A control that draws a scale for a given area over its complete
    with (if horizontal) or height (if vertical).

    This is for example usefull for a slider or similar widget.
  *)

(*
    A scale for numerical intervals.
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

IMPORT  D   := VO:Base:Display,
        U   := VO:Base:Util,
        Z   := VO:Base:Size,

        G   := VO:Object,

        co  := IntStr,
        str := Strings;

CONST
  minScaleInterval = 3;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hSpace*,
                 vSpace* : Z.SizeDesc;
               END;

  Scale*     = POINTER TO ScaleDesc;
  ScaleDesc* = RECORD (G.ImageDesc)
                 from,
                 to       : LONGINT;
                 fromText,
                 toText   : U.Text;
                 fromExt,
                 toExt    : D.FontExtentDesc;
                 vert     : BOOLEAN;
               END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hSpace.Init;
    p.vSpace.Init;
    p.hSpace.SetSize(Z.unit,1);
    p.vSpace.SetSize(Z.unit,1);

    IF D.display.displayType=D.displayTypeTextual THEN
      p.hSize.SetSize(Z.unit,1);
      p.vSize.SetSize(Z.unit,1);
      p.hSpace.SetSize(Z.unit,0);
      p.vSpace.SetSize(Z.unit,0);
    ELSE
      p.hSize.SetSize(Z.unit,3);
      p.vSize.SetSize(Z.unit,3);
    END;
  END Initialize;

  PROCEDURE (s : Scale) Init*;

  BEGIN
    s.Init^;

    s.SetPrefs(prefs);

    s.vert:=FALSE;

    s.from:=0;
    s.to:=100;

    s.fromText:=NIL;
    s.toText:=NIL;
  END Init;

  PROCEDURE (s : Scale) SetDirection*(vertical : BOOLEAN);

    (**
      Define, if you want a vertical or horizontal scale.
    *)

  BEGIN
    s.vert:=vertical;
  END SetDirection;

  PROCEDURE (s : Scale) SetInterval*(from, to : LONGINT);

    (**
      Set the range the scale should go. For example 0,100 for a procentual
      scale.
    *)

  BEGIN
    s.from:=from;
    s.to:=to;
  END SetInterval;

  PROCEDURE (s : Scale) CalcSize*;

  VAR
    buffer : ARRAY 100 OF CHAR;

  BEGIN
    IF s.vert THEN
      s.width:=s.prefs(Prefs).hSize.GetSize();
      s.height:=5;
    ELSE
      s.width:=5;
      s.height:=s.prefs(Prefs).vSize.GetSize();
    END;

    co.IntToStr(s.from,buffer);
    NEW(s.fromText,str.Length(buffer)+1);
    COPY(buffer,s.fromText^);

    co.IntToStr(s.to,buffer);
    NEW(s.toText,str.Length(buffer)+1);
    COPY(buffer,s.toText^);

    D.normalFont.TextExtent(s.fromText^,LEN(s.fromText^)-1,{},s.fromExt);
    D.normalFont.TextExtent(s.toText^,LEN(s.toText^)-1,{},s.toExt);

    IF s.vert THEN
      INC(s.width,U.MaxLong(s.fromExt.width,s.toExt.width)+
          s.prefs(Prefs).hSpace.GetSize());
    ELSE
      INC(s.height,U.MaxLong(s.fromExt.height,s.toExt.height)+
          s.prefs(Prefs).vSpace.GetSize());
    END;

    s.minWidth:=s.width;
    s.minHeight:=s.height;

    s.CalcSize^;
  END CalcSize;

  PROCEDURE (s : Scale) GetExp(number : LONGINT):LONGINT;

    (**
      Calculates log10 number.
    *)

  VAR
    exp : LONGINT;

  BEGIN
    exp:=0;

    WHILE number DIV 10 > 0 DO
      number:=number DIV 10;
      INC(exp);
    END;

    RETURN exp;
  END GetExp;

  PROCEDURE (s : Scale) Pow10(exp : LONGINT):LONGINT;

    (**
      Calculates 10^exp
    *)

  VAR
    x : LONGINT;

  BEGIN
    x:=1;
    WHILE exp>0 DO
      x:=x*10;
      DEC(exp);
    END;
    RETURN x;
  END Pow10;

  PROCEDURE (s : Scale) Draw*(x,y,w,h : LONGINT);

  VAR
    interval,
    exp,
    max,pos,
    mark,int,
    off,
    width,
    height    : LONGINT;
    draw      : D.DrawInfo;

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    draw:=s.GetDrawInfo();

    s.DrawBackground(s.x,s.y,s.width,s.height);

    interval:=s.to-s.from;

    exp:=s.GetExp(interval);
    max:=exp;

    draw.PushForeground(D.textColor);

    IF s.vert THEN
      off:=U.MaxLong(s.fromExt.width,s.toExt.width)+s.prefs(Prefs).hSpace.GetSize();
      IF D.shineColor#D.shadowColor THEN
        width:=s.height-2;
      ELSE
        width:=s.height-1;
      END;
      height:=s.width-off;
    ELSE
      off:=U.MaxLong(s.fromExt.height,s.toExt.height)+s.prefs(Prefs).vSpace.GetSize();
      IF D.shineColor#D.shadowColor THEN
        width:=s.width-2;
      ELSE
        width:=s.width-1;
      END;
      height:=s.height-off;
    END;

    WHILE (exp>=0) & ((width*s.Pow10(exp)) DIV interval>minScaleInterval) DO
      int:=s.Pow10(exp);
      mark:=(s.from DIV int)*int;

      WHILE mark<=s.to DO
        IF (mark>=s.from) & ( (exp=max) OR (mark MOD s.Pow10(exp+1)#0) ) THEN
          IF s.vert THEN
            pos:=width*(mark-s.from) DIV interval;
            draw.PushForeground(D.shadowColor);
            draw.DrawLine(s.x+off+height-(height DIV (max-exp+1)),s.y+pos,
                          s.x+off+height-1,s.y+pos);
            draw.PopForeground;
            IF D.shineColor#D.shadowColor THEN
              draw.PushForeground(D.shineColor);
              draw.DrawLine(s.x+off+height-(height DIV (max-exp+1)),s.y+pos+1,
                            s.x+off+height-1,s.y+pos+1);
              draw.PopForeground;
            END;
          ELSE
            pos:=width*(mark-s.from) DIV interval;
            draw.PushForeground(D.shadowColor);
            draw.DrawLine(s.x+pos,s.y+off+height-(height DIV (max-exp+1)),
                          s.x+pos,s.y+off+height-1);
            draw.PopForeground;
            IF D.shineColor#D.shadowColor THEN
              draw.PushForeground(D.shineColor);
              draw.DrawLine(s.x+pos+1,s.y+off+height-(height DIV (max-exp+1)),
                            s.x+pos+1,s.y+off+height-1);
              draw.PopForeground;
            END;
          END;

        END;
        INC(mark,int);
      END;
      DEC(exp);
    END;

    draw.PushFont(D.normalFont,{});
    IF s.vert THEN
      draw.DrawString(s.x,s.y+s.height-1,s.fromText^,LEN(s.fromText^)-1);
      draw.DrawString(s.x,s.y+D.normalFont.ascent,s.toText^,LEN(s.toText^)-1);
    ELSE
      draw.DrawString(s.x,s.y+D.normalFont.ascent,s.fromText^,LEN(s.fromText^)-1);
      draw.DrawString(s.x+s.width-s.toExt.width,s.y+D.normalFont.ascent,s.toText^,LEN(s.toText^)-1);
    END;
    draw.PopFont;

    draw.PopForeground;
  END Draw;

  PROCEDURE CreateScale*():Scale;

  VAR
    scale : Scale;

  BEGIN
    NEW(scale);
    scale.Init;

    RETURN scale;
  END CreateScale;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Scale.