MODULE VO:VGD:Menu;
  (**
    VGD parser for @otype{M.Menu}.
  *)

  (*
    VGD parser for VO:Menu.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

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

       M   := VO:Menu;

TYPE
  MenuParser*         = POINTER TO MenuParserDesc;
  MenuParserDesc*     = RECORD  (VGD.WindowParserDesc)
                          END;
VAR
  menuParser : MenuParser;

  PROCEDURE (p : MenuParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Menu");
  END Init;

  PROCEDURE (p : MenuParser) ParseEntry(block : PP.Item;
                                        context : VGD.Context):M.MenuEntry;

  VAR
    item      : PP.Item;
    entry     : M.MenuItem;
    sub       : M.SubMenu;
    menu      : M.Menu;
    tmp       : M.MenuEntry;
    id        : LONGINT;
    qualifier : SET;
    key       : STRING;

  BEGIN
    IF block.name^="Item" THEN
      entry:=M.CreateMenuItem();
      item:=block.itemList;
      WHILE item#NIL DO
        WITH item : PP.ValueItem DO
          IF item.name^="label" THEN
            entry.SetTextLabel(item.value);
          ELSIF item.name^="shortcut" THEN
            IF ~D.display.KeyDescriptionToKey(item.value,qualifier,key) THEN
              context.AddError(block,"Cannot parse shortcut description");
              RETURN NIL;
            END;
            entry.SetShortcut(qualifier,key);
          ELSIF item.name^="id" THEN
            id:=0;
            IF ~item.GetInt(id) THEN
              context.AddError(block,"Expected nummerical value");
              RETURN NIL;
            END;
            entry.SetId(id);
          ELSE
            context.AddError(block,"Unknown menu item attribute");
            RETURN NIL;
          END;
        ELSE
          context.AddError(block,"Expected value");
          RETURN NIL;
        END;
        item:=item.next;
      END;
      RETURN entry;
    ELSIF block.name^="Separator" THEN
      IF block.itemList#NIL THEN
        context.AddError(block,"Expected no attributes");
        RETURN NIL;
      END;
      RETURN M.CreateSeparator();
    ELSIF block.name^="Sub" THEN
      sub:=M.CreateSubMenu();
      menu:=M.CreateMenu();
      sub.SetMenu(menu);
      item:=block.itemList;
      WHILE item#NIL DO
        IF  (item IS PP.ValueItem) & (item.name^="label") THEN
          sub.SetTextLabel(item(PP.ValueItem).value);
        ELSE
          tmp:=p.ParseEntry(item,context);
          IF tmp#NIL THEN
            menu.Add(tmp);
          ELSE
            context.AddError(item,"Unknown menu item");
            RETURN NIL;
          END;
        END;
        item:=item.next;
      END;

      RETURN sub;
    END;

    RETURN NIL;
  END ParseEntry;

  PROCEDURE (p : MenuParser) Parse*(window : D.Window;
                                    vgd : PP.Item;
                                    context : VGD.Context):BOOLEAN;

  VAR
    block     : PP.Item;
    menu      : M.Menu;
    entry     : M.MenuEntry;

  BEGIN
    menu:=window(M.Menu);

    block:=vgd.itemList;
    WHILE block#NIL DO
      IF block.name^="name" THEN
      ELSE
        entry:=p.ParseEntry(block,context);
        IF entry#NIL THEN
          menu.Add(entry);
        ELSE
          context.AddError(vgd,"Unknown menu item");
          RETURN FALSE;
        END;
      END;
      block:=block.next;
    END;

    RETURN TRUE;
  END Parse;

BEGIN
  NEW(menuParser);
  menuParser.Init;
  VGD.factory.RegisterWindowParser(menuParser);
END VO:VGD:Menu.