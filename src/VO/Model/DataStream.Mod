
MODULE VO:Model:DataStream;
  (**
    A model for stream-like nummerical data input.
  *)

(*
    A model for stream-like nummerical data input.
    Copyright (C) 1998  Tim Teulings (rael@edge.ping.de)

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

IMPORT O := VO:Base:Object;

CONST
  notifyExplicit* = 0;
  notifyImplicit* = 1;

TYPE
  StreamLongModel*     = POINTER TO StreamLongModelDesc;
  StreamLongModelDesc* = RECORD (O.ModelDesc)
                           (**
                             A model for stream-like nummerical data input.
                           *)
                           notifyMode- : LONGINT;
                           value-      : POINTER TO ARRAY OF LONGINT;
                         END;

  PROCEDURE (s : StreamLongModel) Init*;

  BEGIN
    s.Init^;

    s.notifyMode:=notifyExplicit;
    s.value:=NIL;
  END Init;

  PROCEDURE (s : StreamLongModel) SetSize*(size : LONGINT);

    (**
      Sets the number of data stream channels. You assign a channel
      count to the model before you can assign any values to it.

      You can resize the model but currently all
      previous stored data will be lost.
    *)

  BEGIN
    NEW(s.value,size);
  END SetSize;

  PROCEDURE (s : StreamLongModel) SetNotificationMode*(mode : LONGINT);

    (**
      Sets the notifycation mode of the model.
    *)

  BEGIN
    s.notifyMode:=mode;
  END SetNotificationMode;

  PROCEDURE (s : StreamLongModel) SetValue*(value,channel : LONGINT);
    (**
      Assigns a value to a given channel of the model. Note that the point of
      notification of the assignment will be determinented by the notification
      mode of the model.
    *)

  BEGIN
    s.value[channel]:=value;
    IF s.notifyMode=notifyImplicit THEN
      s.Notify(NIL);
    END;
  END SetValue;

  PROCEDURE (s : StreamLongModel) GetValue*(channel : LONGINT):LONGINT;

    (**
      Returns the current value of the specified channel.
    *)

  BEGIN
    RETURN s.value[channel];
  END GetValue;

  PROCEDURE (s : StreamLongModel) TriggerNotify*;

    (**
      Explicitely generate a notification after setting a number of
      values. You can only trigger a notification if the model is in the
      corresponding mode.
    *)

  BEGIN
    ASSERT(s.notifyMode=notifyExplicit);

    s.Notify(NIL);
  END TriggerNotify;

END VO:Model:DataStream.