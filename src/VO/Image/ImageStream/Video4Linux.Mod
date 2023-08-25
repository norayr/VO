MODULE VO:Image:ImageStream:Video4Linux [FOREIGN "C"; LINK FILE "Video4Linux.c" END];

  (**
    Implements Image streams based on the Video4Linux api.
  *)

  (*
    Video4Linux image stream.
    Copyright (C) 2003 Tim Teulings <rael@edge.ping.de>

    This file is part of VisualOberon.

    VisualOberon is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    VisualOberon is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with VisualOberon. If not, write to the Free Software
    Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
  *)

IMPORT      SYSTEM,

       I := VO:Image:Image,
       S := VO:Image:ImageStream;

TYPE
  InputStream*     = POINTER TO InputStreamDesc;
  InputStreamDesc* = RECORD [VTABLE] (S.InputStreamDesc)
                       internal : SYSTEM.PTR;
                     END;


PROCEDURE Open*(device : ARRAY OF CHAR; channel : LONGINT):InputStream;

PROCEDURE (s : InputStream) GetImageSize*(VAR width : LONGINT;
                                          VAR height : LONGINT);

PROCEDURE (s : InputStream) ReadImage* (result : I.Image):BOOLEAN;

PROCEDURE (s : InputStream) HasMore* ():BOOLEAN;

PROCEDURE (s : InputStream) Close*;

PROCEDURE (s : InputStream) GetHandler*(id : LONGINT):S.Handler;

END VO:Image:ImageStream:Video4Linux.