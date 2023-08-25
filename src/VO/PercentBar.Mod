MODULE VO:PercentBar;

  (**
    A simple percentage visualisation control.
  **)

(*
    A simple percentage visualisation controls.
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

  PercentBar*     = POINTER TO PercentBarDesc;
  PercentBarDesc* = RECORD (G.ImageDesc)
                      (**
                        A simple percentage visualisation control.
                      **)
                    valueList,
                    lastValue  : Value;
                    entries    : LONGINT;
                    total      : LONGREAL;
                  END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.frame:=F.CreateFrame(F.w95IO);
  END Initialize;


  PROCEDURE (p : PercentBar) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.valueList:=NIL;
    p.lastValue:=NIL;

    p.entries:=0;
    p.total:=100;
  END Init;

  PROCEDURE (p : PercentBar) SetTotal*(total : LONGREAL);

  BEGIN
    p.total:=total;
  END SetTotal;

  PROCEDURE (p : PercentBar) AddValue*(value : LONGREAL);

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

  PROCEDURE (p : PercentBar) CalcSize*;

  BEGIN
    p.width:=5*D.display.spaceHeight; (* TODO: We should make e better estimation *)
    p.height:=2*D.display.spaceHeight;

    p.minWidth:=p.width;
    p.minHeight:=p.height;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : PercentBar) Draw*(x,y,w,h : LONGINT);

  VAR
    sum     : LONGREAL;
    prev,
    current,
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

    sum:=0;
    entries:=0;
    entry:=p.valueList;
    WHILE entry#NIL DO
      sum:=sum+entry.value;
      INC(entries);
      entry:=entry.next;
    END;

    IF sum<p.total THEN
      INC(entries);
    END;

    prev:=0;
    count:=1;
    entry:=p.valueList;
    WHILE entry#NIL DO
      current:=ENTIER(p.width*(entry.value/p.total)+0.5);

      draw.PushUniqueFillPattern(count,entries);
      draw.FillRectangle(p.x+prev,p.y,current,p.height);
      draw.PopUniqueFillPattern(count,entries);

      INC(prev,current);
      INC(count);
      entry:=entry.next;
    END;

    IF prev<p.width THEN
      draw.PushForeground(D.shadowColor);
      draw.FillRectangle(p.x+prev,p.y,p.width-prev,p.height);
      draw.PopForeground;
    END;
  END Draw;

  PROCEDURE CreatePercentBar*(): PercentBar;

  VAR
    percentBar : PercentBar;

  BEGIN
    NEW(percentBar);
    percentBar.Init;

    RETURN percentBar;
  END CreatePercentBar;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:PercentBar.