MODULE VO:VGD:Tree;
  (**
    VGD parser for VO:Tree.
  *)

  (*
    VGD parser for VO:Tree.
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
       T   := VO:Tree;


TYPE
  TreeParser          = POINTER TO TreeParserDesc;
  TreeParserDesc      = RECORD (VGD.ObjectParserDesc)
                        END;

VAR
  treeParser : TreeParser;

  PROCEDURE (p : TreeParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Tree");
  END Init;

  PROCEDURE (p : TreeParser) CreateInstance*():G.Object;

  BEGIN
    RETURN T.CreateTree();
  END CreateInstance;

BEGIN
  NEW(treeParser);
  treeParser.Init;
  VGD.factory.RegisterObjectParser(treeParser);
END VO:VGD:Tree.