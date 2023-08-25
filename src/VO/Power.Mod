MODULE VO:Power;

  (**
    A simple flashing light, to show that your application has not
    crashed (yet ;-)).
  *)

(*
    Implements something like a flashing power LED.
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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

IMPORT D := VO:Base:Display,
       F := VO:Base:Frame,
       O := VO:Base:Object,

       G := VO:Object;

CONST
  blinkPeriod = 100;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;


  Power*     = POINTER TO PowerDesc;
  PowerDesc* = RECORD (G.ImageDesc)
                 (**
                   A simple flashing light, to show that your application has not
                   crashed (yet ;-)).
                 *)
                 timer   : D.Timer;
                 current : LONGINT;
                 up      : BOOLEAN;
               END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.frame:=F.CreateFrame(F.double3DIn);
  END Initialize;

  PROCEDURE (p : Power) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.timer:=D.factory.CreateTimer();
    p.timer.SetSecs(0,blinkPeriod);
    p.timer.SetObject(p);

    p.current:=D.blackColor;
    p.up:=TRUE;
  END Init;

  PROCEDURE (p : Power) CalcSize*;

  BEGIN
    p.width:=5;
    p.height:=5;

    p.minWidth:=p.width;
    p.minHeight:=p.height;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : Power) DrawBox;

  VAR
    draw : D.DrawInfo;

  BEGIN
    draw:=p.GetDrawInfo();

    draw.PushForeground(p.current);
    draw.FillRectangle(p.x,p.y,p.width,p.height);
    draw.PopForeground;

    IF p.current=D.blackColor THEN
      p.up:=TRUE;
      p.current:=D.shadowColor;
    ELSIF p.current=D.shadowColor THEN
      IF p.up THEN
        p.current:=D.halfShadowColor;
      ELSE
        p.current:=D.blackColor;
      END;
    ELSIF p.current=D.halfShadowColor THEN
      IF p.up THEN
        p.current:=D.backgroundColor;
      ELSE
        p.current:=D.shadowColor;
      END;
    ELSIF p.current=D.backgroundColor THEN
      IF p.up THEN
        p.current:=D.halfShineColor;
      ELSE
        p.current:=D.halfShadowColor;
      END;
    ELSIF p.current=D.halfShineColor THEN
      IF p.up THEN
        p.current:=D.shineColor;
      ELSE
        p.current:=D.backgroundColor;
      END;
    ELSIF p.current=D.shineColor THEN
      IF p.up THEN
        p.current:=D.whiteColor;
      ELSE
        p.current:=D.halfShineColor;
      END;
    ELSIF p.current=D.whiteColor THEN
      p.current:=D.shineColor;
      p.up:=FALSE;
    END;

  END DrawBox;

  PROCEDURE (p : Power) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~p.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    p.Draw^(x,y,w,h);

    p.DrawBox;

    IF ~p.timer.active THEN
      D.display.AddTimer(p.timer);
    END;
  END Draw;

  PROCEDURE (p : Power) Hide*;

  BEGIN
    IF p.timer.active THEN
      D.display.RemoveTimer(p.timer);
    END;

    IF p.visible THEN
      p.Hide^;
    END;
  END Hide;

  PROCEDURE (p : Power) Receive*(msg : O.Message);

  BEGIN
    WITH msg:
      D.TimerMsg DO
        IF p.visible THEN
          p.DrawBox;
          D.display.AddTimer(p.timer);
        END;
    ELSE
    END;
  END Receive;

  PROCEDURE CreatePower*():Power;

  VAR
    power : Power;

  BEGIN
    NEW(power);
    power.Init;

    RETURN power;
  END CreatePower;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Power.