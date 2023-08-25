MODULE VO:VGD:Pane;
  (**
    VGD parser for VO:Pane.
  *)

  (*
    VGD parser for VO:Pane.
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
       P   := VO:Pane;

TYPE
  PaneParser     = POINTER TO PaneParserDesc;
  PaneParserDesc = RECORD (VGD.ObjectParserDesc)
                     directionId,
                     childId      : LONGINT;
                   END;

VAR
  paneParser : PaneParser;

  PROCEDURE (p : PaneParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Pane");
    p.directionId:=p.RegisterAttribute("direction",VGD.stringType,"Direction of the pane");
    p.childId:=p.RegisterDefaultAttribute(VGD.defaultChildType,"Content of the Pane");
  END Init;

  PROCEDURE (p : PaneParser) SetAttribute*(object : G.Object;
                                           id : LONGINT; VAR data : VGD.DataDesc;
                                           item : PP.Item;
                                           context : VGD.Context);

  BEGIN
    IF id=p.directionId THEN
      IF data.string.Equals("horizontal") THEN
        object(P.Pane).Set(P.horizontal);
      ELSIF data.string.Equals("vertical") THEN
        object(P.Pane).Set(P.vertical);
      ELSE
        context.AddError(item,"Unknown direction");
      END;
    ELSIF id=p.childId THEN
      object(P.Pane).Add(data.object);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : PaneParser) CreateInstance*():G.Object;

  BEGIN
    RETURN P.CreatePane();
  END CreateInstance;

BEGIN
  NEW(paneParser);
  paneParser.Init;
  VGD.factory.RegisterObjectParser(paneParser);
END VO:VGD:Pane.