MODULE GameArea;

  (**
    A simple game area like it is use by some game types.
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
       E   := VO:Base:Event,
       F   := VO:Base:Frame,

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
  areaWidth     = 100;
  areaHeight    = 100;

  visibleWidth  = 16;
  visibleHeight = 12;

  cellWidth     = 36;
  cellHeight    = 36;

  xStep         = 12;
  yStep         = 12;


TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  Area       = ARRAY areaWidth+1 OF ARRAY areaHeight+1 OF INTEGER;

  GameArea       = POINTER TO GameAreaDesc;
  GameAreaDesc   = RECORD (G.GadgetDesc)
                     (**
                       A simple game area implementation.
                     *)
                     current  : LONGINT;
                     up       : BOOLEAN;
                     bitmap   : D.Bitmap;
                     patterns : ARRAY 256 OF D.Bitmap;
                     colors   : ARRAY 256 OF D.Color;
                     inited   : BOOLEAN;
                     area     : POINTER TO Area;
                     xOff,
                     yOff     : INTEGER;
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

  PROCEDURE (p : GameArea) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.RemoveFlags({G.stdFocus});

    p.current:=0;
    p.up:=TRUE;
    p.bitmap:=NIL;
    p.inited:=FALSE;
  END Init;

  PROCEDURE (p : GameArea) CalcSize*;

  BEGIN
    p.width:=visibleWidth*cellWidth;
    p.height:=visibleHeight*cellHeight;

    p.minWidth:=p.width;
    p.minHeight:=p.height;

    p.maxWidth:=p.width;
    p.maxHeight:=p.height;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : GameArea) DrawBox;

  VAR
    draw : D.DrawInfo;
    x,y,
    i,j  : LONGINT;
    c    : INTEGER;

  BEGIN
    IF ~p.inited THEN
      p.colors[0]:=D.blackColor;
      FOR c:=1 TO 255 DO
        D.display.AllocateColor16(SHORT(r.RND(256)*256),
                                  SHORT(r.RND(256)*256),
                                  SHORT(r.RND(256)*256),
                                  D.blackColor,
                                  p.colors[c]);
      END;

      NEW(p.area);
      FOR i:=0 TO areaWidth-1 DO
        FOR j:=0 TO areaHeight-1 DO
          p.area[i,j]:=SHORT(r.RND(256));
        END;
      END;
      p.area[0,0]:=0;

      p.xOff:=0;
      p.yOff:=0;

      p.bitmap:=D.display.CreateBitmap(p.width,p.height);

      FOR c:=0 TO 255 DO
        p.patterns[c]:=D.display.CreateBitmap(cellWidth,cellHeight);
        IF p.patterns[c]#NIL THEN
          draw:=p.patterns[c].draw;
          draw.PushForeground(p.colors[c]);
          draw.FillRectangle(0,0,cellWidth,cellHeight);
          draw.PopForeground;
        END;
      END;

      p.inited:=TRUE;
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

    IF p.patterns[0]#NIL THEN (* We assume, that we good all Bitmaps *)
      FOR i:=0 TO visibleWidth DO
        FOR j:=0 TO visibleHeight DO
          (* The bitmap does the clipping for us! *)
          draw.CopyFromBitmap(p.patterns[p.area[i+(p.xOff DIV cellWidth),j+(p.yOff DIV cellHeight)]],
                              0,0,cellWidth,cellHeight,
                              x+i*cellWidth-(p.xOff MOD cellWidth),
                              y+j*cellHeight-(p.yOff MOD cellHeight));
        END;
      END;
    ELSE
      FOR i:=0 TO visibleWidth DO
        FOR j:=0 TO visibleHeight DO
          draw.PushForeground(p.colors[p.area[i+(p.xOff DIV cellWidth),j+(p.yOff DIV cellHeight)]]);
          draw.FillRectangle(x+i*cellWidth-p.xOff MOD cellWidth,
                             y+j*cellHeight-p.yOff MOD cellHeight,
                             cellWidth,cellHeight);
          draw.PopForeground;
        END;
      END;
    END;

    IF p.bitmap#NIL THEN
      draw:=p.GetDrawInfo();
      draw.CopyFromBitmap(p.bitmap,0,0,p.width,p.height,p.x,p.y);
    END;
  END DrawBox;

  PROCEDURE (p : GameArea) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~p.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    p.Draw^(x,y,w,h);

    p.DrawBox;
  END Draw;

  PROCEDURE (p : GameArea) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  BEGIN
    IF event.type=E.keyDown THEN
      CASE event.key OF
        E.left:
        IF p.xOff-xStep>=0 THEN
          DEC(p.xOff,xStep);
        END;

        p.DrawBox;
        RETURN TRUE;
      | E.right:
        IF p.xOff+xStep+visibleWidth*cellWidth<=areaWidth*cellWidth THEN
          INC(p.xOff,xStep);
        END;

        p.DrawBox;
        RETURN TRUE;
      | E.up:
        IF p.yOff-yStep>=0 THEN
          DEC(p.yOff,yStep);
        END;

        p.DrawBox;
        RETURN TRUE;
      | E.down:
        IF p.yOff+yStep+visibleHeight*cellHeight<=areaHeight*cellHeight THEN
          INC(p.yOff,yStep);
        END;

        p.DrawBox;
        RETURN TRUE;
      ELSE
      END;
    END;
    RETURN FALSE;
  END HandleKeyEvent;

  PROCEDURE (f : GameArea) Free*;

  VAR
    x : LONGINT;

  BEGIN
    FOR x:=0 TO 255 DO
      IF f.patterns[x]#NIL THEN
        D.display.FreeBitmap(f.patterns[x]);
      END;
    END;

    IF f.bitmap#NIL THEN
      D.display.FreeBitmap(f.bitmap);
    END;
  END Free;

  PROCEDURE CreateGameArea*():GameArea;

  VAR
    fire : GameArea;

  BEGIN
    NEW(fire);
    fire.Init;

    RETURN fire;
  END CreateGameArea;

  PROCEDURE (w : Window) PreInit*;

  VAR
    gameArea   : GameArea;
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

      gameArea:=CreateGameArea();
      gameArea.SetFlags({G.horizontalFlex,G.verticalFlex});
      gameArea.RequestFocus();

    wGroup.Set(NIL,gameArea,TRUE);
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
  IF ~Probe.OpenDisplay("GameArea") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("GameArea");

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
END GameArea.