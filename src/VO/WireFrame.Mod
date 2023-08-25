(**
   A simple test for the bitmap feature of VisualOberon. We implement
   a simple wire frame engine. When visible the objects will be rotated
   automatically around 0-0-0. We use a simple double buffering algorithm
   for displaying.

   TODO
   Implement a similar engine with filled polygons and some lightsourcing
   stuff. We must investigate 3D  clipping algorithms for this. We could
   also implement a simple doom-like engine ;-) (Year, look at VODoom.Mod)

   BUGS
   If the 2 dimentional plane the image will be projected to is within the
   created object a line behind the plane will be projected in front of the
   plane.
**)

MODULE VO:WireFrame;

(*
    A simple test for the bitmap feature of VisualOberon.
    Copyright (C) 1998  Tim Teulings (rael@edge.ping.de)

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

IMPORT BG  := VO:Base:Background,
       D   := VO:Base:Display,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,

       G   := VO:Object,

       M   := RealMath;

CONST
  blinkPeriod = 100;

TYPE
  Prefs*         = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc*     = RECORD (G.PrefsDesc)
                   END;

  PointDesc      = RECORD
                     x,y,z : REAL;
                   END;

  Line           = POINTER TO LineDesc;
  LineDesc       = RECORD
                     next : Line;
                     a,b  : PointDesc;
                   END;

  WireFrame*     = POINTER TO WireFrameDesc;
  WireFrameDesc* = RECORD (G.ImageDesc)
                     timer     : D.Timer;

                     bitmap    : D.Bitmap;

                     lineList,
                     lastLine  : Line;
                     p         : PointDesc; (* viewpoint *)
                     bz        : REAL;      (* z-position of map plane in x,y direction *)
                   END;

VAR
  prefs : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;
    
    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.blackColorIndex));
    p.frame:=F.CreateFrame(F.none);
  END Initialize;

  (**
    Rote the point with the given angles around the x- ,y- and
    z-axis.
  **)

  PROCEDURE (VAR p : PointDesc) Rotate(a,b,c : REAL);

  VAR
    x,y,z : REAL;

  BEGIN
    IF a#0 THEN
      (* rotating around x-axis, angle a *)
      y:=p.z*M.sin(a)+p.y*M.cos(a);
      z:=p.z*M.cos(a)-p.y*M.sin(a);

      p.y:=y;
      p.z:=z;
    END;

    IF b#0 THEN
      (* rotating around y-axis, angle b *)
      x:=p.x*M.cos(b)-p.z*M.sin(b);
      z:=p.x*M.sin(b)+p.z*M.cos(b);

      p.x:=x;
      p.z:=z;
    END;

    IF c#0 THEN
      (* rotating around z-axis, angle c *)
      x:=p.x*M.cos(c)-p.y*M.sin(c);
      y:=p.x*M.sin(c)+p.y*M.cos(c);

      p.x:=x;
      p.y:=y;
    END;
  END Rotate;

  (**
    Project the point to the display plane. You must make a copy
    of the point before or you will destroy the original coodinates.
  **)

  PROCEDURE (VAR p : PointDesc) Project(w : WireFrame);

  VAR
    tmp : REAL;

  BEGIN
    (* project onto x,y plane *)
    p.x:=(p.x*(-w.bz-w.p.x))/(p.z-w.p.z);
    p.y:=(p.y*(-w.bz-w.p.y))/(p.z-w.p.z);
    p.z:=0;

    (* switch x,y *)
    tmp:=p.x;
    p.x:=p.y;
    p.y:=tmp;


    (* we transform coordinates *)
    p.x:=p.x+w.width DIV 2;
    p.y:=w.height DIV 2 - p.y;
  END Project;

  PROCEDURE (w : WireFrame) Init*;

  BEGIN
    w.Init^;

    w.SetPrefs(prefs);

    w.timer:=D.factory.CreateTimer();
    w.timer.SetSecs(0,blinkPeriod);
    w.timer.SetObject(w);

    w.bitmap:=NIL;

    w.lineList:=NIL;
    w.lastLine:=NIL;

    w.p.x:=   0;
    w.p.y:=   0;
    w.p.z:=-2000;
    w.bz :=-500;
  END Init;

  (**
    Add a line to be displayed to the engine.
  **)

  PROCEDURE (w : WireFrame) AddLine*(x1,y1,z1,x2,y2,z2 : REAL);

  VAR
    line : Line;

  BEGIN
    NEW(line);
    line.next:=NIL;
    line.a.x:=x1;
    line.a.y:=y1;
    line.a.z:=z1;
    line.b.x:=x2;
    line.b.y:=y2;
    line.b.z:=z2;

    IF w.lineList=NIL THEN
      w.lineList:=line;
    ELSE
      w.lastLine.next:=line;
    END;
    w.lastLine:=line;
  END AddLine;


  (**
    Set the position of the viwer and the distance in z-direction of the
    projection plane from the 0 point.
  **)

  PROCEDURE (w : WireFrame) SetViewer*(x,y,z,bz : REAL);

  BEGIN
    w.p.x:=x;
    w.p.y:=y;
    w.p.z:=z;
    w.bz:=bz;

    IF w.visible THEN
      w.Redraw;
    END;
  END SetViewer;

  PROCEDURE (w : WireFrame) CalcSize*;

  BEGIN
    w.width:=15;
    w.height:=15;

    w.minWidth:=w.width;
    w.minHeight:=w.height;

    w.CalcSize^;
  END CalcSize;

  PROCEDURE (w : WireFrame) DrawBox(rotate : BOOLEAN);

  VAR
    line   : Line;
    a1,a2  : PointDesc;
    wDraw,
    draw   : D.DrawInfo;
    x,y    : LONGINT;

  BEGIN
    IF (w.bitmap=NIL) OR (w.bitmap.width#w.width) OR (w.bitmap.height#w.height) THEN
      IF w.bitmap#NIL THEN
        D.display.FreeBitmap(w.bitmap);
      END;
      w.bitmap:=D.display.CreateBitmap(w.width,w.height);
    END;

    wDraw:=w.GetDrawInfo();

    IF w.bitmap=NIL THEN
      draw:=wDraw;
      x:=w.x;
      y:=w.y;
    ELSE
      draw:=w.bitmap.draw;
      x:=0;
      y:=0;
    END;

    IF w.backgroundObject#NIL THEN
      w.backgroundObject.DrawRelObject(draw,w,x,y,w.width,w.height);
    ELSE
      draw.PushForeground(D.backgroundColor);
      draw.FillRectangle(x,y,w.width,w.height);
      draw.PopForeground;
    END;

    draw.PushForeground(D.whiteColor);
    line:=w.lineList;
    WHILE line#NIL DO
      IF rotate THEN
        line.a.Rotate(M.pi/45,M.pi/45,M.pi/45);
        line.b.Rotate(M.pi/45,M.pi/45,M.pi/45);
      END;
      a1:=line.a;
      a2:=line.b;
      a1.Project(w);
      a2.Project(w);
      draw.DrawLine(x+M.round(a1.x),y+M.round(a1.y),x+M.round(a2.x),y+M.round(a2.y));
      line:=line.next;
    END;
    draw.PopForeground;

    IF w.bitmap#NIL THEN
      wDraw.CopyFromBitmap(w.bitmap,0,0,w.width,w.height,w.x,w.y);
    END;
  END DrawBox;

  PROCEDURE (w : WireFrame) Draw*(x,y,width,height : LONGINT);

  BEGIN
    IF ~w.Intersect(x,y,width,height) THEN
      RETURN;
    END;

    w.Draw^(x,y,width,height);

    w.DrawBox(FALSE);

    IF ~w.timer.active THEN
      D.display.AddTimer(w.timer);
    END;
  END Draw;

  PROCEDURE (w : WireFrame) Hide*;

  BEGIN
    IF w.timer.active THEN
      D.display.RemoveTimer(w.timer);
    END;

    IF w.visible THEN
      w.Hide^;
    END;
  END Hide;

  PROCEDURE (w : WireFrame) Receive*(msg : O.Message);

  BEGIN
    WITH msg:
      D.TimerMsg DO
        IF w.visible THEN
          w.DrawBox(TRUE);
          D.display.AddTimer(w.timer);
        END;
    ELSE
    END;
  END Receive;

  PROCEDURE (w : WireFrame) Free*;

  BEGIN
    IF w.bitmap#NIL THEN
      D.display.FreeBitmap(w.bitmap);
    END;
  END Free;

  PROCEDURE CreateWireFrame*():WireFrame;

  VAR
    wireFrame : WireFrame;

  BEGIN
    NEW(wireFrame);
    wireFrame.Init;

    RETURN wireFrame;
  END CreateWireFrame;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:WireFrame.