MODULE VO:OS:Windows:Event;

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

IMPORT
  E := VO:Base:Event,
  W := Windows,
  S := SYSTEM, Log;

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
                      event  : W.MSG;
                    END;

  KeyEvent*       = POINTER TO KeyEventDesc;
  KeyEventDesc*   = RECORD (E.KeyEventDesc)
  (**
    Keyboard event. The application receives this event when a key
    has been pressed or raised.
  *)
                      event  : W.MSG;
                    END;

  ButtonEvent*    = POINTER TO ButtonEventDesc;
  ButtonEventDesc* = RECORD (E.ButtonEventDesc)
  (**
    Mouse event. The application recieves this event when one or
    more mousebuttons have been pressed or released. You'll also
    get events when the mouse moves.
  *)
                       event : W.MSG;
                     END;

  MotionEvent*    = POINTER TO MotionEventDesc;
  MotionEventDesc* = RECORD (E.MotionEventDesc)
  (**
    Mouse event. The application recieves this event when one or
    more mousebuttons have been pressed or released. You'll also
    get events when the mouse moves.
  *)
                       event  : W.MSG;
                     END;

  (* keyboard state array *)

  KeyState = ARRAY 256 OF W.BYTE;

VAR
  simpleEvent : Event;
  buttonEvent : ButtonEvent;
  motionEvent : MotionEvent;
  keyEvent    : KeyEvent;

  PROCEDURE EvaluateMouseQualifier(state : LONGINT):SET;
  VAR
    qualifier : SET;

    PROCEDURE ToSet(mask : LONGINT) : SET;
    BEGIN
      RETURN S.VAL(SET, mask);
    END ToSet;

  BEGIN
    qualifier:={};

    IF S.VAL(SET,state)*ToSet(W.MK_SHIFT)#{} THEN
      qualifier:=qualifier+E.shiftMask;
    END;

    IF S.VAL(SET,state)*ToSet(W.MK_CONTROL)#{} THEN
      qualifier:=qualifier+E.controlMask;
    END;

    IF S.VAL(SET,state)*ToSet(W.MK_LBUTTON)#{} THEN
      INCL(qualifier,E.button1);
    END;

    IF S.VAL(SET,state)*ToSet(W.MK_MBUTTON)#{} THEN
      INCL(qualifier,E.button2);
    END;

    IF S.VAL(SET,state)*ToSet(W.MK_RBUTTON)#{} THEN
      INCL(qualifier,E.button3);
    END;

    RETURN qualifier;
  END EvaluateMouseQualifier;

  PROCEDURE EvaluateKeyQualifier(VAR state : KeyState):SET;
  VAR
    qualifier : SET;

  BEGIN
    qualifier:={};

    IF ORD(state[W.VK_LSHIFT]) > 1 THEN
      INCL(qualifier, E.qShiftLeft);
    END;

    IF ORD(state[W.VK_RSHIFT]) > 1 THEN
      INCL(qualifier, E.qShiftRight);
    END;

    IF ORD(state[W.VK_LCONTROL]) > 1 THEN
      INCL(qualifier, E.qControlLeft);
    END;

    IF ORD(state[W.VK_RCONTROL]) > 1 THEN
      INCL(qualifier, E.qControlRight);
    END;

    IF ORD(state[W.VK_LMENU]) > 1 THEN
      INCL(qualifier, E.qAltLeft);
    END;

    IF ORD(state[W.VK_RMENU]) > 1 THEN
      INCL(qualifier, E.qAltRight);
    END;

    IF ORD(state[W.VK_LBUTTON]) > 1 THEN
      INCL(qualifier,E.button1);
    END;

    IF ORD(state[W.VK_MBUTTON]) > 1 THEN
      INCL(qualifier,E.button2);
    END;

    IF ORD(state[W.VK_RBUTTON]) > 1 THEN
      INCL(qualifier,E.button3);
    END;

    RETURN qualifier;
  END EvaluateKeyQualifier;


  PROCEDURE TranslateKey(key : LONGINT; qualifier : SET) : LONGINT;
  BEGIN
    CASE key OF
    (* Editing *)
    | W.VK_BACK:    RETURN E.backspace;
    | W.VK_DELETE:  RETURN E.delete;

    (* Advanced editing *)
    | W.VK_RETURN:  RETURN E.return;

    (* Movement *)
    | W.VK_HOME:    RETURN E.home;
    | W.VK_END:     RETURN E.end;
    | W.VK_LEFT:    RETURN E.left;
    | W.VK_RIGHT:   RETURN E.right;
    | W.VK_UP:      RETURN E.up;
    | W.VK_DOWN:    RETURN E.down;
    | W.VK_PRIOR:   RETURN E.prior;
    | W.VK_NEXT:    RETURN E.next;

    (* Special keys *)
    | W.VK_TAB:
      IF qualifier * E.shiftMask # {} THEN
        RETURN E.leftTab
      ELSE
        RETURN E.tab
      END;
    | W.VK_SPACE:   RETURN E.space;
    | W.VK_ESCAPE:  RETURN E.escape;
    | W.VK_PRINT:   RETURN E.print;
    | W.VK_INSERT:  RETURN E.insert;

    (* Function keys *)
    | W.VK_F1:      RETURN E.f1;
    | W.VK_F2:      RETURN E.f2;
    | W.VK_F3:      RETURN E.f3;
    | W.VK_F4:      RETURN E.f4;
    | W.VK_F5:      RETURN E.f5;
    | W.VK_F6:      RETURN E.f6;
    | W.VK_F7:      RETURN E.f7;
    | W.VK_F8:      RETURN E.f8;
    | W.VK_F9:      RETURN E.f9;
    | W.VK_F10:     RETURN E.f10;
    | W.VK_F11:     RETURN E.f11;
    | W.VK_F12:     RETURN E.f12;
    ELSE
      RETURN E.unknown;
    END;
  END TranslateKey;

  PROCEDURE (e : KeyEvent) SetWin32Event*(event : W.MSG);
  VAR
    res  : LONGINT;
    keys : KeyState;
    word : W.WORD;
  BEGIN
    e.event:=event;

    IF (event.message=W.WM_KEYDOWN) OR (e.event.message=W.WM_SYSKEYDOWN) THEN
      e.type:=E.keyDown;
    ELSE
      e.type:=E.keyUp;
    END;
    IF W.GetKeyboardState(S.VAL(W.PBYTE,S.ADR(keys)))#0 THEN END;
    res:=W.ToAscii(e.event.wParam,(e.event.lParam DIV 65536) MOD 2048,S.VAL(W.PBYTE,S.ADR(keys)),word, 0);
    IF res > 0 THEN
      e.text[0] := CHR(word MOD 256);
      IF res > 1 THEN
        e.text[1] := CHR(word DIV 256);
      END;
      e.text[res] := 0X;
    ELSE
      e.text[0] := 0X;
    END;
    e.textLength := res;

    e.qualifier := EvaluateKeyQualifier(keys);
    e.key := TranslateKey(e.event.wParam, e.qualifier);
(*
    Log.Set("Qualifier", e.qualifier);
    Log.LongInt("Key", e.key);
    Log.LongInt("Text", ORD(e.text[0])); *)
(*
    IF e.key # E.unknown THEN
      e.textLength := 0;
    END;
*)
  END SetWin32Event;

  PROCEDURE (e : KeyEvent) GetName*(VAR buffer : ARRAY OF CHAR);
  (**
    Returns a string representing the name of key(s) pressed.
   *)

  BEGIN
    IF ~E.GetKeyName(e.key,buffer) THEN
      buffer[0]:=0X;

      IF W.GetKeyNameTextA(e.event.lParam,S.VAL(W.LPTSTR,S.ADR(buffer)),LEN(buffer))#0 THEN
      END;
      (* convert single letters to lower case *)
      IF (buffer[0] >= 'A') & (buffer[0] <= 'Z') & (buffer[1] = 0X) THEN
        buffer[0] := CHR(ORD(buffer[0])-ORD('A')+ORD('a'));
      END;
    END;
  END GetName;

  PROCEDURE (e : ButtonEvent) SetWin32Event*(event : W.MSG);

  BEGIN
    e.event:=event;
    e.qualifier:=EvaluateMouseQualifier(event.wParam);

    CASE event.message OF
      W.WM_LBUTTONDOWN:
        e.type:=E.mouseDown;
        e.button:=E.button1;
        EXCL(e.qualifier,E.button1);
    | W.WM_LBUTTONUP:
        e.type:=E.mouseUp;
        e.button:=E.button1;
    | W.WM_MBUTTONDOWN:
        e.type:=E.mouseDown;
        e.button:=E.button2;
        EXCL(e.qualifier,E.button2);
    | W.WM_MBUTTONUP:
        e.type:=E.mouseUp;
        e.button:=E.button2;
    | W.WM_RBUTTONDOWN:
        e.type:=E.mouseDown;
        e.button:=E.button3;
        EXCL(e.qualifier,E.button3);
    | W.WM_RBUTTONUP:
        e.type:=E.mouseUp;
        e.button:=E.button3;
    ELSE
      e.button:=E.unknown;
    END;

    e.x:=event.lParam MOD (256*256);
    e.y:=event.lParam DIV (256*256);
  END SetWin32Event;

  (**
    NOTE
      THis as a VODisplay-only access-method for initializing the MouseEvent.
      Do not call this method in your code, it is VODisplay only and does only
      exists on X11 implementations of VisualOberon.
  **)

  PROCEDURE (e : MotionEvent) SetWin32Event*(event : W.MSG);

  BEGIN
    e.event:=event;

    e.x:=event.lParam MOD (256*256);
    e.y:=event.lParam DIV (256*256);

    e.qualifier:=EvaluateMouseQualifier(event.wParam);
  END SetWin32Event;

  PROCEDURE GetEvent*(event : W.MSG):E.Event;

  BEGIN
    CASE event.message OF
      W.WM_LBUTTONDOWN,
      W.WM_LBUTTONUP,
      W.WM_MBUTTONDOWN,
      W.WM_MBUTTONUP,
      W.WM_RBUTTONDOWN,
      W.WM_RBUTTONUP:
        buttonEvent.SetWin32Event(event);
        RETURN buttonEvent;
    | W.WM_MOUSEMOVE:
        motionEvent.SetWin32Event(event);
        RETURN motionEvent;
    | W.WM_KEYDOWN, W.WM_SYSKEYDOWN,
      W.WM_KEYUP, W.WM_SYSKEYUP:
        keyEvent.SetWin32Event(event);
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
  NEW(motionEvent);
END VO:OS:Windows:Event.
