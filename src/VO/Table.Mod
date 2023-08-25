(**
   Implements full featured table on top of VOTableView..
**)

MODULE VO:Table;

(*
   Implements full featured table on top of VOTableView..
    Copyright (C) 2000  Tim Teulings (rael@edge.ping.de)

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

IMPORT D  := VO:Base:Display,
       F  := VO:Base:Frame,
       O  := VO:Base:Object,

       G  := VO:Object,
       GR := VO:Grid,
       H  := VO:Header,
       PL := VO:Panel,
       S  := VO:Scroller,
       T  := VO:TableView;


CONST
(*  repeatTimeOut = 75000;*) (* Time between button repeat *)

TYPE
  Prefs*     = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the cycle is stored.
  **)


  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  Table*     = POINTER TO TableDesc;
  TableDesc* = RECORD (G.LayoutDesc)
                 grid     : GR.Grid;
                 table-   : T.Table;

                 header,
                 hScroll,
                 vScroll  : BOOLEAN;
               END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.single);
    ELSE
      p.frame:=F.CreateFrame(F.double3DIn);
    END;
  END Initialize;


  PROCEDURE (t : Table) Init*;

  BEGIN
    t.Init^;

    t.SetPrefs(prefs);

    t.grid:=NIL;

    t.header:=FALSE;
    t.hScroll:=TRUE;
    t.vScroll:=TRUE;

    t.table:=T.CreateTable();
    t.table.SetFlags({G.horizontalFlex,G.verticalFlex});
  END Init;

  PROCEDURE (t : Table) SetCustomTable*(table : T.Table);

    (**
      Assign a cutsom instance for the internal table object.
    *)

  BEGIN
    t.table:=table;
    t.table.SetFlags({G.horizontalFlex,G.verticalFlex});
  END SetCustomTable;

  PROCEDURE (t : Table) VisitChildren*(VAR visitor : G.VisitorDesc;
                                       onlyVisible : BOOLEAN):BOOLEAN;

  BEGIN
    IF t.grid#NIL THEN
      IF ~visitor.Visit(t.grid) THEN
        RETURN FALSE;
      END;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (t : Table) SetShowHeader*(header : BOOLEAN);

  BEGIN
    t.header:=header;
  END SetShowHeader;

  PROCEDURE (t : Table) SetShowScroller*(hScroll,vScroll : BOOLEAN);

  BEGIN
    t.hScroll:=hScroll;
    t.vScroll:=vScroll;
  END SetShowScroller;

  PROCEDURE (t : Table) SetModel*(model : O.Model);

  BEGIN
    t.table.SetModel(model);
  END SetModel;

  (**
    This function is used to check if an argument to SetModel
    was successfully accepted.
   **)

  PROCEDURE (t : Table) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN t.table.ModelAccepted(m);
  END ModelAccepted;

  PROCEDURE (t : Table) CalcSize*;

  VAR
    panel    : PL.Panel;
    header   : H.Header;
    scroller : S.Scroller;

  BEGIN
    header:=NIL;

    t.grid:=GR.CreateGrid();
    t.grid.SetParent(t);
    t.grid.SetFlags({G.horizontalFlex,G.verticalFlex});

    IF t.hScroll THEN
      t.grid.SetGridSize(2,2);
    ELSE
      t.grid.SetGridSize(2,1);
    END;

    panel:=PL.CreateVPanel();
    panel.SetFlags({G.horizontalFlex,G.verticalFlex});

    IF t.header THEN
      header:=H.CreateHeader();
      header.SetFlags({G.horizontalFlex});

      IF t.table.model#NIL THEN
        header.SetModel(t.table.model.header);
      END;
      header.SetAdjustment(t.table.hAdjustment);
      panel.Add(header);
    END;

    panel.Add(t.table);
    t.grid.SetObject(0,0,panel);

    IF t.vScroll THEN
      scroller:=S.CreateVScroller();
      scroller.SetFlags({G.verticalFlex});
      scroller.SetModel(t.table.vAdjustment);
    t.grid.SetObject(1,0,scroller);
    END;

    IF t.hScroll THEN
      scroller:=S.CreateHScroller();
      scroller.SetFlags({G.horizontalFlex});
      scroller.SetModel(t.table.hAdjustment);
    t.grid.SetObject(0,1,scroller);
    END;

    IF t.HasFocusRequested() THEN
      (* Delegate focusing to the real table *)
      t.table.RequestFocus();
      t.UnrequestFocus();
    END;

    t.grid.CalcSize;

    t.minWidth:=t.grid.oMinWidth;
    t.minHeight:=t.grid.oMinHeight;

    t.width:=t.grid.oWidth;
    t.height:=t.grid.oHeight;

    t.CalcSize^;
  END CalcSize;

  PROCEDURE (t : Table) Layout*;

  BEGIN
    t.grid.MoveResize(t.x,t.y,t.width,t.height);

    t.Layout^;
  END Layout;

  PROCEDURE CreateTable*():Table;

  VAR
    table : Table;

  BEGIN
    NEW(table);
    table.Init;

    RETURN table;
  END CreateTable;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Table.