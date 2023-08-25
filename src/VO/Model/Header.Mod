MODULE VO:Model:Header;

  (**
    A model for describing columns or rows.
  *)

(*
    A model for describing columns or rows.
    Copyright (C) 2000 Tim Teulings (rael@edge.ping.de)

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

IMPORT O   := VO:Base:Object,
       Z   := VO:Base:Size;

TYPE
  HeaderModel*       = POINTER TO HeaderModelDesc;
  HeaderModelDesc*   = RECORD (O.ModelDesc)
                       END;

  EntryDesc          = RECORD
                         label : STRING;
                         size  : Z.Size;
                       END;

  Entries            = POINTER TO ARRAY OF EntryDesc;

  AHeaderModel*      = POINTER TO AHeaderModelDesc;
  AHeaderModelDesc*  = RECORD (HeaderModelDesc)
                         entries : Entries;
                         sColumn : LONGINT;
                       END;

  ResizedColumn*     = POINTER TO ResizedColumnDesc;
  ResizedColumnDesc* = RECORD (O.ResyncMsgDesc)
                         (**
                           If send, a column has been resized and the view should refresh that column.
                         *)
                         column* : LONGINT;
                       END;

  FitColumn*         = POINTER TO FitColumnDesc;
  FitColumnDesc*     = RECORD (O.ResyncMsgDesc)
                         (**
                           If send, the view is requested to fit the width of the
                           column, so that all entries are completely visible.
                         *)
                         column* : LONGINT;
                       END;

  PROCEDURE (h : HeaderModel) Init*;

  BEGIN
    h.Init^;
  END Init;

  PROCEDURE (h : HeaderModel) GetEntries*():LONGINT;

  BEGIN
    RETURN 0;
  END GetEntries;

  PROCEDURE (h : HeaderModel) SetLabelSize*(index,mode,size : LONGINT);

  BEGIN
  END SetLabelSize;

  PROCEDURE (h : HeaderModel) GetLabelSize*(index : LONGINT):LONGINT;

  BEGIN
    RETURN 0;
  END GetLabelSize;

  PROCEDURE (h : HeaderModel) GetLabel*(x : LONGINT):STRING;

  BEGIN
    RETURN NIL;
  END GetLabel;

  PROCEDURE (h : HeaderModel) SetSortColumn*(x : LONGINT);

  BEGIN
  END SetSortColumn;

  PROCEDURE (h : HeaderModel) ClearSortColumn*;

  BEGIN
  END ClearSortColumn;

  PROCEDURE (h : HeaderModel) IsSortColumn*(x : LONGINT):BOOLEAN;

  BEGIN
    RETURN FALSE;
  END IsSortColumn;

  PROCEDURE (h : HeaderModel) RequestFit*(column : LONGINT);

    (**
      Send @otype{FitColumnDesc} to view to request the view to resize
      the referenced @oparam{column} so that all entries are completely
      visible.
    *)

  VAR
    msg : FitColumn;

  BEGIN
    NEW(msg);
    msg.column:=column;
    h.Notify(msg);
  END RequestFit;



  PROCEDURE (h : AHeaderModel) Init*;

  BEGIN
    h.Init^;

    h.entries:=NIL;
    h.sColumn:=-1;
  END Init;

  PROCEDURE (h : AHeaderModel) GetEntries*():LONGINT;

  BEGIN
    IF h.entries=NIL THEN
      RETURN 0;
    ELSE
      RETURN LEN(h.entries^);
    END;
  END GetEntries;

  PROCEDURE (h : AHeaderModel) GetLabelSize*(index : LONGINT):LONGINT;

  BEGIN
    IF (h.entries=NIL) OR (index>=LEN(h.entries^)) THEN
      RETURN 0;
    ELSE
      RETURN h.entries[index].size.GetSize();
    END;
  END GetLabelSize;

  PROCEDURE (h : AHeaderModel) GetLabel*(index : LONGINT):STRING;

  BEGIN
    IF (h.entries=NIL) OR (index>=LEN(h.entries^)) THEN
      RETURN NIL;
    ELSE
       RETURN h.entries[index].label;
     END;
  END GetLabel;

  PROCEDURE (h : AHeaderModel) CreateEntries(size : LONGINT);

  VAR
    old : Entries;
    x   : LONGINT;

  BEGIN
    IF (h.entries=NIL) OR (size>LEN(h.entries^)) THEN
      old:=h.entries;

      NEW(h.entries,size);
      x:=0;
      IF old#NIL THEN
        WHILE x<LEN(old^) DO
          h.entries[x]:=old[x];
          INC(x);
        END;
      END;

      WHILE x<LEN(h.entries^) DO
        h.entries[x].size:=Z.CreateSize();
        h.entries[x].label:=NIL;
        INC(x);
      END;
    END;
  END CreateEntries;

  PROCEDURE (h : AHeaderModel) SetLabel*(index : LONGINT; label : STRING);

  BEGIN
    h.CreateEntries(index+1);
    h.entries[index].label:=label;
    h.Notify(NIL);
  END SetLabel;

  PROCEDURE (h : AHeaderModel) SetLabelSize*(index,mode,size : LONGINT);

  VAR
    msg : ResizedColumn;

  BEGIN
    h.CreateEntries(index+1);
    h.entries[index].size.SetSize(mode,size);

    NEW(msg);
    msg.column:=index;
    h.Notify(msg);
  END SetLabelSize;

  PROCEDURE (h : AHeaderModel) SetSortColumn*(x : LONGINT);

  BEGIN
    h.sColumn:=x;
  END SetSortColumn;

  PROCEDURE (h : AHeaderModel) ClearSortColumn*;

  BEGIN
    h.sColumn:=-1;
  END ClearSortColumn;

  PROCEDURE (h : AHeaderModel) IsSortColumn*(x : LONGINT):BOOLEAN;

  BEGIN
    RETURN h.sColumn=x;
  END IsSortColumn;

END VO:Model:Header.