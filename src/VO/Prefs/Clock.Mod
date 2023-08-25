MODULE VO:Prefs:Clock;

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

       V   := VO:Model:Value,

       GP  := VO:Prefs:Object,
       PP  := VO:Prefs:Parser,

       C   := VO:Clock,
       G   := VO:Object,
       L   := VO:Label,
       SL  := VO:Slider,
       VON := VO:ViewOneOfN;

TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
                 pointerScale*,
                 secPointerScale*,
                 hourScale*,
                 minuteScale*       : V.IntModel;
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;
    d.SetName("Clock");

    d.SetPrefs(C.prefs);

    d.pointerScale:=V.CreateIntModel();
    d.secPointerScale:=V.CreateIntModel();
    d.hourScale:=V.CreateIntModel();
    d.minuteScale:=V.CreateIntModel();
  END Init;

  PROCEDURE (d : Item) GetObject*():G.Object;

  VAR
    label  : L.Label;
    view   : VON.ViewOneOfN;
    slider : SL.Slider;

  BEGIN
    view:=VON.CreateViewOneOfN();
    view.SetFlags({G.horizontalFlex,G.verticalFlex});
    view.RequestFocus;

      label:=L.CreateLabel();
      label.SetFlags({G.horizontalFlex});

        slider:=SL.CreateHSlider();
        slider.SetFlags({G.horizontalFlex});
        slider.RequestFocus;
        slider.SetMinWidth(Z.unit,20);
        slider.SetRange(0,1000);
        slider.SetModel(d.pointerScale);
      label.AddStringLabel("Pointer thickness",slider);

        slider:=SL.CreateHSlider();
        slider.SetFlags({G.horizontalFlex});
        slider.RequestFocus;
        slider.SetMinWidth(Z.unit,20);
        slider.SetRange(0,1000);
        slider.SetModel(d.secPointerScale);
      label.AddStringLabel("Second pointer thickness",slider);

        slider:=SL.CreateHSlider();
        slider.SetFlags({G.horizontalFlex});
        slider.RequestFocus;
        slider.SetMinWidth(Z.unit,20);
        slider.SetRange(0,1000);
        slider.SetModel(d.hourScale);
      label.AddStringLabel("Hour tick thickness",slider);

        slider:=SL.CreateHSlider();
        slider.SetFlags({G.horizontalFlex});
        slider.RequestFocus;
        slider.SetMinWidth(Z.unit,20);
        slider.SetRange(0,1000);
        slider.SetModel(d.minuteScale);
      label.AddStringLabel("Minute tick thickness",slider);

    view.AddView("Sizes",label);

    RETURN view;
  END GetObject;

  PROCEDURE (d : Item) Refresh*;

  BEGIN
    d.Refresh^;

    d.pointerScale.SetLongint(C.prefs.pointerScale);
    d.secPointerScale.SetLongint(C.prefs.secPointerScale);
    d.hourScale.SetLongint(C.prefs.hourScale);
    d.minuteScale.SetLongint(C.prefs.minuteScale);
  END Refresh;

  PROCEDURE (p : Item) Apply*;

  BEGIN
    p.Apply^;

    C.prefs.pointerScale:=p.pointerScale.GetLongint();
    C.prefs.secPointerScale:=p.secPointerScale.GetLongint();
    C.prefs.hourScale:=p.hourScale.GetLongint();
    C.prefs.minuteScale:=p.minuteScale.GetLongint();
  END Apply;

  PROCEDURE (p : Item) LoadPrefs*(top : PP.Item);

  BEGIN
    p.LoadPrefs^(top);

    C.prefs.pointerScale:=ABS(top.GetIntEntry("pointerScale",C.prefs.pointerScale));
    C.prefs.secPointerScale:=ABS(top.GetIntEntry("secPointerScale",C.prefs.secPointerScale));
    C.prefs.hourScale:=ABS(top.GetIntEntry("hourScale",C.prefs.hourScale));
    C.prefs.minuteScale:=ABS(top.GetIntEntry("minuteScale",C.prefs.minuteScale));
  END LoadPrefs;

  PROCEDURE (p : Item) SavePrefs*(block : PP.BlockItem);

  BEGIN
    p.SavePrefs^(block);

    block.AddItemInt("pointerScale",C.prefs.pointerScale);
    block.AddItemInt("secPointerScale",C.prefs.secPointerScale);
    block.AddItemInt("hourScale",C.prefs.hourScale);
    block.AddItemInt("minuteScale",C.prefs.minuteScale);
  END SavePrefs;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:Clock.