MODULE VO:OS:Carbon:Event;

(**
  This module defines a number of events - based on userinteraction -
  a object (gadget, window) can get. These messages are OS-independant,
  but offer a way to interpret the underlying OS-specific events, however
  the interface to that part of the events is not portable.

  NOTE
  * Not all GUIs can name the qualifiers extactly. F.e. X11 does not make a
    destinction between shift_left and shift_right in the qualifier field
    of an event. use the qualifier mask for that or handle key up and down for
    qualifiers explicitely..
**)

(*
    Classhierachie defining a number of OS-independend messgaes.
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

IMPORT E  := VO:Base:Event,

             Carbon,

             SYSTEM,Err;

TYPE
  Event*          = POINTER TO EventDesc;
  EventDesc*      = RECORD (E.EventDesc)
  (**
    Baseclass for events. Currently all objects get a instance
    of this baseclass and then have to analyse the message by
    evaluating the containing X11-event itself. This may change in the
    future. Display will send generate and send instances of inherited
    Classes thatd define abstract events.
  *)
                      event- : Carbon.EventRef;
                    END;

  KeyEvent*       = POINTER TO KeyEventDesc;
  KeyEventDesc*   = RECORD (E.KeyEventDesc)
  (**
    Keyboard event. The application receives this event when a key
    has been pressed or raised.
  *)
                      event- : Carbon.EventRef;
                    END;

  ButtonEvent*    = POINTER TO ButtonEventDesc;
  ButtonEventDesc* = RECORD (E.ButtonEventDesc)
  (**
    Mouse event. The application recieves this event when one or
    more mousebuttons have been pressed or released. You'll also
    get events when the mouse moves.
  *)
                       event- : Carbon.EventRef;
                     END;

  MotionEvent*    = POINTER TO MotionEventDesc;
  MotionEventDesc* = RECORD (E.MotionEventDesc)
  (**
    Mouse event. The application recieves this event when one or
    more mousebuttons have been pressed or released. You'll also
    get events when the mouse moves.
  *)
                       event- : Carbon.EventRef;
                     END;

VAR
  simpleEvent : Event;
  buttonEvent : ButtonEvent;
  motionEvent : MotionEvent;
  keyEvent    : KeyEvent;

  PROCEDURE GetQualifiers(event : Carbon.EventRef):SET;

  VAR
    system,
    qualifier : SET;
    button    : Carbon.EventMouseButton;

  BEGIN
    system:={};
    qualifier:={};

    IF Carbon.GetEventParameter(event,
                                Carbon.kEventParamKeyModifiers,
                                Carbon.typeUInt32,
                                NIL,
                                SIZE(SET),
                                NIL,
                                SYSTEM.VAL(LONGINT,SYSTEM.ADR(system)))=0 THEN

      IF Carbon.shiftKeyBit IN system THEN
        qualifier:=qualifier+E.shiftMask;
      END;
      IF Carbon.kEventKeyModifierNumLockBit IN system THEN
        INCL(qualifier,E.qCapsLock);
      END;
      IF Carbon.controlKeyBit IN system THEN
        qualifier:=qualifier+E.controlMask;
      END;
      IF Carbon.optionKeyBit IN system THEN
        qualifier:=qualifier+E.metaMask;
      END;
      IF Carbon.cmdKeyBit IN system THEN
        qualifier:=qualifier+E.altMask;
      END;
    END;

(*    IF Carbon.GetEventParameter(event,
                                Carbon.kEventParamMouseButton,
                                Carbon.typeMouseButton,
                                NIL,
                                SIZE(Carbon.EventMouseButton),
                                NIL,
                                SYSTEM.VAL(LONGINT,SYSTEM.ADR(button)))=0 THEN

(*      Err.String("MouseButton: "); Err.LongInt(button,0); Err.Ln;*)

      IF button MOD 2=1 THEN
        INCL(qualifier,E.button1);
      END;
    END;*)

    RETURN qualifier;
  END GetQualifiers;

  PROCEDURE (e : KeyEvent) SetCarbonEvent(event : Carbon.EventRef);
  (**
    NOTE
      THis as a VODisplay-only access-method for initializing the MouseEvent.
      Do not call this method in your code, it is VODisplay only and does only
      exists on X11 implementations of VisualOberon.
  *)

  BEGIN
    e.event:=event;

    CASE Carbon.GetEventKind(event) OF
      Carbon.kEventRawKeyDown,
      Carbon.kEventRawKeyRepeat:
      e.type:=E.keyDown;
    | Carbon.kEventRawKeyUp:
      e.type:=E.keyUp;
    END;

    e.text[0]:=0X;
    IF Carbon.GetEventParameter(event,
                                Carbon.kEventParamKeyMacCharCodes,
                                Carbon.typeChar,
                                NIL,
                                SIZE(CHAR),
                                NIL,
                                SYSTEM.VAL(LONGINT,SYSTEM.ADR(e.text[0])))#Carbon.noErr THEN
      e.text[0]:=0X;
    END;

    IF e.text[0]=0X THEN
      e.textLength:=0;
    ELSE
      e.textLength:=1;
    END;

    e.qualifier:=GetQualifiers(event);

    e.key:=-1;
    IF Carbon.GetEventParameter(event,
                                Carbon.kEventParamKeyCode,
                                Carbon.typeUInt32,
                                NIL,
                                SIZE(LONGINT),
                                NIL,
                                SYSTEM.VAL(LONGINT,SYSTEM.ADR(e.key)))#Carbon.noErr THEN
      e.key:=-1;
    END;

    CASE e.key OF
    | 024H:
      e.key:=E.return;
    | 030H:
      IF e.qualifier*E.shiftMask#{} THEN
        e.key:=E.leftTab;
      ELSE
        e.key:=E.tab;
      END;
    | 031H:
      e.key:=E.space;
    | 033H:
      e.key:=E.backspace;
    | 035H:
      e.key:=E.escape;
    | 060H:
      e.key:=E.f5;
    | 061H:
      e.key:=E.f6;
    | 062H:
      e.key:=E.f7;
    | 063H:
      e.key:=E.f3;
    | 064H:
      e.key:=E.f8;
    | 065H:
      e.key:=E.f9;
    | 067H:
      e.key:=E.f11;
    | 06DH:
      e.key:=E.f10;
    | 06FH:
      e.key:=E.f12;
    | 073H:
      e.key:=E.home;
    | 074H:
      e.key:=E.prior;
    | 076H:
      e.key:=E.f4;
    | 077H:
      e.key:=E.end;
    | 078H:
      e.key:=E.f2;
    | 079H:
      e.key:=E.next;
    | 07AH:
      e.key:=E.f1;
    | 07BH:
      e.key:=E.left;
    | 07CH:
      e.key:=E.right;
    | 07DH:
      e.key:=E.down;
    | 07EH:
      e.key:=E.up;
    ELSE
      (*Err.String("unknown keycode: "); Err.Hex(e.key,0); Err.Ln;*)
      e.key:=E.unknown;
    END;

    IF e.key>=0 THEN

      (*e.text[0]:=0X;
      e.textLength:=0;*)
    ELSE
      (*Err.String("Char: '");
      Err.String(e.text^);
      Err.String("'");Err.Ln;*)
    END;

(*    Err.String("Key: '"); Err.String(e.text^); Err.Char("'"); Err.Ln;*)

  END SetCarbonEvent;

  PROCEDURE (e : KeyEvent) GetName*(VAR buffer : ARRAY OF CHAR);
  (**
    Returns a string representing the name of key(s) pressed.
   *)

  BEGIN
    IF ~E.GetKeyName(e.key,buffer) THEN
      buffer[0]:=e.text[0];
      buffer[1]:=0X;

      IF E.shiftMask*e.qualifier=E.shiftMask THEN
        buffer[0]:=CAP(buffer[0]);
      END;

      IF E.controlMask*e.qualifier=E.controlMask THEN
        buffer[0]:=CHR(ORD(buffer[0])+96);
      END;

      (*string:=X11.XKeysymToString(e.key);
      IF string#NIL THEN
        count:=0;
        WHILE (string[count]#0X) & (count<LEN(buffer)-1) DO
          buffer[count]:=string[count];
          INC(count);
        END;
        buffer[count]:=0X;
      END;*)
    END;
  END GetName;

  PROCEDURE (e : ButtonEvent) SetCarbonEvent(event : Carbon.EventRef);

  VAR
    point  : Carbon.Point;
    button : Carbon.EventMouseButton;

  BEGIN
    e.event:=event;

    CASE Carbon.GetEventKind(event) OF
      Carbon.kEventMouseUp:
      e.type:=E.mouseUp;
    | Carbon.kEventMouseDown:
      e.type:=E.mouseDown;
    ELSE
      e.type:=-1;
    END;

    IF Carbon.GetEventParameter(event,
                                Carbon.kEventParamMouseLocation,
                                Carbon.typeQDPoint,
                                NIL,
                                SIZE(Carbon.Point),
                                NIL,
                                SYSTEM.VAL(LONGINT,SYSTEM.ADR(point)))=0 THEN
      Carbon.GlobalToLocal(SYSTEM.VAL(Carbon.PointPtr, SYSTEM.ADR(point)));
      e.x:=point.h;
      e.y:=point.v;
    ELSE
      e.x:=-1;
      e.y:=-1;
    END;

    IF Carbon.GetEventParameter(event,
                                Carbon.kEventParamMouseButton,
                                Carbon.typeMouseButton,
                                NIL,
                                SIZE(Carbon.EventMouseButton),
                                NIL,
                                SYSTEM.VAL(LONGINT,SYSTEM.ADR(button)))=0 THEN

      IF button MOD 2 = 1 THEN
        e.button:=E.button1;
      END;
    ELSE
      e.button:=-1;
    END;

    e.qualifier:=GetQualifiers(event);
  END SetCarbonEvent;

  PROCEDURE (e : MotionEvent) SetCarbonEvent(event : Carbon.EventRef);

  VAR
    point  : Carbon.Point;
    button : Carbon.EventMouseButton;

  BEGIN
    e.event:=event;

    IF Carbon.GetEventParameter(event,
                                Carbon.kEventParamMouseLocation,
                                Carbon.typeQDPoint,
                                NIL,
                                SIZE(Carbon.Point),
                                NIL,
                                SYSTEM.VAL(LONGINT,SYSTEM.ADR(point)))=0 THEN
      Carbon.GlobalToLocal(SYSTEM.VAL(Carbon.PointPtr, SYSTEM.ADR(point)));
      e.x:=point.h;
      e.y:=point.v;
    ELSE
      e.x:=-1;
      e.y:=-1;
    END;

    e.qualifier:=GetQualifiers(event);

    IF Carbon.GetEventParameter(event,
                                Carbon.kEventParamMouseButton,
                                Carbon.typeMouseButton,
                                NIL,
                                SIZE(Carbon.EventMouseButton),
                                NIL,
                                SYSTEM.VAL(LONGINT,SYSTEM.ADR(button)))=0 THEN

      IF button MOD 2 = 1 THEN
        INCL(e.qualifier,E.button1);
      END;
    END;
  END SetCarbonEvent;

  PROCEDURE GetEvent*(event : Carbon.EventRef):E.Event;
  (**
    Convert the given Curses event to a VisualOberon event.
  *)

  BEGIN
    CASE Carbon.GetEventClass(event) OF
      Carbon.kEventClassMouse:
      CASE Carbon.GetEventKind(event) OF
        Carbon.kEventMouseUp,
        Carbon.kEventMouseDown:
        buttonEvent.SetCarbonEvent(event);
        RETURN buttonEvent;
      | Carbon.kEventMouseMoved,
        Carbon.kEventMouseDragged:
        motionEvent.SetCarbonEvent(event);
        RETURN motionEvent;
      ELSE
      END;
    | Carbon.kEventClassKeyboard:
      CASE Carbon.GetEventKind(event) OF
        Carbon.kEventRawKeyDown,
        Carbon. kEventRawKeyRepeat,
        Carbon.kEventRawKeyUp:
        keyEvent.SetCarbonEvent(event);
        RETURN keyEvent;
      ELSE
      END;
    ELSE
    END;

    simpleEvent.event:=event;
    RETURN simpleEvent;
  END GetEvent;

  PROCEDURE GetCarbonEvent*(event : E.Event;
                          VAR carbonEvent : Carbon.EventRef);

  BEGIN
    WITH
      event : ButtonEvent DO
      carbonEvent:=event.event;
    | event : MotionEvent DO
      carbonEvent:=event.event;
    | event : KeyEvent DO
      carbonEvent:=event.event;
    | event : Event DO
      carbonEvent:=event.event;
    END;
  END GetCarbonEvent;

BEGIN
  NEW(simpleEvent);
  NEW(keyEvent);
  NEW(keyEvent.text,256);
  NEW(buttonEvent);
  NEW(motionEvent);
END VO:OS:Carbon:Event.