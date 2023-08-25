MODULE TextView;

(*
    A simple textviewer as demo for the textview gadget of
    VisualOberon.

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

IMPORT D  := VO:Base:Display,
       O  := VO:Base:Object,
       U  := VO:Base:Util,
       Z  := VO:Base:Size,

       TM := VO:Model:TextView,
       V  := VO:Model:Value,

             VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
             VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>

       G  := VO:Object,
       P  := VO:Panel,
       S  := VO:String,
       SP := VO:Space,
       TV := VO:TextView,
       SV := VO:View,
       W  := VO:Window,

             Err,
       F  := Files,
             Out;

TYPE
  Window      = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
                  stringModel : V.StringModel;
                END;

VAR
  w           : Window;
  msg2Exit    : D.Msg2Exit;

  top         : P.Panel;
  space       : SP.Space;
  string      : S.String;
  textModel   : TM.ListTextModel;
  textView    : TV.TextView;
  text        : ARRAY 256 OF CHAR;
  view        : SV.View;


  PROCEDURE LoadFile(name : ARRAY OF CHAR);

  VAR
    file : F.File;
    res  : F.Result;

  BEGIN
    file:=F.Old(name,{F.read},res);
    IF file#NIL THEN
      IF ~textModel.LoadFromChannel(file) THEN
        res.GetText(text);
        Out.String("Error: "); Out.String(text); Out.Ln;
      END;
      file.Close;
    ELSE
      res.GetText(text);
      Out.String("Error: "); Out.String(text); Out.Ln;
    END;
  END LoadFile;

  PROCEDURE (w : Window)  Receive*(message : O.Message);

  VAR
    text : U.Text;

  BEGIN
    WITH
      message : S.EnteredMsg DO
      text:=w.stringModel.GetText();
      LoadFile(text^);
    ELSE
      w.Receive^(message);
    END;
  END Receive;


BEGIN
  IF ~Probe.OpenDisplay("TextView") THEN
    Err.String("Cannot init application!"); Err.Ln;
    HALT(1);
  END;

  NEW(w);
  w.Init;

  NEW(top);
  top.Init;
  top.Set(P.vertical);
  top.SetFlags({G.horizontalFlex,G.verticalFlex});

    NEW(w.stringModel);
    w.stringModel.Init;
    w.stringModel.SetString("./src/TextView.Mod");

    NEW(string);
    string.Init;
    string.SetFlags({G.horizontalFlex});
    string.RequestFocus();
    string.Forward(S.enteredMsg,w);
(*    string.help:=Q.InitHelp(d,MakeListText("Enter filename of\ntextfile to display."),string);*)
    string.SetModel(w.stringModel);
  top.Add(string);

    NEW(space);
    space.Init;
    space.Set(TRUE,SP.normal);
  top.Add(space);

    NEW(textModel);
    textModel.Init;

    NEW(textView);
    textView.Init;
    textView.SetWidth(Z.unit,90);
    textView.SetHeight(Z.screenVRel,80);
    textView.SetModel(textModel);
    textView.RequestFocus();

    view:=SV.CreateView(textView);
    view.SetFlags({G.horizontalFlex,G.verticalFlex});

  top.Add(view);

  w.SetTop(top);
  w.SetTitle("Textview");

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    (*  LoadFile("./TextView.Mod");*)
    D.display.EventLoop;
  END;

  D.display.Close;
END TextView.