MODULE VO:VGD:LightChain;
  (**
    VGD parser for VO:LightChain.
  *)

  (*
    VGD parser for VO:LightChain.
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

       L   := VO:LightChain,
       G   := VO:Object;


TYPE
  LightChainParser     = POINTER TO LightChainParserDesc;
  LightChainParserDesc = RECORD (VGD.ObjectParserDesc)
                           textId : LONGINT;
                         END;

VAR
  lightChainParser : LightChainParser;

  PROCEDURE (p : LightChainParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("LightChain");
    p.textId:=p.RegisterAttribute("text",VGD.stringType,"Text to be show in the light chain");
  END Init;

  PROCEDURE (p : LightChainParser) SetAttribute*(object : G.Object;
                                                 id : LONGINT; VAR data : VGD.DataDesc;
                                                 item : PP.Item;
                                                 context : VGD.Context);

  BEGIN
    IF id=p.textId THEN
      object(L.LightChain).SetText(data.string);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : LightChainParser) CreateInstance*():G.Object;

  BEGIN
    RETURN L.CreateLightChain();
  END CreateInstance;

BEGIN
  NEW(lightChainParser);
  lightChainParser.Init;
  VGD.factory.RegisterObjectParser(lightChainParser);
END VO:VGD:LightChain.