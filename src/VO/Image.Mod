MODULE VO:Image;

  (**
    Implements @otype{Image}.
  *)

  (*
    A class for loading and displaying images.
    Copyright (C) 1997 Tim Teulings (rael@edge.ping.de)

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
       I   := VO:Base:Image,

       G   := VO:Object,

              Object,
              OS:Path;


TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  Image*     = POINTER TO ImageDesc;
  ImageDesc* = RECORD (G.ImageDesc)
                 image- : I.Image;
                 bitmap : D.Bitmap;
               END;

VAR
  prefs : Prefs;

  PROCEDURE (i : Image) Init*;

  BEGIN
    i.Init^;

    i.image:=NIL;
    i.bitmap:=NIL;
  END Init;

  PROCEDURE (i : Image) SetImage*(image : I.Image);

    (**
      Set an image directly.
    *)

  BEGIN
    IF i.image#NIL THEN
      i.image.Free;
    END;
    i.image:=image;

    IF D.canDrawDisabled IN i.image.drawCap THEN
      i.SetFlags({G.canDisable});
    END;

    IF D.canDrawFocused IN i.image.drawCap THEN
      i.RemoveFlags({G.stdFocus});
    END;

    IF i.image.alpha THEN
      i.SetBackgroundObject(NIL);
    END;
  END SetImage;

  PROCEDURE (i : Image) SetFilename*(name : STRING);

    (**
      Set the filename of an image in the filesystem. Must be set before use.
    *)

  VAR
    file : Object.CharsLatin1;

  BEGIN
    file:=Path.Encode(name);
    i.SetImage(I.CreateFileImage(file^,""));
  END SetFilename;

  PROCEDURE (i : Image) SetInternal*(type : LONGINT);

    (**
      Set the type of an internal image. Must be set before use.
    *)

  BEGIN
    i.SetImage(I.CreateVecImage(type));
  END SetInternal;

  PROCEDURE (i : Image) CalcSize*;

  BEGIN
    IF i.image#NIL THEN
      i.width:=i.image.width;
      i.height:=i.image.height;
    ELSE
      IF D.display.displayType=D.displayTypeTextual THEN
        i.width:=1;
        i.height:=1;
      ELSE
        i.width:=20;
        i.height:=20;
      END;
    END;

    i.minWidth:=i.width;
    i.minHeight:=i.height;

    i.CalcSize^;
  END CalcSize;

  PROCEDURE (i : Image) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~i.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    i.Draw^(x,y,w,h);

    IF (i.width=0) OR (i.height=0) OR (w=0) OR (h=0) THEN
      RETURN;
    END;

    IF i.image#NIL THEN
      IF i.image.alpha THEN
        IF (i.bitmap=NIL) OR (i.bitmap.width#i.width) OR (i.bitmap.height#i.height) THEN
          IF i.bitmap#NIL THEN
            D.display.FreeBitmap(i.bitmap);
          END;
          i.bitmap:=D.display.CreateBitmap(i.width,i.height);
        END;
      END;

      draw:=i.GetDrawInfo();

      IF i.bitmap#NIL THEN
        i.bitmap.draw.mode:=draw.mode;
        i.DrawBackgroundWithDrawInfo(i.bitmap.draw,0,0,0,0,i.width,i.height);
        i.image.Draw(i.bitmap.draw,0,0,i.width,i.height);
        draw.CopyFromBitmap(i.bitmap,0,0,i.width,i.height,i.x,i.y);
      ELSE
        IF i.image.alpha THEN
          i.DrawBackground(i.x,i.y,i.width,i.height);
        END;
        i.image.Draw(draw,i.x,i.y,i.width,i.height);
      END;
    END;
  END Draw;

  PROCEDURE (i : Image) Free*;

  BEGIN
    IF i.bitmap#NIL THEN
      D.display.FreeBitmap(i.bitmap);
    END;

    IF i.image#NIL THEN
      i.image.Free;
      i.image:=NIL;
    END;
  END Free;

  PROCEDURE CreateImage*():Image;

    (**
      Creates a new instance of @otype{Image}.
    *)

  VAR
    image : Image;

  BEGIN
    NEW(image);
    image.Init;

    RETURN image;
  END CreateImage;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Image.