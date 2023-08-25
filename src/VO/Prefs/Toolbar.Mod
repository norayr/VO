MODULE VO:Prefs:Toolbar;

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

IMPORT GP  := VO:Prefs:Object,

       V   := VO:Model:Value,

       PP  := VO:Prefs:Parser,

       BO  := VO:Bool,
       G   := VO:Object,
       L   := VO:Label,
       T   := VO:Toolbar,
       VON := VO:ViewOneOfN;

TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
                equalSize : V.BoolModel;
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;
    d.SetName("Toolbar");

    d.SetPrefs(T.prefs);
    d.equalSize:=V.CreateBoolModel();
  END Init;

  PROCEDURE (d : Item) GetObject*():G.Object;

  VAR
    label : L.Label;
    bool  : BO.Bool;
    view  : VON.ViewOneOfN;

  BEGIN
    view:=VON.CreateViewOneOfN();
    view.SetFlags({G.horizontalFlex,G.verticalFlex});
    view.RequestFocus();

      label:=L.CreateLabel();
        bool:=BO.CreateBool();
        bool.RequestFocus;
        bool.SetModel(d.equalSize);
      label.AddStringLabel("Equal size",bool);
    view.AddView("Flags",label);

    RETURN view;
  END GetObject;

  PROCEDURE (d : Item) Refresh*;

  BEGIN
    d.Refresh^;

    d.equalSize.SetBoolean(T.prefs.equalSize);
  END Refresh;

  PROCEDURE (p : Item) Apply*;

  BEGIN
    p.Apply^;

    T.prefs.equalSize:=p.equalSize.GetBoolean();
  END Apply;


  PROCEDURE (p : Item) LoadPrefs*(top : PP.Item);

  BEGIN
    p.LoadPrefs^(top);

    T.prefs.equalSize:=top.GetBoolEntry("equalSize",T.prefs.equalSize);
  END LoadPrefs;

  PROCEDURE (p : Item) SavePrefs*(block : PP.BlockItem);

  BEGIN
    p.SavePrefs^(block);

    block.AddItemBool("equalSize",T.prefs.equalSize);
  END SavePrefs;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:Toolbar.