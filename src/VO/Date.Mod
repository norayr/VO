MODULE VO:Date;

  (**
    Implements @otype{Date}.
  *)

  (*
    Implements a date selction object..
    Copyright (C) 2000 Tim Teulings (rael@edge.ping.de)

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
       E   := VO:Base:Event,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,
       U   := VO:Base:Util,
       Z   := VO:Base:Size,

       DT  := VO:Model:DateTime,

       G   := VO:Object,
       T   := VO:Text,

       C   := Calendar,
       Co  := IntStr,
       L   := Locales,
       SC  := SysClock,
       str := Strings;


CONST
  lastYear  = 31+7+0;
  lastMonth = 31+7+1;
  nextMonth = 31+7+2;
  nextYear  = 31+7+3;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hSpace*,
                 vSpace*     : Z.SizeDesc;
                 weekChars*,
                 monthChars* : LONGINT;
                 emptyFill*  : G.Background;
               END;

  Date*      = POINTER TO DateDesc;
  DateDesc*  = RECORD (G.GadgetDesc)
                 (**
                   Date implements a calender like view to select a day. It uses
                   a monthly overview togteher with some navigation buttons so that
                   you can select any day you like.

                   Value will be read from and written to an assigned model
                   that should be an instance of @otype{DT.DateTime}.

                   Future versions might even support some callback method to allow
                   special coloring for different days.
                 *)
                 date      : DT.DateTime;
                 local     : SC.DateTime;
                 weekStart : SHORTINT;
                 area      : ARRAY 7,7 OF LONGINT;
                 texts     : ARRAY 31+7+4 OF T.Text;
                 current   : T.Text;
                 frame     : F.Frame;
                 cw,ch     : LONGINT;
                 cS        : LONGINT; (* index within texts of the current selected day *)
               END;

VAR
  prefs*          : Prefs;


  PROCEDURE SetDayForCurrentMonthYear(VAR dateTime : SC.DateTime; day : SHORTINT);

  BEGIN
    IF dateTime.zone=SC.localTime THEN
      C.SetLocalTime(dateTime,
                     day,
                     dateTime.month,
                     dateTime.year,
                     dateTime.hour,
                     dateTime.minute,
                     dateTime.second);
    ELSE
      C.SetUTC(dateTime,
               day,
               dateTime.month,
               dateTime.year,
               dateTime.hour,
               dateTime.minute,
               dateTime.second);
    END;
  END SetDayForCurrentMonthYear;

  PROCEDURE IncMonth(VAR dateTime : SC.DateTime);

  VAR
    month : SHORTINT;
    year  : INTEGER;

  BEGIN
    IF dateTime.month=12 THEN
      month:=1;
      year:=dateTime.year+1;
    ELSE
      month:=dateTime.month+1;
      year:=dateTime.year;
    END;

    IF dateTime.zone=SC.localTime THEN
      C.SetLocalTime(dateTime,
                     dateTime.day,
                     month,
                     year,
                     dateTime.hour,
                     dateTime.minute,
                     dateTime.second);
    ELSE
      C.SetUTC(dateTime,
               dateTime.day,
               month,
               year,
               dateTime.hour,
               dateTime.minute,
               dateTime.second);
    END;
  END IncMonth;

  PROCEDURE DecMonth(VAR dateTime : SC.DateTime);

  VAR
    month : SHORTINT;
    year  : INTEGER;

  BEGIN
    IF dateTime.month=1 THEN
      month:=12;
      year:=dateTime.year-1;
    ELSE
      month:=dateTime.month-1;
      year:=dateTime.year;
    END;

    IF dateTime.zone=SC.localTime THEN
      C.SetLocalTime(dateTime,
                     dateTime.day,
                     month,
                     year,
                     dateTime.hour,
                     dateTime.minute,
                     dateTime.second);
    ELSE
      C.SetUTC(dateTime,
               dateTime.day,
               month,
               year,
               dateTime.hour,
               dateTime.minute,
               dateTime.second);
    END;
  END DecMonth;

  PROCEDURE MoveYear(VAR dateTime : SC.DateTime; count : INTEGER);

  BEGIN
    IF dateTime.zone=SC.localTime THEN
      C.SetLocalTime(dateTime,
                     dateTime.day,
                     dateTime.month,
                     dateTime.year+count,
                     dateTime.hour,
                     dateTime.minute,
                     dateTime.second);
    ELSE
      C.SetUTC(dateTime,
               dateTime.day,
               dateTime.month,
               dateTime.year+count,
               dateTime.hour,
               dateTime.minute,
               dateTime.second);
    END;
  END MoveYear;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.frame:=F.CreateFrame(F.none);

    p.hSpace.Init;
    p.vSpace.Init;
    IF D.display.displayType=D.displayTypeTextual THEN
      p.hSpace.SetSize(Z.pixel,0);
      p.vSpace.SetSize(Z.pixel,0);
    ELSE
      p.hSpace.SetSize(Z.unit,1);
      p.vSpace.SetSize(Z.unit,1);
    END;

    p.weekChars:=2;
    p.monthChars:=3;

    p.emptyFill:=BG.CreateBackgroundByFill(BG.CreatePatternFillByIndex(D.bigChess,D.halfShineColorIndex,D.shineColorIndex));

  END Initialize;

  PROCEDURE (d : Date) HandleDateChange;

  VAR
    x,y,
    day,
    week     : SHORTINT;
    current  : SC.DateTime;
    buf1,
    buf2     : ARRAY 256 OF CHAR;

  BEGIN
    FOR y:=1 TO 6 DO
      FOR x:=0 TO 6 DO
        d.area[x,y]:=-1;
      END;
    END;

    week:=1;
    C.SetLocalTime(current,1,d.local.month,d.local.year,0,0,0);

    week:=1;
    d.cS:=-1;
    FOR x:=1 TO C.DaysPerMonth(current) DO
      current.day:=x;
      day:=C.DayOfWeek(current);
      d.area[(day-d.weekStart) MOD 7,week]:=x-1;

      IF d.date#NIL THEN
        IF (current.year=d.date.dateTime.year)
        &  (current.month=d.date.dateTime.month)
        &  (current.day=d.date.dateTime.day) THEN
          d.cS:=x-1;
        END;
      END;

      IF day=(d.weekStart-1) MOD 7 THEN
        INC(week);
      END;
    END;

    current:=d.local;
    buf2:="";
    C.TimeToStr(current,"%B",buf1);
    buf1[d.prefs(Prefs).monthChars]:=0X;
    COPY(buf1,buf2);
    str.Append(" ",buf2);
    C.TimeToStr(current,"%Y",buf1);
    str.Append(buf1,buf2);
    d.current.SetText(buf2);

    IF d.visible THEN
      d.Redraw;
    END;
  END HandleDateChange;

  PROCEDURE (d : Date) Init*;

  VAR
    x,y    : LONGINT;
    string : ARRAY 256 OF CHAR;

  BEGIN
    d.Init^;

    d.SetPrefs(prefs);

    d.date:=NIL;

    d.weekStart:=C.monday;

    (* Initialize frame *)
    IF D.display.displayType=D.displayTypeTextual THEN
      d.frame:=F.CreateFrame(F.single);
    ELSE
      d.frame:=F.CreateFrame(F.w95BO);
    END;

    (* Initialize days texts *)
    FOR x:=0 TO 30 DO
      Co.IntToStr(x+1,string);
      d.texts[x]:=T.MakeCenterText(string);
    END;

    (* Initialize weekdays texts *)
    FOR x:=0 TO 6 DO
      IF L.GetStr(L.daysOfWeek+(d.weekStart+x) MOD 7,string) THEN
      END;
      string[d.prefs(Prefs).weekChars]:=0X; (* reduce length of weekdays *)
      d.texts[x+31]:=T.MakeCenterText(string);
    END;

    d.texts[lastYear]:=T.MakeCenterText("«");
    d.texts[lastMonth]:=T.MakeCenterText("<");
    d.texts[nextMonth]:=T.MakeCenterText(">");
    d.texts[nextYear]:=T.MakeCenterText("»");

    FOR x:=0 TO LEN(d.texts)-1 DO
      d.texts[x].SetFlags({G.horizontalFlex,G.verticalFlex});
      d.texts[x].SetParent(d);
    END;

    d.current:=T.MakeCenterText("");
    d.current.SetFlags({G.horizontalFlex});
    d.current.SetParent(d);

    (* Initial first row with weekdays texts *)
    FOR x:=0 TO 6 DO
      d.area[x,0]:=x+31;
    END;

    (* Initialize the rest to empty string *)
    FOR y:=1 TO 6 DO
      FOR x:=0 TO 6 DO
        d.area[x,y]:=-1;
      END;
    END;

    SC.GetClock(d.local);
    d.HandleDateChange;
  END Init;

  PROCEDURE (d : Date) SetModel*(model : O.Model);

  BEGIN
    IF d.date#NIL THEN
      d.UnattachModel(d.date);
    END;
    IF (model#NIL) & (model IS DT.DateTime) THEN
      d.date:=model(DT.DateTime);
      d.AttachModel(model);
    ELSE
      d.date:=NIL;
    END;
  END SetModel;

  PROCEDURE (d : Date) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN d.date=m;
  END ModelAccepted;

  PROCEDURE (d : Date) CalcSize*;

  VAR
    x : SHORTINT;

  BEGIN
    d.cw:=0;
    d.ch:=0;
    FOR x:=0 TO LEN(d.texts)-1 DO
      d.texts[x].CalcSize;
      d.cw:=U.MaxLong(d.cw,d.texts[x].minWidth);
      d.ch:=U.MaxLong(d.ch,d.texts[x].minHeight);
    END;

    INC(d.cw,d.prefs(Prefs).hSpace.GetSize()+d.frame.minWidth);
    INC(d.ch,d.prefs(Prefs).hSpace.GetSize()+d.frame.minHeight);

    d.current.CalcSize;

    d.cw:=U.MaxLong(d.cw,d.current.minWidth DIV 3);
    d.ch:=U.MaxLong(d.ch,d.current.minHeight);

    d.minWidth:=7*d.cw;
    d.minHeight:=8*d.ch;

    d.width:=d.minWidth;
    d.height:=d.minHeight;

    d.CalcSize^;
  END CalcSize;

  PROCEDURE (d : Date) HandleMouseEvent*(event : E.MouseEvent;
                                         VAR grab : G.Object):BOOLEAN;

  VAR
    x : SHORTINT;

  BEGIN
    IF ~d.visible OR d.disabled THEN
      RETURN FALSE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & d.PointIsIn(event.x,event.y)
       & (event.button=E.button1) THEN
        FOR x:=0 TO LEN(d.texts)-1 DO
          IF d.texts[x].PointIsIn(event.x,event.y) THEN
            IF (x>=0) & (x<=30) THEN
              SetDayForCurrentMonthYear(d.local,x+1);
              IF d.date#NIL THEN
                d.date.SetDateTime(d.local);
              END;
              d.HandleDateChange;
            ELSIF x=lastYear THEN
              IF event.qualifier={} THEN
                MoveYear(d.local,-1);
              ELSE
                MoveYear(d.local,-10);
              END;
              d.HandleDateChange;
            ELSIF x=lastMonth THEN
              DecMonth(d.local);
              d.HandleDateChange;
            ELSIF x=nextMonth THEN
              IncMonth(d.local);
              d.HandleDateChange;
            ELSIF x=nextYear THEN
              IF event.qualifier={} THEN
                MoveYear(d.local,1);
              ELSE
                MoveYear(d.local,10);
              END;
              d.HandleDateChange;
            END;
          END;
        END;
        IF (d.date#NIL) & d.current.PointIsIn(event.x,event.y) THEN
          IF event.qualifier={} THEN
            d.local:=d.date.dateTime;
          ELSE
            SC.GetClock(d.local);
            d.date.SetDateTime(d.local);
          END;
          d.HandleDateChange;
        END;
      END;
    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

(*  PROCEDURE (d : Date) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  VAR
    keysym : LONGINT;

  BEGIN
    IF event.type=E.keyDown THEN
      keysym:=event.GetKey();
      CASE keysym OF
        E.left,
        E.up:
          IF d.date#NIL THEN
            IF event.qualifier=E.shiftMask THEN
              d.date.DecYear;
            ELSE
              d.date.DecMonth;
            END;
            RETURN TRUE;
          END;
      | E.right,
        E.down:
          IF d.date#NIL THEN
            IF event.qualifier=E.shiftMask THEN
              d.date.IncYear;
            ELSE
              d.date.IncMonth;
            END;
            RETURN TRUE;
          END;
      ELSE
      END;
    END;
    RETURN FALSE;
  END HandleKeyEvent;*)

  PROCEDURE (d : Date) Layout*;

  BEGIN
    d.cw:=d.width DIV 7;
    d.ch:=d.height DIV 8;

    d.Layout^;
  END Layout;

  PROCEDURE (d : Date) Draw*(x,y,w,h : LONGINT);

  VAR
    X,Y  : LONGINT;
    draw : D.DrawInfo;
    text : LONGINT;

  BEGIN
    IF ~d.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    d.Draw^(x,y,w,h);

    draw:=d.GetDrawInfo();

    d.current.MoveResize(d.x+2*d.cw,d.y,3*d.cw,d.ch);
    d.current.Draw(x,y,w,h);

    draw.PushForeground(D.warnColor);
    draw.PushBackground(D.warnColor);

    draw.FillBackground(d.x+0*d.cw,d.y,d.cw,d.ch);
    d.frame.Draw(draw,d.x+0*d.cw,d.y,d.cw,d.ch);
    d.texts[lastYear].Resize(d.cw-d.frame.minWidth,d.ch-d.frame.minHeight);
    d.texts[lastYear].Move(d.x+0*d.cw+d.frame.leftBorder,d.y+d.frame.topBorder);
    d.texts[lastYear].Draw(x,y,w,h);

    draw.FillBackground(d.x+1*d.cw,d.y,d.cw,d.ch);
    d.frame.Draw(draw,d.x+1*d.cw,d.y,d.cw,d.ch);
    d.texts[lastMonth].Resize(d.cw-d.frame.minWidth,d.ch-d.frame.minHeight);
    d.texts[lastMonth].Move(d.x+1*d.cw+d.frame.leftBorder,d.y+d.frame.topBorder);
    d.texts[lastMonth].Draw(x,y,w,h);

    draw.FillBackground(d.x+5*d.cw,d.y,d.cw,d.ch);
    d.frame.Draw(draw,d.x+5*d.cw,d.y,d.cw,d.ch);
    d.texts[nextMonth].Resize(d.cw-d.frame.minWidth,d.ch-d.frame.minHeight);
    d.texts[nextMonth].Move(d.x+5*d.cw+d.frame.leftBorder,d.y+d.frame.topBorder);
    d.texts[nextMonth].Draw(x,y,w,h);

    draw.FillBackground(d.x+6*d.cw,d.y,d.cw,d.ch);
    d.frame.Draw(draw,d.x+6*d.cw,d.y,d.cw,d.ch);
    d.texts[nextYear].Resize(d.cw-d.frame.minWidth,d.ch-d.frame.minHeight);
    d.texts[nextYear].Move(d.x+6*d.cw+d.frame.leftBorder,d.y+d.frame.topBorder);
    d.texts[nextYear].Draw(x,y,w,h);

          draw.PopBackground;
          draw.PopForeground;

    FOR Y:=0 TO 6 DO
      FOR X:=0 TO 6 DO
        text:=d.area[X,Y];
        IF text>=0 THEN
          draw.FillBackground(d.x+X*d.cw,d.y+d.current.height+Y*d.ch,d.cw,d.ch);
          d.frame.Draw(draw,d.x+X*d.cw,d.y+d.current.height+Y*d.ch,d.cw,d.ch);
          d.texts[text].Resize(d.cw-d.frame.minWidth,d.ch-d.frame.minHeight);
          d.texts[text].Move(d.x+X*d.cw+d.frame.leftBorder,
                             d.y+d.current.height+Y*d.ch+d.frame.topBorder);
          IF text=d.cS THEN
            draw.mode:={D.selected};
          END;
          d.texts[text].Draw(x,y,w,h);
          draw.mode:={};
        ELSE
          d.prefs(Prefs).emptyFill.DrawRelObject(draw,d,
                                                 d.x+X*d.cw,
                                                 d.y+d.current.height+Y*d.ch,
                                                 d.cw,
                                                 d.ch);
        END;
      END;
    END;

    (* TODO: Fill right, bottom border *)

    IF d.disabled THEN
      d.DrawDisabled;
    END;
  END Draw;

  PROCEDURE (d : Date) Hide*;

  BEGIN
    IF d.visible THEN
      d.current.Hide;

      d.Hide^;
    END;
  END Hide;

  PROCEDURE (d : Date) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    (* we are not interested if the day hasn't changed *)
    (*    IF (d.local.day=d.date.dateTime.day)
     & (d.local.month=d.date.dateTime.month)
     & (d.local.year=d.date.dateTime.year) THEN
       RETURN;
      END;*)

    d.local:=d.date.dateTime;
    d.HandleDateChange;
  END Resync;

  PROCEDURE CreateDate*():Date;

    (**
      Creates a new instance of @otype{Date}.
    *)

  VAR
    date : Date;

  BEGIN
    NEW(date);
    date.Init;

    RETURN date;
  END CreateDate;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Date.