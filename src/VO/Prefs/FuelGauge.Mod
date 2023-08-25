MODULE VO:Prefs:FuelGauge;

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

IMPORT BG  := VO:Base:Background,
       F   := VO:Base:Frame,
       I   := VO:Base:Image,
       Z   := VO:Base:Size,

       GP  := VO:Prefs:Object,
       PP  := VO:Prefs:Parser,

       FG  := VO:FuelGauge;


TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;
    d.SetName("FuelGauge");

    d.SetPrefs(FG.prefs);
  END Init;

  PROCEDURE (p : Item) LoadTheme*(top : PP.Item);

  VAR
    sub : PP.Item;

  BEGIN
    p.LoadTheme^(top);

    Z.LoadSize("width",top,FG.prefs.width);
    Z.LoadSize("height",top,FG.prefs.height);

    sub:=top.GetEntry("Horizontal");
    IF sub#NIL THEN
      I.LoadImage(sub,"image",FG.prefs.hImage);
      BG.LoadBackground(sub,"background",FG.prefs.hBackground);
      F.LoadFrame("frame",sub,FG.prefs.hFrame);
    END;

    sub:=top.GetEntry("Vertical");
    IF sub#NIL THEN
      I.LoadImage(sub,"image",FG.prefs.vImage);
      BG.LoadBackground(sub,"background",FG.prefs.vBackground);
      F.LoadFrame("frame",sub,FG.prefs.vFrame);
    END;

  END LoadTheme;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:FuelGauge.