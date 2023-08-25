MODULE VO:Prefs:Array;

(*
    Copyright (C) 1999  Tim Teulings (rael@edge.ping.de)

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

IMPORT Z   := VO:Base:Size,

       PP  := VO:Prefs:Parser,
       GP  := VO:Prefs:Object,

       A   := VO:Array;


TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;
    d.SetName("Array");

    d.SetPrefs(A.prefs);
  END Init;

  PROCEDURE (p : Item) LoadTheme*(top : PP.Item);

  BEGIN
    p.LoadTheme^(top);

    Z.LoadSize("hSpace",top,A.prefs.hSpace);
    Z.LoadSize("vSpace",top,A.prefs.vSpace);
  END LoadTheme;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:Array.