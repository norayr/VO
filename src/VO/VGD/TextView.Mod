MODULE VO:VGD:TextView;
  (**
    VGD parser for VO:TextView.
  *)

  (*
    VGD parser for VO:TextView.
    Copyright (C) 2004 Tim Teulings (rael@edge.ping.de)

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
       T   := VO:TextView;


TYPE
  TextViewParser     = POINTER TO TextViewParserDesc;
  TextViewParserDesc = RECORD (VGD.ObjectParserDesc)
                       END;

VAR
  textViewParser : TextViewParser;

  PROCEDURE (p : TextViewParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("TextView");
  END Init;

  PROCEDURE (p : TextViewParser) CreateInstance*():G.Object;

  BEGIN
    RETURN T.CreateTextView();
  END CreateInstance;

BEGIN
  NEW(textViewParser);
  textViewParser.Init;
  VGD.factory.RegisterObjectParser(textViewParser);
END VO:VGD:TextView.