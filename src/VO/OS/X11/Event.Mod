MODULE VO:OS:X11:Event;

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

IMPORT       C,

       E  := VO:Base:Event,

             X11:X11,
       xk := X11:Xkeysymdef,
       xu := X11:Xutil;

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
                      event  : X11.XEvent;
                    END;

  KeyEvent*       = POINTER TO KeyEventDesc;
  KeyEventDesc*   = RECORD (E.KeyEventDesc)
  (**
    Keyboard event. The application receives this event when a key
    has been pressed or raised.
  *)
                      event  : X11.XEvent;
                      xKey   : LONGINT;
                    END;

  ButtonEvent*    = POINTER TO ButtonEventDesc;
  ButtonEventDesc* = RECORD (E.ButtonEventDesc)
  (**
    Mouse event. The application recieves this event when one or
    more mousebuttons have been pressed or released. You'll also
    get events when the mouse moves.
  *)
                       event  : X11.XEvent;
                     END;

  MotionEvent*    = POINTER TO MotionEventDesc;
  MotionEventDesc* = RECORD (E.MotionEventDesc)
  (**
    Mouse event. The application recieves this event when one or
    more mousebuttons have been pressed or released. You'll also
    get events when the mouse moves.
  *)
                       event  : X11.XEvent;
                     END;

VAR
  simpleEvent : Event;
  buttonEvent : ButtonEvent;
  motionEvent : MotionEvent;
  keyEvent    : KeyEvent;

  compose     : xu.XComposeStatus;

  PROCEDURE EvaluateQualifier(state : X11.uintmask):SET;
  (**
    Convert the given X11 qualifier description to a VisualOberon
    qualifier description.
  *)

  VAR
    qualifier : SET;

  BEGIN
    qualifier:={};
    IF state*X11.ShiftMask#{} THEN
      qualifier:=qualifier+E.shiftMask;
    END;
    IF state*X11.LockMask#{} THEN
      INCL(qualifier,E.qCapsLock);
    END;
    IF state*X11.ControlMask#{} THEN
      qualifier:=qualifier+E.controlMask;
    END;

    IF state*X11.Mod1Mask#{} THEN
      qualifier:=qualifier+E.altMask;
    END;

(*    IF state*X11.Mod2Mask#{} THEN
(*      Err.String("MOD2 "); Err.Set(state); Err.Char(" "); Err.Set(X11.Mod2Mask); Err.Ln;*)
      qualifier:=qualifier+E.altMask;
    END;*)

(*    IF state*X11.Mod3Mask#{} THEN (* this seems to be AltGr *)
      Err.String("MOD3 ");
      qualifier:=qualifier+E.altMask;
    END;

    IF state*X11.Mod4Mask#{} THEN (* THis is the left windows key! *)
      Err.String("MOD4 ");
      qualifier:=qualifier+E.altMask;
    END;

    IF state*X11.Mod5Mask#{} THEN
      Err.String("MOD5 ");
      qualifier:=qualifier+E.altMask;
    END;*)


    IF state*X11.Button1Mask#{} THEN
      INCL(qualifier,E.button1);
    END;
    IF state*X11.Button2Mask#{} THEN
      INCL(qualifier,E.button2);
    END;
    IF state*X11.Button3Mask#{} THEN
      INCL(qualifier,E.button3);
    END;
    IF state*X11.Button4Mask#{} THEN
      INCL(qualifier,E.button4);
    END;
    IF state*X11.Button5Mask#{} THEN
      INCL(qualifier,E.button5);
    END;
    RETURN qualifier;
  END EvaluateQualifier;

  PROCEDURE (e : KeyEvent) SetX11Event(event : X11.XKeyEvent; xic : X11.XIC):BOOLEAN;
  (**
    NOTE
      THis as a VODisplay-only access-method for initializing the MouseEvent.
      Do not call this method in your code, it is VODisplay only and does only
      exists on X11 implementations of VisualOberon.
  *)

  VAR
    status : X11.Status;

  BEGIN
    e.event.xkey:=event;

    IF event.type=X11.KeyPress THEN
      e.type:=E.keyDown;
    ELSE
      e.type:=E.keyUp;
    END;

    e.qualifier:=EvaluateQualifier(event.state);

    IF event.type=X11.KeyPress THEN
      e.text[0]:=0X;
      e.xKey:=-1;
      e.textLength:=X11.XmbLookupString(xic,
                                        event,
                                        e.text^,
                                        LEN(e.text^)-1,
                                        e.xKey,
                                        status);

      IF status=X11.XLookupNone THEN
        RETURN FALSE;
      ELSIF status=X11.XBufferOverflow THEN
        RETURN FALSE;
      END;
    ELSE
      e.textLength:=xu.XLookupString(e.event.xkey,
                                     e.text^,LEN(e.text^)-1,
                                     e.xKey,
                                     compose);
      e.text[e.textLength]:=0X;
    END;

    CASE e.xKey OF
    | xk.XK_Return:
      e.key:=E.return;
    | xk.XK_ISO_Left_Tab:
      e.key:=E.leftTab;
    | xk.XK_Tab:
      e.key:=E.tab;
    | xk.XK_space:
      e.key:=E.space;
    | xk.XK_BackSpace:
      e.key:=E.backspace;
    | xk.XK_Escape:
      e.key:=E.escape;
    | xk.XK_F5:
      e.key:=E.f5;
    | xk.XK_F6:
      e.key:=E.f6;
    | xk.XK_F7:
      e.key:=E.f7;
    | xk.XK_F3:
      e.key:=E.f3;
    | xk.XK_F8:
      e.key:=E.f8;
    | xk.XK_F9:
      e.key:=E.f9;
    | xk.XK_F11:
      e.key:=E.f11;
    | xk.XK_F10:
      e.key:=E.f10;
    | xk.XK_F12:
      e.key:=E.f12;
    | xk.XK_Home:
      e.key:=E.home;
    | xk.XK_Prior:
      e.key:=E.prior;
    | xk.XK_F4:
      e.key:=E.f4;
    | xk.XK_End:
      e.key:=E.end;
    | xk.XK_F2:
      e.key:=E.f2;
    | xk.XK_Next:
      e.key:=E.next;
    | xk.XK_F1:
      e.key:=E.f1;
    | xk.XK_Left:
      e.key:=E.left;
    | xk.XK_Right:
      e.key:=E.right;
    | xk.XK_Down:
      e.key:=E.down;
    | xk.XK_Up:
      e.key:=E.up;
    | xk.XK_Delete:
      e.key:=E.delete;
    | xk.XK_Print:
      e.key:=E.print;
    | xk.XK_Insert:
      e.key:=E.insert;
    | xk.XK_Shift_L:
      e.key:=E.shiftLeft;
    | xk.XK_Shift_R:
      e.key:=E.shiftRight;
    | xk.XK_Shift_Lock:
      e.key:=E.shiftLock;
    | xk.XK_Caps_Lock:
      e.key:=E.capsLock;
    | xk.XK_Scroll_Lock:
      e.key:=E.scrollLock;
    | xk.XK_Num_Lock:
      e.key:=E.numLock;
    | xk.XK_Control_L:
      e.key:=E.controlLeft;
    | xk.XK_Control_R:
      e.key:=E.controlRight;
    | xk.XK_Alt_L:
      e.key:=E.altLeft;
    | xk.XK_Alt_R:
      e.key:=E.altRight;
    | xk.XK_Meta_L:
      e.key:=E.metaLeft;
    | xk.XK_Meta_R:
      e.key:=E.metaRight;
    | xk.XK_Super_L:
      e.key:=E.superLeft;
    | xk.XK_Super_R:
      e.key:=E.superRight;
    | xk.XK_Hyper_L:
      e.key:=E.hyperLeft;
    | xk.XK_Hyper_R:
      e.key:=E.hyperRight;
    ELSE
      (*Err.String("unknown keycode: "); Err.Hex(e.key,0); Err.Ln;*)
      e.key:=E.unknown;
    END;

    RETURN TRUE;
  END SetX11Event;

  PROCEDURE (e : KeyEvent) GetName*(VAR buffer : ARRAY OF CHAR);
  (**
    Returns a string representing the name of key(s) pressed.
   *)

  VAR
    count  : LONGINT;
    string : C.string;

  BEGIN
    IF ~E.GetKeyName(e.xKey,buffer) THEN
      buffer[0]:=0X;
      string:=X11.XKeysymToString(e.xKey);
      IF string#NIL THEN
        count:=0;
        WHILE (string[count]#0X) & (count<LEN(buffer)-1) DO
          buffer[count]:=string[count];
          INC(count);
        END;
        buffer[count]:=0X;
      END;
    END;
  END GetName;

  PROCEDURE (e : ButtonEvent) SetX11Event(event : X11.XButtonEvent);
  (**
    NOTE
      THis as a VODisplay-only access-method for initializing the MouseEvent.
      Do not call this method in your code, it is VODisplay only and does only
      exists on X11 implementations of VisualOberon.
  *)

  BEGIN
    e.event.xbutton:=event;

    IF event.type=X11.ButtonPress THEN
      e.type:=E.mouseDown;
    ELSE
      e.type:=E.mouseUp;
    END;

    e.x:=event.x;
    e.y:=event.y;

    e.qualifier:=EvaluateQualifier(event.state);

    CASE event.button OF
      X11.Button1 : e.button:=E.button1;
    | X11.Button2 : e.button:=E.button2;
    | X11.Button3 : e.button:=E.button3;
    | X11.Button4 : e.button:=E.button4;
    | X11.Button5 : e.button:=E.button5;
    ELSE
      e.button:=E.unknown;
    END;
  END SetX11Event;

  PROCEDURE (e : MotionEvent) SetX11Event(event : X11.XMotionEvent);
  (**
    NOTE
      THis as a VODisplay-only access-method for initializing the MouseEvent.
      Do not call this method in your code, it is VODisplay only and does only
      exists on X11 implementations of VisualOberon.
  *)

  BEGIN
    e.event.xmotion:=event;

    IF event.is_hint#0X THEN
      IF X11.XQueryPointer(event.display,event.window,event.root,event.subwindow,
                           event.x_root,event.y_root,event.x,event.y,event.state)=0 THEN END;
    END;

    e.x:=event.x;
    e.y:=event.y;
    e.qualifier:=EvaluateQualifier(event.state);
  END SetX11Event;

  PROCEDURE GetEvent*(event : X11.XEvent; xic : X11.XIC):E.Event;
  (**
    Convert the given X11 event to a VisualOberon event.
  *)

  BEGIN
    CASE event.type OF
      X11.ButtonPress,
      X11.ButtonRelease:
        buttonEvent.SetX11Event(event.xbutton);
        RETURN buttonEvent;
    | X11.MotionNotify:
        motionEvent.SetX11Event(event.xmotion);
        RETURN motionEvent;
    | X11.KeyPress,
      X11.KeyRelease:
        IF keyEvent.SetX11Event(event.xkey,xic) THEN
          RETURN keyEvent;
        ELSE
          RETURN NIL;
        END;
    ELSE
      simpleEvent.event:=event;
      RETURN simpleEvent;
    END;
  END GetEvent;

  PROCEDURE GetX11Event*(event : E.Event; VAR x11Event : X11.XEvent);

  BEGIN
    WITH
      event : ButtonEvent DO
        x11Event:=event.event;
    | event : MotionEvent DO
        x11Event:=event.event;
    | event : KeyEvent DO
        x11Event:=event.event;
    | event : Event DO
        x11Event:=event.event;
    END;
  END GetX11Event;

BEGIN
  NEW(simpleEvent);
  NEW(keyEvent);
  NEW(keyEvent.text,256);
  NEW(buttonEvent);
  NEW(motionEvent);
END VO:OS:X11:Event.
