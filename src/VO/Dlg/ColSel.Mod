MODULE VO:Dlg:ColSel;

(**
  A dialog to select one of the internal colors.
*)

(*
    A dialog to select one of the internal colors
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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

IMPORT D  := VO:Base:Display,
       O  := VO:Base:Object,

       A  := VO:Array,
       B  := VO:Button,
       CA := VO:ColorArea,
       G  := VO:Object,
       L  := VO:Label,
       P  := VO:Panel,
       Q  := VO:QuickHelp,
       S  := VO:Space,
       T  := VO:Text,
       W  := VO:Window;

CONST
  setMsg * = 0;

  okId     = 100;
  cancelId = 101;

TYPE
  ColSelDlg*     = POINTER TO ColSelDlgDesc;
  ColSelDlgDesc* = RECORD (W.WindowDesc)
                     color-   : LONGINT;
                     tmpColor : LONGINT;
                     current  : CA.ColorArea;
                   END;

  SetMsg*        = POINTER TO SetMsgDesc;
  SetMsgDesc*    = RECORD (O.MessageDesc)
                     color* : LONGINT;
                   END;


  PROCEDURE (d : ColSelDlg) Init*;

  BEGIN
    d.Init^;

    d.color:=D.textColor;

    d.SetTitle("Color select dialog");
  END Init;

  PROCEDURE (d : ColSelDlg) PreInit*;

  VAR
    panel   : P.Panel;
    array   : A.Array;
    button  : B.Button;
    color   : CA.ColorArea;
    space   : S.Space;
    label   : L.Label;
    i       : LONGINT;

  BEGIN
    d.tmpColor:=d.color;

    NEW(panel);
    panel.Init;
    panel.Set(P.vertical);

      NEW(array);
      array.Init;
      array.SetFlags({G.horizontalFlex});
      array.Set(4,TRUE);
      array.SetSpace(TRUE,TRUE);

      FOR i:=0 TO D.colorCount-1 DO
        NEW(button);
        button.Init;
        button.RequestFocus();

          NEW(color);
          color.Init;
          color.SetColor(i);

        button.SetImage(color);
        button.SetHelpObject(Q.InitHelp(T.MakeLeftText(D.colorNames[i]),button));
        button.SetId(i);
        button.Forward(B.pressedMsg,d);

        array.Add(button);
      END;
    panel.Add(array);

      NEW(space);
      space.Init;
      space.Set(TRUE,S.normal);
    panel.Add(space);

      NEW(label);
      label.Init;
        NEW(color);
        color.Init;
        d.current:=color;
      label.AddStringLabel("Current value:",color);
    panel.Add(label);


      NEW(space);
      space.Init;
      space.Set(TRUE,S.normal);
    panel.Add(space);

      NEW(array);
      array.Init;
      array.SetFlags({G.horizontalFlex});
      array.Set(2,TRUE);
      array.SetSpace(TRUE,FALSE);

        NEW(button);
        button.Init;
        button.SetFlags({G.horizontalFlex,G.verticalFlex});
        button.RequestFocus();
        button.SetLabelString("Ok*");
        button.SetId(okId);
        button.Forward(B.pressedMsg,d);
      array.Add(button);

        NEW(button);
        button.Init;
        button.SetFlags({G.horizontalFlex,G.verticalFlex});
        button.RequestFocus();
        button.SetLabelString("Cancel^");
        button.SetId(cancelId);
        button.Forward(B.pressedMsg,d);
      array.Add(button);
    panel.Add(array);

    d.SetTop(panel);

    d.Forward(W.closeMsg,d);

    d.PreInit^;
  END PreInit;

  PROCEDURE (d : ColSelDlg) Receive*(message : O.Message);

  VAR
    set : SetMsg;

  BEGIN
    WITH
      message : B.PressedMsg DO
        CASE message.source.id OF
          okId:
            d.color:=d.tmpColor;
            d.Close;
            NEW(set);
            set.color:=d.color;
            d.Send(set,setMsg);
        | cancelId:
            d.Close;
        ELSE
          d.tmpColor:=message.source.id;
          d.current.SetColor(d.tmpColor);
        END;
    | message : W.CloseMsg DO
        d.Close;
    ELSE
      d.Receive^(message);
    END;
  END Receive;

  PROCEDURE (d : ColSelDlg) SetColor*(color : LONGINT);

  BEGIN
    d.color:=color;
  END SetColor;

END VO:Dlg:ColSel.