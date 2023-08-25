MODULE VO:Doom;

  (**
    Only for testing. Do not use!
  *)

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

IMPORT D   := VO:Base:Display,
       O   := VO:Base:Object,

       G   := VO:Object,

       Err,
       M   := RealMath;

CONST
  refreshRate = 50;
  width*      = 6;
  height*     = 8;

  free * = 0;
  wall * = 1;

TYPE

  CellDesc  = RECORD
                type : LONGINT;
              END;
  Column    = POINTER TO ARRAY OF CellDesc;
  Map       = POINTER TO ARRAY OF Column;

  Doom*     = POINTER TO DoomDesc;
  DoomDesc* = RECORD (G.GadgetDesc)
                timeOut   : D.TimeOut;
                sleep     : D.Sleep;
                bitmap    : D.Bitmap;

                map       : Map;

                vx,vy,va  : REAL;
              END;

VAR
  grad  : REAL; (* one  in grad *)
  twoPi : REAL; (* two pi *)
  pi14,
  pi34,
  pi54,
  pi74  : REAL;

  PROCEDURE (d : Doom) Init*;

  VAR
    x,y    : LONGINT;

  BEGIN
    d.Init^;

    d.timeOut:=NIL;
    d.sleep:=NIL;
    d.bitmap:=NIL;

    NEW(d.map,width);

    FOR x:=0 TO width-1 DO
      NEW(d.map[x],height);
    END;

    FOR x:=0 TO width-1 DO
      FOR y:=0 TO height-1 DO
        d.map[x][y].type:=free;
      END;
    END;


    (* The area: [] *)
    d.map[0][0].type:=wall;
    d.map[1][0].type:=wall;
    d.map[2][0].type:=wall;
(*    d.map[3][0].type:=wall;*)
    d.map[4][0].type:=wall;
    d.map[5][0].type:=wall;

    d.map[0][1].type:=wall;
    d.map[5][1].type:=wall;
(*    d.map[0][2].type:=wall;*)
(*    d.map[5][2].type:=wall;*)
    d.map[0][3].type:=wall;
    d.map[5][3].type:=wall;

    d.map[0][4].type:=wall;
    d.map[1][4].type:=wall;
(*    d.map[2][4].type:=wall;*)
    d.map[3][4].type:=wall;
    d.map[4][4].type:=wall;
    d.map[5][4].type:=wall;

    d.map[2][7].type:=wall;

    (* We are in the middle *)

    d.vx:=3.0;
    d.vy:=2.5;

    (* angle we are looking *)
    d.va:=M.pi*0/180;
  END Init;

  PROCEDURE (d : Doom) CalcSize*;

  VAR
    window : D.Window;

  BEGIN
    d.width:=10*D.display.spaceWidth;
    d.height:=10*D.display.spaceHeight;

    d.minWidth:=d.width;
    d.minHeight:=d.height;

    IF ~(G.inited IN d.flags) THEN
      window:=d.GetWindow();
      window.AddFreeList(d);
    END;

    d.CalcSize^;
  END CalcSize;

  PROCEDURE (d : Doom) DrawImage(rotate : BOOLEAN);

  VAR
    a,b,    (* y,x - length of the view vector *)
    ba,     (* b/a *)
    ab,     (* a/b *)
    va,     (* current viewing angle *)
    yA,     (* y value vor x=0 *)

    x1,x2,  (* kooridnates of the viewer *)
    p1,p2,  (* temporary variables *)
    dist,h,
    xDist,
    yDist

           : REAL;
    x,y,z,
    h2,

    xx,xy,
    yx,yy,
    xSide,
    ySide,
    side   : LONGINT;

    found,
    xDone,
    yDone  : BOOLEAN;
    draw   : D.DrawInfo;

    (*
      We calculate the intersection with each side (if an intersection exists
      and take the one with shortest distance

       4
      1o2      - sides of the cube
       3
    *)

    PROCEDURE IsHit(x,y : LONGINT; VAR side : LONGINT; VAR dist : REAL):BOOLEAN;

    VAR
      p1,p2,
      di    : REAL;

    BEGIN
      (* init *)
(*      dist:=MAX(REAL);
      side:=-1;*)

      (* 1 *)
      p1:=x;
      p2:=p1*ba+yA;
(*      Err.String("1 "); Err.RealFix(p1,3,3); Err.String(" "); Err.RealFix(p2,3,3);
      Err.String(" "); Err.RealFix(di,3,3);
      Err.Ln;*)
      IF (p2>=y) & (p2<=y+1) THEN
        di:=M.sqrt(M.power(p1-x1,2)+M.power(p2-x2,2));
        IF di<dist THEN
(*          Err.String("!"); Err.Ln;*)
          side:=1;
          dist:=di;
        END;
      END;

      (* 2 *)
      p1:=x+1;
      p2:=p1*ba+yA;
(*      Err.String("2 "); Err.RealFix(p1,3,3); Err.String(" "); Err.RealFix(p2,3,3);
      Err.String(" "); Err.RealFix(di,3,3);
      Err.Ln;*)
      IF (p2>=y) & (p2<=y+1) THEN
        di:=M.sqrt(M.power(p1-x1,2)+M.power(p2-x2,2));
        IF di<dist THEN
(*          Err.String("!"); Err.Ln;*)
          side:=2;
          dist:=di;
        END;
      END;

      (* 3 *)
      p2:=y;
      p1:=(p2-yA)*ab;
(*      Err.String("3 "); Err.RealFix(p1,3,3); Err.String(" "); Err.RealFix(p2,3,3);
      Err.String(" "); Err.RealFix(di,3,3);
      Err.Ln;*)
      IF (p1>=x) & (p1<=x+1) THEN
        di:=M.sqrt(M.power(p1-x1,2)+M.power(p2-x2,2));
        IF di<dist THEN
(*          Err.String("!"); Err.Ln;*)
          side:=3;
          dist:=di;
        END;
      END;

      (* 4 *)
      p2:=y+1;
      p1:=(p2-yA)*ab;
(*      Err.String("4 "); Err.RealFix(p1,3,3); Err.String(" "); Err.RealFix(p2,3,3);
      Err.String(" "); Err.RealFix(di,3,3);
      Err.Ln;*)
      IF (p1>=x) & (p1<=x+1) THEN
        di:=M.sqrt(M.power(p1-x1,2)+M.power(p2-x2,2));
        IF di<dist THEN
(*          Err.String("!"); Err.Ln;*)
          side:=4;
          dist:=di;
        END;
      END;

      RETURN side>0;
    END IsHit;

  BEGIN
    IF (d.bitmap=NIL) OR (d.bitmap.width#d.width) OR (d.bitmap.height#d.height) THEN
      IF d.bitmap#NIL THEN
        D.display.FreeBitmap(d.bitmap);
      END;
      d.bitmap:=D.display.CreateBitmap(d.width,d.height);
    END;

    (* rotate *)

    IF rotate THEN
      d.va:=(d.va+grad);
      IF d.va>twoPi THEN
        d.va:=d.va-twoPi;
      END;
    END;

    (*Drawing the background scenery *)
    d.bitmap.draw.PushForeground(D.blackColor);
    d.bitmap.draw.FillRectangle(0,0,d.bitmap.width,d.bitmap.height DIV 2);
    d.bitmap.draw.PopForeground;

    d.bitmap.draw.PushForeground(D.shadowColor);
    d.bitmap.draw.FillRectangle(0,d.bitmap.height DIV 2,d.bitmap.width,d.bitmap.height DIV 2);
    d.bitmap.draw.PopForeground;

    (*
      we estimate, that the width of the Doom represents a total viweing angle
      of 90 degree.

      For each vertical line we thus calculate an angle between d.va-pi/8<=d.va<=d.va+pi/8
      and then retrace the resulting viweing beam.
    *)
    FOR z:=0 TO d.width-1 DO

      (* calculate the view angle *)
      va:=d.va+((-z+d.width DIV 2) / (d.width DIV 2))*pi14/4;

      a:=M.cos(va);
      b:=M.sin(va);
      x1:=d.vx;
      x2:=d.vy;

      IF a#0 THEN
        ba:=b/a;
        yA:=(x2-ba*x1);
      ELSE
        yA:=MIN(REAL);
        ba:=MAX(REAL);
      END;

      IF b#0 THEN
        ab:=a/b;
      ELSE
        ab:=MAX(REAL);
      END;


(*
      Err.RealFix(va*180/M.pi,3,1); Err.String(" ");
      Err.RealFix(yA,3,3); Err.String(" ");
      Err.RealFix(x1,3,3); Err.String(" "); Err.RealFix(x2,3,3); Err.String(" ");
      Err.RealFix(a,3,3); Err.String(" "); Err.RealFix(b,3,3); Err.String(" ");
      Err.Ln;
*)

      found:=FALSE;

      (*
        Now we find the intersection point of the bean with the lines of the map.
        We are doing a gridlike search.
      *)

      IF a>=0 THEN
        x:=ENTIER(x1)+1;
      ELSE
        x:=ENTIER(x1);
      END;

      IF b>=0 THEN
        y:=ENTIER(x2)+1;
      ELSE
        y:=ENTIER(x2);
      END;

      xDone:=FALSE;
      yDone:=FALSE;
      xDist:=MAX(REAL);
      yDist:=MAX(REAL);
      found:=FALSE;
      WHILE  ~(xDone & yDone) DO
        (* searching on x axis, calculating x coord for current y*)
        IF ~xDone THEN
          p2:=y;
          p1:=(p2-yA)*ab;
          xx:=ENTIER(p1);
          xy:=y;
(*          Err.LongInt(xx,0);   Err.String("+");
          Err.LongInt(xy,0);   Err.String(" ");
          Err.RealFix(p1,3,3); Err.String(" ");
          Err.RealFix(p2,3,3);
          Err.Ln;*)
          IF (xx>=0) & (xx<width) & (d.map[xx][xy].type#free) THEN
            IF IsHit(xx,xy,xSide,xDist) THEN
(*              Err.String("!");
              Err.Ln;*)
              xDone:=TRUE;
              found:=TRUE;
            END;
          END;
          DEC(xy);
(*          Err.LongInt(xx,0);   Err.String("+");
          Err.LongInt(xy,0);   Err.String(" ");
          Err.RealFix(p1,3,3); Err.String(" ");
          Err.RealFix(p2,3,3);
          Err.Ln;*)
          IF (xy>0) & (xx>=0) & (xx<width) & (d.map[xx][xy].type#free) THEN
            IF IsHit(xx,xy,xSide,xDist) THEN
(*              Err.String("!");
              Err.Ln;*)
              xDone:=TRUE;
              found:=TRUE;
            END;
          END;
        END;

        IF ~yDone THEN
          p1:=x;
          p2:=ba*p1+yA;
          yx:=x;
          yy:=ENTIER(p2);
(*          Err.LongInt(yx,0);   Err.String("-");
          Err.LongInt(yy,0);   Err.String(" ");
          Err.RealFix(p1,3,3); Err.String(" ");
          Err.RealFix(p2,3,3);
          Err.Ln;*)
          IF (yy>=0) & (yy<height) & (d.map[yx][yy].type#free) THEN
            IF IsHit(yx,yy,ySide,yDist) THEN
(*              Err.String("!");
              Err.Ln;*)
              yDone:=TRUE;
              found:=TRUE;
            END;
          END;
          DEC(yx);
(*          Err.LongInt(yx,0);   Err.String("-");
          Err.LongInt(yy,0);   Err.String(" ");
          Err.RealFix(p1,3,3); Err.String(" ");
          Err.RealFix(p2,3,3);
          Err.Ln;*)
          IF (yx>0) & (yy>=0) & (yy<height) & (d.map[yx][yy].type#free) THEN
            IF IsHit(yx,yy,ySide,yDist) THEN
(*              Err.String("!");
              Err.Ln;*)
              yDone:=TRUE;
              found:=TRUE;
            END;
          END;
        END;

        IF ~xDone THEN
          IF b>=0 THEN
            INC(y);
          ELSE
            DEC(y);
          END;
          IF (y<0) OR (y>=height) THEN
            xDone:=TRUE;
          END;
        END;
        IF ~yDone THEN
          IF a>=0 THEN
            INC(x);
          ELSE
            DEC(x);
          END;
          IF (x<0) OR (x>=width) THEN
            yDone:=TRUE;
          END;
        END;
      END;

      IF found THEN

        IF xDist<=yDist THEN
          x:=xx;
          y:=xy;
          dist:=xDist;
          side:=xSide;
        ELSE
          x:=yx;
          y:=yy;
          dist:=yDist;
          side:=ySide;
        END;

(*      Err.RealFix(va*180/M.pi,3,1);Err.String(" ");
      Err.LongInt(x,0); Err.String(" ");
      Err.LongInt(y,0); Err.String(" ");
      Err.LongInt(side,0); Err.String(" ");
      Err.RealFix(dist,3,3); Err.String(" ");
      Err.Ln;*)

        ASSERT(side>0);

        h:=d.height*3/4;
        h2:=M.round(h*(5-dist)/5);
        IF side=1 THEN
          d.bitmap.draw.PushForeground(D.warnColor);
        ELSIF side=2 THEN
          d.bitmap.draw.PushForeground(D.whiteColor);
        ELSIF side=3 THEN
          d.bitmap.draw.PushForeground(D.fillColor);
        ELSE
          d.bitmap.draw.PushForeground(D.helpBackgroundColor);
        END;
        d.bitmap.draw.DrawLine(z,(d.height-h2) DIV 2,z,(d.height-h2) DIV 2 + h2);
        d.bitmap.draw.PopForeground;
      END;
    END;

    (* draw target cross *)
    d.bitmap.draw.PushForeground(D.whiteColor);
    d.bitmap.draw.DrawLine(d.width DIV 2,0,             d.width DIV 2,d.height-1);
    d.bitmap.draw.DrawLine(0            ,d.height DIV 2,d.width-1,    d.height DIV 2);
    d.bitmap.draw.PopForeground;

    Err.RealFix(d.va*180/M.pi,3,0); Err.Ln;

    draw:=d.GetDrawInfo();
    draw.CopyFromBitmap(d.bitmap,0,0,d.width,d.height,d.x,d.y);
  END DrawImage;

  PROCEDURE (d : Doom) Draw*(x,y,w,h : LONGINT);

  BEGIN
    d.Draw^(x,y,w,h);

    d.DrawImage(FALSE);

    IF d.timeOut=NIL THEN
      d.timeOut:=D.display.AddTimeOut(0,refreshRate,d);
    END;

(*    IF d.sleep=NIL THEN
      d.sleep:=D.display.AddSleep(d);
    END;*)
  END Draw;

  PROCEDURE (d : Doom) Hide*;

  BEGIN
    IF d.timeOut#NIL THEN
      D.display.RemoveTimeOut(d.timeOut);
      d.timeOut:=NIL;
    END;
(*    IF d.sleep#NIL THEN
      D.display.RemoveSleep(d.sleep);
      d.sleep:=NIL;
    END;*)

    IF d.visible THEN
      d.DrawHide;
      d.Hide^;
    END;
  END Hide;

  PROCEDURE (d : Doom) Receive*(msg : O.Message);

  BEGIN
    WITH msg:
      D.TimeOutMsg DO
        IF d.visible THEN
          d.DrawImage(TRUE);
          d.timeOut:=D.display.AddTimeOut(0,refreshRate,d);
        END;
(*      D.SleepMsg DO
        IF d.visible THEN
          d.DrawImage(TRUE);
        END;*)
    ELSE
    END;
  END Receive;

  PROCEDURE (d : Doom) Free*;

  BEGIN
    IF d.bitmap#NIL THEN
      D.display.FreeBitmap(d.bitmap);
    END;
    IF d.sleep#NIL THEN
      D.display.RemoveSleep(d.sleep);
    END;  END Free;

BEGIN
  grad:=M.pi/180;
  twoPi:=2*M.pi;
  pi14:=1*M.pi/4;
  pi34:=3*M.pi/4;
  pi54:=5*M.pi/4;
  pi74:=7*M.pi/4;
END VO:Doom.