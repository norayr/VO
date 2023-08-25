(**
   The preferences program of VisualOberon.

   All configuration of the GUI can be done, using this program.
**)

MODULE VisualPrefs;

(*
   The preferences program of VisualOberon.
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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
<* POP *>
       PG  := VO:Prefs:GUI,

              Err,RT0;

BEGIN
  RT0.poisonHeap:=MAX(LONGINT);

  IF ~Probe.OpenDisplay("VisualPrefs") THEN
    Err.String("Cannot init application!"); Err.Ln;
    HALT(1);
  END;

  PG.ShowSettings(NIL);

  D.display.Close;
END VisualPrefs.