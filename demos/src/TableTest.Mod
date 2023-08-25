MODULE TableTest;

  (**
    Demo for VisualOberon. Demonstrates the table object.
  *)

(*
    Demo for VisualOberon. Demonstrates the table object.
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
       F   := VO:Base:Frame,
       O   := VO:Base:Object,
       VB  := VO:Base:VecImage,
       Z   := VO:Base:Size,

       SM  := VO:Model:Selection,
       TM  := VO:Model:Table,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)

<* POP *>
       B   := VO:Button,
       G   := VO:Object,
       T   := VO:Table2,
       TV  := VO:TableView2,
       W   := VO:Window,
       WG  := VO:WindowGroup,

              Err;

TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
                 insert,
                 delete  : B.Button;
                 model   : TM.LTableModel;
               END;

VAR
  w : Window;

  (*
  PROCEDURE (w : Window) Receive*(message : O.Message);

  VAR
    entry : TM.ListEntry;

  BEGIN
    WITH
      message : B.PressedMsg DO
        IF message.source=w.insert THEN
          entry:=TM.CreateListEntry(w.model);
          entry.SetStr(1,"Added");
          w.model.AppendEntry(entry);
        ELSIF message.source=w.delete THEN
          IF w.model.selection(SM.SingleLine).line>0 THEN
            w.model.DeleteEntry(w.model.selection(SM.SingleLine).line);
          END;
        END;
        RETURN;
    ELSE
      w.Receive^(message);
    END;
  END Receive;
*)
  PROCEDURE (w : Window) PreInit*;

  VAR
    wGroup : WG.WindowGroup;
    view   : T.Table;
    model1 : TM.TestTable;
    model2 : TM.ASTableModel;
    model3 : TM.LTableModel;
    entry  : TM.ListEntry;
    model  : TM.TableModel;
    x      : LONGINT;
    table  : TV.Table;

  BEGIN
    wGroup:=WG.CreateWindowGroup();

    NEW(model1);
    model1.Init;
    model1.SetSelection(SM.CreateSingleCell());

    NEW(model2);
    model2.Init;
    model2.SetSize(5,2);
    model2.SetColumnString(1,"\ebTestcolumn\en\n\esone");
    model2.SetColumnString(2,"\ebTestcolumn\en\n\estwo");
    model2.SetColumnString(3,"\ebTestcolumn\en\n\esthree");
    model2.SetColumnString(4,"\ebTestcolumn\en\n\esfour");
    model2.SetColumnString(5,"\ebTestcolumn\en\n\esfive");
    model2.SetStr(1,1,"(1,1)");
    model2.SetStr(2,1,"(2,1)");
    model2.SetStr(3,1,"(3,1)");
    model2.SetStr(4,1,"(4,1)");
    model2.SetStr(5,1,"(5,1)");
    model2.SetStr(1,2,"(1,2)");
    model2.SetStr(2,2,"(2,2)");
    model2.SetSelection(SM.CreateSingleLine());

    NEW(model3);
    model3.Init;
    w.model:=model3;
    model3.SetSelection(SM.CreateSingleLine());

    model3.SetColumnString(1,"Column");

    FOR x:=0 TO 100 DO
      entry:=TM.CreateListEntry(model3);
      entry.SetStr(1,"(1,1)");
      model3.AppendEntry(entry);
    END;

    model:=model1;

    view:=T.CreateTable();
    view.SetFlags({G.horizontalFlex,G.verticalFlex});
    view.SetMinWidth(Z.screenHRel,50);
    view.SetMinHeight(Z.screenVRel,50);
    view.RequestFocus();

    table:=TV.CreateTable();
    view.SetCustomTable(table);

    view.SetModel(model);
    view.SetShowHeader(TRUE);

    wGroup.SetMain(view);
    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

BEGIN
  IF ~Probe.OpenDisplay("TestTable") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  NEW(w);
  w.Init;
  w.SetTitle("TableTest");
  w.Forward(W.closeMsg,w);

  IF w.Open() THEN
    w.EventLoop;
  END;

  D.display.Close;
END TableTest.