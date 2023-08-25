MODULE VO:Model:DateTime [OOC_EXTENSIONS];

(**
  A model for date and time.
*)

(*
    A model for date and time.
    Copyright (C) 2001 Tim Teulings (rael@edge.ping.de)

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

              Calendar,
       SC  := SysClock,
              Time;

TYPE
  Value         = POINTER TO ValueDesc;
  ValueDesc     = RECORD
                    dateTime : SC.DateTime;
                    last     : Value;
                  END;

  DateTime*     = POINTER TO DateTimeDesc;
  DateTimeDesc* = RECORD (O.ModelDesc)
                    dateTime- : SC.DateTime;
                    last      : Value;
                  END;

  PROCEDURE Equal(VAR this, that : SC.DateTime):BOOLEAN;

  VAR
    i,a : Time.TimeStamp;

  BEGIN
    Calendar.SetTimeStamp(this,i);
    Calendar.SetTimeStamp(that,a);

    RETURN i.Cmp(a)=0;
  END Equal;

  PROCEDURE (d : DateTime) Init*;

  BEGIN
    d.Init^;

    SC.GetClock(d.dateTime);
    d.last:=NIL;
  END Init;

  PROCEDURE (d : DateTime) SetDateTime*(dateTime[NO_COPY] : SC.DateTime);

    (**
      Sets the new value of the model.
    *)

  BEGIN
    d.dateTime:=dateTime;
    d.Notify(NIL);
  END SetDateTime;

  PROCEDURE (d : DateTime) Push*;

  VAR
    value : Value;

  BEGIN
    NEW(value);
    value.dateTime:=d.dateTime;

    value.last:=d.last;
    d.last:=value;
  END Push;

  PROCEDURE (d : DateTime) Undo*;

  VAR
    changed : BOOLEAN;

  BEGIN
    ASSERT(d.last#NIL);

    changed:=~Equal(d.dateTime,d.last.dateTime);

    IF changed THEN
      d.dateTime:=d.last.dateTime;
      d.Notify(NIL);
    END;
  END Undo;

  PROCEDURE (d : DateTime) Save*;

  BEGIN
    ASSERT(d.last#NIL);

    d.last.dateTime:=d.dateTime;
  END Save;

  PROCEDURE (d : DateTime) Pop*;

  VAR
    changed : BOOLEAN;

  BEGIN
    ASSERT(d.last#NIL);

    changed:=~Equal(d.dateTime,d.last.dateTime);

    IF changed THEN
      d.dateTime:=d.last.dateTime;
    END;

    d.last:=d.last.last;

    IF changed THEN
      d.Notify(NIL);
    END;
  END Pop;

  PROCEDURE CreateDateTime*():DateTime;

  VAR
    model : DateTime;

  BEGIN
    NEW(model);
    model.Init;

    RETURN model;
  END CreateDateTime;

END VO:Model:DateTime.