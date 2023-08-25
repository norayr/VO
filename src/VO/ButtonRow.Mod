MODULE VO:ButtonRow;

  (**
    Implements @otype{ButtonRow}
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
       U := VO:Base:Util,
       Z := VO:Base:Size,

       G := VO:Object;


TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 space*     : Z.SizeDesc;
                 alignment* : LONGINT;
               END;

  ButtonRow*     = POINTER TO ButtonRowDesc;
  ButtonRowDesc* = RECORD(G.GroupDesc)
                     (**
                       A layout group enummerates a number of buttons horizontaly.
                     *)
                     buttonWidth : LONGINT;
                   END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.space.Init;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.space.SetSize(Z.unit,1);
    ELSE
      p.space.SetSize(Z.softUnit,1);
    END;
    p.alignment:=G.alignRight;
  END Initialize;

  PROCEDURE (b : ButtonRow) Init*;

  BEGIN
    b.Init^;

    b.SetPrefs(prefs);

    b.buttonWidth:=0;
  END Init;

  PROCEDURE (b : ButtonRow) CalcSize*;

  VAR
    object : G.Object;

  BEGIN
    b.width:=0;
    b.height:=0;

    object:=b.list;
    WHILE object#NIL DO
      object.CalcSize;
      b.height:=U.MaxLong(b.height,object.oHeight);
      b.buttonWidth:=U.MaxLong(b.buttonWidth,object.oWidth);

      object:=object.next;
    END;

    IF b.count>0 THEN
      b.width:=b.count*b.buttonWidth+(b.count-1)*b.prefs(Prefs).space.GetSize();
    ELSE
      b.width:=0;
    END;
    b.minWidth:=b.width;
    b.minHeight:=b.height;

    b.CalcSize^;
  END CalcSize;

  PROCEDURE (b : ButtonRow) Layout*;

  VAR
    object : G.Object;
    pos,
    count  : LONGINT;

  BEGIN
    CASE b.prefs(Prefs).alignment OF
      G.alignLeft:
        pos:=b.x;
        object:=b.list;
        WHILE object#NIL DO
          object.MoveResize(pos,b.y + (b.height-object.oHeight) DIV 2,
                            b.buttonWidth,b.height);
          INC(pos,object.oWidth+b.prefs(Prefs).space.GetSize());

          object:=object.next;
        END;
    | G.alignRight:
        pos:=b.x+b.width-b.count*b.buttonWidth-(b.count-1)*b.prefs(Prefs).space.GetSize();
        object:=b.list;
        WHILE object#NIL DO
          object.MoveResize(pos,b.y + (b.height-object.oHeight) DIV 2,
                            b.buttonWidth,b.height);
          INC(pos,object.oWidth+b.prefs(Prefs).space.GetSize());

          object:=object.next;
        END;
    | G.alignCenter:
        pos:=b.x+(b.width-b.count*b.buttonWidth-(b.count-1)*b.prefs(Prefs).space.GetSize()) DIV 2;
        object:=b.list;
        WHILE object#NIL DO
          object.MoveResize(pos,b.y + (b.height-object.oHeight) DIV 2,
                            b.buttonWidth,b.height);
          INC(pos,object.oWidth+b.prefs(Prefs).space.GetSize());

          object:=object.next;
        END;
    | G.alignBound:
        pos:=b.x;
        count:=1;
        object:=b.list;
        WHILE object#NIL DO
          object.MoveResize(pos,b.y + (b.height-object.oHeight) DIV 2,
                            b.buttonWidth,b.height);

          IF count<b.count THEN
            INC(pos,object.oWidth);
            INC(pos,(b.width-(pos-b.x)-(b.count-count)*b.buttonWidth)  DIV (b.count-count));
          END;

          INC(count);
          object:=object.next;
        END;
    END;

    b.Layout^;
  END Layout;

  PROCEDURE CreateButtonRow*():ButtonRow;

    (**
      Creates a new instance of @otype{ButtonRow}.
    *)

  VAR
    buttonRow : ButtonRow;

  BEGIN
    NEW(buttonRow);
    buttonRow.Init;

    RETURN buttonRow;
  END CreateButtonRow;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:ButtonRow.