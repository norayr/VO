MODULE VO:Prefs:Slider;

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
       I   := VO:Base:Image,
       Z   := VO:Base:Size,

       GP  := VO:Prefs:Object,
       PP  := VO:Prefs:Parser,

       S   := VO:Slider;

TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;
    d.SetName("Slider");

    d.SetPrefs(S.prefs);
  END Init;

  PROCEDURE (p : Item) LoadTheme*(top : PP.Item);

  VAR
    sub : PP.Item;

  BEGIN
    p.LoadTheme^(top);

    F.LoadFrame("boxFrame",top,S.prefs.boxFrame);

    Z.LoadSize("hSpace",top,S.prefs.hSpace);
    Z.LoadSize("vSpace",top,S.prefs.vSpace);

    sub:=top.GetEntry("Horizontal");
    IF sub#NIL THEN
      I.LoadImage(sub,"image",S.prefs.hKnob);
      BG.LoadBackground(sub,"background",S.prefs.hFill);
    END;


    sub:=top.GetEntry("Vertical");
    IF sub#NIL THEN
      I.LoadImage(sub,"image",S.prefs.vKnob);
      BG.LoadBackground(sub,"background",S.prefs.vFill);
    END;
  END LoadTheme;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:Slider.