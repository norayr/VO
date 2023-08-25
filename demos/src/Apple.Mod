(**
  Draws an "Apfelmännchen".
**)

MODULE Apple;

(*
    Demo for VisualOberon. Checks correctnes of some drawing primitives.
    Copyright (C) 2002 Tim Teulings (rael@edge.ping.de)

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

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>

       G   := VO:Object,
       O   := VO:Base:Object,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              Err,            (* Simple error IO *)
              RT0;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  Apple*     = POINTER TO AppleDesc;
  AppleDesc* = RECORD (G.ImageDesc)
                 timer   : D.Timer;
               END;

  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  prefs    : Prefs;

  w        : Window;       (* The window *)

  msg2Exit : D.Msg2Exit;     (* a simple message converter *)

  PROCEDURE (d : Apple) Init*;

  BEGIN
    d.Init^;

    d.SetPrefs(prefs);

    d.timer:=D.factory.CreateTimer();
    d.timer.SetSecs(0,500);
    d.timer.SetObject(d);
  END Init;

  PROCEDURE (d : Apple) CalcSize*;

  BEGIN
    d.width:=300;
    d.height:=200;

    d.minWidth:=10;
    d.minHeight:=10;

    d.CalcSize^;
  END CalcSize;

  PROCEDURE (d : Apple) Check(re, im : LONGREAL):LONGINT;

  VAR
    reZ,imZ,
    reZOld,imZOld : LONGREAL;
    x             : LONGINT;

  BEGIN
    reZ:=0.0;
    imZ:=0.0;
    reZOld:=0.0;
    imZOld:=0.0;

    x:=0;
    FOR x:=0 TO 29 DO
      imZ:=2*reZOld*imZOld+im;
      reZ:=reZOld*reZOld-imZOld*imZOld+re;

      IF (reZ*imZ+imZ*imZ>4.0) THEN
        RETURN x;
      END;

      reZOld:=reZ;
      imZOld:=imZ;
    END;

    RETURN x;
  END Check;

  PROCEDURE (d : Apple) Calculate;

  VAR
    draw   : D.DrawInfo;
    re,im,
    hZelle,
    vZelle  : LONGREAL;
    a,b,res : LONGINT;

  BEGIN
    draw:=d.GetDrawInfo();

    hZelle:=(1.65-(-1.1))/d.width;
    vZelle:=(0.0875-(-2.1))/d.height;

    im:=-1.1;

    draw.PushForeground(D.blackColor);
    FOR b:=0 TO d.height-1 DO
      re:=-2.1;
      FOR a:=0 TO d.width-1 DO
        res:=d.Check(re,im);
        IF (res=30) THEN
          draw.DrawPoint(d.x+a,d.y+b);
        END;

        re:=re+hZelle;
      END;
      im:=im+vZelle;
    END;
    draw.PopForeground;
  END Calculate;

  PROCEDURE (d : Apple) Draw*(x,y,w,h : LONGINT);

  BEGIN
    d.Draw^(x,y,w,h);

    IF ~d.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    IF d.timer.active THEN
      D.display.RemoveTimer(d.timer);
    END;
    D.display.AddTimer(d.timer);

    d.DrawBackground(d.x,d.y,d.width,d.height);
  END Draw;

  PROCEDURE (d : Apple) Hide*;

  BEGIN
    IF d.timer.active THEN
      D.display.RemoveTimer(d.timer);
    END;
    IF d.visible THEN
      d.Hide^;
    END;
  END Hide;

  PROCEDURE (d : Apple) Receive*(msg : O.Message);

  BEGIN
    WITH msg:
      D.TimerMsg DO
      IF d.visible THEN
        d.Calculate;
      END;
    ELSE
    END;
  END Receive;

  PROCEDURE (w : Window) PreInit*;

  VAR
    test   : Apple;
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
    test.SetFlags({G.horizontalFlex,G.verticalFlex});

    wGroup.Set(NIL,test,TRUE);

    (* Set the top object of the window to the window group *)
    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

BEGIN
  RT0.poisonHeap:=MAX(LONGINT);

  NEW(prefs);
  prefs.Init;

  (*
    Try to initialize it.
    This call make the connection to the X server and allocates
    fonts, colors and that stuff
  *)
  IF ~Probe.OpenDisplay("Apple") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("Apple");

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
END Apple.