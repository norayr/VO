(**
  Visualizes the VODrawTest object. The object draws some drawing primites
  together with some test markes to see if the primitives are positioned
  and sized correctly.
**)

MODULE DrawTest;

(*
    Demo for VisualOberon. Checks correctnes of some drawing primitives.
    Copyright (C) 1999  Tim Teulings (rael@edge.ping.de)

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

              VO:OS:Probe,

              VO:Prefs:All,  (* Include preferences for all objects *)

       G   := VO:Object,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              Err;           (* Simple error IO *)

TYPE
  DrawTest*     = POINTER TO DrawTestDesc;
  DrawTestDesc* = RECORD (G.ImageDesc)
                  END;

  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  w        : Window;       (* The window *)

  msg2Exit : D.Msg2Exit;     (* a simple message converter *)

  PROCEDURE (d : DrawTest) Init*;

  BEGIN
    d.Init^;
  END Init;

  PROCEDURE (d : DrawTest) CalcSize*;

  BEGIN
    d.width:=120;
    d.height:=120;

    d.minWidth:=d.width;
    d.minHeight:=d.height;

    d.CalcSize^;
  END CalcSize;

  PROCEDURE (d : DrawTest) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~d.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    d.Draw^(x,y,w,h);

    draw:=d.GetDrawInfo();

    (* Lines *)
    d.DrawBackground(d.x,d.y,d.width,d.height);

    draw.PushForeground(D.whiteColor);
    draw.DrawLine(d.x+5,d.y,d.x+d.width-5-1,d.y);
    draw.DrawLine(d.x+d.width-5-1,d.y+1,d.x+5,d.y+1);
    draw.DrawLine(d.x,d.y+5,d.x,d.y+d.height-5-1);
    draw.DrawLine(d.x+1,d.y+d.height-5-1,d.x+1,d.y+5);
    draw.PopForeground;

    draw.PushForeground(D.blackColor);
    draw.DrawPoint(d.x+5,d.y+2);
    draw.DrawPoint(d.x+d.width-5-1,d.y+2);
    draw.DrawPoint(d.x+2,d.y+5);
    draw.DrawPoint(d.x+2,d.y+d.height-5-1);
    draw.PopForeground;

    (* Rectangle *)
    draw.PushForeground(D.whiteColor);
    draw.FillRectangle(d.x+10,d.y+10,100,100);
    draw.PopForeground;

    draw.PushForeground(D.blackColor);
    draw.DrawPoint(d.x+9,d.y+9);
    draw.DrawPoint(d.x+110,d.y+9);
    draw.DrawPoint(d.x+9,d.y+110);
    draw.DrawPoint(d.x+110,d.y+110);
    draw.PopForeground;

    (* Arc *)
    draw.PushForeground(D.blackColor);
    draw.FillArc(d.x+10,d.y+10,100,100,180*64,200*64);
    draw.PopForeground;

    (* Filled rectangle *)
    draw.PushBitmap(D.smallChess,D.fgPattern);
    draw.PushForeground(D.backgroundColor);
    draw.PushBackground(D.blackColor);
    draw.FillRectangle(d.x+35,d.y+35,50,50);
    draw.PopBackground;
    draw.PopForeground;
    draw.PopBitmap;

    draw.PushForeground(D.whiteColor);
    draw.DrawPoint(d.x+34,d.y+34);
    draw.DrawPoint(d.x+85,d.y+34);
    draw.DrawPoint(d.x+34,d.y+85);
    draw.DrawPoint(d.x+85,d.y+85);
    draw.PopForeground;

    (* Circle *)
    draw.PushForeground(D.whiteColor);
    draw.DrawArc(d.x+35,d.y+35,50,50,0,20*64);
    draw.PopForeground;
  END Draw;

  PROCEDURE (w : Window) PreInit*;

  VAR
    test   : DrawTest;
    wGroup : WG.WindowGroup; (* The window group *)

  BEGIN
    (*
      Allocate an instance of the window group class.
      This group handles positioning of menustrip and window contents.
    *)
    NEW(wGroup);

    (* Every instance must be initialized *)
    wGroup.Init;

      NEW(test);
      test.Init;

    wGroup.Set(NIL,test,TRUE);

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

  IF ~Probe.OpenDisplay("DrawTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("DrawTest");

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
END DrawTest.