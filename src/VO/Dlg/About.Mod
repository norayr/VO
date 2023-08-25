MODULE VO:Dlg:About;

  (**
    A module for creating a simple about dialog, showing program name,
    version number, copyright, contact address etc.
  *)

(*
    A simple about dialog.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

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
       O   := VO:Base:Object,

       B   := VO:Button,
       BR  := VO:ButtonRow,
       G   := VO:Object,
       P   := VO:Panel,
       S   := VO:Space,
       T   := VO:Text,
       W   := VO:Window,
       WG  := VO:WindowGroup;


TYPE
  Info*      = POINTER TO InfoDesc;
  InfoDesc*  = RECORD
                 program-,
                 version-,
                 author-,
                 contact-,
                 copyright-,
                 license-,
                 description- : STRING;
               END;

  About*     = POINTER TO AboutDesc;
  AboutDesc* = RECORD (W.WindowDesc)
                 info- : Info;
               END;

  PROCEDURE (i : Info) SetProgram*(text : STRING);

  BEGIN
    i.program:=text;
  END SetProgram;

  PROCEDURE (i : Info) SetVersion*(text : STRING);

  BEGIN
    i.version:=text;
  END SetVersion;

  PROCEDURE (i : Info) SetAuthor*(text : STRING);

  BEGIN
    i.author:=text;
  END SetAuthor;

  PROCEDURE (i : Info) SetContact*(text : STRING);

  BEGIN
    i.contact:=text;
  END SetContact;

  PROCEDURE (i : Info) SetCopyright*(text : STRING);

  BEGIN
    i.copyright:=text;
  END SetCopyright;

  PROCEDURE (i : Info) SetLicense*(text : STRING);

  BEGIN
    i.license:=text;
  END SetLicense;

  PROCEDURE (i : Info) SetDescription*(text : STRING);

  BEGIN
    i.description:=text;
  END SetDescription;

  PROCEDURE (i : Info) Init*;

  BEGIN
    i.program:="ThisProgram";
    i.version:="0.0";
    i.author:="<anonymous>";
    i.contact:="< no contact info>";
    i.copyright:="<no copyright>";
    i.license:="<no licence>";
    i.description:="A little usefull program";
  END Init;

  PROCEDURE CreateInfo*():Info;

  VAR
    info : Info;

  BEGIN
    NEW(info);
    info.Init;

    RETURN info;
  END CreateInfo;

  PROCEDURE (d : About) Init*;

  BEGIN
    d.Init^;

    d.info:=CreateInfo();
  END Init;

  PROCEDURE (d : About) SetInfo*(info : Info);

  BEGIN
    d.info:=info;
  END SetInfo;

  PROCEDURE (d : About) PreInit*;

  VAR
    vPanel  : P.Panel;
    button  : B.Button;
    row     : BR.ButtonRow;
    wGroup  : WG.WindowGroup;
    text    : T.Text;
    string : STRING;

  BEGIN
    vPanel:=P.CreateVPanel();
    vPanel.SetFlags({G.horizontalFlex,G.verticalFlex});

    string:="\ec\es\e9"+d.info.program+"\en \e0"+d.info.version+"\e4\n\el"+
    d.info.description+"\en\n\n"+
    "\esAuthor:\en \t"   +d.info.author+"\n"+
    "\esContact:\en \t"  +d.info.contact+"\n"+
    "\esCopyright:\en \t"+d.info.copyright+"\n"+
    "\esLicense:\en \t"  +d.info.license+"\n\n"+
    "\e2\ecThis program was written using \esVisualOberon\en,\na GUI framework written in \esOberon-2\en.\nVisit \eshttp://visualoberon.sourceforge.net\en\nfor more information!";

    text:=T.CreateText();
    text.SetFlags({G.horizontalFlex});
    text.SetString(string);
    vPanel.Add(text);

    vPanel.Add(S.CreateVSpace());

    row:=BR.CreateButtonRow();
    row.SetFlags({G.horizontalFlex});

    button:=B.CreateButton();
    button.SetFlags({G.horizontalFlex,G.verticalFlex});
    button.RequestFocus();
    button.SetLabelString("_OK#");
    button.Forward(B.pressedMsg,d);
    row.Add(button);

    vPanel.Add(row);

    NEW(wGroup);
    wGroup.Init;
    wGroup.SetMain(vPanel);

    d.SetTop(wGroup);

    d.Forward(W.closeMsg,d);

    d.PreInit^;
  END PreInit;

  PROCEDURE (d : About) Receive*(message : O.Message);

  BEGIN
    WITH
      message : B.PressedMsg DO
        d.Exit;
    | message : W.CloseMsg DO
        d.Exit;
    ELSE
      d.Receive^(message);
    END;
  END Receive;

  PROCEDURE CreateAbout*():About;

  VAR
    about : About;

  BEGIN
    NEW(about);
    about.Init;

    RETURN about;
  END CreateAbout;

  PROCEDURE Show*(parent : D.Window;
                  info : Info);

  (**
  *)

  VAR
    about : About;

  BEGIN
    about:=CreateAbout();
    about.SetParent(parent);
    about.SetPosition(D.centerOnParent,D.centerOnParent);
    about.SetTitle("About...");
    about.SetInfo(info);
    IF about.Open() THEN
      about.EventLoop;
      about.Close;
    END;
  END Show;

END VO:Dlg:About.