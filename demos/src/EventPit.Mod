MODULE EventPit;

  (**
    Catches events and displays them.
  *)

(*
    Catches events and displays them.
    Copyright (C) 2004 Tim Teulings (rael@edge.ping.de)

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
       E   := VO:Base:Event,
       F   := VO:Base:Frame,
       Z   := VO:Base:Size,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,    (* The use the preferences setting *)
<* POP *>

       G   := VO:Object,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              ADT:StringBuffer,
              Err;           (* Simple error IO *)

TYPE
  Prefs      = POINTER TO PrefsDesc;
  PrefsDesc  = RECORD (G.PrefsDesc)
               END;

  Pit        = POINTER TO PitDesc;
  PitDesc    = RECORD (G.GadgetDesc)
                 (**
                   A simple gadget that catches events and displays
                   their internal values.
                 *)
               END;

  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  prefs    : Prefs;
  w        : Window;         (* The window *)
  msg2Exit : D.Msg2Exit;     (* a simple message converter *)

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.single);
    ELSE
      p.frame:=F.CreateFrame(F.double3DIn);
    END;
  END Initialize;

  PROCEDURE (p : Pit) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.RemoveFlags({G.stdFocus});
  END Init;

  PROCEDURE (p : Pit) CalcSize*;

  BEGIN
    p.width:=10;
    p.height:=10;

    p.minWidth:=p.width;
    p.minHeight:=p.height;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : Pit) DrawEvent(event : E.Event);

  VAR
    buffer : StringBuffer.StringBuffer;
    draw   : D.DrawInfo;
    tmp    : ARRAY 1024 OF CHAR;

    PROCEDURE AppendQualifier(qualifier : SET);

    BEGIN
      IF E.button1 IN qualifier THEN
        buffer.Append(" button1");
      END;
      IF E.button2 IN qualifier THEN
        buffer.Append(" button2");
      END;
      IF E.button3 IN qualifier THEN
        buffer.Append(" button3");
      END;
      IF E.button4 IN qualifier THEN
        buffer.Append(" button4");
      END;
      IF E.button5 IN qualifier THEN
        buffer.Append(" button5");
      END;

      IF E.qShiftLeft IN qualifier THEN
        buffer.Append(" shiftLeft");
      END;
      IF E.qShiftRight IN qualifier THEN
        buffer.Append(" shiftRight");
      END;

      IF E.qCapsLock IN qualifier THEN
        buffer.Append(" capsLock");
      END;

      IF E.qControlLeft IN qualifier THEN
        buffer.Append(" controlLeft");
      END;
      IF E.qControlRight IN qualifier THEN
        buffer.Append(" controlRight");
      END;

      IF E.qAltLeft IN qualifier THEN
        buffer.Append(" altLeft");
      END;
      IF E.qAltRight IN qualifier THEN
        buffer.Append(" altRight");
      END;

      IF E.qMetaLeft IN qualifier THEN
        buffer.Append(" metaLeft");
      END;
      IF E.qMetaRight IN qualifier THEN
        buffer.Append(" metaRight");
      END;

      IF E.qSuperLeft IN qualifier THEN
        buffer.Append(" superLeft");
      END;
      IF E.qSuperRight IN qualifier THEN
        buffer.Append(" superRight");
      END;

      IF E.qHyperLeft IN qualifier THEN
        buffer.Append(" hyperLeft");
      END;
      IF E.qHyperRight IN qualifier THEN
        buffer.Append(" hyperRight");
      END;
    END AppendQualifier;

  BEGIN
    buffer:=NEW(StringBuffer.StringBuffer,1000);
    WITH event : E.KeyEvent DO
      IF event.type=E.keyDown THEN
        buffer.Append("KEY DOWN");
      ELSE
        buffer.Append("KEY UP");
      END;

      buffer.Append(" KEY: ");
      buffer.AppendInt(event.key);

      buffer.Append(" KEYNAME: '");
      event.GetName(tmp);
      buffer.AppendLatin1(tmp);
      buffer.Append("'");

      buffer.Append(" QUALIFIER:");
      AppendQualifier(event.qualifier);

      buffer.Append(" TEXT: '");
      buffer.AppendLatin1(event.text^);
      buffer.Append("'");
    ELSE
    END;

    p.DrawBackground(p.x,p.y,p.width,p.height);

    draw:=p.GetDrawInfo();
    draw.InstallClip(p.x,p.y,p.width,p.height);
    draw.PushFont(D.normalFont,{});
    draw.PushForeground(D.textColor);
    draw.DrawStr(p.x,p.y+(p.height DIV 2),buffer.ToString());
    draw.PopForeground;
    draw.PopFont;
    draw.FreeLastClip;
  END DrawEvent;

  PROCEDURE (p : Pit) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~p.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    p.Draw^(x,y,w,h);

    p.DrawBackground(p.x,p.y,p.width,p.height);
  END Draw;

  PROCEDURE (p : Pit) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  BEGIN
    p.DrawEvent(event);
    RETURN TRUE;
  END HandleKeyEvent;

  PROCEDURE CreatePit*():Pit;

  VAR
    pit : Pit;

  BEGIN
    NEW(pit);
    pit.Init;

    RETURN pit;
  END CreatePit;

  PROCEDURE (w : Window) PreInit*;

  VAR
    pit : Pit;
    wGroup   : WG.WindowGroup; (* The window group *)

  BEGIN
    (*
      Allocate an instance of the window group class.
     This group handles positioning of menustrip and window contents.
    *)
    NEW(wGroup);

    (* Every instance must be initialized *)
    wGroup.Init;
    wGroup.SetFlags({G.horizontalFlex,G.verticalFlex});
    IF D.display.displayType=D.displayTypeTextual THEN
      wGroup.SetWidth(Z.screenHRel,100);
      wGroup.SetHeight(Z.screenVRel,100);
    ELSE
      wGroup.SetWidth(Z.screenHRel,50);
      wGroup.SetHeight(Z.screenVRel,25);
    END;

      pit:=CreatePit();
      pit.SetFlags({G.horizontalFlex,G.verticalFlex});
      pit.RequestFocus();

    wGroup.Set(NIL,pit,TRUE);
    (* Set the top object of the window to the window group *)
    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

BEGIN
  NEW(prefs);
  prefs.Init;

  IF ~Probe.OpenDisplay("EventPit") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  NEW(w);
  w.Init;
  w.SetTitle("EventPit");
  w.Forward(W.closeMsg,w);

  IF w.Open() THEN
    w.EventLoop;
  END;

  D.display.Close;
END EventPit.