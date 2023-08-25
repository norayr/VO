MODULE VO:OS:X11:Image;

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

       OD := VO:OS:X11:Display,

             X11:X11,
             X11:Xutil,
<* IF HAVE_LIB_XRENDER=TRUE THEN *>
             X11:Xrender,
<* END *>
             C,
             Err;

TYPE
  Image*     = POINTER TO ImageDesc;
  ImageDesc* = RECORD (I.ImageDesc)
                     data       : POINTER TO ARRAY OF CHAR; (** The OS-dependend data *)
                     pixmap     : X11.Pixmap;    (** The X11 pixmap *)
                     shape      : X11.Pixmap;
<* IF HAVE_LIB_XRENDER=TRUE THEN *>
                     picture    : Xrender.Picture;
<* END *>
               END;

  Factory*       = POINTER TO FactoryDesc;
  FactoryDesc*   = RECORD (I.FactoryDesc)
                   END;

VAR
  factory     : Factory;
  display     : X11.DisplayPtr;
  scrNum      : LONGINT;
  visual      : X11.VisualPtr;
  depth       : LONGINT;
  colorMap    : X11.Colormap;
<* IF HAVE_LIB_XRENDER=TRUE THEN *>
  render      : BOOLEAN;
  format,
  alphaFormat : Xrender.XRenderPictFormatPtr;
<* END *>

  PROCEDURE (i : Image) Init*;

  BEGIN
    i.Init^;

    i.data:=NIL;
    i.pixmap:=0;
    i.shape:=0;
<* IF HAVE_LIB_XRENDER=TRUE THEN *>
    i.picture:=0;
<* END *>
  END Init;

  PROCEDURE (i : Image) CreateOSStructures;

  VAR
    s      : LONGINT;
    off    : LONGINT;

    value  : CHAR;

    w,x,
    pad    : LONGINT;
    bytes  : LONGINT;
    values : X11.XGCValues;

    gc     : X11.GC;
    data   : POINTER TO ARRAY OF CHAR;
    image  : X11.XImagePtr;
<* IF HAVE_LIB_XRENDER=TRUE THEN *>
    attr   : Xrender.XRenderPictureAttributes;
    pixmap : X11.Pixmap;
<* END *>

  BEGIN
    IF i.source=NIL THEN
      RETURN;
    END;

<* IF HAVE_LIB_XRENDER=TRUE THEN *>

    IF render THEN
      NEW(i.data,4*i.width*i.height);

      IF (X11.XImageByteOrder(display)=X11.LSBFirst) THEN
        off:=0;
        FOR s:=0 TO LEN(i.current^)-1 DO
          (* Premultiplied alpha values *)
          i.data[off]:=CHR((ORD(i.current[s].b)*ORD(i.current[s].a)) DIV 256);
          INC(off);
          i.data[off]:=CHR((ORD(i.current[s].g)*ORD(i.current[s].a)) DIV 256);
          INC(off);
          i.data[off]:=CHR((ORD(i.current[s].r)*ORD(i.current[s].a)) DIV 256);
          INC(off);
          i.data[off]:=i.current[s].a;
          INC(off);
        END;
      ELSE
        off:=0;
        FOR s:=0 TO LEN(i.current^)-1 DO
          (* Premultiplied alpha values *)
          i.data[off]:=i.current[s].a;
          INC(off);
          i.data[off]:=CHR((ORD(i.current[s].r)*ORD(i.current[s].a)) DIV 256);
          INC(off);
          i.data[off]:=CHR((ORD(i.current[s].g)*ORD(i.current[s].a)) DIV 256);
          INC(off);
          i.data[off]:=CHR((ORD(i.current[s].b)*ORD(i.current[s].a)) DIV 256);
          INC(off);
        END;
      END;

      image:=X11.XCreateImage(display,
                              visual,
                              32,
                              X11.ZPixmap,
                              0,
                              SYSTEM.VAL(C.address,i.data),
                              i.width,
                              i.height,
                              32,
                              i.width*4);

      pixmap:=X11.XCreatePixmap(display,
                                X11.XDefaultRootWindow(display),
                                i.width,
                                i.height,
                                32);

      gc:=X11.XCreateGC(display,pixmap,{},values);

      X11.XPutImage(display,
                    pixmap,
                    gc,
                    image,
                    0,
                    0,
                    0,
                    0,
                    i.width,
                    i.height);

      i.picture:=Xrender.XRenderCreatePicture(display,
                                              pixmap,
                                              alphaFormat,
                                              {},attr);

      IF i.picture=0 THEN
        Err.String("Cannot create picture");Err.Ln;
      END;

      image.data:=NIL;
      X11.XDestroyImage(image);
      X11.XFreeGC(display,gc);
      X11.XFreePixmap(display,pixmap);

      RETURN;
    END;
<* END *>

    IF (depth=24) OR (depth=32) THEN
      bytes:=4;
    ELSIF depth=16 THEN
      bytes:=2;
    ELSIF depth=8 THEN
      bytes:=1;
    ELSE
      RETURN;
    END;

    NEW(i.data,bytes*i.width*i.height);

    image:=X11.XCreateImage(display,
                            visual,
                            depth,
                            X11.ZPixmap,
                            0,
                            SYSTEM.VAL(C.address,i.data),
                            i.width,
                            i.height,
                            bytes*8,
                            0);

    IF image=NIL THEN
      Err.String("Cannot allocate image!"); Err.Ln;
      RETURN;
    END;
(*
    IF i.image.byte_order=X11.LSBFirst THEN
      Err.String("Byte order: LSBFirst");
    ELSE
      Err.String("Byte order: MSBFirst");
    END;
    Err.Ln;
    Err.String("Bitmap unit: "); Err.LongInt(i.image.bitmap_unit,0);Err.Ln;
    IF i.image.bitmap_bit_order=X11.LSBFirst THEN
      Err.String("Bitmap bit order: LSBFirst");
    ELSE
      Err.String("Bitmap bit order: MSBFirst");
    END;
    Err.Ln;
    Err.String("Bitmap pad: "); Err.LongInt(i.image.bitmap_pad,0);Err.Ln;
    Err.String("Bytes per line: "); Err.LongInt(i.image.bytes_per_line,0);Err.Ln;
    Err.String("Bits per pixel: "); Err.LongInt(i.image.bits_per_pixel,0);Err.Ln;

    Err.String("red mask: "); Err.Hex(SYSTEM.VAL(LONGINT,i.image.red_mask),8); Err.Ln;
    Err.String("green mask: "); Err.Hex(SYSTEM.VAL(LONGINT,i.image.green_mask),8); Err.Ln;
    Err.String("blue mask: "); Err.Hex(SYSTEM.VAL(LONGINT,i.image.blue_mask),8); Err.Ln;

    Err.String("---"); Err.Ln;
    Err.LongInt(depth,0);Err.Ln;
    Err.Hex(D.warnColor,0); Err.Ln;
    Err.Hex(D.fillColor,0); Err.Ln;
*)

<*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

    IF image.bits_per_pixel=32 THEN

      IF (image.bitmap_bit_order=X11.LSBFirst) &
          (image.byte_order=X11.LSBFirst) THEN

        off:=0;
        FOR s:=0 TO LEN(i.current^)-1 DO
          i.data[off]:=CHR((ORD(i.current[s].b)*ORD(i.current[s].a)) DIV 256);
          INC(off);
          i.data[off]:=CHR((ORD(i.current[s].g)*ORD(i.current[s].a)) DIV 256);
          INC(off);
          i.data[off]:=CHR((ORD(i.current[s].r)*ORD(i.current[s].a)) DIV 256);
          INC(off);
          i.data[off]:=i.current[s].a;
          INC(off);
        END;

      ELSIF (image.bitmap_bit_order=X11.MSBFirst) &
        (image.byte_order=X11.MSBFirst) THEN

        off:=0;
        FOR s:=0 TO LEN(i.current^)-1 DO
          i.data[off]:=i.current[s].a;
          INC(off);
          i.data[off]:=i.current[s].r;
          INC(off);
          i.data[off]:=i.current[s].g;
          INC(off);
          i.data[off]:=i.current[s].b;
          INC(off);
        END;

      ELSIF (image.bitmap_bit_order=X11.LSBFirst) &
        (image.byte_order=X11.MSBFirst) THEN

        off:=0;
        FOR s:=0 TO LEN(i.current^)-1 DO
          i.data[off]:=i.current[s].a;
          INC(off);
          i.data[off]:=i.current[s].r;
          INC(off);
          i.data[off]:=i.current[s].g;
          INC(off);
          i.data[off]:=i.current[s].b;
          INC(off);
        END;

      ELSE
        RETURN;
      END;
    ELSIF image.bits_per_pixel=16 THEN
      IF (image.bitmap_bit_order=X11.LSBFirst) &
        (image.byte_order=X11.LSBFirst) THEN
        off:=0;
        FOR s:=0 TO LEN(i.current^)-1 DO
          i.data[off]:=CHR(((ORD(i.current[s].g) DIV 4) MOD 8)*32+
                           (ORD(i.current[s].b) DIV 8));
          INC(off);
          i.data[off]:=CHR((ORD(i.current[s].r) DIV 8)*8+
                           (ORD(i.current[s].g) DIV 4) DIV 8);
          INC(off);
        END;
      ELSIF (image.bitmap_bit_order=X11.LSBFirst) &
        (image.byte_order=X11.MSBFirst) THEN
        RETURN;
      ELSE
        RETURN;
      END;

    ELSIF image.bits_per_pixel=8 THEN
      FOR s:=0 TO LEN(i.current^)-1 DO
        (* We assume  2/2/2, which likely will not work (normally 3/3/2 or similar) *)
        i.data[s]:=CHR((ORD(i.current[s].r) DIV 64)*16+
                       (ORD(i.current[s].g) DIV 64)*4+
                       (ORD(i.current[s].b) DIV 64));
      END;
    ELSE
      RETURN;
    END;

<* POP *>

    i.pixmap:=X11.XCreatePixmap(display,
                                X11.XDefaultRootWindow(display),
                                i.width,
                                i.height,
                                depth);

    gc:=X11.XCreateGC(display,i.pixmap,{},values);

    X11.XPutImage(display,
                  i.pixmap,
                  gc,
                  image,
                  0,
                  0,
                  0,
                  0,
                  i.width,
                  i.height);

    image.data:=NIL;
    X11.XDestroyImage(image);
    X11.XFreeGC(display,gc);

    IF i.alpha THEN
      (* Create alpha one-bit mask *)
      pad:=8;

      w:=((i.width+pad-1) DIV pad);
      NEW(data,(w*pad) DIV 8 *i.height);

<*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

      value:=0X;
      off:=0;
      x:=1;
      FOR s:=0 TO LEN(i.current^)-1 DO
        IF ORD(i.current[s].a)>0 THEN
          CASE x OF
           8:
            value:=CHR(ORD(value)+128);
          |7:
            value:=CHR(ORD(value)+64);
          |6:
            value:=CHR(ORD(value)+32);
          |5:
            value:=CHR(ORD(value)+16);
          |4:
            value:=CHR(ORD(value)+8);
          |3:
            value:=CHR(ORD(value)+4);
          |2:
            value:=CHR(ORD(value)+2);
          |1:
            value:=CHR(ORD(value)+1);
          END;
        END;
        INC(x);

        IF x=9 THEN
          data[off]:=value;
          INC(off);
          x:=1;
          value:=0X;
        ELSIF ((s MOD i.width)=(i.width-1)) THEN
          IF x#1 THEN
            data[off]:=value;
            x:=1;
            value:=0X;
            INC(off);
          END;
        END;
      END;
<* POP *>

      image:=X11.XCreateImage(display,
                              visual,
                              1,
                              X11.ZPixmap,
                              0,
                              SYSTEM.VAL(C.address,data),
                              i.width,
                              i.height,
                              pad,
                              w);

      IF image=NIL THEN
        Err.String("Cannot create shape"); Err.Ln;
      END;

      i.shape:=X11.XCreatePixmap(display,
                                 X11.XDefaultRootWindow(display),
                                 i.width,
                                 i.height,
                                 1);

      gc:=X11.XCreateGC(display,i.shape,{},values);

      X11.XPutImage(display,
                    i.shape,
                    gc,
                    image,
                    0,
                    0,
                    0,
                    0,
                    i.width,
                    i.height);

      image.data:=NIL;
      X11.XDestroyImage(image);
      X11.XFreeGC(display,gc);
   END;
  END CreateOSStructures;

  PROCEDURE (i : Image) FreeOSStructures*;

  BEGIN
    IF i.pixmap#0 THEN
      X11.XFreePixmap(display,i.pixmap);
      i.pixmap:=0;
    END;

    IF i.shape#0 THEN
      X11.XFreePixmap(display,i.shape);
      i.shape:=0;
    END;

  <* IF HAVE_LIB_XRENDER=TRUE THEN *>
    IF i.picture#0 THEN
      Xrender.XRenderFreePicture(display,i.picture);
      i.picture:=0;
    END;
    i.data:=NIL;

<* END *>
  END FreeOSStructures;

  PROCEDURE (i : Image) DrawSub*(info : D.DrawInfo;
                                 x,y,w,h,dx,dy : LONGINT);

<* IF HAVE_LIB_XRENDER=TRUE THEN *>
  VAR
    dstPic  : Xrender.Picture;
    attr    : Xrender.XRenderPictureAttributes;
    scratch : X11.Pixmap;
    values  : X11.XGCValues;
    gc      : X11.GC;

<* END *>

  BEGIN
    IF (w=0) OR (h=0) THEN
      RETURN;
    END;

    IF i.pixmap=0 THEN
      i.CreateOSStructures;
    END;

<* IF HAVE_LIB_XRENDER=TRUE THEN *>
    IF i.picture#0 THEN
      scratch:=X11.XCreatePixmap(display,
                                 X11.XDefaultRootWindow(display),
                                 w,h,
                                 depth);

      gc:=X11.XCreateGC(display,scratch,{},values);

      X11.XCopyArea(display,
                    info(OD.DrawInfo).window,
                    scratch,
                    gc,
                    dx,dy,w,h,
                    0,0);

      dstPic:=Xrender.XRenderCreatePicture(display,
                                           scratch,
                                           format,
                                           {},attr);
      Xrender.XRenderComposite(display,
                               Xrender.PictOpOver,
                               i.picture,
                               0,
                               dstPic,
                               x,y,
                               0,0,
                               0,0,
                               w,h);

      X11.XCopyArea(display,
                    scratch,
                    info(OD.DrawInfo).window,
                    info(OD.DrawInfo).gc,
                    0,0,w,h,
                    dx,dy);

      Xrender.XRenderFreePicture(display,dstPic);
      X11.XFreeGC(display,gc);
      X11.XFreePixmap(display,scratch);
      RETURN;
    END;
<* END *>

    IF i.pixmap#0 THEN
      X11.XCopyArea(display,
                    i.pixmap,
                    info(OD.DrawInfo).window,
                    info(OD.DrawInfo).gc,
                    x,y,w,h,
                    dx,dy);
    END;
  END DrawSub;

  PROCEDURE (i : Image) Draw*(info : D.DrawInfo;
                              x,y : LONGINT);

  BEGIN
    i.DrawSub(info,0,0,i.width,i.height,x,y);
  END Draw;

  PROCEDURE (i : Image) DrawSubCliped*(info : D.DrawInfo;
                                       x,y,w,h,dx,dy : LONGINT);

<* IF HAVE_LIB_XRENDER=TRUE THEN *>
  VAR
    dstPic : Xrender.Picture;
    attr   : Xrender.XRenderPictureAttributes;
    scratch : X11.Pixmap;
    values  : X11.XGCValues;
    gc      : X11.GC;
<* END *>

  BEGIN
    IF (w=0) OR (h=0) THEN
      RETURN;
    END;

    IF i.pixmap=0 THEN
      i.CreateOSStructures;
    END;

<* IF HAVE_LIB_XRENDER=TRUE THEN *>
    IF i.picture#0 THEN

      scratch:=X11.XCreatePixmap(display,
                                 X11.XDefaultRootWindow(display),
                                 w,h,
                                 depth);

      gc:=X11.XCreateGC(display,scratch,{},values);

      X11.XCopyArea(display,
                    info(OD.DrawInfo).window,
                    scratch,
                    gc,
                    dx,dy,w,h,
                    0,0);

      dstPic:=Xrender.XRenderCreatePicture(display,
                                           scratch,
                                           format,
                                           {},attr);
      Xrender.XRenderComposite(display,
                               Xrender.PictOpOver,
                               i.picture,
                               0,
                               dstPic,
                               x,y,
                               0,0,
                               0,0,
                               w,h);

      X11.XCopyArea(display,
                    scratch,
                    info(OD.DrawInfo).window,
                    info(OD.DrawInfo).gc,
                    0,0,w,h,
                    dx,dy);

      Xrender.XRenderFreePicture(display,dstPic);
      X11.XFreeGC(display,gc);
      X11.XFreePixmap(display,scratch);

      RETURN;
    END;
<* END *>

    IF i.pixmap#0 THEN
      IF i.shape#0 THEN
        X11.XSetClipMask(display,info(OD.DrawInfo).gc,i.shape);
        X11.XSetClipOrigin(display,info(OD.DrawInfo).gc,dx-x,dy-y);
      END;

      X11.XCopyArea(display,
                    i.pixmap,
                    info(OD.DrawInfo).window,
                    info(OD.DrawInfo).gc,
                    x,y,w,h,
                    dx,dy);

      IF i.shape#0 THEN
        info(OD.DrawInfo).ReinstallClip;
      END;
    END;
  END DrawSubCliped;

  PROCEDURE (i : Image) DrawTiled*(info : D.DrawInfo;
                                   x,y,w,h,dx,dy : LONGINT);

  BEGIN
    IF (w=0) OR (h=0) THEN
      RETURN;
    END;

    IF i.pixmap=0 THEN
      i.CreateOSStructures;
    END;

    IF i.pixmap#0 THEN
      X11.XSetTile(display,info(OD.DrawInfo).gc,i.pixmap);
      X11.XSetTSOrigin(display,info(OD.DrawInfo).gc,dx,dy);
      X11.XSetFillStyle(display,info(OD.DrawInfo).gc,X11.FillTiled);
      X11.XFillRectangle(display,info(OD.DrawInfo).window,info(OD.DrawInfo).gc,x,y,w,h);
      (* TODO: Restore correct fill mode *)
      X11.XSetFillStyle(display,info(OD.DrawInfo).gc,X11.FillSolid);
    END;
  END DrawTiled;

  PROCEDURE (i : Image) Free*;

  BEGIN
    i.FreeOSStructures;
  END Free;

  PROCEDURE (f : Factory) Init*(d : D.Display):BOOLEAN;

  VAR
    info    : Xutil.XVisualInfo;
<* IF HAVE_LIB_XRENDER=TRUE THEN *>
    tmp1,
    tmp2    : C.int;
    pFormat : Xrender.XRenderPictFormat;
<* END *>
(*    PROCEDURE PrintInfo;

    BEGIN
      Err.Hex(info.visualid,0); Err.Char(" ");
      Err.Hex(SYSTEM.VAL(LONGINT,info.red_mask),0); Err.Char(" ");
      Err.Hex(SYSTEM.VAL(LONGINT,info.green_mask),0); Err.Char(" ");
      Err.Hex(SYSTEM.VAL(LONGINT,info.blue_mask),0); Err.Char(" ");
      Err.LongInt(info.colormap_size,0); Err.Char(" ");
      Err.LongInt(info.bits_per_rgb,0); Err.Ln;
    END PrintInfo;*)

  BEGIN
    IF ~(d IS OD.Display) THEN
      RETURN FALSE;
    END;

    display:=d(OD.Display).display;
    scrNum:=d(OD.Display).scrNum;
    visual:=d(OD.Display).visual;
    depth:=d(OD.Display).colorDepth;
    colorMap:=d(OD.Display).colorMap;

    IF Xutil.XMatchVisualInfo(display,scrNum,24,X11.TrueColor,info)#0 THEN

(*      Err.String("Found 24 bit visual"); Err.Ln;
      PrintInfo;*)

      visual:=info.visual;
      depth:=24;
      colorMap:=X11.XCreateColormap(display,
                                    X11.XDefaultRootWindow(display),
                                    visual,
                                    X11.AllocNone);

      d(OD.Display).visual:=visual;
      d(OD.Display).colorDepth:=depth;
      d(OD.Display).colorMap:=colorMap;

    ELSIF Xutil.XMatchVisualInfo(display,scrNum,16,X11.TrueColor,info)#0 THEN
(*      Err.String("Found 16 bit visual"); Err.Ln;
      PrintInfo;*)

      visual:=info.visual;
      depth:=16;
      colorMap:=X11.XCreateColormap(display,
                                    X11.XDefaultRootWindow(display),
                                    visual,
                                    X11.AllocNone);

      d(OD.Display).visual:=visual;
      d(OD.Display).colorDepth:=depth;
      d(OD.Display).colorMap:=colorMap;
    END;

<* IF HAVE_LIB_XRENDER=TRUE THEN *>
    render:=Xrender.XRenderQueryExtension(display,tmp1,tmp2)=X11.True;

    IF render THEN
      format:=Xrender.XRenderFindVisualFormat(display,visual);

      pFormat.id:=0;
      pFormat.type:=Xrender.PictTypeDirect;
      pFormat.depth:=32;
      pFormat.direct.red:=16;
      pFormat.direct.redMask:=0FFH;
      pFormat.direct.green:=8;
      pFormat.direct.greenMask:=0FFH;
      pFormat.direct.blue:=0;
      pFormat.direct.blueMask:=0FFH;
      pFormat.direct.alpha:=24;
      pFormat.direct.alphaMask:=0FFH;
      pFormat.colormap:=0;

      alphaFormat:=Xrender.XRenderFindFormat(display,
                                             {Xrender.PictFormatType,
                                              Xrender.PictFormatDepth,
                                              Xrender.PictFormatRed,
                                              Xrender.PictFormatRedMask,
                                              Xrender.PictFormatGreen,
                                              Xrender.PictFormatGreenMask,
                                              Xrender.PictFormatBlue,
                                              Xrender.PictFormatBlueMask,
                                              Xrender.PictFormatAlpha,
                                              Xrender.PictFormatAlphaMask},
                                             pFormat,0);

                                             END;
<* END *>

   RETURN TRUE;
  END Init;

  PROCEDURE (f : Factory) Deinit*(display : D.Display);

  BEGIN
    (* TODO *)
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
  display:=NIL;
  scrNum:=0;
  visual:=NIL;
  depth:=0;
  colorMap:=0;

  NEW(factory);
  I.Register(factory);
END VO:OS:X11:Image.
