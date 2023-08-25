MODULE VO:Dlg:ImgSel;

(**
  A dialog to select one of the internal images.
*)

(*
    A dialog to select one of the internal images.
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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

IMPORT VB := VO:Base:VecImage,
       Z  := VO:Base:Size,

       SM := VO:Model:Selection,
       TM := VO:Model:Table,

       C  := VO:Combo,
       I  := VO:Image,
       PL := VO:Plate,
       TB := VO:Table;

TYPE
  ImgSelCombo*     = POINTER TO ImgSelComboDesc;
  ImgSelComboDesc* = RECORD (C.ComboDesc)
                       image : I.Image;
                     END;

  PROCEDURE (c : ImgSelCombo) Init*;

  VAR
    image : I.Image;
    model : TM.LTableModel;
    plate : PL.Plate;
    x     : LONGINT;
    entry : TM.ListEntry;

  BEGIN
    c.Init^;

    plate:=PL.CreatePlate();
      c.image:=I.CreateImage();
      c.image.SetMinWidth(Z.unit,4);
      c.image.SetMinHeight(Z.unit,4);
    plate.Add(c.image);
    c.SetValueObject(plate);

    NEW(model);
    model.Init;
    model.SetSelection(SM.CreateSingleLine());
    model.SetLabel(1,"Image");
    model.SetColumnWidth(1,Z.pixel,30);
    model.SetLabel(2,"Name");
    model.SetColumnWidth(2,Z.stdCharWidth,20);

    FOR x:=0 TO VB.imageCount-1 DO
      plate:=PL.CreatePlate();
        image:=I.CreateImage();
        image.SetMinWidth(Z.unit,4);
        image.SetMinHeight(Z.unit,4);
        image.SetInternal(x);
      plate.Add(image);

      entry:=TM.CreateListEntry(model);
      entry.SetObject(1,plate);
      entry.SetString(2,VB.images[x]);
      model.AppendEntry(entry);
    END;

    c.SetTableModel(model);
  END Init;

  PROCEDURE (c : ImgSelCombo) InitTable*(table : TB.Table);

  BEGIN
    table.SetMinWidth(Z.unit,30);
    table.table.SetRowHeight(30);
  END InitTable;

  PROCEDURE (c : ImgSelCombo) CopySelection*(row : LONGINT);

  BEGIN
    c.CopySelection^(row);

    IF row>0 THEN
      c.image.SetInternal(row-1);
    END;
  END CopySelection;

  PROCEDURE CreateImgSelCombo*():ImgSelCombo;

  VAR
    combo : ImgSelCombo;

  BEGIN
    NEW(combo);
    combo.Init;

    RETURN combo;
  END CreateImgSelCombo;

END VO:Dlg:ImgSel.