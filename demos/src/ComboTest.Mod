MODULE ComboTest;

  (**
    Demo of the various flavours of comboboxes (VO:Combo).
  *)

(*
    Demo for VisualOberon. Checks correctnes of some drawing primitives.
    Copyright (C) 2000  Tim Teulings (rael@edge.ping.de)

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

IMPORT D   := VO:Base:Display,     (* Display stuff *)

       TM  := VO:Model:Table,
       V   := VO:Model:Value,

              VO:OS:Probe,
<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)

       X1  := VO:VGD:All,
<* POP *>
              VO:VGD:VGD,

       C   := VO:Combo,
       G   := VO:Object,
       S   := VO:String,
       W   := VO:Window,      (* Window class *)

              Err;           (* Simple error IO *)


TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  w        : Window;       (* The window *)

  desc     : VGD.VGD;
  context  : VGD.Context;

  PROCEDURE (w : Window) PreInit*;

  VAR
    object : G.Object;
    combo  : C.Combo;
    model  : TM.LTableModel;
    string : V.ValueModel;
    int    : V.IntModel;
    entry  : TM.ListEntry;

  BEGIN
    NEW(model);
    model.Init;

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 1");
    model.AppendEntry(entry);

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 2");
    model.AppendEntry(entry);

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 3");
    model.AppendEntry(entry);

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 4");
    model.AppendEntry(entry);

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 5");
    model.AppendEntry(entry);

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 6");
    model.AppendEntry(entry);

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 7");
    model.AppendEntry(entry);

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 8");
    model.AppendEntry(entry);

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 9");
    model.AppendEntry(entry);

    entry:=TM.CreateListEntry(model);
    entry.SetStr(1,"Entry 10");
    model.AppendEntry(entry);

    string:=V.CreateStringModel();
    string.SetString("Bla");

    int:=V.CreateIntModel();
    int.SetLongint(3);

    object:=w.top.GetObjectByName("StringCombo");
    combo:=object(C.Combo);
    combo.value(S.String).SetModel(string);
    combo.SetTableModel(model);

    object:=w.top.GetObjectByName("TextCombo");
    combo:=object(C.Combo);
    combo.SetTableModel(model);
    combo.SetModel(int);

    w.PreInit^;
  END PreInit;

BEGIN
  (*
    Try to initialize it.
    This call make the connection to the X server and allocates
    fonts, colors and that stuff
  *)
  IF ~Probe.OpenDisplay("ComboTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  desc:=VGD.LoadVGD("ComboTest.vgd");
  IF desc=NIL THEN
    Err.String("Cannot load GUI description file"); Err.Ln;
    D.display.Close;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  NEW(context);
  context.Init;
  IF ~VGD.LoadWindow(w,desc,"Main",context) THEN
    Err.String("Error: Cannot instantiate window 'Main' from vgd file!");
    Err.Ln;
    context.DumpErrors;
    HALT(1);
  END;

  w.Forward(W.closeMsg,w);

  (* Open the main window *)
  IF w.Open() THEN
    (*
      Start the main event loop. The event loop will get finished when
      the display receives a close message or its exit method gets called.
    *)
    w.EventLoop;
  END;

  (* Free possible ressources of the display. *)
  D.display.Close;
END ComboTest.