(**
   Control to change time of current date for VO:Model:DateTime.
**)

MODULE VO:Time;

(*
    Control to change time of current date for VO:Model:DateTime.
    Copyright (C) 2000  Tim Teulings (rael@edge.ping.de)

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
       F  := VO:Base:Frame,
       O  := VO:Base:Object,

       DT := VO:Model:DateTime,
       V  := VO:Model:Value,

       G  := VO:Object,
       P  := VO:Panel,
       S  := VO:Slider,
       SP := VO:Space,
       T  := VO:Text,

       C  := Calendar,
       SC := SysClock;


CONST
(*  repeatTimeOut = 75000;*) (* Time between button repeat *)

TYPE
  Prefs*     = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the cycle is stored.
  **)


  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  Time*      = POINTER TO TimeDesc;
  TimeDesc*  = RECORD (G.GadgetDesc)
                 date   : DT.DateTime;
                 panel  : P.Panel;
                 text   : T.Text;
                 hour,
                 minute : V.IntModel;
               END;

VAR
  prefs*          : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.frame:=F.CreateFrame(F.none);
  END Initialize;


  PROCEDURE (t : Time) Init*;

  BEGIN
    t.Init^;

    t.SetPrefs(prefs);

    t.date:=NIL;
    t.panel:=NIL;
    t.text:=NIL;

    NEW(t.hour);
    t.hour.Init;
    t.AttachModel(t.hour);

    NEW(t.minute);
    t.minute.Init;
    t.AttachModel(t.minute);

    t.hour.SetLongint(11);
    t.minute.SetLongint(55);
  END Init;

  PROCEDURE (t : Time) HandleDateChange;

  VAR
    text : ARRAY 256 OF CHAR;
    date : SC.DateTime;

  BEGIN
    date:=t.date.dateTime;

    IF t.hour#NIL THEN
      t.hour.SetLongint(date.hour);
    END;

    IF t.minute#NIL THEN
      t.minute.SetLongint(date.minute);
    END;

    IF t.text#NIL THEN
      C.TimeToStr(date,"%H:%M",text);
      t.text.SetText(text);
    END;
  END HandleDateChange;

  PROCEDURE (t : Time) HandleTimeChange;

  VAR
    date : SC.DateTime;

  BEGIN
    IF t.date#NIL THEN
      date:=t.date.dateTime;
      date.hour:=t.hour.GetShortint();
      date.minute:=t.minute.GetShortint();
      t.date.SetDateTime(date);
    END;
  END HandleTimeChange;

  PROCEDURE (t : Time) SetModel*(model : O.Model);

  BEGIN
    IF t.date#NIL THEN
      t.UnattachModel(t.date);
    END;
    IF (model#NIL) & (model IS DT.DateTime) THEN
      t.date:=model(DT.DateTime);
      t.AttachModel(model);
    ELSE
      t.date:=NIL;
    END;
  END SetModel;

  (**
    This function is used to check if an argument to SetModel
    was successfully accepted.
   **)

  PROCEDURE (t : Time) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN t.date=m;
  END ModelAccepted;

  PROCEDURE (t : Time) CalcSize*;

  VAR
    slider : S.Slider;

  BEGIN
    IF t.panel=NIL THEN
      t.panel:=P.CreateVPanel();
      t.panel.SetParent(t);
      t.panel.SetFlags({G.horizontalFlex,G.verticalFlex});

      t.text:=T.MakeCenterText("--:--");
      t.text.SetFlags({G.horizontalFlex});
      t.text.SetDefault(T.centered,{T.smart},D.normalFont);
      t.panel.Add(t.text);

      t.HandleDateChange; (* For updating the text object *)

      t.panel.Add(SP.CreateVSpace());

      slider:=S.CreateHSlider();
      slider.SetFlags({G.horizontalFlex});
      slider.SetRange(0,23);
      slider.SetModel(t.hour);
      t.panel.Add(slider);

      t.panel.Add(SP.CreateVSpace());

      slider:=S.CreateHSlider();
      slider.SetFlags({G.horizontalFlex});
      slider.SetRange(0,59);
      slider.SetModel(t.minute);
      t.panel.Add(slider);
    END;

    t.panel.CalcSize;

    t.minWidth:=t.panel.oMinWidth;
    t.minHeight:=t.panel.oMinHeight;

    t.width:=t.panel.oWidth;
    t.height:=t.panel.oHeight;

    t.CalcSize^;
  END CalcSize;

  PROCEDURE (t : Time) HandleMouseEvent*(event : E.MouseEvent;
                                         VAR grab : G.Object):BOOLEAN;

  BEGIN
    IF ~t.visible OR t.disabled THEN
      RETURN FALSE;
    ELSE
      RETURN t.panel.HandleMouseEvent(event,grab);
    END;
  END HandleMouseEvent;

  PROCEDURE (t : Time) Layout*;

  BEGIN
    t.panel.MoveResize(t.x,t.y,t.width,t.height);

    t.Layout^;
  END Layout;

  PROCEDURE (t : Time) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~t.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    t.Draw^(x,y,w,h);

    t.panel.Draw(x,y,w,h);

    IF t.disabled THEN
      t.DrawDisabled;
    END;
  END Draw;


  PROCEDURE (t : Time) Hide*;

  BEGIN
    IF t.visible THEN
      t.panel.Hide;
      t.Hide^;
    END;
  END Hide;

  PROCEDURE (t : Time) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF model=t.date THEN
      t.HandleDateChange;
    ELSE
      t.HandleTimeChange;
    END;
  END Resync;

  PROCEDURE CreateTime*():Time;

  VAR
    time : Time;

  BEGIN
    NEW(time);
    time.Init;

    RETURN time;
  END CreateTime;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Time.