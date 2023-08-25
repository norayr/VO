MODULE VO:Prefs:Base;

  (**
    Baseclass for all preferences stuff.
  *)

  (*
    Baseclass for all preferences stuff.
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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

TYPE
  Prefs     * = POINTER TO PrefsDesc;
  PrefsDesc * = RECORD
                  (**
                    Base class for all preferences classes.
                  *)
                  next : Prefs;
                END;

VAR
  list : Prefs;

  PROCEDURE (p : Prefs) Init*;
  (**
    Initialize the preferences struct. The baseclass adds the instance
    to the global list of instances.
  *)

  BEGIN
    p.next:=list;
    list:=p;
  END Init;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
  END Initialize;

  PROCEDURE (p : Prefs) Free*;

  BEGIN
  END Free;

  PROCEDURE Initialize*(dont : Prefs);
  (**
    Initialize all registered preferences.
  *)

  VAR
    entry : Prefs;

  BEGIN
    entry:=list;
    WHILE entry#NIL DO
      IF entry#dont THEN
        entry.Initialize;
      END;
      entry:=entry.next;
    END;

    list:=NIL;
  END Initialize;

  PROCEDURE Free*;
  (**
    Free all registered preferences.
  *)

  VAR
    entry : Prefs;

  BEGIN
    entry:=list;
    WHILE entry#NIL DO
      entry.Free;
      entry:=entry.next;
    END;

    list:=NIL;
  END Free;

BEGIN
  list:=NIL;
END VO:Prefs:Base.