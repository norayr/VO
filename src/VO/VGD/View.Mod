MODULE VO:VGD:View;
  (**
    VGD parser for VO:View.
  *)

  (*
    VGD parser for VO:View.
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
       V   := VO:View,

              ADT:StringBuffer;

TYPE
  ViewParser     = POINTER TO ViewParserDesc;
  ViewParserDesc = RECORD (VGD.ObjectParserDesc)
                   END;

VAR
  viewParser : ViewParser;

  PROCEDURE (p : ViewParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("View");
  END Init;

  PROCEDURE (p : ViewParser) GetDocumentation*(buffer : StringBuffer.StringBuffer);

  BEGIN
    p.GetDocumentation^(buffer);

    buffer.Append("<default> : SCROLLABLE;");
    buffer.AppendLn;
  END GetDocumentation;

  PROCEDURE (p : ViewParser) CreateInstance*():G.Object;

  VAR
    object : V.View;

  BEGIN
    NEW(object);
    object.Init;

    RETURN object;
  END CreateInstance;

  PROCEDURE (p : ViewParser) ParseItem*(item : PP.Item;
                                        object : G.Object;
                                        context : VGD.Context):BOOLEAN;

  VAR
    child : G.Object;

  BEGIN
    IF p.ParseItem^(item,object,context) THEN
      RETURN TRUE;
    END;

    child:=p.GetChild(item,context);
    IF child#NIL THEN
      IF object(V.View).gadget#NIL THEN
        context.AddError(item,"Expected exactly one child");
      ELSIF ~(child IS G.ScrollableGadget) THEN
        context.AddError(item,"Child must inherit from 'VO:Object:ScrollableGadget'");
      ELSE
        object(V.View).SetGadget(child(G.ScrollableGadget));
        RETURN TRUE;
      END;
    END;

    RETURN FALSE;
  END ParseItem;

BEGIN
  NEW(viewParser);
  viewParser.Init;
  VGD.factory.RegisterObjectParser(viewParser);
END VO:VGD:View.