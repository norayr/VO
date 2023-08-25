MODULE DisplayInfo;

  (**
    Small program that show some information about the active display.
  *)


(*
    Demo for VisualOberon. Shows information about active display.
    Copyright (C) 2004 Tim Teulings (rael@edge.ping.de)

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

       L   := VO:Label,
       T   := VO:Text,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              Err,           (* Simple error IO *)
              IntStr;

TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  w : Window;       (* The window *)

  PROCEDURE (w : Window) PreInit*;

  VAR
    label  : L.Label;
    wGroup : WG.WindowGroup; (* The window group *)
    buffer : ARRAY 1024 OF CHAR;

  BEGIN
    (*
      Allocate an instance of the window group class.
      This group handles positioning of menustrip and window contents.
    *)
    wGroup:=WG.CreateWindowGroup();

    label:=L.CreateLabel();

    label.AddStringLabel("Driver",T.MakeLeftString(D.display.driverName));

    CASE D.display.displayType OF
      D.displayTypeTextual:
      label.AddStringLabel("Display type",T.MakeLeftString("textual"));
    | D.displayTypeGraphical:
      label.AddStringLabel("Display type",T.MakeLeftString("graphical"));
    END;

    IntStr.IntToStr(D.display.scrWidth,buffer);
    label.AddStringLabel("Screen width",T.MakeLeftText(buffer));
    IntStr.IntToStr(D.display.scrHeight,buffer);
    label.AddStringLabel("Screen height",T.MakeLeftText(buffer));

    CASE D.display.colorMode OF
      D.monochromeMode:
      label.AddStringLabel("Color mode",T.MakeLeftText("monochrome"));
    | D.greyScaleMode:
      label.AddStringLabel("Color mode",T.MakeLeftText("grey scale"));
    | D.colorMode:
      label.AddStringLabel("Color mode",T.MakeLeftText("color"));
    END;

    IntStr.IntToStr(D.display.colorDepth,buffer);
    label.AddStringLabel("Color depth",T.MakeLeftText(buffer));

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
  IF ~Probe.OpenDisplay("DisplayInfo") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("DisplayInfo");

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
END DisplayInfo.