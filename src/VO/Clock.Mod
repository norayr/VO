MODULE VO:Clock;

  (**
    Implements @otype{Clock}.
  *)

(*
    A analog clock.
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
       F   := VO:Base:Frame,
       O   := VO:Base:Object,
       U   := VO:Base:Util,

       G   := VO:Object,

       SC  := SysClock;

CONST
  callPeriod = 1;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 pointerScale*,
                 secPointerScale*,
                 hourScale*,
                 minuteScale*       : LONGINT;
               END;


  Clock*     = POINTER TO ClockDesc;
  ClockDesc* = RECORD (G.GadgetDesc)
                 (**
                   A simple analog clock with hour, minute,s scond pointers
                   and ticks.
                 *)
                 timer   : D.Timer;
               END;

VAR
  prefs* : Prefs;
  sinTab : ARRAY 16 OF LONGINT;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.frame:=F.CreateFrame(F.none);

    p.pointerScale:=50;
    p.hourScale:=100;
    p.minuteScale:=200;
    p.secPointerScale:=400;
  END Initialize;

  PROCEDURE (c : Clock) Init*;

  BEGIN
    c.Init^;

    c.SetPrefs(prefs);

    c.timer:=D.factory.CreateTimer();
    c.timer.SetSecs(callPeriod,0);
    c.timer.SetObject(c);
  END Init;

  PROCEDURE (c : Clock) CalcSize*;

  BEGIN
    c.width:=15;
    c.height:=15;

    c.minWidth:=c.width;
    c.minHeight:=c.height;

    c.CalcSize^;
  END CalcSize;

  PROCEDURE sin(grad : LONGINT):LONGINT;

    (**
      For performance we calculate sinus and cosinus using a hardcoded table.
    *)

  BEGIN
    IF (grad>=0) & (grad<=90) THEN
      RETURN sinTab[grad DIV 6];
    ELSIF (grad>=91) & (grad<=179) THEN
      RETURN sin(-grad+180);
    ELSIF (grad>=180) & (grad<=269) THEN
      RETURN -sin(grad-180);
    ELSE (*grad>270*)
      RETURN -sin(360-grad);
    END;
  END sin;

  PROCEDURE cos(grad : LONGINT):LONGINT;

    (**
      For performance we calculate sinus and cosinus using a hardcoded table.
    *)

  BEGIN
    RETURN sin((grad+90) MOD 360);
  END cos;

  PROCEDURE (c : Clock) Draw*(x,y,w,h : LONGINT);

  VAR
    zx,zy,r,
    height,i : LONGINT;
    sTime    : SC.DateTime;
    draw     : D.DrawInfo;

  BEGIN
    IF ~c.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    c.Draw^(x,y,w,h);

    draw:=c.GetDrawInfo();

    c.DrawBackground(c.x,c.y,c.width,c.height);

    SC.GetClock(sTime);

    height:=c.height;

    zx:=c.x+c.width DIV 2;
    zy:=c.y+height DIV 2;

    r:=U.MinLong(c.width-D.display.spaceWidth,height-D.display.spaceHeight) DIV 2;

    draw.PushStyle(U.MinLong(c.width,c.height) DIV c.prefs(Prefs).pointerScale+1,
                   D.roundPen);
    draw.PushForeground(D.textColor);
    draw.DrawLine(zx,zy,
                  zx+(r * sin((LONG(sTime.hour) MOD 12)*30+sTime.minute DIV 2) DIV 1500),
                  zy-(r * cos((LONG(sTime.hour) MOD 12)*30+sTime.minute DIV 2) DIV 1500));
    draw.DrawLine(zx,zy,
                  zx+(r * sin(LONG(sTime.minute)*6) DIV 1000),
                  zy-(r * cos(LONG(sTime.minute)*6) DIV 1000));
    draw.PopForeground;
    draw.PopStyle;

    draw.PushStyle(U.MinLong(c.width,c.height) DIV c.prefs(Prefs).secPointerScale+1,
                   D.roundPen);
    draw.PushForeground(D.warnColor);
    draw.DrawLine(zx,zy,
                  zx+(r * sin(LONG(sTime.second)*6) DIV 1150),
                  zy-(r * cos(LONG(sTime.second)*6) DIV 1150));
    draw.PopForeground;
    draw.PopStyle;

    IF r>25 THEN (* minimum radius for drawing minute ticks *)
      draw.PushStyle(U.MinLong(c.width,c.height) DIV c.prefs(Prefs).minuteScale+1,D.roundPen);
      draw.PushForeground(D.textColor);
      FOR i:=0 TO 59 DO
        draw.DrawLine(zx+(r * sin(i*6) DIV 1030),
                      zy-(r * cos(i*6) DIV 1030),
                      zx+(r * sin(i*6) DIV 1000),
                      zy-(r * cos(i*6) DIV 1000));
      END;
      draw.PopForeground;
      draw.PopStyle;
    END;

    IF r>10 THEN (* minimum radius for drawing hour ticks *)
      draw.PushStyle(U.MinLong(c.width,c.height) DIV c.prefs(Prefs).hourScale+1,D.roundPen);
      draw.PushForeground(D.textColor);
      FOR i:=0 TO 11 DO
        draw.DrawLine(zx+(r * sin(i*30) DIV 1150),
                      zy-(r * cos(i*30) DIV 1150),
                      zx+(r * sin(i*30) DIV 1000),
                      zy-(r * cos(i*30) DIV 1000));
      END;
      draw.PopForeground;
      draw.PopStyle;
    END;

    IF ~c.timer.active THEN
      D.display.AddTimer(c.timer);
    END;
  END Draw;

  PROCEDURE (c : Clock) Hide*;

  BEGIN
    IF c.timer.active THEN
      D.display.RemoveTimer(c.timer);
    END;
    IF c.visible THEN
      c.Hide^;
    END;
  END Hide;

  PROCEDURE (c : Clock) Receive*(msg : O.Message);

  BEGIN
    WITH msg:
      D.TimerMsg DO
        IF c.visible THEN
          c.Redraw;
        END;
    ELSE
    END;
  END Receive;

  PROCEDURE CreateClock*():Clock;

    (**
      Creates a new instance of @otype{Clock}.
    *)

  VAR
    clock : Clock;

  BEGIN
    NEW(clock);
    clock.Init;

    RETURN clock;
  END CreateClock;

BEGIN
  sinTab[ 0]:= 000; (*  0 *)
  sinTab[ 1]:= 105; (*  6 *)
  sinTab[ 2]:= 208; (* 12 *)
  sinTab[ 3]:= 309; (* 18 *)
  sinTab[ 4]:= 407; (* 24 *)
  sinTab[ 5]:= 500; (* 30 *)
  sinTab[ 6]:= 588; (* 36 *)
  sinTab[ 7]:= 669; (* 42 *)
  sinTab[ 8]:= 743; (* 48 *)
  sinTab[ 9]:= 809; (* 54 *)
  sinTab[10]:= 866; (* 60 *)
  sinTab[11]:= 914; (* 66 *)
  sinTab[12]:= 951; (* 72 *)
  sinTab[13]:= 978; (* 78 *)
  sinTab[14]:= 995; (* 84 *)
  sinTab[15]:=1000; (* 90 *)

  NEW(prefs);
  prefs.Init;
END VO:Clock.