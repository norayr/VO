MODULE VO:Combo [OOC_EXTENSIONS];

  (**
    Implements @otype{Combo}.
  *)

  (*
    Implements a combobox gadget.
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

IMPORT BG := VO:Base:Background,
       D  := VO:Base:Display,
       E  := VO:Base:Event,
       F  := VO:Base:Frame,
       IB := VO:Base:Image,
       O  := VO:Base:Object,
       U  := VO:Base:Util,
       VB := VO:Base:VecImage,
       Z  := VO:Base:Size,

       SM := VO:Model:Selection,
       TM := VO:Model:Table,
       VM := VO:Model:Value,

       G  := VO:Object,
       I  := VO:Image,
       S  := VO:String,
       T  := VO:Table,
       TV := VO:TableView,
       TX := VO:Text,
       W  := VO:Window,
       WG := VO:WindowGroup,

             Object;

CONST
  okId     = 0;
  cancelId = 1;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 interSpace*,
                 hSpace*,
                 vSpace*     : Z.SizeDesc;
                 image*      : IB.Image;
                 imageRight* : BOOLEAN;
                 popupFrame* : F.Frame;
               END;

  Combo*     = POINTER TO ComboDesc;

  Table      = POINTER TO TableDesc;
  TableDesc  = RECORD (TV.TableDesc)
                 (**
                   Overload table for handling shortcuts.
                 *)
                 cancel : BOOLEAN;
               END;

  Popup      = POINTER TO PopupDesc;
  PopupDesc  = RECORD (W.WindowDesc)
                 (**
                   The popup window.
                 *)
                 tableModel : TM.TableModel;
                 table      : T.Table;
                 combo      : Combo;
               END;

  ComboDesc* = RECORD [ABSTRACT] (G.GadgetDesc)
                 (**
                   Abstract base class for combo box like objects.
                   A combo box is a object that shows one currently selected
                   value (which depending on implementation might even be directly
                   editable) and offers a popup window to offers a list
                   of alternative values.

                   The baseclass offers a framework for such functionality.
                   It defines the needed models, the necessary drawing
                   methods, the handling for opening and closing the
                   popup window, callbacks for setting the new value on
                   selection etc..
                 *)
                 image       : I.Image;

                 value-      : G.Object; (**
                                           The object used to display the current
                                           value. This might even allow implace
                                           editing like for example @otype{S.String}.
                                          *)
                 tableModel- : TM.TableModel; (** The table model used for the popup menu *)
                 model       : VM.ValueModel; (** The model for the current value *)
                 popup       : Popup;
               END;

  TextCombo*     = POINTER TO TextComboDesc;
  TextComboDesc* = RECORD (ComboDesc)
                     (**
                       A concrete implementation of @otype{ComboDesc} displaying
                       the current value using a read only text.
                     *)
                   END;

  StringCombo*     = POINTER TO StringComboDesc;
  StringComboDesc* = RECORD (ComboDesc)
                     (**
                       A concrete implementation of @otype{ComboDesc} displaying
                       the current value using a read and writable instance
                       of @otype{S.String}.
                     *)
                     END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.backgroundColorIndex));

    p.hSpace.Init;
    p.vSpace.Init;
    p.interSpace.Init;
    p.hSpace.SetSize(Z.softUnitP,50);
    p.vSpace.SetSize(Z.softUnitP,50);
    p.interSpace.SetSize(Z.softUnitP,50);

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.textButton);
      p.image:=IB.CreateVecImage(VB.simplePopup);
    ELSE
      p.frame:=F.CreateFrame(F.w95BO);
      p.image:=IB.CreateVecImage(VB.combo);
    END;
    p.imageRight:=TRUE;
    p.popupFrame:=F.CreateFrame(F.none)(*double3DOut*);
  END Initialize;

  PROCEDURE (t : Table) Init*;

  BEGIN
    t.Init^;
    t.cancel:=FALSE;
  END Init;

  PROCEDURE (t : Table) Receive*(message : O.Message);

  VAR
    window : D.Window;

  BEGIN
    WITH message : W.ShortcutMsg DO
      IF message.state=W.shortcutReleased THEN
        IF (message.id=okId) OR (message.id=cancelId) THEN
          t.cancel:=message.id=cancelId;
          window:=t.GetWindow();
          window.Exit;
        END;
      END;
    ELSE
      t.Receive^(message);
    END;
  END Receive;

  PROCEDURE (c : Combo) Init*;

  BEGIN
    c.Init^;

    c.SetFlags({G.canFocus});
    c.RemoveFlags({G.stdFocus});

    c.SetPrefs(prefs);

    c.image:=I.CreateImage();
    c.image.SetParent(c);
    c.image.SetBackgroundObject(NIL);
    c.image.SetObjectFrame(prefs.popupFrame);
    c.image.SetFlags({G.horizontalFlex,G.verticalFlex});

    c.value:=NIL;
    c.tableModel:=NIL;
    c.model:=NIL;
    c.popup:=NIL;
  END Init;

  PROCEDURE (c : Combo) SetTableModel*(model : TM.TableModel);

    (**
      Call this method to assign the table model that will be used to display
      all possible values in the pop window.
    *)

  BEGIN
    c.tableModel:=model;
    c.tableModel.SetSelection(SM.CreateSingleLine());
  END SetTableModel;

  PROCEDURE (c : Combo) SetValueObject*(value : G.Object);

    (**
      Set the object that will be used to display the currently selected
      value. Normally you do not call this method because a concrete
      implementation of @otype{Combo} will do that for you.
    *)

  BEGIN
    c.value:=value;
    c.value.SetParent(c);
    IF ~(c.value IS G.Gadget) THEN
      c.value.SetBackgroundObject(NIL);
    END;
  END SetValueObject;

(*
  PROCEDURE (g : Combo) GetDnDObject*(x,y : LONGINT; drag : BOOLEAN):G.Object;

  VAR
    object,
    return  : G.Object;

  BEGIN
    object:=g.list;
    WHILE object#NIL DO
      return:=object.GetDnDObject(x,y,drag);
      IF return#NIL THEN
        RETURN return;
      END;
      object:=object.next;
    END;
    RETURN g.GetDnDObject^(x,y,drag);
  END GetDnDObject;
*)

  PROCEDURE (c : Combo) CopySelection*(row : LONGINT);

    (**
      This method will be called if a new value was selected from the popup
      window. The baseclass will try its best to assign a sensefull value to
      the model assigned to @otype{Combo}. If the model is numemric it will
      assign the index of the current selcted (starting with 0), if its of type
      text, if will assign the text of the current selected (if the table model
      has more than one coloum if will iterate from left to right until some
      valid text will be returned).

      If you want some other (or more) behaviour, overwrite this method
      and call baseclass if necessary.
    *)

  VAR
    text   : U.Text;
    string : STRING;
    x      : LONGINT;

  BEGIN
    IF c.model#NIL THEN
      IF (c.model.type=VM.longint)
      OR (c.model.type=VM.integer)
      OR (c.model.type=VM.shortint) THEN
        c.model.SetLongint(row-1);
      ELSIF c.model.type=VM.text THEN
        text:=NIL;
        string:=NIL;
        x:=1;
        WHILE (text=NIL) & (string=NIL) & (x<=c.tableModel.GetColumns()) DO
          string:=c.tableModel.GetString(x,row);
          IF string=NIL THEN
            text:=c.tableModel.GetText(x,row);
          END;
          INC(x);
        END;

        IF string#NIL THEN
          c.model.SetString(string);
        ELSIF text#NIL THEN
          c.model.SetText(text);
        ELSE
          c.model.SetString("");
        END;
      END;
    END;

    IF (c.tableModel#NIL) & (c.tableModel.GetRows()>0) THEN
      IF row>0 THEN
        c.tableModel.selection.SelectCell(1,row);
      ELSE
        c.tableModel.selection.Clear;
      END;
    END;
  END CopySelection;

  PROCEDURE (c : Combo) SetModel*(model : O.Model);

  BEGIN
    IF c.model#NIL THEN
      c.UnattachModel(c.model);
    END;
    IF (model#NIL) & (model IS VM.ValueModel) THEN
      c.model:=model(VM.ValueModel);
      c.AttachModel(c.model);
    ELSE
      c.model:=NIL;
    END;
  END SetModel;

  PROCEDURE (c : Combo) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=c.model
  END ModelAccepted;

  PROCEDURE (c : Combo) CalcSize*;

  BEGIN
    c.value.SetFlags({G.horizontalFlex,G.verticalFlex});

    (* Delegate Focus visualisation to value class, if possible *)
    IF c.MayFocus() & ~c.value.StdFocus() THEN
      c.RemoveFlags({G.stdFocus});
      c.value.RequestFocus();
    END;

    c.value.CalcSize;

    c.image.SetImage(c.prefs(Prefs).image);
    c.image.CalcSize;

    c.minHeight:=U.MaxLong(c.value.oMinHeight,c.image.oMinHeight)+
                 c.prefs(Prefs).vSpace.GetSize();
    c.height:=U.MaxLong(c.value.oHeight,c.image.oHeight)+
              c.prefs(Prefs).vSpace.GetSize();

    (* A little trick to make cycle-Button a little bit nicer *)
    c.image.Resize(c.minHeight,c.minHeight);

    c.minWidth:=c.value.oMinWidth+c.prefs(Prefs).interSpace.GetSize()+
                c.image.oWidth+c.prefs(Prefs).hSpace.GetSize()*2;
    c.width:=c.value.oWidth+c.prefs(Prefs).interSpace.GetSize()+
             c.image.oWidth+c.prefs(Prefs).hSpace.GetSize()*2;

    c.CalcSize^;
  END CalcSize;

  PROCEDURE (c : Combo) InitTable*(table : T.Table);

    (**
      Overload this method if you want some inital initialisation of the table
      object used for the popup window. The baseclass is empty.

      Normally this will be done by a concrete implementation of @otype{Combo}.
    *)

  BEGIN
    (* no code *)
  END InitTable;

  PROCEDURE (p : Popup) PreInit*;

  VAR
    closeMsg : W.Msg2Exit;
    wGroup   : WG.WindowGroup;
    table    : Table;

  BEGIN
    wGroup:=WG.CreateWindowGroup();
    wGroup.SetFlags({G.horizontalFlex(*,G.verticalFlex*)});
    NEW(table);
    table.Init;
    p.RegisterCommitShortcut(table,okId,NIL);
    p.RegisterCancelShortcut(table,cancelId,NIL);

    p.table:=T.CreateTable();
    p.table.SetCustomTable(table);
    p.table.SetFlags({G.horizontalFlex(*,G.verticalFlex*)});
    p.table.SetMinHeight(Z.unit,10);
    p.table.SetMaxWidth(Z.screenVRel,30);
    p.table.SetMaxHeight(Z.screenVRel,30);
    p.table.RequestFocus();
    p.table.SetModel(p.tableModel);
    p.table.table.SetAutoSize(TRUE);
    p.table.SetShowScroller(FALSE,TRUE);


    p.combo.InitTable(p.table);

      (* if an entry gets selection with the mouse, close the popup *)
      NEW(closeMsg);
      closeMsg.destination:=p;
      p.table.table.AddHandler(closeMsg,TV.mouseSelectionMsg);

    wGroup.SetMain(p.table);
    wGroup.SetSpace(FALSE);
    p.SetTop(wGroup);

    p.PreInit^;
  END PreInit;

  PROCEDURE (p : Popup) OnOpened*;

  BEGIN
    p.OnOpened^;

    IF (p.tableModel#NIL) & (p.tableModel.selection(SM.SingleLine).line>0) THEN
      p.table.table.MakeVisible(1,p.tableModel.selection(SM.SingleLine).line);
    END;
  END OnOpened;

  PROCEDURE (c : Combo) OpenPopup;

  BEGIN
    NEW(c.popup);
    c.popup.Init;
    c.popup.SetType(D.windowTypePopup);
    c.popup.SetParent(c.GetWindow());
    c.popup.SetReference(c);
    c.popup.tableModel:=c.tableModel;
    c.popup.combo:=c;

    IF c.popup.Open() THEN
      c.popup.EventLoop;
      c.popup.Close;

      IF ~c.popup.table.table(Table).cancel &
        (c.tableModel#NIL) &
        c.tableModel.selection(SM.SingleLine).HasSelection() THEN
        c.CopySelection(c.tableModel.selection(SM.SingleLine).line);
      END;
    END;
  END OpenPopup;

  PROCEDURE (c : Combo) SetTableRow*(row : LONGINT);

  BEGIN
    c.tableModel.selection.SelectCell(1,row);
    c.CopySelection(c.tableModel.selection(SM.SingleLine).line);
  END SetTableRow;


  PROCEDURE (c : Combo) HandleMouseEvent*(event : E.MouseEvent;
                                          VAR grab : G.Object):BOOLEAN;

  BEGIN
    IF ~c.visible OR c.disabled(* OR (c.model=NIL) OR c.model.IsNull()*) THEN
      RETURN FALSE;
    END;

    IF c.value.HandleMouseEvent(event,grab) THEN
      RETURN TRUE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & c.PointIsIn(event.x,event.y)
      & (event.button=E.button1) THEN
        c.OpenPopup;
        RETURN TRUE;
      END;
    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (c : Combo) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  BEGIN
    IF (c.value IS G.Gadget) & c.value(G.Gadget).HandleKeyEvent(event) THEN
      RETURN TRUE;
    END;

    IF c.tableModel=NIL THEN
      RETURN FALSE;
    END;

    IF event.type=E.keyDown THEN
      CASE event.key OF
        E.down:
        IF event.qualifier*E.altMask#{} THEN
          c.OpenPopup;
        ELSIF c.tableModel.GetRows()>0 THEN
          IF c.tableModel.selection(SM.SingleLine).line<1 THEN
            c.SetTableRow(1);
          ELSIF (c.tableModel.selection(SM.SingleLine).line<c.tableModel.GetRows()) THEN
            c.SetTableRow(c.tableModel.selection(SM.SingleLine).line+1);
          END;
        END;
        RETURN TRUE;
      | E.up:
        IF c.tableModel.GetRows()>0 THEN
          IF c.tableModel.selection(SM.SingleLine).line<1 THEN
            c.SetTableRow(c.tableModel.GetRows());
          ELSIF (c.tableModel.selection(SM.SingleLine).line>1) THEN
            c.SetTableRow(c.tableModel.selection(SM.SingleLine).line-1);
          END;
        END;
        RETURN TRUE;
      | E.home:
        IF c.tableModel.GetRows()>0 THEN
          c.SetTableRow(1);
        END;
        RETURN TRUE;
      | E.end:
        IF c.tableModel.GetRows()>0 THEN
          c.SetTableRow(c.tableModel.GetRows());
        END;
        RETURN TRUE;
      ELSE
      END;
    END;

    RETURN FALSE;
  END HandleKeyEvent;

  PROCEDURE (c : Combo) Layout*;

  BEGIN
    c.image.Resize(-1,c.height-c.prefs(Prefs).vSpace.GetSize()*2);
    c.value.Resize(c.width-c.image.oWidth-
                   c.prefs(Prefs).interSpace.GetSize()-
                   c.prefs(Prefs).hSpace.GetSize()*2,
                   c.height-c.prefs(Prefs).vSpace.GetSize()*2);

    IF c.prefs(Prefs).imageRight THEN
      c.value.Move(c.x+c.prefs(Prefs).hSpace.GetSize(),
                   c.y+(c.height-c.value.oHeight) DIV 2);
    ELSE
      c.value.Move(c.x+c.prefs(Prefs).hSpace.GetSize()+c.image.oWidth+
                   c.prefs(Prefs).interSpace.GetSize(),
                   c.y+(c.height-c.value.oHeight) DIV 2);
    END;

    IF c.prefs(Prefs).imageRight THEN
      c.image.Move(c.x+c.width-c.image.oWidth-c.prefs(Prefs).hSpace.GetSize(),
                   c.y+(c.height-c.image.oHeight) DIV 2);
    ELSE
      c.image.Move(c.x+c.prefs(Prefs).hSpace.GetSize(),
                   c.y+(c.height-c.image.oHeight) DIV 2);
    END;

    c.Layout^;
  END Layout;

  PROCEDURE (c : Combo) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~c.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    c.Draw^(x,y,w,h);

    draw:=c.GetDrawInfo();

    draw.InstallClip(x,y,w,h);
    draw.SubRegion(c.image.oX,c.image.oY,c.image.oWidth,c.image.oHeight);
    draw.SubRegion(c.value.oX,c.value.oY,c.value.oWidth,c.value.oHeight);
    c.DrawBackground(c.x,c.y,c.width,c.height);
    draw.FreeLastClip;

    c.value.Draw(x,y,w,h);
    c.image.Draw(x,y,w,h);

    IF c.disabled THEN
      c.DrawDisabled;
    END;
  END Draw;

  PROCEDURE (c : Combo) DrawFocus*;

  BEGIN
    (* If our image can draw a keyboard focus, delegate it *)
    IF  ~c.value.StdFocus() THEN
      IF c.value IS G.Gadget THEN
        c.value(G.Gadget).CatchedFocus;
      ELSE
        c.value.DrawFocus;
      END;
    ELSE
      (* Delegate drawing to the baseclass *)
      c.DrawFocus^;
    END;
  END DrawFocus;

  PROCEDURE (c : Combo) HideFocus*;

  BEGIN
    (* If our image can draw a keyboard focus, delegate it *)
    IF ~c.value.StdFocus() THEN
      IF c.value IS G.Gadget THEN
        c.value(G.Gadget).LostFocus;
      ELSE
        c.value.HideFocus;
      END;
    ELSE
      (* Delegate drawing to the baseclass *)
     c.HideFocus^;
    END;
  END HideFocus;

  PROCEDURE (c : Combo) Hide*;

  BEGIN
    IF c.visible THEN
      c.image.Hide;
      c.value.Hide;
      c.Hide^;
    END;
  END Hide;

  PROCEDURE (c : Combo) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF (model=c.model) THEN
      IF ((c.model.type=VM.longint)
      OR (c.model.type=VM.integer)
      OR (c.model.type=VM.shortint)) & ~c.model.IsNull() THEN
        c.CopySelection(c.model.GetLongint()+1);
      ELSE
        c.CopySelection(-1);
      END;
    END;
  END Resync;

  PROCEDURE (c : TextCombo) Init*;

  VAR
    text : TX.Text;

  BEGIN
    c.Init^;

    text:=TX.CreateText();
    c.SetValueObject(text);
  END Init;

  PROCEDURE (c : TextCombo) CopySelection*(row : LONGINT);

  VAR
    string : STRING;
    text   : U.Text;

  BEGIN
    c.CopySelection^(row);

    IF (row>0) & (c.tableModel#NIL) & (c.tableModel.GetRows()>0) THEN
      string:=c.tableModel.GetString(1,row);
      IF string=NIL THEN
        text:=c.tableModel.GetText(1,row);
      ELSE
        text:=NIL;
      END;

      IF string#NIL THEN
        c.value(TX.Text).SetString(string);
      ELSIF text#NIL THEN
        c.value(TX.Text).SetText(text^);
      ELSE
        c.value(TX.Text).SetText("");
      END;
    ELSE
      c.value(TX.Text).SetText("");
    END;
  END CopySelection;

  PROCEDURE (c : StringCombo) Init*;

  VAR
    string : S.String;

  BEGIN
    c.Init^;

    string:=S.CreateString();
    c.SetValueObject(string);
    string.Forward(S.extNavMsg,c);
  END Init;

  PROCEDURE (c : StringCombo) CopySelection*(row : LONGINT);

  VAR
    string : STRING;
    text   : U.Text;

  BEGIN
    c.CopySelection^(row);

    IF (row>0) & (c.tableModel#NIL) & (c.tableModel.GetRows()>0) THEN
      string:=c.tableModel.GetString(1,row);
      IF string=NIL THEN
        text:=c.tableModel.GetText(1,row);
      ELSE
        text:=NIL;
      END;

      IF c.value(S.String).string#NIL THEN
        IF string#NIL THEN
          c.value(S.String).string.SetString(string);
        ELSIF text#NIL THEN
          c.value(S.String).string.SetString(Object.NewLatin1(text^));
        ELSE
          c.value(S.String).string.SetString("");
        END;
      END;
    END;
  END CopySelection;

  PROCEDURE (c : StringCombo) Receive*(message : O.Message);

  BEGIN
    WITH message : S.ExtNavMsg DO
      IF message.event.type=E.keyDown THEN
        CASE message.event.key OF
          E.down:
          IF message.event.qualifier*E.altMask#{} THEN
            c.OpenPopup;
          ELSE
            IF c.tableModel.selection(SM.SingleLine).line<1 THEN
              c.tableModel.selection.SelectCell(1,1);
              c.CopySelection(c.tableModel.selection(SM.SingleLine).line);
            ELSIF (c.tableModel.selection(SM.SingleLine).line<c.tableModel.GetRows()) THEN
              c.tableModel.selection.SelectCell(1,c.tableModel.selection(SM.SingleLine).line+1);
              c.CopySelection(c.tableModel.selection(SM.SingleLine).line);
            END;
          END;
        | E.up:
          IF c.tableModel.selection(SM.SingleLine).line<1 THEN
            c.tableModel.selection.SelectCell(1,c.tableModel.GetRows());
            c.CopySelection(c.tableModel.selection(SM.SingleLine).line);
          ELSIF (c.tableModel.selection(SM.SingleLine).line>1) THEN
            c.tableModel.selection.SelectCell(1,c.tableModel.selection(SM.SingleLine).line-1);
            c.CopySelection(c.tableModel.selection(SM.SingleLine).line);
          END;
        ELSE
        END;
      END;
    ELSE
    END;
  END Receive;

  PROCEDURE CreateTextCombo*():TextCombo;

    (**
      Creates a new instance of @otype{TextCombo}.
    *)

  VAR
    combo : TextCombo;

  BEGIN
    NEW(combo);
    combo.Init;

    RETURN combo;
  END CreateTextCombo;

  PROCEDURE CreateStringCombo*():StringCombo;

    (**
      Creates a new instance of @otype{StringCombo}.
    *)

  VAR
    combo : StringCombo;

  BEGIN
    NEW(combo);
    combo.Init;

    RETURN combo;
  END CreateStringCombo;

BEGIN
  NEW(prefs);
  prefs.Init;

END VO:Combo.
