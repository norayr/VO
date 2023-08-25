MODULE VO:Edit:Edit [OOC_EXTENSIONS];

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

IMPORT D    := VO:Base:Display,
       DD   := VO:Base:DragDrop,
       E    := VO:Base:Event,
       F    := VO:Base:Frame,
       O    := VO:Base:Object,
       U    := VO:Base:Util,

       S    := VO:Edit:Syntax,
               VO:Edit:Syntax:Standard,
       T    := VO:Edit:Text,

       V    := VO:Model:Value,

       G    := VO:Object,

               ADT:ArrayList,
               ADT:Dictionary,
               Ascii,
               Object,
        str := Strings,
               Err;

CONST
  updateMsg * = 0;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 showEOL*,
                 showTab*,
                 showSpace*,
                 showAEOL*,
                 showCurrentLine* : BOOLEAN;
               END;

  Edit*         = POINTER TO EditDesc;

  Fct*          = PROCEDURE (e : Edit);

  FctEntry      = POINTER TO FctEntryDesc;
  FctEntryDesc  = RECORD (Object.ObjectDesc)
                    fct : Fct;
                  END;

  Plugin*       = POINTER TO PluginDesc;
  PluginDesc*   = RECORD (Object.ObjectDesc)
                    name- : STRING;
                    edit- : Edit;
                  END;

  KeyEntry*     = POINTER TO KeyEntryDesc;
  KeyEntryDesc  = RECORD
                    next     : KeyEntry;
                    key      : ARRAY 35 OF CHAR; (* Make it simple *)
                    function : STRING;           (* Make it simple *)
                    fct      : Fct;
                  END;

  Config*          = POINTER TO ConfigDesc;
  ConfigDesc*      = RECORD
                       name-           : STRING;
                       createBackup*   : BOOLEAN;
                       remTrailSpaces* : BOOLEAN;
                       syntax*         : S.Syntax;
                       keyList-        : KeyEntry; (** configured keys *)
                     END;

  Line      = RECORD
                state : S.StateInfo; (* TODO *)
                drawn : BOOLEAN; (* TODO *)
              END;

  Lines     = POINTER TO ARRAY OF Line;

  DrawInfoDesc = RECORD
                   style- : S.Style;
                   pos-   : LONGINT;
                 END;

  LineInfo*    = POINTER TO LineInfoDesc;
  LineInfoDesc*= RECORD
                   orig-   : U.Text;
                   text-   : U.Text;
                   info-   : POINTER TO ARRAY OF DrawInfoDesc;
                   token-  : POINTER TO ARRAY OF S.Token;
                   start-  : POINTER TO ARRAY OF BOOLEAN;
                   length- : LONGINT;
                 END;

  Colorizer*    = PROCEDURE (i : LineInfo; e : Edit);

  StyleData      = POINTER TO StyleDataDesc;
  StyleDataDesc  = RECORD (S.StyleDataDesc)
                     fg,
                     bg    : D.Color;
                     style : SET;
                   END;

  ColorizeEntry     = POINTER TO ColorizeEntryDesc;
  ColorizeEntryDesc = RECORD
                        next : ColorizeEntry;
                        fct  : Colorizer;
                      END;

  ConfigResolver* = PROCEDURE (e : Edit):Config;

  EditDesc* = RECORD (G.ScrollableGadgetDesc)
                (* The text *)
                model-      : T.Text;
                resolver-   : ConfigResolver;
                config-     : Config;

                (* Text status *)

                stableSelection-,
                readWrite-  : BOOLEAN; (* allow write operations *)

                (* window dimensions *)
                hSize-,
                vSize-      : LONGINT;

                (* Prefs *)
                hScrollOffset*  : LONGINT;
                showEOL*,
                showTab*,
                showSpace*,
                showAEOL*,
                showCurrentLine*,
                selectCurrentLine*: BOOLEAN;

                (* low level text display stuff *)
                startColumn* : LONGINT; (** Change export status!!! *)

                startLine-,
                cursor-,
                markA*, (* TODO! *)
                markB*, (* TODO! *)
                tmpCursor-,
                tmp2Cursor-,
                tmp3Cursor-,
                blockCursor : T.Cursor;

                (* visual controls *)
                top         : V.ValueModel;
                first       : V.ValueModel;

                font        : D.Font;
                fontWidth   : LONGINT;

                lines       : Lines;
                linesBak    : Lines;

                (* visualisation of the current block *)
                showBlock   : BOOLEAN;

                (* Move region *)
                moveRegion  : BOOLEAN;
                mrCount,
                mrStart,
                mrEnd       : LONGINT;

                plugins     : ArrayList.ArrayList(Plugin);
                pluginDict  : Dictionary.Dictionary(STRING,Plugin);
              END;

  UpdateMsg*     = POINTER TO UpdateMsgDesc;
  UpdateMsgDesc* = RECORD (O.MessageDesc)
                     (**
                       send, if information have changed and some additional
                       display (for example statusline) should get updated
                     *)
                     edit- : Edit;        (** Edit control that is source of the message *)
                     msg-  : O.ResyncMsg; (** Optional low level message from text object *)
                   END;

VAR
  (* Preferences *)
  prefs*     : Prefs;

  colorizer  : ColorizeEntry;

  (* search & replace *)
  globalLine : LineInfo;

  (* Function and key list *)
  fctList-   : Dictionary.Dictionary(STRING,FctEntry); (** list of known functions *)

  (* internal *)
  tmpText    : U.Text;
  update     : UpdateMsg;

  PROCEDURE RegisterFunction*(name : STRING; function : Fct);

    (**
      Call this method to register a function to the editor core.
    *)
  VAR
    entry : FctEntry;

  BEGIN
    NEW(entry);
    entry.fct:=function;

    fctList.Set(name,entry);
  END RegisterFunction;

  PROCEDURE GetFunction*(name : STRING):Fct;

  VAR
    entry : FctEntry;

  BEGIN
    IF fctList.HasKey(name) THEN
      entry:=fctList.Get(name);
      RETURN entry.fct;
    ELSE
      RETURN NIL;
    END;
  END GetFunction;

  PROCEDURE (p : Plugin) Init*;

  BEGIN
    (* No code *)
  END Init;

  PROCEDURE (p : Plugin) Receive*(message : O.Message);

  BEGIN
    (* No code *)
  END Receive;

  PROCEDURE (p : Plugin) Free*;

  BEGIN
    (* No code *)
  END Free;

  PROCEDURE (c : Config) Init*;

  BEGIN
    c.name:=NIL;
    c.createBackup:=FALSE;
    c.remTrailSpaces:=FALSE;
    c.syntax:=Standard.syntax;
    c.keyList:=NIL;
  END Init;

  PROCEDURE (c : Config) SetName*(name : STRING);

  BEGIN
    c.name:=name;
  END SetName;

  PROCEDURE (c : Config) AddKey*(key : ARRAY OF CHAR; function : STRING):BOOLEAN;

    (**
      Call this method to register a new key combination an connect it
      to an existing function.
    *)

  VAR
    entry : KeyEntry;

  BEGIN
    NEW(entry);
    COPY(key,entry.key);
    entry.function:=function;
    entry.fct:=GetFunction(function);
    IF entry.fct=NIL THEN
      RETURN FALSE;
    END;

    entry.next:=c.keyList;
    c.keyList:=entry;

    RETURN TRUE;
  END AddKey;

  PROCEDURE (c : Config) Inherit*(config : Config);

  VAR
    entry : KeyEntry;

  BEGIN
    ASSERT(config#NIL);

    c.createBackup:=config.createBackup;
    c.remTrailSpaces:=config.remTrailSpaces;;

    entry:=config.keyList;
    WHILE entry#NIL DO
      IF ~c.AddKey(entry.key,entry.function) THEN
      END;
      entry:=entry.next;
    END;
  END Inherit;

  PROCEDURE DefaultConfigResolver*(e : Edit):Config;

  VAR
    config : Config;

  BEGIN
    NEW(config);
    config.Init;
    config.SetName("Internal");

    RETURN config;
  END DefaultConfigResolver;

  (* -------- prefs ---------- *)

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.showEOL:=FALSE;
    p.showAEOL:=FALSE;
    p.showTab:=FALSE;
    p.showSpace:=FALSE;
    p.showCurrentLine:=FALSE;

(*    p.showEOL:=TRUE;
    p.showAEOL:=TRUE;
    p.showTab:=TRUE;
    p.showSpace:=TRUE;*)
  END Initialize;

  (* -------- helper ---------- *)

  PROCEDURE (e: Edit) GetFirstVisiblePos*():LONGINT;

  BEGIN
    RETURN e.startLine.GetY();
  END GetFirstVisiblePos;

  PROCEDURE (e: Edit) GetLastVisiblePos*():LONGINT;

  VAR
    last : LONGINT;

  BEGIN
    last:=e.startLine.GetY()+e.vSize-1;

    IF last>e.model.lines THEN
      last:=e.model.lines;
    END;

    RETURN last;
  END GetLastVisiblePos;

  PROCEDURE (e: Edit) GetLine*(y : LONGINT; VAR rider : T.Rider);

(*  VAR
    rider : T.Rider;*)

  BEGIN
    e.startLine.GetRiderAtSOL(rider);
    IF rider.MoveLines(y-e.startLine.GetY()) THEN END;
  END GetLine;

  PROCEDURE (e: Edit) GetLastVisibleLine*(VAR rider : T.Rider);

  BEGIN
    e.GetLine(e.GetLastVisiblePos(),rider);
  END GetLastVisibleLine;

  PROCEDURE (e: Edit) IsVisible*(y : LONGINT):BOOLEAN;

  BEGIN
    RETURN (e.GetFirstVisiblePos()<=y) & (y<=e.GetLastVisiblePos());
  END IsVisible;

  PROCEDURE (e: Edit) CanScrollUp*():BOOLEAN;

  BEGIN
    RETURN e.GetFirstVisiblePos()>1;
  END CanScrollUp;

  PROCEDURE (e: Edit) CanScrollDown*():BOOLEAN;

  BEGIN
    RETURN e.GetLastVisiblePos()<e.model.lines;
  END CanScrollDown;

  (* -------- visualisation ---------- *)

  PROCEDURE (e: Edit) DisplayBeep*;

  BEGIN
    D.display.Beep;
  END DisplayBeep;

  (* -------- lines handling ---------- *)

  PROCEDURE (e: Edit) ToggleBackup;

  VAR
    help : Lines;

  BEGIN
    help:=e.linesBak;
    e.linesBak:=e.lines;
    e.lines:=help;
  END ToggleBackup;

  PROCEDURE (e: Edit) MakeLinesBackup;

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

  PROCEDURE (e: Edit) SetDirtyVisibleRange(a,b : LONGINT);

  VAR
    x : LONGINT;

  BEGIN
    FOR x:=a TO b DO
      e.lines[x-1].drawn:=FALSE;
    END;
  END SetDirtyVisibleRange;

  PROCEDURE (e: Edit) SetDirtyRange(y1,y2 : LONGINT);

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

  PROCEDURE (e: Edit) SetDirtyLine(y : LONGINT);

  BEGIN
    e.SetDirtyRange(y,y);
  END SetDirtyLine;


  PROCEDURE (e: Edit) SetDirtyAll*;

  (**
    Mark everything as dirty.

    TODO
    Fix export rights.
  *)

  BEGIN
    e.SetDirtyVisibleRange(1,e.vSize);
  END SetDirtyAll;

  PROCEDURE (e: Edit) UpdateDeleteLines(from, count : LONGINT);

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

  PROCEDURE (e: Edit) UpdateInsertLines(from, count : LONGINT);

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

  PROCEDURE (e: Edit) ResizeLines;

  VAR
    x  : LONGINT;

  BEGIN
    NEW(e.lines,e.vSize);
    FOR x:=0 TO e.vSize-1 DO
      e.lines[x].drawn:=FALSE;
      e.lines[x].state.Init;
    END;
    NEW(e.linesBak,e.vSize);
    FOR x:=0 TO e.vSize-1 DO
      e.linesBak[x].drawn:=FALSE;
      e.linesBak[x].state.Init;
    END;
  END ResizeLines;

  (* -------- selection ---------- *)

  PROCEDURE (e: Edit) IsUnselected*():BOOLEAN;

  BEGIN
    RETURN (e.markA=NIL) & (e.markB=NIL);
  END IsUnselected;

  PROCEDURE (e: Edit) IsSelected*():BOOLEAN;

  BEGIN
    RETURN (e.markA#NIL) & (e.markB#NIL);
  END IsSelected;

  PROCEDURE (e: Edit) IsMarkSet*():BOOLEAN;

  BEGIN
    RETURN (e.markA#NIL) & (e.markB=NIL);
  END IsMarkSet;

  PROCEDURE (e: Edit) GetStartMark*():T.Cursor;

  BEGIN
    ASSERT(e.IsSelected());

    IF e.markB.GetPos()>=e.markA.GetPos() THEN
      RETURN e.markA;
    ELSE
      RETURN e.markB;
    END;
  END GetStartMark;

  PROCEDURE (e: Edit) GetEndMark*():T.Cursor;

  BEGIN
    ASSERT(e.IsSelected());

    IF e.markB.GetPos()>=e.markA.GetPos() THEN
      RETURN e.markB;
    ELSE
      RETURN e.markA;
    END;
  END GetEndMark;

  PROCEDURE (e: Edit) SetStartMark*(cursor : T.Cursor);

  BEGIN
    e.markA:=e.model.GetOrCreateCursor("markA",{});
    e.markA.GotoCursor(cursor);
  END SetStartMark;

  PROCEDURE (e : Edit) ClearSelectionInternal;

  VAR
    a,b   : LONGINT;
    markA,
    markB : T.Cursor;

  BEGIN
    ASSERT(e.IsSelected());

    markA:=e.GetStartMark();
    markB:=e.GetEndMark();
    a:=markA.GetY();
    b:=markB.GetY();
    e.model.FreeCursor(e.markB);
    e.model.FreeCursor(e.markA);
    e.markB:=NIL;
    e.markA:=NIL;
    e.model.NotifyRedraw(a,b);
  END ClearSelectionInternal;

  PROCEDURE (e: Edit) ClearSelectionCallback*;

  (**
    Called by the display layer, when e.DeregisterGlobalSelection was
    successfull
  *)

  BEGIN
    IF ~e.stableSelection THEN
      e.ClearSelectionInternal;
    END;
  END ClearSelectionCallback;

  PROCEDURE (e: Edit) ClearSelection*;

  (**
    Remove the current selection without modifying the text
  *)

  VAR
    a : LONGINT;

  BEGIN
    IF e.IsSelected() THEN
      IF e.stableSelection THEN
        e.ClearSelectionInternal;
      ELSE
        D.display.CancelSelection;
      END;
    ELSIF e.IsMarkSet() THEN
      a:=e.markA.GetY();
      e.model.FreeCursor(e.markA);
      e.markA:=NIL;
      e.model.NotifyRedraw(a,a);
    END;
  END ClearSelection;

  PROCEDURE (e: Edit) DeleteSelection*;

  BEGIN
    IF e.IsSelected() THEN
      IF e.model.DeleteArea(e.GetStartMark(),e.GetEndMark()) THEN
        e.ClearSelection;
      END;
    END;
  END DeleteSelection;

  (* -------- syntax hilightning ---------- *)

  PROCEDURE (e: Edit) SetEndState(line : LONGINT; state[NO_COPY] : S.StateInfo);

  BEGIN
    IF (line>e.GetLastVisiblePos()) OR (line<e.GetFirstVisiblePos()) THEN
      RETURN;
    END;

    IF ~e.lines[line-e.GetFirstVisiblePos()].state.Equals(state) THEN
      e.lines[line-e.GetFirstVisiblePos()].state:=state;
      IF line+1<=e.GetLastVisiblePos() THEN
        e.lines[line-e.GetFirstVisiblePos()+1].drawn:=FALSE;
      END;
    END;
  END SetEndState;

  (* -------- coordinates transaformation ---------- *)

  PROCEDURE (e: Edit) TextToDisplayPos*(y : LONGINT):LONGINT;

  (**
    Returns the display coordinate of the given textline.

    If the line is not currently displayed, GetDisplayPos returns -1.
  *)

  BEGIN
    IF e.IsVisible(y) THEN
      RETURN y-e.GetFirstVisiblePos()+1;
    ELSE
      RETURN -1;
    END;
  END TextToDisplayPos;

  PROCEDURE (e: Edit) DisplayToTextPos*(y : LONGINT):LONGINT;

  (**
    Returns the text coordinate of the given display line.
  *)

  BEGIN
    RETURN e.GetFirstVisiblePos()+y-1;
  END DisplayToTextPos;

  (* -------- drawing stub ---------- *)

  PROCEDURE (e: Edit) MoveRegion(start, end : LONGINT; count : LONGINT);

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

  (* -------- LineInfo ---------- *)

  PROCEDURE (i : LineInfo) Alloc(length : LONGINT);

  BEGIN
    IF (i.text=NIL) OR (LEN(i.text^)<length) THEN
      NEW(i.text,length);
    END;

    IF (i.info=NIL) OR (LEN(i.info^)<length) THEN
      NEW(i.info,length);
    END;

    IF (i.token=NIL) OR (LEN(i.token^)<length) THEN
      NEW(i.token,length);
    END;

    IF (i.start=NIL) OR (LEN(i.start^)<length) THEN
      NEW(i.start,length);
    END;
  END Alloc;

  PROCEDURE (i : LineInfo) XToPos(x : LONGINT):LONGINT;

  VAR
    pos : LONGINT;

  BEGIN
    pos:=x-1;
    WHILE i.info[pos].pos#x DO
      INC(pos);
    END;
    RETURN pos;
  END XToPos;

    (*<*
      PUSH;

      IndexCheck:=FALSE;
      DerefCheck:=FALSE;
      RangeCheck:=FALSE;
      OverflowCheck:=FALSE;
    *>*)

  PROCEDURE (i : LineInfo) ExtractText(e: Edit; rider : T.Rider);

  VAR
    x,y,
    spaces,
    lastPos : LONGINT;

  BEGIN
    i.orig:=rider.GetLine();
    i.Alloc(LEN(i.orig^));

    (*
      Character sequence substitution
    *)

    x:=0;
    y:=0;
    WHILE (i.orig[x]#0X) & (y<LEN(i.text^)) DO
      IF i.orig[x]=Ascii.lf THEN
        IF e.showEOL THEN
          i.text[y]:="¶"; (* Hide the Ascii.lf *)
        ELSE
          i.text[y]:=" ";
        END;
        i.info[y].pos:=x+1;
      ELSIF i.orig[x]=" " THEN
        IF e.showSpace THEN
          i.text[y]:="·";
        ELSE
          i.text[y]:=" ";
        END;
        i.info[y].pos:=x+1;
      ELSIF (i.orig[x]=Ascii.ht) & ~e.showTab THEN
        spaces:=(((y+1) DIV e.model.syntax.tabSize)+1)*e.model.syntax.tabSize-y;
        WHILE (spaces>0) & (y<LEN(i.text^)) DO
          i.text[y]:=" ";
          i.info[y].pos:=x+1;
          DEC(spaces);

          IF (spaces>0) & (y<LEN(i.text^)) THEN
            INC(y);
          END;
        END;
      ELSIF ORD(i.orig[x])<=31 THEN
        (* hide unprintable characters *)
        i.text[y]:="\";
        i.info[y].pos:=x+1;
        IF y+1<LEN(i.text^) THEN
          INC(y);
          IF ORD(i.orig[x]) DIV 16<10 THEN
            i.text[y]:=CHR(ORD("0") + ORD(i.orig[x]) DIV 16);
          ELSE
            i.text[y]:=CHR(ORD("a") + ORD(i.orig[x]) DIV 16 - 10);
          END;
          i.info[y].pos:=x+1;
          IF y+1<LEN(i.text^) THEN
            INC(y);
            IF ORD(i.orig[x]) MOD 16<10 THEN
              i.text[y]:=CHR(ORD("0") + ORD(i.orig[x]) MOD 16);
            ELSE
              i.text[y]:=CHR(ORD("a") + ORD(i.orig[x]) MOD 16 - 10);
            END;
            i.info[y].pos:=x+1;
          END;
        END;
      ELSE
        i.text[y]:=i.orig[x];
        i.info[y].pos:=x+1;
      END;

      lastPos:=i.info[y].pos;

      INC(x);
      INC(y);
    END;

    i.length:=y;

    WHILE y<LEN(i.text^) DO
      INC(lastPos);
      IF e.showAEOL THEN
        i.text[y]:="~";
      ELSE
        i.text[y]:=" ";
      END;
      i.info[y].pos:=lastPos;
      INC(y);
    END;
  END ExtractText;

  PROCEDURE (i : LineInfo) SetArea*(x1,x2 : LONGINT; style : S.Style);

  VAR
    x : LONGINT;

  BEGIN
    x:=x1-1; (* Optimisation: x1 will be at x or later but never before *)
    WHILE (x<LEN(i.info^)) & (i.info[x].pos<x1) DO
      INC(x);
    END;

    WHILE (x<LEN(i.info^)) & (i.info[x].pos<=x2)  DO
      i.info[x].style:=style;
      INC(x);
    END;
  END SetArea;

  PROCEDURE (i : LineInfo) FindNext*(pattern[NO_COPY]: ARRAY OF CHAR;
                                     startPos: LONGINT;
                                     VAR posOfPattern: LONGINT;
                                     case : BOOLEAN):BOOLEAN;

  VAR
    patternPos: LONGINT;

  BEGIN
    IF (startPos < i.length) THEN
      patternPos := 0;
      IF case THEN
        LOOP
          IF (pattern[patternPos] = 0X) THEN
            (* reached end of pattern *)
            posOfPattern := startPos-patternPos;
            RETURN TRUE;
          ELSIF (i.orig[startPos] = 0X) THEN
            (* end of string (but not of pattern) *)
            RETURN FALSE;
          ELSIF (i.orig[startPos] = pattern[patternPos]) THEN
            (* characters identic, compare next one *)
            INC(startPos);
            INC(patternPos)
          ELSE
            (* difference found: reset indices and restart *)
            startPos := startPos-patternPos+1;
            patternPos := 0
          END
        END
      ELSE
        LOOP
          IF (pattern[patternPos] = 0X) THEN
            (* reached end of pattern *)
            posOfPattern := startPos-patternPos;
            RETURN TRUE;
          ELSIF (i.orig[startPos] = 0X) THEN
            (* end of string (but not of pattern) *)
            RETURN FALSE;
          ELSIF (CAP(i.orig[startPos]) = CAP(pattern[patternPos])) THEN
            (* characters identic, compare next one *)
            INC(startPos);
            INC(patternPos)
          ELSE
            (* difference found: reset indices and restart *)
            startPos := startPos-patternPos+1;
            patternPos := 0
          END
        END
      END;
    END;
    RETURN FALSE;
  END FindNext;

  PROCEDURE (i : LineInfo) Colorize(e: Edit; syntax : S.Syntax; state : S.StateInfo; yPos : LONGINT);

  VAR
    x,y     : LONGINT;
    a       : LONGINT;
    cursor,
    markA,
    markB   : T.Cursor;
    token   : S.Token;
    style   : S.Style;
    cEntry  : ColorizeEntry;

  BEGIN
    (*
      Syntax hilighting
    *)

    style:=syntax.GetStyle(state);

    x:=0;
    a:=0;
    WHILE (x<LEN(i.orig^)) & (i.orig[x]#0X) & (a<LEN(i.info^)) DO
      token:=syntax.ParseToken(i.orig,x,y,state);
      style:=token.GetStyle(state.GetCount());
      i.info[a].style:=style;
      i.token[a]:=token;
      i.start[a]:=TRUE;
      INC(a);
      WHILE (a<LEN(i.info^)) & (i.info[a].pos<=x+y) DO
        i.info[a].style:=style;
        i.token[a]:=token;
        i.start[a]:=FALSE;
        INC(a);
      END;

      INC(x,y);
    END;

    (*
      Coloring of end of line
    *)

    WHILE a<LEN(i.info^) DO
      i.info[a].style:=style;
      i.token[a]:=NIL;
      i.start[a]:=FALSE;
      INC(a);
    END;

    (*
      Coloring of current search string.
    *)

    cEntry:=colorizer;
    WHILE cEntry#NIL DO
      cEntry.fct(i,e);
      cEntry:=cEntry.next;
    END;

    IF e.selectCurrentLine & (e.cursor.GetY()=yPos) THEN
      i.SetArea(1,MAX(LONGINT),S.SelectionStyle);
      RETURN;
    END;

    (*
      Coloring of current selection block.
     *)
    IF e.IsSelected() THEN
      markA:=e.GetStartMark();
      markB:=e.GetEndMark();
      IF (markA.GetY()<yPos) & (yPos<markB.GetY()) THEN
        i.SetArea(1,MAX(LONGINT),S.SelectionStyle);
      ELSIF (yPos=markA.GetY()) & (markA.GetY()=markB.GetY()) THEN
        i.SetArea(markA.GetX(),markB.GetX()-1,S.SelectionStyle);
      ELSIF (yPos=markA.GetY()) THEN
        i.SetArea(markA.GetX(),MAX(LONGINT),S.SelectionStyle);
      ELSIF (yPos=markB.GetY()) THEN
        i.SetArea(1,markB.GetX()-1,S.SelectionStyle);
      END;
    END;

    cursor:=e.model.firstCursor;
    WHILE cursor#NIL DO
      IF (T.cursorBookmark IN cursor.flags) & (cursor.GetY()=yPos) THEN
        i.SetArea(cursor.GetX(),cursor.GetX(),S.BookmarkStyle);
      END;
      cursor:=cursor.next;
    END;

    (* Drawing of cursor *)
    IF (e.cursor.GetY()=yPos) THEN
      i.SetArea(e.cursor.GetX(),e.cursor.GetX(),S.CursorStyle);
    END;

    (*    IF e.showCurrentLine & (e.cursor.GetY()=yPos) THEN
      (* TODO: Find a better way to signal current line *)
    *)

    IF e.showBlock & (yPos=e.blockCursor.GetY()) THEN
      i.SetArea(e.blockCursor.GetX(),e.blockCursor.GetX(),S.MarkStyle);
    END;

    e.SetEndState(yPos,state);
  END Colorize;

  (*  <* POP *>*)

  PROCEDURE (e: Edit) GetLineText*(yPos : LONGINT):LineInfo;

  VAR
    rider : T.Rider;
    info  : LineInfo;

  BEGIN
    e.GetLine(yPos,rider);
    info:=globalLine;
    info.ExtractText(e,rider);

    RETURN info;
  END GetLineText;

  PROCEDURE (e: Edit) GetLineTextColored*(rider : T.Rider; yPos : LONGINT):LineInfo;

  VAR
    info : LineInfo;

  BEGIN
    info:=globalLine;
    e.model.state.MoveToLine(yPos);
    info.ExtractText(e,rider);
    info.Colorize(e,e.model.syntax,e.model.state.state,yPos);

    RETURN info;
  END GetLineTextColored;

  (* -------- positioning --------- *)

  PROCEDURE (e: Edit) Page*(lines : LONGINT);

  VAR
    count   : LONGINT;

    endLine : T.Rider;

  BEGIN
    (* Moving visible area *)
    count:=0;
    e.GetLastVisibleLine(endLine);
    IF lines>0 THEN (* paging down *)
      WHILE (count<lines) & endLine.MoveNextLine() & e.startLine.Down() DO
        INC(count);
      END;
    ELSIF lines<0 THEN (* paging up *)
      WHILE (-count<-lines) & e.startLine.Up() & endLine.MoveLastLine() DO
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

  PROCEDURE (e: Edit) ScrollTo*(lines : LONGINT);

  BEGIN
    ASSERT((lines>=1) & (lines<=e.model.lines));

    (* Convert absolute to relative coordinates *)
    lines:=lines-e.GetFirstVisiblePos();

    e.Page(lines);
  END ScrollTo;

  PROCEDURE (e: Edit) MakeVisible(x,y : LONGINT);

  (**
    Redisplay text in that way, that the given point can be seen
  *)

  VAR
    lines,h,a   : LONGINT;
    endLine     : T.Rider;
    refreshVert : BOOLEAN;
    info        : LineInfo;

  BEGIN
    lines:=0;
    e.GetLastVisibleLine(endLine);
    IF y>e.GetLastVisiblePos() THEN (* Go forward *)
      WHILE (y>e.GetLastVisiblePos()) & endLine.MoveNextLine() & e.startLine.Down() DO
        INC(lines);
      END;
      refreshVert:=TRUE;
    ELSIF y<e.GetFirstVisiblePos() THEN (* Go back *)
      WHILE (y<e.GetFirstVisiblePos()) & e.startLine.Up() & endLine.MoveLastLine() DO
        DEC(lines);
      END;
      refreshVert:=TRUE;
    ELSE
      (* coordinate is in visible area *)
      refreshVert:=FALSE;
    END;

    IF refreshVert THEN
      IF ABS(lines)<e.vSize THEN
        (*
          We have to move less than the size of the display.
          Thus we can copy parts of the display content
          and only manually draw newly visible lines.
        *)
        IF lines>0 THEN
          e.MoveRegion(lines+1,e.vSize,-lines);
          e.SetDirtyVisibleRange(e.vSize-lines+1,e.vSize);
        ELSE
          e.MoveRegion(1,e.vSize+lines,-lines);
          e.SetDirtyVisibleRange(1,-lines);
        END;
      ELSE
        (* We must completly redraw the display *)

        (* We try to center the display around the given point *)
        IF lines>0 THEN
          h:=e.vSize;
          WHILE (h>(e.vSize DIV 2)) & endLine.MoveNextLine() & e.startLine.Down() DO
            DEC(h);
          END;
        ELSE
          h:=1;
          WHILE (h<(e.vSize DIV 2)) & e.startLine.Up() & endLine.MoveLastLine() DO
            INC(h);
          END;
        END;

        e.SetDirtyAll;
      END;
    END;

    info:=e.GetLineText(y);

    a:=0;
    WHILE (a<LEN(info.text^)) & (info.info[a].pos<x) DO
      INC(a);
    END;
    WHILE ((a+1)<LEN(info.text^)) & (info.info[a+1].pos<=x) DO
      INC(a);
    END;

    IF (a+1+e.hScrollOffset<=e.hSize) THEN
      IF (e.startColumn>1) THEN
        e.startColumn:=1;
        e.SetDirtyAll;
      END;
    ELSIF a+1-e.hScrollOffset<e.startColumn THEN
      e.startColumn:=a+1-e.hScrollOffset;
      e.SetDirtyAll;
    ELSIF (a+1+e.hScrollOffset>e.startColumn+e.hSize-1) THEN
      e.startColumn:=a+1+e.hScrollOffset-e.hSize;
      e.SetDirtyAll;
    END;
  END MakeVisible;

  PROCEDURE (e: Edit) MakeCursorVisible*(cursor : T.Cursor);

  (**
    Make the given cursor visible in the text.
  *)

  VAR
    lines,
    h,a,x,y     : LONGINT;
    refreshVert : BOOLEAN;
    endLine     : T.Rider;
    info        : LineInfo;

  BEGIN
    x:=cursor.GetX();
    y:=cursor.GetY();

    (*
      Adjust vertical
    *)

    IF cursor.GetY()-e.GetFirstVisiblePos()<0 THEN
      (* Up *)
      lines:=cursor.GetY()-e.GetFirstVisiblePos();
      e.startLine.GotoCursor(cursor);
      IF e.startLine.GotoColumn(1) THEN END;
      e.startLine.GetRiderAtSOL(endLine);

      h:=1;
      WHILE (h<e.vSize) & endLine.MoveNextLine() DO
        INC(h);
      END;
      refreshVert:=TRUE;
    ELSIF cursor.GetY()-e.GetLastVisiblePos()>0 THEN
      (* Down *)
      lines:=cursor.GetY()-e.GetLastVisiblePos();

      e.startLine.GotoCursor(cursor);
      IF e.startLine.GotoColumn(1) THEN END;
      e.startLine.GetRiderAtSOL(endLine);

      h:=1;
      WHILE (h<e.vSize) & e.startLine.Up() DO
        INC(h);
      END;

      refreshVert:=TRUE;
    ELSE
      (* cursor already in visible area *)
      e.GetLastVisibleLine(endLine);
      refreshVert:=FALSE;
      lines:=0;
    END;

    IF refreshVert THEN
      IF ABS(lines)<e.vSize THEN
        (*
          We have to move less than the size of the display.
          Thus we can copy parts of the display content
          and only manually draw newly visible lines.
        *)
        IF lines>0 THEN
          e.MoveRegion(lines+1,e.vSize,-lines);
          e.SetDirtyVisibleRange(e.vSize-lines+1,e.vSize);
        ELSE
          e.MoveRegion(1,e.vSize+lines,-lines);
          e.SetDirtyVisibleRange(1,-lines);
        END;
      ELSE
        (* We must completly redraw the display *)

        (* We try to center the display around the given point *)
        IF lines>0 THEN
          h:=e.vSize;
          WHILE (h>(e.vSize DIV 2)) & endLine.MoveNextLine() & e.startLine.Down() DO
            DEC(h);
          END;
        ELSE
          h:=1;
          WHILE (h<(e.vSize DIV 2)) & e.startLine.Up() & endLine.MoveLastLine() DO
            INC(h);
          END;
        END;

        e.SetDirtyAll;
      END;
    END;

    (*
      Adjust horizontal
    *)

    info:=e.GetLineText(y);

    a:=0;
    WHILE (a<LEN(info.text^)) & (info.info[a].pos<x) DO
      INC(a);
    END;
    WHILE ((a+1)<LEN(info.text^)) & (info.info[a+1].pos<=x) DO
      INC(a);
    END;

    IF (a+1+e.hScrollOffset<=e.hSize) THEN
      IF (e.startColumn>1) THEN
        e.startColumn:=1;
        e.SetDirtyAll;
      END;
    ELSIF a+1-e.hScrollOffset<e.startColumn THEN
      e.startColumn:=a+1-e.hScrollOffset;
      e.SetDirtyAll;
    ELSIF (a+1+e.hScrollOffset>e.startColumn+e.hSize-1) THEN
      e.startColumn:=a+1+e.hScrollOffset-e.hSize;
      e.SetDirtyAll;
    END;
  END MakeCursorVisible;

  (* -------- basic editing ---------- *)

  PROCEDURE (e: Edit) CursorInsertString*(string : ARRAY OF CHAR);

  BEGIN
    IF e.readWrite THEN
      e.DeleteSelection;
      IF ~e.cursor.InsertString(string) THEN
        e.DisplayBeep;
      ELSE
        e.MakeCursorVisible(e.cursor);
      END;
    ELSE
      e.DisplayBeep;
    END;
  END CursorInsertString;

  PROCEDURE (e: Edit) CursorInsertChar*(char : CHAR);

  VAR
    string : ARRAY 2 OF CHAR;

  BEGIN
    string[0]:=char;
    string[1]:=0X;
    e.CursorInsertString(string);
  END CursorInsertChar;

  PROCEDURE (e: Edit) CursorMatchBlock*(cursor : T.Cursor;
                                             onlyVisible : BOOLEAN):BOOLEAN;

    (**
      TODO
      Move this out of the core!
    *)

  VAR
    rider    : T.Rider;
    info     : LineInfo;
    pos,
    count,
    limit    : LONGINT;
    start,
    end      : S.Token;

  BEGIN
    e.tmpCursor.GotoCursor(cursor);
    IF e.tmpCursor.GotoColumn(1) THEN END;
    rider:=NIL;
    e.tmpCursor.GetRiderAtSOL(rider);
    info:=e.GetLineTextColored(rider,e.tmpCursor.GetY());

    pos:=0;
    WHILE (pos<LEN(info.text^)) & (info.info[pos].pos<e.cursor.GetX()) DO
      INC(pos);
    END;

    IF pos>=LEN(info.text^) THEN
      RETURN FALSE;
    END;

    WHILE (pos>=0) & ~info.start[pos] DO
      DEC(pos);
    END;

    IF (pos<0) OR (info.token[pos]=NIL) THEN
      RETURN FALSE;
    END;

    IF S.BlockStart IN info.token[pos].flags THEN
      start:=info.token[pos];
      end:=NIL;
      count:=1;
    ELSIF S.BlockEnd IN info.token[pos].flags THEN
      start:=NIL;
      end:=info.token[pos];
      count:=-1;
    ELSE
      RETURN FALSE;
    END;

    IF start#NIL THEN
      limit:=e.GetLastVisiblePos();
      WHILE (count#0) & (~onlyVisible OR (e.tmpCursor.GetY()<=limit)) DO
        INC(pos);
        IF pos>=LEN(info.text^) THEN
          IF ~e.tmpCursor.Goto(1,e.tmpCursor.GetY()+1) THEN
            RETURN FALSE;
          END;
          rider:=NIL;
          e.tmpCursor.GetRiderAtSOL(rider);
          info:=e.GetLineTextColored(rider,e.tmpCursor.GetY());
          pos:=0;
        END;

        IF info.start[pos] THEN
          IF S.BlockStart IN info.token[pos].flags THEN
            INC(count);
          ELSIF S.BlockEnd IN info.token[pos].flags THEN
            DEC(count);
          END;
        END;
      END;
    ELSE
      limit:=e.GetFirstVisiblePos();
      WHILE (count#0) & (~onlyVisible OR (e.tmpCursor.GetY()>=limit)) DO
        DEC(pos);
        IF pos<0 THEN
          IF ~e.tmpCursor.Goto(1,e.tmpCursor.GetY()-1) THEN
            RETURN FALSE;
          END;
          rider:=NIL;
          e.tmpCursor.GetRiderAtSOL(rider);
          info:=e.GetLineTextColored(rider,e.tmpCursor.GetY());
          pos:=LEN(info.text^)-1;
        END;

        IF info.start[pos] THEN
          IF S.BlockStart IN info.token[pos].flags THEN
            INC(count);
          ELSIF S.BlockEnd IN info.token[pos].flags THEN
            DEC(count);
          END;
        END;
      END;
    END;

    cursor.GotoCursor(e.tmpCursor);
    IF cursor.GotoColumn(info.info[pos].pos) THEN END;

    RETURN TRUE;
  END CursorMatchBlock;

  (* -------- Displaying ---------- *)

  PROCEDURE (e : Edit) UpdateCounts;

  VAR
    msg : T.StatusChangedMsg;

  BEGIN
    update.edit:=e;
    NEW(msg);
    update.msg:=msg;
    e.Send(update,updateMsg);

    e.vAdjustment.Set(e.GetFirstVisiblePos(),
                      e.GetLastVisiblePos()-e.GetFirstVisiblePos()+1,
                      e.model.lines);

    e.hAdjustment.Set(e.startColumn,
                      e.hSize,
                      1000);
  END UpdateCounts;

  PROCEDURE (e : Edit) UpdateName;

  VAR
    msg : T.NameChangedMsg;

  BEGIN
    update.edit:=e;
    NEW(msg);
    update.msg:=msg;
    e.Send(update,updateMsg);
  END UpdateName;

  PROCEDURE (e : Edit) UpdateLowLevel(msg : O.ResyncMsg);

  BEGIN
    update.edit:=e;
    update.msg:=msg;
    e.Send(update,updateMsg);
  END UpdateLowLevel;

  (* -------- initialization ---------- *)

  PROCEDURE CreateStyleData(fg, bg : D.Color; style : SET):StyleData;

  VAR
    data : StyleData;

  BEGIN
    NEW(data);
    data.fg:=fg;
    data.bg:=bg;
    data.style:=style;

    RETURN data;
  END CreateStyleData;

  PROCEDURE (e : Edit) ColorShemeLight*;

  VAR
    fg,bg,
    tmp,
    tmp2  : D.Color;

  BEGIN
    fg:=D.blackColor;
    bg:=D.whiteColor;

    IF D.display.displayType=D.displayTypeTextual THEN
      S.NormalStyle.Set(CreateStyleData(fg,bg,{}));
    ELSE
      S.NormalStyle.Set(CreateStyleData(fg,bg,{D.bold}));
    END;

    D.display.AllocateNamedColor("red",fg,tmp);
    S.KeywordStyle.Set(CreateStyleData(tmp,bg,{}));

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("yellow",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("orange",fg,tmp);
    END;
    S.StringStyle.Set(CreateStyleData(tmp,bg,{}));

    IF D.display.displayType=D.displayTypeTextual THEN
      S.CommentStyle.Set(CreateStyleData(fg,bg,{D.bold}));
    ELSE
      D.display.AllocateNamedColor("dim grey",fg,tmp);
      S.CommentStyle.Set(CreateStyleData(tmp,bg,{D.slanted}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("blue",fg,tmp);
      S.DocuStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
    ELSE
      D.display.AllocateNamedColor("DarkOrange",fg,tmp);
      S.DocuStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      S.SpecialStyle.Set(CreateStyleData(bg,fg,{}));
    ELSE
      D.display.AllocateNamedColor("grey",fg,tmp);
      S.SpecialStyle.Set(CreateStyleData(bg,tmp,{}));
    END;

    S.CursorStyle.Set(CreateStyleData(bg,fg,{}));

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("red",fg,tmp);
      D.display.AllocateNamedColor("yellow",bg,tmp2);
    ELSE
      D.display.AllocateNamedColor("red",fg,tmp);
      D.display.AllocateNamedColor("yellow",bg,tmp2);
    END;
    S.MarkStyle.Set(CreateStyleData(tmp,tmp2,{}));

    S.SelectionStyle.Set(CreateStyleData(D.fillTextColor,D.fillColor,{}));

    S.BookmarkStyle.Set(CreateStyleData(D.fillTextColor,D.fillColor,{}));

    D.display.AllocateNamedColor("Dark slate grey",D.halfShineColor,tmp);
    S.LineStyle.Set(CreateStyleData(D.blackColor,tmp,{}));

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("cyan",fg,tmp);
      S.OperatorStyle.Set(CreateStyleData(tmp,bg,{}));
    ELSE
      D.display.AllocateNamedColor("Blue",fg,tmp);
      S.OperatorStyle.Set(CreateStyleData(tmp,bg,{}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("magenta",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("DarkViolet",fg,tmp);
    END;
    S.PreprocessStyle.Set(CreateStyleData(tmp,bg,{D.bold}));

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("green",fg,tmp);
      S.DatatypeStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
    ELSE
      D.display.AllocateNamedColor("DarkGreen",fg,tmp);
      S.DatatypeStyle.Set(CreateStyleData(tmp,bg,{}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("cyan",fg,tmp);
      S.NumberStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
    ELSE
      D.display.AllocateNamedColor("DarkCyan",fg,tmp);
      S.NumberStyle.Set(CreateStyleData(tmp,bg,{}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("green",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("Brown",fg,tmp);
    END;
    S.FunctionStyle.Set(CreateStyleData(tmp,bg,{}));

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("magenta",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("Purple",fg,tmp);
    END;
    S.IncludeStyle.Set(CreateStyleData(tmp,bg,{D.bold}));


    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("cyan",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("DarkMargenta",fg,tmp);
    END;
    S.Quote1Style.Set(CreateStyleData(tmp,bg,{}));
    D.display.AllocateNamedColor("blue",fg,tmp);
    S.Quote2Style.Set(CreateStyleData(tmp,bg,{}));
    D.display.AllocateNamedColor("green",fg,tmp);
    S.Quote3Style.Set(CreateStyleData(tmp,bg,{}));
    D.display.AllocateNamedColor("red",fg,tmp);
    S.Quote4Style.Set(CreateStyleData(tmp,bg,{}));

    D.display.AllocateNamedColor("red",fg,tmp);
    S.HeaderStyle.Set(CreateStyleData(tmp,bg,{}));

    D.display.AllocateNamedColor("orange",fg,tmp);
    S.WarningStyle.Set(CreateStyleData(tmp,bg,{D.bold}));

    D.display.AllocateNamedColor("red",fg,tmp);
    S.ErrorStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
  END ColorShemeLight;

  PROCEDURE (e : Edit) ColorShemeDark*;

  VAR
    fg,bg,
    tmp,
    tmp2  : D.Color;

  BEGIN
    fg:=D.whiteColor;
    bg:=D.blackColor;

    IF D.display.displayType=D.displayTypeTextual THEN
      S.NormalStyle.Set(CreateStyleData(fg,bg,{D.bold}));
    ELSE
      S.NormalStyle.Set(CreateStyleData(fg,bg,{}));
    END;

    D.display.AllocateNamedColor("red",fg,tmp);
    S.KeywordStyle.Set(CreateStyleData(tmp,bg,{D.bold}));

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("yellow",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("orange",fg,tmp);
    END;
    S.StringStyle.Set(CreateStyleData(tmp,bg,{}));

    IF D.display.displayType=D.displayTypeTextual THEN
      S.CommentStyle.Set(CreateStyleData(fg,bg,{}));
    ELSE
      D.display.AllocateNamedColor("dim grey",fg,tmp);
      S.CommentStyle.Set(CreateStyleData(tmp,bg,{D.slanted}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("yellow",fg,tmp);
      S.DocuStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
    ELSE
      D.display.AllocateNamedColor("yellow",fg,tmp);
      S.DocuStyle.Set(CreateStyleData(tmp,bg,{D.slanted}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      S.SpecialStyle.Set(CreateStyleData(bg,fg,{}));
    ELSE
      D.display.AllocateNamedColor("grey",fg,tmp);
      S.SpecialStyle.Set(CreateStyleData(bg,tmp,{}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      S.CursorStyle.Set(CreateStyleData(bg,fg,{}));
    ELSE
      S.CursorStyle.Set(CreateStyleData(bg,fg,{}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("red",fg,tmp);
      D.display.AllocateNamedColor("yellow",bg,tmp2);
    ELSE
      D.display.AllocateNamedColor("red",fg,tmp);
      D.display.AllocateNamedColor("yellow4",bg,tmp2);
    END;
    S.MarkStyle.Set(CreateStyleData(tmp,tmp2,{}));

    S.SelectionStyle.Set(CreateStyleData(D.fillTextColor,D.fillColor,{}));

    S.BookmarkStyle.Set(CreateStyleData(D.fillTextColor,D.fillColor,{}));

    D.display.AllocateNamedColor("Dark slate grey",D.halfShineColor,tmp);
    S.LineStyle.Set(CreateStyleData(D.blackColor,tmp,{}));

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("cyan",fg,tmp);
      S.OperatorStyle.Set(CreateStyleData(tmp,bg,{}));
    ELSE
      D.display.AllocateNamedColor("SteelBlue",fg,tmp);
      S.OperatorStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("magenta",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("purple",fg,tmp);
    END;
    S.PreprocessStyle.Set(CreateStyleData(tmp,bg,{D.bold}));

    D.display.AllocateNamedColor("green",fg,tmp);
    IF D.display.displayType=D.displayTypeTextual THEN
      S.DatatypeStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
    ELSE
      S.DatatypeStyle.Set(CreateStyleData(tmp,bg,{}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("cyan",fg,tmp);
      S.NumberStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
    ELSE
      D.display.AllocateNamedColor("aquamarine",fg,tmp);
      S.NumberStyle.Set(CreateStyleData(tmp,bg,{}));
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("green",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("palegreen",fg,tmp);
    END;
    S.FunctionStyle.Set(CreateStyleData(tmp,bg,{}));

    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("magenta",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("MediumPurple",fg,tmp);
    END;
    S.IncludeStyle.Set(CreateStyleData(tmp,bg,{}));


    IF D.display.displayType=D.displayTypeTextual THEN
      D.display.AllocateNamedColor("cyan",fg,tmp);
    ELSE
      D.display.AllocateNamedColor("aquamarine",fg,tmp);
    END;
    S.Quote1Style.Set(CreateStyleData(tmp,bg,{}));
    D.display.AllocateNamedColor("blue",fg,tmp);
    S.Quote2Style.Set(CreateStyleData(tmp,bg,{}));
    D.display.AllocateNamedColor("green",fg,tmp);
    S.Quote3Style.Set(CreateStyleData(tmp,bg,{}));
    D.display.AllocateNamedColor("red",fg,tmp);
    S.Quote4Style.Set(CreateStyleData(tmp,bg,{}));

    D.display.AllocateNamedColor("red",fg,tmp);
    S.HeaderStyle.Set(CreateStyleData(tmp,bg,{}));

    D.display.AllocateNamedColor("orange",fg,tmp);
    S.WarningStyle.Set(CreateStyleData(tmp,bg,{D.bold}));

    D.display.AllocateNamedColor("red",fg,tmp);
    S.ErrorStyle.Set(CreateStyleData(tmp,bg,{D.bold}));
  END ColorShemeDark;

  PROCEDURE (e: Edit) Init*;

  BEGIN
    e.Init^;

    e.SetFlags({G.canFocus});
    e.RemoveFlags({G.stdFocus});

    e.SetPrefs(prefs);

    e.model:=NIL;
    e.resolver:=DefaultConfigResolver;
    e.config:=NIL;

    e.top:=e.vAdjustment.GetTopModel();
    e.first:=e.hAdjustment.GetTopModel();

    e.SetObjectFrame(F.CreateFrame(F.none));

    e.ColorShemeLight;

    e.model:=NIL;
    e.hSize:=0;
    e.vSize:=0;

    e.stableSelection:=TRUE;
    e.readWrite:=TRUE;

    e.hScrollOffset:=3;
    e.showEOL:=FALSE;
    e.showAEOL:=FALSE;
    e.showTab:=FALSE;
    e.showSpace:=FALSE;
    e.showCurrentLine:=FALSE;
    e.selectCurrentLine:=FALSE;

    e.plugins:=NEW(ArrayList.ArrayList(Plugin),10);
    e.pluginDict:=NEW(Dictionary.Dictionary(STRING,Plugin));

    e.ResizeLines;
  END Init;

  PROCEDURE (e: Edit) InitText;

  BEGIN
    e.cursor:=e.model.GetOrCreateCursor("cursor",{});
    e.startLine:=e.model.GetOrCreateCursor("startLine",{T.cursorFix,T.cursorHidden});
    e.tmpCursor:=e.model.GetOrCreateCursor("tmp",{T.cursorHidden});
    e.tmp2Cursor:=e.model.GetOrCreateCursor("tmp2",{T.cursorHidden});
    e.tmp3Cursor:=e.model.GetOrCreateCursor("tmp3",{T.cursorHidden});
    e.markA:=e.model.GetCursor("markA");
    e.markB:=e.model.GetCursor("markB");
    e.blockCursor:=e.model.GetOrCreateCursor("BlockCursor",{T.cursorHidden});

    e.moveRegion:=FALSE;

    e.showBlock:=FALSE;

    e.startColumn:=1;

    e.SetDirtyAll;

    IF e.IsSelected() & D.display.RegisterSelection(e,e.GetWindow()) THEN
    END;
  END InitText;

  PROCEDURE (e: Edit) DeinitText;

  BEGIN
    IF e.IsSelected() THEN
      D.display.CancelSelection;
    END;

    e.blockCursor:=NIL;
    e.markB:=NIL;
    e.markA:=NIL;
    e.tmp3Cursor:=NIL;
    e.tmp2Cursor:=NIL;
    e.tmpCursor:=NIL;
    e.cursor:=NIL;
    e.startLine:=NIL;
  END DeinitText;

  PROCEDURE (e: Edit) SetModel*(model : O.Model);

  BEGIN
    IF e.model#NIL THEN
      e.DeinitText;
      e.UnattachModel(e.model);
    END;
    IF (model#NIL) & (model IS T.Text) THEN
      e.model:=model(T.Text);
      e.InitText;
      e.config:=e.resolver(e);
      e.AttachModel(model);
    ELSE
      e.model:=NIL;
    END;
  END SetModel;

  PROCEDURE (e : Edit) SetConfigResolver*(resolver : ConfigResolver);

  BEGIN
    e.resolver:=resolver;
  END SetConfigResolver;

  PROCEDURE (e : Edit) SetConfig*(config : Config);

  BEGIN
    e.config:=config;
    e.UpdateName;
  END SetConfig;

  PROCEDURE (e: Edit) SetReadWrite*(readWrite : BOOLEAN);

  BEGIN
    e.readWrite:=readWrite;
  END SetReadWrite;

  PROCEDURE (e: Edit) SetStableSelection*(stable : BOOLEAN);

  BEGIN
    e.stableSelection:=stable;
  END SetStableSelection;

  (* -------- global utils ---------- *)

  PROCEDURE GetTmpText(size : LONGINT):U.Text;

  BEGIN
    IF (tmpText=NIL) OR (LEN(tmpText^)<size) THEN
      NEW(tmpText,size);
    END;

    RETURN tmpText;
  END GetTmpText;

  (* ---------- Selection --------------- *)


  (* ---------- Printing --------------- *)

  PROCEDURE (e : Edit) PrintLine(draw : D.DrawInfo; line : LineInfo; pos,from,to : LONGINT);

  (**
    Print the given line at the given display position.
  *)

  VAR
    a,p,
    x,
    i,j  : LONGINT;
    tmp  : U.Text;

  BEGIN
    from:=U.MaxLong(from,e.startColumn)-1;
    to:=U.MinLong(to,e.startColumn+e.hSize-1)-1;

(*    IF to>=LEN(line.info^) THEN
      to:=LEN(line.info^)-1;
    END;*)

    (* Draw areas of equal display parameter *)
    p:=from;
    x:=p-e.startColumn+1;
    WHILE p<=to DO
      a:=p;
      WHILE (a+1<=to)
      & (line.info[p].style.data(StyleData).fg=line.info[a+1].style.data(StyleData).fg)
      & (line.info[p].style.data(StyleData).bg=line.info[a+1].style.data(StyleData).bg)
      & (line.info[p].style.data(StyleData).style=line.info[a+1].style.data(StyleData).style) DO
        INC(a);
      END;
      draw.PushForeground(line.info[p].style.data(StyleData).fg);
      draw.PushBackground(line.info[p].style.data(StyleData).bg);
      draw.PushFont(D.fixedFont,line.info[p].style.data(StyleData).style);

      tmp:=GetTmpText(a-p+1+1);
      (*      str.Extract(line.text^,SHORT(p),SHORT(a-p+1),tmp^);*)

      i:=0;
      j:=p;
      WHILE j<=a DO
        tmp[i]:=line.text[j];
        INC(i);
        INC(j);
      END;
      tmp[i]:=0X;

(*      draw.DrawFillString(e.x+x*e.fontWidth,
                          e.y+pos*e.font.height-e.font.descent,
                          tmp^,a-p+1);*)

      draw.DrawFillString(e.x+x*e.fontWidth,
                          e.y+(pos-1)*e.font.height+e.font.ascent,
                          tmp^,a-p+1);

      draw.PopFont;
      draw.PopBackground;
      draw.PopForeground;

      p:=a+1;
      x:=p-e.startColumn+1;
    END;

    IF (to=e.startColumn+e.hSize-2) & (x*e.fontWidth<e.width) THEN
      draw.PushForeground(S.NormalStyle.data(StyleData).bg);
      draw.FillRectangle(e.x+x*e.fontWidth,e.y+(pos-1)*e.font.height,
                         e.width-x*e.fontWidth,e.font.height);
      draw.PopForeground;
    END;
  END PrintLine;

(*  PROCEDURE (e : Edit) DrawRange(draw : D.DrawInfo; x1,x2,y : LONGINT);

  (**
    Show or hide the given mark at the given display position.

    We must not evaluate the position within mark itself but use the
    coordinates explicitly handed.
  *)

  VAR
    pos,
    a,b   : LONGINT;
    rider : T.Rider;
    info  : LineInfo;

  BEGIN
    IF e.visible THEN

      IF e.IsVisible(y) THEN

        pos:=y-e.GetFirstVisiblePos()+1; (* display position *)

        e.GetLine(y,rider);
        info:=e.GetLineTextColored(rider,y);

        a:=0;
        WHILE (a<LEN(info.text^)) & (info.info[a].pos<x1) DO
          INC(a);
        END;
        b:=a;
        WHILE ((b+1)<LEN(info.text^)) & (info.info[b+1].pos<=x2) DO
          INC(b);
        END;

        e.PrintLine(draw,info,pos,a+1,b+1);
      END;
    ELSE
      e.lines[y].drawn:=FALSE; (* TODO: Is this correct? *)
    END;
  END DrawRange;*)

  PROCEDURE (e : Edit) Update*;

  (**
    Refresh each to be refreshed line.
  *)

  VAR
    x,y   : LONGINT;
    draw  : D.DrawInfo;
    rider : T.Rider;
    info  : LineInfo;

  BEGIN
    IF e.visible THEN

      draw:=e.GetDrawInfo();

      x:=0;
      IF e.model#NIL THEN
        draw.PushFont(D.fixedFont,{});

        IF e.moveRegion THEN
          draw.CopyArea(e.x,                                        (* sX     *)
                        e.y+(e.mrStart-1)*e.font.height,            (* sY     *)
                        e.width,                                    (* width  *)
                        (e.mrEnd-e.mrStart+1)*e.font.height,        (* height *)
                        e.x,                                        (* dX     *)
                        e.y+(e.mrStart-1+e.mrCount)*e.font.height); (* dY     *)
          e.moveRegion:=FALSE;
        END;

        y:=e.startLine.GetY();
        e.GetLine(y,rider);
        WHILE (x<LEN(e.lines^)) & (rider#NIL) DO
          IF ~e.lines[x].drawn THEN
            info:=e.GetLineTextColored(rider,y);
            e.PrintLine(draw,info,x+1,e.startColumn,e.startColumn+e.hSize-1);
            e.lines[x].drawn:=TRUE;
          END;

          IF ~rider.MoveNextLine() THEN
            rider:=NIL;
          END;

          INC(x);
          INC(y);
        END;
        draw.PopFont;
      END;

      (* Only necessary, if refresh of whole object *)
      IF x*e.font.height<e.height THEN
        draw.PushForeground(S.NormalStyle.data(StyleData).bg);
        draw.FillRectangle(e.x,e.y+x*e.font.height,
                           e.width,e.height-x*e.font.height);
        draw.PopForeground;
      END;

      e.UpdateCounts;
    END;
  END Update;

  PROCEDURE (e: Edit) Refresh*;

  BEGIN
    e.SetDirtyAll;
    e.Update;
  END Refresh;

  PROCEDURE (e: Edit) SetEndMark*(cursor : T.Cursor);

  VAR
    a,b,
    c,d   : LONGINT;
    markA,
    markB : T.Cursor;

  BEGIN
    ASSERT(e.markA#NIL);

    IF e.IsSelected() THEN
      markA:=e.GetStartMark();
      markB:=e.GetEndMark();
      a:=markA.GetY();
      b:=markB.GetY();

      e.markB.GotoCursor(cursor);

      markA:=e.GetStartMark();
      markB:=e.GetEndMark();
      c:=markA.GetY();
      d:=markB.GetY();

      (* TODO: Make only a refresh of changed region *)
      IF a=c THEN
        IF d>=b THEN
          e.model.NotifyRedraw(b,d);
        ELSE
          e.model.NotifyRedraw(d,b);
        END;
      ELSIF b=d THEN
        IF c>=a THEN
          e.model.NotifyRedraw(a,c);
        ELSE
          e.model.NotifyRedraw(c,a);
        END;
      ELSE
        Err.String("!both selection bounds have changed!");
        e.Refresh;
      END;
    ELSIF D.display.RegisterSelection(e,e.GetWindow()) THEN
      e.markB:=e.model.GetOrCreateCursor("markB",{});
      e.markB.GotoCursor(cursor);
      markA:=e.GetStartMark();
      markB:=e.GetEndMark();
      e.model.NotifyRedraw(markA.GetY(),markB.GetY());
    END;
  END SetEndMark;

  PROCEDURE (e : Edit) Deselect*;

  (**
    Called by the display engine when deregistering a selection was
    successfull, or somebody else registered a selection so that our
    selection is not valid anymore.
  *)

  BEGIN
    IF ~e.stableSelection THEN
      e.ClearSelectionInternal;
    END;
  END Deselect;

  PROCEDURE (e : Edit) GetDnDObject*(x,y : LONGINT; drag : BOOLEAN):G.Object;

  BEGIN
    IF e.visible & e.PointIsIn(x,y) & e.IsSelected() & (drag OR ~e.disabled) THEN
      (* we can drag and drop *)
      RETURN e;
    ELSE
      RETURN NIL;
    END;
  END GetDnDObject;

  PROCEDURE (e : Edit) GetDragInfo*(VAR dragInfo : DD.DnDDataInfo);

  BEGIN
    dragInfo.AddDataType(DD.text,DD.none,{DD.copy,DD.move,DD.insert},DD.copy);
  END GetDragInfo;

  PROCEDURE (e : Edit) GetDropDataType*(VAR dragInfo : DD.DnDDataInfo;
                                        VAR group, type, action : LONGINT):BOOLEAN;

  BEGIN
    group:=DD.text;
    type:=DD.joker;
    RETURN dragInfo.FindDataType(group,type,action);
  END GetDropDataType;

  PROCEDURE (e : Edit) GetDragData*(group, type, action : LONGINT):DD.DnDData;

  VAR
    data   : DD.DnDStringData;
    buffer : T.Buffer;
    tmp    : U.Text;

  BEGIN
    IF (group=DD.text) & (e.IsSelected()) THEN
      buffer:=e.model.CopyArea(e.GetStartMark(),e.GetEndMark());
      NEW(data);
      tmp:=buffer.GetTextCopy();
      data.string:=Object.NewLatin1(tmp^);

      IF action=DD.move THEN
        e.DeleteSelection;
      END;

      RETURN data;
    ELSE
      RETURN NIL;
    END;
  END GetDragData;

  PROCEDURE (e : Edit) GetQualifierString(qualifier : SET; VAR key : ARRAY OF CHAR);

  VAR
    hasQual : BOOLEAN;

  BEGIN
    COPY("",key);

    hasQual:=FALSE;
    IF qualifier*E.shiftMask#{} THEN
      str.Append("S",key);
      hasQual:=TRUE;
    END;
    IF qualifier*E.controlMask#{} THEN
      str.Append("C",key);
      hasQual:=TRUE;
    END;
    IF qualifier*E.altMask#{} THEN
      str.Append("A",key);
      hasQual:=TRUE;
    END;
    IF qualifier*{E.button1}#{} THEN
      str.Append("1",key);
      hasQual:=TRUE;
    END;
    IF qualifier*{E.button2}#{} THEN
      str.Append("2",key);
      hasQual:=TRUE;
    END;
    IF qualifier*{E.button3}#{} THEN
      str.Append("3",key);
      hasQual:=TRUE;
    END;
    IF qualifier*{E.button4}#{} THEN
      str.Append("4",key);
      hasQual:=TRUE;
    END;
    IF qualifier*{E.button5}#{} THEN
      str.Append("5",key);
      hasQual:=TRUE;
    END;

    IF hasQual THEN
      str.Append("+",key);
    END;
  END GetQualifierString;

  PROCEDURE (e : Edit) CoordsToTextPos(cX,cY : LONGINT; VAR x,y : LONGINT):BOOLEAN;

  VAR
    info : LineInfo;

  BEGIN
    cX:=U.RoundRange(cX,e.x,e.x+e.width-1);
    cY:=U.RoundRange(cY,e.y,e.y+e.height-1);

    y:=e.GetFirstVisiblePos()+((cY-e.y) DIV e.font.height);

    IF (y<1) OR (y>e.model.lines) OR ~e.IsVisible(y) THEN
      RETURN FALSE;
    END;

    (*
      Since the drawing of the line is not 1:1 similar to the internal
      array of chars (a character can be wider than one char), we let the
      parser fill the draw bufffer and related structs for this line and
      look there for the X coordinate of that screen position.
    *)
    info:=e.GetLineText(y);
    x:=info.info[((cX-e.x) DIV e.fontWidth)+e.startColumn-1].pos;

    RETURN TRUE;
  END CoordsToTextPos;

  PROCEDURE (e : Edit) CalcSize*;

  BEGIN
    e.font:=D.fixedFont;
    e.fontWidth:=e.font.TextWidth("m",1,{});

    e.width:=5*e.fontWidth;
    e.height:=2*e.font.height;


    e.minWidth:=e.width;
    e.minHeight:=e.height;

    e.CalcSize^;
  END CalcSize;

  (* -------- resize ---------- *)

  PROCEDURE (e: Edit) HandleResize(width,height : LONGINT);

  VAR
    x     : LONGINT;
    rider : T.Rider;

  BEGIN
    IF height#e.vSize THEN
      e.vSize:=height;
      e.ResizeLines;

      e.startLine.GetRiderAtSOL(rider);
      x:=1;
      WHILE(x<e.vSize) & rider.MoveNextLine() DO
        INC(x);
      END;

      (* We want the last line of the text to be the last line in display, if possible *)
      x:=e.vSize-x;
      WHILE (x>0) & e.startLine.Up() DO
        DEC(x);
      END;
    END;
    e.hSize:=width;
  END HandleResize;

  PROCEDURE (e : Edit) Draw*(x,y,w,h : LONGINT);

  VAR
    start,
    end    : LONGINT;

  BEGIN
    e.Draw^(x,y,w,h);

    IF ~e.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    e.HandleResize(e.width DIV e.fontWidth,e.height DIV e.font.height);

    start:=y DIV e.font.height+1;
    end:=U.MinLong(e.GetLastVisiblePos()-e.GetFirstVisiblePos(),(y+h-1) DIV e.font.height+1);

    e.SetDirtyVisibleRange(start,end);

    (* TODO: Refresh only the lines that are in the given region *)
    e.Refresh;
  END Draw;

  PROCEDURE CreateEdit*():Edit;

  VAR
    edit : Edit;

  BEGIN
    NEW(edit);
    edit.Init;

    RETURN edit;
  END CreateEdit;

  (* -------- function execution ---------- *)

  PROCEDURE (e: Edit) ExecuteFunctionPost*;

  BEGIN
    IF e.showBlock THEN
      e.SetDirtyLine(e.blockCursor.GetY());
    END;

    e.blockCursor.GotoCursor(e.cursor);
    e.showBlock:=e.CursorMatchBlock(e.blockCursor,TRUE);
    IF e.showBlock THEN
      e.SetDirtyLine(e.blockCursor.GetY());
    END;

    e.Update;
  END ExecuteFunctionPost;

  PROCEDURE (e: Edit) ExecuteFunction*(function : Fct);

  BEGIN
    ASSERT(function#NIL);

    e.model.CreateNewUndoGroup;
    function(e);
    e.ExecuteFunctionPost;
  END ExecuteFunction;

  PROCEDURE (e: Edit) ExecuteFunctionKey*(key : ARRAY OF CHAR):BOOLEAN;

  VAR
    entry : KeyEntry;

  BEGIN
    entry:=e.config.keyList;
    WHILE (entry#NIL) & (entry.key#key) DO
      entry:=entry.next;
    END;

    IF entry#NIL THEN
      IF entry.fct#NIL THEN
        e.ExecuteFunction(entry.fct);
      END;
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END ExecuteFunctionKey;

  PROCEDURE (e: Edit) ExecuteText*(text : ARRAY OF CHAR);

  BEGIN
    e.model.CreateNewUndoGroup;
    e.CursorInsertString(text);
    e.ExecuteFunctionPost;
  END ExecuteText;

  PROCEDURE (e : Edit) AddPlugin*(name : STRING; plugin : Plugin);

  BEGIN
    plugin.name:=name;
    plugin.edit:=e;
    e.plugins.Append(plugin);
    e.pluginDict.Set(name,plugin);
    plugin.Init;
  END AddPlugin;

  PROCEDURE (e : Edit) GetPlugin*(name : STRING):Plugin;

  BEGIN
    IF e.pluginDict.HasKey(name) THEN
      RETURN e.pluginDict.Get(name);
    ELSE
      RETURN NIL;
    END;
  END GetPlugin;

  PROCEDURE (e : Edit) RemovePlugin*(plugin : Plugin);

  VAR
    x : LONGINT;

  BEGIN
    e.pluginDict.Delete(plugin.name);
    FOR x:=0 TO e.plugins.Size()-1 DO
      IF e.plugins.Get(x)=plugin THEN
        plugin.Free;
        plugin.edit:=NIL;
        e.plugins.Remove(x);
        RETURN;
      END;
    END;
  END RemovePlugin;

  PROCEDURE (e : Edit) RemoveAllPlugins*;

  VAR
    x      : LONGINT;
    plugin : Plugin;

  BEGIN
    FOR x:=0 TO e.plugins.Size()-1 DO
      plugin:=e.plugins.Get(x);
      plugin.Free;
      plugin.edit:=NIL;
      e.plugins.Remove(x);
    END;
    e.pluginDict.Clear;
  END RemoveAllPlugins;

  PROCEDURE (e : Edit) HandleDrop*(data : DD.DnDData; action : LONGINT):BOOLEAN;

  VAR
    text : STRING;
    tmp  : Object.CharsLatin1;

  BEGIN
    WITH data : DD.DnDStringData DO

      (*
        TODO: Exchange selection if selection exists
      *)

      CASE action OF
        DD.insert,
        DD.copy,
        DD.move:
        text:=data.string;
        WITH text : Object.String8 DO
          tmp:=text.CharsLatin1();
          e.DeleteSelection;
          IF e.cursor.InsertString(tmp^) THEN END;
          e.ExecuteFunctionPost;
        ELSE
        END;
      ELSE
        RETURN FALSE;
      END;
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END HandleDrop;

  PROCEDURE (e : Edit) HandleMouseEvent*(event : E.MouseEvent;
                                         VAR grab : G.Object):BOOLEAN;

  VAR
    x,y    : LONGINT;
    key    : ARRAY 35 OF CHAR;
    window : D.Window;

  BEGIN
    IF ~e.visible OR e.disabled OR (e.model=NIL) THEN
      RETURN FALSE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) THEN
        IF e.PointIsIn(event.x,event.y) THEN

          e.GetQualifierString(event.qualifier,key);

          window:=e.GetWindow();

          IF (event.button=E.button1) & (event.qualifier={})
          & ~window.IsTrippleClicked()
          & ~window.IsDoubleClicked() THEN
            (* TODO: Make this a function! *)
            IF e.CoordsToTextPos(event.x,event.y,x,y) THEN
              e.ClearSelection;
              IF e.cursor.Goto(x,y) THEN
                e.SetStartMark(e.cursor);
              END;
            END;
            e.ExecuteFunctionPost;
            grab:=e;

            RETURN TRUE;
          ELSIF event.button=E.button2 THEN
            str.Append("MouseButton2",key);
          ELSIF event.button=E.button3 THEN
            str.Append("MouseButton3",key);
          ELSIF event.button=E.button4 THEN
            str.Append("MouseButton4",key);
          ELSIF event.button=E.button5 THEN
            str.Append("MouseButton5",key);
          ELSE
            str.Append("MouseButton1",key);
          END;

          IF window.IsTrippleClicked() THEN
            str.Append(" trippleclick",key);
          ELSIF window.IsDoubleClicked() THEN
            str.Append(" doubleclick",key);
          END;

          IF e.ExecuteFunctionKey(key) THEN
            grab:=e;
            RETURN TRUE;
          END;
        END;
      ELSIF (event.type=E.mouseUp) & (grab#NIL) THEN
        IF e.IsMarkSet() OR (e.IsSelected() & (e.markA.GetPos()=e.markB.GetPos())) THEN
          e.ClearSelection;
        END;
        e.ExecuteFunctionPost;
        grab:=NIL;
        RETURN TRUE;
      END;
    | event : E.MotionEvent DO
      IF event.qualifier={E.button1} THEN
        (* TODO: Make this a function *)
        IF e.IsMarkSet() OR e.IsSelected() THEN
          IF e.CoordsToTextPos(event.x,event.y,x,y) THEN
            IF e.cursor.Goto(x,y) THEN
              e.SetEndMark(e.cursor);
            END;
          END;
        END;
        e.ExecuteFunctionPost;
      ELSE
        e.GetQualifierString(event.qualifier,key);
        (* TODO: At least differntiate between motion up and motion down *)
        str.Append("MouseMotion",key);
        IF e.ExecuteFunctionKey(key) THEN END;
      END;
    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (e : Edit) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  VAR
    buffer : ARRAY 256 OF CHAR;
    key    : ARRAY 20 OF CHAR;

  BEGIN
    IF e.model=NIL THEN
      RETURN FALSE;
    END;

    (* We are only interested in key down messages *)
    IF event.type#E.keyDown THEN
      RETURN FALSE;
    END;

    e.GetQualifierString(event.qualifier,key);

    event.GetName(buffer);
    str.Append(buffer,key);

    (*Err.String(key); Err.Ln;*)

    IF e.ExecuteFunctionKey(key) THEN
      RETURN TRUE;
    ELSE
      IF event.textLength>0 THEN
        e.ExecuteText(event.text^);
        RETURN TRUE;
      ELSE
        (*Err.String(key); Err.Ln;*)
      END;
    END;

    RETURN FALSE;
  END HandleKeyEvent;

  (* -------- model feetback ---------- *)

  PROCEDURE (e: Edit) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF msg=NIL THEN
      IF model=e.model THEN
        e.SetDirtyAll;
        e.Update;
      ELSIF model=e.top THEN
        IF ~e.top.IsNull() & (e.top.GetLongint()#e.GetFirstVisiblePos()) THEN
          e.ScrollTo(e.top.GetLongint());
          e.ExecuteFunctionPost;
        END;
      ELSIF model=e.first THEN
        IF ~e.first.IsNull() & (e.first.GetLongint()#e.startColumn) THEN
          e.startColumn:=e.first.GetLongint();
          e.SetDirtyAll;
          e.ExecuteFunctionPost;
        END;
      END;

    ELSE
      WITH
        msg : T.RedrawMsg DO
          e.SetDirtyRange(msg.from,msg.to);
      | msg : T.CursorMsg DO
        IF msg.cursor=e.cursor THEN
          e.SetDirtyLine(msg.oldPos.y);
          e.SetDirtyLine(msg.cursor.GetY());
          e.MakeCursorVisible(msg.cursor);
        END;
      | msg : T.DeleteLinesMsg DO
          e.UpdateDeleteLines(msg.from,msg.count);
      | msg : T.InsertLinesMsg DO
          e.UpdateInsertLines(msg.from,msg.count);
      ELSE
        IF model=e.model THEN
          e.UpdateLowLevel(msg);
        END;
      END;
    END;
  END Resync;

  PROCEDURE (e : Edit) Receive*(message : O.Message);

  VAR
    x      : LONGINT;
    plugin : Plugin;

  BEGIN
    FOR x:=0 TO e.plugins.Size()-1 DO
      plugin:=e.plugins.Get(x);
      plugin.Receive(message);
    END;

    e.Receive^(message);
  END Receive;

  PROCEDURE AddColorizer*(fct : Colorizer);

  VAR
    entry : ColorizeEntry;

  BEGIN
    NEW(entry);
    entry.fct:=fct;
    entry.next:=colorizer;
    colorizer:=entry;
  END AddColorizer;

BEGIN
  colorizer:=NIL;

  NEW(globalLine);
  globalLine.info:=NIL;
  globalLine.text:=NIL;
  globalLine.token:=NIL;
  globalLine.start:=NIL;

  fctList:=NEW(Dictionary.Dictionary(STRING,FctEntry));

  NEW(prefs);
  prefs.Init;

  tmpText:=NIL;

  NEW(update);
END VO:Edit:Edit.
