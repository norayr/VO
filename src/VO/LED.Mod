MODULE VO:LED;

  (**
    Implements @otype{LED}.
  *)

  (*
    Implements a simple led with two states: on and off.
    Copyright (C) 1997 Tim Teulings (rael@edge.ping.de)

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

IMPORT S  := VO:State,
       I  := VO:Base:Image,
       VI := VO:Base:VecImage;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (S.PrefsDesc)
               END;

  LED*     = POINTER TO LEDDesc;
  LEDDesc* = RECORD (S.StateDesc)
               (**
                 Implements a read-only two state (on/off) LED. Similar
                 to a read-only bool object.

                 Its expects an bool model as model.
               *)
             END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.image:=I.CreateVecImage(VI.led);
  END Initialize;

  PROCEDURE (l : LED) Init*;

  BEGIN
    l.Init^;

    l.Disable(TRUE);
    l.SetPrefs(prefs);
    (* We do that for stopping interactive toggling via keyboard or mouse *)
  END Init;

  PROCEDURE CreateLED*():LED;

    (**
      Creates a new instance of @otype{LED}.
    *)

  VAR
    led : LED;

  BEGIN
    NEW(led);
    led.Init;

    RETURN led;
  END CreateLED;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:LED.