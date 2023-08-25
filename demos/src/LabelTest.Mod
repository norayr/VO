MODULE LabelTest;

  (**
    Small demo program for demonstartion and testing VO:Label.
  *)


(*
    Demo for VisualOberon. Shows/tests VO:Label.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

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
       Z   := VO:Base:Size,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>

       C   := VO:ColorArea,
       G   := VO:Object,
       L   := VO:Label,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              Err;           (* Simple error IO *)

TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  w : Window;       (* The window *)

  PROCEDURE (w : Window) PreInit*;

  VAR
    color  : C.ColorArea;
    label  : L.Label;
    wGroup : WG.WindowGroup; (* The window group *)

  BEGIN
    (*
      Allocate an instance of the window group class.
      This group handles positioning of menustrip and window contents.
    *)
    wGroup:=WG.CreateWindowGroup();

      label:=L.CreateLabel();
      label.SetFlags({G.horizontalFlex,G.verticalFlex});

        color:=C.CreateColorArea();
        color.SetFlags({G.horizontalFlex,G.verticalFlex});
        color.SetMinWidth(Z.unit,10);
        color.SetMinHeight(Z.unit,30);
        color.SetColor(D.whiteColor);
      label.AddStringLabel("Label1",color);

        color:=C.CreateColorArea();
        color.SetFlags({G.verticalFlex});
        color.SetMinWidth(Z.unit,2);
        color.SetMinHeight(Z.unit,2);
        color.SetColor(D.whiteColor);
      label.AddStringLabel("Label2",color);

        color:=C.CreateColorArea();
        color.SetFlags({G.horizontalFlex});
        color.SetMinWidth(Z.unit,2);
        color.SetMinHeight(Z.unit,2);
        color.SetColor(D.whiteColor);
      label.AddStringLabel("Label3",color);

    wGroup.SetMain(label);

    (* Set the top object of the window to the window group *)
    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

BEGIN
  (*
    Try to initialize it.
    This call make the connection to the X server and allocates
    fonts, colors and that stuff
  *)
  IF ~Probe.OpenDisplay("LabelTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("LabelTest");

  w.Forward(W.closeMsg,w);

  (* Open the main window *)
  IF w.Open() THEN
    (*
      Start the main event loop. The event loop will get finished when
      the display receives a close message or its exit method gets called.
    *)
    w.EventLoop;
  END;
  w.Close;

  (* Free possible ressources of the display. *)
  D.display.Close;
END LabelTest.