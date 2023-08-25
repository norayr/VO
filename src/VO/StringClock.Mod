MODULE VO:StringClock;

  (**
    A nice digital clock, to be placed everywhere you like.
  *)

(*
    A digital clock.
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

IMPORT D  := VO:Base:Display,
       E  := VO:Base:Event,
       O  := VO:Base:Object,
       U  := VO:Base:Util,

       G  := VO:Object,

       C  := Calendar,
       SC := SysClock;

CONST
  callPeriod = 1;

TYPE
  Prefs*           = POINTER TO PrefsDesc;
  PrefsDesc*       = RECORD (G.PrefsDesc)
                     END;

  StringClock*     = POINTER TO StringClockDesc;
  StringClockDesc* = RECORD (G.GadgetDesc)
                       (**
                         A nice digital clock, to be placed everywhere you like.
                       *)
                       timer      : D.Timer;
                       foreground : D.Color;
                       font       : D.Font;
                       timeWidth,
                       dateWidth  : LONGINT;
                       selected   : BOOLEAN;
                     END;

VAR
  prefs* : Prefs;

  PROCEDURE (d : StringClock) Init*;

  BEGIN
    d.Init^;

    d.SetPrefs(prefs);

    d.foreground:=D.textColor;
    d.selected:=FALSE;
    d.font:=NIL;

    d.timer:=D.factory.CreateTimer();
    d.timer.SetSecs(callPeriod,0);
    d.timer.SetObject(d);
  END Init;

  PROCEDURE (d : StringClock) SetForeground*(color : D.Color);

  BEGIN
    d.foreground:=color;
  END SetForeground;

  PROCEDURE (d : StringClock) CalcSize*;

  VAR
    string : ARRAY 2 OF CHAR;

  BEGIN
    d.font:=D.fixedFont;
    string:="X";
    d.timeWidth:=8*d.font.TextWidth(string,1,{});
    d.dateWidth:=10*d.font.TextWidth(string,1,{});

    d.width:=U.MaxLong(d.timeWidth,d.dateWidth);
    d.height:=d.font.height;

    d.minWidth:=d.width;
    d.minHeight:=d.height;

    d.CalcSize^;
  END CalcSize;

  (**
    This method gets called when the window gets an event and looks for
    someone that processes it.

    If GetFocus return an object, that objets HandleEvent-method
    get called untill it gives away the focus.
  **)

  PROCEDURE (d : StringClock) HandleMouseEvent*(event : E.MouseEvent;
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
        d.Redraw;

        (*
          Since we want the focus for waiting for buttonup we return
          a pointer to ourself.
        *)

        grab:=d;
        RETURN TRUE;
      ELSIF (event.type=E.mouseUp) & (event.button=E.button1) THEN
        (* We get unselected again and must redisplay ourself *)
        d.selected:=FALSE;
        d.Redraw;

        grab:=NIL;
        RETURN TRUE;
      END;
    ELSE
    END;
    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (d : StringClock) Draw*(x,y,w,h : LONGINT);

  VAR
    sTime : SC.DateTime;
    text  : ARRAY 11 OF CHAR;
    draw  : D.DrawInfo;

  BEGIN
    IF ~d.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    d.Draw^(x,y,w,h);

    draw:=d.GetDrawInfo();

    draw.InstallClip(x,y,w,h);
    d.DrawBackground(d.x,d.y,d.width,d.height);

    SC.GetClock(sTime);

    draw.PushFont(D.fixedFont,{});
    draw.PushForeground(d.foreground);
    IF d.selected THEN
      C.TimeToStr(sTime,"%d.%m.%Y",text);
      draw.DrawString(d.x+(d.width-d.dateWidth) DIV 2,
                      d.y+d.font.ascent+(d.height-d.font.height) DIV 2,text,10);
    ELSE
      C.TimeToStr(sTime,"%H:%M:%S",text);
      draw.DrawString(d.x+(d.width-d.timeWidth) DIV 2,
                      d.y+d.font.ascent+(d.height-d.font.height) DIV 2,text,8);
    END;
    draw.PopForeground;
    draw.PopFont;

    draw.FreeLastClip;

    IF ~d.timer.active THEN
      D.display.AddTimer(d.timer);
    END;
  END Draw;

  PROCEDURE (d : StringClock) Hide*;

  BEGIN
    IF d.timer.active THEN
      D.display.RemoveTimer(d.timer);
    END;
    IF d.visible THEN
      d.Hide^;
    END;
  END Hide;

  PROCEDURE (d : StringClock) Receive*(msg : O.Message);

  BEGIN
    WITH msg:
      D.TimerMsg DO
        IF d.visible THEN
          d.Redraw;
        END;
    ELSE
    END;
  END Receive;

  PROCEDURE CreateStringClock*():StringClock;

  VAR
    clock : StringClock;

  BEGIN
    NEW(clock);
    clock.Init;

    RETURN clock;
  END CreateStringClock;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:StringClock.