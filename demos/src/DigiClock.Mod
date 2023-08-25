MODULE DigiClock;

(**
  A demo for the VO:DigiClock class. This little clock is really useable and
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

IMPORT BG  := VO:Base:Background,
       D   := VO:Base:Display,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)

       X1  := VO:VGD:All,
<* POP *>
              VO:VGD:VGD,

       C   := VO:DigiClock,
       G   := VO:Object,
       W   := VO:Window,

              Err,
       L   := Locales;

VAR
  w        : W.Window;

  object   : G.Object;
  clock    : C.DigiClock;

  color    : D.Color;

  msg2Exit : D.Msg2Exit;

  desc     : VGD.VGD;
  context  : VGD.Context;

  old      : ARRAY 32 OF CHAR;

BEGIN
  IF ~Probe.OpenDisplay("DigiClock") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  L.Set(L.ALL,"",old);  (* use env variables *)

  desc:=VGD.LoadVGD("DigiClock.vgd");
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
    Err.String("Error: Cannot instantiate window from vgd file!");
    Err.Ln;
    context.DumpErrors;
    HALT(1);
  END;

  object:=w.top.GetObjectByName("Clock");
  clock:=object(C.DigiClock);

  D.display.AllocateNamedColor("green",D.textColor,color);
  clock.SetForeground(color);
  D.display.AllocateNamedColor("black",D.backgroundColor,color);
  clock.SetNumberBackground(color);
  clock.SetBackgroundObject(BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.blackColorIndex)));

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
  END;

  D.display.Close;
END DigiClock.