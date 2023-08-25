MODULE VO:VGD:WindowGroup;
  (**
    VGD parser for VO:WindowGroup.
  *)

  (*
    VGD parser for VO:WindowGroup.
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

       WG  := VO:WindowGroup,
       G   := VO:Object;

TYPE
  WindowGroupParser     = POINTER TO WindowGroupParserDesc;
  WindowGroupParserDesc = RECORD (VGD.ObjectParserDesc)
                            mainId,
                            menuId,
                            toolbarId,
                            statusLineId : LONGINT;
                          END;

VAR
  windowGroupParser : WindowGroupParser;

  PROCEDURE (p : WindowGroupParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("WindowGroup");
    p.mainId:=p.RegisterAttribute("Main",VGD.singleChildType,"The main object displayed in the center of the dialog.");
    p.menuId:=p.RegisterAttribute("Menu",VGD.singleChildType,"The optional menu strip.");
    p.toolbarId:=p.RegisterAttribute("Toolbar",VGD.singleChildType,"An optional toolbar.");
    p.statusLineId:=p.RegisterAttribute("StatusLine",VGD.singleChildType,"An optional status line.");
  END Init;

  PROCEDURE (p : WindowGroupParser) SetAttribute*(object : G.Object;
                                                  id : LONGINT; VAR data : VGD.DataDesc;
                                                    item : PP.Item;
                                                    context : VGD.Context);

  BEGIN
    IF id=p.mainId THEN
      object(WG.WindowGroup).SetMain(data.object);
    ELSIF id=p.menuId THEN
      object(WG.WindowGroup).SetMenu(data.object);
    ELSIF id=p.toolbarId THEN
      object(WG.WindowGroup).SetToolbar(data.object);
    ELSIF id=p.statusLineId THEN
      object(WG.WindowGroup).SetStatusLine(data.object);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : WindowGroupParser) CreateInstance*():G.Object;

  BEGIN
    RETURN WG.CreateWindowGroup();
  END CreateInstance;

BEGIN
  NEW(windowGroupParser);
  windowGroupParser.Init;
  VGD.factory.RegisterObjectParser(windowGroupParser);
END VO:VGD:WindowGroup.