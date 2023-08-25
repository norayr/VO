MODULE FormDemo1;

(**
  A simple demo for @code{VO:Model:View} and @code{VO:Dlg:Form}.
*)

(*
    A simple demo for VO:Model:View and VO:Dlg:Form.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

    This file is part of VisualOberon.

    VisualOberon is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    VisualOberon is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with VisualOberon. If not, write to the Free Software
    Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

IMPORT D   := VO:Base:Display,     (* Display stuff *)
       E   := VO:Base:Event,
       O   := VO:Base:Object,
       U   := VO:Base:Util,
       Z   := VO:Base:Size,

              VO:Dlg:About,
       FD  := VO:Dlg:Form,

       SM  := VO:Model:Selection,
       TM  := VO:Model:Table,
       V   := VO:Model:Value,
       VI  := VO:Model:View,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,    (* The use the preferences setting *)
<* POP *>

       B   := VO:Button,
       BR  := VO:ButtonRow,
       G   := VO:Object,   (* GUI object baseclass *)
       L   := VO:Label,
       M   := VO:Menu,
       P   := VO:Panel,
       S   := VO:String,
       SP  := VO:Space,
       T   := VO:Table,
       TV  := VO:TableView,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              Err;           (* Simple error IO *)

CONST
  about       = 0;
  addEntry    = 1;
  deleteEntry = 2;
  viewEntry   = 3;
  editEntry   = 4;
  save        = 5;
  quit        = 6;

TYPE
  Main          = POINTER TO MainDesc;
  MainDesc      = RECORD (W.WindowDesc)
                  END;

  Form          = POINTER TO FormDesc;
  FormDesc      = RECORD (FD.FormDesc)
                  END;

  View          = POINTER TO ViewDesc;
  ViewDesc      = RECORD (VI.ViewDesc)
                    name : V.StringModel;
                  END;

  ListEntry     = POINTER TO ListEntryDesc;
  ListEntryDesc = RECORD (TM.ListEntryBaseDesc)
                    view : View;
                  END;


VAR
  w     : Main;           (** The main window *)
  model : TM.LTableModel; (** model that holds all our values *)
  info  : About.Info;

  PROCEDURE (v : View) Init*;

  BEGIN
    v.name:=V.CreateStringModel();
    v.RegisterModel("Name",v.name);
  END Init;

  PROCEDURE (e : ListEntry) Init*(model : TM.LTableModel);

  BEGIN
    e.Init^(model);

    NEW(e.view);
    e.view.Init;
  END Init;

  PROCEDURE (e : ListEntry) GetString*(x : LONGINT):STRING;

  BEGIN
    RETURN e.view.name.GetString();
  END GetString;

  PROCEDURE (w : Form) Receive*(message : O.Message);

  BEGIN
    WITH message : B.PressedMsg DO
      CASE message.source.id OF
        0:
        (*        IF w.person.GetTextLength()>0 THEN*)
          w.ExitOK;
          (*        ELSE
          D.display.Beep;
        END;*)
      | 1:
        w.ExitCancel;
      ELSE
      END;
    ELSE
      w.Receive^(message);
    END;
  END Receive;

  PROCEDURE (w : Form) PreInit*;

  VAR
    panel  : P.Panel;
    label  : L.Label;
    string : S.String;
    row    : BR.ButtonRow;
    button : B.Button;
    wGroup : WG.WindowGroup; (* The window group *)

  BEGIN
    wGroup:=WG.CreateWindowGroup();
    wGroup.SetFlags({G.horizontalFlex,G.verticalFlex});

    panel:=P.CreateVPanel();
    panel.SetFlags({G.horizontalFlex});
      label:=L.CreateLabel();
      label.SetFlags({G.horizontalFlex});
        string:=S.CreateString();
        string.SetName("Name");
        string.SetFlags({G.horizontalFlex});
        string.RequestFocus();
      label.AddStringLabel("Name",string);
    panel.Add(label);

    panel.Add(SP.CreateVSpace());

      row:=BR.CreateButtonRow();
      row.SetFlags({G.horizontalFlex});

        button:=B.CreateButton();
        button.SetFlags({G.horizontalFlex});
        button.RequestFocus();
        button.SetLabelString("_OK*");
        button.SetId(0);
        button.Forward(B.pressedMsg,w);

      row.Add(button);

        button:=B.CreateButton();
        button.SetFlags({G.horizontalFlex});
        button.RequestFocus();
        button.SetLabelString("_Cancel^");
        button.SetId(1);
        button.Forward(B.pressedMsg,w);
      row.Add(button);
    panel.Add(row);

      wGroup.Set(NIL,panel,TRUE);
    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

  PROCEDURE (w : Main) About;

  BEGIN
    About.Show(w,info);
  END About;

  PROCEDURE (w : Main) AddEntry;

  VAR
    form  : Form;
    entry : ListEntry;

  BEGIN
    NEW(entry);
    entry.Init(model);

    NEW(form);
    form.Init;
    form.SetTitle("Add...");
    form.SetParent(w);
    form.SetPosition(D.centerOnParent,D.centerOnParent);
    form.AttachView(entry.view);
    IF form.Open() THEN
      form.SetMode(FD.modeNew);
      form.EventLoop;
      form.Close;

      IF form.result THEN
        model.AppendEntry(entry);
      END;
    END;
  END AddEntry;

  PROCEDURE (w : Main) DeleteEntry;

  BEGIN
    IF model.selection(SM.SingleLine).line>=1 THEN
      model.DeleteEntry(model.selection(SM.SingleLine).line);
    END;
  END DeleteEntry;

  PROCEDURE (w : Main) ViewEntry;

  VAR
    form     : Form;
    tmp      : TM.ListEntryBase;
    entry    : ListEntry;

  BEGIN
    tmp:=model.GetEntry(model.selection(SM.SingleLine).line);
    IF tmp=NIL THEN
      RETURN;
    END;

    entry:=tmp(ListEntry);

    NEW(form);
    form.Init;
    form.SetTitle("View...");
    form.SetParent(w);
    form.SetPosition(D.centerOnParent,D.centerOnParent);
    form.AttachView(entry.view);
    IF form.Open() THEN
      form.SetMode(FD.modeView);
      form.EventLoop;
      form.Close;
    END;
  END ViewEntry;

  PROCEDURE (w : Main) EditEntry;

  VAR
    form     : Form;
    tmp      : TM.ListEntryBase;
    entry    : ListEntry;

  BEGIN
    tmp:=model.GetEntry(model.selection(SM.SingleLine).line);
    IF tmp=NIL THEN
      RETURN;
    END;

    entry:=tmp(ListEntry);

    NEW(form);
    form.Init;
    form.SetTitle("Edit...");
    form.SetParent(w);
    form.SetPosition(D.centerOnParent,D.centerOnParent);
    form.AttachView(entry.view);
    IF form.Open() THEN
      form.SetMode(FD.modeEdit);
      form.EventLoop;
      form.Close;
    END;
  END EditEntry;

  PROCEDURE (w : Main) SaveEntries;

  VAR
    entry : ListEntry;

  BEGIN
    entry:=model.first(ListEntry);
    WHILE entry#NIL DO
      Err.Object(entry.view.name.GetString()); Err.Ln;

      IF entry.next#NIL THEN
        entry:=entry.next(ListEntry);
      ELSE
        entry:=NIL;
      END;
    END;
    Err.String("---"); Err.Ln;
  END SaveEntries;

  PROCEDURE (w : Main) Receive*(message : O.Message);

  BEGIN
    WITH message : M.SelectedMsg DO
      CASE message.id OF
        addEntry:
        w.AddEntry;
      | deleteEntry:
        w.DeleteEntry;
      | viewEntry:
        w.ViewEntry;
      | editEntry:
        w.EditEntry;
      | save:
        w.SaveEntries;
      | quit:
        D.display.Exit;
      | about:
        w.About;
      ELSE
      END;
    | message : TV.DoubleClickMsg DO
      w.ViewEntry;
    | message : W.CloseMsg DO
      D.display.Exit;
    ELSE
      w.Receive^(message);
    END;
  END Receive;

  PROCEDURE (w : Main) PreInit*;

  VAR
    table  : T.Table;
    entry  : ListEntry;
    wGroup : WG.WindowGroup; (* The window group *)
    menu   : M.Menu;
    strip  : M.MenuStrip;

  BEGIN
    wGroup:=WG.CreateWindowGroup();
    wGroup.SetFlags({G.horizontalFlex,G.verticalFlex});

    NEW(model);
    model.Init;
    model.SetSelection(SM.CreateSingleLine());
    NEW(entry);
    entry.Init(model);
    entry.view.name.SetString("Paul");
    model.AppendEntry(entry);

    table:=T.CreateTable();
    table.SetFlags({G.horizontalFlex,G.verticalFlex});
    table.SetMinWidth(Z.unit,50);
    table.SetMinHeight(Z.unit,70);
    table.RequestFocus();
    table.SetModel(model);
    table.table.Forward(TV.doubleClickMsg,w);

    wGroup.SetMain(table);

    strip:=M.CreateMenuStrip();

    menu:=M.InitMenu();
    menu.AddTextItemSC("_Save",save,E.controlMask,"s");
    menu.AddTextItemSC("_Quit",quit,E.controlMask,"q");
    strip.AddPullDownMenuString("_File",menu);

    menu:=M.InitMenu();
    menu.AddTextItemSC("_Add name...",addEntry,E.controlMask,"a");
    menu.AddTextItemSC("_Delete Name",deleteEntry,E.controlMask,"d");
    menu.AddSeparator;
    menu.AddTextItemSC("_View name...",viewEntry,E.controlMask,"i");
    menu.AddTextItemSC("_Edit name...",editEntry,E.controlMask,"e");
    strip.AddPullDownMenuString("_Edit",menu);

    menu:=M.InitMenu();
    menu.AddTextItemSC("_About...",about,E.controlMask,"?");
    strip.AddPullDownMenuString("_Help",menu);

    strip.Forward(M.selectedMsg,w);

    wGroup.SetMenu(strip);
    (*wGroup.SetMenuObject(menu);*)

    w.SetTop(wGroup);

    w.SetTitle("FormDemo1");

    w.PreInit^;
  END PreInit;

BEGIN
  (*
    Try to initialize it.
    This call make the connection to the X server and allocates
    fonts, colors and that stuff
  *)
  IF ~Probe.OpenDisplay("FormDemo1") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  info:=About.CreateInfo();
  info.SetProgram("FormDemo1");
  info.SetVersion("0.0");
  info.SetAuthor("Tim Teulings");
  info.SetContact("tim@teulings.org");
  info.SetCopyright("2003, Tim Teulings");
  info.SetLicense("GNU GPL License");
  info.SetDescription("A small testprogram to demonstrate\nForms.");

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.Forward(W.closeMsg,w);

  (* Open the main window *)
  IF w.Open() THEN
    (*
      Start the main event loop. The event loop will get finished when
      the display receives a close message or its exit method gets called.
    *)
    D.display.EventLoop;
  END;

  (* Free possible ressources of the display. *)
  D.display.Close;
END FormDemo1.