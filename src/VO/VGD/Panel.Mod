MODULE VO:VGD:Panel;
  (**
    VGD parser for VO:Panel.
  *)

  (*
    VGD parser for VO:Panel.
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

       G   := VO:Object,
       P   := VO:Panel;

TYPE
  PanelParser     = POINTER TO PanelParserDesc;
  PanelParserDesc = RECORD (VGD.ObjectParserDesc)
                      directionId,
                      childId      : LONGINT;
                    END;

VAR
  panelParser : PanelParser;

  PROCEDURE (p : PanelParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Panel");
    p.directionId:=p.RegisterAttribute("direction",VGD.stringType,"Direction of the panel");
    p.childId:=p.RegisterDefaultAttribute(VGD.defaultChildType,"Content of the Panel");
  END Init;

  PROCEDURE (p : PanelParser) SetAttribute*(object : G.Object;
                                            id : LONGINT; VAR data : VGD.DataDesc;
                                            item : PP.Item;
                                            context : VGD.Context);

  BEGIN
    IF id=p.directionId THEN
      IF data.string.Equals("horizontal") THEN
        object(P.Panel).Set(P.horizontal);
      ELSIF data.string.Equals("vertical") THEN
        object(P.Panel).Set(P.vertical);
      ELSE
        context.AddError(item,"Unknown direction");
      END;
    ELSIF id=p.childId THEN
      object(P.Panel).Add(data.object);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : PanelParser) CreateInstance*():G.Object;

  BEGIN
    RETURN P.CreatePanel();
  END CreateInstance;

BEGIN
  NEW(panelParser);
  panelParser.Init;
  VGD.factory.RegisterObjectParser(panelParser);
END VO:VGD:Panel.