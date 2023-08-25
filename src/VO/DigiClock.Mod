MODULE VO:DigiClock;

  (**
    Implements @otype{DigiClock}.
  *)

  (*
    A digital clock.
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

IMPORT D  := VO:Base:Display,
       E  := VO:Base:Event,
       O  := VO:Base:Object,

       G  := VO:Object,
       S  := VO:Segment7,

       C  := Calendar,
       SC := SysClock;

CONST
  callPeriod = 1;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  DigiClock*     = POINTER TO DigiClockDesc;
  DigiClockDesc* = RECORD (G.GadgetDesc)
                     (**
                       A simple digital clock that show the current time and
                       alternativly the current date if selcted. The clock
                       updates itself automatically.
                     *)
                     segment    : ARRAY 4 OF S.Segment7;
                     timer      : D.Timer;
                     foreground,
                     numberBg   : D.Color;
                     selected   : BOOLEAN;
                   END;

VAR
  prefs* : Prefs;

  PROCEDURE (d : DigiClock) Init*;

  BEGIN
    d.Init^;

    d.SetPrefs(prefs);

    d.foreground:=D.textColor;
    d.numberBg:=D.backgroundColor;
    d.selected:=FALSE;

    d.timer:=D.factory.CreateTimer();
    d.timer.SetSecs(callPeriod,0);
    d.timer.SetObject(d);
  END Init;

  PROCEDURE (d : DigiClock) SetForeground*(color : D.Color);

    (**
      Sets the foreground color used for the digit.
    *)

  BEGIN
    d.foreground:=color;
  END SetForeground;

  PROCEDURE (d : DigiClock) SetNumberBackground*(color : D.Color);

    (**
      Sets the background color used for unhighlighted parts of the digits..
    *)

  BEGIN
    d.numberBg:=color;
  END SetNumberBackground;

  PROCEDURE (d : DigiClock) CalcSize*;

  VAR
    x,count  : LONGINT;

  BEGIN
    FOR x:=0 TO LEN(d.segment)-1 DO
      d.segment[x]:=S.CreateSegment7();
      d.segment[x].SetParent(d);
      d.segment[x].SetFlags({G.horizontalFlex,G.verticalFlex});
      d.segment[x].CalcSize;
    END;

    count:=LEN(d.segment);
    d.width:=count*d.segment[0].oWidth+ (* segment width *)
             (count-1)*D.display.spaceWidth DIV 2+ (* space between segments *)
             (count DIV 2-1)*D.display.spaceWidth; (* space for points *)
    d.height:=d.segment[0].oHeight;

    d.minWidth:=d.width;
    d.minHeight:=d.height;

    d.CalcSize^;
  END CalcSize;

  PROCEDURE (d : DigiClock) DrawClock(full : BOOLEAN);

  VAR
    sTime  : SC.DateTime;
    text   : ARRAY 9 OF CHAR;
    i,xPos,
    count,
    sWidth : LONGINT;
    draw   : D.DrawInfo;

  BEGIN
    draw:=d.GetDrawInfo();


    SC.GetClock(sTime);

    IF d.selected THEN
      C.TimeToStr(sTime,"%d%m%y",text);
    ELSE
      C.TimeToStr(sTime,"%H%M%S",text);
    END;

    count:=LEN(d.segment);

    (* Resizing *)
    sWidth:=(d.width-
            (count-1)*(D.display.spaceWidth DIV 2)-
            (count DIV 2 - 1)*D.display.spaceWidth
            ) DIV count;

    (* Drawing *)
    xPos:=d.x+(d.width-count*sWidth-
              (count-1)*(D.display.spaceWidth DIV 2)-
              (count DIV 2 - 1)*D.display.spaceWidth
              ) DIV 2;
    FOR i:=0 TO LEN(d.segment)-1 DO
      d.segment[i].SetValue(ORD(text[i])-ORD("0"));
      IF full THEN
        d.segment[i].SetOnColor(d.foreground);
        d.segment[i].SetOffColor(d.numberBg);
        d.segment[i].MoveResize(xPos,d.y,sWidth,d.height);
        d.segment[i].Draw(d.oX,d.oY,d.oWidth,d.oHeight);
      END;
      INC(xPos,d.segment[i].oWidth+D.display.spaceWidth DIV 2);
      IF (i+1<LEN(d.segment)-1) & ((i+1) MOD 2 = 0) THEN
        (* Draw little rectangles between the hour, minutes, seconds parts *)
        IF ~d.selected & (sTime.second MOD 2 = 0) THEN
          draw.PushForeground(d.foreground);
          draw.FillRectangle(xPos,d.y+d.height DIV 5,
                             D.display.spaceWidth DIV 2,
                             d.height DIV 5);
          draw.FillRectangle(xPos,d.y+3*(d.height DIV 5),
                             D.display.spaceWidth DIV 2,
                             d.height DIV 5);
          draw.PopForeground;
        ELSE
          d.DrawBackground(xPos,d.y+d.height DIV 5,
                           D.display.spaceWidth DIV 2,
                           d.height DIV 5);
          d.DrawBackground(xPos,d.y+3*(d.height DIV 5),
                           D.display.spaceWidth DIV 2,
                           d.height DIV 5);
        END;
        INC(xPos,D.display.spaceWidth);
      END;
    END;
  END DrawClock;

  PROCEDURE (d : DigiClock) HandleMouseEvent*(event : E.MouseEvent;
                                              VAR grab : G.Object):BOOLEAN;

  BEGIN
    (* It makes no sense to get the focus if we are currently not visible *)
    IF ~d.visible OR d.disabled THEN
      RETURN FALSE;
    END;

    (*
      When the left mousebutton gets pressed without any qualifier
      in the bounds of our button...
   *)

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & d.PointIsIn(event.x,event.y) & (event.button=E.button1) THEN
        (* We change our state to pressed and redisplay ourself *)
        d.selected:=TRUE;
        d.DrawClock(FALSE);

        (*
          Since we want the focus for waiting for buttonup we return
          a pointer to ourself.
        *)

        grab:=d;
        RETURN TRUE;
      ELSIF (event.type=E.mouseUp) & (event.button=E.button1) THEN
        (* We get unselected again and must redisplay ourself *)
        d.selected:=FALSE;
        d.DrawClock(FALSE);

        grab:=NIL;
        RETURN TRUE;
      END;
    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (d : DigiClock) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~d.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    d.Draw^(x,y,w,h);

    d.DrawBackground(d.x,d.y,d.width,d.height);

    d.DrawClock(TRUE);

    IF ~d.timer.active THEN
      D.display.AddTimer(d.timer);
    END;
  END Draw;

  PROCEDURE (d : DigiClock) Hide*;

  BEGIN
    IF d.timer.active THEN
      D.display.RemoveTimer(d.timer);
    END;
    IF d.visible THEN
      d.Hide^;
    END;
  END Hide;

  PROCEDURE (d : DigiClock) Receive*(msg : O.Message);

  BEGIN
    WITH msg:
      D.TimerMsg DO
        IF d.visible THEN
          d.DrawClock(FALSE);
          D.display.AddTimer(d.timer);
        END;
    ELSE
    END;
  END Receive;

  PROCEDURE CreateDigiClock*():DigiClock;

    (**
      Creates a new instance of @otype{DigiClock}.
    *)

  VAR
    digiClock : DigiClock;

  BEGIN
    NEW(digiClock);
    digiClock.Init;

    RETURN digiClock;
  END CreateDigiClock;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:DigiClock.