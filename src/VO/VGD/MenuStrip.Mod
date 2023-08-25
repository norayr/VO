MODULE VO:VGD:MenuStrip;
  (**
    VGD parser for VO:MenuStrip.
  *)

  (*
    VGD parser for VO:MenuStrip.
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
       M   := VO:Menu;

TYPE
  MenuStripParser     = POINTER TO MenuStripParserDesc;
  MenuStripParserDesc = RECORD (VGD.ObjectParserDesc)
                        END;

VAR
  menuStripParser : MenuStripParser;

  PROCEDURE (p : MenuStripParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("MenuStrip");
  END Init;

  PROCEDURE (p : MenuStripParser) CreateInstance*():G.Object;

  BEGIN
    RETURN M.CreateMenuStrip();
  END CreateInstance;

  PROCEDURE (p : MenuStripParser) ParseItem*(item : PP.Item;
                                             object : G.Object;
                                             context : VGD.Context):BOOLEAN;

  VAR
    menu : M.Menu;

  BEGIN
    IF p.ParseItem^(item,object,context) THEN
      RETURN TRUE;
    ELSIF item.name^="TextEntry" THEN
      IF (item.itemList#NIL) & (item.itemList.next#NIL) &
        (item.itemList.next.next=NIL) THEN
        IF (item.itemList IS PP.ValueItem) & (item.itemList.name^="label") &
          (item.itemList.next IS PP.ValueItem) & (item.itemList.next.name^="menu") THEN
          menu:=M.CreateMenu();
          IF ~VGD.LoadWindow(menu,context.vgd,item.itemList.next(PP.ValueItem).value,context) THEN
            context.AddError(item.itemList.next,"Cannot instanciate menu");
            RETURN FALSE;
          END;

          object(M.MenuStrip).AddPullDownMenuString(item.itemList(PP.ValueItem).value,
                                                    menu);
          RETURN TRUE;
        ELSE
          context.AddError(item,"First entry must be value 'label'");
        END;
      ELSE
        context.AddError(item,"Expected two childs");
      END;
    END;

    RETURN FALSE;
  END ParseItem;

BEGIN
  NEW(menuStripParser);
  menuStripParser.Init;
  VGD.factory.RegisterObjectParser(menuStripParser);
END VO:VGD:MenuStrip.