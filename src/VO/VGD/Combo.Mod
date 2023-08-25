MODULE VO:VGD:Combo;
  (**
    VGD parser for VO:Combo.
  *)

  (*
    VGD parser for VO:Combo.
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

       D   := VO:Combo,
       G   := VO:Object;


TYPE
  ComboParser           = POINTER TO ComboParserDesc;
  ComboParserDesc       = RECORD (VGD.ObjectParserDesc)
                          END;

  StringComboParser     = POINTER TO StringComboParserDesc;
  StringComboParserDesc = RECORD (ComboParserDesc)
                          END;

  TextComboParser       = POINTER TO TextComboParserDesc;
  TextComboParserDesc   = RECORD (ComboParserDesc)
                          END;

VAR
  stringParser : StringComboParser;
  textParser   : TextComboParser;

  PROCEDURE (p : StringComboParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("StringCombo");
  END Init;

  PROCEDURE (p : TextComboParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("TextCombo");
  END Init;

  PROCEDURE (p : ComboParser) CreateInstance*():G.Object;

  BEGIN
    IF p.name.Equals("StringCombo") THEN
      RETURN D.CreateStringCombo();
    ELSIF p.name.Equals("TextCombo") THEN
      RETURN D.CreateTextCombo();
    ELSE
      RETURN NIL;
    END;
  END CreateInstance;

BEGIN
  NEW(stringParser);
  stringParser.Init;
  VGD.factory.RegisterObjectParser(stringParser);

  NEW(textParser);
  textParser.Init;
  VGD.factory.RegisterObjectParser(textParser);
END VO:VGD:Combo.