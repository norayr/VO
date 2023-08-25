(**
  A little program to demonstrate our small doom engine.
**)

MODULE Doom;

(*
    A little program to demonstrate our small doom engine.
    Copyright (C) 1998 Tim Teulings (rael@edge.ping.de)

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
       Z   := VO:Base:Size,

              VO:Prefs:All,  (* Include preferences for all objects *)

       DM  := VO:Doom,
       G   := VO:Object,
       W   := VO:Window,

              Err;

VAR
  w        : W.Window;

  doom     : DM.Doom;

  msg2Exit : D.Msg2Exit;

BEGIN
  D.display.SetAppName("Doom");
  IF ~D.display.Open() THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  NEW(doom);
  doom.Init;
  doom.SetFlags({G.horizontalFlex,G.verticalFlex});
  doom.SetWidth(Z.unit,100);
  doom.SetHeight(Z.unit,100);

  NEW(w);
  w.Init;
  w.SetTop(doom);
  w.SetTitle("Doom");
  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
  END;

  D.display.Close;
END
Doom.