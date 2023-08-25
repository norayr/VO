MODULE VO:VGD:Text;
  (**
    VGD parser for VO:Text.
  *)

  (*
    VGD parser for VO:Text.
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

       T   := VO:Text,
       G   := VO:Object;


TYPE
  TextParser     = POINTER TO TextParserDesc;
  TextParserDesc = RECORD (VGD.ObjectParserDesc)
                     textId : LONGINT;
                   END;

VAR
  textParser : TextParser;

  PROCEDURE (p : TextParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Text");
    p.textId:=p.RegisterAttribute("text",VGD.stringType,"The text to be shown");
  END Init;

  PROCEDURE (p : TextParser) SetAttribute*(object : G.Object;
                                           id : LONGINT; VAR data : VGD.DataDesc;
                                           item : PP.Item;
                                           context : VGD.Context);

  BEGIN
    IF id=p.textId THEN
      object(T.Text).SetString(data.string);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : TextParser) CreateInstance*():G.Object;

  BEGIN
    RETURN T.CreateText();
  END CreateInstance;

BEGIN
  NEW(textParser);
  textParser.Init;
  VGD.factory.RegisterObjectParser(textParser);
END VO:VGD:Text.