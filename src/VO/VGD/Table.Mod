MODULE VO:VGD:Table;
  (**
    VGD parser for VO:Table.
  *)

  (*
    VGD parser for VO:Table.
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
       T   := VO:Table;


TYPE
  TableParser          = POINTER TO TableParserDesc;
  TableParserDesc      = RECORD (VGD.ObjectParserDesc)
                         END;

VAR
  tableParser : TableParser;

  PROCEDURE (p : TableParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Table");
  END Init;

  PROCEDURE (p : TableParser) CreateInstance*():G.Object;

  BEGIN
    RETURN T.CreateTable();
  END CreateInstance;

BEGIN
  NEW(tableParser);
  tableParser.Init;
  VGD.factory.RegisterObjectParser(tableParser);
END VO:VGD:Table.