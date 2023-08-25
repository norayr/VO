MODULE VO:Dlg:Msg;

  (**
    A module for creating a number of simple dialogs for displaying
    modal messages and getting simple user response.
  *)

(*
    A Module for simple dialogs.
    Copyright (C) 1997 Tim Teulings (rael@edge.ping.de)

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
       VB  := VO:Base:VecImage,

       B   := VO:Button,
       BR  := VO:ButtonRow,
       G   := VO:Object,
       I   := VO:Image,
       P   := VO:Panel,
       S   := VO:Space,
       T   := VO:Text,
       W   := VO:Window,
       WG  := VO:WindowGroup;

CONST
  (* various image types *)
  none     * = 0;
  warning  * = 1;
  info     * = 2;
  atention * = 3;
  question * = 4;


TYPE
  MsgDialog*     = POINTER TO MsgDialogDesc;
  MsgDialogDesc* = RECORD (W.WindowDesc)
                     text    : STRING;
                     button  : STRING;
                     type    : LONGINT;
                     result- : LONGINT;
                   END;

  PROCEDURE (d : MsgDialog) Init*;

  BEGIN
    d.Init^;

    d.text:=NIL;
  END Init;

  PROCEDURE (d : MsgDialog) SetText*(text,button : STRING; type : LONGINT);

  (**
    Set the text to display in the dialog, the buttons to be showed and
    the image.

    PARAMETER
    Text can use any escape sequences supported by VOText, button consists
    of a list of button labels ("_","*","^" and "#" are supported) devided
    by "|" and type can be one of the constants defined in this module.
  *)

  BEGIN
    d.text:=text;
    d.button:=button;
    d.type:=type;
  END SetText;

  PROCEDURE (d : MsgDialog) PreInit*;

  VAR
    vPanel,
    hPanel  : P.Panel;
    image   : I.Image;
    button  : B.Button;
    row     : BR.ButtonRow;
    space   : S.Space;
    wGroup  : WG.WindowGroup;
    label   : STRING;
    length,
    a,b,pos : LONGINT;

  BEGIN
    vPanel:=P.CreateVPanel();

      hPanel:=P.CreateHPanel();
      hPanel.SetFlags({G.horizontalFlex,G.verticalFlex});

      image:=I.CreateImage();
      CASE d.type OF
        info:
          image.SetInternal(VB.info);
      | atention:
          image.SetInternal(VB.atention);
      | warning:
          image.SetInternal(VB.warning);
      | question:
          image.SetInternal(VB.question);
      END;
      hPanel.Add(image);
      NEW(space);
      space.Init;
      space.Set(FALSE,S.huge);
      hPanel.Add(space);

      IF d.text#NIL THEN
       hPanel.Add(T.MakeLeftString(d.text));
      END;

    vPanel.Add(hPanel);

    vPanel.Add(S.CreateVSpace());

      NEW(row);
      row.Init;
      row.SetFlags({G.horizontalFlex});

      IF d.button#NIL THEN
        length:=d.button.length;
        a:=0;
        b:=0;
        pos:=0;

        WHILE b<length DO
          IF d.button.CharAt(b)="|" THEN
            label:=d.button.Substring(a,b);

            button:=B.CreateButton();
            button.SetFlags({G.horizontalFlex,G.verticalFlex});
            button.RequestFocus();
            button.SetLabelString(label);
            button.SetId(pos);
            button.Forward(B.pressedMsg,d);
            row.Add(button);

            a:=b+1;
            INC(b);
            INC(pos);
          ELSE
            INC(b);
          END;
        END;

        IF a<length-1 THEN
          label:=d.button.Substring(a,length);

          button:=B.CreateButton();
          button.SetFlags({G.horizontalFlex,G.verticalFlex});
          button.RequestFocus();
          button.SetLabelString(label);
          button.SetId(pos);
          button.Forward(B.pressedMsg,d);
          row.Add(button);
        END;
      END;
    vPanel.Add(row);

    wGroup:=WG.CreateWindowGroup();
    wGroup.SetMain(vPanel);

    d.SetTop(wGroup);

    d.Forward(W.closeMsg,d);

    d.PreInit^;
  END PreInit;

  PROCEDURE (d : MsgDialog) Receive*(message : O.Message);

  BEGIN
    WITH
      message : B.PressedMsg DO
        d.result:=message.source.id;
        d.Exit;
    | message : W.CloseMsg DO
        d.result:=-1;
        d.Exit;
    ELSE
      d.Receive^(message);
    END;
  END Receive;

  PROCEDURE Dialog*(parent : D.Window;
                    title,
                    text,
                    button : STRING;
                    type : LONGINT):MsgDialog;

  (**
    Opens a dialog with the given title and text. The dialog has a list of buttons
    as described in button. Buttons descriptions contain of a number button labels,
    divided by "|" (e.g. "OK*|Cancel^".).

    Type can be one of the constants defined.

    The functions returns the zero based position of the pressed button within
    the button description string. If the window was closed without pressing
    one of the buttons, -1 is returned.
  *)

  VAR
    msgDialog : MsgDialog;

  BEGIN
    NEW(msgDialog);
    msgDialog.Init;
    msgDialog.SetParent(parent);
    msgDialog.SetPosition(D.centerOnParent,D.centerOnParent);
    msgDialog.SetTitle(title);
    msgDialog.SetText(text,button,type);
    IF msgDialog.Open() THEN
      msgDialog.EventLoop;
      msgDialog.Close;
    END;
    RETURN msgDialog;
  END Dialog;

  PROCEDURE Message*(parent : D.Window;
                     title,
                     text,
                     button : STRING;
                     type : LONGINT);

  BEGIN
    IF Dialog(parent,title,text,button,type)#NIL THEN
    END;
  END Message;

  PROCEDURE Ask*(parent : D.Window;title,text,button : STRING):LONGINT;

  VAR
    dialog : MsgDialog;

  BEGIN
    dialog:=Dialog(parent,title,text,button,question);
    RETURN dialog.result;
  END Ask;

  PROCEDURE Error*(parent : D.Window; title,error : STRING);

  BEGIN
    Message(parent,title,error,"_OK*",atention);
  END Error;

END VO:Dlg:Msg.