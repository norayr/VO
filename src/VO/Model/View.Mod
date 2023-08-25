MODULE VO:Model:View[OOC_EXTENSIONS];

(**
  A @otype{View} is a collection of @otype{O.Model}s.
  Each model instance has a nmae, and thus can be referenced by this
  name. The @otype{View} suplies methods to call method specific
  methods like @oproc{O.Model.Push} or
  @oproc{O.Model.Pop} for all members of the view
  simultaniously.
*)

(*
  A collection container for name models inheriting from
    VO:Base:Object:Model.
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

IMPORT O   := VO:Base:Object;

TYPE
  Entry*     = POINTER TO EntryDesc;
  EntryDesc* = RECORD
                 next-  : Entry;
                 name-  : STRING;
                 model- : O.Model;
               END;

  View*     =  POINTER TO ViewDesc;
  ViewDesc* =  RECORD
                 (**
                   A view holds a list of instances derived from
                   @otype{O.Model}.
                 *)
                 list-,
                 last   : Entry;
               END;

  PROCEDURE (v : View) Init*;

    (**
      Initialize the @otype{View}. This must be called just after
      allocation.
    *)

  BEGIN
    v.list:=NIL;
    v.last:=NIL;
  END Init;

  PROCEDURE (v : View) RegisterModel*(name : STRING; model : O.Model);

    (**
      Register the model under the given name. Every name must be unique.

      It is required that the models correctly implement
      @oproc{O.Model.Push},
      @oproc{O.Model.Pop},
      @oproc{O.Model.Save},
      @oproc{O.Model.Undo}
    *)

  VAR
    entry : Entry;

  BEGIN
    NEW(entry);
    entry.name:=name;
    entry.model:=model;
    entry.next:=NIL;

    IF v.list=NIL THEN
      v.list:=entry;
    ELSE
      v.last.next:=entry;
    END;
    v.last:=entry;
  END RegisterModel;

  PROCEDURE (v : View) GetModel*(name : STRING):O.Model;

  VAR
    entry : Entry;

  BEGIN
    entry:=v.list;
    WHILE entry#NIL DO
      IF entry.name=name THEN
        RETURN entry.model;
      END;
      entry:=entry.next;
    END;

    RETURN NIL;
  END GetModel;

  PROCEDURE (v : View) Backup*;

    (**
      Open up a new backup level.
    *)

  VAR
    entry : Entry;

  BEGIN
    entry:=v.list;
    WHILE entry#NIL DO
      entry.model.Push;
      entry:=entry.next;
    END;
  END Backup;

  PROCEDURE (v : View) DropBackup*;

    (**
      Throw way the current backup level and restore the
      value the models had before the last backup level was created.
    *)

  VAR
    entry : Entry;

  BEGIN
    entry:=v.list;
    WHILE entry#NIL DO
      entry.model.Pop;
      entry:=entry.next;
    END;
  END DropBackup;

  PROCEDURE (v : View) StoreCurrent*;

    (**
      Store the value of the current backup level in the last backup level
      to make changes permanent.
    *)

  VAR
    entry : Entry;

  BEGIN
    entry:=v.list;
    WHILE entry#NIL DO
      entry.model.Save;
      entry:=entry.next;
    END;
  END StoreCurrent;

  PROCEDURE (v : View) Restore*;

    (**
      Copy back the value from the last backup level into the current
      backup level.
    *)

  VAR
    entry : Entry;

  BEGIN
    entry:=v.list;
    WHILE entry#NIL DO
      entry.model.Undo;
      entry:=entry.next;
    END;
  END Restore;

  PROCEDURE CreateView*():View;

  VAR
    view : View;

  BEGIN
    NEW(view);
    view.Init;

    RETURN view;
  END CreateView;

END VO:Model:View.