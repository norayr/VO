MODULE VO:VGD:Bool;
  (**
    VGD parser for VO:Bool.
  *)

  (*
    VGD parser for VO:Bool.
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

       D   := VO:Bool,
       G   := VO:Object;


TYPE
  BoolParser          = POINTER TO BoolParserDesc;
  BoolParserDesc      = RECORD (VGD.ObjectParserDesc)
                        END;

VAR
  boolParser : BoolParser;

  PROCEDURE (p : BoolParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Bool");
  END Init;

  PROCEDURE (p : BoolParser) CreateInstance*():G.Object;

  BEGIN
    RETURN D.CreateBool();
  END CreateInstance;

BEGIN
  NEW(boolParser);
  boolParser.Init;
  VGD.factory.RegisterObjectParser(boolParser);
END VO:VGD:Bool.