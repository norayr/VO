MODULE VO:VGD:Label;
  (**
    VGD parser for VO:Label.
  *)

  (*
    VGD parser for VO:Label.
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
       L   := VO:Label,

              ADT:StringBuffer;

TYPE
  LabelParser     = POINTER TO LabelParserDesc;
  LabelParserDesc = RECORD (VGD.ObjectParserDesc)
                    END;

VAR
  labelParser : LabelParser;

  PROCEDURE (p : LabelParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Label");
  END Init;

  PROCEDURE (p : LabelParser) GetDocumentation*(buffer : StringBuffer.StringBuffer);

  BEGIN
    p.GetDocumentation^(buffer);

    buffer.Append("<TextEntry text='<text>'> <SomeChild /> </TextEntry> | <Entry> <SomeLabel /> <SomeChild/> </Entry>");
    buffer.AppendLn;
  END GetDocumentation;

  PROCEDURE (p : LabelParser) CreateInstance*():G.Object;

  BEGIN
    RETURN L.CreateLabel();
  END CreateInstance;

  PROCEDURE (p : LabelParser) ParseItem*(item : PP.Item;
                                         object : G.Object;
                                         context : VGD.Context):BOOLEAN;

  VAR
    child1,
    child2  : G.Object;

  BEGIN
    IF p.ParseItem^(item,object,context) THEN
      RETURN TRUE;
    END;

    IF item.name^="Entry" THEN
      IF (item.itemList#NIL) & (item.itemList.next#NIL) &
        (item.itemList.next.next=NIL) THEN
        child1:=p.GetChild(item.itemList,context);
        child2:=p.GetChild(item.itemList.next,context);
        IF (child1#NIL) & (child2#NIL) THEN
          object(L.Label).AddLabel(child1,child2);
          RETURN TRUE;
        END
      ELSE
        context.AddError(item,"Expected two childs");
      END;

    ELSIF item.name^="TextEntry" THEN
      IF (item.itemList#NIL) & (item.itemList.next#NIL) &
        (item.itemList.next.next=NIL) THEN
        IF (item.itemList IS PP.ValueItem) & (item.itemList.name^="text") THEN
          child2:=p.GetChild(item.itemList.next,context);
          IF  (child2#NIL) THEN
            object(L.Label).AddStringLabel(item.itemList(PP.ValueItem).value,child2);
            RETURN TRUE;
          END
        ELSE
          context.AddError(item,"First entry must be value 'text'");
        END;
      ELSE
        context.AddError(item,"Expected two childs");
      END;
    END;

    RETURN FALSE;
  END ParseItem;

BEGIN
  NEW(labelParser);
  labelParser.Init;
  VGD.factory.RegisterObjectParser(labelParser);
END VO:VGD:Label.