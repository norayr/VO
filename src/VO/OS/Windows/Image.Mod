MODULE VO:OS:Windows:Image;

  (*
    Image subsystem for VisualOberon.
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

IMPORT       SYSTEM,

       D  := VO:Base:Display,

       I  := VO:Image:Image,

       OD := VO:OS:Windows:Display,

       W := Windows;

TYPE
  ImageData = POINTER TO ARRAY [NO_LENGTH_INFO] OF CHAR;

TYPE
  Image*     = POINTER TO ImageDesc;
  ImageDesc* = RECORD (I.ImageDesc)
                 dc : W.HDC;
                 bitmap : W.HBITMAP;
                 data : ImageData;
               END;

  Factory*       = POINTER TO FactoryDesc;
  FactoryDesc*   = RECORD (I.FactoryDesc)
                   END;

VAR
  factory     : Factory;

  PROCEDURE (i : Image) Init*;
  BEGIN
    i.Init^;

    i.dc := 0;
    i.bitmap := 0;
    i.data := NIL;
  END Init;

  PROCEDURE (i : Image) GetBitmapHeader(VAR info : W.BITMAPINFO);
  BEGIN
    info.bmiHeader.biSize := SIZE(W.BITMAPINFOHEADER);
    info.bmiHeader.biWidth := i.width;
    info.bmiHeader.biHeight := -i.height; (* Top-down bitmap *)
    info.bmiHeader.biPlanes := 1;
    info.bmiHeader.biBitCount := 32;
    info.bmiHeader.biCompression := W.BI_RGB;
    info.bmiHeader.biSizeImage := 0;
    info.bmiHeader.biXPelsPerMeter := 2835; (* 72 DPI *)
    info.bmiHeader.biYPelsPerMeter := 2835; (* 72 DPI *)
    info.bmiHeader.biClrUsed := 0;
    info.bmiHeader.biClrImportant := 0;
  END GetBitmapHeader;

  PROCEDURE (i : Image) CreateOSStructures;

  VAR
    d : OD.Display;
    info : W.BITMAPINFO;
    oldImage : W.HGDIOBJ;
    dataPtr : W.LPVOID;
    off, s : LONGINT;

  BEGIN
    IF i.source=NIL THEN
      RETURN;
    END;

    d := D.display(OD.Display);
    i.dc := W.CreateCompatibleDC(d.hdc);
    IF i.dc =  0 THEN
      OD.Error("Image: Cannot CreateCompatibleDC");
      RETURN;
    END;

    i.GetBitmapHeader(info);

    i.bitmap := W.CreateDIBSection(i.dc,
                                  info,
                                  W.DIB_RGB_COLORS,
                                  dataPtr,
                                  0, 0);
    IF (i.bitmap = 0) THEN
      OD.Error("Image: Failed to CreateDIBSection");
      RETURN;
    END;

    i.data := SYSTEM.VAL(ImageData, dataPtr);
    IF (i.data = NIL) THEN
      OD.Error("Image: No pixel data");
      RETURN;
    END;

    oldImage := W.SelectObject(i.dc, i.bitmap);

    IF W.GdiFlush() # W.TRUE THEN
      OD.Error("Image: GDIFlush");
    END;

    <*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

    off := 0;
    FOR s:=0 TO LEN(i.current^)-1 DO
      i.data[off]:=i.current[s].b;
      INC(off);
      i.data[off]:=i.current[s].g;
      INC(off);
      i.data[off]:=i.current[s].r;
      INC(off);
      i.data[off]:=0X;
      INC(off);
    END;

    <* POP; *>
  END CreateOSStructures;

  PROCEDURE (i : Image) FreeOSStructures*;
  
  BEGIN
    IF i.bitmap # 0 THEN
      IF W.DeleteObject(i.bitmap) # W.TRUE THEN
        OD.Error("Image: Delete bitmap");
      END;
      i.bitmap := 0;
    END;

    IF i.dc # 0 THEN
      IF W.DeleteDC(i.dc) # W.TRUE THEN
        OD.Error("Image: Delete DC");
      END;
      i.dc := 0;
    END;

  END FreeOSStructures;

(* Windows GDI does not support an alpha channel, although
this is available via other APIs such as DirectX and OpenGL.

This code implements an alpha-blend of the current image onto
the current output device bitmap. This implementation will
probably work for most display devices, although it is
probably quite slow.

TODO: Add mask-based transparency for binary alpha channels.

*)

  PROCEDURE (i : Image) AlphaBlend(info : D.DrawInfo;
    sx, sy, w, h, dx, dy : LONGINT);
  TYPE
    PixelDesc = RECORD b, g, r, a : CHAR END;
    Data = POINTER TO ARRAY [NO_LENGTH_INFO] OF PixelDesc;
  VAR
    bitmap : W.HBITMAP;
    oldBitmap : W.HGDIOBJ;
    dc : W.HDC;
    inf : OD.DrawInfo;
    dataPtr : W.LPVOID;
    bi : W.BITMAPINFO;
    src : I.Data; dest : Data;
    srcOff, destOff : LONGINT;
    sr, sg, sb, dr, dg, db, a, a2 : INTEGER;
    k, j: LONGINT;

    bRes : W.BOOL;
    res : LONGINT;
  BEGIN
    IF w > i.width THEN w := i.width END;
    IF h > i.height THEN h := i.height END;

    inf := info(OD.DrawInfo);

    (* Create a bitmap compatible with the output device *)
    dc := W.CreateCompatibleDC(inf.dc);
    bitmap := W.CreateCompatibleBitmap(inf.dc, w, h);
    oldBitmap := W.SelectObject(dc, bitmap);

    (* Copy pixels from output device to temporary bitmap *)
    bRes := W.BitBlt(dc, 0, 0, w, h, inf.dc, dx, dy, W.SRCCOPY);

    (* Get bitmap size *)
    i.GetBitmapHeader(bi);
    bi.bmiHeader.biWidth := w;
    bi.bmiHeader.biHeight := -h;
    res := W.GetDIBits(dc, bitmap, 0, h, 0, bi, W.DIB_RGB_COLORS);

    (* Alllocate memory *)
    dataPtr := W.GlobalAlloc(W.GMEM_FIXED, bi.bmiHeader.biSizeImage);

    (* Fetch pixels into device-independent array *)
    res := W.GetDIBits(dc, bitmap, 0, h, dataPtr, bi, W.DIB_RGB_COLORS);

    IF res # h THEN
      OD.Error("Image:AlphaBlend: GetDIBits");
    ELSE
      (* Perform alpha-blend of image and device bitmap *)
      dest := SYSTEM.VAL(Data, dataPtr);
      src := i.current;

    <*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

      FOR k := 0 TO h-1 DO
        srcOff := (sy + k) * i.width + sx;
        destOff := k * w;
        FOR j := 0 TO w-1 DO
          (* source: our image data *)
          sr := ORD(src[srcOff].r);
          sg := ORD(src[srcOff].g);
          sb := ORD(src[srcOff].b);
          a := ORD(src[srcOff].a);
          a2 := (255 - a);

          (* destination: output device bitmap data *)
          dr := ORD(dest[destOff].r);
          dg := ORD(dest[destOff].g);
          db := ORD(dest[destOff].b);

          (* blend *)
          dest[destOff].r := CHR((sr * a + dr * a2) DIV 256);
          dest[destOff].g := CHR((sg * a + db * a2) DIV 256);
          dest[destOff].b := CHR((sb * a + db * a2) DIV 256);

          INC(srcOff);
          INC(destOff);
        END;
      END;
    <* POP *>
      (* Write result bitmap to device *)
      res := W.SetDIBits(dc, bitmap, 0, h, dataPtr, bi, W.DIB_RGB_COLORS);  
      bRes := W.BitBlt(inf.dc, dx, dy, w, h, dc, 0, 0, W.SRCCOPY);
    END;

    oldBitmap := W.SelectObject(dc, oldBitmap);
    bRes := W.DeleteObject(bitmap);
    bRes := W.DeleteDC(dc);
    dataPtr := W.GlobalFree(dataPtr);
  END AlphaBlend;

  PROCEDURE (i : Image) Draw*(info : D.DrawInfo;
                              x,y : LONGINT);
  VAR bRes : W.BOOL;
  BEGIN
    IF (i.bitmap = 0) THEN
      i.CreateOSStructures;
    END;

    IF i.bitmap # 0 THEN
      IF i.alpha THEN
        i.AlphaBlend(info, 0, 0, i.width, i.height, x, y);
      ELSE
        bRes := W.BitBlt(info(OD.DrawInfo).dc, x, y, i.width, i.height, i.dc, 0, 0, W.SRCCOPY);
      END;
    END;
  END Draw;

  PROCEDURE (i : Image) DrawSub*(info : D.DrawInfo;
                                 x,y,w,h,dx,dy : LONGINT);
  VAR bRes : W.BOOL;
  BEGIN
    IF i.bitmap=0 THEN
      i.CreateOSStructures;
    END;

    IF i.bitmap#0 THEN
      IF i.alpha THEN
        i.AlphaBlend(info, x, y, w, h, dx, dy);
      ELSE
        bRes := W.BitBlt(info(OD.DrawInfo).dc, dx, dy, w, h, i.dc, x, y, W.SRCCOPY);
      END;
    END;
  END DrawSub;

  PROCEDURE (i : Image) DrawSubCliped*(info : D.DrawInfo;
                                       x,y,w,h,dx,dy : LONGINT);

  BEGIN
    (* TODO *)
    IF i.bitmap=0 THEN
      i.CreateOSStructures;
    END;

    IF i.bitmap#0 THEN
      i.DrawSub(info, x, y, w, h, dx, dy);
    END;
  END DrawSubCliped;

  PROCEDURE (i : Image) DrawTiled*(info : D.DrawInfo;
                                   x,y,w,h,dx,dy : LONGINT);
  VAR
    dc : W.HDC;
    hbrush : W.HBRUSH;
    rect : W.RECT;
    res : W.BOOL;
  BEGIN
    (* TODO *)
    IF i.bitmap=0 THEN
      i.CreateOSStructures;
    END;

    IF i.bitmap#0 THEN
      dc := info (OD.DrawInfo).dc;
      hbrush := W.CreatePatternBrush(i.bitmap);
      rect.left := x; rect.top := y;
      rect.right := x + w; rect.bottom := y + h;
      res := W.FillRect(dc, rect, hbrush);
      res := W.DeleteObject(hbrush);
    END;
  END DrawTiled;

  PROCEDURE (i : Image) Free*;

  BEGIN
    i.FreeOSStructures;
  END Free;

  PROCEDURE (f : Factory) Init*(d : D.Display):BOOLEAN;

  BEGIN
    IF ~(d IS OD.Display) THEN
      RETURN FALSE;
    END;

   RETURN TRUE;
  END Init;

  PROCEDURE (f : Factory) Deinit*(display : D.Display);

  BEGIN
  END Deinit;

  PROCEDURE (f : Factory) CreateImage*():I.Image;

  VAR
    image : Image;

  BEGIN
    NEW(image);
    image.Init;

    RETURN image;
  END CreateImage;

BEGIN
  NEW(factory);
  I.Register(factory);
END VO:OS:Windows:Image.
