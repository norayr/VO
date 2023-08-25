MODULE VO:VGD:ButtonRow;
  (**
    VGD parser for VO:ButtonRow.
  *)

  (*
    VGD parser for VO:ButtonRow.
    Copyright (C) 2002 Tim Teulings (rael@edge.ping.de)

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

IMPORT        VO:VGD:VGD,

       PP  := VO:Prefs:Parser,

       B   := VO:ButtonRow,
       G   := VO:Object;

TYPE
  ButtonRowParser     = POINTER TO ButtonRowParserDesc;
  ButtonRowParserDesc = RECORD (VGD.ObjectParserDesc)
                          childId : LONGINT;
                        END;

VAR
  panelParser : ButtonRowParser;

  PROCEDURE (p : ButtonRowParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("ButtonRow");
    p.childId:=p.RegisterDefaultAttribute(VGD.defaultChildType,"Content of the ButtonRow");
  END Init;

  PROCEDURE (p : ButtonRowParser) SetAttribute*(object : G.Object;
                                            id : LONGINT; VAR data : VGD.DataDesc;
                                            item : PP.Item;
                                            context : VGD.Context);

  BEGIN
    IF id=p.childId THEN
      object(B.ButtonRow).Add(data.object);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : ButtonRowParser) CreateInstance*():G.Object;

  BEGIN
    RETURN B.CreateButtonRow();
  END CreateInstance;

BEGIN
  NEW(panelParser);
  panelParser.Init;
  VGD.factory.RegisterObjectParser(panelParser);
END VO:VGD:ButtonRow.