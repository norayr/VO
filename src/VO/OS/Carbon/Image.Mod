MODULE VO:OS:Carbon:Image;

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

       OD := VO:OS:Carbon:Display,

             Carbon,

             Err;

TYPE
  Image*     = POINTER TO ImageDesc;
  ImageDesc* = RECORD (I.ImageDesc)
                 data,
                 mask  : POINTER TO ARRAY OF CHAR; (** The OS-dependend data *)
                 image,
                 alphaImage : Carbon.GWorldPtr;
               END;

  Factory*       = POINTER TO FactoryDesc;
  FactoryDesc*   = RECORD (I.FactoryDesc)
                   END;

VAR
  factory     : Factory;

  PROCEDURE (i : Image) Init*;

  BEGIN
    i.Init^;

    i.data:=NIL;
    i.image:=NIL;
    i.alphaImage:=NIL;
  END Init;

  PROCEDURE (i : Image) CreateOSStructures;

  VAR
    off,s : LONGINT;
    rect  : Carbon.Rect;

  BEGIN
    IF i.source=NIL THEN
      RETURN;
    END;

    NEW(i.data,4*i.width*i.height);

    <*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

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

    <* POP; *>

    rect.left:=0;
    rect.right:=SHORT(i.width);
    rect.top:=0;
    rect.bottom:=SHORT(i.height);
    IF Carbon.NewGWorldFromPtr(i.image,
                               Carbon.k32RGBAPixelFormat,
                               SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)),
                               NIL,
                               NIL,
                               0,
                               SYSTEM.VAL(Carbon.Ptr,i.data),
                               4*i.width)#Carbon.noErr THEN
      Err.String("Cannot create image!"); Err.Ln;
    END;

    IF i.alpha THEN
      NEW(i.mask,4*i.width*i.height);

      <*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

      off:=0;
      FOR s:=0 TO LEN(i.current^)-1 DO
        i.mask[off]:=CHR(255-ORD(i.current[s].a));
        INC(off);
        i.mask[off]:=CHR(255-ORD(i.current[s].a));
        INC(off);
        i.mask[off]:=CHR(255-ORD(i.current[s].a));
        INC(off);
        i.mask[off]:=CHR(255-ORD(i.current[s].a));
        INC(off);
      END;

      <* POP; *>

      IF Carbon.NewGWorldFromPtr(i.alphaImage,
                                 Carbon.k32RGBAPixelFormat,
                                 SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(rect)),
                                 NIL,
                                 NIL,
                                 0,
                                 SYSTEM.VAL(Carbon.Ptr,i.mask),
                                 4*i.width)#Carbon.noErr THEN
        Err.String("Cannot create alpha mask!"); Err.Ln;
      END;
    ELSE
      i.alphaImage:=NIL;
    END;
  END CreateOSStructures;

  PROCEDURE (i : Image) FreeOSStructures*;

  BEGIN
    IF i.image#NIL THEN
      Carbon.DisposeGWorld(i.image);
      i.image:=NIL;
    END;

    IF i.alphaImage#NIL THEN
      Carbon.DisposeGWorld(i.alphaImage);
      i.image:=NIL;
    END;

    i.data:=NIL;
  END FreeOSStructures;

  PROCEDURE (i : Image) Copy(d : D.DrawInfo;
                             sX,sY,width,height,dX,dY : LONGINT);

  VAR
    sScr,
    aScr,
    dScr   : Carbon.BitMapPtr;
    source,
    dest   : Carbon.Rect;
    point  : Carbon.Point;
    hdl    : Carbon.PixMapHandle;

  BEGIN
    sScr:=Carbon.GetPortBitMapForCopyBits(i.image);

    point.h:=SHORT(sX);
    point.v:=SHORT(sY);

    source.top:=point.v;
    source.left:=point.h;
    source.bottom:=source.top+SHORT(height);
    source.right:=source.left+SHORT(width);

    dScr:=Carbon.GetPortBitMapForCopyBits(d(OD.DrawInfo).port);

    point.h:=SHORT(dX);
    point.v:=SHORT(dY);

    dest.top:=point.v;
    dest.left:=point.h;
    dest.bottom:=dest.top+SHORT(height);
    dest.right:=dest.left+SHORT(width);

    d.PushForeground(D.blackColor);
    d.PushBackground(D.whiteColor);
    hdl:=Carbon.GetGWorldPixMap(i.image);

    IF Carbon.LockPixels(hdl[0])#0X THEN
      IF i.alphaImage#NIL THEN
        aScr:=Carbon.GetPortBitMapForCopyBits(i.alphaImage);

        Carbon.CopyDeepMask(sScr,aScr,dScr,
                            SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(source)),
                            SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(source)),
                            SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(dest)),
                            Carbon.srcCopy,NIL);
      ELSE
        Carbon.CopyBits(sScr,dScr,
                        SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(source)),
                        SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(dest)),
                        Carbon.srcCopy,NIL);
      END;
      Carbon.UnlockPixels(hdl[0]);
    END;
    d.PopBackground;
    d.PopForeground;
  END Copy;

  PROCEDURE (i : Image) Draw*(info : D.DrawInfo;
                              x,y : LONGINT);

  BEGIN
    IF i.image=NIL THEN
      i.CreateOSStructures;
    END;

    IF i.image=NIL THEN
      RETURN;
    END;

    i.Copy(info,0,0,i.width,i.height,x,y);
  END Draw;

  PROCEDURE (i : Image) DrawSub*(info : D.DrawInfo;
                                 x,y,w,h,dx,dy : LONGINT);

  BEGIN
    IF i.image=NIL THEN
      i.CreateOSStructures;
    END;

    IF i.image=NIL THEN
      RETURN;
    END;

    i.Copy(info,x,y,w,h,dx,dy);
  END DrawSub;

  PROCEDURE (i : Image) DrawSubCliped*(info : D.DrawInfo;
                                       x,y,w,h,dx,dy : LONGINT);

  BEGIN
    IF i.image=NIL THEN
      i.CreateOSStructures;
    END;

    IF i.image=NIL THEN
      RETURN;
    END;

    i.Copy(info,x,y,w,h,dx,dy);
  END DrawSubCliped;

  PROCEDURE (i : Image) DrawTiled*(info : D.DrawInfo;
                                   x,y,w,h,dx,dy : LONGINT);

  VAR
    pix  : Carbon.PixPatHandle;
    hdl1,
    hdl2 : Carbon.PixMapHandle;
    dest : Carbon.Rect;

  BEGIN
    IF i.image=NIL THEN
      i.CreateOSStructures;
    END;

    IF i.image=NIL THEN
      RETURN;
    END;

    pix:=Carbon.NewPixPat();
    hdl1:=Carbon.GetGWorldPixMap(i.image);
    hdl2:=pix[0].patMap;
    Carbon.CopyPixMap(hdl1[0],hdl2[0]);
    pix[0].patData:=Carbon.NewHandleClear(4*i.width*i.height);

    Carbon.BlockMove(SYSTEM.VAL(Carbon.LogicalAddress,Carbon.GetPixBaseAddr(hdl1[0])),
                     SYSTEM.VAL(Carbon.LogicalAddress,pix[0].patData[0]),
                     4*i.width*i.height);
    Carbon.PixPatChanged(pix[0]);

    dest.top:=SHORT(y);
    dest.left:=SHORT(x);
    dest.bottom:=dest.top+SHORT(h);
    dest.right:=dest.left+SHORT(w);
    Carbon.SetGWorld(info(OD.DrawInfo).port,NIL);
    Carbon.FillCRect(SYSTEM.VAL(Carbon.RectPtr,SYSTEM.ADR(dest)),
                     pix[0]);

    Carbon.DisposePixPat(pix[0]);
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
  NEW(factory);
  I.Register(factory);
END VO:OS:Carbon:Image.