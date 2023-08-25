MODULE VO:VGD:Image;
  (**
    VGD parser for VO:Image.
  *)

  (*
    VGD parser for VO:Image.
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
       I   := VO:Image;


TYPE
  ImageParser          = POINTER TO ImageParserDesc;
  ImageParserDesc      = RECORD (VGD.ObjectParserDesc)
                           filenameId : LONGINT;
                         END;

VAR
  imageParser : ImageParser;

  PROCEDURE (p : ImageParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Image");
    p.filenameId:=p.RegisterAttribute("filename",VGD.stringType,"Filename of the external image file");
  END Init;

  PROCEDURE (p : ImageParser) SetAttribute*(object : G.Object;
                                            id : LONGINT; VAR data : VGD.DataDesc;
                                            item : PP.Item;
                                            context : VGD.Context);

  BEGIN
    IF id=p.filenameId THEN
      object(I.Image).SetFilename(data.string);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : ImageParser) CreateInstance*():G.Object;

  BEGIN
    RETURN I.CreateImage();
  END CreateInstance;

BEGIN
  NEW(imageParser);
  imageParser.Init;
  VGD.factory.RegisterObjectParser(imageParser);
END VO:VGD:Image.