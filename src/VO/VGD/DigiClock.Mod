MODULE VO:VGD:DigiClock;
  (**
    VGD parser for VO:DigiClock.
  *)

  (*
    VGD parser for VO:DigiClock.
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

       D   := VO:DigiClock,
       G   := VO:Object;


TYPE
  DigiClockParser          = POINTER TO DigiClockParserDesc;
  DigiClockParserDesc      = RECORD (VGD.ObjectParserDesc)
                             END;

VAR
  digiClockParser : DigiClockParser;

  PROCEDURE (p : DigiClockParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("DigiClock");
  END Init;

  PROCEDURE (p : DigiClockParser) CreateInstance*():G.Object;

  BEGIN
    RETURN D.CreateDigiClock();
  END CreateInstance;

BEGIN
  NEW(digiClockParser);
  digiClockParser.Init;
  VGD.factory.RegisterObjectParser(digiClockParser);
END VO:VGD:DigiClock.