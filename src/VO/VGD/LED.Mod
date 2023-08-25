MODULE VO:VGD:LED;
  (**
    VGD parser for VO:LED.
  *)

  (*
    VGD parser for VO:LED.
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

       D   := VO:LED,
       G   := VO:Object;


TYPE
  LEDParser          = POINTER TO LEDParserDesc;
  LEDParserDesc      = RECORD (VGD.ObjectParserDesc)
                       END;

VAR
  ledParser : LEDParser;

  PROCEDURE (p : LEDParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("LED");
  END Init;

  PROCEDURE (p : LEDParser) CreateInstance*():G.Object;

  BEGIN
    RETURN D.CreateLED();
  END CreateInstance;

BEGIN
  NEW(ledParser);
  ledParser.Init;
  VGD.factory.RegisterObjectParser(ledParser);
END VO:VGD:LED.