MODULE VO:Image:Image;

  (**
    The core classes for the bitmap based image subsystem of VisualOberon.
  *)

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

IMPORT        SYSTEM,

       D   := VO:Base:Display;

TYPE
  PixelDesc*     = RECORD
                     (**
                       Holds color value information for one pixel within the
                       image.
                     *)
                     r*,        (** red value *)
                     g*,        (** green value *)
                     b*,        (** blue value *)
                     a* : CHAR; (** alpha value *)
                   END;
  Data*          = POINTER TO ARRAY OF PixelDesc;

  Image*         = POINTER TO ImageDesc;
  ImageDesc*     = RECORD [ABSTRACT]
                     (**
                       Lowlevel representation of an image. Hold plattform
                       independend data together with some OS dependend
                       handles.
                     *)
                     oWidth-,              (** The original width of the image *)
                     oHeight-   : LONGINT; (** The original height of the image *)
                     alpha-     : BOOLEAN; (** TRUE, if there is alpha channel information in the image *)
                     width*,               (** The current width, may be different from oWidth because of resizing *)
                     height*    : LONGINT; (** The current width, may be different from oWidth because of resizing *)
                     source*,              (** The original image data *)
                     current*   : Data;    (** The current data, after effects and resizing *)
                   END;

  Factory*       = POINTER TO FactoryDesc;
  FactoryDesc*   = RECORD [ABSTRACT]
                   END;

(*  ScalerDesc     = RECORD
                     coord : LONGINT;
                   END;*)

TYPE
  List = ARRAY 100 OF Factory;

VAR
  list    : List;
  count   : LONGINT;

VAR
  factory*    : Factory;

  PROCEDURE (i : Image) Init*;

  BEGIN
    i.width:=0;
    i.height:=0;
    i.alpha:=FALSE;

    i.source:=NIL;
    i.current:=NIL;
  END Init;

  PROCEDURE (i : Image) [ABSTRACT] FreeOSStructures*;
  END FreeOSStructures;

  PROCEDURE (i : Image) SetData*(width,height : LONGINT;
                                 alpha : BOOLEAN;
                                 data : Data);

  BEGIN
    ASSERT(data#NIL);
    ASSERT(LEN(data^)=width*height);

    i.FreeOSStructures;

    i.oWidth:=width;
    i.oHeight:=height;
    i.width:=width;
    i.height:=height;

    i.alpha:=alpha;

    i.source:=data;
    i.current:=data;
  END SetData;

  PROCEDURE (i : Image) Resize*(width,height : LONGINT);

  CONST
    scale = 100;

  VAR
(*    xs,
    ys     : POINTER TO ARRAY OF LONGINT;*)
    x,y,
    j      : LONGINT;

    xs,
    ys,
    fx,
    fy,
    xm,
    ym,
    xmi,
    ymi,
    cx,cy,
    p1,p2,
    p3,p4  : LONGINT;
    new    : Data;

  BEGIN
    IF i.source=NIL THEN
      RETURN;
    END;

    IF (width=0) OR (height=0) THEN
      RETURN;
    END;

    IF (i.width=width) & (i.height=height) THEN
      RETURN;
    END;

    NEW(new,width*height);

<*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

(*
      (* Simple scaling *)

    NEW(xs,width);

    xs[0]:=0;
    xs[width-1]:=i.oWidth-1;

    FOR j:=1 TO width-2 DO
      xs[j]:=((i.oWidth-1)*j) DIV (width-1);
    END;

    NEW(ys,height);

    ys[0]:=0;
    ys[height-1]:=i.oHeight-1;

    FOR j:=1 TO height-2 DO
      ys[j]:=((i.oHeight-1)*j) DIV (height-1);
    END;

    j:=0;
    FOR y:=0 TO height-1 DO
      FOR x:=0 TO width-1 DO
        new[j]:=i.source[ys[y]*i.oWidth+xs[x]];
        INC(j);
      END;
    END;
    *)

    (* bilinear scaling *)

    xs:=(i.oWidth*scale) DIV width;
    ys:=(i.oHeight*scale) DIV height;

    j:=0;
    FOR y:=0 TO height-1 DO
      FOR x:=0 TO width-1 DO
        fx:=(x*xs) DIV scale;
        fy:=(y*ys) DIV scale;
        cx:=fx+1;
        IF cx>=i.oWidth THEN
          cx:=fx;
        END;
        cy:=fy+1;
        IF cy>=i.oHeight THEN
          cy:=fy;
        END;

        xm:=(x*xs-fx*scale);
        xmi:=scale-xm;
        ym:=(y*ys-fy*scale);
        ymi:=scale-ym;

        p1:=fy*i.oWidth+fx;
        p2:=fy*i.oWidth+cx;
        p3:=cy*i.oWidth+fx;
        p4:=cy*i.oWidth+cx;

        new[j].r:=CHR((ymi*(xmi*ORD(i.source[p1].r)+xm*ORD(i.source[p2].r))+
                       ym*(xmi*ORD(i.source[p3].r)+xm*ORD(i.source[p4].r))) DIV (scale*scale));

        new[j].g:=CHR((ymi*(xmi*ORD(i.source[p1].g)+xm*ORD(i.source[p2].g))+
                       ym*(xmi*ORD(i.source[p3].g)+xm*ORD(i.source[p4].g))) DIV (scale*scale));

        new[j].b:=CHR((ymi*(xmi*ORD(i.source[p1].b)+xm*ORD(i.source[p2].b))+
                       ym*(xmi*ORD(i.source[p3].b)+xm*ORD(i.source[p4].b))) DIV (scale*scale));

        new[j].a:=CHR((ymi*(xmi*ORD(i.source[p1].a)+xm*ORD(i.source[p2].a))+
                       ym*(xmi*ORD(i.source[p3].a)+xm*ORD(i.source[p4].a))) DIV (scale*scale));

        INC(j);
      END;
    END;

<* POP *>

    i.width:=width;
    i.height:=height;
    i.current:=new;

    i.FreeOSStructures;
  END Resize;

  PROCEDURE (i : Image) InitializeEmpty*;

  VAR
    p : LONGINT;

  BEGIN
    i.FreeOSStructures;

    i.oWidth:=10;
    i.oHeight:=10;
    i.width:=10;
    i.height:=10;
    i.alpha:=FALSE;

    NEW(i.source,i.width*i.height);

<*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

    p:=0;
    WHILE p<LEN(i.source^) DO

      i.source[p].r:=CHR(255);
      i.source[p].g:=i.source[p].r;
      i.source[p].b:=i.source[p].r;

      INC(p);
    END;
    <* POP *>

    i.current:=i.source;
  END InitializeEmpty;

  PROCEDURE (i : Image) Shade*(width, height : LONGINT);

  VAR
    p,x : LONGINT;

  BEGIN
    i.FreeOSStructures;

    i.oWidth:=width;
    i.oHeight:=height;
    i.width:=width;
    i.height:=height;
    i.alpha:=FALSE;

    NEW(i.source,i.width*i.height);

<*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

    p:=0;
    x:=0;
    WHILE p<LEN(i.source^) DO

      i.source[p].r:=CHR((x*256) DIV i.width);
      i.source[p].g:=i.source[p].r;
      i.source[p].b:=i.source[p].r;

      INC(x);
      x:=x MOD i.width;

      INC(p);
    END;
    <* POP *>

    i.current:=i.source;
  END Shade;

  PROCEDURE (i : Image) [ABSTRACT] Draw*(info : D.DrawInfo;
                                         x,y : LONGINT);
  END Draw;

  PROCEDURE (i : Image) [ABSTRACT] DrawSub*(info : D.DrawInfo;
                                            x,y,w,h,dx,dy : LONGINT);
    (**
      Draw the sub rectangle x,y,w,h of the picture at position dx,dy.

      (This is the same as drawing the picture at dx-x,dy-y
      and clip this to the sub rectangle x,y,w,h (relative to the
      picture origin)).
    *)
  END DrawSub;

  PROCEDURE (i : Image) [ABSTRACT] DrawSubCliped*(info : D.DrawInfo;
                                                  x,y,w,h,dx,dy : LONGINT);
    (**
      Draw the sub rectangle x,y,w,h of the picture at position dx,dy.

      (This is the same as drawing the picture at dx-x,dy-y
      and clip this to the sub rectangle x,y,w,h (relative to the
      picture origin)). You must also respect the current clipping
      rectangle!
    *)

  END DrawSubCliped;

  PROCEDURE (i : Image) [ABSTRACT] DrawTiled*(info : D.DrawInfo;
                                              x,y,w,h,dx,dy : LONGINT);
  END DrawTiled;

  PROCEDURE (i : Image) [ABSTRACT] Free*;
  END Free;

  PROCEDURE (f : Factory) [ABSTRACT] CreateImage*():Image;
  END CreateImage;

  PROCEDURE (f : Factory) [ABSTRACT] Init*(display : D.Display):BOOLEAN;
  END Init;

  PROCEDURE (f : Factory) [ABSTRACT]Deinit*(display : D.Display);
  END Deinit;

  PROCEDURE (i : Image) Clone*():Image;

    (**
      Create a deep copy of the image. "Deep" means, that the original
      image and its copy do not share any resources. Changing the copy
      does not change the original.
    *)

  VAR
    image : Image;
    data  : Data;

  BEGIN
    image:=factory.CreateImage();
    NEW(data,i.oWidth*i.oHeight);
    SYSTEM.MOVE(SYSTEM.VAL(SYSTEM.ADDRESS,i.source),
                SYSTEM.VAL(SYSTEM.ADDRESS,data),LEN(data^));
    image.SetData(i.oWidth,i.oHeight,i.alpha,data);

    RETURN image;
  END Clone;

  PROCEDURE (i : Image) CloneRegion*(x,y,width,height : LONGINT):Image;

  VAR
    image : Image;
    data  : Data;
    a,b,j : LONGINT;
    alpha : BOOLEAN;

  BEGIN
    ASSERT((x>=0) & (y>=0) & (x+width<=i.oWidth) & (y+height<=i.oHeight));

    image:=factory.CreateImage();
    NEW(data,width*height);

<*PUSH; IndexCheck:=FALSE; DerefCheck:=FALSE; OverflowCheck:=FALSE *>

    j:=0;
    alpha:=FALSE;
    FOR b:=y TO y+height-1 DO
      FOR a:=x TO x+width-1 DO
        data[j]:=i.source[b*i.oWidth+a];
        IF ORD(data[j].a)#255 THEN
          alpha:=TRUE;
        END;
        INC(j);
      END;
    END;

<* POP *>

    image.SetData(width,height,alpha,data);

    RETURN image;
  END CloneRegion;

  PROCEDURE Register*(factory : Factory);

    (**
      Registers a driver. Normally there is no need
      to register a driver manually.
    *)

  BEGIN
    list[count]:=factory;
    INC(count);
  END Register;

  PROCEDURE Probe*(display : D.Display);

  VAR
    current : LONGINT;

  BEGIN
    FOR current:=0 TO count-1 DO
      IF list[current].Init(display) THEN
        factory:=list[current];
        RETURN;
      END;
    END;
  END Probe;

BEGIN
  count:=0;
  factory:=NIL;
END VO:Image:Image.
