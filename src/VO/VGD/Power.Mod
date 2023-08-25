MODULE VO:VGD:Power;
  (**
    VGD parser for VO:Power.
  *)

  (*
    VGD parser for VO:Power.
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

       D   := VO:Power,
       G   := VO:Object;


TYPE
  PowerParser          = POINTER TO PowerParserDesc;
  PowerParserDesc      = RECORD (VGD.ObjectParserDesc)
                         END;

VAR
  powerParser : PowerParser;

  PROCEDURE (p : PowerParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Power");
  END Init;

  PROCEDURE (p : PowerParser) CreateInstance*():G.Object;

  BEGIN
    RETURN D.CreatePower();
  END CreateInstance;

BEGIN
  NEW(powerParser);
  powerParser.Init;
  VGD.factory.RegisterObjectParser(powerParser);
END VO:VGD:Power.