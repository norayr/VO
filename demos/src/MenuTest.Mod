MODULE MenuTest;

  (**
    A more or less senseless demo-programm for VisualOberon.
  *)

(*
    Demo for VisualOberon.
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

IMPORT D   := VO:Base:Display,
       E   := VO:Base:Event,
       O   := VO:Base:Object,

              VO:Dlg:About,

       V   := VO:Model:Value,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>
        PG := VO:Prefs:GUI,

       L   := VO:Label,
       G   := VO:Object,
       M   := VO:Menu,
       ST  := VO:String,
       W   := VO:Window,
       WG  := VO:WindowGroup,

(*              C,*)
Err(*,
Types*);

CONST
  quitId     = 1000;
  settingsId = 1001;
  aboutId    = 1002;

TYPE
TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
                 current   : V.IntModel;
               END;

VAR
  w        : Window;
  msg2Exit : D.Msg2Exit;

  info     : About.Info;

  PROCEDURE (w : Window) Receive*(message : O.Message);

  BEGIN
    WITH
      message : M.SelectedMsg DO
      w.current.SetLongint(message.id);
      CASE message.id OF
          settingsId:
            PG.settings.SetParent(w);
            PG.settings.SetPosition(D.centerOnParent,D.centerOnParent);
            IF PG.settings.Open() THEN
              PG.settings.EventLoop;
              PG.settings.Close;
            END;
        | quitId:
            D.display.Exit;
        | aboutId:
          About.Show(w,info);
        ELSE
        END;
        RETURN;
    ELSE
      w.Receive^(message);
    END;
  END Receive;

  PROCEDURE (w : Window) PreInit*;

  VAR
    string : ST.String;
    label  : L.Label;
    wGroup : WG.WindowGroup;
    sub,
    sub2,
    sub3,
    sub4   : M.Menu;
    strip  : M.MenuStrip;

  BEGIN
    w.SetTitle("MenuTest");

    w.current:=V.CreateIntModel();
    w.current.SetLongint(-1);

    string:=ST.CreateString();
    string.SetFlags({G.horizontalFlex,G.verticalFlex});
    string.SetModel(w.current);
    string.SetReadOnly(TRUE);

    label:=L.CreateLabel();
    label.SetFlags({G.horizontalFlex,G.verticalFlex});
    label.AddStringLabel("Menu ID:",string);

    NEW(strip);
    strip.Init;
    strip.Forward(M.selectedMsg,w);

    sub:=M.InitMenu();
    sub.AddTextItem("New",0);
    sub.AddTextItemSC("Open...",1,E.controlMask,"o");
    sub.AddTextItemSC("Save",2,E.controlMask,"o");
    sub.AddSeparator;
    sub.AddTextItemSC("\ew\ebQuit",quitId,E.controlMask,"q");
    strip.AddPullDownMenuString("_File",sub);

    sub:=M.InitMenu();
    sub.AddTextItemSC("Cut",3,E.controlMask,"x");
    sub.AddTextItemSC("Copy",4,E.controlMask,"c");
    sub.AddTextItemSC("Paste",5,E.controlMask,"v");
      sub2:=M.InitMenu();
      sub2.AddTextItem("Sub 1",6);
      sub2.AddTextItem("Sub 2",7);
      sub2.AddTextItem("Sub 3",8);
      sub2.AddTextItem("Sub 4",9);
      sub2.AddTextItem("Sub 5",10);
      sub2.AddTextItem("Sub 6",11);
      sub2.AddTextItem("Sub 7",12);
        sub3:=M.InitMenu();
        sub3.AddTextItem("SubSub 1",13);
        sub3.AddTextItem("SubSub 2",14);
        sub3.AddTextItem("SubSub 3",15);
        sub3.AddTextItem("SubSub 4",16);
        sub3.AddTextItem("SubSub 5",17);
          sub4:=M.InitMenu();
          sub4.AddTextItem("SubSubSub 1",18);
          sub4.AddTextItem("SubSubSub 2",19);
          sub4.AddTextItem("SubSubSub 3",20);
          sub4.AddTextItem("SubSubSub 4",21);
          sub4.AddTextItem("SubSubSub 5",22);
        sub3.AddTextSubMenu("SubSubSub",sub4);
      sub2.AddTextSubMenu("SubSub",sub3);
    sub.AddTextSubMenu("Sub",sub2);

    strip.AddPullDownMenuString("_Edit",sub);

    sub:=M.InitMenu();
    sub.AddTextItemSC("Find...",23,E.controlMask,"f");
    sub.AddTextItemSC("Find next",24,E.controlMask,"n");
    sub.AddSeparator;
    sub.AddTextItemSC("Replace...",25,E.controlMask,"r");
    sub.AddTextItemSC("Replace next",26,E.controlMask,"y");
    sub.AddSeparator;
    sub.AddTextItemSC("Goto",27,E.controlMask,"g");
    strip.AddPullDownMenuString("_Search",sub);

    sub:=M.InitMenu();
    sub.AddTextItem("Help on item...",28);
    sub.AddTextItem("Tutorial",29);
    sub.AddSeparator;
    sub.AddTextItemSC("\ebVO settings...",settingsId,E.controlMask,"!");
    sub.AddSeparator;
    sub.AddTextItemSC("\ebAbout...",aboutId,E.controlMask,"?");
    strip.AddPullDownMenuString("_Help",sub);

    wGroup:=WG.CreateWindowGroup();
    wGroup.SetFlags({G.horizontalFlex,G.verticalFlex});
    wGroup.SetMain(label);
    wGroup.SetSpace(TRUE);
    wGroup.SetMenu(strip);

    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

BEGIN
  IF ~Probe.OpenDisplay("MenuTest") THEN
    Err.String("Cannot init application!"); Err.Ln;
    HALT(1);
  END;

  info:=About.CreateInfo();
  info.SetProgram("MenuTest");
  info.SetVersion("0.0");
  info.SetAuthor("Tim Teulings");
  info.SetContact("tim@teulings.org");
  info.SetCopyright("2003, Tim Teulings");
  info.SetLicense("GNU GPL License");
  info.SetDescription("A small testprogram to demonstrate\nmenues");

  NEW(w);
  w.Init;

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
    w.Close;
  END;

  D.display.Close;
END MenuTest.