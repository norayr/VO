MODULE VO:Image:Loader:GIF [FOREIGN "C"; LINK FILE "GIF.c"; LIB "gif" END];

  (*
    Image loading subsystem for VisualOberon.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

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

IMPORT      VO:Image:Image,
       L := VO:Image:Loader;

TYPE
  Loader*      = POINTER TO LoaderDesc;
  LoaderDesc*  = RECORD (L.LoaderDesc)
                 END;


VAR
  loader- : Loader;

  PROCEDURE (l : Loader) CanLoad*(file : ARRAY OF CHAR):BOOLEAN;

  PROCEDURE (l : Loader) Load*(file : ARRAY OF CHAR;
                               image : Image.Image):BOOLEAN;


END VO:Image:Loader:GIF.