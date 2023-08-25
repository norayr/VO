(*	$Id: Locales.Mod,v 1.1 2003/05/03 08:20:52 tteuling Exp $	*)
MODULE Locales [FOREIGN "C"; LINK FILE "Locales.c" END];
(*
    Locales - localization information based on the Posix/C facilities.
    Copyright (C) 1996, 1997 Michael Griebling
 
    This module is free software; you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 2 of the
    License, or (at your option) any later version.
 
    This module is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.
 
    You should have received a copy of the GNU Lesser General Public
    License along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*)

<* Warnings := FALSE *>
IMPORT Strings;  (* the C implementation uses this module *)

CONST
  (* Localization identifier definitions -- ids 0 to 99 are reserved *)
  (* NUMERIC category *)
  decimalPoint* = 0;      (* decimal point separator *)
  thousandsSep* = 1;      (* digit group separator to left of dp *)
  grouping* = 2;          (* string groups to left of dp *)

  (* MONETARY category *)
  intCurrencySymbol* = 3; (* international currency symbol *)
  currencySymbol* = 4;    (* local currency symbol *)
  monDecimalPoint* = 5;   (* monetary decimal point separator *)
  monThousandsSep* = 6;   (* monetary digit group separator to left of dp *)
  monGrouping* = 7;       (* monetary string groups to left of dp *)
  positiveSign* = 8;      (* positive monetary quantities *)
  negativeSign* = 9;      (* negative monetary quantities *)
  intFracDigits* = 10;    (* international fractional digits to right of dp *)
  fracDigits* = 11;       (* local fractional digits to right of dp *)
  pCSPrecedes* = 12;      (* positive monetary symbol precedes *)
  pSepBySpace* = 13;      (* positive monetary symbol separated by space *)
  nCSPrecedes* = 14;      (* negative monetary symbol precedes *)
  nSepBySpace* = 15;      (* negative monetary symbol separated by space *)
  pSignPosn* = 16;        (* positive number sign position *)
  nSignPosn* = 17;        (* negative number sign position *)

  (* TIME category *)
  daysOfWeek* = 18;       (* day of week strings -- 18-Sunday, 19-Monday, etc. *)
  months* = daysOfWeek+7; (* month strings -- 25-January, 26-Februrary, etc. *)
  defTimeFormat* = months+12;       (* default time format *)
  defDateFormat* = defTimeFormat+1; (* default date format *)
  defBothFormat* = defDateFormat+1; (* default time/date format *)
  
  startUserID* = 100;

  (* any integer item which is not specified *)
  unspecified* = MAX(SHORTINT);
  
TYPE
  ErrorProc* = PROCEDURE (selector: ARRAY OF CHAR; VAR descr: ARRAY OF CHAR);

VAR
  (* Localization category definitions *)
  ALL- : LONGINT;      (* all possible parameters *)
  COLLATE- : LONGINT;  (* string collation *)
  CTYPE- : LONGINT;    (* character conversion *) 
  MONETARY- : LONGINT; (* money formatting parameters *)
  NUMERIC- : LONGINT;  (* number formatting parameters *)
  TIME- : LONGINT;     (* time/date parameters *)  
  
  GetText* : ErrorProc; (* localized error routine *)

PROCEDURE GetStr * (id: LONGINT; VAR ls: ARRAY OF CHAR) : BOOLEAN;
(* Return the localization string in `ls' which is associated with
   the `id'.  Return FALSE if the localization `id' is invalid, 
   undefined, or not a string. *)

PROCEDURE GetInt * (id: LONGINT) : LONGINT;
(* Return the localization integer which is associated with the `id'.  
   Return MIN(LONGINT) if the localization `id' is invalid, undefined, 
   or not an integer. *)

PROCEDURE Set * (category: LONGINT; name: ARRAY OF CHAR; VAR old: ARRAY OF CHAR);
(* Set a new locale called `name' for the `category' items.  Return the
   previous locale name in `old'. NOTE: Unless the following call is
   made in a user program, all locales will use the "C" defaults and
   environment variables will be ignored:
   
                Locales.Set(Locales.ALL, "", old)
 *)

END Locales.
