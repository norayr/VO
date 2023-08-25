MODULE VO:VGD:FrameGroup;
  (**
    VGD parser for VO:FrameGroup.
  *)

  (*
    VGD parser for VO:FrameGroup.
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

       F   := VO:FrameGroup,
       G   := VO:Object;

TYPE
  FrameGroupParser     = POINTER TO FrameGroupParserDesc;
  FrameGroupParserDesc = RECORD (VGD.ObjectParserDesc)
                           textId,
                           childId : LONGINT;
                         END;

VAR
  frameParser : FrameGroupParser;

  PROCEDURE (p : FrameGroupParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("FrameGroup");
    p.textId:=p.RegisterAttribute("text",VGD.stringType,"Text to be shown as part of the frame");
    p.childId:=p.RegisterDefaultAttribute(VGD.defaultChildType,"Content of the Frame");
  END Init;

  PROCEDURE (p : FrameGroupParser) SetAttribute*(object : G.Object;
                                                 id : LONGINT; VAR data : VGD.DataDesc;
                                                 item : PP.Item;
                                                 context : VGD.Context);

  BEGIN
    IF id=p.textId THEN
      object(F.FrameGroup).SetStringLabel(data.string);
    ELSIF id=p.childId THEN
      object(F.FrameGroup).SetObject(data.object);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : FrameGroupParser) CreateInstance*():G.Object;

  BEGIN
    RETURN F.CreateFrameGroup();
  END CreateInstance;

BEGIN
  NEW(frameParser);
  frameParser.Init;
  VGD.factory.RegisterObjectParser(frameParser);
END VO:VGD:FrameGroup.