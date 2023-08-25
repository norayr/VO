MODULE WRITE;

  (*
    Demo for the VO internal multiline text edit control.
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

IMPORT D   := VO:Base:Display,

       E   := VO:Edit:Edit,
              VO:Edit:Function,
              VO:Edit:Syntax:Standard,
       T   := VO:Edit:Text,

              VO:OS:Probe,

              VO:Prefs:All,  (* Include preferences for all objects *)

       G   := VO:Object,
       ML  := VO:TextEdit,
       V   := VO:View,
       W   := VO:Window,
       Z   := VO:Base:Size,

              Err,
       str := Strings;

CONST
  initialText = "Type something!";

TYPE
  Window*     = POINTER TO WindowDesc;
  WindowDesc* = RECORD (W.WindowDesc)
                END;

VAR
  w       : Window;
  edit    : ML.TextEdit;
  view    : V.View;
  text    : T.Text;

BEGIN
  IF ~Probe.OpenDisplay("WRITE") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  NEW(w);
  w.Init;

    NEW(text);
    text.Init;
    text.SetText(initialText,str.Length(initialText),Standard.syntax);

    edit:=ML.CreateTextEdit();
    edit.SetFlags({G.horizontalFlex,G.verticalFlex});
    edit.RequestFocus();
    edit.SetModel(text);
    edit.Forward(E.updateMsg,w);
    IF D.display.displayType#D.displayTypeTextual THEN
      edit.SetMinWidth(Z.unit,80);
      edit.SetMinHeight(Z.unit,25);
      edit.SetWidth(Z.unit,80);
      edit.SetHeight(Z.unit,25);
    END;

    view:=V.CreateView(edit);
    view.SetFlags({G.horizontalFlex,G.verticalFlex});
    IF D.display.displayType=D.displayTypeTextual THEN
      view.SetWidth(Z.screenHRel,80);
      view.SetHeight(Z.screenVRel,80);
    END;

  w.SetTop(view);
  w.SetTitle("VOE");

  w.Forward(W.closeMsg,w);

  IF w.Open() THEN
    w.EventLoop;
  END;

  w.Close;

  D.display.Close;
END WRITE.