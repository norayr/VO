MODULE VO:Edit:Text [OOC_EXTENSIONS];

  (*
    Part of the VO internal multiline text edit control.
    Copyright (C) 2003 Tim Teulings

    This module is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with OOC. If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

IMPORT O   := VO:Base:Object,
       U   := VO:Base:Util,

       B   := VO:Edit:Block,
       R   := VO:Edit:Run,
       S   := VO:Edit:Syntax,
              VO:Edit:Syntax:Standard,

              Ascii,
              Err,
              IO,
       IOB := IO:Buffer,
              IO:FileChannel,
       str := Strings,s:=SYSTEM;

CONST
  undoNone* = 0;
  undoUndo* = 1;
  undoRedo* = 2;

  cursorFix*      = 0; (** Cursor will keep its position even if some editing happens *)
  cursorHidden*   = 1; (** This cursor is for internal use and should not be displayed *)
  cursorBookmark* = 2; (** This is a bookmark *)

  stateStep = 1;

TYPE
  Rider*      = POINTER TO RiderDesc;
  State*      = POINTER TO StateDesc;
  Cursor*     = POINTER TO CursorDesc;
  Buffer*     = POINTER TO BufferDesc;
  Text*       = POINTER TO TextDesc;

  UndoEntry      = POINTER TO UndoEntryDesc;
  UndoEntryDesc  = RECORD
                      (** Baseclass for holding text manipulation information *)
                      next : UndoEntry;
                    END;

  UndoInsert     = POINTER TO UndoInsertDesc;
  UndoInsertDesc = RECORD (UndoEntryDesc)
                      (** All information to undo a text insertion *)
                      pos   : LONGINT;
                      count : LONGINT;
                    END;

  UndoDelete     = POINTER TO UndoDeleteDesc;
  UndoDeleteDesc = RECORD (UndoEntryDesc)
                      (** All information to undo a text deletion *)
                      pos  : LONGINT;
                      text : R.Run;
                    END;

  UndoGroup      = POINTER TO UndoGroupDesc;
  UndoGroupDesc  = RECORD
                     (** Groups a number of undo changes *)
                     last    : UndoGroup;
                     first   : UndoEntry;
                     changed : BOOLEAN;
                   END;

  PosDesc*    = RECORD
                  (** for tempory storing text position *)
                  x-,y-,pos- : LONGINT;
                END;

  RiderDesc   = RECORD
                  (** a (temporary) rider for the text *)
                  run      : R.Run;
                  blockPos : LONGINT;

                  pos     : LONGINT;
                  x,yPos  : LONGINT;
                END;

  Memory      = POINTER TO ARRAY OF S.StateInfo;

  StateDesc*  = RECORD
                  (** Stores syntax parsing information *)
                  text        : Text; (** pointer to the text *)
                  rider       : Rider; (** always points to the line before the current row *)
                  state-      : S.StateInfo;
                  row         : LONGINT; (** the current row *)
                  memory      : Memory;
                  highMark    : LONGINT;
                  cursor      : Cursor;
                END;

  CursorDesc* = RECORD
                  (** a cursor *)
                  next-,
                  last   : Cursor;
                  text   : Text;
                  rider  : Rider;

                  x      : LONGINT;

                  flags- : SET;

                  name-  : POINTER TO ARRAY OF CHAR;
                END;

  BufferDesc* = RECORD
                  first : R.Run;
                END;

  TextDesc*   = RECORD (O.ModelDesc)
                  (** a text object itself *)
                  first      : R.Run;

                  firstCursor-,
                  lastCursor : Cursor;

                  undoMode   : LONGINT;
                  undoStack  : UndoGroup;
                  redoStack  : UndoGroup;

                  changed-,
                  readOnly-  : BOOLEAN;

                  lines-     : LONGINT;

                  fileName-  : STRING;
                  syntax-    : S.Syntax;

                  state-     : State;
                END;

  CursorMsg*     = POINTER TO CursorMsgDesc;
  CursorMsgDesc* = RECORD (O.ResyncMsgDesc)
                     cursor-  : Cursor;
                     oldPos-  : PosDesc;
                   END;

  RedrawMsg*     = POINTER TO RedrawMsgDesc;
  RedrawMsgDesc* = RECORD (O.ResyncMsgDesc)
                     from-,
                     to-    : LONGINT;
                   END;

  InsertLinesMsg*      = POINTER TO InsertLinesMsgDesc;
  InsertLinesMsgDesc * = RECORD (O.ResyncMsgDesc)
                           from*,
                           count* : LONGINT;
                         END;

  DeleteLinesMsg*      = POINTER TO DeleteLinesMsgDesc;
  DeleteLinesMsgDesc * = RECORD (O.ResyncMsgDesc)
                           from*,
                           count* : LONGINT;
                         END;

  StatusChangedMsg*      = POINTER TO StatusChangedMsgDesc;
  StatusChangedMsgDesc * = RECORD (O.ResyncMsgDesc)
                           END;

  NameChangedMsg*      = POINTER TO NameChangedMsgDesc;
  NameChangedMsgDesc * = RECORD (O.ResyncMsgDesc)
                         END;

  ChangedChangedMsg*      = POINTER TO ChangedChangedMsgDesc;
  ChangedChangedMsgDesc * = RECORD (O.ResyncMsgDesc)
                            END;

VAR
  globalText   : U.Text;

  PROCEDURE (b : Buffer) Init;

  BEGIN
    b.first:=NIL;
  END Init;

  PROCEDURE (b : Buffer) SetRun(run : R.Run);

  BEGIN
    b.first:=run;
  END SetRun;

  PROCEDURE (b : Buffer) GetRun():R.Run;

  BEGIN
    RETURN b.first;
  END GetRun;

  PROCEDURE (b : Buffer) GetRunCopy():R.Run;

  BEGIN
    RETURN R.DuplicateRunList(b.first);
  END GetRunCopy;

  PROCEDURE (b : Buffer) GetTextCopy*():U.Text;

  VAR
    size,
    x,y  : LONGINT;
    run  : R.Run;
    text : U.Text;

  BEGIN
    size:=1;
    run:=b.first;
    WHILE run#NIL DO
      INC(size,run.length);
      run:=run.next;
    END;

    NEW(text,size);

    x:=0;
    run:=b.first;
    WHILE run#NIL DO
      y:=run.pos;
      WHILE y<run.pos+run.length DO
        text[x]:=run.block.text[y];
        INC(x);
        INC(y);
      END;
      run:=run.next;
    END;

    text[x]:=0X;

    RETURN text;
  END GetTextCopy;

  PROCEDURE (r : Rider) Init;

  BEGIN
    r.run:=NIL;
    r.blockPos:=-1;

    r.pos:=-1;
    r.x:=-1;
    r.yPos:=-1;
  END Init;

  PROCEDURE (r : Rider) StorePos(VAR rider : RiderDesc);

  BEGIN
    rider:=r^;
  END StorePos;

  PROCEDURE (r : Rider) RestorePos(VAR rider : RiderDesc);

  BEGIN
    r^:=rider;
  END RestorePos;

  PROCEDURE (r : Rider) GotoRider(rider : Rider);

  BEGIN
    r^:=rider^;
  END GotoRider;

  PROCEDURE (r : Rider) Clone():Rider;

  VAR
    rider : Rider;

  BEGIN
    NEW(rider);
    rider^:=r^;

    RETURN rider;
  END Clone;

  PROCEDURE (r : Rider) GetLineLength():LONGINT;

  VAR
    length,
    pos     : LONGINT;
    run     : R.Run;

  BEGIN
    length:=0;

    (* Count everything before the current position *)
    pos:=r.blockPos-1;
    run:=r.run;
    IF pos<run.pos THEN
      run:=run.last;
      IF run#NIL THEN
        pos:=run.pos+run.length-1;
      END;
    END;

    WHILE ((run#NIL) & (run.block.text[pos]#Ascii.lf)) DO
      INC(length);

      IF pos-1>=run.pos THEN
        DEC(pos);
      ELSE
        run:=run.last;
        IF run#NIL THEN
          pos:=run.pos+run.length-1;
        END;
      END;
    END;

    (* Count everything at and after this position *)
    pos:=r.blockPos;
    run:=r.run;
    WHILE ((run.next#NIL) & (run.block.text[pos]#Ascii.lf)) DO
      INC(length);

      IF pos+1<=run.pos+run.length-1 THEN
        INC(pos);
      ELSE
        run:=run.next;
        IF run#NIL THEN
          pos:=run.pos;
        END;
      END;
    END;

    RETURN length;
  END GetLineLength;

  PROCEDURE (r : Rider) IsEOL():BOOLEAN;

  BEGIN
    RETURN r.run.block.text[r.blockPos]=Ascii.lf;
  END IsEOL;

  PROCEDURE (r : Rider) IsEOT():BOOLEAN;

  BEGIN
    RETURN (r.run.next=NIL) & (r.blockPos=r.run.pos+r.run.length-1);
  END IsEOT;

  PROCEDURE (r : Rider) GetPreviousChar*():CHAR;

  (**
    Return the character the rider is currently pointing to..
  *)

  BEGIN
    IF r.blockPos>r.run.pos THEN
      RETURN r.run.block.text[r.blockPos-1];
    ELSIF r.run.last#NIL THEN
      RETURN r.run.last.block.text[r.run.last.pos+r.run.last.length-1];
    ELSE
      RETURN 0X;
    END;
  END GetPreviousChar;

  PROCEDURE (r : Rider) GetChar*():CHAR;

  (**
    Return the character the rider is currently pointing to..
  *)

  BEGIN
    RETURN r.run.block.text[r.blockPos];
  END GetChar;

  PROCEDURE (r : Rider) Move(offset : LONGINT):BOOLEAN;

  (**
    Move rider the given number of characters back or forward depending
    on the sign of offset.
  *)

  VAR
    store : RiderDesc;
    eol   : BOOLEAN;

  BEGIN
    r.StorePos(store);

    IF offset<0 THEN

      WHILE offset<0 DO

        IF r.blockPos-1>=r.run.pos THEN
          DEC(r.blockPos);
        ELSIF r.run.last#NIL THEN
          r.run:=r.run.last;
          r.blockPos:=r.run.pos+r.run.length-1;
        ELSE
          r.RestorePos(store);
          RETURN FALSE;
        END;

        (* update cursor position *)
        IF r.IsEOL() THEN
          DEC(r.yPos);
          r.x:=r.GetLineLength()+1;
        ELSE
          DEC(r.x);
        END;

        DEC(r.pos);

        INC(offset);
      END;

    ELSIF offset>0 THEN

      WHILE offset>0 DO
        eol:=r.IsEOL();

        IF r.blockPos+1<=r.run.pos+r.run.length-1 THEN
          INC(r.blockPos);
        ELSIF r.run.next#NIL THEN
          r.run:=r.run.next;
          r.blockPos:=r.run.pos;
        ELSE
          r.RestorePos(store);
          RETURN FALSE;
        END;

        (* update cursor position *)
        IF eol THEN
          r.x:=1;
          INC(r.yPos);
        ELSE
          INC(r.x);
        END;

        INC(r.pos);

        DEC(offset);
      END;

    END;

    RETURN TRUE;
  END Move;

  PROCEDURE (r : Rider) Back():BOOLEAN;

  (**
    Move rider back one character.
  *)

  BEGIN
    RETURN r.Move(-1);
  END Back;

  PROCEDURE (r : Rider) Forward():BOOLEAN;

  (**
    Move rider forward one character.
  *)

  BEGIN
    RETURN r.Move(1);
  END Forward;

  PROCEDURE (r : Rider) GotoColumn(x : LONGINT):BOOLEAN;

  BEGIN
    IF r.x=x THEN
      RETURN TRUE;
    END;

    RETURN r.Move(x-r.x);
  END GotoColumn;

  PROCEDURE (r : Rider) GotoRow(y : LONGINT):BOOLEAN;

  VAR
    store : RiderDesc;

  BEGIN
    IF r.yPos=y THEN
      RETURN TRUE;
    END;

    r.StorePos(store);

    IF y>r.yPos THEN
      REPEAT
      UNTIL (~r.Forward() OR (r.yPos=y));
    ELSIF y<r.yPos THEN
      REPEAT
      UNTIL (~r.Back() OR (r.yPos=y));
    END;

    IF r.yPos=y THEN
      RETURN TRUE;
    ELSE
      r.RestorePos(store);
      RETURN FALSE;
    END;
  END GotoRow;

  PROCEDURE (r : Rider) Goto(x,y : LONGINT):BOOLEAN;

  VAR
    store : RiderDesc;

  BEGIN
    IF (r.x=x) & (r.yPos=y) THEN
      RETURN TRUE;
    END;

    r.StorePos(store);

    IF r.GotoRow(y) THEN
      IF r.GotoColumn(x) THEN
        RETURN TRUE;
      END;
    END;

    r.RestorePos(store);

    RETURN FALSE;
  END Goto;

  PROCEDURE (r : Rider) GotoPos(pos : LONGINT):BOOLEAN;

  BEGIN
    IF r.pos=pos THEN
      RETURN TRUE;
    END;

    RETURN r.Move(pos-r.pos);
  END GotoPos;

  PROCEDURE (r : Rider) MoveLastLine*():BOOLEAN;

  VAR
    store : RiderDesc;

  BEGIN
    r.StorePos(store);

    (* Must always move at least one char back *)
    IF ~r.Back() THEN
      r.RestorePos(store);
      RETURN FALSE;
    END;

    (* Move to the end of the last line *)
    WHILE r.GetChar()#Ascii.lf DO
      IF ~r.Back() THEN
        r.RestorePos(store);
        RETURN FALSE;
      END;
    END;

    (* Move back until you find Ascii.lf as previous character *)
    WHILE (r.GetPreviousChar()#Ascii.lf) & r.Back() DO
      (* Maybe we a already in the first line, so just stop on errors of r.Back() *)
    END;

    RETURN TRUE;
  END MoveLastLine;

  PROCEDURE (r : Rider) MoveNextLine*():BOOLEAN;

  VAR
    store : RiderDesc;

  BEGIN
    r.StorePos(store);

    (* Move until the end of the line *)
    WHILE r.run.block.text[r.blockPos]#Ascii.lf DO
      (* This is just a copy from Rider.Move(1) *)
      IF r.blockPos+1<=r.run.pos+r.run.length-1 THEN
        INC(r.blockPos);
      ELSIF r.run.next#NIL THEN
        r.run:=r.run.next;
        r.blockPos:=r.run.pos;
      ELSE
        r.RestorePos(store);
        RETURN FALSE;
      END;
      INC(r.x);
      INC(r.pos);
    END;

    (* Move over the Ascii.Lf onto the start of the next line *)
    (* This is just a copy from Rider.Move(1) *)
    IF r.blockPos+1<=r.run.pos+r.run.length-1 THEN
      INC(r.blockPos);
    ELSIF r.run.next#NIL THEN
      r.run:=r.run.next;
      r.blockPos:=r.run.pos;
    ELSE
      r.RestorePos(store);
      RETURN FALSE;
    END;
    r.x:=1;
    INC(r.yPos);
    INC(r.pos);

    RETURN TRUE;
  END MoveNextLine;

  PROCEDURE (r : Rider) MoveLines*(lines : LONGINT):BOOLEAN;

  VAR
    store : RiderDesc;

  BEGIN
    r.StorePos(store);

    IF lines>0 THEN
      WHILE lines>0 DO
        IF ~r.MoveNextLine() THEN
          r.RestorePos(store);
          RETURN FALSE;
        END;
        DEC(lines);
      END;
    ELSIF lines<0 THEN
      WHILE lines<0 DO
        IF ~r.MoveLastLine() THEN
          r.RestorePos(store);
          RETURN FALSE;
        END;
        INC(lines);
      END;
    END;

    RETURN TRUE;
  END MoveLines;

  PROCEDURE (r : Rider) GetLine*():U.Text;

  VAR
    x,pos,
    len   : LONGINT;
    run   : R.Run;
    tmp   : U.Text;

  BEGIN
    len:=LEN(globalText^);

    x:=0;
    run:=r.run;
    pos:=r.blockPos;
    WHILE (run.next#NIL) & (run.block.text[pos]#Ascii.lf) DO
      IF len<x+1 THEN
        INC(len,100);
        NEW(tmp,len);
        COPY(globalText^,tmp^);
        globalText:=tmp;
      END;
      globalText[x]:=run.block.text[pos];

      INC(x);

      INC(pos);
      IF pos>=run.pos+run.length THEN
        run:=run.next;
        IF run#NIL THEN
          pos:=run.pos;
        END;
      END;
    END;

    IF len<x+1 THEN
      INC(len,100);
      NEW(tmp,len);
      COPY(globalText^,tmp^);
      globalText:=tmp;
    END;
    globalText[x]:=Ascii.lf;
    INC(x);

    IF len<x+1 THEN
      INC(len,100);
      NEW(tmp,len);
      COPY(globalText^,tmp^);
      globalText:=tmp;
    END;
    globalText[x]:=0X;

    RETURN globalText;
  END GetLine;

  PROCEDURE CountText(run : R.Run; VAR firstX,lastX,lines,chars : LONGINT);

  VAR
    rider : Rider;

  BEGIN
    ASSERT(run#NIL);

    firstX:=0;
    lastX:=0;
    lines:=0;
    chars:=0;

    NEW(rider);
    rider.Init;
    rider.run:=run;
    rider.blockPos:=run.pos;

    REPEAT
      IF rider.IsEOL() THEN
        INC(lines);
        lastX:=0;
      ELSIF lines>0 THEN
        INC(lastX);
      ELSE
        INC(firstX);
      END;
      INC(chars);
    UNTIL ~rider.Forward();

(*    Err.String("Handling ");
    Err.LongInt(lines,0);
    Err.String(" line(s), ");
    Err.LongInt(chars,0);
    Err.String(" char(s) - first line length is ");
    Err.LongInt(firstX,0);
    Err.String(", last line length is ");
    Err.LongInt(lastX,0);
    Err.Ln;*)
  END CountText;

  PROCEDURE (c : Cursor) Init*;

  BEGIN
    c.last:=NIL;
    c.next:=NIL;

    c.text:=NIL;
    c.rider:=NIL;

    c.flags:={};

    c.name:=NIL;
  END Init;

  PROCEDURE (t : Text) GetFirst*():Rider;

  VAR
    rider : Rider;

  BEGIN
    NEW(rider);
    rider.Init;

    rider.run:=t.first;
    rider.blockPos:=rider.run.pos;

    rider.pos:=0;
    rider.x:=1;
    rider.yPos:=1;

    RETURN rider;
  END GetFirst;

  PROCEDURE (c : Cursor) LinkText(text : Text);

  BEGIN
    ASSERT(c.rider=NIL);

    c.text:=text;
    c.rider:=text.GetFirst();

    c.x:=1;
  END LinkText;

  PROCEDURE (c : Cursor) UnlinkText;

  BEGIN
    ASSERT(c.rider#NIL);

    c.text:=NIL;
    c.rider:=NIL;
  END UnlinkText;

  PROCEDURE (t : Text) CreateCursor*(name : ARRAY OF CHAR; flags : SET):Cursor;

  VAR
    cursor : Cursor;

  BEGIN
    ASSERT(t.first#NIL);

    NEW(cursor);
    cursor.Init;

    cursor.flags:=flags;

    NEW(cursor.name,str.Length(name)+1);
    COPY(name,cursor.name^);

    IF t.firstCursor=NIL THEN
      t.firstCursor:=cursor;
    ELSE
      t.lastCursor.next:=cursor;
      cursor.last:=t.lastCursor;
    END;
    t.lastCursor:=cursor;

    cursor.LinkText(t);

    RETURN cursor;
  END CreateCursor;

  PROCEDURE (t : Text) GetCursor*(name : ARRAY OF CHAR):Cursor;

  VAR
    cursor : Cursor;

  BEGIN
    cursor:=t.firstCursor;
    WHILE cursor#NIL DO
      IF cursor.name^=name THEN
        RETURN cursor;
      END;
      cursor:=cursor.next;
    END;

    RETURN NIL;
  END GetCursor;

  PROCEDURE (t : Text) GetOrCreateCursor*(name : ARRAY OF CHAR; flags : SET):Cursor;

  VAR
    cursor : Cursor;

  BEGIN

    cursor:=t.GetCursor(name);

    IF cursor=NIL THEN
      cursor:=t.CreateCursor(name,flags);
    END;

    RETURN cursor;
  END GetOrCreateCursor;

  PROCEDURE (t : Text) FreeCursor*(cursor : Cursor);

  BEGIN
    cursor.UnlinkText;

    IF cursor.last#NIL THEN
      cursor.last.next:=cursor.next;
    ELSE
      t.firstCursor:=cursor.next;
    END;

    IF cursor.next#NIL THEN
      cursor.next.last:=cursor.last;
    ELSE
      t.lastCursor:=cursor.last;
    END;
  END FreeCursor;

  PROCEDURE (s : State) Init(text : Text);

  BEGIN
    s.text:=text;
    s.state.Init;
    NEW(s.rider);
    s.row:=1;
    NEW(s.memory,1);
    s.memory[0].Init;
    s.highMark:=0;

    s.cursor:=s.text.GetOrCreateCursor("state",{cursorFix,cursorHidden});
  END Init;

  PROCEDURE (t : Text) NotifyRefresh;

  BEGIN
    t.Notify(NIL);
  END NotifyRefresh;

  PROCEDURE (t : Text) NotifyRedraw*(a,b : LONGINT);

  VAR
    redrawMsg : RedrawMsg;

  BEGIN
    NEW(redrawMsg);
    redrawMsg.from:=a;
    redrawMsg.to:=b;
    t.Notify(redrawMsg);
  END NotifyRedraw;

  PROCEDURE (t : Text) NotifyInsert*(from,count : LONGINT);

  VAR
    insertMsg : InsertLinesMsg;

  BEGIN
    NEW(insertMsg);
    insertMsg.from:=from;
    insertMsg.count:=count;
    t.Notify(insertMsg);
  END NotifyInsert;

  PROCEDURE (t : Text) NotifyDelete*(from,count : LONGINT);

  VAR
    deleteMsg : DeleteLinesMsg;

  BEGIN
    NEW(deleteMsg);
    deleteMsg.from:=from;
    deleteMsg.count:=count;
    t.Notify(deleteMsg);
  END NotifyDelete;

  PROCEDURE (t : Text) NotifyStatusChanged*;

  VAR
    msg : StatusChangedMsg;

  BEGIN
    NEW(msg);
    t.Notify(msg);
  END NotifyStatusChanged;

  PROCEDURE (t : Text) NotifyNameChanged*;

  VAR
    msg : NameChangedMsg;

  BEGIN
    NEW(msg);
    t.Notify(msg);
  END NotifyNameChanged;

  PROCEDURE (t : Text) NotifyChangedChanged*;

  VAR
    msg : ChangedChangedMsg;

  BEGIN
    NEW(msg);
    t.Notify(msg);
  END NotifyChangedChanged;

  PROCEDURE (t : Text) CreateUndoInsert(pos, count : LONGINT);

  VAR
    entry : UndoInsert;

  BEGIN
    ASSERT(t.undoMode=undoUndo);

    NEW(entry);
    entry.pos:=pos;
    entry.count:=count;

    entry.next:=t.undoStack.first;
    t.undoStack.first:=entry;
    IF t.redoStack#NIL THEN
      t.redoStack.first:=NIL;
    END;
  END CreateUndoInsert;

  PROCEDURE (t : Text) CreateUndoDelete(pos : LONGINT; text : R.Run);

  VAR
    entry : UndoDelete;

  BEGIN
    ASSERT(t.undoMode=undoUndo);

    NEW(entry);
    entry.pos:=pos;
    entry.text:=text;

    entry.next:=t.undoStack.first;
    t.undoStack.first:=entry;
    IF t.redoStack#NIL THEN
      t.redoStack.first:=NIL;
    END;
  END CreateUndoDelete;

  PROCEDURE (t : Text) CreateRedoInsert(pos, count : LONGINT);

  VAR
    entry : UndoInsert;

  BEGIN
    ASSERT(t.undoMode=undoRedo);

    NEW(entry);
    entry.pos:=pos;
    entry.count:=count;

    entry.next:=t.redoStack.first;
    t.redoStack.first:=entry;
  END CreateRedoInsert;

  PROCEDURE (t : Text) CreateRedoDelete(pos : LONGINT; text : R.Run);

  VAR
    entry : UndoDelete;

  BEGIN
    ASSERT(t.undoMode=undoRedo);

    NEW(entry);
    entry.pos:=pos;
    entry.text:=text;

    entry.next:=t.redoStack.first;
    t.redoStack.first:=entry;
  END CreateRedoDelete;

  PROCEDURE (t : Text) SetChanged*(changed : BOOLEAN);

  BEGIN
    IF t.changed#changed THEN
      t.changed:=changed;
      t.NotifyChangedChanged;
    END;
  END SetChanged;

  PROCEDURE (t : Text) SetReadOnly*(readOnly : BOOLEAN);

  BEGIN
    IF t.readOnly#readOnly THEN
      t.readOnly:=readOnly;
      t.NotifyChangedChanged;
    END;
  END SetReadOnly;

  PROCEDURE (c : Cursor) GetChar*():CHAR;

  BEGIN
    RETURN c.rider.GetChar();
  END GetChar;

  PROCEDURE (c : Cursor) GetPreviousChar*():CHAR;

  BEGIN
    RETURN c.rider.GetPreviousChar();
  END GetPreviousChar;

  PROCEDURE (c : Cursor) GetLineLength*():LONGINT;

  BEGIN
    RETURN c.rider.GetLineLength();
  END GetLineLength;

  PROCEDURE (c : Cursor) GetX*():LONGINT;

  BEGIN
    RETURN c.x;
  END GetX;

  PROCEDURE (c : Cursor) GetY*():LONGINT;

  BEGIN
    RETURN c.rider.yPos;
  END GetY;

  PROCEDURE (c : Cursor) GetPos*():LONGINT;

  BEGIN
    RETURN c.rider.pos;
  END GetPos;

  PROCEDURE (c : Cursor) PrintPos*;

  BEGIN
    IF c.name#NIL THEN
      Err.String(c.name^);
    END;
    Err.Char("[");
    Err.LongInt(c.GetX(),0);
    Err.Char("/");
    Err.LongInt(c.rider.x,0);
    Err.Char(",");
    Err.LongInt(c.GetY(),0);
    Err.Char("(");
    Err.LongInt(c.GetPos(),0);
    Err.String(")]");
    Err.Hex(s.VAL(LONGINT,c.rider.run),8);
    Err.Char(",");
    Err.LongInt(c.rider.run.pos,0); Err.String("<=");
    Err.LongInt(c.rider.blockPos,0); Err.String("<=");
    Err.LongInt(c.rider.run.pos+c.rider.run.length-1,0);
  END PrintPos;

  PROCEDURE (c : Cursor) GetRiderAtPos():Rider;

  (**
    Returns a rider to the current letter
  *)

  BEGIN
    RETURN c.rider.Clone();
  END GetRiderAtPos;

  PROCEDURE (c : Cursor) GetRiderAtSOL*(VAR rider : Rider);

  BEGIN
    rider:=c.rider.Clone();
    IF rider.GotoColumn(1) THEN END;
  END GetRiderAtSOL;

  PROCEDURE (c : Cursor) GotoRider(rider : Rider);

  VAR
    msg : CursorMsg;

  BEGIN
    NEW(msg);
    msg.cursor:=c;
    msg.oldPos.x:=c.GetX();
    msg.oldPos.y:=c.GetY();
    msg.oldPos.pos:=c.GetPos();

    c.rider:=rider.Clone();
    c.x:=rider.x;

    c.text.Notify(msg);
  END GotoRider;

  PROCEDURE (c : Cursor) GotoCursor*(cursor : Cursor);


  VAR
    msg : CursorMsg;

  BEGIN
    ASSERT(cursor#NIL);

    NEW(msg);
    msg.cursor:=c;
    msg.oldPos.x:=c.GetX();
    msg.oldPos.y:=c.GetY();
    msg.oldPos.pos:=c.GetPos();

    c.rider:=cursor.rider.Clone();
    c.x:=cursor.x;

    c.text.Notify(msg);
  END GotoCursor;

  PROCEDURE (c : Cursor) GotoPos*(pos : LONGINT):BOOLEAN;

  VAR
    msg : CursorMsg;

  BEGIN
    IF c.GetPos()=pos THEN
      RETURN TRUE;
    END;

    NEW(msg);
    msg.cursor:=c;
    msg.oldPos.x:=c.GetX();
    msg.oldPos.y:=c.GetY();
    msg.oldPos.pos:=c.GetPos();

    IF c.rider.GotoPos(pos) THEN
      c.x:=c.rider.x;
      c.text.Notify(msg);

      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END GotoPos;

  PROCEDURE (c : Cursor) Goto*(x,y : LONGINT):BOOLEAN;

  VAR
   msg    : CursorMsg;
   length : LONGINT;
(*   delta,
   delta2 : LONGINT;
   tmp,
   tmp2   : Cursor;*)

  BEGIN
    IF x<1 THEN
      RETURN FALSE;
    END;

    IF (x=c.GetX()) & (y=c.GetY()) THEN
      RETURN TRUE;
    END;

(*    delta:=ABS(c.GetY()-y);
    tmp:=c.text.firstCursor;
    tmp2:=NIL;
    WHILE tmp#NIL DO
      delta2:=ABS(tmp.GetY()-y);
      IF delta2<delta THEN
        tmp2:=tmp;
      END;
      tmp:=tmp.next;
    END;

    IF tmp2#NIL THEN
      Err.LongInt(y,0); Err.String(":");
      Err.String(c.name^); Err.String(" "); Err.LongInt(c.GetY(),0);
      Err.String("->");
      Err.String(tmp2.name^); Err.String(" "); Err.LongInt(tmp2.GetY(),0);
      Err.Ln;
    END;*)

    NEW(msg);
    msg.cursor:=c;
    msg.oldPos.x:=c.GetX();
    msg.oldPos.y:=c.GetY();
    msg.oldPos.pos:=c.GetPos();

    IF c.rider.Goto(1,y) THEN

      c.x:=x;
      length:=c.GetLineLength();
      IF x<=length THEN
        IF c.rider.Goto(x,y) THEN
        END;
      ELSE
        IF ~c.rider.Goto(c.GetLineLength()+1,y) THEN
          IF c.rider.Goto(c.GetLineLength(),y) THEN
          END;
        END;
      END;

      c.text.Notify(msg);
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END Goto;

  PROCEDURE (c : Cursor) GotoColumn*(column : LONGINT):BOOLEAN;

  BEGIN
    RETURN c.Goto(column,c.GetY());
  END GotoColumn;

  PROCEDURE (c : Cursor) GotoRow*(row : LONGINT):BOOLEAN;

  BEGIN
    RETURN c.Goto(c.GetX(),row);
  END GotoRow;

  PROCEDURE (c : Cursor) Move*(offset : LONGINT):BOOLEAN;

  VAR
   msg : CursorMsg;

  BEGIN
    IF offset=0 THEN
      RETURN TRUE;
    END;

    NEW(msg);
    msg.cursor:=c;
    msg.oldPos.x:=c.GetX();
    msg.oldPos.y:=c.GetY();
    msg.oldPos.pos:=c.GetPos();

    IF c.rider.Move(offset) THEN
      c.x:=c.rider.x;
      c.text.Notify(msg);
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END Move;

  PROCEDURE (c : Cursor) Back*():BOOLEAN;

  BEGIN
    RETURN c.Move(-1);
  END Back;

  PROCEDURE (c : Cursor) Forward*():BOOLEAN;

  BEGIN
    RETURN c.Move(1);
  END Forward;

  PROCEDURE (c : Cursor) Left*():BOOLEAN;

  BEGIN
    RETURN c.Goto(c.GetX()-1,c.GetY());
  END Left;

  PROCEDURE (c : Cursor) Right*():BOOLEAN;

  BEGIN
    RETURN c.Goto(c.GetX()+1,c.GetY());
  END Right;

  PROCEDURE (c : Cursor) Up*():BOOLEAN;

  BEGIN
    RETURN c.Goto(c.GetX(),c.GetY()-1);
  END Up;

  PROCEDURE (c : Cursor) Down*():BOOLEAN;

  BEGIN
    RETURN c.Goto(c.GetX(),c.GetY()+1);
  END Down;

  PROCEDURE (s : State) RememberState(line : LONGINT; VAR state : S.StateInfo);

  VAR
    tmp   : Memory;
    x,
    index : LONGINT;

  BEGIN
    IF (line MOD stateStep#0) OR (line DIV stateStep<s.highMark) THEN
      RETURN;
    END;

    index:=line DIV stateStep;

    IF index>s.highMark THEN
      ASSERT(s.highMark+1=index);
      IF index>LEN(s.memory^)-1 THEN
        NEW(tmp,LEN(s.memory^)*10);
        FOR x:=0 TO LEN(s.memory^)-1 DO
          tmp[x]:=s.memory[x];
        END;
        s.memory:=tmp;
      END;

      s.memory[index]:=state;
      s.highMark:=index;
    END;
  END RememberState;

  PROCEDURE (s : State) MoveHighMark(line : LONGINT);

  VAR
    index : LONGINT;

  BEGIN
    index:=line DIV stateStep;

    IF index<s.highMark THEN
      s.highMark:=index;
    END;
  END MoveHighMark;

  PROCEDURE (s : State) MoveToLine*(line : LONGINT);

  VAR
    text    : U.Text;
    x,
    newLine,
    length  : LONGINT;
    token   : S.Token;

  BEGIN
    IF line=s.row THEN
      RETURN;
    END;

    IF line<1 THEN
      line:=1;
    END;

    (* See, if we can jump to a position close before the requested line *)
    IF line=1 THEN
      s.state.Init;
      s.row:=1;
    ELSIF (line<s.row) THEN
      newLine:=(line DIV stateStep) * stateStep;
      IF ~s.cursor.Goto(1,newLine-1) THEN
        ASSERT(FALSE);
      END;
      s.row:=newLine;
      s.state:=s.memory[newLine DIV stateStep];
    ELSIF (line>s.row) THEN
      IF line DIV stateStep>s.highMark THEN
        newLine:=s.highMark*stateStep;
      ELSE
        newLine:=(line DIV stateStep) * stateStep;
      END;

      IF newLine>s.row THEN
        IF ~s.cursor.Goto(1,newLine-1) THEN
          ASSERT(FALSE);
        END;

        s.row:=newLine;
        s.state:=s.memory[newLine DIV stateStep];
      END;
    END;

    (* Now walk the rest line by line *)

    IF line>s.row THEN
      WHILE (line>s.row) DO

        s.RememberState(s.row,s.state);

        IF ~s.cursor.Goto(1,s.row) THEN
          ASSERT(FALSE);
        END;

        INC(s.row);

        s.rider.GotoRider(s.cursor.rider);
        text:=s.rider.GetLine();
        x:=0;

        WHILE (x<LEN(text^)) & (text[x]#0X) DO
          token:=s.text.syntax.ParseToken(text,x,length,s.state);
          INC(x,length);
        END;

        s.RememberState(s.row,s.state);
      END;
    END;
  END MoveToLine;

  PROCEDURE (c : Cursor) InsertRun(run : R.Run):BOOLEAN;

  VAR
    rider,
    rider2   : Rider;
(*    oldX,*)
    oldY,
    oldPos,
    firstX,
    lastX,
    lines,
    chars,
    oldCY     : LONGINT;
    cursor    : Cursor;
    insertRun : R.Run;
    msg       : CursorMsg;

  BEGIN
    ASSERT(run#NIL);

    IF c.text.readOnly THEN
      RETURN FALSE;
    END;

(*    Err.String("InsertRun"); Err.Ln;*)

    rider:=c.GetRiderAtPos();

    (*
      Check for insertion after end of line.
    *)

    IF c.GetX()>rider.x THEN
      insertRun:=R.CreateRunChars(" ",c.GetX()-c.rider.x);
      insertRun.Append(run);
      c.x:=rider.x;
    ELSE
      insertRun:=run;
    END;

    (*
      Calculate messure of run
      (size of first and last line, number of lines over all)
    *)

    CountText(insertRun,firstX,lastX,lines,chars);

    (*
      Store old position
    *)

    oldPos:=c.GetPos();
    oldY:=c.GetY();

(*    cursor:=c.text.firstCursor;
    WHILE cursor#NIL DO
      Err.String("=> ");cursor.PrintPos; Err.Ln;
      cursor:=cursor.next;
    END;*)

    (*c.PrintPos;Err.Ln;*)

(*    Err.String("r:");Err.Char(rider.run.block.text[rider.blockPos]);
    Err.Char("(");
    Err.LongInt(rider.x,0); Err.Char(",");
    Err.LongInt(rider.yPos,0); Err.Char(",");
    Err.LongInt(rider.blockPos,0); Err.Char(",");
    Err.LongInt(rider.run.pos,0);
    Err.Char(")");Err.Ln;
    rider.run.DumpEnviroment;*)

    rider.run.InsertRunBefore(rider.blockPos,insertRun);
    INC(rider.pos,chars);
    IF lines=0 THEN
      INC(rider.x,firstX);
    ELSE
      rider.x:=lastX+1;
    END;
    INC(rider.yPos,lines);

    IF insertRun.last=NIL THEN
      c.text.first:=insertRun;
    ELSIF (c.text.first=rider.run) & (insertRun.last#NIL) THEN
      c.text.first:=insertRun.last;
    END;

    (*
      Update global data and all cursor behind the insertion point using
      the calculated messurements.
    *)

    NEW(msg);
    cursor:=c.text.firstCursor;
    WHILE cursor#NIL DO
(*          Err.String("3=> "); cursor.PrintPos;Err.Ln;*)
      oldCY:=cursor.GetY();
      IF cursor.GetPos()>=oldPos THEN
        msg.cursor:=cursor;
        msg.oldPos.x:=cursor.GetX();
        msg.oldPos.y:=cursor.GetY();
        msg.oldPos.pos:=cursor.GetPos();

        IF (cursor.GetY()=oldY) THEN
(*          Err.String("- "); cursor.PrintPos;Err.Ln;*)
          IF lines=0 THEN
            INC(cursor.x,firstX);
            INC(cursor.rider.x,firstX);
          ELSE
            cursor.x:=lastX+1;
            cursor.rider.x:=lastX+1;
          END;
        ELSE
(*          Err.String("-- "); cursor.PrintPos;Err.Ln;*)
        END;
        INC(cursor.rider.pos,chars);
        INC(cursor.rider.yPos,lines);
(*        Err.String("$>"); cursor.PrintPos;Err.Ln;*)
      END;

      (*
        Recalculate rider for all cursor that share the same run.
      *)

      IF cursor.rider.run=rider.run THEN
(*       Err.String("+ "); cursor.PrintPos;Err.Ln;*)
        rider2:=rider.Clone();
        IF rider2.GotoPos(cursor.rider.pos) THEN END;
        cursor.rider:=rider2;
(*        Err.String("=>"); cursor.PrintPos;Err.Ln;*)
(*        Err.String("r:");Err.Char(rider2.run.block.text[rider2.blockPos]);
        Err.Char("(");
        Err.LongInt(rider2.x,0); Err.Char(",");
        Err.LongInt(rider2.yPos,0); Err.Char(",");
        Err.LongInt(rider2.blockPos,0); Err.Char(",");
        Err.LongInt(rider2.run.pos,0);
        Err.Char(")");Err.Ln;*)
      END;

      IF cursorFix IN cursor.flags THEN
        IF ~cursor.Goto(1,oldCY) THEN
          ASSERT(FALSE);
        END;
      END;

      cursor:=cursor.next;
    END;

    cursor:=c.text.firstCursor;
    WHILE cursor#NIL DO
      c.text.Notify(msg);
      cursor:=cursor.next;
    END;

    INC(c.text.lines,lines);

    c.text.state.MoveToLine(oldY-1);
    c.text.state.MoveHighMark(oldY-1);

(*    Err.String("r:");Err.Char(c.rider.run.block.text[c.rider.blockPos]);Err.Char("("); Err.LongInt(c.rider.x,0); Err.Char(",");Err.LongInt(c.rider.yPos,0);Err.Char(")");Err.Ln;
    Err.String("c:");Err.Char("("); Err.LongInt(c.x,0); Err.Char(",");Err.LongInt(c.y,0);Err.Char(")");Err.Ln;*)


    c.text.SetChanged(TRUE);

    IF c.text.undoMode=undoUndo THEN
      c.text.CreateUndoInsert(oldPos,chars);
    ELSIF c.text.undoMode=undoRedo THEN
      c.text.CreateRedoInsert(oldPos,chars);
    END;

    c.text.NotifyRedraw(oldY,oldY);

    (*
      Create a message for inserted lines
    *)

    IF lines>0 THEN
      c.text.NotifyInsert(oldY+1,lines);
    END;

(*    Err.String("InsertRun (done)"); Err.Ln;*)

    RETURN TRUE;
  END InsertRun;

  PROCEDURE (c : Cursor) InsertString*(string[NO_COPY] : ARRAY OF CHAR):BOOLEAN;

  BEGIN
    IF string="" THEN
      RETURN TRUE;
    ELSE
      RETURN c.InsertRun(R.CreateRunString(string,str.Length(string)));
    END;
  END InsertString;

  PROCEDURE (c : Cursor) InsertChar*(char : CHAR):BOOLEAN;

  VAR
    buffer : ARRAY 2 OF CHAR;

  BEGIN
    buffer[0]:=char;
    buffer[1]:=0X;
    RETURN c.InsertString(buffer);
  END InsertChar;

  PROCEDURE (c : Cursor) InsertChars*(char : CHAR; count : LONGINT):BOOLEAN;

  BEGIN
    RETURN c.InsertRun(R.CreateRunChars(char,count));
  END InsertChars;

  PROCEDURE (c : Cursor) InsertBuffer*(buffer : Buffer):BOOLEAN;

  BEGIN
    RETURN c.InsertRun(buffer.GetRunCopy());
  END InsertBuffer;

  PROCEDURE (c : Cursor) GotoNextOccurence*(string : ARRAY OF CHAR; case : BOOLEAN):BOOLEAN;

  VAR
    a,b    : Rider;
    x,
    length : LONGINT;

  BEGIN
    length:=str.Length(string);
    IF length=0 THEN
      RETURN FALSE;
    END;

    a:=c.GetRiderAtPos();
    IF ~a.Forward() THEN (* currently we start searching at the next char *)
      RETURN FALSE;
    END;

    (* For speed, we duplicate the code *)
    IF case THEN
      REPEAT
        IF a.run.block.text[a.blockPos]=string[0] THEN
          x:=0;
          b:=a.Clone();
          WHILE (b.run.block.text[b.blockPos]=string[x]) DO
            INC(x);
            IF (x<LEN(string)) & (x<length) THEN
              IF ~b.Forward() THEN (* End of text *)
                RETURN FALSE;
              END;
            END;
          END;

          IF (x>=LEN(string)) OR (x=length) THEN
            c.GotoRider(a);
            RETURN TRUE;
          END;
        END;
      UNTIL ~a.Forward();
    ELSE
      FOR x:=0 TO length-1 DO
        string[x]:=CAP(string[x]);
      END;

      REPEAT
        IF CAP(a.run.block.text[a.blockPos])=string[0] THEN
          x:=0;
          b:=a.Clone();
          WHILE (CAP(b.run.block.text[b.blockPos])=string[x]) DO
            INC(x);
            IF (x<LEN(string)) & (x<length) THEN
              IF ~b.Forward() THEN (* End of text *)
                RETURN FALSE;
              END;
            END;
          END;

          IF (x>=LEN(string)) OR (x=length) THEN
            c.GotoRider(a);
            RETURN TRUE;
          END;
        END;
      UNTIL ~a.Forward();
    END;

    RETURN FALSE;
  END GotoNextOccurence;

  PROCEDURE (t : Text) CountLines;

  VAR
    rider : Rider;

  BEGIN
    NEW(rider);
    rider.Init;

    rider.run:=t.first;
    rider.blockPos:=rider.run.pos;

    rider.pos:=0;
    rider.x:=1;
    rider.yPos:=1;

    t.lines:=1;
    WHILE rider.MoveNextLine() DO
      INC(t.lines);
    END;
  END CountLines;

  PROCEDURE (t : Text) ResetCursors;

  VAR
    cursor : Cursor;

  BEGIN
    cursor:=t.firstCursor;
    WHILE cursor#NIL DO
      cursor.UnlinkText;
      cursor.LinkText(t);
      cursor:=cursor.next;
    END;
  END ResetCursors;

  PROCEDURE (t : Text) SetText*(text[NO_COPY] : ARRAY OF CHAR;
                                length : LONGINT;
                                syntax : S.Syntax);

  VAR
    run,
    last : R.Run;

  BEGIN
    t.first:=R.CreateRunString(text,length);
    IF t.first#NIL THEN
      last:=t.first;
      WHILE last.next#NIL DO
        last:=last.next;
      END;

      run:=R.CreateRunChar(Ascii.eot);

      last.next:=run;
      run.last:=last;
    ELSE
      t.first:=R.CreateRunChar(Ascii.eot);
    END;

    t.CountLines;
    t.ResetCursors;
    t.fileName:=NIL;
    t.SetChanged(FALSE);
    t.SetReadOnly(FALSE);
    t.syntax:=syntax;

    NEW(t.state); (* why? *)
    t.state.Init(t);

    t.state.MoveHighMark(1);

    t.Notify(NIL);
  END SetText;

  PROCEDURE (t : Text) Clear*;

  BEGIN
    t.SetText("",0,Standard.syntax);
  END Clear;

  PROCEDURE (t : Text) Init*;

  BEGIN
    t.Init^;

    t.firstCursor:=NIL;
    t.lastCursor:=NIL;

    t.undoMode:=undoUndo;
    t.undoStack:=NIL;
    t.redoStack:=NIL;

    t.Clear;

    NEW(t.state);
    t.state.Init(t);
  END Init;

  PROCEDURE (t : Text) IsEmpty*():BOOLEAN;

  BEGIN
    RETURN (t.first=NIL) OR ((t.first.next=NIL) & (t.first.length=1));
  END IsEmpty;

  PROCEDURE (t : Text) DeleteArea*(markA,markB : Cursor):BOOLEAN;

  VAR
    run       : R.Run;
    riderA,
    riderB    : Rider;
    firstX,
    lastX,
    lines,
    chars,
    oldX,
    oldX2,
    oldY,
    oldCY,
    oldPos    : LONGINT;
    cursor    : Cursor;
    msg       : CursorMsg;

  BEGIN
    ASSERT(markA.GetPos()<markB.GetPos());

    IF t.readOnly THEN
      RETURN FALSE;
    END;

(*    Err.String("DeleteArea"); Err.Ln;*)
    t.state.MoveToLine(markA.GetY()-1);
    t.state.MoveHighMark(markA.GetY()-1);

    (*markA.PrintPos;markB.PrintPos;Err.Ln;*)

    oldX:=markA.GetX();
    oldX2:=markB.GetX();
    oldPos:=markB.GetPos();
    oldY:=markB.GetY();

    IF markA.GetX()>markA.GetLineLength()+1 THEN
      (*Err.String("Need to fill!!!"); Err.Ln;*)
      IF markA.GotoColumn(markA.GetLineLength()+1) THEN
        IF markA.InsertChars(" ",oldX-markA.GetLineLength()-1) THEN END;
      END;
    END;

    (*markA.PrintPos;markB.PrintPos;Err.Ln;*)

    (* get the two riders pointing to the cursor positions *)
    riderA:=markA.GetRiderAtPos();
    riderB:=markB.GetRiderAtPos();

    (* delete everything within the area *)
    run:=R.JoinRuns(riderA.run,riderA.blockPos,
                    riderB.run,riderB.blockPos);

    IF riderB.run.last=NIL THEN
      t.first:=riderB.run;
    END;

    (*
      Calculate messure of run
      (size of first and last line, number of lines over all)
    *)

    CountText(run,firstX,lastX,lines,chars);

    (* Fix cursors and global data *)

(*    markA.PrintPos;Err.Ln;
    markB.PrintPos;Err.Ln;*)

    NEW(msg);
    cursor:=t.firstCursor;
    WHILE cursor#NIL DO
      oldCY:=cursor.GetY();

      msg.cursor:=cursor;
      msg.oldPos.x:=cursor.GetX();
      msg.oldPos.y:=cursor.GetY();
      msg.oldPos.pos:=cursor.GetPos();

      (*cursor.PrintPos; Err.Ln;*)

      (*
        All cursor within the deleted area are placed at the
        start of the deleted block. They get the run of markB, but
        the coordinates of markA.
      *)
      IF (cursor.GetPos()>=markA.GetPos()) & (cursor.GetPos()<=markB.GetPos()) THEN
        (*Err.String("-1 ");cursor.PrintPos;Err.Ln;*)
        cursor.rider:=riderB.Clone();
        cursor.rider.pos:=riderA.pos;
        cursor.rider.yPos:=riderA.yPos;
        cursor.rider.x:=riderA.x;
        cursor.x:=riderA.x;
      ELSIF cursor.GetPos()>oldPos THEN
        IF cursor.rider.run=markA.rider.run THEN
          oldPos:=cursor.GetPos();
          cursor.rider:=riderB.Clone();
          cursor.rider.pos:=riderA.pos;
          cursor.rider.yPos:=riderA.yPos;
          cursor.rider.x:=riderA.x;
          cursor.x:=riderA.x;
          IF cursor.Move(oldPos-riderA.pos-chars) THEN END;
        ELSE
          (*Err.String("-2 ");cursor.PrintPos;Err.Ln;*)
          IF cursor.GetY()=oldY THEN
            IF lines=0 THEN
              (*Err.String("-3 ");cursor.PrintPos;Err.Ln;*)
              DEC(cursor.x,firstX);
              DEC(cursor.rider.x,firstX);
          ELSE
            (*Err.String("-4 ");cursor.PrintPos;Err.Ln;*)
            cursor.x:=oldX+cursor.x-oldX2;
            cursor.rider.x:=oldX+cursor.rider.x-oldX2;
          END;
          END;
          DEC(cursor.rider.yPos,lines);
          DEC(cursor.rider.pos,chars);
        END;
      END;
      (*Err.String("=>");cursor.PrintPos;Err.Ln;*)

      IF cursorFix IN cursor.flags THEN
        IF cursor.Goto(1,oldCY) THEN END;
      END;
      t.Notify(msg);

      cursor:=cursor.next;
    END;

    DEC(t.lines,lines);

    t.SetChanged(TRUE);

    IF t.undoMode=undoUndo THEN
      t.CreateUndoDelete(markA.GetPos(),run);
    ELSIF t.undoMode=undoRedo THEN
      t.CreateRedoDelete(markA.GetPos(),run);
    END;

    t.NotifyRedraw(markA.GetY(),markA.GetY());

    IF lines>0 THEN
      t.NotifyDelete(markA.GetY()+1,lines);
    END;

    RETURN TRUE;
  END DeleteArea;

  PROCEDURE (t : Text) CopyArea*(markA,markB : Cursor):Buffer;

  VAR
    riderA,
    riderB  : Rider;
    start,
    last,
    current,
    run     : R.Run;
    buffer  : Buffer;

  BEGIN
    (*Err.String("CopyArea"); Err.Ln;*)
    riderA:=markA.GetRiderAtPos();
    riderB:=markB.GetRiderAtPos();

    start:=NIL;
    last:=NIL;
    run:=riderA.run;
    WHILE run#riderB.run.next DO
      current:=run.Copy();
      IF start=NIL THEN
        start:=current;
        start.last:=NIL;
      ELSE
        last.next:=current;
        current.last:=last;
      END;
      last:=current;

      run:=run.next;
    END;

    last.next:=NIL;

    DEC(start.length,riderA.blockPos-riderA.run.pos);
    start.pos:=riderA.blockPos;
    IF start.length=0 THEN
      start:=start.next;
      start.last:=NIL;
    END;

    last.length:=riderB.blockPos-last.pos;
    IF last.length=0 THEN
      IF last.last=NIL THEN (* first run *)
        start:=NIL;
      ELSE
        last.last.next:=NIL;
      END;
    END;

    NEW(buffer);
    buffer.Init;
    buffer.SetRun(start);

    RETURN buffer;
  END CopyArea;

  PROCEDURE (t : Text) CreateNewUndoGroup*;

  VAR
    group : UndoGroup;

  BEGIN
    IF (t.undoStack=NIL) OR (t.undoStack.first#NIL) THEN
      NEW(group);
      group.last:=t.undoStack;
      group.first:=NIL;
      group.changed:=t.changed;
      t.undoStack:=group;
    END;
  END CreateNewUndoGroup;

  PROCEDURE (t : Text) CreateNewRedoGroup*;

  VAR
    group : UndoGroup;

  BEGIN
    IF (t.redoStack=NIL) OR (t.redoStack.first#NIL) THEN
      NEW(group);
      group.last:=t.redoStack;
      group.first:=NIL;
      group.changed:=t.changed;
      t.redoStack:=group;
    END;
  END CreateNewRedoGroup;

  PROCEDURE (t : Text) UndoStep*(cursor, cursor2 : Cursor):BOOLEAN;

  (**
    Make a undo with the help of the two handed cursors. We expect at least
    cursor to be valid.
  *)

  VAR
    entry : UndoEntry;
    res   : BOOLEAN;

  BEGIN
    IF (t.undoStack#NIL) & (t.undoStack.first=NIL) THEN
      (* remove empty undo group created before this call *)
      t.undoStack:=t.undoStack.last;
    END;

    IF t.undoStack=NIL THEN
      RETURN FALSE;
    END;

    t.undoMode:=undoRedo;
    t.CreateNewRedoGroup;

    entry:=t.undoStack.first;

    WHILE entry#NIL DO
      res:=FALSE;
      WITH entry : UndoInsert DO
        IF cursor.GotoPos(entry.pos) THEN
          cursor2.GotoCursor(cursor);
          IF cursor2.GotoPos(entry.pos+entry.count) THEN
            res:=t.DeleteArea(cursor,cursor2);
          ELSE
            (* TODO: Restaurate position of cursor *)
          END;
        END;
      | entry : UndoDelete DO
        IF cursor.GotoPos(entry.pos) THEN
          res:=cursor.InsertRun(entry.text);
        END;
      END;

      IF res THEN
        entry:=entry.next;
      ELSE
        entry:=NIL;
      END;
    END;

    IF t.undoStack.changed#t.changed THEN
      t.SetChanged(t.undoStack.changed);
    END;

    t.undoStack:=t.undoStack.last;

    t.undoMode:=undoUndo;

    RETURN TRUE;
  END UndoStep;

  PROCEDURE (t : Text) RedoStep*(cursor, cursor2 : Cursor):BOOLEAN;

  (**
    Make a undo with the help of the two handed cursors. We expect at least
    cursor to be valid.
  *)

  VAR
    entry : UndoEntry;
    res   : BOOLEAN;

  BEGIN
    IF t.redoStack=NIL THEN
      RETURN FALSE;
    END;

    entry:=t.redoStack.first;

    WHILE entry#NIL DO
      res:=FALSE;
      WITH entry : UndoInsert DO
        IF cursor.GotoPos(entry.pos) THEN
          cursor2.GotoCursor(cursor);
          IF cursor2.GotoPos(entry.pos+entry.count) THEN
            res:=t.DeleteArea(cursor,cursor2);
          ELSE
            (* TODO: Restaurate position of cursor *)
          END;
        END;
      | entry : UndoDelete DO
        IF cursor.GotoPos(entry.pos) THEN
          res:=cursor.InsertRun(entry.text);
        END;
      END;

      IF res THEN
        entry:=entry.next;
      ELSE
        entry:=NIL;
      END;
    END;

    IF t.redoStack.changed#t.changed THEN
      t.SetChanged(t.redoStack.changed);
    END;

    t.redoStack:=t.redoStack.last;

    RETURN TRUE;
  END RedoStep;

  PROCEDURE (t : Text) SetFileName*(name : STRING; syntax : S.Syntax);

  BEGIN
    t.fileName:=name;
    t.syntax:=syntax;

    t.NotifyNameChanged;
  END SetFileName;

  PROCEDURE (t : Text) HasFileName*():BOOLEAN;

  BEGIN
    RETURN (t.fileName#NIL) & (t.fileName.length>0);
  END HasFileName;

  PROCEDURE (t : Text) LoadFromFile*(name : STRING;
                                     syntax : S.Syntax) RAISES IO.Error;

  (**
    Reads the given file into the text.
  *)

  VAR
    file      : IOB.Channel;

    size,
    blockSize : LONGINT;

    x,blocks  : LONGINT;
    first,
    last,run  : R.Run;
    buffer    : ARRAY B.blockLen OF CHAR;

  BEGIN
    first:=NIL;

    file:=FileChannel.Open(name,{FileChannel.read});

    size:=file.base(FileChannel.Channel).Length();
    blocks:=size DIV B.blockLen;
    IF size MOD B.blockLen#0 THEN
      INC(blocks);
    END;

    last:=NIL;

    IF blocks#0 THEN

      x:=1;

      WHILE (x<=blocks) DO

        IF x<blocks THEN
          blockSize:=LEN(buffer);
        ELSE
          blockSize:=size - (blocks-1)*LEN(buffer);
        END;

        IF file.Read(buffer,0,blockSize)<=0 THEN END;

        run:=R.CreateRunString(buffer,blockSize);

        IF last=NIL THEN
          first:=run;
        ELSE
          last.next:=run;
          run.last:=last;
        END;
        last:=run;

        INC(x);
      END;
    END;

    run:=R.CreateRunChar(Ascii.eot);

    IF last=NIL THEN
      first:=run;
    ELSE
      last.next:=run;
      run.last:=last;
    END;
    last:=run;

    file.Close;

    t.first:=first;
    t.SetChanged(FALSE);
    t.SetFileName(name,syntax);
    t.CountLines;
    t.ResetCursors;
    t.state.MoveHighMark(1);

    t.SetReadOnly(FALSE);
    TRY
      file:=FileChannel.Open(name,{FileChannel.write});
      file.Close;
    CATCH IO.Error:
      t.SetReadOnly(TRUE);
    END;

    t.Notify(NIL);
  END LoadFromFile;

  PROCEDURE (t : Text) SaveToFile*(name : STRING;
                                   stripTrailingSpace : BOOLEAN) RAISES IO.Error;

    (**
      Save the text in the given text to a file.
    *)

  VAR
    file   : IO.ByteChannel;
    start  : R.Run;
    x,y,
    end    : LONGINT;
    tmp    : U.Text;
    res    : BOOLEAN;

    PROCEDURE SaveLine() RAISES IO.Error;

    BEGIN
      IF stripTrailingSpace THEN
        WHILE (x>0) & (globalText[x-1]=" ") DO
          DEC(x);
        END;
      END;

      IF file.Write(globalText^,0,x)<=0 THEN END;
    END SaveLine;

    PROCEDURE WriteEOL() RAISES IO.Error;

    VAR
      tmp : ARRAY 1 OF CHAR;

    BEGIN
      tmp[0]:=Ascii.lf;
      IF file.Write(tmp,0,1)<=0 THEN END;
    END WriteEOL;

  BEGIN
    res:=TRUE;

    (*
      First try to open existing file. This way we don't modify the
      filesystem flags
    *)
    TRY
      file:=FileChannel.Open(name,{FileChannel.write,
                                   FileChannel.truncate});
    CATCH IO.Error:
      file:=NIL;
    END;

    (* If that does not work, we try to create a new file *)
    IF file=NIL THEN
      file:=FileChannel.Open(name,
                             {FileChannel.create,
                              FileChannel.write,
                              FileChannel.truncate});
    END;

    start:=t.first; (* We do not save the starting newline *)

    x:=0;
    WHILE start#NIL DO
      IF start.next#NIL THEN
        end:=start.pos+start.length-1;
      ELSE
        end:=start.pos+start.length-2;
      END;

      FOR y:=start.pos TO end DO
        IF x>=LEN(globalText^) THEN
          NEW(tmp,LEN(globalText^)*2);
          COPY(globalText^,tmp^);
          globalText:=tmp;
        END;
        globalText[x]:=start.block.text[y];

        IF globalText[x]=Ascii.lf THEN
          SaveLine;
          WriteEOL;
          x:=0;
        ELSE
          INC(x);
        END;
      END;
      start:=start.next;
    END;

    SaveLine;

    file.Close;

    t.SetChanged(FALSE);
  END SaveToFile;

  PROCEDURE CreateBackup*(file,bak : STRING):BOOLEAN;
(*
  VAR
    ires  : INTEGER;

  BEGIN
    of.Delete(bak,ires);
    of.Rename(file,bak,ires);
    RETURN ires=0;*)

  CONST
    bufferSize = 1024*10;

  VAR
    in,out    : FileChannel.Channel;
    size,
    blocks,
    x,
    blockSize : LONGINT;
    buffer    : ARRAY bufferSize OF CHAR;
    result    : BOOLEAN;

  BEGIN
    in:=NIL;
    out:=NIL;
    result:=TRUE;

    TRY
      out:=FileChannel.OpenUnbuffered(bak,
                                      {FileChannel.create,
                                       FileChannel.write,
                                       FileChannel.truncate});
      in:=FileChannel.OpenUnbuffered(file,
                                     {FileChannel.read});

      size:=in.Length();
      blocks:=size DIV bufferSize;
      IF size MOD bufferSize#0 THEN
        INC(blocks);
      END;

      x:=1;
      WHILE (x<=blocks) DO
        IF x<blocks THEN
          blockSize:=LEN(buffer);
        ELSE
          blockSize:=size - (blocks-1)*LEN(buffer);
        END;

        IF in.Read(buffer,0,blockSize)<=0 THEN END;
        IF out.Write(buffer,0,blockSize)<=0 THEN END;

        INC(x);
      END;
    CATCH IO.Error(e):
      result:=FALSE;
    END;

    TRY
      IF in#NIL THEN
        in.Close;
      END;
      IF out#NIL THEN
        out.Close;
      END;
    CATCH IO.Error:
    END;

    RETURN result;
  END CreateBackup;

BEGIN
  NEW(globalText,1024);
END VO:Edit:Text.