MODULE VO:VGD:Tab;
  (**
    VGD parser for VO:Tab.
  *)

  (*
    VGD parser for VO:Tab.
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
       T   := VO:Tab,

              ADT:StringBuffer;

TYPE
  TabParser     = POINTER TO TabParserDesc;
  TabParserDesc = RECORD (VGD.ObjectParserDesc)
                  END;

VAR
  tabParser : TabParser;

  PROCEDURE (p : TabParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Tab");
  END Init;

  PROCEDURE (p : TabParser) GetDocumentation*(buffer : StringBuffer.StringBuffer);

  BEGIN
    p.GetDocumentation^(buffer);

    buffer.Append("<TextRider text='<text>'> <SomeChild /> </TextRider> | <Rider> <SomeLabel /> <SomeChild/> </Rider>");
    buffer.AppendLn;
  END GetDocumentation;

  PROCEDURE (p : TabParser) CreateInstance*():G.Object;

  BEGIN
    RETURN T.CreateTab();
  END CreateInstance;

  PROCEDURE (p : TabParser) ParseItem*(item : PP.Item;
                                       object : G.Object;
                                       context : VGD.Context):BOOLEAN;

  VAR
    child1,
    child2  : G.Object;

  BEGIN
    IF p.ParseItem^(item,object,context) THEN
      RETURN TRUE;
    END;

    IF item.name^="Rider" THEN
      IF (item.itemList#NIL) & (item.itemList.next#NIL) &
        (item.itemList.next.next=NIL) THEN
        child1:=p.GetChild(item.itemList,context);
        child2:=p.GetChild(item.itemList.next,context);
        IF (child1#NIL) & (child2#NIL) THEN
          object(T.Tab).AddTab(child1,child2);
          RETURN TRUE;
        END
      ELSE
        context.AddError(item,"Expected two attributes");
      END;
    ELSIF item.name^="TextRider" THEN
      IF (item.itemList#NIL) & (item.itemList.next#NIL) &
        (item.itemList.next.next=NIL) THEN
        IF (item.itemList IS PP.ValueItem) & (item.itemList.name^="text") THEN
          child2:=p.GetChild(item.itemList.next,context);
          IF  (child2#NIL) THEN
            object(T.Tab).AddStringTab(item.itemList(PP.ValueItem).value,child2);
            RETURN TRUE;
          END
        ELSE
          context.AddError(item,"First attribute must be value 'text'");
        END;
      ELSE
        context.AddError(item,"Expected two attributes");
      END;
    END;

    RETURN FALSE;
  END ParseItem;

BEGIN
  NEW(tabParser);
  tabParser.Init;
  VGD.factory.RegisterObjectParser(tabParser);
END VO:VGD:Tab.