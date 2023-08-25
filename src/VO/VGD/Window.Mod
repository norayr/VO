MODULE VO:VGD:Window;
  (**
    VGD parser for VO:Window.
  *)

  (*
    VGD parser for VO:Window.
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

       W   := VO:Window,
       G   := VO:Object,

              Object;

TYPE
  WindowParser*         = POINTER TO WindowParserDesc;
  WindowParserDesc*     = RECORD  (VGD.WindowParserDesc)
                          END;
VAR
  windowParser : WindowParser;

  PROCEDURE (p : WindowParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Window");
  END Init;

  PROCEDURE (p : WindowParser) ReadFocusList(window : W.Window;
                                             vgd : PP.Item;
                                             context : VGD.Context):BOOLEAN;

  VAR
    entry  : PP.Item;
    object : G.Object;

  BEGIN
    IF window.top=NIL THEN
      context.AddError(vgd,"Cannot define focus object if window has no child");
      RETURN FALSE;
    END;

    vgd:=vgd.itemList;
    WHILE vgd#NIL DO
      IF vgd.name^="Object" THEN
        IF (vgd.itemList#NIL) & (vgd.itemList.next=NIL) &
          (vgd.itemList IS PP.ValueItem) THEN
          object:=window.top.GetObjectByName(vgd.itemList(PP.ValueItem).value);
          IF object#NIL THEN
            object.RequestFocus();
          ELSE
            context.AddError(vgd.itemList,"Object not found");
            RETURN FALSE;
          END;
        ELSE
          context.AddError(vgd,"One value parameter expected");
          RETURN FALSE;
        END;
      ELSIF vgd.name^="Group" THEN
        entry:=vgd.itemList;
        WHILE entry#NIL DO
          WITH entry : PP.ValueItem DO
            object:=window.top.GetObjectByName(vgd.itemList(PP.ValueItem).value);
            IF object#NIL THEN
              IF entry=vgd.itemList THEN
                object.RequestFocus();
              ELSE
                object.RequestFocus(); (* TODO: grouping *)
              END;
            ELSE
              context.AddError(vgd.itemList,"Object not found");
              RETURN FALSE;
            END;
          ELSE
            context.AddError(vgd.itemList,"Value expected");
            RETURN FALSE;
          END;
          entry:=entry.next;
        END;
      ELSE
        context.AddError(vgd,"Unknown attribute");
        RETURN FALSE;
      END;
      vgd:=vgd.next;
    END;

    RETURN TRUE;
  END ReadFocusList;

  PROCEDURE (p : WindowParser) Parse*(window : D.Window;
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
      ELSIF block.name^="title" THEN
        WITH block : PP.ValueItem DO
          window.SetTitle(block.value);
        ELSE
          context.AddError(block,"Expected value");
        END;
      ELSIF block.name^="style" THEN
        WITH block : PP.ValueItem DO
          IF block.HasValue("popup") THEN
            window(W.Window).SetType(D.windowTypePopup);
          ELSIF block.HasValue("normal") THEN
            window(W.Window).SetType(D.windowTypeAuto);
          ELSE
            context.AddError(block,"Unknown value");
          END;
        ELSE
          context.AddError(block,"Expected value");
        END;
      ELSIF block.name^="Focus" THEN
        IF ~p.ReadFocusList(window(W.Window),block,context) THEN
          RETURN FALSE;
        END;
      ELSE
        IF window(W.Window).top#NIL THEN
          context.AddError(block,"Window can have only one child!");
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
          window(W.Window).SetTop(object);
        END;
      END;
      block:=block.next;
    END;

    IF window(W.Window).top=NIL THEN
      context.AddError(vgd,"Window has no children");
      RETURN FALSE;
    END;

    RETURN TRUE;
  END Parse;

BEGIN
  NEW(windowParser);
  windowParser.Init;
  VGD.factory.RegisterWindowParser(windowParser);
END VO:VGD:Window.
