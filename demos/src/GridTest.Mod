(**
**)

MODULE GridTest;

(*
    Demo for VisualOberon. Checks correctness of grid object.
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
       Z   := VO:Base:Size,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>

       C   := VO:ColorArea,
       G   := VO:Object,
       GR  := VO:Grid,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              Err;           (* Simple error IO *)

TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  w        : Window;       (* The window *)

  msg2Exit : D.Msg2Exit;     (* a simple message converter *)

  PROCEDURE (w : Window) PreInit*;

  VAR
    color  : C.ColorArea;
    grid   : GR.Grid;
    wGroup : WG.WindowGroup; (* The window group *)

  BEGIN
    (*
      Allocate an instance of the window group class.
      This group handles positioning of menustrip and window contents.
    *)
    NEW(wGroup);

    (* Every instance must be initialized *)
    wGroup.Init;

      grid:=GR.CreateGrid();
      grid.SetFlags({G.horizontalFlex,G.verticalFlex});
      grid.SetSpace(TRUE,TRUE);

        color:=C.CreateColorArea();
        color.SetFlags({G.horizontalFlex,G.verticalFlex});
        color.SetMinWidth(Z.unit,10);
        color.SetMinHeight(Z.unit,30);
        color.SetColor(D.whiteColor);
      grid.SetObject(0,0,color);

        color:=C.CreateColorArea();
        color.SetFlags({G.verticalFlex});
        color.SetMinWidth(Z.unit,2);
        color.SetMinHeight(Z.unit,2);
        color.SetColor(D.whiteColor);
      grid.SetObject(1,0,color);

        color:=C.CreateColorArea();
        color.SetFlags({G.horizontalFlex});
        color.SetMinWidth(Z.unit,2);
        color.SetMinHeight(Z.unit,2);
        color.SetColor(D.whiteColor);
      grid.SetObject(0,1,color);
    wGroup.Set(NIL,grid,TRUE);

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
  IF ~Probe.OpenDisplay("GridTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("GridTest");

  (*
    Allocate an instance of this special message handler.
    A handler is a class that can convert any or a special
    input message to an other message and sends the resulting
    message to the given destination. However the baseclas just
    returns the input message.

    Most converters are handwritten, but some special converters are
    given by the corresponding objects.

    This converter converts the close-message generated when clicking
    the closing gadget of the window to an exist-message of the display
    class.
  *)
  NEW(msg2Exit);

  (*
    Send the resulting exit message to the display, which will finish
    the event loop and receiving.
  *)
  msg2Exit.destination:=D.display;

  (*
    Add the handler to window and tell the window that it should call
    this hndler when a close message gets send.
  *)
  w.AddHandler(msg2Exit,W.closeMsg);

  (* Open the main window *)
  IF w.Open() THEN
    (*
      Start the main event loop. The event loop will get finished when
      the display receives a close message or its exit method gets called.
    *)
    D.display.EventLoop;
  END;

  (* Free possible ressources of the display. *)
  D.display.Close;
END GridTest.