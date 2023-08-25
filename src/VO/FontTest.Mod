MODULE VO:FontTest;

  (**
    Only for testing. Do not use!
  *)

  (*
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

IMPORT D   := VO:Base:Display,

       G   := VO:Object,

       str := Strings,
              Err;

CONST
  text = "Ä This is a good Jest";
  xOff = 20;
  yOff = 20;


TYPE
  Prefs*        = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc*    = RECORD (G.PrefsDesc)
                  END;

  FontTest*     = POINTER TO FontTestDesc;
  FontTestDesc* = RECORD (G.ImageDesc)
                  END;

VAR
  prefs : Prefs;

  PROCEDURE (d : FontTest) Init*;

  BEGIN
    d.Init^;
  END Init;

  PROCEDURE (d : FontTest) CalcSize*;

  VAR
    font  : D.Font;
    width : LONGINT;

  BEGIN
    font:=D.normalFont;
    d.width:=font.TextWidth(text,str.Length(text),{})+2*xOff;
    d.height:=font.height+2*yOff;

    d.minWidth:=d.width;
    d.minHeight:=d.height;

    d.CalcSize^;
  END CalcSize;

  PROCEDURE (d : FontTest) Draw*(x,y,w,h : LONGINT);

  VAR
    draw   : D.DrawInfo;
    font   : D.Font;
    extent : D.FontExtentDesc;
    width  : LONGINT;

  BEGIN
    IF ~d.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    d.Draw^(x,y,w,h);

    draw:=d.GetDrawInfo();

    font:=D.normalFont;

    width:=font.TextWidth(text,str.Length(text),{});
    font.TextExtent(text,str.Length(text),{},extent);

    Err.String("font height: "); Err.LongInt(font.height,0); Err.Ln;
    Err.String("font ascent: "); Err.LongInt(font.ascent,0); Err.Ln;
    Err.String("font descent: "); Err.LongInt(font.descent,0); Err.Ln;
    Err.String("string width: "); Err.LongInt(width,0); Err.Ln;

    Err.String("ex. width: "); Err.LongInt(extent.width,0); Err.Ln;
    Err.String("ex. height: "); Err.LongInt(extent.height,0); Err.Ln;
    Err.String("ex. lbearing: "); Err.LongInt(extent.lbearing,0); Err.Ln;
    Err.String("ex. rbearing: "); Err.LongInt(extent.rbearing,0); Err.Ln;
    Err.String("ex. ascent: "); Err.LongInt(extent.ascent,0); Err.Ln;
    Err.String("ex. descent: "); Err.LongInt(extent.descent,0); Err.Ln;

    (* Background *)
    d.DrawBackground(d.x,d.y,d.width,d.height);

    draw.PushForeground(D.whiteColor);

    (* top *)
    draw.DrawLine(d.x+xOff,d.y+yOff,d.x+xOff+width-1,d.y+yOff);

    (* bottom *)
    draw.DrawLine(d.x+xOff,d.y+yOff+font.height-1,d.x+xOff+width-1,d.y+yOff+font.height-1);

    (* left *)
    draw.DrawLine(d.x+xOff,d.y+yOff,d.x+xOff,d.y+yOff+font.height-1);

    (* right *)
    draw.DrawLine(d.x+xOff+width-1,d.y+yOff,d.x+xOff+width-1,d.y+yOff+font.height-1);
    draw.PopForeground;

    draw.PushFont(font,{});
    draw.PushForeground(D.blackColor);

    draw.DrawString(d.x+xOff-extent.lbearing,d.y+yOff+font.ascent,text,str.Length(text));

    draw.PopForeground;
    draw.PopFont;
  END Draw;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:FontTest.