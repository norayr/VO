MODULE VO:Prefs:Button;

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
       Z   := VO:Base:Size,

       GP  := VO:Prefs:Object,
       PP  := VO:Prefs:Parser,

       B   := VO:Button;

TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;

    d.SetName("Button");

    d.SetPrefs(B.prefs);
  END Init;

  PROCEDURE (p : Item) LoadTheme*(top : PP.Item);

  VAR
    sub : PP.Item;

  BEGIN
    p.LoadTheme^(top);

    sub:=top.GetEntry("Return");
    IF sub#NIL THEN
      BG.LoadBackground(sub,"background",B.prefs.bgReturn);
      F.LoadFrame("frame",sub,B.prefs.returnFrame);
    END;

    sub:=top.GetEntry("Escape");
    IF sub#NIL THEN
      BG.LoadBackground(sub,"background",B.prefs.bgEscape);
      F.LoadFrame("frame",sub,B.prefs.escapeFrame);
    END;

    sub:=top.GetEntry("Default");
    IF sub#NIL THEN
      BG.LoadBackground(sub,"background",B.prefs.bgDefault);
      F.LoadFrame("frame",sub,B.prefs.defaultFrame);
    END;

    Z.LoadSize("hSpace",top,B.prefs.hSpace);
    Z.LoadSize("vSpace",top,B.prefs.vSpace);

    F.LoadFrame("sFrame",top,B.prefs.sFrame);
    F.LoadFrame("iFrame",top,B.prefs.iFrame);
    F.LoadFrame("tFrame",top,B.prefs.tFrame);

    B.prefs.gridDisable:=top.GetBoolEntry("gridDisable",B.prefs.gridDisable);
  END LoadTheme;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:Button.