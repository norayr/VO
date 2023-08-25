MODULE XTest;

  (**
    A more or less senseless demo-programm for VisualOberon.
  *)

(*
    Demo for VisualOberon.
    Copyright (C) 1997 Tim Teulings (rael@edge.ping.de)

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

IMPORT D   := VO:Base:Display,
       O   := VO:Base:Object,

              VO:Dlg:About,

       DS  := VO:Model:DataStream,
       SM  := VO:Model:Selection,
       TM  := VO:Model:Table,
       V   := VO:Model:Value,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>
       PG  := VO:Prefs:GUI,

<* PUSH; Warnings:=FALSE *>
       X1  := VO:VGD:All,
<* POP *>
              VO:VGD:VGD,

       A   := VO:Array,
       B   := VO:Button,
       BO  := VO:Bool,
       C   := VO:Combo,
       CA  := VO:ColorArea,
       FU  := VO:FuelGauge,
       G   := VO:Object,
       LED := VO:LED,
       M   := VO:Menu,
       OZ  := VO:Oszil,
       R   := VO:Radio,
       SL  := VO:Slider,
       ST  := VO:String,
       T   := VO:Text,
       TL  := VO:Table,
       W   := VO:Window,
       WF  := VO:WireFrame,
       X   := VO:Image,

(*              C,*)
Err(*,
Types*);

CONST
  quitId     = 100;
  settingsId = 101;
  aboutId    = 103;

TYPE
TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
                 current   : V.IntModel;
                 stream    : DS.StreamLongModel;
                 topPos    : V.IntModel;

                 popup     : W.Window;
                 fTimer    : D.Timer;

                 status    : T.Text;
                 fuel      : FU.FuelGauge;
               END;

  TreeVisitorDesc  = RECORD (G.VisitorDesc)
                       depth : LONGINT;
                     END;

VAR
  w        : Window;

  desc     : VGD.VGD;
  context  : VGD.Context;

  msg2Exit : D.Msg2Exit;

  info     : About.Info;

  PROCEDURE NewImageEntry*(file : STRING):G.Object;

  VAR
    image : X.Image;

  BEGIN
    NEW(image);
    image.Init;
    image.SetFilename(file);

    RETURN image;
  END NewImageEntry;

  PROCEDURE MakeOKPopup(gadget : B.Button):W.Window;

  VAR
    array      : A.Array;
    button1,
    button2    : B.Button;
    open       : W.Msg2OpenModal;
    close      : W.Msg2Close;
    popup      : W.Window;

  BEGIN
    (* Make popupwindow *)

    NEW(popup);
    popup.Init;
    popup.SetType(D.windowTypePopup);
    popup.SetParent(w);

    NEW(array);
    array.Init;
    array.Set(2,TRUE);
    array.SetFlags({G.horizontalFlex,G.verticalFlex});

      NEW(button1);
      button1.Init;
      button1.SetFlags({G.horizontalFlex,G.verticalFlex});
      button1.RequestFocus();
      button1.SetLabelString("Ok*");
    array.Add(button1);

      NEW(button2);
      button2.Init;
      button2.SetFlags({G.horizontalFlex,G.verticalFlex});
      button2.RequestFocus();
      button2.SetLabelString("Cancel^");
    array.Add(button2);

    popup.SetTop(array);
    popup.SetReference(gadget);
    NEW(open);
    open.destination:=popup;
    gadget.AddHandler(open, B.pressedMsg);
    NEW(close);
    close.destination:=popup;
    button1.AddHandler(close, B.pressedMsg);
    NEW(close);
    close.destination:=popup;
    button2.AddHandler(close, B.pressedMsg);
    RETURN popup;
  END MakeOKPopup;

  (*  PROCEDURE (VAR t : TreeVisitorDesc) Visit*(object : G.Object):BOOLEAN;

  VAR
    visitor : TreeVisitorDesc;
    type    : Types.Type;
    x       : LONGINT;

  BEGIN
    type:=Types.TypeOf(object);

    FOR x:=1 TO t.depth DO
      Err.Char(" ");
    END;
    Err.String(type.module.name^);Err.Char(".");Err.String(type.name^);Err.Ln;

    visitor.depth:=t.depth+2;
    IF object.VisitChildren(visitor,FALSE) THEN END;

    RETURN TRUE;
  END Visit;

  PROCEDURE (w : Window) DumpObjectTree;

  VAR
    visitor : TreeVisitorDesc;
    type    : Types.Type;

  BEGIN
    Err.String("Object tree:"); Err.Ln;

    type:=Types.TypeOf(w.top);
    Err.String(type.module.name^);Err.Char(".");Err.String(type.name^);Err.Ln;

    visitor.depth:=2;
    IF w.top.VisitChildren(visitor,FALSE) THEN END;
  END DumpObjectTree;*)

  PROCEDURE (w : Window) Receive*(message : O.Message);

  BEGIN
    WITH
      message : B.PressedMsg DO
        w.status.SetText("Button pressed!");
        RETURN;
    | message : ST.EnteredMsg DO
        w.status.SetText("Text entered!");
        RETURN;
    | message : M.SelectedMsg DO
      w.status.SetText("Menuitem selected!");
        CASE message.id OF
          settingsId:
            PG.ShowSettings(w);
        | quitId:
            D.display.Exit;
        | aboutId:
          About.Show(w,info);
        | 12:
          (*          w.DumpObjectTree;*)
        ELSE
        END;
        RETURN;
    | message : D.TimerMsg DO
      IF message.timer=w.fTimer THEN
        w.current.SetLongint((w.current.GetLongint()+1) MOD 101);
        w.stream.SetValue((w.current.GetLongint()+1) MOD 101,0);
        D.display.AddTimer(w.fTimer);
        RETURN;
      END;
    ELSE
      w.Receive^(message);
    END;
  END Receive;

  PROCEDURE AppendToList(model : TM.LTableModel; string : STRING);

  VAR
    entry : TM.ListEntry;

  BEGIN
    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,string);
    model.AppendEntry(entry);
  END AppendToList;

  PROCEDURE (w : Window) PreInit*;

  VAR
    anim        : WF.WireFrame;
    button      : B.Button;
    boolModel   : V.BoolModel;
    color       : CA.ColorArea;
    combo       : C.Combo;
    intModel    : V.IntModel;
    slider      : SL.Slider;
    stringModel : V.StringModel;
    string      : ST.String;
    oszil       : OZ.Oszil;
    strip       : M.MenuStrip;
    table       : TL.Table;
    tableModel,
    tableModel2,
    comboModel  : TM.LTableModel;
    object      : G.Object;

  BEGIN
    w.current:=V.CreateIntModel();
    w.current.SetLongint(0);

    NEW(w.stream);
    w.stream.Init;
    w.stream.SetNotificationMode(DS.notifyImplicit);
    w.stream.SetSize(1);

    w.topPos:=V.CreateIntModel();
    w.topPos.SetLongint(42);

    NEW(tableModel);
    tableModel.Init;

    AppendToList(tableModel,"Entry 1");
    AppendToList(tableModel,"Entry 2");
    AppendToList(tableModel,"Entry 3");
    AppendToList(tableModel,"Entry 4");
    AppendToList(tableModel,"Entry 5");
    AppendToList(tableModel,"Entry 6");
    AppendToList(tableModel,"Entry 7");
    AppendToList(tableModel,"Entry 8");
    AppendToList(tableModel,"Entry 9");
    AppendToList(tableModel,"Entry 10");
    AppendToList(tableModel,"Entry 11");
    AppendToList(tableModel,"Entry 12");
    AppendToList(tableModel,"Entry 13");
    AppendToList(tableModel,"Entry 14");
    AppendToList(tableModel,"Entry 15");
    AppendToList(tableModel,"Entry 16");
    AppendToList(tableModel,"Entry 17");
    AppendToList(tableModel,"Entry 18");
    AppendToList(tableModel,"Entry 19");
    AppendToList(tableModel,"Entry 20");

    NEW(tableModel2);
    tableModel2.Init;
(*    tableModel2.AppendEntryObject(NewImageEntry("xpm/new.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/open.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/save.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/redo.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/undo.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/first.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/left.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/current.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/right.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/last.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/cut.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/copy.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/paste.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/insert.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/export.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/help.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/mail.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/followmail.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/remail.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/news.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/renews.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/pgp.xpm"));
    tableModel2.AppendEntryObject(NewImageEntry("xpm/popup.xpm"));*)

    NEW(comboModel);
    comboModel.Init;

    AppendToList(comboModel,"Entry 1");
    AppendToList(comboModel,"Entry 2");
    AppendToList(comboModel,"Entry 3");
    AppendToList(comboModel,"Entry 4");
    AppendToList(comboModel,"Entry 5");
    AppendToList(comboModel,"Entry 6");
    AppendToList(comboModel,"Entry 7");
    AppendToList(comboModel,"Entry 8");
    AppendToList(comboModel,"Entry 9");
    AppendToList(comboModel,"Entry 10");

    (* The submenues will be added later *)

    boolModel:=V.CreateBoolModel();
    boolModel.SetBoolean(TRUE);

    object:=w.top.GetObjectByName("CB1");
    object(BO.Bool).SetModel(boolModel);
    object:=w.top.GetObjectByName("CB2");
    object(BO.Bool).SetModel(boolModel);
    object:=w.top.GetObjectByName("CB3");
    object(BO.Bool).SetModel(boolModel);
    object:=w.top.GetObjectByName("CB4");
    object(BO.Bool).SetModel(boolModel);
    object:=w.top.GetObjectByName("CB5");
    object(BO.Bool).SetModel(boolModel);
    object:=w.top.GetObjectByName("LED");
    object(LED.LED).SetModel(boolModel);

    intModel:=V.CreateIntModel();
    intModel.SetLongint(0);

    object:=w.top.GetObjectByName("RB1");
    object(R.Radio).SetModel(intModel);
    object(R.Radio).SetIndex(0);
    object:=w.top.GetObjectByName("RB2");
    object(R.Radio).SetModel(intModel);
    object(R.Radio).SetIndex(1);
    object:=w.top.GetObjectByName("RB3");
    object(R.Radio).SetModel(intModel);
    object(R.Radio).SetIndex(2);
    object:=w.top.GetObjectByName("RB4");
    object(R.Radio).SetModel(intModel);
    object(R.Radio).SetIndex(3);
    object:=w.top.GetObjectByName("RB5");
    object(R.Radio).SetModel(intModel);
    object(R.Radio).SetIndex(4);

    object:=w.top.GetObjectByName("Slider");
    slider:=object(SL.Slider);
    slider.SetRange(0,100);
    slider.SetModel(w.topPos);

    object:=w.top.GetObjectByName("Popup");
    button:=object(B.Button);
    button.Forward(B.pressedMsg,w);
    w.popup:=MakeOKPopup(button);

    object:=w.top.GetObjectByName("Disabled");
    button:=object(B.Button);
    button.Disable(TRUE);

    intModel:=V.CreateIntModel();
    intModel.SetLongint(2);

    object:=w.top.GetObjectByName("Combo");
    combo:=object(C.Combo);
    combo.SetTableModel(comboModel);

    object:=w.top.GetObjectByName("Oszil");
    oszil:=object(OZ.Oszil);
    oszil.SetRange(0,150);
    oszil.SetInterval(100,10);
    oszil.SetModel(w.stream);

    object:=w.top.GetObjectByName("Fuel");
    w.fuel:=object(FU.FuelGauge);
    w.fuel.SetRange(0,100);
    w.fuel.SetModel(w.current);

    stringModel:=V.CreateStringModel();
    stringModel.SetString("VisualOberon is really, really, really, really, really fantastic!");

    object:=w.top.GetObjectByName("String1");
    string:=object(ST.String);
    string.SetModel(stringModel);
    string.Forward(ST.enteredMsg,w);

    stringModel:=V.CreateStringModel();
    stringModel.SetString("Drop on me!");

    object:=w.top.GetObjectByName("String2");
    string:=object(ST.String);
    string.SetModel(stringModel);
    string.Forward(ST.enteredMsg,w);

    object:=w.top.GetObjectByName("Table1");
    table:=object(TL.Table);
    table.SetShowHeader(FALSE);
    table.SetModel(tableModel);
    tableModel.SetSelection(SM.CreateSingleLine());

    object:=w.top.GetObjectByName("Table2");
    table:=object(TL.Table);
    table.SetShowHeader(FALSE);
    table.SetModel(tableModel2);
    table.table.SetRowHeight(24);
    tableModel2.SetSelection(SM.CreateSingleLine());

    object:=w.top.GetObjectByName("WireFrame");
    anim:=object(WF.WireFrame);
    anim.SetViewer(0,0,-2000,-500);
    (* Front plane *)
    (*        anim.AddLine(-25, 25,25, 25, 25,25);
      anim.AddLine( 25, 25,25, 25,-25,25);
      anim.AddLine( 25,-25,25,-25,-25,25);
      anim.AddLine(-25,-25,25,-25, 25,25);

      (* back plane *)
      anim.AddLine(-25, 25,-25, 25, 25,-25);
      anim.AddLine( 25, 25,-25, 25,-25,-25);
      anim.AddLine( 25,-25,-25,-25,-25,-25);
      anim.AddLine(-25,-25,-25,-25, 25,-25);

      (* connections between front and back *)
      anim.AddLine( 25, 25,25, 25, 25,-25);
      anim.AddLine(-25,-25,25,-25,-25,-25);
      anim.AddLine(-25, 25,25,-25, 25,-25);
    anim.AddLine( 25,-25,25, 25,-25,-25);*)

    (* outer O *)
    anim.AddLine( 50, 0,0, 50,50,0);
    anim.AddLine( 50,50,0,-50,50,0);
    anim.AddLine(-50, 0,0,-50,50,0);
    anim.AddLine( 50, 0,0,-50, 0,0);

    (* inner O *)
    anim.AddLine( 40,10,0, 40,40,0);
    anim.AddLine( 40,40,0,-40,40,0);
    anim.AddLine(-40,10,0,-40,40,0);
    anim.AddLine( 40,10,0,-40,10,0);

    (* V *)
    anim.AddLine( 50,  0,0,50, -25,0);
    anim.AddLine( 50,-25,0, 0, -25,0);

    anim.AddLine(-50,  0,0,50,-100,0);

    anim.AddLine( 50,-75,0,50,-100,0);
    anim.AddLine(  0,-25,0,50, -75,0);

    object:=w.top.GetObjectByName("Color1");
    color:=object(CA.ColorArea);
    color.SetColor(D.halfShadowColor);

    object:=w.top.GetObjectByName("Color2");
    color:=object(CA.ColorArea);
    color.SetColor(D.halfShadowColor);

    object:=w.top.GetObjectByName("Status");
    w.status:=object(T.Text);

    object:=w.top.GetObjectByName("MenuStrip");
    strip:=object(M.MenuStrip);
    strip.Forward(M.selectedMsg,w);

    w.PreInit^;
  END PreInit;

BEGIN
  IF ~Probe.OpenDisplay("XTest") THEN
    Err.String("Cannot init application!"); Err.Ln;
    HALT(1);
  END;

  desc:=VGD.LoadVGD("XTest.vgd");
  IF desc=NIL THEN
    Err.String("Cannot load GUI description file 'XTest.vgd'"); Err.Ln;
    D.display.Close;
    HALT(1);
  END;

  NEW(w);
  w.Init;

  NEW(context);
  context.Init;
  IF ~VGD.LoadWindow(w,desc,"Main",context) THEN
    Err.String("Error: Cannot instantiate window from vgd file!");
    Err.Ln;
    context.DumpErrors;
    HALT(1);
  END;

  info:=About.CreateInfo();
  info.SetProgram("XTest");
  info.SetVersion("0.0");
  info.SetAuthor("Tim Teulings");
  info.SetContact("tim@teulings.org");
  info.SetCopyright("1997-2003, Tim Teulings");
  info.SetLicense("GNU GPL License");
  info.SetDescription("A small testprogram to demonstrate\na number of features of VisualOberon");

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    w.fTimer:=D.factory.CreateTimer();
    w.fTimer.SetSecs(0,100);
    w.fTimer.SetObject(w);
    D.display.AddTimer(w.fTimer);

    D.display.EventLoop;

    w.Close;
  ELSE
    Err.String("Cannot open inital window"); Err.Ln;
  END;

  D.display.Close;
END XTest.
