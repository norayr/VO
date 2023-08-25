MODULE VO:VGD:Space;
  (**
    VGD parser for VO:Space.
  *)

  (*
    VGD parser for VO:Space.
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
       S   := VO:Space;


TYPE
  SpaceParser     = POINTER TO SpaceParserDesc;
  SpaceParserDesc = RECORD (VGD.ObjectParserDesc)
                      directionId : LONGINT;
                    END;

VAR
  spaceParser : SpaceParser;

  PROCEDURE (p : SpaceParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Space");
    p.directionId:=p.RegisterAttribute("direction",VGD.stringType,"Direction of the space");
  END Init;

  PROCEDURE (p : SpaceParser) SetAttribute*(object : G.Object;
                                            id : LONGINT; VAR data : VGD.DataDesc;
                                            item : PP.Item;
                                            context : VGD.Context);

  BEGIN
    IF id=p.directionId THEN
      IF data.string.Equals("horizontal") THEN
        object(S.Space).Set(FALSE,S.normal);
      ELSIF data.string.Equals("vertical") THEN
        object(S.Space).Set(TRUE,S.normal);
      ELSE
        context.AddError(item,"Unknown direction");
      END;
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : SpaceParser) CreateInstance*():G.Object;

  BEGIN
    RETURN S.CreateSpace();
  END CreateInstance;

BEGIN
  NEW(spaceParser);
  spaceParser.Init;
  VGD.factory.RegisterObjectParser(spaceParser);
END VO:VGD:Space.