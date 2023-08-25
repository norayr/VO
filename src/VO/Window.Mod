MODULE VO:Window;

  (**
    Implements a window that contains one instance @otype{G.Object}. Instances
    of this class will likely used for most "normal" and "popup" window
    within you rapplication. If you want the window to hold a more complex
    scenario than just one instance of @otype{G.Object} just use a container
    object to hold them.

    @otype{Window} also support focus handling and other high level features.
  *)

  (*
    Windows.
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

IMPORT D   := VO:Base:Display,
       E   := VO:Base:Event,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,
       U   := VO:Base:Util,

       P   := VO:Prefs:Base,
       FG  := VO:FrameGroup,
       G   := VO:Object,

              Object;

CONST
  (* various messages *)

  openMsg*      = 0;
  openModalMsg* = 1;
  closeMsg*     = 2;
  exitMsg*      = 3;
  shortcutMsg*  = 4;

  shortcutPressed*  = 0;
  shortcutReleased* = 1;
  shortcutCanceled* = 2;

  (* Constants for @code{Window.GetPosObject} *)

  menuGadget = 0; (** Each Object can have its private context-sensitive menu       *)
  helpGadget = 1; (** Each Object can have its private context-sensitive helpobject *)
  dragGadget = 2; (** An object you can drag data from *)

TYPE
  Shortcut         = POINTER TO ShortcutDesc;
  ShortcutDesc     = RECORD
                       (**
                         Store one shortcut entry.
                       *)
                        next      : Shortcut;    (** Pointer to next Shortcut *)
                        object    : G.Object;    (** The object that owns the shortcodes *)
                        qualifier : SET;         (** Qualifier to be matched *)
                        key       : STRING;      (** Character to be matched *)
                        id        : LONGINT;     (** Id of the shortcode *)
                        target    : O.MsgObject; (** The target of the shortcut message *)
                      END;

  Window*          = POINTER TO WindowDesc;

  KeyHandler       = POINTER TO KeyHandlerDesc;
  KeyHandlerDesc   = RECORD
                       window     : Window;
                       current    : G.Gadget; (** Current object having focus *)

                       sFirst,                   (** List of shortcuts *)
                       sLast,
                       sCurrent   : Shortcut;
                     END;

  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (P.PrefsDesc)
                 frame* : F.Frame; (** the frame to use for the window *)
               END;

  WindowDesc*   = RECORD (D.WindowDesc)
                    prefs      : Prefs;         (** Window preferences object *)
                    top-       : G.Object;      (** The top most object *)
                    current    : G.Object;      (** Object currently holding mouse event focus *)
                    reference  : G.Object;      (** If set, object the window should open relativ to *)
                    keyHandler : KeyHandler;    (** Instance of key handler *)
                    frame      : FG.FrameGroup; (** Top object *)
                  END;

  OpenMsg*        = POINTER TO OpenMsgDesc;
  OpenMsgDesc*    = RECORD (O.MessageDesc)
                      (** Send this message to a window to open it non-modal *)
                    END;

  OpenModalMsg*     = POINTER TO OpenModalMsgDesc;
  OpenModalMsgDesc* = RECORD (O.MessageDesc)
                        (** Send this message to a window to open it modal *)
                      END;

  CloseMsg*       = POINTER TO CloseMsgDesc;
  CloseMsgDesc*   = RECORD (O.MessageDesc)
                      (** Send this message to a window to close it *)
                    END;

  ExitMsg*        = POINTER TO ExitMsgDesc;
  ExitMsgDesc*    = RECORD (O.MessageDesc)
                      (**
                        Send this message to a window to close it and leave
                        the modal event loop
                      *)
                    END;

  ShortcutMsg*    = POINTER TO ShortcutMsgDesc;
  ShortcutMsgDesc*= RECORD (O.MessageDesc)
                      (**
                        This message will be send to the defined target,
                        if a registered short was triggered.
                      *)
                      object- : G.Object; (** The gadget the shortcode was registered for *)
                      id-     : LONGINT;  (** The id of the shortcode *)
                      state-  : LONGINT;  (** The shortcut state *)
                    END;

  (* Some messagehandler *)

  Msg2Open*       = POINTER TO Msg2OpenDesc;
  Msg2OpenDesc*   = RECORD (O.HandlerDesc)
                    END;

  Msg2OpenModal*     = POINTER TO Msg2OpenModalDesc;
  Msg2OpenModalDesc* = RECORD (O.HandlerDesc)
                       END;

  Msg2Close*      = POINTER TO Msg2CloseDesc;
  Msg2CloseDesc*  = RECORD (O.HandlerDesc)
                    END;

  Msg2Exit*      = POINTER TO Msg2ExitDesc;
  Msg2ExitDesc*  = RECORD (O.HandlerDesc)
                   END;

  GetPosVisitorDesc = RECORD (G.VisitorDesc)
                        x,y,type : LONGINT;
                        object   : G.Object;
                      END;

VAR
  prefs* : Prefs;

  PROCEDURE (k : KeyHandler) Init;

  BEGIN
    k.current:=NIL;

    k.sFirst:=NIL;
    k.sLast:=NIL;
    k.sCurrent:=NIL;
  END Init;

  PROCEDURE (k : KeyHandler) SetFocus(gadget : G.Gadget);

  BEGIN
    IF k.current=gadget THEN
      RETURN;
    END;

    IF k.current#NIL THEN
      k.current.LostFocus;
    END;

    k.current:=gadget;
    IF k.current#NIL THEN
      k.current.CatchedFocus;
    END;
  END SetFocus;

  PROCEDURE (k : KeyHandler) GetCurrentFocusGadget():G.Gadget;

  BEGIN
    RETURN k.current;
  END GetCurrentFocusGadget;

  PROCEDURE (k : KeyHandler) SetFocusFirst();

  VAR
    object : G.Object;

  BEGIN
    object:=k.window.top.GetFocusFirst();
    IF object#NIL THEN
      k.SetFocus(object(G.Gadget));
    ELSE
      k.SetFocus(NIL);
    END;
  END SetFocusFirst;

  PROCEDURE (k : KeyHandler) SetFocusNext();

  VAR
    object : G.Object;

  BEGIN
    IF k.current#NIL THEN
      object:=k.current.GetFocusNext(k.current);

      IF object#NIL THEN
        k.SetFocus(object(G.Gadget));
        RETURN;
      END;
    END;

    object:=k.window.top.GetFocusFirst();
    IF object#NIL THEN
      k.SetFocus(object(G.Gadget));
    ELSE
      k.SetFocus(NIL);
    END;
  END SetFocusNext;

  PROCEDURE (k : KeyHandler) SetFocusLast();

  VAR
    object : G.Object;

  BEGIN
    IF k.current#NIL THEN
      object:=k.current.GetFocusPrevious(k.current);

      IF object#NIL THEN
        k.SetFocus(object(G.Gadget));
        RETURN;
      END;
    END;

    object:=k.window.top.GetFocusFirst();
    IF object#NIL THEN
      k.SetFocus(object(G.Gadget));
    ELSE
      k.SetFocus(NIL);
    END;
  END SetFocusLast;

  PROCEDURE (k : KeyHandler) SetFocusNextInGroup();

  BEGIN
  END SetFocusNextInGroup;

  PROCEDURE (k : KeyHandler) SetFocusLastInGroup();

  BEGIN
  END SetFocusLastInGroup;

  PROCEDURE (k : KeyHandler) Activate;

  BEGIN
    IF k.current#NIL THEN
      k.current.RecatchedFocus;
    ELSE
      k.SetFocusFirst;
    END;
  END Activate;

  PROCEDURE (k : KeyHandler) Deactivate;

  BEGIN
    IF k.current#NIL THEN
      k.current.LostFocus;
    END;
  END Deactivate;

  PROCEDURE (k : KeyHandler) AddShortcut(object : G.Object;
                                         qualifier : SET;
                                         key : STRING;
                                         id : LONGINT;
                                         target : O.MsgObject);
  (**
    Adds a shortcut with the given @oparam{qualifier} and character for
    @oparam{object}. An object must be visible to get notified, so shortcuts
    can be shared as long as only one object at the time is visible.

    If a shortcut gets triggered, a @otype{ShortcutMsgDesc} will be send to
    @oparam{target} or @oparam{object}, if @oparam{target} is @code{NIL}.
  *)

  VAR
    entry : Shortcut;

  BEGIN
    NEW(entry);
    entry.next:=NIL;
    entry.qualifier:=qualifier;
    entry.object:=object;
    entry.key:=key;
    entry.id:=id;
    entry.target:=target;

    IF k.sLast#NIL THEN
      k.sLast.next:=entry;
    ELSE
      k.sFirst:=entry;
    END;
    k.sLast:=entry;
  END AddShortcut;

  PROCEDURE (sc : Shortcut) Match(event : E.KeyEvent):BOOLEAN;

  (**
    Checks if the given shortcut entry matches the given key.
  *)

  VAR
    found     : BOOLEAN;
    buffer    : ARRAY 256 OF CHAR;
    text,
    key       : STRING;
    qualifier : SET;

  BEGIN
    event.GetName(buffer);
    key:=Object.NewLatin1(buffer);
    text:=Object.NewLatin1(event.text^);

    qualifier:=event.qualifier-E.shiftMask;

    found:=FALSE;
    IF (((sc.qualifier={}) & (qualifier={})) OR (sc.qualifier*qualifier#{}))
      & (sc.key.EqualsIgnoreCase(key)  OR sc.key.Equals(text)) THEN
      found:=TRUE;
    END;

    RETURN found & ((sc.object.visible) OR (G.scAlways IN sc.object.flags));
  END Match;

  PROCEDURE (k : KeyHandler) GetSCEntry(event : E.KeyEvent):Shortcut;

  (**
    Returns the shortcut matching or NIL.
  *)

  VAR
    sc        : Shortcut;
    found     : BOOLEAN;
    buffer    : ARRAY 256 OF CHAR;
    text,
    key       : STRING;
    qualifier : SET;

  BEGIN
    found:=FALSE;
    sc:=k.sFirst;

    event.GetName(buffer);
    key:=Object.NewLatin1(buffer);
    text:=Object.NewLatin1(event.text^);


    qualifier:=event.qualifier-E.shiftMask;
    WHILE sc#NIL DO
      IF (((sc.qualifier={}) & (qualifier={})) OR (sc.qualifier*qualifier#{}))
        & (sc.key.EqualsIgnoreCase(key) OR sc.key.Equals(text)) THEN
        found:=TRUE;
      END;

      IF found & ((sc.object.visible) OR (G.scAlways IN sc.object.flags)) THEN
        RETURN sc;
      ELSE
        found:=FALSE;
        sc:=sc.next;
      END;
    END;

    RETURN NIL;
  END GetSCEntry;

  PROCEDURE (k : KeyHandler) CreateShortcutMsg(object : G.Object;
                                               id, state : LONGINT;
                                               target : O.MsgObject);

  VAR
    msg : ShortcutMsg;

  BEGIN
    NEW(msg);
    msg.object:=object;
    msg.id:=id;
    msg.state:=state;
    IF target#NIL THEN
      target.Receive(msg);
    ELSE
      object.Receive(msg);
    END;
  END CreateShortcutMsg;

  PROCEDURE (k : KeyHandler) CancelCurrent;

  BEGIN
    IF k.sCurrent#NIL THEN
      k.CreateShortcutMsg(k.sCurrent.object,k.sCurrent.id,
                          shortcutCanceled,k.sCurrent.target);
    END;
    k.sCurrent:=NIL;
  END CancelCurrent;

  PROCEDURE (k : KeyHandler) HandleEvent(event : E.KeyEvent):BOOLEAN;

  VAR
    sc : Shortcut;

  BEGIN
    IF k.current#NIL THEN
      IF k.current.HandleKeyEvent(event) THEN
        RETURN TRUE;
      END;
    END;

    CASE event.type OF
      E.keyDown:
      sc:=k.GetSCEntry(event);

      IF sc#NIL THEN
        IF sc#k.sCurrent THEN
          k.CancelCurrent;
          k.sCurrent:=sc;
          k.CreateShortcutMsg(sc.object,sc.id,shortcutPressed,sc.target);
          RETURN TRUE;
        END;
      ELSE
        k.CancelCurrent;
      END;
    | E.keyUp:
      IF k.sCurrent#NIL THEN
        IF ~k.sCurrent.Match(event) THEN
          k.CancelCurrent;
        ELSE
          k.CreateShortcutMsg(k.sCurrent.object,k.sCurrent.id,
                              shortcutReleased,k.sCurrent.target);
          k.sCurrent:=NIL;
        END;
      END;
    END;

    IF event.type=E.keyDown THEN
      CASE event.key OF
        E.tab:
        IF event.qualifier={} THEN
          k.SetFocusNext;
          RETURN TRUE;
        END;
      | E.leftTab:
(*        IF event.qualifier*E.shiftMask # {} THEN*)
          k.SetFocusLast;
          RETURN TRUE;
(*        END;*)
      | E.left,E.up:
        IF event.qualifier={} THEN
          k.SetFocusLastInGroup;
          RETURN TRUE;
        END;
      | E.right,E.down:
        IF event.qualifier={} THEN
          k.SetFocusNextInGroup;
          RETURN TRUE;
        END;
      ELSE
      END;
    END;

    RETURN FALSE;
  END HandleEvent;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.none);
    ELSE
      p.frame:=F.CreateFrame(F.double3DOut);
    END;
  END Initialize;

  PROCEDURE (w : Window) Init*;

  BEGIN
    w.Init^;

    w.prefs:=prefs;

    w.top:=NIL;
    w.current:=NIL;
    NEW(w.keyHandler);
    w.keyHandler.Init;
    w.keyHandler.window:=w;
    w.frame:=NIL;
  END Init;

  PROCEDURE (w : Window) SetTop*(top : G.Object);

  (**
    Set the top object for this window.
  *)

  BEGIN
    w.top:=top;
  END SetTop;

  PROCEDURE (w : Window) SetReference*(reference : G.Object);

  BEGIN
    w.reference:=reference;
  END SetReference;

  PROCEDURE (w : Window) GetReference():G.Object;

  BEGIN
    RETURN w.reference;
  END GetReference;

  PROCEDURE (w : Window) RegisterShortcut*(object : G.Object;
                                           qualifier : SET;
                                           key : STRING;
                                           id : LONGINT;
                                           target : O.MsgObject);

  (**
    Adds a shortcut with the given qualifier and character for an object.
    Additional a special mode can be given for the shortcut whith states
    additional situations the shortcut get evaluated. An object must
    be visible to get notified, so shortcuts can be shared as long as
    only one object at the time is visible.
  *)

  BEGIN
    w.keyHandler.AddShortcut(object,qualifier,key,id,target);
  END RegisterShortcut;

  PROCEDURE (w : Window) RegisterCommitShortcut*(object : G.Object;
                                                 id : LONGINT;
                                                 target : O.MsgObject);

  (**
    Adds a "commit action" shortcut (that is normally mapped to @code{Return}.
    See @oproc{Window.RegisterShortcut}.
  *)

  BEGIN
    w.RegisterShortcut(object,{},"Return",id,target);
  END RegisterCommitShortcut;

  PROCEDURE (w : Window) RegisterCancelShortcut*(object : G.Object;
                                                 id : LONGINT;
                                                 target : O.MsgObject);

  (**
    Adds a "cancel action" shortcut (that is normally mapped to @code{Escape}.
    See @oproc{Window.RegisterShortcut}.
  *)

  BEGIN
    w.RegisterShortcut(object,{},"Escape",id,target);
  END RegisterCancelShortcut;

  PROCEDURE (w : Window) RegisterDefaultShortcut*(object : G.Object;
                                                  id : LONGINT;
                                                  target : O.MsgObject);

  (**
    Adds a "end action" shortcut (that is normally mapped to @code{Return}
    and @code{Escape}. See @oproc{Window.RegisterShortcut}.
  *)

  BEGIN
    w.RegisterShortcut(object,{},"Return",id,target);
    w.RegisterShortcut(object,{},"Escape",id,target);
  END RegisterDefaultShortcut;

  PROCEDURE (w : Window) CalcSize;

  BEGIN
    NEW(w.frame);
    w.frame.Init;

    CASE w.impl.type OF
      D.windowTypeMenu,
      D.windowTypePopup,
      D.windowTypeSplash:
      w.frame.SetFrame(w.prefs.frame);
    ELSE
      w.frame.SetFrame(F.CreateFrame(F.none)); (* Windowmanager does decoration *)
    END;

    w.frame.SetFlags({G.horizontalFlex,G.verticalFlex});
    w.frame.SetSpace(FALSE);
    w.frame.SetObject(w.top);
    w.frame.SetWindow(w);

    w.frame.CalcSize;
    IF (w.impl.type=D.windowTypePopup) & (w.reference#NIL) THEN
      (* Is is nice, when reference and popup have the same width *)
      w.frame.Resize(w.reference.oWidth,-1);
    END;
    w.SetSize(w.frame.oWidth,w.frame.oHeight);

    IF G.horizontalFlex IN w.top.flags THEN
      w.SetMinSize(w.frame.oMinWidth,-1);
      w.SetMaxSize(w.frame.oMaxWidth,-1);
    ELSE
      w.SetMinSize(w.GetWidth(),-1);
      w.SetMaxSize(w.GetWidth(),-1);
    END;
    IF G.verticalFlex IN w.top.flags THEN
      w.SetMinSize(-1,w.frame.oMinHeight);
      w.SetMaxSize(-1,w.frame.oMaxHeight);
    ELSE
      w.SetMinSize(-1,w.GetHeight());
      w.SetMaxSize(-1,w.GetHeight());
    END;
  END CalcSize;

  PROCEDURE (w : Window) PreInit*;

  (**
     Creates a window on the display with top as top object
     and with title as title.
  *)

  VAR
    parent : D.Window;
    x,y    : LONGINT;

  BEGIN
    w.CalcSize;

    IF (w.impl.type=D.windowTypePopup) & (w.reference#NIL) THEN
      parent:=w.reference.GetWindow();
      x:=parent.GetX();
      y:=parent.GetY();
      INC(x,w.reference.oX);
      INC(y,w.reference.oY+w.reference.oHeight);

      x:=U.RoundRange(x,0,D.display.scrWidth-1-w.GetWidth());
      y:=U.RoundRange(y,0,D.display.scrHeight-1-w.GetHeight());

      w.SetPos(x,y);
      w.SetPosition(D.manualPos,D.manualPos);
    END;

    w.PreInit^;
  END PreInit;

  PROCEDURE (w : Window) ReinitWindow*;

  VAR
    maped : BOOLEAN;

  BEGIN
    maped:=w.IsMaped();
    IF maped THEN
      w.top.Hide;
    END;

    w.CalcSize;

    w.Resize(w.frame.oWidth,w.frame.oHeight);

    IF w.IsMaped() THEN
      w.frame.Move(0,0);
      w.frame.Draw(0,0,w.GetWidth(),w.GetHeight());
      w.keyHandler.SetFocusFirst;
    ELSE
      w.frame.Resize(w.GetWidth(),w.GetHeight());
    END;
  END ReinitWindow;

  PROCEDURE (w : Window) Close*;

  BEGIN
    w.Close^;

    w.frame.Free;
  END Close;

  (* -- handler for some common windowevents -- *)

  PROCEDURE (w : Window) OnClosePressed*;

  VAR
    close : CloseMsg;

  BEGIN
    NEW(close);
    w.Send(close,closeMsg);
  END OnClosePressed;

  PROCEDURE (w : Window) OnUnmaped*;

  BEGIN
    w.OnUnmaped^;

    w.frame.Hide;
  END OnUnmaped;

  PROCEDURE (w : Window) OnFocusIn*;

  BEGIN
    w.OnFocusIn^;

    w.keyHandler.Activate;
  END OnFocusIn;

  PROCEDURE (w : Window) OnFocusOut*;

  BEGIN
    w.OnFocusOut^;

    w.keyHandler.Deactivate;

    CASE w.impl.type OF
      D.windowTypeMenu,
      D.windowTypePopup,
      D.windowTypeSplash:
      (* Close the window, if it gets deactivated *)
      IF w.IsInEventLoop() THEN
        w.Close;
      END;
    ELSE
    END;
  END OnFocusOut;

  PROCEDURE (w : Window) OnRedraw*(x,y,width,height : LONGINT);

  BEGIN
    w.frame.Move(0,0);
    w.frame.Draw(x,y,width,height);

    w.OnRedraw^(x,y,width,height);
  END OnRedraw;

  PROCEDURE (w : Window) OnResized*(width,height : LONGINT);

  BEGIN
    w.frame.Resize(width,height);
    IF w.IsMaped() THEN
      w.frame.Draw(0,0,w.GetWidth(),w.GetHeight());
    END;

    w.OnResized^(width,height);
  END OnResized;

  PROCEDURE (VAR v : GetPosVisitorDesc) Visit*(object : G.Object):BOOLEAN;

  BEGIN
    IF object.visible & object.PointIsIn(v.x,v.y) THEN
      IF object.VisitChildren(v,TRUE) THEN
        CASE v.type OF
          menuGadget:
          IF object.GetMenuObject()#NIL THEN
            v.object:=object;
            RETURN FALSE;
          END;
        | helpGadget:
          IF object.GetHelpObject()#NIL THEN
            v.object:=object;
            RETURN FALSE;
          END;
        | dragGadget:
          IF object.CanDrag() THEN
            v.object:=object;
            RETURN FALSE;
          END;
        END;
      ELSE
        RETURN FALSE;
      END;
    END;

    RETURN TRUE;
  END Visit;

  PROCEDURE (w : Window) GetPosObject(mode : LONGINT):G.Object;

    (**
      Returns the object under the cursor to supports the given mode.
    *)

  VAR
    rx,ry,
    wx,wy : LONGINT;

  VAR
    visitor : GetPosVisitorDesc;

  BEGIN
    w.GetMousePos(rx,ry,wx,wy);

    visitor.x:=wx;
    visitor.y:=wy;
    visitor.type:=mode;
    visitor.object:=NIL;
    IF w.frame.VisitChildren(visitor,TRUE) THEN END;

    IF visitor.object#NIL THEN
      RETURN visitor.object;
    ELSE
      RETURN NIL;
    END;
  END GetPosObject;

  PROCEDURE (w : Window) GetDnDObject*(x,y : LONGINT; drag : BOOLEAN):G.Object;

  (**
    Returns the object that coveres the given point and that supports
    dragging of data.

    If drag is TRUE, when want to find a object that we can drag data from,
    else we want an object to drop data on.
  *)

  BEGIN
    RETURN w.frame.GetDnDObject(x,y,drag);
  END GetDnDObject;

  PROCEDURE (w : Window) OnContextHelp*;

  (**
    Show the context help of an object under the cursor.
  *)

  VAR
    object : G.Object;
    help   : D.Window;

  BEGIN
    IF w.current=NIL THEN
      object:=w.GetPosObject(helpGadget);
      IF object#NIL THEN
        help:=object.GetHelpObject();
        IF help#NIL  THEN
          IF help.Open() THEN END;
        END;
      END;
    END;
  END OnContextHelp;

  PROCEDURE (w : Window) OnContextMenu*():BOOLEAN;

  (**
    This method gets called, when the window things you should
    open a context sensitiv menu.

    RESULT
    Return TRUE if you have opened a context menu, else FALSE.

    NOTE
    If this method returns FALSE, the display will propagate
    the corresponding event that started contextsensitive help
    to the window.
  *)

  VAR
    object : G.Object;
    menu   : D.Window;

  BEGIN
    object:=w.GetPosObject(menuGadget);
    IF object#NIL THEN
      menu:=object.GetMenuObject();
      IF menu#NIL THEN
        IF menu.Open() THEN END;
        RETURN TRUE;
      END;
    END;
    RETURN FALSE;
  END OnContextMenu;

  PROCEDURE (w : Window) FocusNext*;

  (**
    Move the keyboard focus to the next valid object.
  *)

  BEGIN
    w.keyHandler.SetFocusNext;
  END FocusNext;

  PROCEDURE (w : Window) SetFocus*(gadget : G.Gadget);
  (**
  *)

  BEGIN
    w.keyHandler.SetFocus(gadget);
  END SetFocus;

  PROCEDURE (w : Window) HandleEvent*(event : E.Event):BOOLEAN;

  BEGIN
    IF w.HandleEvent^(event) THEN
      RETURN TRUE;
    END;

    (*
      We close the window if we are popup and the user clicks
      outside the window.
    *)
    CASE w.impl.type OF
      D.windowTypeMenu,
      D.windowTypePopup,
      D.windowTypeSplash:
      IF (event IS E.ButtonEvent) & (event(E.ButtonEvent).type=E.mouseDown) THEN
        IF ~w.CursorIsIn() THEN
          w.Close;
          RETURN TRUE;
        END;
      END;
    ELSE
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown)
        & ((event.button=E.button3) OR
           ((event.button=E.button1) & (event.qualifier*E.controlMask#{})))
        & w.OnContextMenu() THEN
        RETURN TRUE;
      END;
    ELSE
    END;

    (*
      now delegate the event to the current or if no current object
      exists, to the top most object
    *)
    WITH
      event :  E.MouseEvent DO
      IF w.current#NIL THEN
        IF w.current.HandleMouseEvent(event,w.current) THEN
          (*          Err.String("."); Err.Ln;*)
        END;

        IF w.current=NIL THEN
          (*          Err.String("-"); Err.Ln; Err.Ln;*)
        END;
        (* Should we further delegate event? *)
      ELSE
        IF w.frame.HandleMouseEvent(event,w.current) THEN
          (*          Err.String("+"); Err.Ln;*)
          IF (w.current#NIL) & w.current.CanFocus() THEN
            (*            Err.String("++"); Err.Ln;*)
            w.keyHandler.SetFocus(w.current(G.Gadget));
          END;
        END;
      END;
    | event : E.KeyEvent DO
      IF w.keyHandler.HandleEvent(event) THEN END;
    ELSE
    END;

    RETURN TRUE;
  END HandleEvent;

  PROCEDURE (w : Window) Receive*(message : O.Message);

  BEGIN
    WITH
      message: OpenMsg DO
        IF w.Open() THEN END;
    | message: OpenModalMsg DO
        IF w.Open() THEN
          w.EventLoop;
        END;
    | message: CloseMsg DO
        w.Close;
    | message: ExitMsg DO
        w.Exit;
    ELSE
    END;
  END Receive;

  (*
    some predefined message-converter
  *)

  PROCEDURE (h : Msg2Open) Convert*(message : O.Message):O.Message;

  VAR
    new : OpenMsg;

  BEGIN
    NEW(new);
    RETURN new;
  END Convert;

  PROCEDURE (h : Msg2OpenModal) Convert*(message : O.Message):O.Message;

  VAR
    new : OpenModalMsg;

  BEGIN
    NEW(new);
    RETURN new;
  END Convert;

  PROCEDURE (h : Msg2Close) Convert*(message : O.Message):O.Message;

  VAR
    new : CloseMsg;

  BEGIN
    NEW(new);
    RETURN new;
  END Convert;

  PROCEDURE (h : Msg2Exit) Convert*(message : O.Message):O.Message;

  VAR
    new : ExitMsg;

  BEGIN
    NEW(new);
    RETURN new;
  END Convert;

  PROCEDURE CreateWindow*():Window;

  VAR
    window : Window;

  BEGIN
    NEW(window);
    window.Init;

    RETURN window;
  END CreateWindow;

BEGIN
  NEW(prefs);
  prefs.Init;

END VO:Window.
