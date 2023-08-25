MODULE VO:VGD:Toolbar;
  (**
    VGD parser for VO:Toolbar.
  *)

  (*
    VGD parser for VO:Toolbar.
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

       PP  := VO:Prefs:Parser,

       G   := VO:Object,
       T   := VO:Toolbar;

TYPE
  ToolbarParser     = POINTER TO ToolbarParserDesc;
  ToolbarParserDesc = RECORD (VGD.ObjectParserDesc)
                        childId : LONGINT;
                      END;

VAR
  toolbarParser : ToolbarParser;

  PROCEDURE (p : ToolbarParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Toolbar");
    p.childId:=p.RegisterDefaultAttribute(VGD.defaultChildType,"Content of the Toolbar");
  END Init;

  PROCEDURE (p : ToolbarParser) SetAttribute*(object : G.Object;
                                              id : LONGINT; VAR data : VGD.DataDesc;
                                              item : PP.Item;
                                              context : VGD.Context);

  BEGIN
    IF id=p.childId THEN
      object(T.Toolbar).Add(data.object);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : ToolbarParser) CreateInstance*():G.Object;

  BEGIN
    RETURN T.CreateToolbar();
  END CreateInstance;

BEGIN
  NEW(toolbarParser);
  toolbarParser.Init;
  VGD.factory.RegisterObjectParser(toolbarParser);
END VO:VGD:Toolbar.