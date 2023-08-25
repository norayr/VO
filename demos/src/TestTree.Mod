(**
    Demo for VisualOberon. Demonstrates the tree object.
**)

MODULE TestTree;

(*
    Demo for VisualOberon. Demonstrates the tree object.
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

       TM  := VO:Model:Tree,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)

       X1  := VO:VGD:All,
<* POP *>
              VO:VGD:VGD,

       G   := VO:Object,
       T   := VO:Tree,
       W   := VO:Window,

              Err;

VAR
  w        : W.Window;

  object   : G.Object;
  tree     : T.Tree;
  model    : TM.TreeModel;

  desc     : VGD.VGD;
  context  : VGD.Context;

  msg2Exit : D.Msg2Exit;

BEGIN
  IF ~Probe.OpenDisplay("TestTree") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  desc:=VGD.LoadVGD("TestTree.vgd");
  IF desc=NIL THEN
    Err.String("Cannot load GUI description file"); Err.Ln;
    D.display.Close;
    HALT(1);
  END;

  NEW(w);
  w.Init;

  NEW(context);
  context.Init;
  IF ~VGD.LoadWindow(w,desc,"Main",context) THEN
    Err.String("Error: Cannot instantiate window 'Main' from vgd file!");
    Err.Ln;
    context.DumpErrors;
    HALT(1);
  END;

  NEW(model);
  model.Init;
  model.SetTop(TM.CreateTextItem(model,"one"));
  model.top.AddChild(TM.CreateTextItem(model,"two"));
  model.top.firstChild.AddChild(TM.CreateTextItem(model,"two (a)"));
  model.top.firstChild.AddChild(TM.CreateTextItem(model,"two (b)"));
  model.top.firstChild.ShowChildren;
  model.top.AddChild(TM.CreateTextItem(model,"three"));
  model.top.ShowChildren;
  model.top.InsertAfter(TM.CreateTextItem(model,"four"));
  model.top.next.AddChild(TM.CreateTextItem(model,"five"));
  model.top.next.AddChild(TM.CreateTextItem(model,"six"));
  model.top.next.ShowChildren;
  model.top.next.InsertAfter(TM.CreateTextItem(model,"seven"));
  model.top.next.next.AddChild(TM.CreateTextItem(model,"eight"));
  model.top.next.next.AddChild(TM.CreateTextItem(model,"nine"));
  model.top.next.next.ShowChildren;
  model.top.next.next.InsertAfter(TM.CreateTextItem(model,"ten"));

  object:=w.top.GetObjectByName("Tree");
  tree:=object(T.Tree);
  tree.SetModel(model);

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
  END;

  D.display.Close;
END TestTree.