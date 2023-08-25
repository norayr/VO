MODULE VO:VGD:QuickHelp;
  (**
    VGD parser for VO:QuickHelp.
  *)

  (*
    VGD parser for VO:QuickHelp.
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

IMPORT D   := VO:Base:Display,
              VO:VGD:VGD,

       PP  := VO:Prefs:Parser,

       Q   := VO:QuickHelp,
       G   := VO:Object,

              Object;

TYPE
  QuickHelpParser*         = POINTER TO QuickHelpParserDesc;
  QuickHelpParserDesc*     = RECORD  (VGD.WindowParserDesc)
                             END;
VAR
  helpParser : QuickHelpParser;

  PROCEDURE (p : QuickHelpParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("QuickHelp");
  END Init;

  PROCEDURE (p : QuickHelpParser) Parse*(window : D.Window;
                                         vgd : PP.Item;
                                         context : VGD.Context):BOOLEAN;

  VAR
    block  : PP.Item;
    parser : VGD.ObjectParser;
    object : G.Object;

  BEGIN
    block:=vgd.itemList;
    WHILE (block#NIL) DO
      IF block.name^="name" THEN
      ELSE
        IF window(Q.Help).top#NIL THEN
          context.AddError(block,"QuickHelp can have only one child!");
          RETURN FALSE;
        END;

        parser:=VGD.factory.GetObjectParser(Object.NewLatin1(block.name^));
        IF parser=NIL THEN
          context.AddError(block,"Cannot find parser for object");
          RETURN FALSE;
        ELSE
          object:=parser.Parse(block,context);
          IF object=NIL THEN
            context.AddError(block,"Cannot instantiate child object");
            RETURN FALSE;
          END;
          window(Q.Help).SetTop(object);
        END;
      END;
      block:=block.next;
    END;

    IF window(Q.Help).top=NIL THEN
      context.AddError(vgd,"QuickHelp has no children");
      RETURN FALSE;
    END;

    RETURN TRUE;
  END Parse;

BEGIN
  NEW(helpParser);
  helpParser.Init;
  VGD.factory.RegisterWindowParser(helpParser);
END VO:VGD:QuickHelp.