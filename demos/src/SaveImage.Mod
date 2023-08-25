MODULE SaveImage;

  (**
    Saves an image to a file. Code is a variant of example "Image".
  *)

(*
    Demo for VO:Image:Image.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

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

IMPORT D   := VO:Base:Display,

       I   := VO:Image:Image,
              VO:Image:Writer,

<* IF HAVE_LIB_JPEG=TRUE THEN *>
              VO:Image:Writer:JPG,
<* END *>

<* IF HAVE_LIB_PNG=TRUE THEN *>
              VO:Image:Writer:PNG,
<* END *>
              VO:Image:Writer:PPM,

              VO:OS:Probe,

              Err;

VAR
  image   : I.Image;
  options : Writer.Options;

  PROCEDURE CreateImage():I.Image;

  VAR
    image : I.Image;
    data  : I.Data;
    x,y   : LONGINT;

  BEGIN
    image:=I.factory.CreateImage();
    NEW(data,256*256);

    FOR y:=0 TO 255 DO
      FOR x:=0 TO 255 DO
        data[y*256+x].r:=CHR(x);
        data[y*256+x].g:=CHR(255-y);
        data[y*256+x].b:=CHR(255-x);
        data[y*256+x].a:=CHR(255);
      END;
    END;
    image.SetData(256,256,FALSE,data);

    RETURN image;
  END CreateImage;

BEGIN
  (*
    Try to initialize it.
    This call make the connection to the X server and allocates
    fonts, colors and that stuff
  *)
  IF ~Probe.OpenDisplay("SaveImage") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  image:=CreateImage();
  options:=Writer.CreateOptions();

<* IF HAVE_LIB_JPEG=TRUE THEN *>
  IF JPG.Store("/tmp/image.jpg",image,options) THEN
    Err.String("Stored image as '/tmp/image.jpg'");Err.Ln;
  ELSE
    Err.String("JPG image NOT Stored!");Err.Ln;
  END;
<* END *>

<* IF HAVE_LIB_PNG=TRUE THEN *>
  IF PNG.Store("/tmp/image.png",image,options) THEN
    Err.String("Stored image as '/tmp/image.png'");Err.Ln;
  ELSE
    Err.String("PNG image NOT Stored!");Err.Ln;
  END;
<* END *>

  IF PPM.Store("/tmp/image.ppm",image,options) THEN
    Err.String("Stored image as '/tmp/image.ppm'");Err.Ln;
  ELSE
    Err.String("PPM image NOT Stored!");Err.Ln;
  END;

  (* Free possible ressources of the display. *)
  D.display.Close;
END SaveImage.