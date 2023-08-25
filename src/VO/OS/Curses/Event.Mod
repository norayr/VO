MODULE VO:OS:Curses:Event;

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

             Ascii,
       ls := CharClass,
             Curses,
             Strings;

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
                      event  : Curses.Event;
                    END;

  KeyEvent*       = POINTER TO KeyEventDesc;
  KeyEventDesc*   = RECORD (E.KeyEventDesc)
  (**
    Keyboard event. The application receives this event when a key
    has been pressed or raised.
  *)
                      event  : Curses.Event;
                      window : Curses.Window;
                    END;

  ButtonEvent*    = POINTER TO ButtonEventDesc;
  ButtonEventDesc* = RECORD (E.ButtonEventDesc)
  (**
    Mouse event. The application recieves this event when one or
    more mousebuttons have been pressed or released. You'll also
    get events when the mouse moves.
  *)
                       event  : Curses.Event;
                     END;

  (*
  MotionEvent*    = POINTER TO MotionEventDesc;
  MotionEventDesc* = RECORD (E.MotionEventDesc)
  (**
    Mouse event. The application recieves this event when one or
    more mousebuttons have been pressed or released. You'll also
    get events when the mouse moves.
  *)
                       event  : Curses.Event;
                     END;
*)
VAR
  simpleEvent : Event;
  buttonEvent : ButtonEvent;
(*  motionEvent : MotionEvent;*)
  keyEvent    : KeyEvent;

  PROCEDURE (e : KeyEvent) SetCursesEvent(event : Curses.Event;
                                          window : Curses.Window;
                                          meta : BOOLEAN);
  (**
    NOTE
      THis as a VODisplay-only access-method for initializing the MouseEvent.
      Do not call this method in your code, it is VODisplay only and does only
      exists on X11 implementations of VisualOberon.
  *)

  VAR
    name : ARRAY 256 OF CHAR;

  BEGIN
    e.event:=event;
    e.window:=window;

    e.textLength:=1;

    NEW(e.text,2);
    window.ConvertToKeyEvent(event,e.text[0]);
    e.text[1]:=0X;

(*    Err.String("Key: '"); Err.String(e.text^); Err.Char("'"); Err.Ln;*)

    window.GetEventName(event,name);

    e.type:=E.keyDown;
    e.qualifier:={};

    IF meta THEN
      e.qualifier:=e.qualifier+E.altMask;
    END;

    IF name="^M" THEN
      e.key:=E.return;
    ELSIF name="KEY_PPAGE" THEN
      e.key:=E.prior;
      e.text[0]:=0X;
    ELSIF name="KEY_NPAGE" THEN
      e.key:=E.next;
      e.text[0]:=0X;
    ELSIF name="KEY_HOME" THEN
      e.key:=E.home;
      e.text[0]:=0X;
    ELSIF name="KEY_END" THEN
      e.key:=E.end;
      e.text[0]:=0X;
    ELSIF name="KEY_DC" THEN
      e.key:=E.delete;
      e.text[0]:=0X;
    ELSIF name="KEY_IC" THEN
      e.key:=E.insert;
      e.text[0]:=0X;
    ELSIF name="KEY_UP" THEN
      e.key:=E.up;
      e.text[0]:=0X;
    ELSIF name="KEY_DOWN" THEN
      e.key:=E.down;
      e.text[0]:=0X;
    ELSIF name="KEY_LEFT" THEN
      e.key:=E.left;
      e.text[0]:=0X;
    ELSIF name="KEY_RIGHT" THEN
      e.key:=E.right;
      e.text[0]:=0X;
    ELSIF name="KEY_BACKSPACE" THEN
      e.key:=E.backspace;
      e.text[0]:=Ascii.bs;
    ELSIF name="KEY_BTAB" THEN
      e.key:=E.leftTab;
      e.text[0]:=0X;
    ELSIF name="KEY_F(1)" THEN
      e.key:=E.f1;
      e.text[0]:=0X;
    ELSIF name="KEY_F(2)" THEN
      e.key:=E.f2;
      e.text[0]:=0X;
    ELSIF name="KEY_F(3)" THEN
      e.key:=E.f3;
      e.text[0]:=0X;
    ELSIF name="KEY_F(4)" THEN
      e.key:=E.f4;
      e.text[0]:=0X;
    ELSIF name="KEY_F(5)" THEN
      e.key:=E.f5;
      e.text[0]:=0X;
    ELSIF name="KEY_F(6)" THEN
      e.key:=E.f6;
      e.text[0]:=0X;
    ELSIF name="KEY_F(7)" THEN
      e.key:=E.f7;
      e.text[0]:=0X;
    ELSIF name="KEY_F(8)" THEN
      e.key:=E.f8;
      e.text[0]:=0X;
    ELSIF name="KEY_F(9)" THEN
      e.key:=E.f9;
      e.text[0]:=0X;
    ELSIF name="KEY_F(10)" THEN
      e.key:=E.f10;
      e.text[0]:=0X;
    ELSIF name="KEY_F(11)" THEN
      e.key:=E.f11;
      e.text[0]:=0X;
    ELSIF name="KEY_F(12)" THEN
      e.key:=E.f12;
      e.text[0]:=0X;
    ELSIF name="^I" THEN
      e.key:=E.tab;
    ELSIF name=" " THEN
      e.key:=E.space;
    ELSIF (name[0]="M") & (name[1]="-") THEN
      e.qualifier:=e.qualifier+E.altMask;
    ELSE
      e.key:=-ORD(e.text[0]);
      IF (name[0]="^") THEN
        Strings.Delete(name,0,1);
        e.qualifier:=e.qualifier+E.controlMask;
      END;

      IF ls.IsLetter(e.text[0]) & ls.IsUpper(e.text[0]) THEN
        e.qualifier:=e.qualifier+E.shiftMask;
      END;
    END;

(*    Err.String(name); Err.Ln;*)
  END SetCursesEvent;

  PROCEDURE (e : KeyEvent) GetName*(VAR buffer : ARRAY OF CHAR);
  (**
    Returns a string representing the name of key(s) pressed.
   *)

  BEGIN
    IF ~E.GetKeyName(e.key,buffer) THEN
      (*      COPY(e.text^,buffer);*)
      e.window.GetEventName(e.event,buffer);
      IF (buffer[0]="^") THEN
        Strings.Delete(buffer,0,1);
        buffer[0]:=CHR(ORD(buffer[0])+32);
      ELSIF (buffer[0]="M") & (buffer[1]="-") THEN
        Strings.Delete(buffer,0,2);
      END;
    END;

    (*Err.String("KeyName: ");
    Err.String(buffer);
    Err.Ln;*)
  END GetName;

  PROCEDURE (e : ButtonEvent) SetCursesEvent(event : Curses.Event;
                                             window : Curses.Window);

  VAR
    mouseEvent : Curses.MouseEventDesc;

  BEGIN
    e.event:=event;

    window.ConvertToMouseEvent(event,mouseEvent);

    IF mouseEvent.mode=Curses.modePress THEN
      e.type:=E.mouseDown;
    ELSIF mouseEvent.mode=Curses.modeRelease THEN
      e.type:=E.mouseUp;
    ELSE
      e.type:=-1;
    END;

    e.x:=mouseEvent.x;
    e.y:=mouseEvent.y;

(*    IF Curses.modifierShift IN

    e.qualifier:=EvaluateQualifier(event.state);
*)
    CASE mouseEvent.button OF
      Curses.button1 : e.button:=E.button1;
    | Curses.button2 : e.button:=E.button2;
    | Curses.button3 : e.button:=E.button3;
    | Curses.button4 : e.button:=E.button4;
    ELSE
      e.button:=E.unknown;
    END;
  END SetCursesEvent;

  PROCEDURE GetEvent*(event : Curses.Event;
                      window : Curses.Window;
                      meta : BOOLEAN):E.Event;
  (**
    Convert the given Curses event to a VisualOberon event.
  *)

  BEGIN
    IF window.IsMouseEvent(event) THEN
      buttonEvent.SetCursesEvent(event,window);
      RETURN buttonEvent;
    ELSIF window.IsKeyEvent(event) THEN
      keyEvent.SetCursesEvent(event,window,meta);
      RETURN keyEvent;
    ELSE
      simpleEvent.event:=event;
      RETURN simpleEvent;
    END;
  END GetEvent;

BEGIN
  NEW(simpleEvent);
  NEW(keyEvent);
  NEW(keyEvent.text,256);
  NEW(buttonEvent);
(*  NEW(motionEvent);*)
END VO:OS:Curses:Event.