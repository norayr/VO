MODULE VO:Model:Size [OOC_EXTENSIONS];

(**
  A model for @code{VO:Base:Size}.
*)

(*
  A model for VO:Base:Size
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

IMPORT O   := VO:Base:Object,
       Z   := VO:Base:Size;

TYPE
  Value         = POINTER TO ValueDesc;
  ValueDesc     = RECORD
                    size : Z.SizeDesc;
                    last : Value;
                  END;

  Size*         = POINTER TO SizeDesc;
  SizeDesc*     = RECORD (O.ModelDesc)
                    size- : Z.SizeDesc;
                    last  : Value;
                  END;

  PROCEDURE Equal(VAR this, that : Z.SizeDesc):BOOLEAN;

  BEGIN
    RETURN (this.mode=that.mode) & (this.size=that.size);
  END Equal;

  PROCEDURE (s : Size) Init*;

  BEGIN
    s.Init^;

    s.size.Init;
    s.last:=NIL;
  END Init;

  PROCEDURE (s : Size) SetSize*(size[NO_COPY] : Z.SizeDesc);

    (**
      Sets the new value of the model.
    *)

  BEGIN
    s.size:=size;
    s.Notify(NIL);
  END SetSize;

  PROCEDURE (s : Size) Push*;

  VAR
    value : Value;

  BEGIN
    NEW(value);
    value.size:=s.size;

    value.last:=s.last;
    s.last:=value;
  END Push;

  PROCEDURE (s : Size) Undo*;

  VAR
    changed : BOOLEAN;

  BEGIN
    ASSERT(s.last#NIL);

    changed:=~Equal(s.size,s.last.size);

    IF changed THEN
      s.size:=s.last.size;
      s.Notify(NIL);
    END;
  END Undo;

  PROCEDURE (s : Size) Save*;

  BEGIN
    ASSERT(s.last#NIL);

    s.last.size:=s.size;
  END Save;

  PROCEDURE (s : Size) Pop*;

  VAR
    changed : BOOLEAN;

  BEGIN
    ASSERT(s.last#NIL);

    changed:=~Equal(s.size,s.last.size);

    IF changed THEN
      s.size:=s.last.size;
    END;

    s.last:=s.last.last;

    IF changed THEN
      s.Notify(NIL);
    END;
  END Pop;

  PROCEDURE CreateSize*():Size;

  VAR
    model : Size;

  BEGIN
    NEW(model);
    model.Init;

    RETURN model;
  END CreateSize;

END VO:Model:Size.