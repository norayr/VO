MODULE VO:Image:Loader:All;

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

<*PUSH; Warnings:=FALSE; *>

IMPORT
  <* IF HAVE_LIB_PNG=TRUE THEN *>
  VO:Image:Loader:PNG,
  <* END *>

  <* IF HAVE_LIB_JPEG=TRUE THEN *>
  VO:Image:Loader:JPG,
  <* END *>

  <* IF HAVE_LIB_GIF=TRUE THEN *>
  VO:Image:Loader:GIF,
  <* END *>

  <* IF HAVE_LIB_TIFF=TRUE THEN *>
  VO:Image:Loader:TIF,
  <* END *>

(*  <* IF HAVE_LIB_XPM=TRUE THEN *>
  VO:Image:Loader:XPM,
  <* END *>*)

  Err; (* Only a dummy *)
<* POP *>

END VO:Image:Loader:All.