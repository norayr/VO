MODULE VO:VGD:Clock;
  (**
    VGD parser for VO:Clock.
  *)

  (*
    VGD parser for VO:Clock.
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

       D   := VO:Clock,
       G   := VO:Object;


TYPE
  ClockParser          = POINTER TO ClockParserDesc;
  ClockParserDesc      = RECORD (VGD.ObjectParserDesc)
                             END;

VAR
  clockParser : ClockParser;

  PROCEDURE (p : ClockParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Clock");
  END Init;

  PROCEDURE (p : ClockParser) CreateInstance*():G.Object;

  BEGIN
    RETURN D.CreateClock();
  END CreateInstance;

BEGIN
  NEW(clockParser);
  clockParser.Init;
  VGD.factory.RegisterObjectParser(clockParser);
END VO:VGD:Clock.