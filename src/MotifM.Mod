(**
   Some motif macros.
**)

MODULE MotifM;

(*
    Some motif macros.
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

  PROCEDURE GetEventType*(flag : CHAR):INTEGER;

  BEGIN
    RETURN (ORD(flag) DIV 128) MOD 2;
  END GetEventType;

  PROCEDURE GetMsgType*(flag : CHAR):INTEGER;

  BEGIN
    RETURN ORD(flag) MOD 128;
  END GetMsgType;

  PROCEDURE GetOperation*(flag : INTEGER):INTEGER;

  BEGIN
    RETURN flag MOD 16;
  END GetOperation;

  PROCEDURE GetStatus*(flag : INTEGER):INTEGER;

  BEGIN
    RETURN (flag DIV 16) MOD 16;
  END GetStatus;

  PROCEDURE GetOperations*(flag : INTEGER):INTEGER;

  BEGIN
    RETURN (flag DIV 256) MOD 16;
  END GetOperations;

  PROCEDURE GetCompletition*(flag : INTEGER):INTEGER;

  BEGIN
    RETURN (flag DIV 4096) MOD 16;
  END GetCompletition;


  PROCEDURE SetEventType*(VAR flag : CHAR; value : LONGINT);

  BEGIN
    flag:=CHR(ORD(flag)+(value MOD 2)*128);
  END SetEventType;

  PROCEDURE SetOperation*(VAR flag : INTEGER; value : LONGINT);

  BEGIN
    INC(flag,SHORT(value MOD 16));
  END SetOperation;

  PROCEDURE SetStatus*(VAR flag: INTEGER; value : LONGINT);

  BEGIN
    INC(flag,SHORT((value MOD 16) * 16));
  END SetStatus;

  PROCEDURE SetOperations*(VAR flag: INTEGER; value : LONGINT);

  BEGIN
    INC(flag,SHORT((value MOD 16) * 256));
  END SetOperations;

  PROCEDURE SetCompletition*(VAR flag: INTEGER; value : LONGINT);

  BEGIN
    INC(flag,SHORT((value MOD 16) * 4096));
  END SetCompletition;

END MotifM.