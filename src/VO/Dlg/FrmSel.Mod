MODULE VO:Dlg:FrmSel;

  (**
    A dialog to select a internal frame.
  *)

(*
    A dialog to select a internal frame.
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

IMPORT F  := VO:Base:Frame,
       Z  := VO:Base:Size,

       SM := VO:Model:Selection,
       TM := VO:Model:Table,

       C  := VO:Combo,
       FG := VO:FrameGroup,
       PL := VO:Plate,
       TB := VO:Table;

TYPE
  FrmSelCombo*     = POINTER TO FrmSelComboDesc;
  FrmSelComboDesc* = RECORD (C.ComboDesc)
                       frame : FG.FrameGroup;
                     END;


  PROCEDURE (c : FrmSelCombo) Init*;

  VAR
    frame : FG.FrameGroup;
    model : TM.LTableModel;
    entry : TM.ListEntry;
    plate : PL.Plate;
    x     : LONGINT;

  BEGIN
    c.Init^;

    plate:=PL.CreatePlate();
      c.frame:=FG.CreateFrameGroup();
      c.frame.SetMinWidth(Z.unit,3);
      c.frame.SetMinHeight(Z.unit,3);
    plate.Add(c.frame);
    c.SetValueObject(plate);

    NEW(model);
    model.Init;
    model.SetSelection(SM.CreateSingleLine());
    model.SetLabel(1,"Frame");
    model.SetColumnWidth(1,Z.pixel,30);
    model.SetLabel(2,"Name");
    model.SetColumnWidth(2,Z.stdCharWidth,20);

    FOR x:=0 TO F.internalFrameCount-1 DO
      plate:=PL.CreatePlate();
        frame:=FG.CreateFrameGroup();
        frame.SetMinWidth(Z.unit,3);
        frame.SetMinHeight(Z.unit,3);
        frame.SetFrame(F.CreateFrame(x));
      plate.Add(frame);
      entry:=TM.CreateListEntry(model);
      entry.SetObject(1,plate);
      entry.SetString(2,F.internalFrames[x]);
      model.AppendEntry(entry);
    END;

    c.SetTableModel(model);
  END Init;

  PROCEDURE (c : FrmSelCombo) InitTable*(table : TB.Table);

  BEGIN
    table.SetMinWidth(Z.unit,30);
    table.table.SetRowHeight(20);
  END InitTable;

  PROCEDURE (c : FrmSelCombo) CopySelection*(row : LONGINT);

  BEGIN
    c.CopySelection^(row);

    IF row>0 THEN
      c.frame.SetFrame(F.CreateFrame(row-1));
    END;
  END CopySelection;

  PROCEDURE CreateFrmSelCombo*():FrmSelCombo;

  VAR
    combo : FrmSelCombo;

  BEGIN
    NEW(combo);
    combo.Init;

    RETURN combo;
  END CreateFrmSelCombo;

END VO:Dlg:FrmSel.