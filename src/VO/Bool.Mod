MODULE VO:Bool;

(**
   Implements @otype{Bool}.
*)

(*
    Implements a bool gadget.
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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
       V  := VO:Base:VecImage,

       S  := VO:State;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (S.PrefsDesc)
               END;

  Bool*     = POINTER TO BoolDesc;
  BoolDesc* = RECORD (S.StateDesc)
                (**
                  A simple boolean button with a selected and an unselected state.
                  Also know as checkbox.
                *)
              END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.image:=I.CreateVecImage(V.simpleCheck);
    ELSE
      p.image:=I.CreateVecImage(V.w95Check);
    END;
  END Initialize;

  PROCEDURE (b : Bool) Init*;

  BEGIN
    b.Init^;

    b.SetPrefs(prefs);
  END Init;

  PROCEDURE CreateBool*(): Bool;

    (**
      Creates a new instance of @otype{Bool}.
    *)

  VAR
    bool : Bool;

  BEGIN
    NEW(bool);
    bool.Init;

    RETURN bool;
  END CreateBool;

BEGIN
  NEW(prefs);
  prefs.Init;

END VO:Bool.