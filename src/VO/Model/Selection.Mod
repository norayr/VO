MODULE VO:Model:Selection[OOC_EXTENSIONS];

  (**
    Implements models for selections in a one or two dimensional array.
    Used within VO:Model:Table and VO:Table.

  *)

  (*
    Implements models for selections in a one or two dimensional array.
    Used within VO:Model:Table and VO:Table.

    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

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

IMPORT O   := VO:Base:Object;

CONST
  lineBased* = 0;
  cellBased* = 1;

TYPE
  Selection*            = POINTER TO SelectionDesc;
  SelectionDesc*        = RECORD [ABSTRACT] (O.ModelDesc)
                            type- : LONGINT;
                          END;

  None*                 = POINTER TO NoneDesc;
  NoneDesc*             = RECORD (SelectionDesc)
                          END;

  SingleLine*           = POINTER TO SingleLineDesc;
  SingleLineDesc*       = RECORD (SelectionDesc)
                            line- : LONGINT;
                          END;

  SingleCell*           = POINTER TO SingleCellDesc;
  SingleCellDesc*       = RECORD( SelectionDesc)
                            column-,
                            row-     : LONGINT;
                          END;

  RefreshCell*          = POINTER TO RefreshCellDesc;
  RefreshCellDesc*      = RECORD (O.ResyncMsgDesc)
                            column-,
                            row-     : LONGINT;
                          END;

  RefreshRow*           = POINTER TO RefreshRowDesc;
  RefreshRowDesc*       = RECORD (O.ResyncMsgDesc)
                            line- : LONGINT;
                          END;

  Selected*             = POINTER TO SelectedDesc;
  SelectedDesc*         = RECORD (O.ResyncMsgDesc)
                          END;

  (* ---------------------------------------- *)

  PROCEDURE (s : Selection) Init*;

    (**
      Method to initialize a @otype{Selection}-Object. call this method
      before any othe rright after allocation.
    *)

  BEGIN
    s.Init^;

    s.type:=lineBased;
  END Init;

  PROCEDURE (s : Selection) [ABSTRACT] HasSelection*():BOOLEAN;

    (**
      Returns @code{TRUE} if a selection exists.
    *)

  END HasSelection;

  PROCEDURE (s : Selection) [ABSTRACT] IsCellSelected*(column,row : LONGINT):BOOLEAN;

    (**
      Return @code{TRUE} if the given cell is selected.
    *)

  END IsCellSelected;

  PROCEDURE (s : Selection) [ABSTRACT] IsLineSelected*(line : LONGINT):BOOLEAN;

    (**
      Return @code{TRUE} if the given line is selected.
    *)

  END IsLineSelected;

  PROCEDURE (s : Selection) [ABSTRACT] Clear*;

    (**
      Clears the current selction if available.
    *)

  END Clear;

  PROCEDURE (s : Selection) [ABSTRACT] OnLineDeleted*(line : LONGINT);

    (**
      Call this method if a given line has been deleted.
    *)

  END OnLineDeleted;

  PROCEDURE (s : Selection) [ABSTRACT] OnClear*;

    (**
      Call this method if the complete list has been deleted.
    *)

  END OnClear;

  PROCEDURE (s : Selection) [ABSTRACT] SelectCell*(column,row : LONGINT);

    (**
      Call this method if a given cell has been selecte dvia the GUI.
    *)

  END SelectCell;

  PROCEDURE (s : Selection) SendCellRefresh(column, row : LONGINT);

  VAR
    msg : RefreshCell;

  BEGIN
    NEW(msg);

    msg.column:=column;
    msg.row:=row;

    s.Notify(msg);
  END SendCellRefresh;

  PROCEDURE (s : Selection) SendLineRefresh(line : LONGINT);

  VAR
    msg : RefreshRow;

  BEGIN
    NEW(msg);

    msg.line:=line;

    s.Notify(msg);
  END SendLineRefresh;

  PROCEDURE (s : Selection) SendSelected;

  VAR
    msg : Selected;

  BEGIN
    NEW(msg);
    s.Notify(msg);
  END SendSelected;

  (* ---------------------------------------- *)

  PROCEDURE (s : None) HasSelection*():BOOLEAN;

  BEGIN
    RETURN FALSE;
  END HasSelection;

  PROCEDURE (s : None) IsCellSelected*(column, row : LONGINT):BOOLEAN;

  BEGIN
    ASSERT((column>0) & (row>0));

    RETURN FALSE;
  END IsCellSelected;

  PROCEDURE (s : None) IsLineSelected*(line : LONGINT):BOOLEAN;

  BEGIN
    ASSERT(line>0);

    RETURN FALSE;
  END IsLineSelected;

  PROCEDURE (s : None) Clear*;

  BEGIN
    (* no code *)
  END Clear;

  PROCEDURE (s : None) OnLineDeleted*(line : LONGINT);

  BEGIN
    (* no code *)
  END OnLineDeleted;

  PROCEDURE (s : None) OnClear*;

  BEGIN
    (* no code *)
  END OnClear;

  PROCEDURE (s : None) SelectCell*(column,row : LONGINT);

  BEGIN
    (* no code *)
  END SelectCell;

  PROCEDURE CreateNone*():None;

  VAR
    none : None;

  BEGIN
    NEW(none);
    none.Init;

    RETURN none;
  END CreateNone;

  (* ---------------------------------------- *)

  PROCEDURE (s : SingleLine) Init*;

  BEGIN
    s.Init^;

    s.type:=lineBased;

    s.line:=-1;
  END Init;

  PROCEDURE (s : SingleLine) HasSelection*():BOOLEAN;

  BEGIN
    RETURN s.line>0;
  END HasSelection;

  PROCEDURE (s : SingleLine) IsCellSelected*(column, row : LONGINT):BOOLEAN;

  BEGIN
    ASSERT((column>0) & (row>0));

    RETURN row=s.line;
  END IsCellSelected;

  PROCEDURE (s : SingleLine) IsLineSelected*(line : LONGINT):BOOLEAN;

  BEGIN
    ASSERT(line>0);

    RETURN line=s.line;
  END IsLineSelected;

  PROCEDURE (s : SingleLine) Clear*;

  VAR
    old : LONGINT;

  BEGIN
    IF s.line>0 THEN
      old:=s.line;
      s.line:=-1;
      s.SendLineRefresh(old);
    END;
  END Clear;

  PROCEDURE (s : SingleLine) OnLineDeleted*(line : LONGINT);

  BEGIN
    IF line<s.line THEN
      (* correct index *)
      DEC(s.line);
    ELSIF line=s.line THEN
      s.line:=-1;
    END;
  END OnLineDeleted;

  PROCEDURE (s : SingleLine) OnClear*;

  BEGIN
    s.line:=-1;
  END OnClear;

  PROCEDURE (s : SingleLine) SelectLine*(line : LONGINT);

  VAR
    old : LONGINT;

  BEGIN
    ASSERT(line>0);

    IF s.line#line THEN
      old:=s.line;
      s.line:=line;
      s.SendLineRefresh(old);
      s.SendLineRefresh(s.line);
      s.SendSelected;
    END;
  END SelectLine;

  PROCEDURE (s : SingleLine) SelectCell*(column,row : LONGINT);

  BEGIN
    s.SelectLine(row);
  END SelectCell;

  PROCEDURE CreateSingleLine*():SingleLine;

  VAR
    singleLine : SingleLine;

  BEGIN
    NEW(singleLine);
    singleLine.Init;

    RETURN singleLine;
  END CreateSingleLine;

  (* ---------------------------------------- *)

  PROCEDURE (s : SingleCell) Init*;

  BEGIN
    s.Init^;

    s.type:=cellBased;

    s.column:=-1;
    s.row:=-1;
  END Init;

  PROCEDURE (s : SingleCell) HasSelection*():BOOLEAN;

  BEGIN
    RETURN (s.column>0) & (s.row>0);
  END HasSelection;

  PROCEDURE (s : SingleCell) IsCellSelected*(column, row : LONGINT):BOOLEAN;

  BEGIN
    ASSERT((column>0) & (row>0));

    RETURN (column=s.column) & (row=s.row);
  END IsCellSelected;

  PROCEDURE (s : SingleCell) IsLineSelected*(line : LONGINT):BOOLEAN;

  BEGIN
    ASSERT(line>0);

    RETURN FALSE;
  END IsLineSelected;

  PROCEDURE (s : SingleCell) Clear*;

  VAR
    oldColumn,
    oldRow : LONGINT;

  BEGIN
    IF (s.column>0) & (s.row>0) THEN
      oldColumn:=s.column;
      oldRow:=s.row;

      s.column:=-1;
      s.row:=-1;

      s.SendCellRefresh(oldColumn,oldRow);
    END;
  END Clear;

  PROCEDURE (s : SingleCell) OnLineDeleted*(line : LONGINT);

  BEGIN
    IF line<s.row THEN
      (* correct index *)
      DEC(s.row);
    ELSIF line=s.row THEN
      s.column:=-1;
      s.row:=-1;
    END;
  END OnLineDeleted;

  PROCEDURE (s : SingleCell) OnClear*;

  BEGIN
    s.column:=-1;
    s.row:=-1;
  END OnClear;

  PROCEDURE (s : SingleCell) SelectCell*(column,row : LONGINT);

  VAR
    oldColumn,
    oldRow : LONGINT;

  BEGIN
    ASSERT((column>0) & (row>0));

    IF (column#s.column) OR (row#s.row) THEN
      oldColumn:=s.column;
      oldRow:=s.row;

      s.column:=column;
      s.row:=row;

      s.SendCellRefresh(oldColumn,oldRow);
      s.SendCellRefresh(s.column,s.row);
      s.SendSelected;
    END;
  END SelectCell;

  PROCEDURE CreateSingleCell*():SingleCell;

  VAR
    singleCell : SingleCell;

  BEGIN
    NEW(singleCell);
    singleCell.Init;

    RETURN singleCell;
  END CreateSingleCell;

END VO:Model:Selection.