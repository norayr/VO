(**
  A demo for the VOArray class. Shows all 256 keycodes in an array of buttons.
**)

MODULE CharacterTable;

(*
    Demo for VisualOberon. Shows the ascci-table.
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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

       V   := VO:Model:Value,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,
<* POP *>

       AR  := VO:Array,
       G   := VO:Object,
       P   := VO:Panel,
       S   := VO:Space,
       SL  := VO:Slider,
       T   := VO:Text,
       TA  := VO:Tab,
       W   := VO:Window,
       WG  := VO:WindowGroup,

              Ascii,
              Err;

TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
                 text  : ARRAY 256 OF T.Text;
                 lText : ARRAY 256 OF T.Text;
                 page  : V.IntModel;
               END;


VAR
  w        : Window;


  msg2Exit : D.Msg2Exit;

  i        : LONGINT;

  PROCEDURE (w : Window) SetAsciiText();

  VAR
    buff : ARRAY 2 OF CHAR;
    i    : LONGINT;
    char : CHAR;

  BEGIN
    FOR i:=0 TO 255 DO
      char:=CHR(i);
      CASE char OF (* we filter some of them :-) *)
        0X..01FX,07FX..09FX:
(*        Ascii.lf:*)
        char:=" ";
      ELSE
      END;

      buff[0]:=char;
      buff[1]:=0X;

      w.text[i].SetText(buff);
    END;
  END SetAsciiText;

  PROCEDURE (w : Window) SetUnicodeText();

  VAR
    buff : ARRAY 2 OF LONGCHAR;
    i    : LONGINT;
    char : LONGCHAR;

  BEGIN
    FOR i:=0 TO 255 DO
      char:=LONGCHR(i+w.page.GetLongint()*256);
      CASE char OF (* we filter some of them :-) *)
        0X..01FX,07FX..09FX:
(*        Ascii.lf:*)
          char:=" ";
      ELSE
      END;

      buff[0]:=char;
      buff[1]:=0X;

      w.lText[i].SetLongText(buff);
    END;
  END SetUnicodeText;

  PROCEDURE (w : Window) PreInit*;

  VAR
    array  : AR.Array;
    panel  : P.Panel;
    slider : SL.Slider;
    space  : S.Space;
    tab    : TA.Tab;
    wGroup : WG.WindowGroup;

  BEGIN
    NEW(w.page);
    w.page.Init;
    w.page.SetLongint(0);

    wGroup:=WG.CreateWindowGroup();

      tab:=TA.CreateTab();
      tab.SetFlags({G.horizontalFlex,G.verticalFlex});
      tab.RequestFocus();

        array:=AR.CreateArray();
        array.Set(16,TRUE);
        array.SetFlags({G.horizontalFlex,G.verticalFlex});

          FOR i:=0 TO 255 DO
            NEW(w.text[i]);
            w.text[i].Init;
            w.text[i].SetFlags({G.horizontalFlex,G.verticalFlex});
            w.text[i].SetDefault(T.leftAlligned,{},D.LargeFont);

(*        button.SetHelpObject(Q.InitHelp(d,T.MakeLeftText(buff2),button));*)
            array.Add(w.text[i]);
          END;

          w.SetAsciiText();

      tab.AddTab(T.MakeCenterText("ASCII"),array);

        panel:=P.CreateHPanel();
        panel.SetFlags({G.horizontalFlex,G.verticalFlex});

          slider:=SL.CreateVSlider();
          slider.SetFlags({G.verticalFlex});
          slider.RequestFocus();
          slider.SetModel(w.page);
          slider.SetRange(0,255);
          slider.Forward(SL.movedMsg,w);
        panel.Add(slider);

          space:=S.CreateHSpace();

        panel.Add(space);

          array:=AR.CreateArray();
          array.Set(16,TRUE);
          array.SetFlags({G.horizontalFlex,G.verticalFlex});

          FOR i:=0 TO 255 DO
            NEW(w.lText[i]);
            w.lText[i].Init;
            w.lText[i].SetFlags({G.horizontalFlex,G.verticalFlex});
            w.lText[i].SetDefault(T.leftAlligned,{},D.LargeFont);

(*        button.SetHelpObject(Q.InitHelp(d,T.MakeLeftText(buff2),button));*)
            array.Add(w.lText[i]);
          END;

          w.SetUnicodeText();

        panel.Add(array);

      tab.AddTab(T.MakeCenterText("Unicode"),panel);

    wGroup.Set(NIL,tab,TRUE);

    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

  PROCEDURE (w : Window) Receive*(message : O.Message);

  BEGIN
    WITH
      message : SL.MovedMsg DO
        w.SetUnicodeText();
        RETURN;
    ELSE
    END;
    w.Receive^(message);
  END Receive;

BEGIN
  IF ~Probe.OpenDisplay("CharacterTable") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  NEW(w);
  w.Init;
  w.SetTitle("Character-Table");

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
  END;

  D.display.Close;
END CharacterTable.