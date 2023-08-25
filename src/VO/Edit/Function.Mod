MODULE VO:Edit:Function [OOC_EXTENSIONS];

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

IMPORT D   := VO:Base:Display,
       U   := VO:Base:Util,

       E   := VO:Edit:Edit,
       S   := VO:Edit:Syntax,
       T   := VO:Edit:Text,

              Ascii,
              Object;

  PROCEDURE CursorLeft*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.Goto(e.cursor.GetX()-1,e.cursor.GetY()) THEN END;
  END CursorLeft;

  PROCEDURE CursorLeftSelection*(e : E.Edit);

  BEGIN
    IF e.IsUnselected() THEN
      e.SetStartMark(e.cursor);
    END;
    IF e.cursor.Goto(e.cursor.GetX()-1,e.cursor.GetY()) THEN
      e.SetEndMark(e.cursor);
    END;
  END CursorLeftSelection;

  PROCEDURE CursorRight*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.Goto(e.cursor.GetX()+1,e.cursor.GetY()) THEN END;
  END CursorRight;

  PROCEDURE CursorRightSelection*(e : E.Edit);

  BEGIN
    IF e.IsUnselected() THEN
      e.SetStartMark(e.cursor);
    END;
    IF e.cursor.Goto(e.cursor.GetX()+1,e.cursor.GetY()) THEN
      e.SetEndMark(e.cursor);
    END;
  END CursorRightSelection;

  PROCEDURE CursorUp*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.Goto(e.cursor.GetX(),e.cursor.GetY()-1) THEN END;
  END CursorUp;

  PROCEDURE CursorUpSelection*(e : E.Edit);

  BEGIN
    IF e.IsUnselected() THEN
      e.SetStartMark(e.cursor);
    END;
    IF e.cursor.Goto(e.cursor.GetX(),e.cursor.GetY()-1) THEN
      e.SetEndMark(e.cursor);
    END;
  END CursorUpSelection;

  PROCEDURE CursorDown*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.Goto(e.cursor.GetX(),e.cursor.GetY()+1) THEN END;
  END CursorDown;

  PROCEDURE CursorDownSelection*(e : E.Edit);

  BEGIN
    IF e.IsUnselected() THEN
      e.SetStartMark(e.cursor);
    END;
    IF e.cursor.Goto(e.cursor.GetX(),e.cursor.GetY()+1) THEN
      e.SetEndMark(e.cursor);
    END;
  END CursorDownSelection;

  PROCEDURE CursorPageUp*(e : E.Edit);

  VAR
    y : LONGINT;

  BEGIN
    e.ClearSelection;
    IF e.GetFirstVisiblePos()=1 THEN
      IF e.cursor.Goto(e.cursor.GetX(),1) THEN END;
    ELSE
      y:=e.TextToDisplayPos(e.cursor.GetY());
      e.Page(-(e.vSize-1));
      IF e.cursor.Goto(e.cursor.GetX(),e.DisplayToTextPos(y)) THEN END;
    END;
  END CursorPageUp;

  PROCEDURE CursorPageUpSelection*(e : E.Edit);

  VAR
    y : LONGINT;

  BEGIN
    IF e.IsUnselected() THEN
      e.SetStartMark(e.cursor);
    END;

    IF e.GetFirstVisiblePos()=1 THEN
      IF e.cursor.Goto(e.cursor.GetX(),1) THEN END;
    ELSE
      y:=e.TextToDisplayPos(e.cursor.GetY());
      e.Page(-(e.vSize-1));
      IF e.cursor.Goto(e.cursor.GetX(),e.DisplayToTextPos(y)) THEN END;
    END;

    e.SetEndMark(e.cursor);
  END CursorPageUpSelection;

  PROCEDURE CursorPageDown*(e : E.Edit);

  VAR
    y : LONGINT;

  BEGIN
    e.ClearSelection;
    IF e.GetLastVisiblePos()=e.model.lines THEN
      IF e.cursor.Goto(e.cursor.GetX(),e.model.lines) THEN END;
    ELSE
      y:=e.TextToDisplayPos(e.cursor.GetY());
      e.Page(e.vSize-1);
      y:=e.DisplayToTextPos(y);
      IF y>e.model.lines THEN
        y:=e.model.lines;
      END;
      IF e.cursor.Goto(e.cursor.GetX(),y) THEN END;
    END;
  END CursorPageDown;

  PROCEDURE CursorPageDownSelection*(e : E.Edit);

  VAR
    y : LONGINT;

  BEGIN
    IF e.IsUnselected() THEN
      e.SetStartMark(e.cursor);
    END;

    IF e.GetLastVisiblePos()=e.model.lines THEN
      IF e.cursor.Goto(e.cursor.GetX(),e.model.lines) THEN END;
    ELSE
      y:=e.TextToDisplayPos(e.cursor.GetY());
      e.Page(e.vSize-1);
      y:=e.DisplayToTextPos(y);
      IF y>e.model.lines THEN
        y:=e.model.lines;
      END;
      IF e.cursor.Goto(e.cursor.GetX(),y) THEN END;
    END;

    e.SetEndMark(e.cursor);
  END CursorPageDownSelection;

  PROCEDURE CursorGotoStart*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.GotoPos(0) THEN END;
  END CursorGotoStart;

  PROCEDURE CursorGotoEnd*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.GotoRow(e.model.lines) THEN
      IF e.cursor.GotoColumn(e.cursor.GetLineLength()+1) THEN END;
    END;
  END CursorGotoEnd;

  PROCEDURE CursorSOL*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.GotoColumn(1) THEN END;
  END CursorSOL;

  PROCEDURE CursorEOL*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.GotoColumn(e.cursor.GetLineLength()+1) THEN END;
  END CursorEOL;

  PROCEDURE CursorSOLSelection*(e : E.Edit);

  BEGIN
    IF e.IsUnselected() THEN
      e.SetStartMark(e.cursor);
    END;
    IF e.cursor.GotoColumn(1) THEN
      e.SetEndMark(e.cursor);
    END;
  END CursorSOLSelection;

  PROCEDURE CursorEOLSelection*(e : E.Edit);

  BEGIN
    IF e.IsUnselected() THEN
      e.SetStartMark(e.cursor);
    END;
    IF e.cursor.GotoColumn(e.cursor.GetLineLength()+1) THEN
      e.SetEndMark(e.cursor);
    END;
  END CursorEOLSelection;

  PROCEDURE CursorFirstVisibleRow*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.GotoRow(e.GetFirstVisiblePos()) THEN END;
  END CursorFirstVisibleRow;

  PROCEDURE CursorLastVisibleRow*(e : E.Edit);

  BEGIN
    e.ClearSelection;
    IF e.cursor.GotoRow(e.GetLastVisiblePos()) THEN END;
  END CursorLastVisibleRow;

  PROCEDURE CursorDelete*(e : E.Edit);

  BEGIN
    IF e.readWrite THEN
      IF e.IsSelected() THEN
        e.DeleteSelection;
      ELSE
        (*e.cursor.PrintPos;Err.Ln;*)
        e.tmpCursor.GotoCursor(e.cursor);
        (*e.tmpCursor.PrintPos;Err.Ln;*)
        IF e.tmpCursor.Forward() THEN
          (*e.tmpCursor.PrintPos;Err.Ln;*)
          IF ~e.model.DeleteArea(e.cursor,e.tmpCursor) THEN
            e.DisplayBeep;
          END;
        ELSE
          e.DisplayBeep;
        END;
      END;
    END;
  END CursorDelete;

  PROCEDURE CursorBackspace*(e : E.Edit);

  BEGIN
    IF e.readWrite THEN
      IF e.IsSelected() THEN
        e.DeleteSelection;
      ELSE
        IF e.cursor.GetX()>e.cursor.GetLineLength()+1 THEN
          CursorLeft(e);
        ELSE
          (*e.cursor.PrintPos;Err.Ln;*)
          IF e.cursor.Back() THEN
            CursorDelete(e);
          ELSE
            e.DisplayBeep;
          END;
        END;
      END;
    END;
  END CursorBackspace;

  PROCEDURE CursorSplitLine*(e : E.Edit);

  BEGIN
    IF e.readWrite THEN
      e.DeleteSelection;

      IF e.cursor.InsertChar(Ascii.lf) THEN
        e.MakeCursorVisible(e.cursor);
      ELSE
        e.DisplayBeep;
      END;
    END;
  END CursorSplitLine;

  PROCEDURE CursorDeleteLine*(e : E.Edit);

  VAR
    oldX : LONGINT;

  BEGIN
    e.ClearSelection;

    oldX:=e.cursor.GetX();

    IF e.cursor.GotoColumn(1) THEN
      e.tmpCursor.GotoCursor(e.cursor);
      IF e.tmpCursor.Goto(1,e.cursor.GetY()+1) THEN
        IF e.model.DeleteArea(e.cursor,e.tmpCursor) THEN
          IF e.cursor.GotoColumn(oldX) THEN END;
        ELSE
          e.DisplayBeep;
        END;
      END;
    END;
  END CursorDeleteLine;

  PROCEDURE CursorSelectWord*(e : E.Edit);

  BEGIN
    e.ClearSelection();

    e.tmpCursor.GotoCursor(e.cursor);
    IF e.model.syntax.word[ORD(e.tmpCursor.GetChar())] THEN
      WHILE e.tmpCursor.Left() & e.model.syntax.word[ORD(e.tmpCursor.GetChar())] DO
      END;

      IF ~e.model.syntax.word[ORD(e.tmpCursor.GetChar())] THEN
        IF e.tmpCursor.Right() THEN END;
      END;
      e.SetStartMark(e.tmpCursor);

      e.tmpCursor.GotoCursor(e.cursor);
      WHILE e.tmpCursor.Right() & e.model.syntax.word[ORD(e.tmpCursor.GetChar())] DO
      END;

      e.SetEndMark(e.tmpCursor);
    END;
  END CursorSelectWord;

  PROCEDURE CursorSelectLine*(e : E.Edit);

  BEGIN
    e.tmpCursor.GotoCursor(e.cursor);
    IF e.tmpCursor.GotoColumn(1) THEN END;
    e.SetStartMark(e.tmpCursor);

    IF e.tmpCursor.GotoColumn(e.tmpCursor.GetLineLength()+1) THEN END;
    e.SetEndMark(e.tmpCursor);
  END CursorSelectLine;

  PROCEDURE CursorSelectBlock*(e : E.Edit);

  VAR
    rider    : T.Rider;
    info     : E.LineInfo;
    pos,
    count,x  : LONGINT;
    found    : BOOLEAN;

  BEGIN
    (* search backwards *)

    IF e.IsSelected() THEN
      e.tmpCursor.GotoCursor(e.markA);
      IF e.tmpCursor.Back() THEN END;
      e.tmp2Cursor.GotoCursor(e.markB);
      IF e.tmp2Cursor.Forward() THEN END;
    ELSE
      e.tmpCursor.GotoCursor(e.cursor);
      e.tmp2Cursor.GotoCursor(e.cursor);
    END;

    e.ClearSelection();

    x:=e.tmpCursor.GetX();
    IF e.tmpCursor.GotoColumn(1) THEN END;
    rider:=NIL;
    e.tmpCursor.GetRiderAtSOL(rider);
    info:=e.GetLineTextColored(rider,e.tmpCursor.GetY());

    pos:=0;
    WHILE (pos<LEN(info.text^)) & (info.info[pos].pos<x) DO
      INC(pos);
    END;

    count:=-1;
    found:=FALSE;
    WHILE ~((count=0) & found) DO
      DEC(pos);
      IF pos<0 THEN
        IF ~e.tmpCursor.Goto(1,e.tmpCursor.GetY()-1) THEN
          RETURN;
        END;
        rider:=NIL;
        e.tmpCursor.GetRiderAtSOL(rider);
        info:=e.GetLineTextColored(rider,e.tmpCursor.GetY());
        pos:=LEN(info.text^)-1;
      END;

      IF info.start[pos] THEN
        IF S.BlockStart IN info.token[pos].flags THEN
          found:=TRUE;
          INC(count);
        ELSIF S.BlockEnd IN info.token[pos].flags THEN
          found:=TRUE;
          DEC(count);
        END;
      END;
    END;

    IF e.tmpCursor.GotoColumn(info.info[pos].pos) THEN END;
    e.SetStartMark(e.tmpCursor);

    (* search forward *)

    x:=e.tmp2Cursor.GetX();
    IF e.tmp2Cursor.GotoColumn(1) THEN END;
    rider:=NIL;
    e.tmp2Cursor.GetRiderAtSOL(rider);
    info:=e.GetLineTextColored(rider,e.tmp2Cursor.GetY());

    pos:=0;
    WHILE (pos<LEN(info.text^)) & (info.info[pos].pos<x) DO
      INC(pos);
    END;

    count:=1;
    found:=FALSE;
    WHILE ~((count=0) & found) DO
      INC(pos);
      IF pos>=LEN(info.text^) THEN
        IF ~e.tmp2Cursor.Goto(1,e.tmp2Cursor.GetY()+1) THEN
          RETURN;
        END;
        rider:=NIL;
        e.tmp2Cursor.GetRiderAtSOL(rider);
        info:=e.GetLineTextColored(rider,e.tmp2Cursor.GetY());
        pos:=0;
      END;

      IF info.start[pos] THEN
        IF S.BlockStart IN info.token[pos].flags THEN
          found:=TRUE;
          INC(count);
        ELSIF S.BlockEnd IN info.token[pos].flags THEN
          found:=TRUE;
          DEC(count);
        END;
      END;
    END;

    (* advance to the next token *)
    INC(pos);
    WHILE (pos<LEN(info.start^)) & ~info.start[pos] DO
      INC(pos);
    END;

    IF e.tmp2Cursor.GotoColumn(info.info[pos].pos) THEN END;
    e.SetEndMark(e.tmp2Cursor);
  END CursorSelectBlock;

  PROCEDURE CursorInsertBuffer*(e : E.Edit);

  BEGIN
    IF e.readWrite THEN
      e.DeleteSelection;
      IF ~D.display.GetClipboard(e) THEN
        e.DisplayBeep;
      END;
    END;
  END CursorInsertBuffer;

  PROCEDURE CursorMatchBlock*(e : E.Edit);

  BEGIN
    IF ~e.CursorMatchBlock(e.cursor,FALSE) THEN
      e.DisplayBeep;
    END;
  END CursorMatchBlock;

  PROCEDURE CursorMatchToken*(e : E.Edit);

(*  VAR
    line : T.Line;
    info : LineInfo;
    xPos,
    yPos,
    pos  : LONGINT;*)

  BEGIN
(*    xPos:=e.cursor.GetX();
    yPos:=e.cursor.GetY();
    line:=e.GetLine(yPos);
    info:=e.GetLineTextColored(line,yPos);
    pos:=info.XToPos(xPos);
    IF (info.token[pos]#NIL) & (info.token[pos] IS S.Token) & (info.token[pos](S.Token).match#NIL) THEN
    ELSE
      e.DisplayBeep;
      RETURN;
    END;*)
  END CursorMatchToken;

  PROCEDURE DisplayRefresh*(e : E.Edit);

  BEGIN
    e.Refresh;
  END DisplayRefresh;

  PROCEDURE DisplayScrollUp*(e : E.Edit);

  BEGIN
    IF e.CanScrollUp() THEN
      e.ScrollTo(e.GetFirstVisiblePos()-1);
    END;
  END DisplayScrollUp;

  PROCEDURE DisplayScrollDown*(e : E.Edit);

  BEGIN
    IF e.CanScrollDown() THEN
      e.ScrollTo(e.GetFirstVisiblePos()+1);
    END;
  END DisplayScrollDown;

  PROCEDURE DisplayScrollLeft*(e : E.Edit);

  BEGIN
    IF e.startColumn>1 THEN
      DEC(e.startColumn);
      e.SetDirtyAll;
    END;
  END DisplayScrollLeft;

  PROCEDURE DisplayScrollRight*(e : E.Edit);

  BEGIN
    INC(e.startColumn);
    e.SetDirtyAll;
  END DisplayScrollRight;

  PROCEDURE SelectionCopy*(e : E.Edit);

  VAR
    text   : U.Text;
    string : STRING;
    buffer : T.Buffer;

  BEGIN
    IF e.IsSelected() THEN
      buffer:=e.model.CopyArea(e.GetStartMark(),e.GetEndMark());

      IF buffer#NIL THEN
        text:=buffer.GetTextCopy();
        IF text#NIL THEN
          string:=Object.NewLatin1(text^);
          IF ~D.display.SetClipboard(string) THEN
            e.DisplayBeep;
          END;
        END;
      END;
    ELSE
      e.DisplayBeep;
    END;
  END SelectionCopy;

  PROCEDURE SelectionDelete(e : E.Edit);

  BEGIN
    e.DeleteSelection;
  END SelectionDelete;

  PROCEDURE SelectionCut*(e : E.Edit);

  BEGIN
    SelectionCopy(e);
    SelectionDelete(e);
  END SelectionCut;

  PROCEDURE SelectionClear*(e : E.Edit);

  BEGIN
    e.ClearSelection;
  END SelectionClear;

  PROCEDURE SelectionIndent*(e : E.Edit);

  VAR
    markA,
    markB    : T.Cursor;
    lastLine : LONGINT;

  BEGIN
    IF e.IsSelected() THEN
      markA:=e.GetStartMark();
      markB:=e.GetEndMark();
      e.tmpCursor.GotoCursor(markB);
      IF e.tmpCursor.Back() THEN
        lastLine:=e.tmpCursor.GetY();
        e.tmpCursor.GotoCursor(markA);
        IF e.tmpCursor.GotoColumn(1) THEN
          WHILE e.tmpCursor.GetY()<=lastLine DO
            IF e.tmpCursor.InsertChar(" ") THEN END;
            IF e.tmpCursor.Goto(1,e.tmpCursor.GetY()+1) THEN END;
          END;
        END;
      END;
    ELSE
      e.DisplayBeep;
    END;
  END SelectionIndent;

  PROCEDURE SelectionOutdent*(e : E.Edit);

  VAR
    markA,
    markB    : T.Cursor;
    lastLine : LONGINT;

  BEGIN
    IF e.IsSelected() THEN
      markA:=e.GetStartMark();
      markB:=e.GetEndMark();
      e.tmpCursor.GotoCursor(markB);
      IF e.tmpCursor.Back() THEN
        lastLine:=e.tmpCursor.GetY();
        e.tmpCursor.GotoCursor(markA);
        IF e.tmpCursor.GotoColumn(1) THEN
          WHILE e.tmpCursor.GetY()<=lastLine DO
            IF e.tmpCursor.GetChar()=" " THEN
              e.tmp2Cursor.GotoCursor(e.tmpCursor);
              IF e.tmp2Cursor.Forward() THEN END;
              IF e.model.DeleteArea(e.tmpCursor,e.tmp2Cursor) THEN END;
            END;
            IF e.tmpCursor.Goto(1,e.tmpCursor.GetY()+1) THEN END;
          END;
        END;
      END;
    ELSE
      e.DisplayBeep;
    END;
  END SelectionOutdent;

  PROCEDURE TextSelectAll*(e : E.Edit);

  BEGIN
    e.tmpCursor.GotoCursor(e.cursor);

    IF e.tmpCursor.GotoPos(0) THEN END;
    e.SetStartMark(e.tmpCursor);

    IF e.tmp2Cursor.GotoRow(e.model.lines) THEN
      IF e.tmp2Cursor.GotoColumn(e.tmp2Cursor.GetLineLength()+1) THEN END;
    END;

    e.SetEndMark(e.tmp2Cursor);
  END TextSelectAll;

  PROCEDURE TextUndo*(e : E.Edit);

  BEGIN
    IF ~e.model.UndoStep(e.cursor,e.tmpCursor) THEN
      e.DisplayBeep;
    END;
  END TextUndo;

  PROCEDURE TextRedo*(e : E.Edit);

  BEGIN
    IF ~e.model.RedoStep(e.cursor,e.tmpCursor) THEN
      e.DisplayBeep;
    END;
  END TextRedo;

BEGIN
  E.RegisterFunction("CursorLeft",CursorLeft);
  E.RegisterFunction("CursorRight",CursorRight);
  E.RegisterFunction("CursorUp",CursorUp);
  E.RegisterFunction("CursorDown",CursorDown);
  E.RegisterFunction("CursorLeftSelection",CursorLeftSelection);
  E.RegisterFunction("CursorRightSelection",CursorRightSelection);
  E.RegisterFunction("CursorUpSelection",CursorUpSelection);
  E.RegisterFunction("CursorDownSelection",CursorDownSelection);
  E.RegisterFunction("CursorPageUp",CursorPageUp);
  E.RegisterFunction("CursorPageDown",CursorPageDown);
  E.RegisterFunction("CursorPageUpSelection",CursorPageUpSelection);
  E.RegisterFunction("CursorPageDownSelection",CursorPageDownSelection);
  E.RegisterFunction("CursorGotoStart",CursorGotoStart);
  E.RegisterFunction("CursorGotoEnd",CursorGotoEnd);
  E.RegisterFunction("CursorSOL",CursorSOL);
  E.RegisterFunction("CursorEOL",CursorEOL);
  E.RegisterFunction("CursorSOLSelection",CursorSOLSelection);
  E.RegisterFunction("CursorEOLSelection",CursorEOLSelection);
  E.RegisterFunction("CursorFirstVisibleRow",CursorFirstVisibleRow);
  E.RegisterFunction("CursorLastVisibleRow",CursorLastVisibleRow);
  E.RegisterFunction("CursorDelete",CursorDelete);
  E.RegisterFunction("CursorBackspace",CursorBackspace);
  E.RegisterFunction("CursorSplitLine",CursorSplitLine);
  E.RegisterFunction("CursorDeleteLine",CursorDeleteLine);
  E.RegisterFunction("CursorSelectWord",CursorSelectWord);
  E.RegisterFunction("CursorSelectLine",CursorSelectLine);
  E.RegisterFunction("CursorSelectBlock",CursorSelectBlock);
  E.RegisterFunction("CursorInsertBuffer",CursorInsertBuffer);
  E.RegisterFunction("CursorMatchBlock",CursorMatchBlock);
  E.RegisterFunction("CursorMatchToken",CursorMatchToken);
  E.RegisterFunction("DisplayRefresh",DisplayRefresh);
  E.RegisterFunction("DisplayScrollUp",DisplayScrollUp);
  E.RegisterFunction("DisplayScrollDown",DisplayScrollDown);
  E.RegisterFunction("DisplayScrollLeft",DisplayScrollLeft);
  E.RegisterFunction("DisplayScrollRight",DisplayScrollRight);
  E.RegisterFunction("SelectionCopy",SelectionCopy);
  E.RegisterFunction("SelectionDelete",SelectionDelete);
  E.RegisterFunction("SelectionCut",SelectionCut);
  E.RegisterFunction("SelectionClear",SelectionClear);
  E.RegisterFunction("SelectionIndent",SelectionIndent);
  E.RegisterFunction("SelectionOutdent",SelectionOutdent);
  E.RegisterFunction("TextSelectAll",TextSelectAll);
  E.RegisterFunction("TextUndo",TextUndo);
  E.RegisterFunction("TextRedo",TextRedo);
END VO:Edit:Function.