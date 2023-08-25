MODULE VO:ViewOneOfN;

  (**
    Implements abstract layout object that display one out of n views
    at the same time.
  *)

(*
    Implements abstract layout object that display one out of n views
    at the same time.

    Copyright (C) 2002 Tim Teulings (rael@edge.ping.de)

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


IMPORT D   := VO:Base:Display,
       FR  := VO:Base:Frame,
       O   := VO:Base:Object,
       U   := VO:Base:Util,
       Z   := VO:Base:Size,

       SM  := VO:Model:Selection,
       TM  := VO:Model:Table,
       V   := VO:Model:Value,

       C   := VO:Combo,
       G   := VO:Object,
       M   := VO:Multi,
       P   := VO:Panel,
       SP  := VO:Space,
       TA  := VO:Tab,
       TB  := VO:Table;

CONST
  modeTab   = 0;
  modeCombo = 1;
  modeTable = 2;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 planA*,
                 planAAlternate*,
                 planAAlterLimit*,
                 planB*,
                 planAMaxDepth*        : LONGINT;
                 planBOnParentSmaller* : BOOLEAN;
                 comboModeFrame*,
                 tableModeFrame*       : FR.Frame;
               END;

  Entry     = POINTER TO EntryDesc;
  EntryDesc = RECORD
                (**
                  Internal structure to hold list of entries
                *)
                next   : Entry;
                label  : STRING;
                object : G.Object;
              END;

  ViewOneOfN*     = POINTER TO ViewOneOfNDesc;
  ViewOneOfNDesc* = RECORD (G.LayoutDesc)
                  (**
                    Implements abstract layout object that displays one out of
                    n views at a time.
                  *)
                  list,
                  last    : Entry;
                  control : G.Object;
                  size    : LONGINT;
                  mode    : LONGINT;
                END;

  ComboToMulti     = POINTER TO ComboToMultiDesc;
  ComboToMultiDesc = RECORD (O.MsgObjectDesc)
                       multi : M.Multi;
                     END;


  TableToMulti     = POINTER TO TableToMultiDesc;
  TableToMultiDesc = RECORD (O.HandlerDesc)
                       multi : M.Multi;
                     END;

VAR
  prefs* : Prefs;

  PROCEDURE (h : ComboToMulti) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    h.multi.SetEntry(model(V.ValueModel).GetLongint()+1);
  END Resync;

  PROCEDURE (h : TableToMulti) Send*(message : O.Message);

  BEGIN
    h.multi.SetEntry(message.source(TM.LTableModel).selection(SM.SingleLine).line);
  END Send;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.planA:=modeCombo;
      p.planAAlternate:=modeCombo;
      p.planAAlterLimit:=8;
      p.planB:=modeCombo;
      p.planAMaxDepth:=2;
      p.planBOnParentSmaller:=TRUE;
    ELSE
      p.planA:=modeTab;
      p.planAAlternate:=modeTable;
      p.planAAlterLimit:=8;
      p.planB:=modeCombo;
      p.planAMaxDepth:=2;
      p.planBOnParentSmaller:=TRUE;
    END;

    p.comboModeFrame:=FR.CreateFrame(FR.none);
    p.tableModeFrame:=FR.CreateFrame(FR.none);
  END Initialize;

  PROCEDURE (t : ViewOneOfN) Init*;

  BEGIN
    t.Init^;

    t.SetFlags({G.canFocus});
    t.RemoveFlags({G.stdFocus});

    t.SetPrefs(prefs); (* We set the prefs *)

    t.list:=NIL;
    t.last:=NIL;
    t.control:=NIL;

    t.size:=0;
    t.mode:=modeCombo;
  END Init;

  PROCEDURE (t : ViewOneOfN) VisitChildren*(VAR visitor : G.VisitorDesc;
                                        onlyVisible : BOOLEAN):BOOLEAN;

  VAR
    entry : Entry;

  BEGIN
    IF t.control#NIL THEN
      RETURN visitor.Visit(t.control);
    ELSE
      entry:=t.list;
      WHILE entry#NIL DO
        IF ~visitor.Visit(entry.object) THEN
          RETURN FALSE;
        END;
        entry:=entry.next;
      END;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (t : ViewOneOfN) AddView*(label : STRING; object : G.Object);

  VAR
    entry : Entry;

  BEGIN
    NEW(entry);
    entry.label:=label;
    entry.object:=object;
    entry.next:=NIL;

    IF t.list=NIL THEN
      t.list:=entry;
    ELSE
      t.last.next:=entry;
    END;
    t.last:=entry;

    INC(t.size);
  END AddView;

  PROCEDURE (t : ViewOneOfN) GetSelection* () : LONGINT;
  (* Return the index of the selected view. Currently, only works for tab
     views. *)
  BEGIN
    CASE t.mode OF
    | modeTab:
      RETURN t.control(TA.Tab).selected;
    END;
  END GetSelection;

  PROCEDURE (t : ViewOneOfN) CalcSize*;

  VAR
    entry    : Entry;
    tab      : TA.Tab;
    table    : TB.Table;
    panel    : P.Panel;
    combo    : C.Combo;
    multi    : M.Multi;
    value    : V.IntModel;
    model    : TM.LTableModel;
    tEntry   : TM.ListEntry;
    comboMsg : ComboToMulti;
    tableMsg : TableToMulti;
    object   : G.Object;
    width    : LONGINT;
    tabs     : LONGINT;

  BEGIN
    t.mode:=t.prefs(Prefs).planA;

    tabs:=0;

    IF t.mode=modeTab THEN
      INC(tabs);
    END;

    object:=t.parent;
    WHILE object#NIL DO
      IF (object IS ViewOneOfN) THEN
        INC(tabs);
      END;
      object:=object.parent;
    END;

    IF (tabs>t.prefs(Prefs).planAMaxDepth) THEN
      t.mode:=t.prefs(Prefs).planB;
    END;

    IF (t.mode=t.prefs(Prefs).planA) & (t.prefs(Prefs).planBOnParentSmaller) THEN
      object:=t.parent;
      WHILE (object#NIL) & ~(object IS ViewOneOfN) DO
        object:=object.parent;
      END;

      IF (object#NIL) & (object(ViewOneOfN).size<t.size) THEN
        t.mode:=t.prefs(Prefs).planB;
      END;
    END;

    IF t.size>t.prefs(Prefs).planAAlterLimit THEN
      t.mode:=t.prefs(Prefs).planAAlternate;
    END;

    IF t.mode=modeTab THEN
      tab:=TA.CreateTab();
      entry:=t.list;
      WHILE entry#NIL DO
        tab.AddStringTab(entry.label,entry.object);
        entry:=entry.next;
      END;

      IF t.HasFocusRequested() THEN
        (* Delegate focusing to subobject *)
        tab.RequestFocus();
      END;

      t.control:=tab;
    ELSIF t.mode=modeCombo THEN
      t.SetObjectFrame(t.prefs(Prefs).comboModeFrame);

      panel:=P.CreateVPanel();

      NEW(model);
      model.Init;

      value:=V.CreateIntModel();

      NEW(comboMsg);

      combo:=C.CreateTextCombo();
      combo.SetFlags({G.horizontalFlex});
      combo.SetModel(value);
      combo.SetTableModel(model);
      panel.Add(combo);

      IF t.HasFocusRequested() THEN
        (* Delegate focusing to subobject *)
        combo.RequestFocus();
      END;

      panel.Add(SP.CreateVSpace());

      multi:=M.CreateMulti();
      multi.SetFlags({G.horizontalFlex,G.verticalFlex});
      comboMsg.multi:=multi;
      panel.Add(multi);

      value.AddObject(comboMsg);

      entry:=t.list;
      WHILE entry#NIL DO
        tEntry:=TM.CreateListEntry(model);
        tEntry.SetStr(1,entry.label);
        model.AppendEntry(tEntry);
        multi.Add(entry.object);
        entry:=entry.next;
      END;
      value.SetLongint(0);

      t.control:=panel;
    ELSIF t.mode=modeTable THEN
      t.SetObjectFrame(t.prefs(Prefs).tableModeFrame);
      panel:=P.CreateHPanel();

      NEW(model);
      model.Init;
      model.SetSelection(SM.CreateSingleLine());

      NEW(tableMsg);
      model.AddHandler(tableMsg,TM.selectionMsg);

      table:=TB.CreateTable();
      table.SetFlags({G.verticalFlex});
      table.SetModel(model);
      table.SetShowHeader(FALSE);
      table.SetShowScroller(FALSE,TRUE);

      IF t.HasFocusRequested() THEN
        (* Delegate focusing to subobject *)
        table.RequestFocus;
      END;

      panel.Add(table);
      panel.Add(SP.CreateHSpace());
      multi:=M.CreateMulti();
      multi.SetFlags({G.horizontalFlex,G.verticalFlex});
      tableMsg.multi:=multi;
      panel.Add(multi);

      width:=5; (* hardcoded minimal width of table *)
      entry:=t.list;
      WHILE entry#NIL DO
        width:=U.MaxLong(width,entry.label.length);

        tEntry:=TM.CreateListEntry(model);
        tEntry.SetStr(1,entry.label);
        model.AppendEntry(tEntry);
        multi.Add(entry.object);
        entry:=entry.next;
      END;

      table.SetMinWidth(Z.unit,width);

      model.selection.SelectCell(1,1);
      multi.SetEntry(1);

      t.control:=panel;
    ELSE
      ASSERT(FALSE);
    END;

    t.control.SetFlags({G.horizontalFlex,G.verticalFlex});
    t.control.SetParent(t);
    t.control.CalcSize;

    IF t.HasFocusRequested() THEN
      (*
        Since we delegated focus to our subobjects we remove ourself
        from the focusing chain.
      *)
      t.UnrequestFocus();
    END;

    t.minWidth:=t.control.minWidth;
    t.minHeight:=t.control.minHeight;
    t.width:=t.control.width;
    t.height:=t.control.height;

    t.CalcSize^;
  END CalcSize;

  PROCEDURE (t : ViewOneOfN) Layout*;

  BEGIN
    t.control.Resize(t.width,t.height);
    t.control.Move(t.x+(t.width-t.control.oWidth) DIV 2,
                   t.y+(t.height-t.control.oHeight) DIV 2);

    t.Layout^;
  END Layout;

  PROCEDURE CreateViewOneOfN*():ViewOneOfN;

  VAR
    oneOfN : ViewOneOfN;

  BEGIN
    NEW(oneOfN);
    oneOfN.Init;

    RETURN oneOfN;
  END CreateViewOneOfN;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:ViewOneOfN.
