MODULE VO:Radio;

  (**
    Implements @otype{Radio}.
  *)

  (*
    Implements a radiobutton.
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

IMPORT D  := VO:Base:Display,
       I  := VO:Base:Image,

       S  := VO:State,
       V  := VO:Base:VecImage;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (S.PrefsDesc)
               END;

  Radio*     = POINTER TO RadioDesc;
  RadioDesc* = RECORD (S.StateDesc)
                 (**
                   A radio button.
                 *)
               END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.image:=I.CreateVecImage(V.simpleRadio);
    ELSE
      p.image:=I.CreateVecImage(V.w95Radio);
    END;
  END Initialize;

  PROCEDURE (r : Radio) Init*;

  BEGIN
    r.Init^;

    r.SetPrefs(prefs);
  END Init;

  PROCEDURE CreateRadio*():Radio;

  VAR
    radio : Radio;

  BEGIN
    NEW(radio);
    radio.Init;

    RETURN radio;
  END CreateRadio;

BEGIN
  NEW(prefs);
  prefs.Init;

END VO:Radio.
