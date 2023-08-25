MODULE VO:TableView [OOC_EXTENSIONS];

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

IMPORT BG   := VO:Base:Background,
       D    := VO:Base:Display,
       E    := VO:Base:Event,
       F    := VO:Base:Frame,
       O    := VO:Base:Object,
       U    := VO:Base:Util,
       Z    := VO:Base:Size,

       HM   := VO:Model:Header,
       SM   := VO:Model:Selection,
       TM   := VO:Model:Table,
       V    := VO:Model:Value,

       G    := VO:Object,

       str  := Strings;

CONST
  textOffset = 2; (*
                     If a header is drawn, should be the same as the left width
                     of the frame object used for drawing a header cell
                   *)

  (* Events *)
  mouseSelectionMsg* = 0;
  doubleClickMsg*    = 1;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 focusFrame*  : F.Frame;
                 selection*,
                 background2* : G.Background;
               END;

  Table*     = POINTER TO TableDesc;

  Line       = RECORD
                 drawn : BOOLEAN;
               END;

  Lines      = POINTER TO ARRAY OF Line;

  TableDesc* = RECORD (G.ScrollableGadgetDesc)
                 (* The table *)
                 model-       : TM.TableModel;

                 autoSize-    : BOOLEAN;

                (* window dimensions *)
                 vSize        : LONGINT;

                 (* low level text display stuff *)
                 tableWidth,
                 startColumn,
                 startLine,
                 rowHeight    : LONGINT;

                 font         : D.Font;

                 (* visual controls *)
                 top          : V.ValueModel;
                 first        : V.ValueModel;

                 lines        : Lines;
                 linesBak     : Lines;

                (* Move region *)
                 moveRegion   : BOOLEAN;
                 mrCount,
                 mrStart,
                 mrEnd        : LONGINT;
              END;

  MouseSelectionMsg*     = POINTER TO MouseSelectionMsgDesc;
  MouseSelectionMsgDesc* = RECORD (O.MessageDesc)
                           END;

  DoubleClickMsg*     = POINTER TO DoubleClickMsgDesc;
  DoubleClickMsgDesc* = RECORD (O.MessageDesc)
                        END;

VAR
  (* Preferences *)
  prefs*     : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.tableBackgroundColorIndex));
    p.selection:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.fillColorIndex));
    p.background2:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.tableBackground2ColorIndex));

    p.frame:=F.CreateFrame(F.none);

    IF D.display.displayType=D.displayTypeTextual THEN
      p.focusFrame:=F.CreateFrame(F.none);
    ELSE
      p.focusFrame:=F.CreateFrame(F.dottedFocus);
    END;
  END Initialize;

  (* -------- helper ---------- *)

  PROCEDURE (t : Table) GetCell(mx,my : LONGINT; VAR x,y : LONGINT):BOOLEAN;
    (**
      Return the cell under the given coordinates. Returns FALSE if there is no
      cell at the given position.
    *)

  VAR
    start : LONGINT;

  BEGIN
    IF t.model=NIL THEN
      RETURN FALSE;
    END;

    y:=(my-t.y) DIV t.rowHeight+1;

    IF (y<1) OR (y+t.vAdjustment.GetTop()-1>t.vAdjustment.GetTotal()) THEN
      RETURN FALSE;
    END;

    INC(y,t.vAdjustment.GetTop()-1);
    DEC(mx,t.x-t.hAdjustment.GetTop());

    start:=0;
    FOR x:=0 TO t.model.GetColumns()-1 DO
      IF (mx>=start) & (mx<start+t.model.GetColumnWidth(x)) THEN
        RETURN TRUE;
      END;
      INC(start,t.model.GetColumnWidth(x));
    END;

    RETURN FALSE;
  END GetCell;

  PROCEDURE (e : Table) GetFirstVisiblePos*():LONGINT;

  BEGIN
    RETURN e.startLine;
  END GetFirstVisiblePos;

  PROCEDURE (e : Table) GetLastVisiblePos*():LONGINT;

  VAR
    last : LONGINT;

  BEGIN
    last:=e.startLine+e.vSize-1;

    IF last>e.model.GetRows() THEN
      last:=e.model.GetRows();
    END;

    RETURN last;
  END GetLastVisiblePos;

  PROCEDURE (e : Table) IsVisible*(y : LONGINT):BOOLEAN;

  BEGIN
    RETURN (e.GetFirstVisiblePos()<=y) & (y<=e.GetLastVisiblePos());
  END IsVisible;

  (* -------- lines handling ---------- *)

  PROCEDURE (e : Table) ToggleBackup;

  VAR
    help : Lines;

  BEGIN
    help:=e.linesBak;
    e.linesBak:=e.lines;
    e.lines:=help;
  END ToggleBackup;

  PROCEDURE (e : Table) MakeLinesBackup;

  (**
    Fill line backup array.
  *)

  VAR
    x : LONGINT;

  BEGIN
    FOR x:=0 TO LEN(e.lines^)-1 DO
      e.linesBak[x]:=e.lines[x];
    END;
  END MakeLinesBackup;

  PROCEDURE (e : Table) SetDirtyVisibleRange(a,b : LONGINT);

  BEGIN
    DEC(a);
    WHILE a<b DO
      e.lines[a].drawn:=FALSE;
      INC(a);
    END;
  END SetDirtyVisibleRange;

  PROCEDURE (e : Table) SetDirtyRange(y1,y2 : LONGINT);

  (**
    Mark the given range of lines (text relative y coordinate) dirty.
  *)

  VAR
    x : LONGINT;

  BEGIN
    IF (y1>e.GetLastVisiblePos()) OR (y2<e.GetFirstVisiblePos()) THEN
      RETURN;
    END;

    IF y1<e.GetFirstVisiblePos() THEN
      y1:=e.GetFirstVisiblePos();
    END;
    IF y2>e.GetLastVisiblePos() THEN
      y2:=e.GetLastVisiblePos();
    END;

    (* Could use SetDirty and transaformation of coords here *)

    FOR x:=y1 TO y2 DO
      e.lines[x-e.GetFirstVisiblePos()].drawn:=FALSE;
    END;
  END SetDirtyRange;

  PROCEDURE (e : Table) SetDirtyLine(y : LONGINT);

  BEGIN
    e.SetDirtyRange(y,y);
  END SetDirtyLine;


  PROCEDURE (e : Table) SetDirtyAll*;

  (**
    Mark everything as dirty.

    TODO
    Fix export rights.
  *)

  BEGIN
    e.SetDirtyVisibleRange(1,e.GetLastVisiblePos()-e.GetFirstVisiblePos()+1);
  END SetDirtyAll;

  PROCEDURE (e : Table) UpdateDeleteLines(from, count : LONGINT);

  (**
    Update the display, when the given lines are deleted.
  *)

(*
  VAR
    x    : LONGINT;
    line : R.LineRun;*)

  BEGIN
    IF e.IsVisible(from) OR e.IsVisible(from+count) THEN
      e.SetDirtyAll; (* TODO: ! *)

(*    IF (from>=e.startPos) & (from<=e.endPos) THEN
      IF e.view.startLine.last#NIL THEN
        e.view.startLine:=e.view.startLine.last.next(R.LineRun);
      END;

      line:=e.view.startLine;
      x:=1;
      WHILE(x<=e.view.vSize) & (line#NIL) DO
        IF ~e.IsSameLine(line,x) THEN
          e.SetLine(line,x);
        END;
        IF line#NIL THEN
          e.endLine:=line;
        END;
        line:=line.NextLine();
        INC(x);
      END;
      WHILE x<=e.view.vSize DO
        IF ~e.IsSameLine(NIL,x) THEN
          e.SetLine(NIL,x);
        END;
        INC(x);
      END;
      e.endPos:=e.startPos+LEN(e.view.lines^)-1;*)
    END;
  END UpdateDeleteLines;

  PROCEDURE (e : Table) UpdateInsertLines(from, count : LONGINT);

  (**
    Update the display, when the given lines are inserted.
  *)

(*  VAR
    x    : LONGINT;
    line : R.LineRun;*)

  BEGIN
    IF e.IsVisible(from) THEN
      e.SetDirtyRange(from,MAX(LONGINT));

      (* TODO: we can check if we can move parts of the display *)
    END;
  END UpdateInsertLines;

  PROCEDURE (e : Table) ResizeLines;

  VAR
    x  : LONGINT;

  BEGIN
    NEW(e.lines,e.vSize);
    FOR x:=0 TO e.vSize-1 DO
      e.lines[x].drawn:=FALSE;
    END;
    NEW(e.linesBak,e.vSize);
    FOR x:=0 TO e.vSize-1 DO
      e.linesBak[x].drawn:=FALSE;
    END;
  END ResizeLines;

  (* -------- drawing stub ---------- *)

  PROCEDURE (e : Table) MoveRegion(start, end : LONGINT; count : LONGINT);

  (**
    Move the given range of lines (display relative) the given amount up
    or down on the display.

    NOTE
    Only the lines array itself will be update. All other elements must
    be updated manually.
  *)

  VAR
    x : LONGINT;

  BEGIN
    IF count=0 THEN
      RETURN;
    END;

    e.MakeLinesBackup;

    IF count<0 THEN
      FOR x:=start-1 TO end-1 DO
        e.linesBak[x].drawn:=TRUE;
        e.linesBak[x+count]:=e.lines[x];
      END;
    ELSE
      FOR x:=end-1 TO start-1 BY -1 DO
        e.linesBak[x].drawn:=TRUE;
        e.linesBak[x+count]:=e.lines[x];
      END;
    END;

    IF ~e.moveRegion THEN
      e.moveRegion:=TRUE;
      e.mrCount:=count;
      e.mrStart:=start;
      e.mrEnd:=end;
    ELSE
      FOR x:=start-1 TO end-1 DO
        e.linesBak[x+count].drawn:=FALSE;
      END;
    END;

    e.ToggleBackup;
  END MoveRegion;

  (* -------- positioning --------- *)

  PROCEDURE (e : Table) Page*(lines : LONGINT);

  VAR
    count,
    endLine : LONGINT;

  BEGIN
    (* Moving visible area *)
    count:=0;
    endLine:=e.GetLastVisiblePos();

    IF lines>0 THEN (* paging down *)
      WHILE (count<lines) & (endLine<e.model.GetRows()) DO
        INC(e.startLine);
        INC(endLine);
        INC(count);
      END;
    ELSIF lines<0 THEN (* paging up *)
      WHILE (-count<-lines) & (e.startLine>1) DO
        DEC(e.startLine);
        DEC(endLine);
        DEC(count);
      END;
    ELSE
      RETURN;
    END;

    (* Updating display. Count=0 will be droped silently *)

    IF (ABS(count)>e.vSize) THEN
      e.SetDirtyAll;
    ELSIF count>0 THEN
      e.MoveRegion(count+1,e.vSize,-count);
      e.SetDirtyVisibleRange(e.vSize-count+1,e.vSize);
    ELSIF count<0 THEN
      e.MoveRegion(1,e.vSize+count,-count);
      e.SetDirtyVisibleRange(1,-count);
    END;
  END Page;

  PROCEDURE (e : Table) ScrollTo*(lines : LONGINT);

  BEGIN
    ASSERT((lines>=1) & (lines<=e.model.GetRows()));

    (* Convert absolute to relative coordinates *)
    lines:=lines-e.GetFirstVisiblePos();

    e.Page(lines);
  END ScrollTo;

  PROCEDURE (t : Table) IsRowVisible*(row : LONGINT):BOOLEAN;

  BEGIN
    RETURN (row>=t.vAdjustment.GetTop()) & (row<=t.vAdjustment.GetTop()+t.vAdjustment.GetVisible());
  END IsRowVisible;

  PROCEDURE (e : Table) MakeVisible*(x,y : LONGINT);

    (**
      Redisplay text in that way, that the given point can be seen
    *)

  VAR
    i,pos : LONGINT;
  BEGIN

    e.vAdjustment.MakeVisible(y);

    pos:=0;
    FOR i:=0 TO x-2 DO
      INC(pos,e.model.GetColumnWidth(i));
    END;

    e.hAdjustment.MakeVisible(pos);
  END MakeVisible;

  PROCEDURE (e : Table) Init*;

  BEGIN
    e.Init^;

    e.SetFlags({G.canFocus});
    e.RemoveFlags({G.stdFocus});

    e.SetPrefs(prefs);

    e.top:=e.vAdjustment.GetTopModel();
    e.first:=e.hAdjustment.GetTopModel();

    e.SetObjectFrame(F.CreateFrame(F.none));

    e.model:=NIL;
    e.vSize:=0;
    e.rowHeight:=0;
    e.autoSize:=FALSE;

    e.font:=D.normalFont;

    e.ResizeLines;
  END Init;

  PROCEDURE (t : Table) SetAutoSize*(autoSize : BOOLEAN);

    (**
      If @oparam{autoSize} is @code{TRUE}, the initial height of the
      table is be set that way, that all entries are visible.

      Use @oproc{G.Object.SetMaxHeight} the restrict the maximum
      height of the table. Be aware that the table might exceed
      streen height, if do not.
    *)

  BEGIN
    t.autoSize:=autoSize;
  END SetAutoSize;

  PROCEDURE (t : Table) SetRowHeight*(height : LONGINT);

    (**
      Set the height of a single row in the table to a non-standard value.
      By default, the row height is choosen that way, that text using the
      standard font is completly visible. A non-standard height might be
      necessary if you choose a non-standard font are graphical elements.
    *)

  BEGIN
    t.rowHeight:=height;
  END SetRowHeight;

  PROCEDURE (e : Table) RecalcTableWidth;

  VAR
    column : LONGINT;

  BEGIN
    e.tableWidth:=0;
    FOR column:=0 TO e.model.GetColumns()-1 DO
      INC(e.tableWidth,e.model.GetColumnWidth(column));
    END;
  END RecalcTableWidth;

  PROCEDURE (e : Table) InitText;

  BEGIN
    e.startColumn:=1;
    e.startLine:=1;

    e.RecalcTableWidth;
    e.SetDirtyAll;
  END InitText;

  PROCEDURE (e : Table) SetModel*(model : O.Model);

  BEGIN
    IF e.model#NIL THEN
      IF e.model.header#NIL THEN
        e.UnattachModel(e.model.header);
      END;
      e.UnattachModel(e.model);
    END;
    IF (model#NIL) & (model IS TM.TableModel) THEN
      e.model:=model(TM.TableModel);
      e.InitText;
      e.AttachModel(model);
      IF e.model.header#NIL THEN
        e.AttachModel(e.model.header);
      END;
    ELSE
      e.model:=NIL;
    END;
  END SetModel;

  PROCEDURE (e : Table) FitColumn*(column : LONGINT);

  VAR
    y,
    width  : LONGINT;
    string : STRING;
    text   : U.Text;
    extent : D.FontExtentDesc;
    object : G.Object;

  BEGIN
    IF (e.model=NIL) OR (e.model.header=NIL) THEN
      RETURN;
    END;

    width:=D.display.spaceWidth;
    FOR y:=1 TO e.model.GetRows() DO
      string:=e.model.GetString(column,y);
      IF string#NIL THEN
        e.font.StrExtent(string,{},extent);
        width:=U.MaxLong(width,extent.rbearing-extent.lbearing+2*textOffset);
      ELSE
        text:=e.model.GetText(column,y);
        IF text#NIL THEN
          e.font.TextExtent(text^,str.Length(text^),{},extent);
          width:=U.MaxLong(width,extent.rbearing-extent.lbearing+2*textOffset);
        ELSE
          object:=e.model.GetObject(column,y);
          IF object#NIL THEN
            IF ~(G.inited IN object.flags) OR (object.GetWindow()#e.GetWindow()) THEN
              object.SetWindow(e.GetWindow());
              object.SetParent(e);
              object.CalcSize;
            END;
            width:=U.MaxLong(width,object.oWidth);
          END;
        END;
      END;
    END;

    e.model.header.SetLabelSize(column-1,Z.pixel,width);
  END FitColumn;

  (* -------- Displaying ---------- *)

  PROCEDURE (e : Table) UpdateStatus;

  BEGIN
    e.vAdjustment.Set(e.GetFirstVisiblePos(),
                      e.GetLastVisiblePos()-e.GetFirstVisiblePos()+1,
                      e.model.GetRows());

    e.RecalcTableWidth;
    e.hAdjustment.Set(e.startColumn,
                      e.width,
                      e.tableWidth);
  END UpdateStatus;

  (* ---------- Printing --------------- *)

  PROCEDURE (e : Table) DrawCell(draw :  D.DrawInfo;
                                 xPos,
                                 yPos,
                                 width,
                                 height,
                                 x,y    : LONGINT);

  VAR
    string    : STRING;
    text      : U.Text;
    selected,
    cliped    : BOOLEAN;
    textStart,
    textWidth,
    length,
    alignment : LONGINT;
    extent    : D.FontExtentDesc;
    object    : G.Object;

  BEGIN
    selected:=e.model.selection.IsLineSelected(y) OR e.model.selection.IsCellSelected(x,y);
    alignment:=e.model.GetAlignment(x,y);

    IF selected THEN
      e.prefs(Prefs).selection.DrawRelObject(draw,e,U.MaxLong(e.x,xPos),yPos,U.MinLong(e.width,width),height);
      draw.PushForeground(D.fillTextColor);
    ELSIF y MOD 2#0 THEN
      e.prefs(Prefs).background.DrawRelObject(draw,e,U.MaxLong(e.x,xPos),yPos,U.MinLong(e.width,width),height);
      draw.PushForeground(D.tableTextColor);
    ELSE
      e.prefs(Prefs).background2.DrawRelObject(draw,e,U.MaxLong(e.x,xPos),yPos,U.MinLong(e.width,width),height);
      draw.PushForeground(D.tableTextColor);
    END;

    cliped:=FALSE;
    string:=e.model.GetString(x,y);
    IF string#NIL THEN
      e.font.StrExtent(string,{},extent);
      textWidth:=extent.rbearing-extent.lbearing;
      cliped:=textWidth>width;

      IF cliped THEN
        draw.InstallClip(xPos,yPos,width,height);
      END;

      CASE alignment OF
      | TM.centerAlign:
        textStart:=xPos+(width-textWidth) DIV 2;
      | TM.rightAlign:
        textStart:=xPos+width-textWidth-textOffset-extent.lbearing;
      ELSE
        textStart:=xPos+textOffset-extent.lbearing;
      END;

      draw.DrawStr(textStart,yPos+e.font.ascent+(height-e.font.height) DIV 2,string);
    ELSE
      text:=e.model.GetText(x,y);
      IF text#NIL THEN
        length:=str.Length(text^);
        e.font.TextExtent(text^,length,{},extent);
        textWidth:=extent.rbearing-extent.lbearing;
        cliped:=textWidth>width;

        IF cliped THEN
          draw.InstallClip(xPos,yPos,width,height);
        END;

        CASE alignment OF
        | TM.centerAlign:
          textStart:=xPos+(width-textWidth) DIV 2;
        | TM.rightAlign:
          textStart:=xPos+width-textWidth-textOffset-extent.lbearing;
        ELSE
          textStart:=xPos+textOffset-extent.lbearing;
        END;

        draw.DrawString(textStart,yPos+e.font.ascent+(height-e.font.height) DIV 2,
                        text^,length);
      ELSE
        object:=e.model.GetObject(x,y);

        IF object#NIL THEN
          IF ~(G.inited IN object.flags) OR (object.GetWindow()#e.GetWindow()) THEN
            object.SetWindow(e.GetWindow());
            object.SetParent(e);
            object.CalcSize;
          END;

          object.Resize(width,height);

          object.Move(xPos+textOffset,
                      yPos+(height-object.oHeight) DIV 2);
          object.Draw(xPos,yPos,width,height);
        END;
      END;
    END;

    IF selected & ~e.model.selection.IsLineSelected(y) & e.HasFocus() THEN
      (* Draw a frame arond one cell *)
      e.prefs(Prefs).focusFrame.Draw(draw,xPos,yPos,width,height);
    END;

    IF cliped THEN
      draw.FreeLastClip;
    END;

    draw.PopForeground;
  END DrawCell;

  PROCEDURE (e : Table) PrintLine(draw : D.DrawInfo;
                                  pos,y,
                                  startColumn,endColumn : LONGINT);

  (**
    Print the given line at the given display position.
  *)

  VAR
    x,start,
    top,
    column,
    columnWidth : LONGINT;

  BEGIN
    top:=e.y+pos*e.rowHeight;

    start:=e.x-e.startColumn+1;
    x:=start;

    draw.PushFont(e.font,{});

    FOR column:=1 TO e.model.GetColumns() DO
      columnWidth:=e.model.GetColumnWidth(column-1);
      IF (column>=startColumn) & (column<=endColumn) &
        ~((x>e.x+e.width-1) OR (x+columnWidth-1<e.x)) THEN (* Draw only if visible *)
        e.DrawCell(draw,x,e.y+pos*e.rowHeight,columnWidth,e.rowHeight,column,y);
      END;
      INC(x,columnWidth);
    END;

    IF x<e.x+e.width THEN (* Fill space behind last cell in row *)
      IF e.model.selection.IsLineSelected(y) THEN
        e.prefs(Prefs).selection.DrawRelObject(draw,e,x,top,e.x+e.width-x+1,e.rowHeight);
      ELSIF y MOD 2#0 THEN
        e.prefs(Prefs).background.DrawRelObject(draw,e,x,top,e.x+e.width-x+1,e.rowHeight);
      ELSE
        e.prefs(Prefs).background2.DrawRelObject(draw,e,x,top,e.x+e.width-x+1,e.rowHeight);
      END;
    END;

    draw.PopFont;

    IF e.model.selection.IsLineSelected(y) & e.HasFocus() THEN
      (* Draw a frame arond whole line *)
      IF e.model.GetColumns()=1 THEN
        e.prefs(Prefs).focusFrame.Draw(draw,e.x,top,e.width,e.rowHeight);
      ELSE
        e.prefs(Prefs).focusFrame.Draw(draw,start,top,e.tableWidth,e.rowHeight);
      END;
    END;
  END PrintLine;

  PROCEDURE (e : Table) UpdateColumns*(start,stop : LONGINT);

  (**
    Refresh each to be refreshed line.
  *)

  VAR
    x,y  : LONGINT;
    draw : D.DrawInfo;

  BEGIN
    IF e.visible THEN

      draw:=e.GetDrawInfo();

      e.UpdateStatus;

      draw.InstallClip(e.x,e.y,e.width,e.height);

      x:=0;
      IF e.model#NIL THEN
        draw.PushFont(D.fixedFont,{});

        IF e.moveRegion THEN
          draw.CopyArea(e.x,                                        (* sX     *)
                        e.y+(e.mrStart-1)*e.rowHeight,              (* sY     *)
                        e.width,                                    (* width  *)
                        (e.mrEnd-e.mrStart+1)*e.rowHeight,          (* height *)
                        e.x,                                        (* dX     *)
                        e.y+(e.mrStart-1+e.mrCount)*e.rowHeight);   (* dY     *)
          e.moveRegion:=FALSE;
        END;

        y:=e.startLine;
        WHILE (x<LEN(e.lines^)) & (y<=e.model.GetRows()) DO
          IF ~e.lines[x].drawn THEN
            e.PrintLine(draw,x,y,start,stop);
            e.lines[x].drawn:=TRUE;
          END;

          INC(x);
          INC(y);
        END;

        draw.PopFont;
      END;

      (* Only necessary, if refresh of whole object *)
      IF x*e.rowHeight<e.height THEN
        draw.PushForeground(D.tableBackgroundColor);
        draw.FillRectangle(e.x,e.y+x*e.rowHeight,
                           e.width,e.height-x*e.rowHeight);
        draw.PopForeground;
      END;

      draw.FreeLastClip;
    END;
  END UpdateColumns;

  PROCEDURE (e : Table) Update*;

  BEGIN
    IF e.model#NIL THEN
      e.UpdateColumns(1,e.model.GetColumns());
    ELSE
      e.UpdateColumns(1,1);
    END;
  END Update;

  PROCEDURE (e : Table) Refresh*;

  BEGIN
    e.SetDirtyAll;
    e.Update;
  END Refresh;

  PROCEDURE (e : Table) CalcSize*;

  BEGIN
    e.width:=10*D.display.spaceWidth;
    e.height:=10*D.display.spaceHeight;

    e.minWidth:=e.width;
    e.minHeight:=e.height;

    IF e.rowHeight=0 THEN
      e.rowHeight:=e.font.height(*+t.focusFrame.minHeight*);
    END;

    IF e.autoSize & (e.model#NIL) THEN
      e.height:=U.MaxLong(e.height,e.model.GetRows()*e.rowHeight);
    END;

    e.CalcSize^;
  END CalcSize;

  (* -------- resize ---------- *)

  PROCEDURE (e : Table) HandleResize(height : LONGINT);

  BEGIN
    IF height#e.vSize THEN
      e.vSize:=height;
      e.ResizeLines;
    END;
  END HandleResize;

  PROCEDURE (e : Table) Draw*(x,y,w,h : LONGINT);

  VAR
    start,
    end    : LONGINT;
    draw   : D.DrawInfo;

  BEGIN
    e.Draw^(x,y,w,h);

    IF ~e.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    e.HandleResize(e.height DIV e.rowHeight);

    IF e.model#NIL THEN
      start:=y DIV e.rowHeight+1;
      end:=U.MinLong(e.GetLastVisiblePos()-e.GetFirstVisiblePos(),(y+h-1) DIV e.rowHeight+1);
      e.SetDirtyVisibleRange(start,end);
      e.Refresh;
    ELSE
      draw:=e.GetDrawInfo();
      draw.PushForeground(D.tableBackgroundColor);
      draw.FillRectangle(e.x,e.y,
                         e.width,e.height);
      draw.PopForeground;
    END;
  END Draw;

  PROCEDURE (t : Table) DrawFocus*;

  VAR
    selection : SM.Selection;

  BEGIN
    IF t.model=NIL THEN
      RETURN;
    END;

    selection:=t.model.selection;

    IF selection.HasSelection() THEN
      WITH
        selection : SM.None DO
      | selection : SM.SingleCell DO
        t.SetDirtyLine(selection.row);
      | selection : SM.SingleLine DO
        t.SetDirtyLine(selection.line);
      ELSE
      END;
    END;
    t.Update;
  END DrawFocus;

  PROCEDURE (t : Table) HideFocus*;

  VAR
    selection : SM.Selection;

  BEGIN
    IF t.model=NIL THEN
      RETURN;
    END;

    selection:=t.model.selection;

    IF selection.HasSelection() THEN
      WITH
        selection : SM.None DO
      | selection : SM.SingleCell DO
        t.SetDirtyLine(selection.row);
      | selection : SM.SingleLine DO
        t.SetDirtyLine(selection.line);
      ELSE
      END;
    END;
    t.Update;
  END HideFocus;

  PROCEDURE CreateTable*():Table;

  VAR
    table : Table;

  BEGIN
    NEW(table);
    table.Init;

    RETURN table;
  END CreateTable;

  PROCEDURE (t : Table) OnMouseSelection*;

  VAR
    selection : MouseSelectionMsg;

  BEGIN
    NEW(selection);

    t.Send(selection,mouseSelectionMsg);
  END OnMouseSelection;

  PROCEDURE (t : Table) OnDoubleClick*;

  VAR
    msg : DoubleClickMsg;

  BEGIN
    NEW(msg);
    t.Send(msg,doubleClickMsg);
  END OnDoubleClick;

  PROCEDURE (t : Table) Up;

  VAR
    selection : SM.Selection;

  BEGIN
    selection:=t.model.selection;

    WITH
      selection : SM.None DO
      t.vAdjustment.DecTop;
    | selection : SM.SingleCell DO
      IF selection.row>1 THEN
        selection.SelectCell(selection.column,selection.row-1);
        t.MakeVisible(selection.column,selection.row);
      END;
    | selection : SM.SingleLine DO
      IF selection.line>1 THEN
        selection.SelectLine(selection.line-1);
        t.MakeVisible(1,selection.line);
      END;
    ELSE
    END;
  END Up;

  PROCEDURE (t : Table) Down;

  VAR
    selection : SM.Selection;

  BEGIN
    selection:=t.model.selection;

    WITH
      selection : SM.None DO
      t.vAdjustment.IncTop;
    | selection : SM.SingleCell DO
      IF selection.HasSelection() THEN
        IF selection.row<t.model.GetRows() THEN
          selection.SelectCell(selection.column,selection.row+1);
          t.MakeVisible(selection.column,selection.row);
        END;
      ELSE
        selection.SelectCell(1,1);
      END;
    | selection : SM.SingleLine DO
      IF selection.HasSelection() THEN
        IF selection.line<t.model.GetRows() THEN
          selection.SelectLine(selection.line+1);
          t.MakeVisible(1,selection.line);
        END;
      ELSE
        selection.SelectCell(1,1);
      END;
    ELSE
    END;
  END Down;

  PROCEDURE (t : Table) Left;

  VAR
    selection : SM.Selection;

  BEGIN
    selection:=t.model.selection;

    WITH
      selection : SM.None DO
      t.hAdjustment.DecTop;
    | selection : SM.SingleCell DO
      IF (selection.column<=0) OR (selection.row<=0) THEN
        selection.SelectCell(1,1);
        t.MakeVisible(selection.column,selection.row);
      ELSIF selection.column>1 THEN
        selection.SelectCell(selection.column-1,selection.row);
        t.MakeVisible(selection.column,selection.row);
      END;
    | selection : SM.SingleLine DO
      t.hAdjustment.DecTop;
    ELSE
    END;
  END Left;

  PROCEDURE (t : Table) Right;

  VAR
    selection : SM.Selection;

  BEGIN
    selection:=t.model.selection;

    WITH
      selection : SM.None DO
      t.hAdjustment.IncTop;
    | selection : SM.SingleCell DO
      IF (selection.column<=0) OR (selection.row<=0) THEN
        selection.SelectCell(1,1);
        t.MakeVisible(selection.column,selection.row);
      ELSIF selection.column<t.model.GetColumns() THEN
        selection.SelectCell(selection.column+1,selection.row);
        t.MakeVisible(selection.column,selection.row);
      END;
    | selection : SM.SingleLine DO
      t.hAdjustment.IncTop;
    ELSE
    END;
  END Right;

  PROCEDURE (t : Table) Home;

  VAR
    selection : SM.Selection;

  BEGIN
    selection:=t.model.selection;

    WITH
      selection : SM.None DO
      t.vAdjustment.SetTop(1);
    | selection : SM.SingleCell DO
      selection.SelectCell(1,selection.row);
      t.MakeVisible(selection.column,selection.row);
    | selection : SM.SingleLine DO
      selection.SelectLine(1);
      t.MakeVisible(1,selection.line);
    END;
  END Home;

  PROCEDURE (t : Table) End;

  VAR
    selection : SM.Selection;

  BEGIN
    selection:=t.model.selection;

    WITH
      selection : SM.None DO
      t.vAdjustment.SetTop(U.MaxLong(1,t.vAdjustment.GetTotal()-t.vAdjustment.GetVisible()+1));
    | selection : SM.SingleCell DO
      selection.SelectCell(t.model.GetColumns(),selection.row);
      t.MakeVisible(selection.column,selection.row);
    | selection : SM.SingleLine DO
      selection.SelectLine(t.model.GetRows());
      t.MakeVisible(1,selection.line);
    END;
  END End;

  PROCEDURE (t : Table) PageUp;

  VAR
    selection : SM.Selection;

  BEGIN
    selection:=t.model.selection;

    WITH
      selection : SM.None DO
      t.vAdjustment.PageBack;
    | selection : SM.SingleCell DO
      t.vAdjustment.PageBack;
    | selection : SM.SingleLine DO
      IF selection.HasSelection() THEN
        selection.SelectLine(U.MaxLong(1,
                                       selection.line-t.vAdjustment.GetVisible()+1));
        t.MakeVisible(1,selection.line);
      ELSE
        selection.SelectLine(1);
        t.MakeVisible(1,selection.line);
      END;
    END;
  END PageUp;

  PROCEDURE (t : Table) PageDown;

  VAR
    selection : SM.Selection;

  BEGIN
    selection:=t.model.selection;

    WITH
      selection : SM.None DO
      t.vAdjustment.PageForward;
    | selection : SM.SingleCell DO
      t.vAdjustment.PageForward;
    | selection : SM.SingleLine DO
      IF selection.HasSelection() THEN
        selection.SelectLine(U.MinLong(t.vAdjustment.GetTotal(),
                                       selection.line+t.vAdjustment.GetVisible()+1));
        t.MakeVisible(1,selection.line);
      ELSE
        selection.SelectLine(1);
        t.MakeVisible(1,selection.line);
      END;
    END;
  END PageDown;

  PROCEDURE (t : Table) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  BEGIN
    IF t.model=NIL THEN
      RETURN FALSE;
    END;

    IF event.type=E.keyDown THEN
      CASE event.key OF
      | E.left:
        t.Left;
      | E.right:
        t.Right;
      | E.up:
        t.Up;
      | E.down:
        t.Down;
      | E.home:
        t.Home;
      | E.end:
        t.End;
      | E.prior:
        t.PageUp;
      | E.next:
        t.PageDown;
      | E.space:
        IF t.model.selection.HasSelection() THEN
          t.OnMouseSelection;
        END;
      ELSE
        RETURN FALSE;
      END;
      t.Update;
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END HandleKeyEvent;

  PROCEDURE (t : Table) HandleMouseEvent*(event : E.MouseEvent;
                                          VAR grab : G.Object):BOOLEAN;

  VAR
    x,y    : LONGINT;
    window : D.Window;

  BEGIN
    IF ~t.visible OR t.disabled OR (t.model=NIL) THEN
      RETURN FALSE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & t.PointIsIn(event.x,event.y) THEN
        IF (event.button=E.button1) THEN
          IF t.GetCell(event.x,event.y,x,y) THEN
            t.model.selection.SelectCell(x+1,y);
            t.OnMouseSelection;
            window:=t.GetWindow();
            IF window.IsDoubleClicked() THEN (* TODO: Define double click more precisly *)
              t.OnDoubleClick;
            END;
          END;
        ELSIF (event.button=E.button4) THEN
          t.vAdjustment.DecTop;
        ELSIF (event.button=E.button5) THEN
          t.vAdjustment.IncTop;
        END;

        grab:=t;

        RETURN TRUE;
      ELSIF (grab=t) & (event.type=E.mouseUp) THEN

        grab:=NIL;

        RETURN TRUE;
      END;
    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  (* -------- model feetback ---------- *)

  PROCEDURE (e : Table) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF msg=NIL THEN
      IF model=e.model THEN
        IF e.vAdjustment.GetBottom()>e.model.GetRows() THEN
          e.vAdjustment.Set(U.MaxLong(1,e.model.GetRows()-e.vAdjustment.GetVisible()+1),
                            e.vAdjustment.GetVisible(),
                            e.model.GetRows());
        END;
        e.Refresh;
      ELSIF model=e.top THEN
        IF ~e.top.IsNull() & (e.top.GetLongint()#e.GetFirstVisiblePos()) THEN
          e.ScrollTo(e.top.GetLongint());
          e.Update;
        END;
      ELSIF model=e.first THEN
        IF ~e.first.IsNull() & (e.first.GetLongint()#e.startColumn) THEN
          e.startColumn:=e.first.GetLongint();
          e.Refresh;
        END;
      END;

    ELSE
      WITH
        msg : TM.RefreshCell DO
        IF e.visible THEN
          e.SetDirtyLine(msg.y);
        END;
      | msg : TM.RefreshRow DO
        IF e.visible THEN
          e.SetDirtyLine(msg.y);
        END;
      | msg : TM.InsertRow DO
        IF e.visible THEN
          e.UpdateInsertLines(msg.y,1);
        END;
      | msg : TM.DeleteRow DO
        IF e.visible THEN
          e.UpdateDeleteLines(msg.y,1);
        END;
      | msg : HM.ResizedColumn DO
        IF e.visible & (e.model#NIL) THEN
          e.SetDirtyAll;
          e.UpdateColumns(msg.column+1,e.model.GetColumns());
        END;
      | msg : HM.FitColumn DO
        e.FitColumn(msg.column+1);
      ELSE
        e.startLine:=1;
        e.startColumn:=1;
        e.SetDirtyAll;
      END;

      IF e.visible THEN
        e.Update;
      END;
    END;
  END Resync;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:TableView.