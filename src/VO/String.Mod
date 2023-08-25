MODULE VO:String;

  (**
    Implements @otype{String}.
  *)

(*
    Implements a string gadget.
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

(*
  Contributions:

  * introducing centered and right alignment. Beat Christen, 08-Dec-97

*)


IMPORT BG  := VO:Base:Background,
       D   := VO:Base:Display,
       DD  := VO:Base:DragDrop,
       E   := VO:Base:Event,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,

       V   := VO:Model:Value,

       G   := VO:Object,

       CC  := CharClass,
              Object;

CONST
  enteredMsg    * = 0;
  escapeMsg     * = 1;
  extNavMsg     * = 2;

  leftAligned   * = 0;
  rightAligned  * = 1;
  centerAligned * = 2;

  (* mode *)
  normal*   = 0;
  password* = 1;

  passwordChar      = "*";

  (* Known actions *)
  actionCut         =  1;
  actionCopy        =  2;
  actionPaste       =  3;
  actionSelectAll   =  4;
  actionReturn      =  5;
  actionEscape      =  6;
  actionSelectLeft  =  7;
  actionCursorLeft  =  8;
  actionSelectRight =  9;
  actionCursorRight = 10;
  actionSelectStart = 11;
  actionCursorStart = 12;
  actionSelectEnd   = 13;
  actionCursorEnd   = 14;
  actionBackspace   = 15;
  actionDelete      = 16;

TYPE
  Prefs*          = POINTER TO PrefsDesc;
  PrefsDesc*      = RECORD (G.PrefsDesc)
                      selection*   : G.Background;
                      gridDisable* : BOOLEAN;
                      baseline*    : BOOLEAN;
                    END;

  Alignment*      = LONGINT;

  String*         = POINTER TO StringDesc;
  StringDesc*     = RECORD (G.GadgetDesc)
                      (**
                        Implements a single one-line text input object.

                        Its expect a model of type @otype{V.StringModel}.
                      *)
                      textAlign   : Alignment;
                      textWidth,
                      visWidth,
                      offset,
                      cursor-,
                      markA-,
                      markB-,
                      textPos     : LONGINT;
                      font        : D.Font;
                      string-     : V.ValueModel;
                      selected    : BOOLEAN;
                      readOnly    : BOOLEAN;
                      mode        : LONGINT;
                    END;

  Controller*     = POINTER TO ControllerDesc;
  ControllerDesc* = RECORD (G.ControllerDesc)
                    END;

  EnteredMsg*     = POINTER TO EnteredMsgDesc;
  EnteredMsgDesc* = RECORD (O.MessageDesc)
                    END;

  EscapeMsg*      = POINTER TO EscapeMsgDesc;
  EscapeMsgDesc*  = RECORD (O.MessageDesc)
                    END;

  ExtNavMsg*      = POINTER TO ExtNavMsgDesc;
  ExtNavMsgDesc*  = RECORD (O.MessageDesc)
                      event* : E.KeyEvent;
                    END;

VAR
  prefs*     : Prefs;
  controller : Controller;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.tableBackgroundColorIndex));
    p.selection:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.fillColorIndex));

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.textButton);
    ELSE
      p.frame:=F.CreateFrame(F.double3DIn);
    END;
    p.gridDisable:=TRUE;
    p.baseline:=FALSE;
  END Initialize;

  PROCEDURE (s : String) Init*;

  BEGIN
    s.Init^;

    s.SetPrefs(prefs); (* We set the prefs *)
    s.SetController(controller);

    s.SetFlags({G.canFocus});
    s.RemoveFlags({G.stdFocus});

    s.textWidth:=256;
    s.visWidth:=20;
    s.offset:=0;
    s.cursor:=0;
    s.markA:=-1;
    s.markB:=-1;
    s.selected:=FALSE;
    s.mode:=normal;
    s.string:=NIL;
    s.textAlign:=leftAligned;
    s.font:=D.normalFont;
    s.readOnly:=FALSE;
  END Init;

  PROCEDURE (s : String) SetFont*(font : D.Font);

    (**
      Sets the font to be used by the string object. By default
      @otype{String} will use @ovar{D.normalFont}.
    *)

  BEGIN
    IF font#NIL THEN
      s.font:=font;

      IF s.visible THEN
        s.Redraw;
      END;
    END;
  END SetFont;

  PROCEDURE (s : String) SetMode*(mode : LONGINT);

  BEGIN
    s.mode:=mode;
  END SetMode;

  PROCEDURE (s : String) SetModel*(model : O.Model);

  BEGIN
    IF s.string#NIL THEN
      s.UnattachModel(s.string);
    END;
    IF (model#NIL) & (model IS V.ValueModel) THEN
      s.string:=model(V.ValueModel);
      s.offset:=0;
      s.AttachModel(model);
    ELSE
      s.string:=NIL;
    END;
  END SetModel;

  PROCEDURE (s : String) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN s.string=m;
  END ModelAccepted;

  PROCEDURE (s : String) SetStringWidth*(width,visWidth : LONGINT);

    (**
      Set the maximum text with of string gadget and the visible with
      of the string gadget in letters.

      NOTE
      The with in letters will be estimated and thus the real width
      may differ from the given one.
    *)

  VAR
    help : STRING;

  BEGIN
    IF (s.string#NIL) & ~s.string.IsNull() THEN
      help:=s.string.GetString();
      IF help.length>width THEN
        help:=help.Substring(0,width);
        s.string.SetString(help);
      END;
    END;
    s.textWidth:=width;
    s.visWidth:=visWidth;
  END SetStringWidth;

  PROCEDURE (s : String) SetStringAlignment*(a:Alignment);

    (**
      Set the aligment for the text within the string object.
    *)

  BEGIN
    s.textAlign:=a;
  END SetStringAlignment;

  PROCEDURE (s : String) SetReadOnly*(readOnly : BOOLEAN);

  BEGIN
    s.readOnly:=readOnly;
    s.Redraw;
  END SetReadOnly;

  PROCEDURE (s : String) CalcSize*;

  VAR
    font : D.Font;

  BEGIN
    font:=s.font;

    s.width:=s.visWidth*D.display.spaceWidth;
    s.height:=font.height;

    s.minWidth:=s.width;
    s.minHeight:=s.height;

    s.CalcSize^;
  END CalcSize;

  PROCEDURE (s : String) ConvertToPassword(text : STRING):STRING;

  VAR
    x   : LONGINT;
    tmp : POINTER TO ARRAY OF LONGCHAR;

  BEGIN
    NEW(tmp,text.length+1);
    x:=0;
    WHILE x<text.length DO
      tmp[x]:=passwordChar(*02022X*);
      INC(x);
    END;
    tmp[text.length]:=0X;

    RETURN Object.NewUTF16(tmp^);
  END ConvertToPassword;

  PROCEDURE (s : String) GetCursorPos(x : LONGINT):LONGINT;

    (**
      Sets the cursor under the mouse.
    *)

  VAR
    y,
    widthA,
    widthB,
    length  : LONGINT;
    help    : STRING;
    str16   : Object.String16;
    txt16   : Object.CharsUTF16;
    extent  : D.FontExtentDesc;
    found   : BOOLEAN;
    font    : D.Font;

  BEGIN
    font:=s.font;

    IF x<s.textPos THEN
      RETURN 0;
    END;
    DEC(x,s.textPos);

    IF s.string.IsNull() THEN
      RETURN 0;
    END;

    help:=s.string.GetString();
    length:=help.length;

    IF help=NIL THEN
      RETURN 0;
    END;

    IF s.mode=password THEN
      help:=s.ConvertToPassword(help);
    END;

    str16:=help.ToString16();
    txt16:=str16.CharsUTF16();

    found:=FALSE;
    y:=0;
    WHILE ~found & (y<length) DO (* TODO: Optimize *)
      font.LongTextExtent(txt16^,y,{},extent);
      widthA:=extent.width;
      font.LongTextExtent(txt16^,y+1,{},extent);
      widthB:=extent.width;
      IF (widthA<=x) & (x<=widthB) THEN
        IF (x-widthA)>(widthB-widthA) DIV 2 THEN
          INC(y);
        END;
        found:=TRUE;
      ELSE
        INC(y);
      END;
    END;

    RETURN y;
  END GetCursorPos;

  PROCEDURE (s : String) Selected():BOOLEAN;

  BEGIN
    RETURN s.markA>=0;
  END Selected;

  PROCEDURE (s : String) SetSelection(a,b : LONGINT);

  BEGIN
    IF D.display.RegisterSelection(s,s.GetWindow()) THEN
      s.markA:=a;
      s.markB:=b;
    END;
  END SetSelection;

  PROCEDURE (s : String) ClearSelection;

  BEGIN
    IF s.Selected() THEN
      s.markA:=-1;
      s.markB:=-1;
      D.display.CancelSelection;
    END;
  END ClearSelection;

  PROCEDURE (s : String) SelectAll;

  VAR
    length : LONGINT;

  BEGIN
    IF s.Selected() THEN
      s.ClearSelection;
    END;

    IF (s.string#NIL) THEN
      length:=s.string.GetTextLength();
      IF length>0 THEN
        s.SetSelection(0,length);
        s.cursor:=0;
      END;
    END;
  END SelectAll;

  PROCEDURE (s : String) DeleteSelection;

  VAR
    a,b : LONGINT;

  BEGIN
    IF s.Selected() THEN
      a:=s.markA;
      b:=s.markB;
      s.ClearSelection;
      s.string.Delete(a,b-a);
    END;
  END DeleteSelection;

  (* ---- Drag and drop stuff *)

  PROCEDURE (s : String) GetDnDObject*(x,y : LONGINT; drag : BOOLEAN):G.Object;

  BEGIN
    IF s.visible & s.PointIsIn(x,y) & (s.string#NIL) & ~s.string.IsNull()
    & (s.mode#password)
    & (drag OR ~s.disabled) THEN
      (* we can drag and drop *)
      RETURN s;
    ELSE
      RETURN NIL;
    END;
  END GetDnDObject;

  PROCEDURE (s : String) GetDragInfo*(VAR dragInfo : DD.DnDDataInfo);

  BEGIN
    dragInfo.AddDataType(DD.text,DD.none,{DD.copy,DD.move,DD.insert},DD.copy);
  END GetDragInfo;

  PROCEDURE (s : String) GetDropDataType*(VAR dragInfo : DD.DnDDataInfo;
                                          VAR group, type, action : LONGINT):BOOLEAN;

  BEGIN
    group:=DD.text;
    type:=DD.joker;
    RETURN dragInfo.FindDataType(group,type,action);
  END GetDropDataType;

  PROCEDURE (s : String) GetDragData*(group, type, action : LONGINT):DD.DnDData;

  VAR
    data : DD.DnDStringData;
    text : STRING;

  BEGIN
    IF (group=DD.text) & (s.string#NIL) & ~s.string.IsNull() & (s.mode#password) THEN
      NEW(data);
      IF s.Selected() THEN
        text:=s.string.GetString();
        text:=text.Substring(s.markA,s.markB);
        data.string:=text;

        IF action=DD.move THEN
          s.string.Delete(SHORT(s.markA),SHORT(s.markB-s.markA));
        END;
      ELSE
        data.string:=s.string.GetString();
        IF action=DD.move THEN
          s.string.SetString("");
        END;
      END;
      RETURN data;
    ELSE
      RETURN NIL;
    END;
  END GetDragData;

  PROCEDURE (s : String) HandleDrop*(data : DD.DnDData; action : LONGINT):BOOLEAN;

  VAR
    x    : LONGINT;
    text : STRING;

  BEGIN
    WITH data : DD.DnDStringData DO

      text:=data.string;
      x:=0;
      WHILE x<data.string.length DO
        IF (ORD(data.string.CharAt(x))<256) &
          CC.IsControl(CHR(ORD(data.string.CharAt(x)))) THEN
          RETURN FALSE;
        END;
        INC(x);
      END;

      (*
        TODO: Exchange selection if selection exists
      *)

      IF s.string.GetTextLength()+text.length>s.textWidth THEN
        RETURN FALSE;
      END;

      CASE action OF
        DD.insert:
        IF s.Selected() THEN
          s.DeleteSelection;
        END;
        INC(s.cursor,text.length);
        s.string.Insert(text,s.cursor-text.length);
      | DD.copy,
        DD.move:
          s.string.SetString(text);
      ELSE
        RETURN FALSE;
      END;
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END HandleDrop;

  PROCEDURE (s : String) DrawText;

  VAR
    x,
    width,
    cursorPos,
    markA,
    markB,
    offset,
    space     : LONGINT;
    extent1,
    extent2   : D.FontExtentDesc;
    string,
    help,
    help2    : STRING;
    font      : D.Font;
    draw      : D.DrawInfo;

  BEGIN
    font:=s.font;
    draw:=s.GetDrawInfo();

    offset:=s.y+(s.height-font.height) DIV 2;

    IF D.display.displayType=D.displayTypeTextual THEN
      space:=0;
    ELSE
      space:=D.display.spaceWidth DIV 2
    END;
    (* x = left starting position of string, y = top position *)
    x:=s.x+space;
    width:=s.width-2*space;

    (* Draw background *)
    IF s.disabled & ~s.prefs(Prefs).gridDisable THEN
      draw.PushForeground(D.backgroundColor);
      draw.FillRectangle(s.x,s.y,s.width,s.height);
      draw.PopForeground;
    ELSE
      s.DrawBackground(s.x,s.y,s.width,s.height);
    END;

    (* Draw optional baseline *)
    IF s.prefs(Prefs).baseline THEN
      IF s.disabled THEN
        draw.PushForeground(D.disabledColor);
      ELSE
        draw.PushForeground(D.textColor);
      END;

      draw.DrawLine(x,offset+font.ascent-1,x+width-1,s.y+font.ascent-1);

      draw.PopForeground;
    END;

    (* prepare to be printed string *)
    IF s.string#NIL THEN
      IF s.string.IsNull() THEN
        string:=Object.NewLatin1("");
      ELSE
        IF s.mode=password THEN
          string:=s.ConvertToPassword(s.string.GetString());
        ELSE
          string:=s.string.GetString();
        END;
      END;
    ELSE
      string:=NIL;
    END;

    IF string#NIL THEN
      draw.InstallClip(s.x,s.y,s.width,s.height);

      IF s.cursor>string.length THEN
        s.cursor:=string.length;
      END;

      (* Calculate starting pos depending on alignment *)
      IF s.textAlign=leftAligned THEN
        s.textPos:=x;
      ELSIF s.textAlign=rightAligned THEN
        s.textPos:=x+width-font.StrWidth(string,{});
      ELSE (* center *)
        s.textPos:=x+(width-font.StrWidth(string,{})) DIV 2;
      END;

      (* Calculate bound of first letter of help^ *)
      help2:=string.Substring(0,1);
      font.StrExtent(help2,{},extent2);

      (*
        correct starting position of string by left hand
        space of starting character
       *)
      DEC(s.textPos,extent2.lbearing);

      cursorPos:=s.textPos;

      IF s.cursor>0 THEN
        (* Copy string from 0 before cursor to help *)
        help:=string.Substring(0,s.cursor);

        (* calculate bounds of help^ *)
        font.StrExtent(help,{},extent1);

        (* Calculate cursor position *)
        INC(cursorPos,extent1.rbearing);
      END;

      (* correct cursor position by first character of 2nd string *)
      IF (s.cursor>0) & (s.cursor<string.length) THEN
        help2:=string.Substring(s.cursor,s.cursor+1);
        font.StrExtent(help2,{},extent2);
        INC(cursorPos,extent2.lbearing);
      END;

      (* Make cursor visible in gadget by correcting starting offset *)
      IF cursorPos-s.offset>x+width-2 THEN (* cursor is out on the right *)
        INC(s.offset,cursorPos-s.offset-(x+width-2));
      ELSIF cursorPos-s.offset<x THEN (* cursor is out on the left *)
        DEC(s.offset,x-cursorPos+s.offset);
      END;

      (* correct textstart and cursorpos, too *)
      DEC(cursorPos,s.offset);

      IF s.Selected() THEN (* there exists a selection *)
        markA:=s.textPos;

        IF s.markA>0 THEN
          (* Copy string from 0 before cursor to help *)
          help:=string.Substring(0,s.markA);

          (* calculate bounds of help^ *)
          font.StrExtent(help,{},extent1);

          (* Calculate cursor position *)
          INC(markA,extent1.rbearing);
        END;

        (* correct cursor position by first character of 2nd string *)
        IF (s.markA>0) & (s.markA<string.length) THEN
          help2:=string.Substring(s.markA,s.markA+1);
          font.StrExtent(help2,{},extent2);
          INC(markA,extent2.lbearing);
        END;

        (* Copy string from 0 before cursor to help *)
        help:=string.Substring(0,s.markB);

        (* calculate bounds of help^ *)
        font.StrExtent(help,{},extent1);

        (* Calculate cursor position *)
        markB:=s.textPos+extent1.rbearing;

        (* correct cursor position by first character of 2nd string *)
        IF s.markB<string.length THEN
          help2:=string.Substring(s.markB,s.markB+1);
          font.StrExtent(help2,{},extent2);
          INC(markB,extent2.lbearing);
        END;

        DEC(markA,s.offset);
        DEC(markB,s.offset);

        s.prefs(Prefs).selection.DrawRelObject(draw,s,markA,s.y,markB-markA+1,s.height);
      END;

      DEC(s.textPos,s.offset);

      (* Draw the string *)
      draw.PushFont(s.font,{});
      IF s.disabled & ~s.prefs(Prefs).gridDisable THEN
        draw.PushForeground(D.disabledColor);
      ELSIF s.Selected() THEN
        IF D.display.displayType=D.displayTypeTextual THEN
          draw.PushForeground(D.fillTextColor);
        ELSE
          draw.PushForeground(D.textColor);
        END;
      ELSE
        draw.PushForeground(D.textColor);
      END;

      draw.DrawStr(s.textPos,offset+font.ascent,string);

      draw.PopForeground;
      draw.PopFont;

      (* Drawing the cursor *)
      IF s.selected THEN
        IF D.display.displayType=D.displayTypeTextual THEN
          draw.InvertRectangle(cursorPos,offset,1,s.y+font.height-1-offset+1);
        ELSE
          draw.PushForeground(D.textColor);
          draw.FillRectangle(cursorPos,offset,1,s.y+font.height-1-offset+1);
          draw.PopForeground;
        END;
      END;

      IF s.disabled & s.prefs(Prefs).gridDisable THEN
        s.DrawDisabled;
      END;

      draw.FreeLastClip;
    END;
  END DrawText;

  PROCEDURE (s : String) SetCursorPos*(pos : LONGINT);

  VAR
    string : STRING;

  BEGIN
    string:=s.string.GetString();
    ASSERT(pos<=string.length);

    IF pos<0 THEN
      pos:=string.length;
    END;

    s.cursor:=pos;

    IF s.visible THEN
      s.DrawText;
    END;
  END SetCursorPos;

  PROCEDURE (s : String) Deselect*;

    (**
      Clears the current selection.
    *)

  BEGIN
    s.ClearSelection;
    IF s.visible THEN
      s.DrawText;
    END;
  END Deselect;

  PROCEDURE (s : String) HandleMouseEvent*(event : E.MouseEvent;
                                           VAR grab : G.Object):BOOLEAN;

  VAR
    help   : LONGINT;
    window : D.Window;

  BEGIN
    IF ~s.visible OR (s.string=NIL) THEN
      RETURN FALSE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & s.PointIsIn(event.x,event.y)
        & (event.button=E.button1) THEN
        window:=s.GetWindow();
        IF window.IsDoubleClicked() THEN
          s.SelectAll;
          s.DrawText;
        ELSE
          s.selected:=TRUE;
          s.cursor:=s.GetCursorPos(event.x);
          s.ClearSelection;
          s.DrawText;

          grab:=s;
        END;
        RETURN TRUE;
      ELSIF (event.type=E.mouseDown) & (event.button=E.dragDropButton)
      & s.PointIsIn(event.x,event.y) THEN
        s.selected:=TRUE;
        s.cursor:=s.GetCursorPos(event.x);
        s.ClearSelection;
        s.DrawText;
        IF ~D.display.QuerySelection(s.GetWindow(),s,D.text) THEN END;

        grab:=s;
        RETURN TRUE;
      ELSIF (grab=s) & (event.button=E.button1) & (event.type=E.mouseUp) THEN
        help:=s.GetCursorPos(event.x);
        IF help>s.cursor THEN
          s.SetSelection(s.cursor,help);
          s.cursor:=help;
          s.DrawText;
        ELSIF help<s.cursor THEN
          s.SetSelection(help,s.cursor);
          s.DrawText;
        END;

        grab:=NIL;
        RETURN TRUE;
      ELSIF (grab=s) & (event.type=E.mouseUp) & (event.button=E.dragDropButton) THEN
        IF ~D.display.QuerySelection(s.GetWindow(),s,D.text) THEN
        END;

        grab:=NIL;
        RETURN TRUE;
      END;
    | event : E.MotionEvent DO
      IF (grab=s) & (event.qualifier={E.button1}) THEN
        help:=s.GetCursorPos(event.x);
        IF help>s.cursor THEN
          s.SetSelection(s.cursor,help);
        ELSIF help<s.cursor THEN
          s.SetSelection(help,s.cursor);
        ELSE
          s.ClearSelection;
        END;
        s.DrawText;

        RETURN TRUE;
      END;
    ELSE
    END;
    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (s : String) DrawFocus*;

  BEGIN
    s.DrawText;
  END DrawFocus;

  PROCEDURE (s : String) HideFocus*;

  BEGIN
    s.DrawText;
  END HideFocus;

  PROCEDURE (s : String) RecatchedFocus*;

  BEGIN
    s.selected:=TRUE;

    s.RecatchedFocus^;
  END RecatchedFocus;

  PROCEDURE (s : String) CatchedFocus*;

  BEGIN
    IF ~s.selected THEN
      s.SelectAll();
    END;

    s.selected:=TRUE;

    s.CatchedFocus^;
  END CatchedFocus;

  PROCEDURE (s : String) LostFocus*;

  BEGIN
    s.selected:=FALSE;
    s.ClearSelection;
    s.LostFocus^;
  END LostFocus;

  PROCEDURE (s : String) ActionCut*;

  VAR
    text : STRING;

  BEGIN
    IF (s.string#NIL) & s.Selected() THEN
      text:=s.string.GetString();
      text:=text.Substring(s.markA,s.markB);
      IF ~D.display.SetClipboard(text) THEN
        D.display.Beep;
      ELSE
        s.DeleteSelection;
        s.DrawText;
      END;
    ELSE
      D.display.Beep;
    END;
  END ActionCut;

  PROCEDURE (s : String) ActionCopy*;

  VAR
    text : STRING;

  BEGIN
    IF (s.string#NIL) & s.Selected() THEN
      text:=s.string.GetString();
      text:=text.Substring(s.markA,s.markB);
      IF ~D.display.SetClipboard(text) THEN
        D.display.Beep;
      END;
    ELSE
      D.display.Beep;
    END;
  END ActionCopy;

  PROCEDURE (s : String) ActionPaste*;

  BEGIN
    IF ~D.display.GetClipboard(s) THEN
      D.display.Beep;
    END;
  END ActionPaste;

  PROCEDURE (s : String) ActionSelectAll*;

  BEGIN
    s.SelectAll;
    s.DrawText;
  END ActionSelectAll;

  PROCEDURE (s : String) ActionReturn*():BOOLEAN;

  VAR
    entered : EnteredMsg;

  BEGIN
    IF s.HasHandler(enteredMsg) THEN
      IF ~s.HasFocus() THEN
        s.selected:=FALSE;
        s.DrawText;
        (*ELSE
          s.LeaveFocus;*)
      END;

      NEW(entered);
      s.Send(entered,enteredMsg);
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END ActionReturn;

  PROCEDURE (s : String) ActionEscape*():BOOLEAN;

  VAR
    escape : EscapeMsg;

  BEGIN
    IF s.HasHandler(escapeMsg) THEN
      IF ~s.HasFocus() THEN
        s.selected:=FALSE;
        s.DrawText;
      END;

      NEW(escape);
      s.Send(escape,escapeMsg);
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END ActionEscape;

  PROCEDURE (s : String) ActionSelectLeft*;

  BEGIN
    IF s.cursor>0 THEN
      IF ~s.Selected() THEN
        DEC(s.cursor);
        s.SetSelection(s.cursor,s.cursor+1);
        s.DrawText;
      ELSIF (s.markA+1=s.markB) & (s.markB=s.cursor) THEN
        s.ClearSelection;
        DEC(s.cursor);
        s.DrawText;
      ELSIF s.cursor=s.markA THEN
        DEC(s.cursor);
        s.SetSelection(s.cursor,s.markB);
        s.DrawText;
      ELSIF s.cursor=s.markB THEN
        DEC(s.cursor);
        s.SetSelection(s.markA,s.cursor);
        s.DrawText;
      END;
    END;
  END ActionSelectLeft;

  PROCEDURE (s : String) ActionSelectRight*;

  BEGIN
    IF s.cursor<s.string.GetTextLength() THEN
      IF ~s.Selected() THEN
        INC(s.cursor);
        s.SetSelection(s.cursor-1,s.cursor);
        s.DrawText;
      ELSIF (s.markA+1=s.markB) & (s.markA=s.cursor) THEN
        s.ClearSelection;
        INC(s.cursor);
        s.DrawText;
      ELSIF s.cursor=s.markB THEN
        INC(s.cursor);
        s.SetSelection(s.markA,s.cursor);
        s.DrawText;
      ELSIF s.cursor=s.markA THEN
        INC(s.cursor);
        s.SetSelection(s.cursor,s.markB);
        s.DrawText;
      END;
    END;
  END ActionSelectRight;

  PROCEDURE (s : String) ActionSelectStart*;

  BEGIN
    IF s.Selected() THEN
      IF s.cursor=s.markA THEN
        s.SetSelection(0,s.markB);
      ELSE
        s.SetSelection(0,s.markA);
      END;
    ELSE
      s.SetSelection(0,s.cursor);
    END;
    s.cursor:=0;
    s.DrawText;
  END ActionSelectStart;

  PROCEDURE (s : String) ActionSelectEnd*;

  BEGIN
    IF s.Selected() THEN
      IF s.cursor=s.markA THEN
        s.SetSelection(s.markB,s.string.GetTextLength());
      ELSE
        s.SetSelection(s.markA,s.string.GetTextLength());
      END;
    ELSE
      s.SetSelection(s.cursor,s.string.GetTextLength());
    END;
    s.cursor:=s.string.GetTextLength();
    s.DrawText;
  END ActionSelectEnd;

  PROCEDURE (s : String) ActionCursorLeft*;

  BEGIN
    s.ClearSelection;
    IF s.cursor>0 THEN
      DEC(s.cursor);
    END;
    s.DrawText;
  END ActionCursorLeft;

  PROCEDURE (s : String) ActionCursorRight*;

  BEGIN
    s.ClearSelection;
    IF s.cursor<s.string.GetTextLength() THEN
      INC(s.cursor);
    END;
    s.DrawText;
  END ActionCursorRight;

  PROCEDURE (s : String) ActionCursorStart*;

  BEGIN
    s.ClearSelection;
    s.cursor:=0;
    s.DrawText;
  END ActionCursorStart;

  PROCEDURE (s : String) ActionCursorEnd*;

  BEGIN
    s.ClearSelection;
    s.cursor:=s.string.GetTextLength();
    s.DrawText;
  END ActionCursorEnd;

  PROCEDURE (s : String) ActionBackspace*;

  BEGIN
    IF ~s.disabled & ~ s.readOnly THEN
      IF s.Selected() THEN
        s.cursor:=s.markA;
        s.DeleteSelection;
      ELSIF s.cursor>0 THEN
        s.ClearSelection;
        DEC(s.cursor);
        s.string.Delete(s.cursor,1);
      END;
    END;
  END ActionBackspace;

  PROCEDURE (s : String) ActionDelete*;

  BEGIN
    IF ~s.disabled & ~s.readOnly THEN
      IF s.Selected() THEN
        s.cursor:=s.markA;
        s.DeleteSelection;
      ELSIF s.cursor<s.string.GetTextLength() THEN
        s.ClearSelection;
        s.string.Delete(s.cursor,1);
      END;
    END;
  END ActionDelete;

  PROCEDURE (s : String) HandleKeys(event :  E.KeyEvent):BOOLEAN;

  VAR
    ext : ExtNavMsg;
    tmp : ARRAY 1024 OF CHAR;

  BEGIN
    IF s.string=NIL THEN
      RETURN FALSE;
    END;

    CASE event.key OF
      E.up,
      E.down:
      NEW(ext);
      ext.event:=event;
      s.Send(ext,extNavMsg);
      RETURN TRUE;
    ELSE
      IF ~s.disabled & ~s.readOnly & (s.string#NIL) THEN
        event.GetName(tmp);
        EXCL(event.qualifier,E.qShiftLeft);
        EXCL(event.qualifier,E.qShiftRight);
        IF (event.textLength>0) & ~CC.IsControl(event.text[0]) &
          ~((tmp=event.text^) & (event.qualifier#{})) THEN
          IF s.string.GetTextLength()+event.textLength<=s.textWidth THEN
            s.DeleteSelection;
            INC(s.cursor,event.textLength);
            s.string.Insert(Object.NewLatin1(event.text^),
                            s.cursor-event.textLength);
            RETURN TRUE;
          ELSE
            D.display.Beep;
            RETURN FALSE;
          END;
        END;
      END;
    END;
    RETURN FALSE;
  END HandleKeys;

  PROCEDURE (s : String) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  BEGIN
    IF s.HandleKeyEvent^(event) THEN
      RETURN TRUE;
    END;

    IF event.type=E.keyDown THEN
      RETURN s.HandleKeys(event);
    ELSE
      RETURN FALSE;
    END;
  END HandleKeyEvent;

  PROCEDURE (s : String) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    s.DrawText;
  END Draw;

  PROCEDURE (s : String) Hide*;

  BEGIN
    IF s.visible THEN
      s.ClearSelection;
      s.Hide^;
    END;
  END Hide;

  PROCEDURE (s : String) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF model=s.string THEN
      IF s.Selected() THEN
        s.SelectAll;
      END;
      IF s.visible THEN
        s.DrawText;
      END;
    END;
  END Resync;

  PROCEDURE CreateString*():String;

    (**
      Creates a new instance of @otype{String}.
    *)

  VAR
    string : String;

  BEGIN
    NEW(string);
    string.Init;

    RETURN string;
  END CreateString;

  PROCEDURE (c : Controller) Init*;

  BEGIN
    c.Init^;

    c.RegisterKeyAction("C+x",actionCut);
    c.RegisterKeyAction("S+Delete",actionCut);

    c.RegisterKeyAction("C+c",actionCopy);
    c.RegisterKeyAction("C+Insert",actionCopy);

    c.RegisterKeyAction("C+v",actionPaste);
    c.RegisterKeyAction("S+Insert",actionPaste);

    c.RegisterKeyAction("C+a",actionSelectAll);
    c.RegisterKeyAction("Return",actionReturn);
    c.RegisterKeyAction("Escape",actionEscape);

    c.RegisterKeyAction("S+Left",actionSelectLeft);
    c.RegisterKeyAction("S+Right",actionSelectRight);
    c.RegisterKeyAction("S+Home",actionSelectStart);
    c.RegisterKeyAction("S+End",actionSelectEnd);

    c.RegisterKeyAction("Left",actionCursorLeft);
    c.RegisterKeyAction("Right",actionCursorRight);
    c.RegisterKeyAction("Home",actionCursorStart);
    c.RegisterKeyAction("End",actionCursorEnd);

    c.RegisterKeyAction("BackSpace",actionBackspace);
    c.RegisterKeyAction("Delete",actionDelete);

  END Init;

  PROCEDURE (c : Controller) DoAction*(object : G.Object; action : LONGINT):BOOLEAN;

  BEGIN
    WITH object : String DO
      CASE action OF
        actionCut:
        object.ActionCut;
      | actionCopy:
        object.ActionCopy;
      | actionPaste:
        object.ActionPaste;
      | actionSelectAll:
        object.ActionSelectAll;
      | actionReturn:
        IF ~object.ActionReturn() THEN
          RETURN FALSE;
        END;
      | actionEscape:
        IF ~object.ActionEscape() THEN
          RETURN FALSE;
        END;
      | actionSelectLeft:
        object.ActionSelectLeft;
      | actionCursorLeft:
        object.ActionCursorLeft;
      | actionSelectRight:
        object.ActionSelectRight;
      | actionCursorRight:
        object.ActionCursorRight;
      | actionSelectStart:
        object.ActionSelectStart;
      | actionCursorStart:
        object.ActionCursorStart;
      | actionSelectEnd:
        object.ActionSelectEnd;
      | actionCursorEnd:
        object.ActionCursorEnd;
      | actionBackspace:
        object.ActionBackspace;
      | actionDelete:
        object.ActionDelete;
      END;
    END;
    RETURN TRUE;
  END DoAction;

BEGIN
  NEW(prefs);
  prefs.Init;

  NEW(controller);
  controller.Init;
END VO:String.
