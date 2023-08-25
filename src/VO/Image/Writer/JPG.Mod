MODULE VO:Image:Writer:JPG [FOREIGN "C"; LINK FILE "JPG.c"; LIB "jpeg" END];

  (**
    Module fro writting jpegs. Jpegs honour the quality field in
    @ofield{Writer.Options.quality}
  *)

  (*
    Image storing subsystem for VisualOberon.
    Copyright (C) 2004 Tim Teulings (rael@edge.ping.de)

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

IMPORT VO:Image:Image,
       VO:Image:Writer;

  PROCEDURE Store*(file : ARRAY OF CHAR;
                   image : Image.Image;
                   options : Writer.Options):BOOLEAN;

END VO:Image:Writer:JPG.