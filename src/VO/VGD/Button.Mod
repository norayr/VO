MODULE VO:VGD:Button;
  (**
    VGD parser for VO:Button.
  *)

  (*
    VGD parser for VO:Button.
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

       B   := VO:Button,
       G   := VO:Object;


TYPE
  ButtonParser          = POINTER TO ButtonParserDesc;
  ButtonParserDesc      = RECORD (VGD.ObjectParserDesc)
                            labelTextId,
                            typeId,
                            childId      : LONGINT;
                          END;

VAR
  buttonParser : ButtonParser;

  PROCEDURE (p : ButtonParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Button");

    p.labelTextId:=p.RegisterAttribute("labelText",VGD.stringType,"Text to be used as button label");
    p.typeId:=p.RegisterAttribute("type",VGD.stringType,"Type of button");
    p.childId:=p.RegisterDefaultAttribute(VGD.defaultChildType,"Content of the button");
  END Init;

  PROCEDURE (p : ButtonParser) SetAttribute*(object : G.Object;
                                             id : LONGINT; VAR data : VGD.DataDesc;
                                             item : PP.Item;
                                             context : VGD.Context);

  BEGIN
    IF id=p.labelTextId THEN
      object(B.Button).SetLabelString(data.string);
    ELSIF id=p.typeId THEN
      IF data.string.Equals("normal") THEN
        object(B.Button).SetType(B.normal);
      ELSIF data.string.Equals("small") THEN
        object(B.Button).SetType(B.small);
      ELSIF data.string.Equals("image") THEN
        object(B.Button).SetType(B.image);
      ELSIF data.string.Equals("toolbar") THEN
        object(B.Button).SetType(B.toolBar);
      ELSE
        context.AddError(item,"Unknown type");
      END;
    ELSIF id=p.childId THEN
      object(B.Button).SetImage(data.object);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : ButtonParser) CreateInstance*():G.Object;

  BEGIN
    RETURN B.CreateButton();
  END CreateInstance;

BEGIN
  NEW(buttonParser);
  buttonParser.Init;
  VGD.factory.RegisterObjectParser(buttonParser);
END VO:VGD:Button.