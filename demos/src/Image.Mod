MODULE Image;

  (**
    Shows how to use VO:Image:Image together with an in-memory image.
  *)

(*
    Demo for VO:Image:Image.
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

       I   := VO:Image:Image,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,    (* The use the preferences setting *)
<* POP *>

       G   := VO:Object,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              Err;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  Image       = POINTER TO ImageDesc;
  ImageDesc   = RECORD (G.ImageDesc)
                 (**
                   Demonstration for use of in-memory images.
                 *)
                  image : I.Image;
              END;

  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  prefs : Prefs;
  w     : Window;         (* The window *)

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.frame:=F.CreateFrame(F.double3DIn);
  END Initialize;

  PROCEDURE (p : Image) Init*;

  VAR
    data : I.Data;
    x,y  : LONGINT;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.image:=I.factory.CreateImage();
    NEW(data,256*256);

    FOR y:=0 TO 255 DO
      FOR x:=0 TO 255 DO
        data[y*256+x].r:=CHR(x);
        data[y*256+x].g:=CHR(255-y);
        data[y*256+x].b:=CHR(255-x);
        data[y*256+x].a:=CHR(0);
      END;
    END;
    p.image.SetData(256,256,FALSE,data);
  END Init;

  PROCEDURE (p : Image) CalcSize*;

  BEGIN
    p.width:=256;
    p.height:=256;

    p.minWidth:=p.width;
    p.minHeight:=p.height;

    p.maxWidth:=p.width;
    p.maxHeight:=p.height;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (i : Image) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~i.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    i.Draw^(x,y,w,h);

    IF i.image#NIL THEN
      draw:=i.GetDrawInfo();

      IF i.image.alpha THEN
        i.DrawBackground(x,y,w,h);
      END;

      i.image.Draw(i.GetDrawInfo(),i.x,i.y);
    END;
  END Draw;

  PROCEDURE CreateImage*():Image;

  VAR
    image : Image;

  BEGIN
    NEW(image);
    image.Init;

    RETURN image;
  END CreateImage;

  PROCEDURE (w : Window) PreInit*;

  VAR
    image  : Image;
    wGroup : WG.WindowGroup; (* The window group *)

  BEGIN
    (*
      Allocate an instance of the window group class.
     This group handles positioning of menustrip and window contents.
    *)
    NEW(wGroup);

    (* Every instance must be initialized *)
    wGroup.Init;

      image:=CreateImage();

    wGroup.SetMain(image);
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
  IF ~Probe.OpenDisplay("Image") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("Image");

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
END Image.