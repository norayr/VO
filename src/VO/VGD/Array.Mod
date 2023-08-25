MODULE VO:VGD:Array;
  (**
    VGD parser for VO:Array.
  *)

  (*
    VGD parser for VO:Array.
    Copyright (C) 2004 Tim Teulings (rael@edge.ping.de)

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

       A   := VO:Array,
       G   := VO:Object;


TYPE
  ArrayParser     = POINTER TO ArrayParserDesc;
  ArrayParserDesc = RECORD (VGD.ObjectParserDesc)
                      horizCountId,
                      vertCountId,
                      horizSpaceId,
                      vertSpaceId,
                      childId       : LONGINT;
                    END;

VAR
  arrayParser : ArrayParser;

  PROCEDURE (p : ArrayParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Array");

    p.horizCountId:=p.RegisterAttribute("horizontalCount",VGD.intType,"Number of elements in horizontal direction");
    p.vertCountId:=p.RegisterAttribute("verticalCount",VGD.intType,"Number of elements in vertical direction");
    p.horizSpaceId:=p.RegisterAttribute("horizontalSpace",VGD.intType,"Leave some free room in horizontal direction between the individual objects");
    p.vertSpaceId:=p.RegisterAttribute("verticalSpace",VGD.intType,"Leave some free room in vertical direction between the individual objects");
    p.childId:=p.RegisterDefaultAttribute(VGD.defaultChildType,"Content of the Array");
  END Init;

  PROCEDURE (p : ArrayParser) SetAttribute*(object : G.Object;
                                            id : LONGINT; VAR data : VGD.DataDesc;
                                            item : PP.Item;
                                            context : VGD.Context);

  BEGIN
    IF id=p.horizCountId THEN
      object(A.Array).Set(data.int,TRUE);
    ELSIF id=p.vertCountId THEN
      object(A.Array).Set(data.int,FALSE);
    ELSIF id=p.horizSpaceId THEN
      object(A.Array).SetHorizontalSpace(data.bool);
    ELSIF id=p.vertSpaceId THEN
      object(A.Array).SetVerticalSpace(data.bool);
    ELSIF id=p.childId THEN
      object(A.Array).Add(data.object);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : ArrayParser) CreateInstance*():G.Object;

  BEGIN
    RETURN A.CreateArray();
  END CreateInstance;

BEGIN
  NEW(arrayParser);
  arrayParser.Init;
  VGD.factory.RegisterObjectParser(arrayParser);
END VO:VGD:Array.