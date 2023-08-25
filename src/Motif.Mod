(**
   Interface to some motif defines and structs.
**)

MODULE Motif [INTERFACE "C"];
(* C land ahead.  Enter at your own risk! *)

(*
    Motif Interface lowlevel stuff.
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

CONST

  DND_PROTOCOL_VERSION* = 0;

  XmINITIATOR* = 0;
  XmRECEIVER*  = 1;

  (* D&D message types *)

  XmTOP_LEVEL_ENTER*   = 0;
  XmTOP_LEVEL_LEAVE*   = 1;
  XmDRAG_MOTION*       = 2;
  XmDROP_SITE_ENTER*   = 3;
  XmDROP_SITE_LEAVE*   = 4;
  XmDROP_START*        = 5;
  XmDROP_FINISH*       = 6;
  XmDRAG_DROP_FINISH*  = 7;
  xmOPERATION_CHANGED* = 8;

  (* Operation codes *)

  XmDROP_NOOP* = 0;
  XmDROP_MOVE* = 1;
  XmDROP_COPY* = 2;
  XmDROP_LINK* = 4;

  (* Completion status codes *)

  XmDROP*           = 0;
  XmDROP_HELP*      = 1;
  XmDROP_CANCEL*    = 2;
  XmDROP_INTERRUPT* = 3;

  (* Drop site status codes *)

  XmNO_DROP_SITE*      = 1;
  XmDROP_SITE_INVALID* = 2;
  XmDROP_SITE_VALID*   = 3;
  XmINVALID_DROP_SITE* = 2;
  XmVALID_DROP_SITE*   = 3;

  (* help constants for oberon for accessung d&d flags *)

  flagSet1* =    0;
  flagSet2* =   16;
  flagSet3* =  256;
  flagSet4* = 4096;

  (* Drag protocol styles *)

  XmDRAG_NONE*               = 0;
  XmDRAG_DROP_ONLY*          = 1;
  XmDRAG_PREFER_PREREGISTER* = 2;
  XmDRAG_PREREGISTER*        = 3;
  XmDRAG_PREFER_DYNAMIC*     = 4;
  XmDRAG_PREFER_RECEIVER*    = 5;

TYPE
  XmDndReceiverProp* = RECORD
                         byte_order*       : CHAR;
                         protocol_version* : SHORTINT;
                         protocol_style*   : SHORTINT;
                         pad1*             : SHORTINT;
                         proxy_window*     : LONGINT;
                         num_drop_sites*   : INTEGER;
                         pad2*             : INTEGER;
                         total_size*       : LONGINT;
                       END;

  XmDndInitiatorProp* = RECORD
                          byte_order*       : CHAR;
                          protocol_version* : SHORTINT;
                          target_index*     : INTEGER;
                          selection_atom*   : LONGINT;
                        END;

END Motif.