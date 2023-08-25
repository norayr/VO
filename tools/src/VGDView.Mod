MODULE VGDView;

(**
  A viewer for the VisualOberon GUI description files.
*)

(*
    A viewer for the VisualOberon GUI description files.
    Copyright (C) 2002 Tim Teulings (rael@edge.ping.de)

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

IMPORT D   := VO:Base:Display, (* Display stuff *)
       E   := VO:Base:Event,
       O   := VO:Base:Object,
       Z   := VO:Base:Size,

              VO:Dlg:About,
       FD  := VO:Dlg:File,
       MD  := VO:Dlg:Msg,

       SM  := VO:Model:Selection,
       TM  := VO:Model:Table,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,    (* The use the preferences setting *)
<* POP *>
       PP  := VO:Prefs:Parser,

<* PUSH; Warnings:=FALSE *>
       X1  := VO:VGD:All,
<* POP *>
              VO:VGD:VGD,

       B   := VO:Button,
       BR  := VO:ButtonRow,
       G   := VO:Object,
       M   := VO:Menu,
       P   := VO:Panel,
       SP  := VO:Space,
       T   := VO:Table,
       TA  := VO:Tab,
       TV  := VO:TableView,
       W   := VO:Window,       (* Window class *)
       WG  := VO:WindowGroup,

              Err,             (* Simple error IO *)
              IO,
              OS:Path,
       pp  := OS:ProcessParameters,
       PA  := ProgramArgs,
       TR  := TextRider;

CONST
  OpenCmd   = 0;
  ReloadCmd = 1;
  QuitCmd   = 2;
  AboutCmd  = 3;

TYPE
  Window        = POINTER TO WindowDesc;
  WindowDesc    = RECORD (W.WindowDesc)
                    windowTable : T.Table;
                    windowModel : TM.LTableModel;
                  END;

  ErrorView     = POINTER TO ErrorViewDesc;
  ErrorViewDesc = RECORD (W.WindowDesc)
                    context : VGD.Context;
                  END;


VAR
  w          : Window;         (* The window *)
  msg2Exit   : D.Msg2Exit;     (* a simple message converter *)
  file       : STRING;

  info       : About.Info;
  desc       : VGD.VGD;

  PROCEDURE (w : ErrorView) PreInit*;

  VAR
    wGroup   : WG.WindowGroup;
    panel    : P.Panel;
    space    : SP.Space;
    button   : B.Button;
    bRow     : BR.ButtonRow;
    table    : T.Table;
    model    : TM.LTableModel;
    entry    : TM.ListEntry;
    error    : VGD.ErrorEntry;
    msg2Exit : W.Msg2Exit;     (* a simple message converter *)

  BEGIN
    wGroup:=WG.CreateWindowGroup();
    wGroup.SetFlags({G.horizontalFlex,G.verticalFlex});
    wGroup.SetWidth(Z.unit,100);
    wGroup.SetHeight(Z.unit,50);

    panel:=P.CreateVPanel();
    panel.SetFlags({G.horizontalFlex,G.verticalFlex});

    table:=T.CreateTable();
    table.SetFlags({G.horizontalFlex,G.verticalFlex});
    table.RequestFocus();
    table.SetShowHeader(TRUE);

    NEW(model);
    model.Init;
    model.SetSelection(SM.CreateSingleLine());
    model.SetLabel(1,"Item");
    model.SetColumnWidth(1,Z.stdCharWidth,35);
    model.SetLabel(2,"Error");
    model.SetColumnWidth(2,Z.stdCharWidth,80);

    error:=w.context.errorList;
    WHILE error#NIL DO
      entry:=TM.CreateListEntry(model);
      IF error.item.name#NIL THEN
        entry.SetString(1,error.item.name^);
      ELSE
        entry.SetStr(1,"???");
      END;
      IF error.error#NIL THEN
        entry.SetStr(2,error.error);
      ELSE
        entry.SetStr(2,"???");
      END;
      model.AppendEntry(entry);
      error:=error.next;
    END;

    table.table.SetModel(model);

    panel.Add(table);

    space:=SP.CreateVSpace();
    panel.Add(space);

    bRow:=BR.CreateButtonRow();
    bRow.SetFlags({G.horizontalFlex});

    button:=B.CreateButton();
    button.RequestFocus();
    button.SetLabelString("_Quit*");

    NEW(msg2Exit);
    msg2Exit.destination:=w;
    button.AddHandler(msg2Exit,B.pressedMsg);

    bRow.Add(button);

    panel.Add(bRow);

    wGroup.SetMain(panel);

    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

  PROCEDURE ShowErrors(context : VGD.Context);

  VAR
    errorView : ErrorView;
    msg2Exit  : W.Msg2Exit;     (* a simple message converter *)

  BEGIN
    NEW(errorView);
    errorView.context:=context;
    errorView.Init;
    errorView.SetParent(w);
    errorView.SetPosition(D.centerOnParent,D.centerOnParent);
    errorView.SetTitle("There were errors!");

    NEW(msg2Exit);
    msg2Exit.destination:=errorView;
    errorView.AddHandler(msg2Exit,W.closeMsg);
    IF errorView.Open() THEN
      errorView.EventLoop;
      errorView.Close;
    END;
  END ShowErrors;

  PROCEDURE (w : Window) PreInit*;

  VAR
    wGroup : WG.WindowGroup;
    tab    : TA.Tab;
    sub    : M.Menu;
    strip  : M.MenuStrip;

  BEGIN
    wGroup:=WG.CreateWindowGroup();
    wGroup.SetFlags({G.horizontalFlex,G.verticalFlex});
    wGroup.SetWidth(Z.unit,50);
    wGroup.SetHeight(Z.screenVRel,30);

    tab:=TA.CreateTab();
    tab.SetFlags({G.horizontalFlex,G.verticalFlex});
    tab.RequestFocus();

    w.windowTable:=T.CreateTable();
    w.windowTable.SetFlags({G.horizontalFlex,G.verticalFlex});
    w.windowTable.RequestFocus();

    NEW(w.windowModel);
    w.windowModel.Init;
    w.windowModel.SetSelection(SM.CreateSingleLine());

    w.windowTable.table.SetModel(w.windowModel);
    w.windowTable.table.Forward(TV.doubleClickMsg,w);
    tab.AddStringTab("Windows",w.windowTable);

    wGroup.SetMain(tab);

    strip:=M.CreateMenuStrip();

    sub:=M.InitMenu();
    sub.AddTextItemSC("_Open",OpenCmd,E.controlMask,"o");
    sub.AddTextItemSC("_Reload",ReloadCmd,E.controlMask,"r");
    sub.AddSeparator;
    sub.AddTextItemSC("_Quit",QuitCmd,E.controlMask,"q");
    strip.AddPullDownMenuString("_File",sub);
    sub:=M.InitMenu();
    sub.AddTextItemSC("_About",AboutCmd,E.controlMask,"?");
    strip.AddPullDownMenuString("_Help",sub);

    strip.Forward(M.selectedMsg,w);

    wGroup.SetMenu(strip);

    w.SetTop(wGroup);

    w.SetTitle("VGDView");

    w.PreInit^;
  END PreInit;

  PROCEDURE (w : Window) ReadVGD(file : STRING);

  VAR
    item,
    block : PP.Item;
    entry : TM.ListEntry;

  BEGIN
    desc:=VGD.LoadVGD(file);
    IF desc=NIL THEN
      IF MD.Dialog(w,"Error...","Cannot load vgd File!","OK*",MD.atention)#NIL THEN
      END;
      RETURN;
    ELSIF desc.top=NIL THEN
      IF MD.Dialog(w,"Error...","vgd File is empty!","OK*",MD.atention)#NIL THEN
      END;
    ELSE
      w.windowModel.DeleteAll;

      item:=desc.top.itemList;
      WHILE item#NIL DO
        IF item.name^="Window" THEN
          block:=item.itemList;
          WHILE block#NIL DO
            IF (block.name^="name") & (block IS PP.ValueItem) THEN
              entry:=TM.CreateListEntry(w.windowModel);
              entry.SetStr(1,block(PP.ValueItem).value);
              w.windowModel.AppendEntry(entry);
            END;
            block:=block.next;
          END;
        END;
        item:=item.next;
      END;
    END;
  END ReadVGD;

  PROCEDURE (w : Window) OpenFile;

  VAR
    name : STRING;

  BEGIN
    IF file#NIL THEN
      name:=file;
    ELSE
      TRY
        name:=pp.GetCwd();
      CATCH IO.Error:
        name:="/";
      END;
    END;

    IF FD.GetExistingFile(w,"Open...",name) THEN
      file:=name;
      w.ReadVGD(file);
    END;
  END OpenFile;

  PROCEDURE (w : Window) OpenWindow(name : STRING);

  VAR
    context   : VGD.Context;
    window    : W.Window;
    msg2Exit : W.Msg2Exit;

  BEGIN
    NEW(context);
    context.Init;

    NEW(window);
    window.Init;

    IF ~VGD.LoadWindow(window,desc,name,context) THEN
      ShowErrors(context);
    ELSE
      NEW(msg2Exit);
      msg2Exit.destination:=window;
      window.AddHandler(msg2Exit,W.closeMsg);
      window.SetParent(w);
      window.SetPosition(D.centerOnParent,D.centerOnParent);

      IF window.Open() THEN
        window.EventLoop;
        window.Close;
      END;
    END;
  END OpenWindow;

  PROCEDURE (w : Window) Receive*(message : O.Message);

  VAR
    text : STRING;

  BEGIN
    WITH
      message : TV.DoubleClickMsg DO
      IF w.windowModel.selection(SM.SingleLine).line>0 THEN
        text:=w.windowModel.GetString(1,w.windowModel.selection(SM.SingleLine).line);
        w.OpenWindow(text);
      END;
    | message : M.SelectedMsg DO
      CASE message.id OF
        OpenCmd:
        w.OpenFile;
      | ReloadCmd:
        IF ~file.Equals("") THEN
          w.ReadVGD(file);
        END;
      | QuitCmd:
        D.display.Exit;
      | AboutCmd:
        About.Show(w,info);
      END;
    ELSE
      w.Receive^(message);
    END;
  END Receive;

  PROCEDURE ParseArgs():BOOLEAN;

  VAR
    reader : TR.Reader;
    buffer : ARRAY 1024 OF CHAR;

  BEGIN
    reader:=TR.ConnectReader(PA.args);
    IF reader#NIL THEN
      reader.ReadLine(buffer);

      IF PA.args.ArgNumber()>1 THEN
        Err.String("Expected exactly one argument!"); Err.Ln;
        Err.String("Usage:"); Err.Ln;
        Err.String("VGDView <filename>"); Err.Ln;
        RETURN FALSE;
      END;

      IF PA.args.ArgNumber()=1 THEN
        reader.ReadLine(buffer);
        file:=Path.Decode(buffer);
      ELSE
        file:=NIL;
      END;
    END;

    RETURN TRUE;
  END ParseArgs;

BEGIN
  IF ~ParseArgs() THEN
    HALT(1);
  END;

  (*
    Try to initialize it.
    This call make the connection to the X server and allocates
    fonts, colors and that stuff
  *)
  IF ~Probe.OpenDisplay("VGDView") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  info:=About.CreateInfo();
  info.SetProgram("VGDView");
  info.SetVersion("0.0");
  info.SetAuthor("Tim Teulings");
  info.SetContact("tim@teulings.org");
  info.SetCopyright("2002-2003, Tim Teulings");
  info.SetLicense("GNU GPL License");
  info.SetDescription("Previewer for *.vgd files");

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (*
    Allocate an instance of this special message handler.
    A handler is a class that can convert any or a special
    input message to an other message and sends the resulting
    message to the given destination. However the baseclas just
    returns the input message.

    Most converters are handwritten, but some special converters are
    given by the corresponding objects.

    This converter converts the close-message generated when clicking
    the closing gadget of the window to an exist-message of the display
    class.
  *)
  NEW(msg2Exit);

  (*
    Send the resulting exit message to the display, which will finish
    the event loop and receiving.
  *)
  msg2Exit.destination:=D.display;

  (*
    Add the handler to window and tell the window that it should call
    this hndler when a close message gets send.
  *)
  w.AddHandler(msg2Exit,W.closeMsg);

  (* Open the main window *)
  IF w.Open() THEN
    IF file#NIL THEN
      w.ReadVGD(file);
    END;

    (*
      Start the main event loop. The event loop will get finished when
      the display receives a close message or its exit method gets called.
    *)
    D.display.EventLoop;
  END;

  (* Free possible ressources of the display. *)
  D.display.Close;
END VGDView.