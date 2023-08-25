MODULE VO:VGD:ViewOneOfN;
  (**
    VGD parser for VO:ViewOneOfN.
  *)

  (*
    VGD parser for VO:ViewOneOfN.
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
       OON := VO:ViewOneOfN,

              ADT:StringBuffer;

TYPE
  ViewOneOfNParser     = POINTER TO ViewOneOfNParserDesc;
  ViewOneOfNParserDesc = RECORD (VGD.ObjectParserDesc)
                         END;

VAR
  viewOneOfNParser : ViewOneOfNParser;

  PROCEDURE (p : ViewOneOfNParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("ViewOneOfN");
  END Init;

  PROCEDURE (p : ViewOneOfNParser) GetDocumentation*(buffer : StringBuffer.StringBuffer);

  BEGIN
    p.GetDocumentation^(buffer);

    buffer.Append("<View text='<text>'> <SomeChild /> </Entry>");
    buffer.AppendLn;
  END GetDocumentation;

  PROCEDURE (p : ViewOneOfNParser) CreateInstance*():G.Object;

  BEGIN
    RETURN OON.CreateViewOneOfN();
  END CreateInstance;

  PROCEDURE (p : ViewOneOfNParser) ParseItem*(item : PP.Item;
                                          object : G.Object;
                                          context : VGD.Context):BOOLEAN;

  VAR
    child : G.Object;

  BEGIN
    IF p.ParseItem^(item,object,context) THEN
      RETURN TRUE;
    END;

    IF item.name^="View" THEN
      IF (item.itemList#NIL) & (item.itemList.next#NIL) &
        (item.itemList.next.next=NIL) THEN
        IF (item.itemList IS PP.ValueItem) & (item.itemList.name^="text") THEN
          child:=p.GetChild(item.itemList.next,context);
          IF  (child#NIL) THEN
            object(OON.ViewOneOfN).AddView(item.itemList(PP.ValueItem).value,child);
            RETURN TRUE;
          END
        ELSE
          context.AddError(item,"First attribute must be value 'text'");
        END;
      ELSE
        context.AddError(item,"Expected two childs");
      END;
    END;

    RETURN FALSE;
  END ParseItem;

BEGIN
  NEW(viewOneOfNParser);
  viewOneOfNParser.Init;
  VGD.factory.RegisterObjectParser(viewOneOfNParser);
END VO:VGD:ViewOneOfN.