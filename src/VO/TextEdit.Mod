MODULE VO:TextEdit;

  (*
    Provides a simple multiline text edit control.
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

IMPORT E   := VO:Edit:Edit,
  <*PUSH; Warnings:=FALSE; *>
              VO:Edit:Function,
              VO:Edit:Syntax:Standard
  <* POP *>
           ;

TYPE
  TextEdit*     = POINTER TO TextEditDesc;
  TextEditDesc* = RECORD (E.EditDesc)
                   END;

  KeyDesc        = RECORD
                     key : ARRAY 30 OF CHAR;
                     fct : STRING;
                   END;

VAR
  config  : E.Config;
  x       : LONGINT;
  keyList : ARRAY 34 OF KeyDesc;

  PROCEDURE ConfigResolver(e : E.Edit):E.Config;

  BEGIN
    RETURN config;
  END ConfigResolver;

  PROCEDURE (m : TextEdit) Init*;

  BEGIN
    m.Init^;

    m.SetConfigResolver(ConfigResolver);
    m.SetStableSelection(FALSE);
  END Init;

  PROCEDURE CreateTextEdit*():TextEdit;

  VAR
    multi : TextEdit;

  BEGIN
    NEW(multi);
    multi.Init;

    RETURN multi;
  END CreateTextEdit;

BEGIN
  (* Cursor movement *)
  keyList[ 0].key:="Left";        keyList[ 0].fct:="CursorLeft";
  keyList[ 1].key:="Right";       keyList[ 1].fct:="CursorRight";
  keyList[ 2].key:="Up";          keyList[ 2].fct:="CursorUp";
  keyList[ 3].key:="Down";        keyList[ 3].fct:="CursorDown";

  (* paging *)
  keyList[ 4].key:="Prior";       keyList[ 4].fct:="CursorPageUp";
  keyList[ 5].key:="Next";        keyList[ 5].fct:="CursorPageDown";

  (* Scrolling *)
  keyList[ 6].key:="C+Left";      keyList[ 6].fct:="DisplayScrollLeft";
  keyList[ 7].key:="C+Right";     keyList[ 7].fct:="DisplayScrollRight";
  keyList[ 8].key:="C+Up";        keyList[ 8].fct:="DisplayScrollUp";
  keyList[ 9].key:="C+Down";      keyList[ 9].fct:="DisplayScrollDown";

  (* Extended *)
  keyList[10].key:="Home";        keyList[10].fct:="CursorSOL";
  keyList[11].key:="End";         keyList[11].fct:="CursorEOL";
  keyList[12].key:="C+Prior";     keyList[12].fct:="CursorGotoStart";
  keyList[13].key:="C+Next";      keyList[13].fct:="CursorGotoEnd";
  keyList[14].key:="C+Home";      keyList[14].fct:="CursorFirstVisibleRow";
  keyList[15].key:="C+End";       keyList[15].fct:="CursorLastVisibleRow";

  (* Selection *)
  keyList[16].key:="S+Left";      keyList[16].fct:="CursorLeftSelection";
  keyList[17].key:="S+Right";     keyList[17].fct:="CursorRightSelection";
  keyList[18].key:="S+Up";        keyList[18].fct:="CursorUpSelection";
  keyList[19].key:="S+Down";      keyList[19].fct:="CursorDownSelection";
  keyList[20].key:="S+Home";      keyList[20].fct:="CursorSOLSelection";
  keyList[21].key:="S+End";       keyList[21].fct:="CursorEOLSelection";
  keyList[22].key:="S+Prior";     keyList[22].fct:="CursorPageUpSelection";
  keyList[23].key:="S+Next";      keyList[23].fct:="CursorPageDownSelection";
  keyList[24].key:="S+a";         keyList[24].fct:="TextSelectAll";

  (* Cut, copy, paste *)
  keyList[25].key:="S+Insert";    keyList[25].fct:="CursorInsertBuffer";
  keyList[26].key:="C+Insert";    keyList[26].fct:="SelectionCopy";
  keyList[27].key:="S+Delete";    keyList[27].fct:="SelectionCut";

  keyList[28].key:="S+x";         keyList[28].fct:="SelectionCut";
  keyList[29].key:="C+c";         keyList[29].fct:="SelectionCopy";
  keyList[30].key:="C+v";         keyList[30].fct:="CursorInsertBuffer";

  (* Basis editing *)
  keyList[31].key:="Delete";      keyList[31].fct:="CursorDelete";
  keyList[32].key:="BackSpace";   keyList[32].fct:="CursorBackspace";
  keyList[33].key:="Return";      keyList[33].fct:="CursorSplitLine";


  NEW(config);
  config.Init;
  config.SetName("Standard");

  FOR x:=0 TO LEN(keyList)-1 DO
    IF ~config.AddKey(keyList[x].key,keyList[x].fct) THEN
(*      Err.String("Cannot assign '");
      Err.String(keyList[x].fct);
      Err.String("' to key '");
      Err.String(keyList[x].key);
      Err.String("'");
      Err.Ln;*)
      ASSERT(FALSE);
    END;
  END;
END VO:TextEdit.