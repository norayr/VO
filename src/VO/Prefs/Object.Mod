MODULE VO:Prefs:Object;

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

       PG  := VO:Prefs:GUI,
       PP  := VO:Prefs:Parser,

       G   := VO:Object;

TYPE
  PrefsItem*     = POINTER TO PrefsItemDesc;
  PrefsItemDesc* = RECORD (PG.PrefsItemDesc)
                     prefs : G.Prefs;
                   END;

  PROCEDURE (d : PrefsItem) Init*;

  BEGIN
    d.Init^;
    d.SetName("Object");
  END Init;

  PROCEDURE (d : PrefsItem) SetPrefs*(prefs : G.Prefs);

  BEGIN
    d.prefs:=prefs;
  END SetPrefs;

  PROCEDURE (p : PrefsItem) LoadTheme*(top : PP.Item);

  BEGIN
    p.LoadTheme^(top);

    F.LoadFrame("frame",top,p.prefs.frame);
    BG.LoadBackground(top,"normal",p.prefs.background);
    Z.LoadSize("hSize",top,p.prefs.hSize);
    Z.LoadSize("vSize",top,p.prefs.vSize);
  END LoadTheme;

END VO:Prefs:Object.