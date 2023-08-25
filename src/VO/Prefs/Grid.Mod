MODULE VO:Prefs:Grid;

(*
    Copyright (C) 2000  Tim Teulings (rael@edge.ping.de)

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

       GP  := VO:Prefs:Object,
       PP  := VO:Prefs:Parser,

       G   := VO:Grid;

TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;
    d.SetName("Grid");

    d.SetPrefs(G.prefs);
  END Init;

  PROCEDURE (p : Item) LoadTheme*(top : PP.Item);

  BEGIN
    p.LoadTheme^(top);

    Z.LoadSize("hSpace",top,G.prefs.hSpace);
    Z.LoadSize("vSpace",top,G.prefs.vSpace);
  END LoadTheme;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:Grid.