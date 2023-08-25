MODULE VO:Edit:Block [OOC_EXTENSIONS];

(**
  Handles allocating of textblocks and text within textblocks.
*)

  (*
    Part of the VO internal multiline text edit control.
    Copyright (C) 2003 Tim Teulings

    This module is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with OOC. If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

CONST
  blockLen * = 128(*8192*); (** The size of one block *)

TYPE
  (**
    The text within a block.
  *)

  TextDesc*  = ARRAY blockLen OF CHAR;


  Block*     = POINTER TO BlockDesc;
  BlockDesc* = RECORD
                 (**
                   A block of texts. Runs point to an area within a block.
                 *)
                 text* : TextDesc; (** The text                     *)
                 size* : LONGINT;  (** Used space, should be global *)
               END;

VAR
  block-      : Block;  (** current textstore-buffer *)


  (*****************************************
   * Buffer handling routines
   *****************************************)

  PROCEDURE GetNewBlock();

  (**
    Allocates a new block.
  *)

  BEGIN
    NEW(block);
    block.size:=0;
  END GetNewBlock;

  PROCEDURE GetBlockWithSize*(size : LONGINT);

  (**
    Allocates a new block with the given size. It is garanteed
    that block points to a block for text with at least the given size.

    NOTE
    The size given must no exceed the maximum size of a block.
  *)

  BEGIN
    ASSERT(size<=blockLen);

    IF block=NIL THEN
      GetNewBlock;
    ELSIF size>blockLen-block.size THEN
      GetNewBlock;
    END;
  END GetBlockWithSize;

  PROCEDURE StoreAreaInBlock*(text[NO_COPY] : ARRAY OF CHAR; from,size : LONGINT):LONGINT;

  (**
    Stores the text of the given size into the current block.

    RESULT
    Returns the starting position of the copied text within the block.

    NOTE
    Size must not exceed the maximum size of a block.
  *)

  VAR x,y,result : LONGINT;

  BEGIN
    ASSERT(size<=blockLen);

    GetBlockWithSize(size);

    (* Text copy, could be optimized *)
    y:=block.size;
    result:=block.size;
    FOR x:=from TO from+size-1 DO
      block.text[y]:=text[x];
      INC(y);
    END;

    INC(block.size,size);
    RETURN result;
  END StoreAreaInBlock;

  PROCEDURE StoreInBlock*(text[NO_COPY] : ARRAY OF CHAR; size : LONGINT):LONGINT;

  (**
    Stores the text of the given size into the current block.

    RESULT
    Returns the starting position of the copied text within the block.

    NOTE
    Size must not exceed the maximum size of a block.
  *)

  VAR x,y,result : LONGINT;

  BEGIN
    ASSERT(size<=blockLen);

    GetBlockWithSize(size);

    (* Text copy, could be optimized *)
    y:=block.size;
    result:=block.size;
    FOR x:=0 TO size-1 DO
      block.text[y]:=text[x];
      INC(y);
    END;

    INC(block.size,size);
    RETURN result;
  END StoreInBlock;

  PROCEDURE StoreCharsInBlock*(char : CHAR; count : LONGINT):LONGINT;

  (**
    Stores the given character count times in the current block.

    RESULT
    Returns the starting position of the copied text within the block.

    NOTE
    Size must not exceed the maximum size of a block.
  *)

  VAR x,y,result : LONGINT;

  BEGIN
    ASSERT(count<=blockLen);

    GetBlockWithSize(count);

    (* Text copy, could be optimized *)
    y:=block.size;
    result:=block.size;
    FOR x:=0 TO count-1 DO
      block.text[y]:=char;
      INC(y);
    END;

    INC(block.size,count);
    RETURN result;
  END StoreCharsInBlock;

  PROCEDURE StoreCharInBlock*(char : CHAR):LONGINT;

  (**
    Stores the given character in the current block.

    RESULT
    Returns the starting position of the copied text within the block.

    NOTE
    Size must not exceed the maximum size of a block.
  *)

  VAR result : LONGINT;

  BEGIN
    GetBlockWithSize(1);

    result:=block.size;
    block.text[block.size]:=char;

    INC(block.size);
    RETURN result;
  END StoreCharInBlock;

END VO:Edit:Block.