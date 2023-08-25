MODULE VO:Prefs:ButtonRow;

(*
    Copyright (C) 1999  Tim Teulings (rael@edge.ping.de)

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

IMPORT Z   := VO:Base:Size,

       GP  := VO:Prefs:Object,
       PP  := VO:Prefs:Parser,

       BR  := VO:ButtonRow,
       G   := VO:Object;

TYPE
  Item*     = POINTER TO ItemDesc;
  ItemDesc* = RECORD (GP.PrefsItemDesc)
              END;

VAR
  prefs : Item;

  PROCEDURE (d : Item) Init*;

  BEGIN
    d.Init^;
    d.SetName("ButtonRow");

    d.SetPrefs(BR.prefs);
  END Init;

  PROCEDURE (p : Item) LoadTheme*(top : PP.Item);

  VAR
    buffer : ARRAY 256 OF CHAR;
    pos    : LONGINT;

  BEGIN
    p.LoadTheme^(top);

    Z.LoadSize("space",top,BR.prefs.space);

    IF top.GetStringEntry("alignment",buffer) THEN
      pos:=G.GetAlignment(buffer);
      IF pos>=0 THEN
        BR.prefs.alignment:=pos;
      ELSE
        p.ErrorWrongData("alignment",buffer);
      END;
    END;
  END LoadTheme;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:ButtonRow.