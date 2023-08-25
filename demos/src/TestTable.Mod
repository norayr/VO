MODULE TestTable;

  (**
    Demo for VisualOberon. Demonstrates the table object.
  *)

(*
    Demo for VisualOberon. Demonstrates the table object.
    Copyright (C) 1998  Tim Teulings (rael@edge.ping.de)

    This file is part of VisualOberon.

    VisualOberon is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    VisualOberon is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with VisualOberon. If not, write to the Free Software
    Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

IMPORT D   := VO:Base:Display,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,
       VB  := VO:Base:VecImage,
       Z   := VO:Base:Size,

       SM  := VO:Model:Selection,
       TM  := VO:Model:Table,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)

       X1  := VO:VGD:All,
<* POP *>
              VO:VGD:VGD,

       B   := VO:Button,
       C   := VO:ColorArea,
       FG  := VO:FrameGroup,
       G   := VO:Object,
       I   := VO:Image,
       PL  := VO:Plate,
       T   := VO:Table,
       W   := VO:Window,

              Err;

TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
                 insert,
                 delete  : B.Button;
                 model   : TM.LTableModel;
               END;

VAR
  w        : Window;

  desc     : VGD.VGD;
  context  : VGD.Context;

  msg2Exit : D.Msg2Exit;

  PROCEDURE (w : Window) Receive*(message : O.Message);

  VAR
    entry : TM.ListEntry;

  BEGIN
    WITH
      message : B.PressedMsg DO
        IF message.source=w.insert THEN
          entry:=TM.CreateListEntry(w.model);
          entry.SetStr(1,"Added");
          w.model.AppendEntry(entry);
        ELSIF message.source=w.delete THEN
          IF w.model.selection(SM.SingleLine).line>0 THEN
            w.model.DeleteEntry(w.model.selection(SM.SingleLine).line);
          END;
        END;
        RETURN;
    ELSE
      w.Receive^(message);
    END;
  END Receive;

  PROCEDURE (w : Window) PreInit*;

  VAR
    x        : LONGINT;
    object   : G.Object;
    plate    : PL.Plate;
    color    : C.ColorArea;
    frame    : FG.FrameGroup;
    image    : I.Image;
    table    : T.Table;

    model1   : TM.TestTable;
    model2   : TM.ASTableModel;
    model3,
    model4   : TM.LTableModel;
    entry    : TM.ListEntry;

  BEGIN
    NEW(model1);
    model1.Init;
    model1.SetSelection(SM.CreateSingleCell());

    object:=w.top.GetObjectByName("Table1");
    table:=object(T.Table);
    table.SetModel(model1);
    table.SetShowHeader(FALSE);

    NEW(model2);
    model2.Init;
    model2.SetSize(5,2);
    model2.SetLabel(1,"\ebTestcolumn\en\n\esone");
    model2.SetLabel(2,"\ebTestcolumn\en\n\estwo");
    model2.SetLabel(3,"\ebTestcolumn\en\n\esthree");
    model2.SetLabel(4,"\ebTestcolumn\en\n\esfour");
    model2.SetLabel(5,"\ebTestcolumn\en\n\esfive");
    model2.SetString(1,1,"(1,1)");
    model2.SetString(2,1,"(2,1)");
    model2.SetString(3,1,"(3,1)");
    model2.SetString(4,1,"(4,1)");
    model2.SetString(5,1,"(5,1)");
    model2.SetString(1,2,"(1,2)");
    model2.SetString(2,2,"(2,2)");
    model2.SetSelection(SM.CreateSingleLine());

    object:=w.top.GetObjectByName("Table2");
    table:=object(T.Table);
    table.SetModel(model2);
    table.SetShowHeader(TRUE);

    NEW(model3);
    model3.Init;
    w.model:=model3;
    model3.SetSelection(SM.CreateSingleLine());

    entry:=TM.CreateListEntry(model3);
    entry.SetStr(1,"Entry 1");
    model3.AppendEntry(entry);
    entry:=TM.CreateListEntry(model3);
    entry.SetStr(1,"Entry 2");
    model3.AppendEntry(entry);
    entry:=TM.CreateListEntry(model3);
    entry.SetStr(1,"Entry 3");
    model3.AppendEntry(entry);
    entry:=TM.CreateListEntry(model3);
    entry.SetStr(1,"Entry 4");
    model3.AppendEntry(entry);
    entry:=TM.CreateListEntry(model3);
    entry.SetStr(1,"Entry 5");
    model3.AppendEntry(entry);
    entry:=TM.CreateListEntry(model3);
    entry.SetStr(1,"Entry 6");
    model3.AppendEntry(entry);

    object:=w.top.GetObjectByName("Table3");
    table:=object(T.Table);
    table.SetModel(model3);
    table.SetShowHeader(FALSE);

    object:=w.top.GetObjectByName("Insert");
    w.insert:=object(B.Button);
    w.insert.Forward(B.pressedMsg,w);

    object:=w.top.GetObjectByName("Delete");
    w.delete:=object(B.Button);
    w.delete.Forward(B.pressedMsg,w);

    NEW(model4);
    model4.Init;
    model4.SetSelection(SM.CreateSingleLine());
    model4.SetLabel(1,"Object");
    model4.SetColumnWidth(1,Z.stdCharWidth,10);
    model4.SetLabel(2,"Objectname");
    model4.SetColumnWidth(2,Z.stdCharWidth,35);

    FOR x:=0 TO D.colorCount-1 DO
      plate:=PL.CreatePlate();
        color:=C.CreateColorArea();
        color.SetMinWidth(Z.unit,6);
        color.SetMinHeight(Z.unit,3);
        color.SetColor(D.GetColorByIndex(x));
      plate.Add(color);
      entry:=TM.CreateListEntry(model4);
      entry.SetObject(1,plate);
      entry.SetString(2,D.colorNames[x]);
      model4.AppendEntry(entry);
    END;

    FOR x:=0 TO F.internalFrameCount-1 DO
      plate:=PL.CreatePlate();
        frame:=FG.CreateFrameGroup();
        frame.SetMinWidth(Z.unit,3);
        frame.SetMinHeight(Z.unit,3);
        frame.SetFrame(F.CreateFrame(x));
      plate.Add(frame);
      entry:=TM.CreateListEntry(model4);
      entry.SetObject(1,plate);
      entry.SetString(2,F.internalFrames[x]);
      model4.AppendEntry(entry);;
    END;

    FOR x:=0 TO VB.imageCount-1 DO
      plate:=PL.CreatePlate();
        image:=I.CreateImage();
        image.SetMinWidth(Z.unit,3);
        image.SetMinHeight(Z.unit,3);
        image.SetInternal(x);
      plate.Add(image);
      entry:=TM.CreateListEntry(model4);
      entry.SetObject(1,plate);
      entry.SetString(2,VB.images[x]);
      model4.AppendEntry(entry);
    END;

    object:=w.top.GetObjectByName("Table4");
    table:=object(T.Table);
    table.SetModel(model4);
    table.table.SetRowHeight(40);
    table.SetShowHeader(TRUE);

    w.PreInit^;
  END PreInit;

BEGIN
  IF ~Probe.OpenDisplay("TestTable") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  desc:=VGD.LoadVGD("TestTable.vgd");
  IF desc=NIL THEN
    Err.String("Cannot load GUI description file"); Err.Ln;
    D.display.Close;
    HALT(1);
  END;

  NEW(w);
  w.Init;

  NEW(context);
  context.Init;
  IF ~VGD.LoadWindow(w,desc,"Main",context) THEN
    Err.String("Error: Cannot instantiate window 'Main' from vgd file!");
    Err.Ln;
    context.DumpErrors;
    HALT(1);
  END;

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
  END;

  D.display.Close;
END TestTable.