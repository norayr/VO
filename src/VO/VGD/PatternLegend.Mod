MODULE VO:VGD:PatternLegend;
  (**
    VGD parser for VO:PatternLegend.
  *)

  (*
    VGD parser for VO:PatternLegend.
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

       P   := VO:PatternLegend,
       G   := VO:Object;


TYPE
  PatternLegendParser          = POINTER TO PatternLegendParserDesc;
  PatternLegendParserDesc      = RECORD (VGD.ObjectParserDesc)
                                 END;

VAR
  patternLegendParser : PatternLegendParser;

  PROCEDURE (p : PatternLegendParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("PatternLegend");
  END Init;

  PROCEDURE (p : PatternLegendParser) CreateInstance*():G.Object;

  BEGIN
    RETURN P.CreatePatternLegend();
  END CreateInstance;

BEGIN
  NEW(patternLegendParser);
  patternLegendParser.Init;
  VGD.factory.RegisterObjectParser(patternLegendParser);
END VO:VGD:PatternLegend.