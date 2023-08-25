MODULE Fire;

  (**
    A simple fire simulation.
  *)

(*
    Implements a simple fdire simulation.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

    This module is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with VisualOberon. If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

IMPORT D   := VO:Base:Display,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,    (* The use the preferences setting *)
<* POP *>

       G   := VO:Object,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              Err,           (* Simple error IO *)
       r   := RandomNumbers;

CONST
  blinkPeriod = 20;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  Area       = ARRAY 200 OF ARRAY 200 OF INTEGER;

  Fire       = POINTER TO FireDesc;
  FireDesc   = RECORD (G.ImageDesc)
                 (**
                   A simple fire animation.
                 *)
                 timer   : D.Timer;
                 current : LONGINT;
                 up      : BOOLEAN;
                 bitmap  : D.Bitmap;
                 colors  : ARRAY 256 OF D.Color;
                 inited  : BOOLEAN;
                 area    : POINTER TO Area;
              END;

  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  prefs    : Prefs;
  w        : Window;         (* The window *)
  msg2Exit : D.Msg2Exit;     (* a simple message converter *)

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.frame:=F.CreateFrame(F.double3DIn);
  END Initialize;

  PROCEDURE (p : Fire) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.timer:=D.factory.CreateTimer();
    p.timer.SetSecs(0,blinkPeriod);
    p.timer.SetObject(p);

    p.current:=0;
    p.up:=TRUE;
    p.bitmap:=NIL;
    p.inited:=FALSE;
  END Init;

  PROCEDURE (p : Fire) CalcSize*;

  BEGIN
    p.width:=200;
    p.height:=200;

    p.minWidth:=p.width;
    p.minHeight:=p.height;

    p.maxWidth:=p.width;
    p.maxHeight:=p.height;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : Fire) DrawBox;

  VAR
    draw : D.DrawInfo;
    x,y,
    i,j  : LONGINT;
    c,g  : INTEGER;

  BEGIN
    IF ~p.inited THEN
      p.colors[0]:=D.blackColor;
      FOR c:=1 TO 255 DO
(*        D.display.AllocateColor16(c*256+10000,c*256,0,D.blackColor,p.colors[c]);*)
        D.display.AllocateColor16(c*256,(c DIV 2)*256,0,D.blackColor,p.colors[c]);
      END;

      NEW(p.area);

      FOR x:=0 TO 199 DO
        FOR y:=0 TO 199 DO
          p.area[x,y]:=0;
        END;
      END;

    FOR i:=0 TO 199 DO
      IF r.RND(2)=0 THEN
        p.area[i,0]:=255;
      ELSE
        p.area[i,0]:=64;
      END;
    END;

      p.inited:=TRUE;
    END;

    IF p.bitmap=NIL THEN
      p.bitmap:=D.display.CreateBitmap(p.width,p.height);
    END;

    IF p.bitmap#NIL THEN
      draw:=p.bitmap.draw;
      x:=0;
      y:=0;
    ELSE
      draw:=p.GetDrawInfo();
      x:=p.x;
      y:=p.y;
    END;

    <*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

    FOR i:=0 TO 199 DO
      FOR j:=0 TO 199 DO
        draw.DrawPointWithColor(x+i,y+199-j,p.colors[p.area[i,j]]);
      END;
    END;

    FOR j:=1 TO 199 DO (* all rows, but the first one *)
      FOR i:=1 TO 198 DO
        p.area[i,j]:=(p.area[i,j]+p.area[i-1,j-1]+p.area[i,j-1]+p.area[i+1,j-1]) DIV 4;
        IF (j MOD 50=0) & (p.area[i,j]>0) THEN
          DEC (p.area[i,j]);
        END;
      END;
    END;

    (* Fill new base line *)
    FOR i:=0 TO 199 DO
      IF r.RND(2)=0 THEN
        p.area[i,0]:=255;
      ELSE
        p.area[i,0]:=64;
      END;
    END;

    <* POP *>

    IF p.bitmap#NIL THEN
      draw:=p.GetDrawInfo();
      draw.CopyFromBitmap(p.bitmap,0,0,p.width,p.height,p.x,p.y);
    END;
  END DrawBox;

  PROCEDURE (p : Fire) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~p.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    p.Draw^(x,y,w,h);

    p.DrawBox;

    IF ~p.timer.active THEN
      D.display.AddTimer(p.timer);
    END;
  END Draw;

  PROCEDURE (p : Fire) Hide*;

  BEGIN
    IF p.timer.active THEN
      D.display.RemoveTimer(p.timer);
    END;

    IF p.visible THEN
      p.Hide^;
    END;
  END Hide;

  PROCEDURE (p : Fire) Receive*(msg : O.Message);

  BEGIN
    WITH msg: D.TimerMsg DO
      IF p.visible THEN
        p.DrawBox;
        D.display.AddTimer(p.timer);
      END;
    ELSE
    END;
  END Receive;

  PROCEDURE (f : Fire) Free*;

  BEGIN
    IF f.bitmap#NIL THEN
      D.display.FreeBitmap(f.bitmap);
    END;
  END Free;

  PROCEDURE CreateFire*():Fire;

  VAR
    fire : Fire;

  BEGIN
    NEW(fire);
    fire.Init;

    RETURN fire;
  END CreateFire;

  PROCEDURE (w : Window) PreInit*;

  VAR
    fire   : Fire;
    wGroup : WG.WindowGroup; (* The window group *)

  BEGIN
    (*
      Allocate an instance of the window group class.
     This group handles positioning of menustrip and window contents.
    *)
    NEW(wGroup);

    (* Every instance must be initialized *)
    wGroup.Init;
    wGroup.SetFlags({G.horizontalFlex,G.verticalFlex});

      fire:=CreateFire();

    wGroup.SetMain(fire);
    (* Set the top object of the window to the window group *)
    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

BEGIN
  NEW(prefs);
  prefs.Init;

  (*
    Try to initialize it.
    This call make the connection to the X server and allocates
    fonts, colors and that stuff
  *)
  IF ~Probe.OpenDisplay("Fire") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("Fire");

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
END Fire.