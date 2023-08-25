(**
**)

MODULE HeaderTest;

(*
    Demo for VisualOberon. Checks correctness of header object.
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

       A   := VO:Model:Adjustment,
       HM  := VO:Model:Header,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>

       G   := VO:Object,
       H   := VO:Header,
       P   := VO:Panel,
       S   := VO:Scroller,
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
    header     : H.Header;
    model      : HM.AHeaderModel;
    panel      : P.Panel;
    scroller   : S.Scroller;
    adjustment : A.Adjustment;
    wGroup     : WG.WindowGroup; (* The window group *)

  BEGIN
    (*
      Allocate an instance of the window group class.
      This group handles positioning of menustrip and window contents.
    *)
    wGroup:=WG.CreateWindowGroup();

      panel:=P.CreateVPanel();
      panel.SetFlags({G.horizontalFlex});

        NEW(adjustment);
        adjustment.Init;
(*        adjustment.SetTotal(100);
      adjustment.SetVisible(50);*)
        adjustment.SetTop(1);

        scroller:=S.CreateHScroller();
        scroller.SetFlags({G.horizontalFlex});
        scroller.SetModel(adjustment);
        (*w.AddFocusObject(scroller);*)
      panel.Add(scroller);

        NEW(model);
        model.Init;
        model.SetLabel(0,"Spalte 1");
        model.SetLabel(1,"Spalte 2");
        model.SetLabel(2,"Spalte 3");
        model.SetLabel(3,"Spalte 4");
        model.SetLabel(4,"Spalte 5");
        model.SetLabel(5,"Spalte 6");

        header:=H.CreateHeader();
        header.SetWidth(Z.unit,50);
        header.SetFlags({G.horizontalFlex});
        header.SetModel(model);
        header.SetAdjustment(adjustment);
      panel.Add(header);
    wGroup.Set(NIL,panel,TRUE);

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
  IF ~Probe.OpenDisplay("HeaderTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("HeaderTest");

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
END HeaderTest.