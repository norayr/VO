(**
    Demo for VisualOberon. Shows a list of all available fonts.
    Note, that the fontlist may differ from the OS fontlist, because
    VisualOberon may do some filtering.
**)

MODULE FontList;

(*
    Demo for VisualOberon. Shows list of all available fonts.
    Copyright (C) 1998  Tim Teulings (rael@edge.ping.de)

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
       Z   := VO:Base:Size,

       SM  := VO:Model:Selection,
       TM  := VO:Model:Table,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>

       G   := VO:Object,
       P   := VO:Panel,
       T   := VO:Table,
       W   := VO:Window,

              Err;

TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
                 model : TM.ASTableModel;
               END;

VAR
  w : Window;

  PROCEDURE GetFontList(model : TM.ASTableModel);

  VAR
    fontList      : D.FontList;
    foundry       : D.FontFoundry;
    family        : D.FontFamily;
    encoding      : D.FontEncoding;

    fontCount     : LONGINT;

  BEGIN
    fontList:=D.display.GetFontList();

    fontCount:=0;
    family:=fontList.families;
    WHILE family#NIL DO
      foundry:=family.foundries;
      WHILE foundry#NIL DO
        encoding:=foundry.encodings;
        WHILE encoding#NIL DO
          INC(fontCount);
          encoding:=encoding.next;
        END;
        foundry:=foundry.next;
      END;
      family:=family.next;
    END;

    model.SetSize(3,fontCount);
    model.SetLabel(1,"Foundry");
    model.header.SetLabelSize(0,Z.stdCharWidth,20);
    model.SetLabel(2,"Family");
    model.header.SetLabelSize(1,Z.stdCharWidth,20);
    model.SetLabel(3,"Encoding");
    model.header.SetLabelSize(2,Z.stdCharWidth,15);

    fontCount:=0;
    family:=fontList.families;
    WHILE family#NIL DO
      foundry:=family.foundries;
      WHILE foundry#NIL DO
        encoding:=foundry.encodings;
        WHILE encoding#NIL DO
          model.SetString(1,fontCount+1,foundry.name^);
          model.SetString(2,fontCount+1,family.name^);
          model.SetString(3,fontCount+1,encoding.encoding^);

          INC(fontCount);
          encoding:=encoding.next;
        END;
        foundry:=foundry.next;
      END;
      family:=family.next;
    END;
  END GetFontList;

  PROCEDURE (w : Window) PreInit*;

  VAR
    panel : P.Panel;
    table : T.Table;

  BEGIN
    NEW(panel);
    panel.Init;
    panel.Set(P.horizontal);
    panel.SetFlags({G.horizontalFlex,G.verticalFlex});

      NEW(w.model);
      w.model.Init;
      GetFontList(w.model);

      NEW(table);
      table.Init;
      table.SetFlags({G.horizontalFlex,G.verticalFlex});
      table.SetWidth(Z.unit,100);
      table.SetHeight(Z.unit,50);
      table.RequestFocus();
      table.SetShowHeader(TRUE);
      table.SetModel(w.model);

    w.model.SetSelection(SM.CreateSingleLine());
    panel.Add(table);

    w.SetTop(panel);

    w.PreInit^;
  END PreInit;

BEGIN
  IF ~Probe.OpenDisplay("FontList") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  NEW(w);
  w.Init;
  w.SetTitle("FontList");

  w.Forward(W.closeMsg,w);

  IF w.Open() THEN
    w.EventLoop;
  END;

  D.display.Close;
END FontList.