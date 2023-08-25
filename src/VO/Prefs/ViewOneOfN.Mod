MODULE VO:Prefs:ViewOneOfN;

(*
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

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

       TM  := VO:Model:Table,
       V   := VO:Model:Value,

       GP  := VO:Prefs:Object,
       PP  := VO:Prefs:Parser,

       BO  := VO:Bool,
       CO  := VO:Combo,
       G   := VO:Object,
       L   := VO:Label,
       SL  := VO:Slider,
       VON := VO:ViewOneOfN;

TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
                planA,
                planAAlternate,
                planAAlterLimit,
                planB,
                planAMaxDepth        : V.IntModel;
                planBOnParentSmaller : V.BoolModel;
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;
    d.SetName("ViewOneOfN");

    d.SetPrefs(VON.prefs);

    d.planA:=V.CreateIntModel();
    d.planAAlternate:=V.CreateIntModel();
    d.planAAlterLimit:=V.CreateIntModel();
    d.planB:=V.CreateIntModel();
    d.planAMaxDepth:=V.CreateIntModel();
    d.planBOnParentSmaller:=V.CreateBoolModel();
  END Init;

  PROCEDURE (d : Item) GetObject*():G.Object;

  VAR
    label  : L.Label;
    bool   : BO.Bool;
    combo  : CO.Combo;
    slider : SL.Slider;
    model  : TM.LTableModel;
    entry  : TM.ListEntry;
    view   : VON.ViewOneOfN;

  BEGIN
    view:=VON.CreateViewOneOfN();
    view.SetFlags({G.horizontalFlex,G.verticalFlex});
    view.RequestFocus();

        label:=L.CreateLabel();
        label.SetFlags({G.horizontalFlex,G.verticalFlex});

          NEW(model);
          model.Init;

          entry:=TM.CreateListEntry(model);
          entry.SetString(1,"Tab");
          model.AppendEntry(entry);
          entry:=TM.CreateListEntry(model);
          entry.SetString(1,"Combo");
          model.AppendEntry(entry);
          entry:=TM.CreateListEntry(model);
          entry.SetString(1,"Table");
          model.AppendEntry(entry);

          combo:=CO.CreateTextCombo();
          combo.SetFlags({G.horizontalFlex});
          combo.SetMinWidth(Z.unit,20);
          combo.RequestFocus;
          combo.SetTableModel(model);
          combo.SetModel(d.planA);
        label.AddStringLabel("Plan A",combo);

          NEW(model);
          model.Init;

          entry:=TM.CreateListEntry(model);
          entry.SetString(1,"Tab");
          model.AppendEntry(entry);
          entry:=TM.CreateListEntry(model);
          entry.SetString(1,"Combo");
          model.AppendEntry(entry);
          entry:=TM.CreateListEntry(model);
          entry.SetString(1,"Table");
          model.AppendEntry(entry);

          combo:=CO.CreateTextCombo();
          combo.SetFlags({G.horizontalFlex});
          combo.SetMinWidth(Z.unit,20);
          combo.RequestFocus;
          combo.SetTableModel(model);
          combo.SetModel(d.planAAlternate);
        label.AddStringLabel("Plan A Alternate",combo);

          NEW(model);
          model.Init;

          entry:=TM.CreateListEntry(model);
          entry.SetString(1,"Tab");
          model.AppendEntry(entry);
          entry:=TM.CreateListEntry(model);
          entry.SetString(1,"Combo");
          model.AppendEntry(entry);
          entry:=TM.CreateListEntry(model);
          entry.SetString(1,"Table");
          model.AppendEntry(entry);

          combo:=CO.CreateTextCombo();
          combo.SetFlags({G.horizontalFlex});
          combo.SetMinWidth(Z.unit,20);
          combo.RequestFocus;
          combo.SetTableModel(model);
          combo.SetModel(d.planB);
        label.AddStringLabel("Plan B",combo);

          slider:=SL.CreateHSlider();
          slider.SetFlags({G.horizontalFlex});
          slider.SetMinWidth(Z.unit,20);
          slider.RequestFocus;
          slider.SetRange(0,30);
          slider.SetModel(d.planAAlterLimit);
        label.AddStringLabel("Min. entr. for plan A alt.",slider);

          slider:=SL.CreateHSlider();
          slider.SetFlags({G.horizontalFlex});
          slider.SetMinWidth(Z.unit,20);
          slider.RequestFocus;
          slider.SetRange(0,10);
          slider.SetModel(d.planAMaxDepth);
          label.AddStringLabel("Max. depth for plan A",slider);

          bool:=BO.CreateBool();
          bool.RequestFocus;
          bool.SetModel(d.planBOnParentSmaller);
        label.AddStringLabel("Choose pl. B on par. less. entr.",bool);

        view.AddView("Mode decision",label);

      RETURN view;
  END GetObject;

  PROCEDURE (d : Item) Refresh*;

  BEGIN
    d.Refresh^;

    d.planA.SetLongint(VON.prefs.planA);
    d.planAAlternate.SetLongint(VON.prefs.planAAlternate);
    d.planAAlterLimit.SetLongint(VON.prefs.planAAlterLimit);
    d.planB.SetLongint(VON.prefs.planB);
    d.planAMaxDepth.SetLongint(VON.prefs.planAMaxDepth);
    d.planBOnParentSmaller.SetBoolean(VON.prefs.planBOnParentSmaller);
  END Refresh;

  PROCEDURE (d : Item) Apply*;

  BEGIN
    d.Apply^;

    VON.prefs.planA:=d.planA.GetLongint();
    VON.prefs.planAAlternate:=d.planAAlternate.GetLongint();
    VON.prefs.planAAlterLimit:=d.planAAlterLimit.GetLongint();
    VON.prefs.planB:=d.planB.GetLongint();
    VON.prefs.planAMaxDepth:=d.planAMaxDepth.GetLongint();
    VON.prefs.planBOnParentSmaller:=d.planBOnParentSmaller.GetBoolean();
  END Apply;

  PROCEDURE (p : Item) LoadPrefs*(top : PP.Item);

  BEGIN
    p.LoadPrefs^(top);

    VON.prefs.planA:=top.GetIntEntry("planA",VON.prefs.planA);
    VON.prefs.planAAlternate:=top.GetIntEntry("planAAlternate",VON.prefs.planAAlternate);
    VON.prefs.planAAlterLimit:=top.GetIntEntry("planAAlterLimit",VON.prefs.planAAlterLimit);
    VON.prefs.planB:=top.GetIntEntry("planB",VON.prefs.planB);
    VON.prefs.planAMaxDepth:=top.GetIntEntry("planAMaxDepth",VON.prefs.planAMaxDepth);
    VON.prefs.planBOnParentSmaller:=top.GetBoolEntry("planBOnParrentSmaller",VON.prefs.planBOnParentSmaller);
  END LoadPrefs;

  PROCEDURE (p : Item) SavePrefs*(block : PP.BlockItem);

  BEGIN
    p.SavePrefs^(block);

    block.AddItemInt("planA",VON.prefs.planA);
    block.AddItemInt("planAAlternate",VON.prefs.planAAlternate);
    block.AddItemInt("planAAlterLimit",VON.prefs.planAAlterLimit);
    block.AddItemInt("planB",VON.prefs.planB);
    block.AddItemInt("planAMaxDepth",VON.prefs.planAMaxDepth);
    block.AddItemBool("planBOnSmallerParent",VON.prefs.planBOnParentSmaller);
  END SavePrefs;


BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:ViewOneOfN.
