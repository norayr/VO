MODULE VO:Prefs:Label;

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

       G   := VO:Object,
       L   := VO:Label,
       R   := VO:Radio,
       VON := VO:ViewOneOfN;

TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
                labelPos    : V.IntModel;
                labelAlign  : V.IntModel;
                objectAlign : V.IntModel;
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;
    d.SetName("Label");

    d.SetPrefs(L.prefs);

    d.labelPos:=V.CreateIntModel();
    d.labelAlign:=V.CreateIntModel();
    d.objectAlign:=V.CreateIntModel();
  END Init;

  PROCEDURE (d : Item) GetObject*():G.Object;

  VAR
    label  : L.Label;
    radio  : R.Radio;
    view   : VON.ViewOneOfN;

  BEGIN
    view:=VON.CreateViewOneOfN();
    view.SetFlags({G.horizontalFlex,G.verticalFlex});
    view.RequestFocus();

        label:=L.CreateLabel();

          radio:=R.CreateRadio();
          radio.RequestFocus;
          radio.SetIndex(L.left);
          radio.SetModel(d.labelPos);
        label.AddStringLabel("Left",radio);

          radio:=R.CreateRadio();
          radio.RequestFocus;
          radio.SetIndex(L.right);
          radio.SetModel(d.labelPos);
        label.AddStringLabel("Right",radio);

      view.AddView("Label pos.",label);

        label:=L.CreateLabel();

          radio:=R.CreateRadio();
          radio.RequestFocus;
          radio.SetIndex(L.left);
          radio.SetModel(d.labelAlign);
        label.AddStringLabel("Left",radio);

          radio:=R.CreateRadio();
          radio.RequestFocus;
          radio.SetIndex(L.right);
          radio.SetModel(d.labelAlign);
       label.AddStringLabel("Right",radio);

     view.AddView("Label align.",label);

        label:=L.CreateLabel();

          radio:=R.CreateRadio();
          radio.RequestFocus;
          radio.SetIndex(L.left);
          radio.SetModel(d.objectAlign);
        label.AddStringLabel("Left",radio);

          radio:=R.CreateRadio();
          radio.RequestFocus;
          radio.SetIndex(L.right);
          radio.SetModel(d.objectAlign);
        label.AddStringLabel("Right",radio);

      view.AddView("Object align.",label);

    RETURN view;
  END GetObject;

  PROCEDURE (d : Item) Refresh*;

  BEGIN
    d.Refresh^;

    d.labelPos.SetLongint(L.prefs.labelPos);
    d.labelAlign.SetLongint(L.prefs.labelAlign);
    d.objectAlign.SetLongint(L.prefs.objectAlign);
  END Refresh;

  PROCEDURE (p : Item) Apply*;

  BEGIN
    p.Apply^;

    L.prefs.labelPos:=p.labelPos.GetLongint();
    L.prefs.labelAlign:=p.labelAlign.GetLongint();
    L.prefs.objectAlign:=p.objectAlign.GetLongint();
  END Apply;

  PROCEDURE (p : Item) LoadPrefs*(top : PP.Item);

  BEGIN
    p.LoadPrefs^(top);

    L.prefs.labelAlign:=top.GetIntEntry("labelAlign",L.prefs.labelAlign);
    L.prefs.objectAlign:=top.GetIntEntry("objectAlign",L.prefs.objectAlign);
    L.prefs.labelPos:=top.GetIntEntry("lablePos",L.prefs.labelPos);
  END LoadPrefs;

  PROCEDURE (p : Item) LoadTheme*(top : PP.Item);

  BEGIN
    p.LoadTheme^(top);

    Z.LoadSize("hSpace",top,L.prefs.hSpace);
    Z.LoadSize("hSpace",top,L.prefs.vSpace);
  END LoadTheme;

  PROCEDURE (p : Item) SavePrefs*(block : PP.BlockItem);

  BEGIN
    p.SavePrefs^(block);

    block.AddItemInt("labelPos",L.prefs.labelPos);
    block.AddItemInt("labelAlign",L.prefs.labelAlign);
    block.AddItemInt("objectAlign",L.prefs.objectAlign);
  END SavePrefs;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:Label.