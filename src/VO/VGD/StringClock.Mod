MODULE VO:VGD:StringClock;
  (**
    VGD parser for VO:StringClock.
  *)

  (*
    VGD parser for VO:StringClock.
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

       G   := VO:Object,
       S   := VO:StringClock;


TYPE
  StringClockParser          = POINTER TO StringClockParserDesc;
  StringClockParserDesc      = RECORD (VGD.ObjectParserDesc)
                               END;

VAR
  stringClockParser : StringClockParser;

  PROCEDURE (p : StringClockParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("StringClock");
  END Init;

  PROCEDURE (p : StringClockParser) CreateInstance*():G.Object;

  BEGIN
    RETURN S.CreateStringClock();
  END CreateInstance;

BEGIN
  NEW(stringClockParser);
  stringClockParser.Init;
  VGD.factory.RegisterObjectParser(stringClockParser);
END VO:VGD:StringClock.