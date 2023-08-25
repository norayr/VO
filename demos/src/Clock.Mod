MODULE Clock;

(**
  A demo for the VO:Clock class. This little clock is really useable and
  was used by the author as part of his fvwm2 button pannel.
*)

(*
    Demo for VisualOberon. Shows the current time.
    Copyright (C) 1997 Tim Teulings (rael@edge.ping.de)

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

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)

       X1  := VO:VGD:All,
<* POP *>
              VO:VGD:VGD,

       W   := VO:Window,

              Err;


VAR
  w        : W.Window;
  msg2Exit : D.Msg2Exit;

  desc     : VGD.VGD;
  context  : VGD.Context;

BEGIN
  IF ~Probe.OpenDisplay("Clock") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  desc:=VGD.LoadVGD("Clock.vgd");
  IF desc=NIL THEN
    Err.String("Cannot load GUI description file"); Err.Ln;
    D.display.Close;
    HALT(1);
  END;

  NEW(w);
  w.Init;

  NEW(context);
  context.Init;
  IF ~VGD.LoadWindow(w,desc,"Main",context) THEN
    Err.String("Error: Cannot instantiate windows from vgd file!");
    Err.Ln;
    context.DumpErrors;
    HALT(1);
  END;

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
  END;

  D.display.Close;
END Clock.