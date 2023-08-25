MODULE VO:Model:Table;

  (**
    A model for table-like data. This is an abstract baseclass. It just
    defines an interface which must be implemented by derived models.

    A database modl f.e. would directly work on the result set. Other
    model may work on lists as internal datarepresentation. These models may
    implement additional methods for direct access or for adding and removing
    lines or data.
  *)

  (*
    A model for table-like data.
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

IMPORT        SYSTEM,
       O   := VO:Base:Object,
       U   := VO:Base:Util,

       HM  := VO:Model:Header,
       SM  := VO:Model:Selection,

       G   := VO:Object,

       co  := IntStr,
              Object,
       str := Strings;

CONST
  leftAlign       * = 0;
  centerAlign     * = 1;
  rightAlign      * = 2;

  (* Events *)
  selectionMsg* = 0;

TYPE
  TableModel*       = POINTER TO TableModelDesc;
  TableModelDesc*   = RECORD (O.ModelDesc)
                        (**
                          Abstract baseclass for all table models. Its purpose is,
                          to define an common interface for all tablemodels. The
                          table object itself will only talk with the model through
                          this interface.
                        *)
                        header*    : HM.HeaderModel; (** Writeable only for inherting mdoels *)
                        selection- : SM.Selection;   (** The selection model, holding selection information *)
                      END;


  (* Some internal datatstructures for the ASTableModel *)

  ASColumn          = POINTER TO ARRAY OF STRING;
  ASRows            = POINTER TO ARRAY OF ASColumn;

  ASTableModel*     = POINTER TO ASTableModelDesc;

  ASTableModelDesc* = RECORD (TableModelDesc)
                        (**
                          This implementation stores the value internally as a
                          two dimentional (a)rray of (s) strings.
                        *)
                        rows : ASRows;
                      END;

  CellEntryDesc    = RECORD
                       object : G.Object;
                       text   : U.Text;
                       string : STRING;
                     END;

  LRow             = POINTER TO ARRAY OF CellEntryDesc;

  LTableModel*     = POINTER TO LTableModelDesc;

  ListEntryBase*    = POINTER TO ListEntryBaseDesc;
  ListEntryBaseDesc* = RECORD
                         last-,
                         next-  : ListEntryBase;
                         model- : LTableModel;
                       END;

  ListEntry*       = POINTER TO ListEntryDesc;
  ListEntryDesc*   = RECORD (ListEntryBaseDesc)
                       row : LRow;
                     END;

  LTableModelDesc* = RECORD (TableModelDesc)
                       (**
                         This implementation stores the value
                         internally as a two dimentional (a)rray
                         of (s) strings.
                       *)
                       first-,
                       last-,
                       current    : ListEntryBase;
                       currentPos : LONGINT;
                       rows       : LONGINT;
                      END;


  TestTable*        = POINTER TO TestModelDesc;

  TestModelDesc*    = RECORD (TableModelDesc)
                        (**
                          A simple model implementation, just for testing purpose.
                        *)
                        buffer : U.Text;
                      END;

  (* --------------------------- *)

  RefreshCell*     = POINTER TO RefreshCellDesc;
  RefreshCellDesc* = RECORD (O.ResyncMsgDesc)
                       x*,y* : LONGINT;
                     END;

  RefreshRow*      = POINTER TO RefreshRowDesc;
  RefreshRowDesc*  = RECORD (O.ResyncMsgDesc)
                       y* : LONGINT;
                     END;

  InsertRow*        = POINTER TO InsertRowDesc;
  InsertRowDesc*    = RECORD (O.ResyncMsgDesc)
                        y*,count* : LONGINT;
                      END;

  DeleteRow*        = POINTER TO DeleteRowDesc;
  DeleteRowDesc*    = RECORD (O.ResyncMsgDesc)
                        y*,count* : LONGINT;
                      END;

  (* --------------------------- *)

  SelectionMsg*     = POINTER TO SelectionMsgDesc;
  SelectionMsgDesc* = RECORD (O.MessageDesc)
                        (**
                          This message will be send, when the current selection
                          changes.
                        *)
                      END;


VAR
  refreshCell : RefreshCell; (* We allocate a global instance and reuse it everytime *)
  refreshRow  : RefreshRow; (* We allocate a global instance and reuse it everytime *)
  insertRow   : InsertRow;
  deleteRow   : DeleteRow;

  PROCEDURE (t : TableModel) Init*;

  BEGIN
    t.Init^;

    t.header:=NIL;

    t.selection:=SM.CreateNone();
    t.AttachModel(t.selection);
  END Init;

  PROCEDURE (t : TableModel) RedrawRow*(row : LONGINT);

  BEGIN
    refreshRow.y:=row;
    t.Notify(refreshRow);
  END RedrawRow;

  PROCEDURE (t : TableModel) RedrawCell*(column,row : LONGINT);

  BEGIN
    refreshCell.x:=column;
    refreshCell.y:=row;
    t.Notify(refreshCell);
  END RedrawCell;


  PROCEDURE (t : TableModel) NotifyInsert*(y,count : LONGINT);

  BEGIN
    insertRow.y:=y;
    insertRow.count:=count;

    t.Notify(insertRow);
  END NotifyInsert;

  PROCEDURE (t : TableModel) NotifyDelete*(y,count : LONGINT);

  BEGIN
    deleteRow.y:=y;
    deleteRow.count:=count;

    t.Notify(deleteRow);
  END NotifyDelete;

  PROCEDURE (t : TableModel) SendLineSelection;

  VAR
    selection : SelectionMsg;

  BEGIN
    NEW(selection);
    t.Send(selection,selectionMsg);
  END SendLineSelection;

  PROCEDURE (t : TableModel) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF model=t.selection THEN
      IF msg#NIL THEN
        WITH
          msg : SM.RefreshCell DO
          t.RedrawCell(msg.column,msg.row);
        | msg : SM.RefreshRow DO
          t.RedrawRow(msg.line);
        | msg : SM.Selected DO
          t.SendLineSelection;
        ELSE
        END;
      ELSE
        t.Notify(NIL);
      END;
    END;
  END Resync;

  PROCEDURE (t : TableModel) SetSelection*(selection : SM.Selection);

  (**
    Set the @otype{SM.Selection} object responsible for holding all information
    about the current selection. By default @otype{SM.None} ist set.

    You must assign a valid instance of a class derived from @otype{SM.Selection}.
  *)

  BEGIN
    ASSERT(selection#NIL);

    t.selection.Clear;
    t.UnattachModel(t.selection);

    t.selection:=selection;
    t.AttachModel(t.selection);
  END SetSelection;

  PROCEDURE (t : TableModel) GetRows*():LONGINT;

  BEGIN
    RETURN 0;
  END GetRows;

  PROCEDURE (t : TableModel) GetColumns*():LONGINT;

  BEGIN
    RETURN 1;
  END GetColumns;

  PROCEDURE (t : TableModel) GetColumnWidth*(index : LONGINT):LONGINT;

  BEGIN
    RETURN MAX(INTEGER);
  END GetColumnWidth;

  PROCEDURE (t : TableModel) GetText*(x,y : LONGINT):U.Text;

  BEGIN
    RETURN NIL;
  END GetText;

  PROCEDURE (t : TableModel) GetString*(x,y : LONGINT):STRING;

  BEGIN
    RETURN NIL;
  END GetString;

  PROCEDURE (t : TableModel) GetObject*(x,y : LONGINT):G.Object;

  BEGIN
    RETURN NIL;
  END GetObject;

  PROCEDURE (t : TableModel) GetAlignment*(x,y : LONGINT):LONGINT;

  BEGIN
    RETURN leftAlign;
  END GetAlignment;




  PROCEDURE (t : TestTable) Init*;

  BEGIN
    t.Init^;

    NEW(t.buffer,100);
  END Init;


  PROCEDURE (t : TestTable) GetColumns*():LONGINT;

  BEGIN
    RETURN 10;
  END GetColumns;

  PROCEDURE (t : TestTable) GetColumnWidth*(index : LONGINT):LONGINT;

  BEGIN
    RETURN 15*8;
  END GetColumnWidth;

  PROCEDURE (t : TestTable) GetRows*():LONGINT;

  BEGIN
    RETURN 100;
  END GetRows;

  PROCEDURE (t : TestTable) GetText*(x,y : LONGINT):U.Text;

  VAR
    help : ARRAY 32 OF CHAR;

  BEGIN
    COPY("(",t.buffer^);
    co.IntToStr(x,help);
    str.Append(help,t.buffer^);
    str.Append(",",t.buffer^);
    co.IntToStr(y,help);
    str.Append(help,t.buffer^);
    str.Append(")",t.buffer^);

    RETURN t.buffer;
  END GetText;

  PROCEDURE (t : TestTable) GetAlignment*(x,y : LONGINT):LONGINT;

  BEGIN
    RETURN rightAlign;
  END GetAlignment;


  PROCEDURE (t : ASTableModel) SetSize*(width,height : LONGINT);

  (**
    Set the size of the table in rows and columns.
    Currently all previous stored texts are lost. This may change
    in the future.

    NOTE
    We make the internally used array one greater in width and height to store
    possible additional information. Currently the first row is used to store
    the column header texts.
  *)

  VAR
    x,y : LONGINT;

  BEGIN
    NEW(t.rows,height+1);
    FOR x:=0 TO height DO
      NEW(t.rows[x],width+1);
      FOR y:=0 TO width DO
        t.rows[x][y]:=NIL;
      END;
    END;

    t.Notify(NIL);
  END SetSize;

  PROCEDURE (t : ASTableModel) Init*;

  VAR
    h : HM.AHeaderModel;

  BEGIN
    t.Init^;

    NEW(h);
    h.Init;

    t.header:=h;
    t.rows:=NIL;

    t.SetSize(0,0);
  END Init;

  PROCEDURE (t : ASTableModel) SetLabel*(column : LONGINT; label : STRING);

  BEGIN
    t.header(HM.AHeaderModel).SetLabel(column-1,label);
  END SetLabel;

  PROCEDURE (t : ASTableModel) GetColumnWidth*(index : LONGINT):LONGINT;

  BEGIN
    RETURN t.header.GetLabelSize(index);
  END GetColumnWidth;

  PROCEDURE (t : ASTableModel) GetColumns*():LONGINT;

  BEGIN
    IF t.rows=NIL THEN
      RETURN 0;
    ELSE
      RETURN LEN(t.rows[0]^)-1;
    END;
  END GetColumns;

  PROCEDURE (t : ASTableModel) GetRows*():LONGINT;

  BEGIN
    IF t.rows=NIL THEN
      RETURN 0;
    ELSE
      RETURN LEN(t.rows^)-1;
    END;
  END GetRows;

  PROCEDURE (t : ASTableModel) SetStr*(x,y : LONGINT; string : STRING);

  BEGIN
    t.rows[y][x]:=string;

    t.RedrawCell(x,y);
  END SetStr;

  PROCEDURE (t : ASTableModel) SetText*(x,y : LONGINT; text : U.Text);

  BEGIN
    t.SetStr(x,y,Object.NewLatin1(text^));
  END SetText;

  PROCEDURE (t : ASTableModel) SetString*(x,y : LONGINT; string : ARRAY OF CHAR);

  VAR
    text : U.Text;

  BEGIN
    NEW(text,str.Length(string)+1);
    COPY(string,text^);

    t.SetText(x,y,text);
  END SetString;

  PROCEDURE (t : ASTableModel) GetString*(x,y : LONGINT):STRING;

  BEGIN
    RETURN t.rows[y][x];
  END GetString;

  (* ------------------------------------------- *)

  PROCEDURE (e : ListEntryBase) Init*(model : LTableModel);

  BEGIN
    e.next:=NIL;
    e.last:=NIL;
    e.model:=model;
  END Init;

  PROCEDURE (e : ListEntryBase) GetText*(x : LONGINT):U.Text;

  BEGIN
    RETURN NIL;
  END GetText;

  PROCEDURE (e : ListEntryBase) GetString*(x : LONGINT):STRING;

  BEGIN
    RETURN NIL;
  END GetString;

  PROCEDURE (e : ListEntryBase) GetObject*(x : LONGINT):G.Object;

  BEGIN
    RETURN NIL;
  END GetObject;

  PROCEDURE (e : ListEntryBase) IsGreater*(other : ListEntryBase;
                                           column : LONGINT):BOOLEAN;

    (**
      Comparison method for @oproc{LTableModel.Sort}. The baseclass
      is implemented by calling @oproc{ListEntryBase.GetText} on both parameters
      and comparing the resulting texts or alternativly by comparing the two
      pointers themselfs if no text is available.

      Overload if you want a different implementation.
    *)

  VAR
    text1,
    text2   : U.Text;
    string1,
    string2 : STRING;

  BEGIN
    text1:=e.GetText(column);
    text2:=other.GetText(column);

    IF (text1#NIL) & (text2#NIL) THEN
      RETURN text1^>text2^;
    ELSE

      string1:=e.GetString(column);
      string2:=other.GetString(column);

      IF (string1#NIL) & (string2#NIL) THEN
        RETURN string1.Compare(string2)>0;
      ELSE
        RETURN SYSTEM.VAL(SYSTEM.ADDRESS,e)>SYSTEM.VAL(SYSTEM.ADDRESS,other);
      END;
    END;
  END IsGreater;

  PROCEDURE (e : ListEntryBase) Free*;

  BEGIN
  END Free;

  (* ------------------------------------------- *)

  PROCEDURE (e : ListEntry) Init*(model : LTableModel);

  VAR
    x : LONGINT;

  BEGIN
    e.Init^(model);

    NEW(e.row,model.GetColumns());

    FOR x:=0 TO LEN(e.row^)-1 DO
      e.row[x].text:=NIL;
      e.row[x].string:=NIL;
      e.row[x].object:=NIL;
    END;
  END Init;

  PROCEDURE (e : ListEntry) SetText*(x : LONGINT; text : U.Text);

  BEGIN
    e.row[x-1].text:=text;
    e.row[x-1].string:=NIL;
    e.row[x-1].object:=NIL;
  END SetText;

  PROCEDURE (e : ListEntry) SetString*(x : LONGINT; string : ARRAY OF CHAR);

  VAR
    text : U.Text;

  BEGIN
    NEW(text,str.Length(string)+1);
    COPY(string,text^);

    e.SetText(x,text);
  END SetString;

  PROCEDURE (e : ListEntry) SetStr*(x : LONGINT; string : STRING);

  BEGIN
    e.row[x-1].text:=NIL;
    e.row[x-1].string:=string;
    e.row[x-1].object:=NIL;
  END SetStr;

  PROCEDURE (e : ListEntry) SetObject*(x : LONGINT; object: G.Object);

  BEGIN
    e.row[x-1].object:=object;
    e.row[x-1].text:=NIL;
  END SetObject;

  PROCEDURE (e : ListEntry) GetText*(x : LONGINT):U.Text;

  BEGIN
    ASSERT((x>=1) & (x<=LEN(e.row^)));

    RETURN e.row[x-1].text;
  END GetText;

  PROCEDURE (e : ListEntry) GetString*(x : LONGINT):STRING;

  BEGIN
    ASSERT((x>=1) & (x<=LEN(e.row^)));

    RETURN e.row[x-1].string;
  END GetString;

  PROCEDURE (e : ListEntry) GetObject*(x : LONGINT):G.Object;

  BEGIN
    ASSERT((x>=1) & (x<=LEN(e.row^)));

    RETURN e.row[x-1].object;
  END GetObject;

  PROCEDURE (e : ListEntry) Free*;

  VAR
    x : LONGINT;

  BEGIN
    FOR x:=0 TO LEN(e.row^)-1 DO
      IF e.row[x].object#NIL THEN
        e.row[x].object.Free;
      END;
    END;
  END Free;

  PROCEDURE CreateListEntry*(model : LTableModel):ListEntry;

  VAR
    entry : ListEntry;

  BEGIN
    NEW(entry);
    entry.Init(model);

    RETURN entry;
  END CreateListEntry;

  (* ------------------------------------------- *)

  PROCEDURE (t : LTableModel) Init*;

  VAR
    h : HM.AHeaderModel;

  BEGIN
    t.Init^;

    NEW(h);
    h.Init;

    t.header:=h;

    t.first:=NIL;
    t.last:=NIL;
    t.rows:=0;

    t.current:=NIL;
    t.currentPos:=0;
  END Init;

  PROCEDURE (t : LTableModel) SetLabel*(column : LONGINT; label : STRING);

  BEGIN
    t.header(HM.AHeaderModel).SetLabel(column-1,label);
  END SetLabel;

  PROCEDURE (t : LTableModel) SetColumnWidth*(index,mode,width : LONGINT);

  BEGIN
    t.header.SetLabelSize(index-1,mode,width);
  END SetColumnWidth;

  PROCEDURE (t : LTableModel) GetColumns*():LONGINT;

  VAR
    count : LONGINT;

  BEGIN
    count:=t.header.GetEntries();

    IF count=0 THEN
      RETURN 1;
    ELSE
      RETURN count;
    END;
  END GetColumns;

  PROCEDURE (t : LTableModel) GetColumnWidth*(index : LONGINT):LONGINT;

  BEGIN
    IF t.GetColumns()<=1 THEN
      RETURN MAX(INTEGER);
    ELSE
      RETURN t.header.GetLabelSize(index);
    END;
  END GetColumnWidth;

  PROCEDURE (t : LTableModel) GetRows*():LONGINT;

  BEGIN
    RETURN t.rows;
  END GetRows;

  PROCEDURE (t : LTableModel) GetEntry*(y : LONGINT):ListEntryBase;

  BEGIN
    IF (y<1) OR (y>t.rows) THEN
      RETURN NIL;
    END;

    IF t.current=NIL THEN
      t.current:=t.first;
      t.currentPos:=1;
      WHILE y>1 DO
        t.current:=t.current.next;
        INC(t.currentPos);
        DEC(y);
      END;

      RETURN t.current;
    ELSE
      IF y>t.currentPos THEN
        y:=y-t.currentPos;
        WHILE y>0 DO
          t.current:=t.current.next;
          INC(t.currentPos);
          DEC(y);
        END;
      ELSIF y<t.currentPos THEN
        y:=t.currentPos-y;
        WHILE y>0 DO
          t.current:=t.current.last;
          DEC(t.currentPos);
          DEC(y);
        END;
      END;

      RETURN t.current;
    END;
  END GetEntry;

  PROCEDURE (t : LTableModel) InsertEntry*(pos : LONGINT; entry : ListEntryBase);

  VAR
    insert : ListEntryBase;

  BEGIN
   (* we can insert before the first and after the last entry *)
    ASSERT((pos>=0) & (pos<=t.rows));

    IF t.header#NIL THEN
      t.header.ClearSortColumn;
    END;

    IF pos=0 THEN (* insert before all others *)
      IF t.first=NIL THEN
        t.first:=entry;
        t.last:=entry;
      ELSE
        t.first.last:=entry;
        entry.next:=t.first;
        t.first:=entry;
      END;
    ELSIF pos=t.rows THEN
      t.last.next:=entry;
      entry.last:=t.last;
      t.last:=entry;
    ELSE
      insert:=t.GetEntry(pos);
      entry.next:=insert.next;
      IF insert.next#NIL THEN
        insert.next.last:=entry;
      END;
      entry.last:=insert;
      insert.next:=entry;
    END;

    INC(t.rows);

    t.current:=entry;
    t.currentPos:=pos+1;

    t.NotifyInsert(pos+1,1);
  END InsertEntry;


  PROCEDURE (t : LTableModel) PrependEntry*(entry : ListEntryBase);

  BEGIN
    t.InsertEntry(0,entry);
  END PrependEntry;

  PROCEDURE (t : LTableModel) AppendEntry*(entry : ListEntryBase);

  BEGIN
    t.InsertEntry(t.rows,entry);
  END AppendEntry;

  PROCEDURE (t : LTableModel) SwapWithNext*(entry : ListEntryBase);

    (**
      Just for internal use, do not use it yet!
    *)

  VAR
    next : ListEntryBase;

  BEGIN
    next:=entry.next;

    ASSERT(next#NIL);

    next.last:=entry.last;
    IF next.last#NIL THEN
      next.last.next:=next;
    END;

    entry.next:=next.next;
    IF entry.next#NIL THEN
      entry.next.last:=entry;
    END;

    next.next:=entry;
    entry.last:=next;

    IF t.current=entry THEN
      t.current:=next;
    ELSIF t.current=next THEN
      t.current:=entry;
    END;

    IF t.first=entry THEN
      t.first:=next;
    ELSIF t.first=next THEN
      t.first:=entry;
    END;

    IF t.last=entry THEN
      t.last:=next;
    ELSIF t.last=next THEN
      t.last:=entry;
    END;
  END SwapWithNext;

  PROCEDURE (t : LTableModel) DeleteEntry*(pos : LONGINT);

  VAR
    entry : ListEntryBase;

  BEGIN
    (* we can insert before the first and after the last entry *)
    ASSERT((pos>=1) & (pos<=t.rows));

    entry:=t.GetEntry(pos);

    IF entry=t.first THEN
      t.first:=t.first.next;
    END;

    IF entry=t.last THEN
      t.last:=t.last.last;
    END;

    IF entry.last#NIL THEN
      entry.last.next:=entry.next;
    END;

    IF entry.next#NIL THEN
      entry.next.last:=entry.last;
    END;

    entry.Free;

    DEC(t.rows);

    t.current:=NIL; (* TODO: We could do better *)

    t.selection.OnLineDeleted(pos);

    t.NotifyDelete(pos,1);
  END DeleteEntry;

  PROCEDURE (t : LTableModel) DeleteAll*;

  VAR
    entry : ListEntryBase;

  BEGIN
    entry:=t.first;
    WHILE entry#NIL DO
      entry.Free;
      entry:=entry.next;
    END;

    t.first:=NIL;
    t.last:=NIL;
    t.current:=NIL;
    t.rows:=0;

    t.selection.OnClear;

    t.Notify(NIL);
  END DeleteAll;

  PROCEDURE (t : LTableModel) RotateStartTo*(entry : ListEntryBase);

    (**
      Will rotate the list, so that the given entry is the new start of
      the list.

      It is assumed that entry is in the list. Otherweise the behaviour is
      undefined.
    *)

  BEGIN
    IF t.header#NIL THEN
      t.header.ClearSortColumn;
    END;

    t.last.next:=t.first;
    t.first.last:=t.last;

    t.first:=entry;
    t.last:=entry.last;

    t.first.last:=NIL;
    t.last.next:=NIL;

    t.current:=t.first;
    t.currentPos:=1;

    t.Notify(NIL);
  END RotateStartTo;

  PROCEDURE (t : LTableModel) Sort*(column : LONGINT; down : BOOLEAN);

    (**
      Sort the table using the given column. If down=TRUE the column will be
      sorted down (bigger entries will be further down the list) lese it will
      be sorted up.

      Currently down is not evaluated.

      Sorting will be done using ListEntryBase.IsGreater.
      Sorting is stable.
      The current sorting algorithm is Quicksort, but than can change anytime.
    *)

  VAR
    changed : BOOLEAN;
    a,b     : ListEntryBase;

  BEGIN
    IF t.header#NIL THEN
      t.header.SetSortColumn(column);
    END;

    IF t.GetRows()=0 THEN
      RETURN;
    END;

    REPEAT
      changed:=FALSE;
      a:=t.first;
      WHILE (a#NIL) & (a.next#NIL) DO
        b:=a.next;
        IF a.IsGreater(b,column) THEN
          t.SwapWithNext(a);
          changed:=TRUE;

          IF a.next#NIL THEN
            b:=a.next;
          ELSE
            b:=NIL;
          END;
        ELSE
          a:=b;
          IF b.next#NIL THEN
            b:=b.next;
          ELSE
            b:=NIL;
          END;
        END;
      END;
    UNTIL ~changed;

    t.Notify(NIL);
  END Sort;

  PROCEDURE (t : LTableModel) GetText*(x,y : LONGINT):U.Text;

  VAR
    entry : ListEntryBase;

  BEGIN
    ASSERT((x>=1) & (x<=t.GetColumns()) & (y>=1) & (y<=t.rows));

    entry:=t.GetEntry(y);

    RETURN entry.GetText(x);;
  END GetText;

  PROCEDURE (t : LTableModel) GetString*(x,y : LONGINT):STRING;

  VAR
    entry : ListEntryBase;

  BEGIN
    ASSERT((x>=1) & (x<=t.GetColumns()) & (y>=1) & (y<=t.rows));

    entry:=t.GetEntry(y);

    RETURN entry.GetString(x);
  END GetString;

  PROCEDURE (t : LTableModel) GetObject*(x,y : LONGINT):G.Object;

  VAR
    entry : ListEntryBase;

  BEGIN
    ASSERT((x>=1) & (x<=t.GetColumns()) & (y>=1) & (y<=t.rows));

    entry:=t.GetEntry(y);

    RETURN entry.GetObject(x);
  END GetObject;

BEGIN
  NEW(refreshCell);
  NEW(refreshRow);
  NEW(insertRow);
  NEW(deleteRow);
END VO:Model:Table.