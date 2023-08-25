MODULE VO:PieChart;

  (**
    A simple pie chart for statistic stuff.
  *)

(*
    A simple pie chart for statistic stuff.
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

       G := VO:Object;

TYPE
  Prefs*        = POINTER TO PrefsDesc;
  PrefsDesc*    = RECORD (G.PrefsDesc)
                  END;

  Value         = POINTER TO ValueDesc;
  ValueDesc     = RECORD
                    (**
                      This holds the values the pie chart displays.
                    *)
                    next  : Value;    (** All values are single linked *)
                    value : LONGREAL; (** The value *)
                  END;

  PieChart*     = POINTER TO PieChartDesc;
  PieChartDesc* = RECORD (G.ImageDesc)
                    (**
                      A simple pie chart for statistic stuff.
                    *)
                    valueList,
                    lastValue  : Value;
                    entries    : LONGINT;
                    total      : LONGREAL;
                  END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : PieChart) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.valueList:=NIL;
    p.lastValue:=NIL;

    p.entries:=0;
    p.total:=100;
  END Init;

  PROCEDURE (p : PieChart) SetTotal*(total : LONGREAL);

  BEGIN
    p.total:=total;
  END SetTotal;

  PROCEDURE (p : PieChart) AddValue*(value : LONGREAL);

  VAR
    entry : Value;

  BEGIN
    NEW(entry);
    entry.value:=value;
    entry.next:=NIL;

    IF p.valueList=NIL THEN
      p.valueList:=entry;
    ELSE
      p.lastValue.next:=entry;
    END;
    p.lastValue:=entry;

    INC(p.entries);
  END AddValue;

  PROCEDURE (p : PieChart) CalcSize*;

  BEGIN
    p.width:=15;
    p.height:=15;

    p.minWidth:=p.width;
    p.minHeight:=p.height;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : PieChart) Draw*(x,y,w,h : LONGINT);

  VAR
    prev,
    arc,
    count,
    entries : LONGINT;
    entry   : Value;
    draw    : D.DrawInfo;

  BEGIN
    IF ~p.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    p.Draw^(x,y,w,h);

    draw:=p.GetDrawInfo();

    p.DrawBackground(p.x,p.y,p.width,p.height);

    draw.PushForeground(D.shadowColor);
    draw.FillArc(p.x,p.y,p.width-1,p.height-1,0*64,360*64);
    draw.PopForeground;

    prev:=0;
    arc:=0;
    entries:=0;
    entry:=p.valueList;
    WHILE entry#NIL DO
      arc:=ENTIER((entry.value*360) / p.total+0.5);
      INC(prev,arc);
      INC(entries);
      entry:=entry.next;
    END;

    IF (entries>=1) & (prev+arc<360) THEN
      INC(entries);
    END;

    prev:=0;
    count:=1;
    entry:=p.valueList;
    WHILE entry#NIL DO
      arc:=ENTIER((entry.value*360) / p.total+0.5);

      draw.PushUniqueFillPattern(count,entries);
      draw.FillArc(p.x,p.y,p.width-1,p.height-1,prev*64,arc*64);
      draw.PopUniqueFillPattern(count,entries);

      INC(prev,arc);
      INC(count);
      entry:=entry.next;
    END;

    draw.PushForeground(D.shadowColor);
    draw.DrawArc(p.x,p.y,p.width,p.height,226*64,180*64);
    draw.PopForeground;
    draw.PushForeground(D.shineColor);
    draw.DrawArc(p.x,p.y,p.width,p.height,45*64,180*64);
    draw.PopForeground;
  END Draw;

  PROCEDURE CreatePieChart*(): PieChart;

  VAR
    pieChart : PieChart;

  BEGIN
    NEW(pieChart);
    pieChart.Init;

    RETURN pieChart;
  END CreatePieChart;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:PieChart.