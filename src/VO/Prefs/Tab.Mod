MODULE VO:Prefs:Tab;

(*
    Copyright (C) 1999 Tim Teulings (rael@edge.ping.de)

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

IMPORT BG  := VO:Base:Background,
       F   := VO:Base:Frame,
       Z   := VO:Base:Size,

       GP  := VO:Prefs:Object,
       PP  := VO:Prefs:Parser,

       T   := VO:Tab;

TYPE
  PrefsItem*     = POINTER TO PrefsItemDesc;
  PrefsItemDesc* = RECORD (GP.PrefsItemDesc)
                   END;

VAR
  prefs : PrefsItem;

  PROCEDURE (d : PrefsItem) Init*;

  BEGIN
    d.Init^;
    d.SetName("Tab");

    d.SetPrefs(T.prefs);
  END Init;

  PROCEDURE (p : PrefsItem) LoadTheme*(top : PP.Item);

  BEGIN
    BG.LoadBackground(top,"riderBackground",T.prefs.riderBackground);
    BG.LoadBackground(top,"riderSelectBackground",T.prefs.riderSelectBackground);

    F.LoadFrame("riderFrame",top,T.prefs.riderFrame);
    Z.LoadSize("riderHSpace",top,T.prefs.riderHSpace);
    Z.LoadSize("riderVSpace",top,T.prefs.riderVSpace);

    T.prefs.hilightSelection:=top.GetBoolEntry("hilightSelection",T.prefs.hilightSelection);
    T.prefs.hilightActive:=top.GetBoolEntry("hilightActive",T.prefs.hilightActive);
    T.prefs.hilightActiveFrame:=top.GetBoolEntry("hilightActiveFrame",T.prefs.hilightActiveFrame);
  END LoadTheme;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:Tab.