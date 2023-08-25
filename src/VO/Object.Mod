MODULE VO:Object [OOC_EXTENSIONS];

(**
  Implements a hierachie of baseclasses for all displayable objects.
*)

(*
    Basesclass for all graphical objects.
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


IMPORT D   := VO:Base:Display,
       E   := VO:Base:Event,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,
       U   := VO:Base:Util,
       Z   := VO:Base:Size,

       A   := VO:Model:Adjustment,

       P   := VO:Prefs:Base,

              ADT:Dictionary,
       OB  := Object;

CONST
  actionNone * = 0; (** Special noop action *)

  (* values for Object.flags *)

  horizontalFlex * =  0; (** Object can change its size in horizontal direction              *)
  verticalFlex   * =  1; (** Object can change its size in vertical direction                *)
  stdFocus       * =  3; (** Object uses the std way of displ. focus, ie. Object does it all *)
  hasFocus       * =  4; (** The objects currently has the focus                             *)
  canFocus       * =  5; (** We can handle keyboard focus events                             *)
  mayFocus       * =  6; (** It is possible that the object must draw its focus frame, it should therfor
                             interpet this flag to reserve some display space etc... *)
  showFocus      * =  7; (** We can't handle focus events, but should display one. Likely to happend,
                             when focus displaying has been delegated from super object      *)
  requestsFocus  * =  8; (** We request focus handling *)
  scAlways       * =  9; (** Can handle sc even when not visible (menus f.e.)                *)
  canDisable     * = 10; (** Object has special handling for drawing disabled *)
  inited         * = 11; (** CalcSize has been called at least one *)

  (* values for minXXX and maxXXX *)

  minSize = 0;
  maxSize = MAX(INTEGER);   (* Because of hardcoded focusborderwidth of 2 than might be added *)

  (* Constants for different kind of alignments an object may support *)

  alignLeft      * = 0; (** align left *)
  alignCenter    * = 1; (** center within bounds *)
  alignRight     * = 2; (** align right *)
  alignBound     * = 3; (** Resize object that it covers all available space *)
  alignTop       * = 4; (** align top *)
  alignBottom    * = 5; (** align bottom *)

  alignmentCount * = 6;

TYPE
  AlignmentName = ARRAY 15 OF CHAR;

  Background*     = POINTER TO BackgroundDesc;
  BackgroundDesc* = RECORD [ABSTRACT]
  (**
    An object can have a background color or an background object that is responsible
    for drawing the given region in the background style. Background object could draw
    the background simply using the background color (though you can achive this b
    y simply setting the background color without using an background object),
    a regular pattern, a titled image, an image stretched to fit the whole object or
    something even more complicated.

    The apropiate method of filling the background will be handled the DrawBackground
    method. It will fill the given area in the backgrojund area or will delegate
    drawing to the background object - if available.

    source stores the orign of this Background. E.g., yo assign a background object
    to a button. The button will delegate the background to it label. However in some
    cases the background must not be rendered relative to the size of the label but
    still relative to the button.
  *)
                    END;


  Prefs*      = POINTER TO PrefsDesc;
  PrefsDesc*  = RECORD (P.PrefsDesc)
                  (**
                    Special Preferences object for graphical objects.
                  *)

                  background* : Background;
                  frame*      : F.Frame;
                  hSize*,                    (** Value to fixate the horizontal size of the object *)
                  vSize*      : Z.SizeDesc; (** Value to fixate the vertical size of the object *)
                END;

  VisitorDesc* = RECORD [ABSTRACT]
                   (**
                     Visitor allows you to enumerate a list of objects.
                     You call a special visit-method, handing over an instance of
                     Visitor (or a derived class containing additional information).
                     The visit method will be called a every object visited.

                     This makes it easy to iterate over a collection of objects
                     without knowing the internal structure of the collection.
                     It follows the iterator design pattern.
                   *)
                 END;

  Action      = POINTER TO ActionDesc;
  ActionDesc  = RECORD (O.ObjectDesc)
                  id : LONGINT;
                END;

  Controller*     = POINTER TO ControllerDesc;
  ControllerDesc* = RECORD
                      (**
                        Controller, mapping external interaction like keyboard and
                        mouse events onto actions supported by the corresponding
                        object.

                        Normally all objects of a certain type share the same derived
                        controller instance.
                      *)
                      keys : Dictionary.Dictionary(STRING,Action); (** List of key to action mappings *)
                    END;

  Object*     = POINTER TO ObjectDesc;
  ObjectDesc* = RECORD [ABSTRACT] (D.ObjectDesc)
                  (**
                    Special Preferences object for graphical objects.
                  *)

                  next*,                             (** All objects a singlelinked *)
                  parent-              : Object;

                  (* preferences *)
                  prefs-               : Prefs;      (** Preferences of this object *)

                  (* Sizing stuff *)

                  x-,y-,                             (** The current bounds of the object *)
                  width*,height*,

                  minWidth*,minHeight*,              (** Its minimal and maximal bounds *)
                  maxWidth*,maxHeight* : LONGINT;

                  oX-,oY-,
                  oWidth-,oHeight-    : LONGINT;     (**
                                                       The outer bounds of the object
                                                       Inner bounds + possible focus frame
                                                     *)

                  oMinWidth-,
                  oMinHeight-,                       (** Its minimal and maximal bounds *)
                  oMaxWidth-,
                  oMaxHeight-          : LONGINT;

                  setWidth,
                  setHeight,
                  setMinWidth,
                  setMinHeight,
                  setMaxWidth,
                  setMaxHeight         : Z.SizeDesc;

                  (* generalFlags *)

                  flags-               : SET;        (** Some special flags *)

                  (* visibility stuff *)

                  backgroundObject-,
                  selectionObject-     : Background;
                  visible-,                          (** The object is currently visible, i.e. not hidden *)
                  disabled-,
                  layouted             : BOOLEAN;    (** Every object can be disabled *)

                  (* objects *)
                  window               : D.Window;
                  menu                 : D.Window;   (** pointer the context sensitive menuobject *)
                  help                 : D.Window;   (** pointer the context sensitive helpobject *)

                  objectFrame-         : F.Frame;

                  focus-               : F.Frame;
                  labelObject-         : Object;     (** An object can have a label *)
                  controller-          : Controller;
                END;

  Control*     = POINTER TO ControlDesc;
  ControlDesc* = RECORD [ABSTRACT] (ObjectDesc)
                   (**
                     New baseclasses that distinguish between objects which
                     control data and those which are used to control
                     layout.
                   *)
                  END;

  Image*      = POINTER TO ImageDesc;  (* An image is a special kind of Object *)
  ImageDesc*  = RECORD [ABSTRACT] (ObjectDesc)
                  (**
                    The baseclass for all images. Images do not have any
                    event-handling.
                  *)
                END;


  Gadget*     = POINTER TO GadgetDesc;
  GadgetDesc* = RECORD [ABSTRACT] (ControlDesc)
                  (**
                    The baseclass for all gadgets. Gadgets have methods
                    for event handling, unlike images for example.
                  *)
                END;


  Layout*     = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD [ABSTRACT] (ObjectDesc)
                  (**
                    New baseclasses that distinguish between objects which
                    control data and those which are used to control
                    layout.
                  *)
                END;

  ScrollableGadget*     = POINTER TO ScrollableGadgetDesc;
  ScrollableGadgetDesc* = RECORD [ABSTRACT] (GadgetDesc)
                            (**
                              The baseclass for all scrollable gadgets.
                            *)
                            hAdjustment*,
                            vAdjustment* : A.Adjustment;
                          END;

  Group*      = POINTER TO GroupDesc;
  GroupDesc*  = RECORD [ABSTRACT] (LayoutDesc)
                  (**
                    An group is a special kind of Object. Although it is a
                    collection of objects, it acts only as a layout instance.
                    So it inherits from LayoutObject.

                    It collects a number of object and presents them as one
                    object to the rest of the world.
                  *)
                  list-,               (** A linked list of all children *)
                  last-  : Object;
                  count- : LONGINT;    (** The number of children *)
                END;

 (* -- messages -- *)

  LabelClickedMsg*     = POINTER TO LabelClickedMsgDesc;
  LabelClickedMsgDesc* = RECORD (O.MessageDesc)
                           (**
                             The LabelClickedMsg maybe generated when someone clicks on your label.
                           *)
                         END;

  (* -- visitors -- *)

  FreeVisitorDesc*     = RECORD (VisitorDesc)
                           (**
                             Visitor that recursivly frees all objects by calling
                             @oproc{Object.Free}.
                           *)
                         END;

  SubRegionVisitorDesc = RECORD (VisitorDesc)
                           draw : D.DrawInfo;
                         END;

  DrawVisitorDesc      = RECORD (VisitorDesc)
                           layout : Layout;
                           x,y,width,height : LONGINT;
                         END;

  DisableVisitorDesc   = RECORD (VisitorDesc)
                           disable : BOOLEAN;
                         END;

  HideVisitorDesc      = RECORD (VisitorDesc)
                         END;

  MouseEventVisitorDesc= RECORD (VisitorDesc)
                           event : E.MouseEvent;
                           grab : Object;
                         END;

  GetDnDVisitorDesc    = RECORD (VisitorDesc)
                           x,y    : LONGINT;
                           drag   : BOOLEAN;
                           object : Object;
                         END;

  GetNameVisitorDesc    = RECORD (VisitorDesc)
                            name   : STRING;
                            object : Object;
                          END;

  SetWindowVisitorDesc  = RECORD (VisitorDesc)
                          END;

  IsChildVisitorDesc    = RECORD (VisitorDesc)
                            object : Object;
                            res    : BOOLEAN;
                          END;

  FocusFirstVisitorDesc = RECORD (VisitorDesc)
                            object : Object;
                          END;

  FocusLastVisitorDesc  = RECORD (VisitorDesc)
                            object : Object;
                          END;

  FocusAfterVisitorDesc = RECORD (VisitorDesc)
                            start  : BOOLEAN;
                            base,
                            object : Object;
                          END;

  FocusBeforeVisitorDesc = RECORD (VisitorDesc)
                             start  : BOOLEAN;
                             base,
                             object : Object;
                           END;

  FocusAfterRVisitorDesc = RECORD (VisitorDesc)
                             start  : BOOLEAN;
                             base,
                             object : Object;
                           END;

  FocusBeforeRVisitorDesc = RECORD (VisitorDesc)
                              base,
                              object : Object;
                            END;

VAR
  alignments- : ARRAY alignmentCount OF AlignmentName;

  (* -------------------------------------------- *)

  PROCEDURE (b : Background) [ABSTRACT] Draw*(draw : D.DrawInfo;
                                              relX,relY,relWidth,relHeight,
                                              x,y,w,h : LONGINT);
  (**
    Draw the background. The baseclass will simply fill the given area
    with the defined object background color.
  *)
  END Draw;

  PROCEDURE (b : Background) DrawRelObject*(draw : D.DrawInfo;
                                            relObject : Object;
                                            x,y,w,h : LONGINT);

  BEGIN
    b.Draw(draw,relObject.x,relObject.y,relObject.width,relObject.height,x,y,w,h);
  END DrawRelObject;

  PROCEDURE (b : Background) [ABSTRACT] CanDraw*(draw : D.DrawInfo):BOOLEAN;
    (**
      Returns @code{TRUE}, if the background object can handle the drawing
      request.
    *)
  END CanDraw;

  PROCEDURE (b : Background) [ABSTRACT] Copy*():Background;
  (**
    Return a copy of the current background object.
  *)
  END Copy;

  PROCEDURE (b : Background) Free*;
  (**
    Free internal data.
  *)

  BEGIN
  END Free;

  (* -------------------------------------------- *)

  PROCEDURE (VAR v : VisitorDesc) Visit*(object : Object):BOOLEAN;

    (**
      If you visit a list of objects, this method will be called for
      every object visited.

      Returning @code{TRUE} means "go on", returning @code{FALSE} means,
      stop and return.
    *)

  BEGIN
    RETURN TRUE;
  END Visit;

  (* -------------------------------------------- *)

  PROCEDURE (c : Controller) Init*;

  BEGIN
    NEW(c.keys);
  END Init;

  PROCEDURE (c : Controller) RegisterKeyAction*(key : STRING; action : LONGINT);

    (**
      Register an @oparam{action} for a @oparam{key}-shortcut.
    *)

  VAR
    act : Action;

  BEGIN
    NEW(act);
    act.id:=action;
    c.keys.Set(key,act);
  END RegisterKeyAction;

  PROCEDURE (c : Controller) GetActionForKey*(key : STRING):LONGINT;

    (**
      Return the action for a certain key combination or @oconst{actionNone}
      if no action for this key combination can be found.
    *)

  VAR
    action : Action;

  BEGIN
    IF c.keys.HasKey(key) THEN
      action:=c.keys.Get(key);
      RETURN action.id;
    ELSE
      RETURN actionNone;
    END;
  END GetActionForKey;

  PROCEDURE (c : Controller) DoAction*(object : Object; action : LONGINT):BOOLEAN;

    (**
      Execute @oparam{action} on @oparam{object}.
    *)

  BEGIN
    RETURN FALSE;
  END DoAction;

  (* -------------------------------------------- *)

  PROCEDURE (o : Object) Init*;
  (**
    Every object needs an initialiser.

    If you provide an Init-method for an object you must first cann the
    Init-method of the baseclass.

    Note, that this does not hinder you ro provide function-like initializer, too.
    They just have to call this method.
  *)

  BEGIN
    o.Init^;
    o.x:=0;
    o.y:=0;

    o.oX:=0;
    o.oY:=0;

    o.width:=0;
    o.height:=0;

    o.oWidth:=0;
    o.oHeight:=0;

    o.next:=NIL;
    o.parent:=NIL;

    o.prefs:=NIL;

    o.minWidth:=minSize;
    o.minHeight:=minSize;
    o.maxWidth:=maxSize;
    o.maxHeight:=maxSize;

    o.oMinWidth:=minSize;
    o.oMinHeight:=minSize;
    o.oMaxWidth:=maxSize;
    o.oMaxHeight:=maxSize;

    o.setWidth.Init;
    o.setHeight.Init;
    o.setMinWidth.Init;
    o.setMinHeight.Init;
    o.setMaxWidth.Init;
    o.setMaxHeight.Init;

    o.flags:={stdFocus};
    o.visible:=FALSE;
    o.disabled:=FALSE;

    o.layouted:=FALSE;

    o.focus:=NIL;
    o.labelObject:=NIL;

    o.backgroundObject:=NIL;
    o.selectionObject:=NIL;

    o.window:=NIL;
    o.menu:=NIL;
    o.help:=NIL;

    o.objectFrame:=F.CreateFrame(F.none);

    o.controller:=NIL;
  END Init;

  PROCEDURE (o : Object) SetController*(controller : Controller);

  BEGIN
    o.controller:=controller;
  END SetController;

  PROCEDURE (o : Object) VisitChildren*(VAR visitor : VisitorDesc;
                                        onlyVisible : BOOLEAN):BOOLEAN;

    (**
      The object base class does not know about children. This method will
      do nothing.

      Returning @code{TRUE} means "go on", returning @code{FALSE} means,
      stop and return.
    *)

  BEGIN
    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (o : Object) SetFlags*(flags : SET);
  (**
    Via this functions you can add the given flags to the
    flags already set.
  *)

  BEGIN
    o.flags:=o.flags+flags;
  END SetFlags;

  PROCEDURE (o : Object) RemoveFlags*(flags : SET);
  (**
    Via this functions you can remove the given flags from the
    flags already set.
  *)

  BEGIN
    o.flags:=o.flags-flags;
  END RemoveFlags;

  PROCEDURE (o : Object) ClearFlags*;
  (**
    Via this functions you can clear all flags.

    NOTE
    This is a dangerous operations. There are many internal flags used by
    VO and it is likely that some things will not operate the way you
    want them to. Use removeFlags instead whenever possible.
  *)

  BEGIN
    o.flags:={};
  END ClearFlags;

  PROCEDURE (o : Object) SetWidth*(mode, value : LONGINT);
  (**
    Set the width of the object.
    "Mode" defines the interpretation of the given value.
  *)

  BEGIN
    o.setWidth.SetSize(mode,value);
  END SetWidth;

  PROCEDURE (o : Object) SetHeight*(mode, value : LONGINT);
  (**
    Set the height of the object.
    "Mode" defines the interpretation of the given value.
  *)

  BEGIN
    o.setHeight.SetSize(mode,value);
  END SetHeight;

  PROCEDURE (o : Object) SetMinWidth*(mode, value : LONGINT);
  (**
    Set the minWidth of the object.
    "Mode" defines the interpretation of the given value.
  *)

  BEGIN
    o.setMinWidth.SetSize(mode,value);
  END SetMinWidth;

  PROCEDURE (o : Object) SetMinHeight*(mode, value : LONGINT);
  (**
    Set the minHeight of the object.
    "Mode" defines the interpretation of the given value.
  *)

  BEGIN
    o.setMinHeight.SetSize(mode,value);
  END SetMinHeight;

  PROCEDURE (o : Object) SetMaxWidth*(mode, value : LONGINT);
  (**
    Set the maxWidth of the object.
    "Mode" defines the interpretation of the given value.
  *)

  BEGIN
    o.setMaxWidth.SetSize(mode,value);
  END SetMaxWidth;

  PROCEDURE (o : Object) SetMaxHeight*(mode, value : LONGINT);
  (**
    Set the maxHeight of the object.
    "Mode" defines the interpretation of the given value.
  *)

  BEGIN
    o.setMaxHeight.SetSize(mode,value);
  END SetMaxHeight;

  PROCEDURE (o : Object) SetBackgroundObject*(background : Background);
  (**
    Set the background object for the object. Behaviour for complex/group
    objects is undefined.
  *)

  BEGIN
    IF o.backgroundObject#NIL THEN
      (*o.backgroundObject.Free;*)
    END;

    o.backgroundObject:=background;
  END SetBackgroundObject;

  PROCEDURE (o : Object) SetSelectionBackgroundObject*(background : Background);
  (**
    Set the background object for the object. Behaviour for complex/group
    objects is undefined.
  *)

  BEGIN
    IF o.selectionObject#NIL THEN
      (*o.selectionObject.Free;*)
    END;

    o.selectionObject:=background;
  END SetSelectionBackgroundObject;

  PROCEDURE (o : Object) SetLabelObject*(label : Object);
  (**
    Assign a label to the object. Some object may support some
    tricky operations with their label. A checkbox f.e. may delegate its
    focus frame to its label.
  *)

  BEGIN
    o.labelObject:=label;
  END SetLabelObject;

  PROCEDURE (VAR v : SetWindowVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    IF object#NIL THEN
      object.window:=NIL;
      RETURN object.VisitChildren(v,FALSE);
    ELSE
      RETURN FALSE;
    END;
  END Visit;

  PROCEDURE (o : Object) SetWindow*(window : D.Window);

  VAR
    visitor : SetWindowVisitorDesc;

  BEGIN
    o.window:=window;
    IF o.VisitChildren(visitor,FALSE) THEN END;
  END SetWindow;

  PROCEDURE (o : Object) GetWindow*():D.Window;

    (**
      Returns the @otype{D.Window} this @otype{Object} belong to.
    *)

  BEGIN
    IF o.window#NIL THEN
      RETURN o.window;
    ELSIF o.parent#NIL THEN
      o.window:=o.parent.GetWindow();
      RETURN o.window;
    ELSE
       RETURN NIL;
     END;
  END GetWindow;

  PROCEDURE (o : Object) SetParent*(parent : Object);
  (**
    Sets the parent object of this object.

    NOTE
    Normaly the objects tries to get its windows and thus is draw info object
    asking its parent. So be carefull to set a parent object for each object
    use instantiate. Most time this is automatically handled by the container
    object.

    Since top level object cannot have a parent, you must explicitely set
    the window calling SetWindow().
  *)

  BEGIN
(*    ASSERT((o.parent=NIL) OR (o.parent=parent));*)

    o.parent:=parent;
    o.window:=NIL;
  END SetParent;

  PROCEDURE (VAR v : GetNameVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    IF (object.name#NIL) & (object.name.Equals(v.name)) THEN
      v.object:=object;
      RETURN FALSE;
    ELSE
      RETURN object.VisitChildren(v,FALSE);
    END;
  END Visit;

  PROCEDURE (o : Object) GetObjectByName*(name : STRING):Object;

  VAR
    visitor : GetNameVisitorDesc;

  BEGIN
    visitor.object:=NIL;
    visitor.name:=name;

    IF visitor.Visit(o) THEN
      IF o.VisitChildren(visitor,FALSE) THEN END;
    END;
    RETURN visitor.object;
  END GetObjectByName;

  PROCEDURE (o : Object) GetDrawInfo*():D.DrawInfo;
  (**
    Returns the VODisplay.DrawInfo used for all drawing.
  *)

  VAR
    window : D.Window;

  BEGIN
    window:=o.GetWindow();

    ASSERT(window#NIL);

    RETURN window.GetDrawInfo();
  END GetDrawInfo;

  PROCEDURE (o : Object) SetObjectFrame*(frame : F.Frame);

  BEGIN
    o.objectFrame:=frame;
  END SetObjectFrame;

  PROCEDURE (o : Object) SetHelpObject*(helpObject : D.Window);

    (**
      Assign a @otype{D.Window} that will displayed as tooltip. The baseclass will
      store the object within a private variable and will return it when
      @oproc{Object.GetHelpObject} gets called.
    *)

  BEGIN
    o.help:=helpObject;
  END SetHelpObject;

  PROCEDURE (o : Object) GetHelpObject*():D.Window;
    (**
      Returns the help window for this object.
    *)

  BEGIN
    RETURN o.help;
  END GetHelpObject;

  PROCEDURE (o : Object) SetMenuObject*(menuObject : D.Window);

    (**
      Assign a @otype{D.Window} that will displayed as menu. The baseclass will
      store  the object within a private variable and will return it when
      @oproc{Object.GetMenuObject} gets called.
    *)

  BEGIN
    o.menu:=menuObject;
  END SetMenuObject;

  PROCEDURE (o : Object) GetMenuObject*():D.Window;
  (**
    Returns the menu window for this object.
  *)

  BEGIN
    RETURN o.menu;
  END GetMenuObject;

  PROCEDURE (o : Object) SetFocusObject*(focus : F.Frame);

  BEGIN
    o.focus:=focus;
  END SetFocusObject;

  PROCEDURE (o : Object) StdFocus*():BOOLEAN;
  (**
    Returns TRUE, when the object displays itself using the standard functionality
    of displaying focus frameing, e.g. stdFocus
    is in Object.flags.
  *)

  BEGIN
    RETURN stdFocus IN o.flags;
  END StdFocus;

  PROCEDURE (o : Object) HasFocus*():BOOLEAN;
  (**
    Returns TRUE, when the object has the focus, e.g. hasFocus
    is in Object.flags.
  *)

  BEGIN
    RETURN hasFocus IN o.flags;
  END HasFocus;

  PROCEDURE (o : Object) CanFocus*():BOOLEAN;
  (**
    Returns TRUE, when the object can handle keyboard focus events,a e.g. canFocus
    is in Object.flags.
  *)

  BEGIN
    RETURN canFocus IN o.flags;
  END CanFocus;

  PROCEDURE (o : Object) MayFocus*():BOOLEAN;
  (**
    Returns TRUE, when the object may show its focusframe,a e.g. mayFocus
    is in Object.flags.
  *)

  BEGIN
    RETURN mayFocus IN o.flags;
  END MayFocus;

  PROCEDURE (o : Object) DisplayFocus*():BOOLEAN;
  (**
    Returns TRUE, when the object should display its focusframe,a e.g. showFocus
    or hasFocus is in Object.flags.
  *)

  BEGIN
    RETURN (hasFocus IN o.flags) OR (showFocus IN o.flags);
  END DisplayFocus;

  PROCEDURE (o : Object) RequestFocus*;
  (**
    Sets the @oconst{requestsFocus} flag and in consequence registers itself as
    member of the focus chain.
  *)

  BEGIN
    INCL(o.flags,mayFocus);
    INCL(o.flags,requestsFocus);
  END RequestFocus;

  PROCEDURE (o : Object) UnrequestFocus*;
  (**
    Negates @oproc{Object.RequestFocus}.
  *)

  BEGIN
    EXCL(o.flags,mayFocus);
    EXCL(o.flags,requestsFocus);
  END UnrequestFocus;

  PROCEDURE (o : Object) HasFocusRequested*():BOOLEAN;
  (**
    Returns TRUE, when the object has the focus, e.g. hasFocus
    is in Object.flags.
  *)

  BEGIN
    RETURN requestsFocus IN o.flags;
  END HasFocusRequested;

  PROCEDURE (o : Object) CanHandleFocus*():BOOLEAN;

  (**
    Returns TRUE, when the object request focus handling, e.g. requestsFocus
    is in Object.flags, is visible and not disabled.
  *)

  BEGIN
    RETURN (requestsFocus IN o.flags) & o.visible & ~o.disabled;
  END CanHandleFocus;


  PROCEDURE (VAR v : FocusFirstVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    IF object.CanHandleFocus() THEN
      v.object:=object;
      RETURN FALSE;
    ELSE
      RETURN object.VisitChildren(v,TRUE);
    END;
  END Visit;

  PROCEDURE (o : Object) GetFocusFirst*():Object;

    (**
      Returns the first child object (or the object itself that requests
      keyboard focusing.
    *)

  VAR
    visitor : FocusFirstVisitorDesc;

  BEGIN
    IF o.CanHandleFocus() THEN
      RETURN o;
    END;

    visitor.object:=NIL;

    IF o.VisitChildren(visitor,TRUE) THEN END;

    RETURN visitor.object;
  END GetFocusFirst;

  PROCEDURE (o : Object) GetFocusLast*():Object;

    (**
      Returns the last child object (or the object itself9 that requests
      keyboard focusing.
    *)
  VAR

    visitor : FocusLastVisitorDesc;

  BEGIN
    visitor.object:=NIL;

    IF o.VisitChildren(visitor,TRUE) THEN END;

    IF visitor.object#NIL THEN
      RETURN visitor.object;
    END;

    IF o.CanHandleFocus() THEN
      RETURN o;
    ELSE
      RETURN NIL;
    END;
  END GetFocusLast;

  PROCEDURE (o : Object) GetFocusNext*(object : Object):Object;

    (**
      Returns the next object (or the object itself9 that requests
      keyboard focusing.
    *)

  VAR
    first  : FocusFirstVisitorDesc;
    after  : FocusAfterVisitorDesc;
    before : FocusBeforeVisitorDesc;
    test   : IsChildVisitorDesc;
    res    : Object;

  BEGIN
    IF object=o THEN
      (* First we search for the first object in the list of children *)
      first.object:=NIL;
      IF o.VisitChildren(first,TRUE) THEN END;

      IF first.object#NIL THEN
        RETURN first.object;
      END;

      (* Delegate it to our parent *)
      IF o.parent#NIL THEN
        RETURN o.parent.GetFocusNext(o);
      ELSE
        RETURN NIL;
      END;

    ELSE

      (* Search for the next object in our list of children  *)
      after.start:=FALSE;
      after.base:=object;
      after.object:=NIL;
      IF o.VisitChildren(after,TRUE) THEN END;

      IF after.object#NIL THEN
        RETURN after.object;
      END;

      (*
        If we a called by a child and connot find a follower within our
        list of children we delegate it to the parent to investigate all
        other subtrees.
      *)

      test.object:=object;
      test.res:=FALSE;
      IF o.VisitChildren(test,TRUE) THEN END;

      IF test.res & (o.parent#NIL) THEN
        res:=o.parent.GetFocusNext(o);
        IF res#NIL THEN
          RETURN res;
        END;
      END;

      (* Now, if that fails: can we handle it ourself? *)
      IF o.CanHandleFocus() THEN
        RETURN o;
      END;

      (* Search for the next object in our list of children  *)
      before.start:=TRUE;
      before.base:=object;
      before.object:=NIL;
      IF o.VisitChildren(before,TRUE) THEN END;

      IF before.object#NIL THEN
        RETURN before.object;
      END;

    END;

    RETURN NIL;
  END GetFocusNext;

  PROCEDURE (o : Object) GetFocusPrevious*(object : Object):Object;

    (**
      Returns the previous object (or the object itself9 that requests
      keyboard focusing.
    *)

  VAR
    last   : FocusLastVisitorDesc;
    after  : FocusAfterRVisitorDesc;
    before : FocusBeforeRVisitorDesc;
    res    : Object;

  BEGIN
    IF object=o THEN
      (* Delegate it to our parent *)
      IF o.parent#NIL THEN
        res:=o.parent.GetFocusPrevious(o);
        IF res#NIL THEN
          RETURN res;
        END;
      END;

      (* After that we search for the last object in the list of children *)

      last.object:=NIL;
      IF o.VisitChildren(last,TRUE) THEN END;

      RETURN last.object;

    ELSE
      (* Search for the previous object in our list of children  *)
      before.base:=object;
      before.object:=NIL;
      IF o.VisitChildren(before,TRUE) THEN END;

      IF before.object#NIL THEN
        RETURN before.object;
      END;

      (* Now, if that fails: can we handle it ourself? *)
      IF o.CanHandleFocus() THEN
        RETURN o;
      END;

      (*
        If we a called by a child and connot find a follower within our
        list of children we delegate it to the parent to investigate all
        other subtrees.
      *)
      IF (o.parent#NIL) THEN
        res:=o.parent.GetFocusPrevious(o);
        IF res#NIL THEN
          RETURN res;
        END;
      END;

      (* Search for the next object in our list of children  *)
      after.start:=FALSE;
      after.base:=object;
      after.object:=NIL;
      IF o.VisitChildren(after,TRUE) THEN END;

      IF after.object#NIL THEN
        RETURN after.object;
      END;

    END;

    RETURN NIL;
  END GetFocusPrevious;

  PROCEDURE (VAR v : IsChildVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    IF object=v.object THEN
      v.res:=TRUE;
    END;

    RETURN TRUE;
  END Visit;

  PROCEDURE (VAR v : FocusLastVisitorDesc) Visit*(object : Object):BOOLEAN;

  VAR
    tmp : Object;

  BEGIN
    tmp:=v.object;
    v.object:=NIL;

    IF object.VisitChildren(v,TRUE) THEN END;
    IF v.object=NIL THEN
      IF object.CanHandleFocus() THEN
        v.object:=object;
      END;
    END;

    IF v.object=NIL THEN
      v.object:=tmp;
    END;

    RETURN TRUE;
  END Visit;

  PROCEDURE (VAR v : FocusAfterVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    IF v.start THEN
      v.object:=object.GetFocusFirst();
      RETURN v.object=NIL;
    ELSE
      IF object=v.base THEN
        v.start:=TRUE;
      END;

      RETURN TRUE;
    END;
  END Visit;

  PROCEDURE (VAR v : FocusBeforeVisitorDesc) Visit*(object : Object):BOOLEAN;

  VAR
    tmp : Object;

  BEGIN
    IF object=v.base THEN
      v.start:=FALSE;
      RETURN FALSE;
    END;

    tmp:=object.GetFocusFirst();
    IF tmp#NIL THEN
      v.object:=tmp;
      RETURN FALSE;
    END;

    RETURN TRUE;
  END Visit;

  PROCEDURE (VAR v : FocusAfterRVisitorDesc) Visit*(object : Object):BOOLEAN;

  VAR
    tmp : Object;

  BEGIN
    IF v.start THEN
      tmp:=object.GetFocusLast();

      IF tmp#NIL THEN
        v.object:=tmp;
      END;
    ELSE
      IF object=v.base THEN
        v.start:=TRUE;
      END;
    END;

    RETURN TRUE;
  END Visit;

  PROCEDURE (VAR v : FocusBeforeRVisitorDesc) Visit*(object : Object):BOOLEAN;

  VAR
    tmp : Object;

  BEGIN
    IF object=v.base THEN
      RETURN FALSE;
    END;

    tmp:=object.GetFocusLast();
    IF tmp#NIL THEN
      v.object:=tmp;
    END;

    RETURN TRUE;
  END Visit;

  PROCEDURE (o : Object) SetPrefs*(p : Prefs);

  BEGIN
    o.prefs:=p; (* We set the prefs *)

    IF p.background#NIL THEN
      o.SetBackgroundObject(p.background.Copy());
    END;

    IF p.hSize.IsSizeSet() THEN
      o.SetWidth(p.hSize.mode,p.hSize.size);
    END;

    IF p.vSize.IsSizeSet() THEN
      o.SetHeight(p.vSize.mode,p.vSize.size);
    END;

    o.objectFrame:=o.prefs.frame;
  END SetPrefs;

  PROCEDURE (o : Object) CalcSize*;
  (**
    Tell the object it should calculate its size depending on its current settings

    This method normally gets calleed once before the first call of ObjectDraw.
    The window calls this method for its top object before it opens itself
    and draws its content. The top object call this method automatically for all
    its children.

    If this method get called for you object you normally have to simly
    propagate it to all your children and set the values for minWidth,
    minHeight, width and height. The setting of the max-values is optional,
    the defaultvalue for them is MAX(LONGINT).

    After this your *must* call this method of your baseclass.
  *)

  VAR
    window : D.Window;

  BEGIN
    IF o.setMinWidth.IsSizeSet() THEN
      o.minWidth:=U.RoundRange(o.setMinWidth.GetSize(),o.minWidth,o.maxWidth);
    END;

    IF o.setMinHeight.IsSizeSet() THEN
      o.minHeight:=U.RoundRange(o.setMinHeight.GetSize(),o.minHeight,o.maxHeight);
    END;

    IF o.setMaxWidth.IsSizeSet() THEN
      o.maxWidth:=U.RoundRange(o.setMaxWidth.GetSize(),o.minWidth,o.maxWidth);
    END;

    IF o.setMaxHeight.IsSizeSet() THEN
      o.maxHeight:=U.RoundRange(o.setMaxHeight.GetSize(),o.minHeight,o.maxHeight);
    END;

    o.width:=U.RoundRange(o.width,o.minWidth,o.maxWidth);
    o.height:=U.RoundRange(o.height,o.minHeight,o.maxHeight);

    IF o.setWidth.IsSizeSet() THEN
      o.width:=U.RoundRange(o.setWidth.GetSize(),o.minWidth,o.maxWidth);
    END;

    IF o.setHeight.IsSizeSet() THEN
      o.height:=U.RoundRange(o.setHeight.GetSize(),o.minHeight,o.maxHeight);
    END;

    o.oWidth:=o.width;
    o.oHeight:=o.height;

    o.oMinWidth:=o.minWidth;
    o.oMinHeight:=o.minHeight;

    o.oMaxWidth:=o.maxWidth;
    o.oMaxHeight:=o.maxHeight;

    INC(o.oWidth,o.objectFrame.leftBorder+o.objectFrame.rightBorder);
    INC(o.oHeight,o.objectFrame.topBorder+o.objectFrame.bottomBorder);

    INC(o.oMinWidth,o.objectFrame.leftBorder+o.objectFrame.rightBorder);
    INC(o.oMinHeight,o.objectFrame.topBorder+o.objectFrame.bottomBorder);
    INC(o.oMaxWidth,o.objectFrame.leftBorder+o.objectFrame.rightBorder);
    INC(o.oMaxHeight,o.objectFrame.topBorder+o.objectFrame.bottomBorder);

    IF o.MayFocus() & o.StdFocus() THEN

      IF o.focus=NIL THEN
        o.focus:=F.CreateFrame(F.doubleFocus);
        (* We need a frame-image for a button *)
      END;

      INC(o.oWidth,o.focus.leftBorder+o.focus.rightBorder);
      INC(o.oHeight,o.focus.topBorder+o.focus.bottomBorder);

      INC(o.oMinWidth,o.focus.leftBorder+o.focus.rightBorder);
      INC(o.oMinHeight,o.focus.topBorder+o.focus.bottomBorder);
      INC(o.oMaxWidth,o.focus.leftBorder+o.focus.rightBorder);
      INC(o.oMaxHeight,o.focus.topBorder+o.focus.bottomBorder);
    END;

    IF ~(horizontalFlex IN o.flags) THEN
      o.oMinWidth:=o.oWidth;
      o.minWidth:=o.width;
      o.oMaxWidth:=o.oWidth;
      o.maxWidth:=o.width;
    END;
    IF ~(verticalFlex IN o.flags) THEN
      o.oMinHeight:=o.oHeight;
      o.minHeight:=o.height;
      o.oMaxHeight:=o.oHeight;
      o.maxHeight:=o.height;
    END;

    INCL(o.flags,inited);

    IF o.menu#NIL THEN
      window:=o.GetWindow();
      o.menu.SetParent(window);
    END;

    o.layouted:=FALSE;
  END CalcSize;

  PROCEDURE (o : Object) CanGrow*(horiz : BOOLEAN):BOOLEAN;
  (**
    Returns true, if the object can grow in the stated direction

    An object is resizable, if

    * It hase the xxxFlex-flag set for that direction

    * And if its current size is smaller than it maximal size

  *)

  BEGIN
    IF horiz THEN
      IF horizontalFlex IN o.flags THEN
        RETURN o.width<o.maxWidth;
      ELSE
        RETURN FALSE;
      END;
    ELSE
      IF verticalFlex IN o.flags THEN
        RETURN o.height<o.maxHeight;
      ELSE
        RETURN FALSE;
      END;
    END;
  END CanGrow;

  PROCEDURE (o : Object) CanShrink*(horiz : BOOLEAN):BOOLEAN;
  (**
    Same as Object.CanGrow only for shrinking
  *)

  BEGIN
    IF horiz THEN
      IF horizontalFlex IN o.flags THEN
        RETURN o.width>o.minWidth;
      ELSE
        RETURN FALSE;
      END;
    ELSE
      IF verticalFlex IN o.flags THEN
        RETURN o.height>o.minHeight;
      ELSE
        RETURN FALSE;
      END;
    END;
  END CanShrink;

  PROCEDURE (o : Object) CanResize*(grow, horiz : BOOLEAN):BOOLEAN;
  (**
    This calls Object.CanGrow or Object.Can.Shrink depending on its options
  *)

  BEGIN
    IF grow THEN
      RETURN o.CanGrow(horiz);
    ELSE
      RETURN o.CanShrink(horiz);
    END;
  END CanResize;

  PROCEDURE (o : Object) CanDrag*():BOOLEAN;
  (**
    Returns TRUE if you can drag data from the object.
  *)

  BEGIN
    RETURN FALSE;
  END CanDrag;

  PROCEDURE (o : Object) Resize*(width,height : LONGINT);
  (**
    This function tries to resize the object to the given measurement

    Note, that the object may not have the giving size after calling since
    it have the follow the settings for o.flags and it maximal size

    Normally the features of this implementation are enought.
    But you can overload it (At the moment none of the classes does this).

  *)

  VAR
    oldOWidth,oldOHeight : LONGINT;

  BEGIN
    oldOWidth:=o.oWidth;
    oldOHeight:=o.oHeight;

    IF o.MayFocus() & o.StdFocus() THEN
      IF (horizontalFlex IN o.flags) & (width>=0) THEN
        o.oWidth:=U.MaxLong(width,o.oMinWidth);
        o.width:=o.oWidth-o.focus.leftBorder-o.focus.rightBorder
                         -o.objectFrame.leftBorder-o.objectFrame.rightBorder;
      END;
      IF (verticalFlex IN o.flags) & (height>=0) THEN
        o.oHeight:=U.MaxLong(height,o.oMinHeight);
        o.height:=o.oHeight-o.focus.topBorder-o.focus.bottomBorder
                           -o.objectFrame.topBorder-o.objectFrame.bottomBorder;
      END;
    ELSE
      IF (horizontalFlex IN o.flags) & (width>=0) THEN
        o.oWidth:=U.MaxLong(width,o.oMinWidth);
        o.width:=o.oWidth-o.objectFrame.leftBorder-o.objectFrame.rightBorder;
      END;
      IF (verticalFlex IN o.flags) & (height>=0) THEN
        o.oHeight:=U.MaxLong(height,o.oMinHeight);
        o.height:=o.oHeight-o.objectFrame.topBorder-o.objectFrame.bottomBorder;
      END;
    END;

    IF (oldOWidth#o.oWidth) OR (oldOHeight#o.oHeight) THEN
      o.layouted:=FALSE;
    END;
  END Resize;

  PROCEDURE (o : Object) SetRelayout*;

  BEGIN
    o.layouted:=FALSE;
  END SetRelayout;

  PROCEDURE (o : Object) Layout*;

  BEGIN
    o.layouted:=TRUE;
  END Layout;

  PROCEDURE (o : Object) DrawDisabled*;

    (**
      This is just a convinience function. Call this if your are a gadget and want
      to show yourself disabled. It draws a pattern over the bound of the gadget.

      Not that this is just a proposal. You can of cause use other methods to show
      yourself disabled, but keep some style guide in mind.
    *)

  VAR
    draw : D.DrawInfo;

  BEGIN
    draw:=o.GetDrawInfo();

    draw.PushForeground(D.disabledColor);
    draw.PushBitmap(D.smallChess,D.fgPattern);
    draw.FillRectangle(o.oX,o.oY,o.oWidth,o.oHeight);
    draw.PopBitmap;
    draw.PopForeground;
  END DrawDisabled;

  PROCEDURE (o : Object) DrawBackgroundWithDrawInfo*(draw : D.DrawInfo;
                                                     xRel,yRel,
                                                     x,y,w,h : LONGINT);
    (**
      This is just a convenience function. Draws the given rectangle using the
      current background of the object.
    *)

  VAR
    object : Object;

  BEGIN
    object:=o;
    WHILE (object#NIL) &
      ((object.backgroundObject=NIL) OR ~object.backgroundObject.CanDraw(draw)) DO
      object:=object.parent;
    END;

    IF object#NIL THEN
      object.backgroundObject.Draw(draw,
                                   xRel+object.x-o.x,yRel+object.y-o.y,
                                   object.width,object.height,
                                   x,y,w,h);
    ELSE
      IF D.selected IN draw.mode THEN
        draw.PushForeground(D.fillColor);
        draw.FillRectangle(x,y,w,h);
        draw.PopForeground;
      ELSE
        draw.PushForeground(D.backgroundColor);
        draw.FillRectangle(x,y,w,h);
        draw.PopForeground;
      END;
    END;
  END DrawBackgroundWithDrawInfo;

  PROCEDURE (o : Object) DrawBackground*(x,y,w,h : LONGINT);

    (**
      This is just a convenience function. Draws the given rectangle using the
      current background of the object.
    *)

  BEGIN
    o.DrawBackgroundWithDrawInfo(o.GetDrawInfo(),o.x,o.y,x,y,w,h);
  END DrawBackground;

  PROCEDURE (o : Object) DrawParentBackgroundWithDrawInfo*(draw : D.DrawInfo;
                                                           xRel,yRel,
                                                           x,y,w,h : LONGINT);
    (**
      This is just a convenience function. Draws the given rectangle using the
      current background of the parent object.
    *)

  VAR
    set : BOOLEAN;

  BEGIN
    set:=D.selected IN draw.mode;
    IF set THEN
      EXCL(draw.mode,D.selected);
    END;

    IF o.parent#NIL THEN
      o.parent.DrawBackgroundWithDrawInfo(draw,xRel,yRel,x,y,w,h);
    ELSE
      draw.PushForeground(D.backgroundColor);
      draw.FillRectangle(x,y,w,h);
      draw.PopForeground;
    END;

    IF set THEN
      INCL(draw.mode,D.selected);
    END;
  END DrawParentBackgroundWithDrawInfo;

  PROCEDURE (o : Object) DrawParentBackground*(x,y,w,h : LONGINT);

    (**
      This is just a convenience function. Draws the given rectangle using the
      current background of the parent object.
    *)

  BEGIN
    o.DrawParentBackgroundWithDrawInfo(o.GetDrawInfo(),o.x,o.y,x,y,w,h);
  END DrawParentBackground;

  PROCEDURE (o : Object) Draw*(x,y,w,h : LONGINT);
  (**
    Tells the object to draw itself at the given position and with the mode
    set in draw.mode.

    You can igonore modes you do not support and simply assume mode=normal.

    You *must* call the Draw-method of your superclass first!
  *)

  VAR
    draw : D.DrawInfo;
    a,b,
    c,d  : LONGINT;

  BEGIN
    o.visible:=TRUE;

    IF ~o.layouted THEN
      o.Layout;
    END;

    draw:=o.GetDrawInfo();

    IF o.MayFocus() & o.StdFocus() & (o.focus#NIL) THEN
      IF o.DisplayFocus() THEN
        o.focus.Draw(draw,o.oX,o.oY,o.oWidth,o.oHeight);
      ELSE
        draw.InstallClip(o.oX,o.oY,o.oWidth,o.oHeight);
        draw.SubRegion(o.oX+o.focus.leftBorder,
                       o.oY+o.focus.topBorder,
                       o.oWidth-o.focus.leftBorder-o.focus.rightBorder,
                       o.oHeight-o.focus.topBorder-o.focus.bottomBorder);
        o.DrawParentBackground(o.oX,o.oY,o.oWidth,o.oHeight);
        draw.FreeLastClip;
      END;
    END;

    a:=o.x-o.objectFrame.leftBorder;
    b:=o.y-o.objectFrame.topBorder;
    c:=o.width+o.objectFrame.leftBorder+o.objectFrame.rightBorder;
    d:=o.height+o.objectFrame.topBorder+o.objectFrame.bottomBorder;

    IF o.objectFrame.alpha THEN
      draw.InstallClip(a,b,c,d);
      draw.SubRegion(o.x,o.y,o.width,o.height);
      o.DrawParentBackground(a,b,c,d);
      o.objectFrame.Draw(draw,a,b,c,d);
      draw.FreeLastClip;
    ELSE
      o.objectFrame.Draw(draw,a,b,c,d);
    END;
  END Draw;

  PROCEDURE (o : Object) Move*(x,y : LONGINT);
  (**
  *)

  VAR
    oldOX,oldOY : LONGINT;

  BEGIN
    oldOX:=o.oX;
    oldOY:=o.oY;

    o.oX:=x;
    o.oY:=y;

    o.x:=x;
    o.y:=y;

    IF o.MayFocus() & o.StdFocus() THEN
      INC(o.x,o.focus.leftBorder);
      INC(o.y,o.focus.topBorder);
    END;

    INC(o.x,o.objectFrame.leftBorder);
    INC(o.y,o.objectFrame.topBorder);

    IF (oldOX#o.oX) OR (oldOY#o.oY) THEN
      o.layouted:=FALSE;
    END;
  END Move;

  PROCEDURE (o : Object) MoveResize*(x,y,width,height : LONGINT);

  BEGIN
    o.Move(x,y);
    o.Resize(width,height);
  END MoveResize;

  PROCEDURE (o : Object) Redraw*;
  (**
    Tells the object to redraw itself
    You normally do not need to overload this method.
  *)

  BEGIN
    IF o.visible THEN
      o.Draw(o.oX,o.oY,o.oWidth,o.oHeight);
    END;
  END Redraw;

  PROCEDURE (o : Object) Intersect*(x,y,w,h : LONGINT):BOOLEAN;
  (**
    Returns TRUE if the two areas intersect, else FALSE.
  *)

  BEGIN
    RETURN ~((y+h-1<o.oY) (* above *)
             OR (y>o.oY+o.oHeight-1) (* under *)
             OR (x+w-1<o.oX) (* left *)
             OR (x>o.oX+o.oWidth-1)); (* right *)
  END Intersect;

  PROCEDURE (o : Object) Disable*(disable : BOOLEAN);
  (**
    Disable the object.
    The object should show it's disabled state via it's
    visual apperance.
  *)

  VAR
    window : D.Window;

  BEGIN
    IF o.disabled#disable THEN
      o.disabled:=disable;

      IF o.disabled THEN
        window:=o.GetWindow();
        IF window#NIL THEN
          window.FocusNext();
        END;
      END;

      o.Redraw;
    END;
  END Disable;

  PROCEDURE (o : Object) Hide*;
  (**
    Tell the object to hide itself.
    The space of the object should have the backgroundcolor after hiding.

    The method of the baseclass simply sets Object.visible to FALSE. If you
    implement your own object, you must overload this methods and hide all
    possibly existing child objects. After that call
    Object.Hide of your baseclass. Since Object.Hide may have other purposes
    in the future, too.

    NOTE
    Hide is not expected to clean the area it covers when @oproc{o.Hide} is
    called (It doesn't hurt though). It is expected that the parent object
    (or window if the top most object is hidden) handles hiding of an object.
    It must show anothe robject in place or must clean the area itself.

    While the parent should only call @oproc{o.Hide} if the object is not
    already hidden, you should check for @ofield{o.visible} before doing
    anything.
  *)

  VAR
    window : D.Window;

  BEGIN
    o.visible:=FALSE;

    (* Tell the window, that the focus object hides *)
    IF o.HasFocus() THEN
      window:=o.GetWindow();
      window.FocusNext();
    END;
  END Hide;

  PROCEDURE (o : Object) DrawFocus*;
  (**
    This method gets called when the window thinks, that the
    object should show somekind of keyboardfocus. This will
    happen, when the object gets the focus, or when the
    focus has to be refreshed because of a window refresh.

    NOTE
    You can use the supplied focusFrame but you need not to do.
    The baseclass does nothing.
  *)

  BEGIN
    IF o.focus#NIL THEN
      o.focus.Draw(o.GetDrawInfo(),o.oX,o.oY,o.oWidth,o.oHeight);
    END;
  END DrawFocus;

  PROCEDURE (o : Object) HideFocus*;
  (**
    This method gets called when the window thinks, that the
    object should hide the keyboardfocus. This happens when
    the object loses the focus.
  *)

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF o.focus#NIL THEN
      draw:=o.GetDrawInfo();
      draw.InstallClip(o.oX,o.oY,o.oWidth,o.oHeight);
      draw.SubRegion(o.oX+o.focus.leftBorder,
                     o.oY+o.focus.topBorder,
                     o.oWidth-o.focus.leftBorder-o.focus.rightBorder,
                     o.oHeight-o.focus.topBorder-o.focus.bottomBorder);
      o.DrawParentBackground(o.oX,o.oY,o.oWidth,o.oHeight);
      draw.FreeLastClip;
    END;
  END HideFocus;

  PROCEDURE (o : Object) LeaveFocus*;
  (**
    Ask the window to change the focus to the next entry.
    This is usefull f.e. for stringgadgets. If you enter return, the
    gadget should get deactivated and the focus should change to the
    next element.

    NOTE
    The object must have the focus, otherwise nothing will happen.
  *)

  VAR
    window : D.Window;

  BEGIN
    IF o.HasFocus() THEN
      window:=o.GetWindow();
      window.FocusNext;
    END;
  END LeaveFocus;

  PROCEDURE (o : Object) PointIsIn*(x,y : LONGINT):BOOLEAN;
  (**
    Ask the object, if the given point it in its bounds.
    We also check if the pointer is within the bounds of the
    label of the object, if the object has one.
  *)

  BEGIN
    IF ~o.visible THEN
      RETURN FALSE;
    END;

    RETURN (x>=o.oX) & (y>=o.oY) & (x<=o.oX+o.oWidth-1) & (y<=o.oY+o.oHeight-1);
  END PointIsIn;

  PROCEDURE (o : Object) MouseIsIn*():BOOLEAN;
  (**
    Tells if the mouse pointer is currently ober the object.
    We also check if the mouse pointer is within the bounds of the
    label of the object, if the object has one.
  *)

  VAR
    rx,ry,
    wx,wy  : LONGINT;
    window : D.Window;

  BEGIN
    IF ~o.visible OR o.disabled THEN
      RETURN FALSE;
    ELSE
      window:=o.GetWindow();
      window.GetMousePos(rx,ry,wx,wy);
      RETURN o.PointIsIn(wx,wy);
    END;
  END MouseIsIn;

  PROCEDURE (g : Object) HandleMouseEvent*(event : E.MouseEvent;
                                           VAR grab : Object):BOOLEAN;
  (**
    Handles Mouse events.

    Returns true, if the object has handled the event.

    If the objects want to grab mouse events (directly receive mouseevents),
    it must store itself in grab. If it wants to loose the grab, it must
    set grab to NIL.
  *)

  BEGIN
    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (o : Object) GetDnDObject*(x,y : LONGINT; drag : BOOLEAN):Object;
  (**
    Returns the object that coveres the given point and that supports
    drag and drop of data.

    If drag is TRUE, when want to find a object that we can drag data from,
    else we want an object to drop data on.
  *)

  BEGIN
    RETURN NIL;
  END GetDnDObject;

  PROCEDURE (o : Object) Free*;
  (**
    This method frees all ressources bound to this object instance if
    the window holding this object will be closed.

    Don't free dependent child objects. Since a @otype{VisitorDesc} will
    be for freeing the object tree you do not have to call @oproc{Object.Free}
    for your child objects if they are in reach for the Visitor. That
    will be done for you.
  *)
  BEGIN
(*    o.backgroundObject.Free;
    o.selectionObject.Free;*)
  END Free;

  (* -------------------------------------------- *)

  PROCEDURE (VAR v : FreeVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    IF object.VisitChildren(v,FALSE) THEN END;
    RETURN TRUE;
  END Visit;

  PROCEDURE (VAR v : SubRegionVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    v.draw.SubRegion(object.oX,object.oY,object.oWidth,object.oHeight);

    RETURN TRUE;
  END Visit;

  PROCEDURE (VAR v : DisableVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    object.Disable(v.disable);

    RETURN TRUE;
  END Visit;

  PROCEDURE (VAR v : HideVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    object.Hide;

    RETURN TRUE;
  END Visit;

  PROCEDURE (VAR v : MouseEventVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    RETURN ~object.HandleMouseEvent(v.event,v.grab);
  END Visit;

  PROCEDURE (VAR v : GetDnDVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    v.object:=object.GetDnDObject(v.x,v.y,v.drag);
    RETURN v.object=NIL;
  END Visit;

  (* -------------------------------------------- *)

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=NIL;
    p.frame:=F.CreateFrame(F.none);
    p.hSize.Init;
    p.vSize.Init;
  END Initialize;

  PROCEDURE (p : Prefs) Free*;

  BEGIN
    IF p.background#NIL THEN
      p.background.Free;
      p.background:=NIL;
    END;

    p.Free^;
  END Free;


  (* -------------------------------------------- *)

  PROCEDURE (o : Control) SetModel * (m : O.Model);
  (**
    This method connects a model to the control.
   *)

  BEGIN
  END SetModel;

  PROCEDURE (o : Control) ModelAccepted * (m : O.Model):BOOLEAN;
  (**
    As SetModel is too general to guarantee that the model
    is accepted, we need to check the result. This is done by
    ModelAccepted. It returns true if the actual model is the
    same as the argument. This has to be implemented by real
    views.
   *)

  BEGIN
    RETURN FALSE
  END ModelAccepted;

  (* ----------------------------------- *)

  PROCEDURE (g : Gadget) CatchedFocus*;
  (**
    Called, when you got the keyboard focus.
  *)

  BEGIN
    INCL(g.flags,hasFocus);
    g.DrawFocus;
  END CatchedFocus;

  PROCEDURE (g : Gadget) RecatchedFocus*;
  (**
    Called, when you got the keyboard focus.
  *)

  BEGIN
    INCL(g.flags,hasFocus);
    g.DrawFocus;
  END RecatchedFocus;

  PROCEDURE (g : Gadget) LostFocus*;
  (**
    Call, when the keyboard focus has been taken away from you.
  *)

  BEGIN
    EXCL(g.flags,hasFocus);
    g.HideFocus;
  END LostFocus;

  PROCEDURE (g : Gadget) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;
  (**
    This gets called, when you have the current keyboard focus and
    the users presses keys. You can expect to get only keyboard events.

    RESULT
    Return TRUE if you have handled the event, else FALSE.

    NOTE
    If you activtly have grabed the focus using Object.GetFocus and
    Object.handleEvent you will get the keyboardevents there. This
    function gets only called when you don't grabed the focus.
  *)

  VAR
    desc   : STRING;
    name   : ARRAY 256 OF CHAR;
    action : LONGINT;

  BEGIN
    IF event.type=E.keyDown THEN
      IF g.controller#NIL THEN
        event.GetName(name);
        D.display.KeyToKeyDescription(event.qualifier,OB.NewLatin1(name),desc);
        action:=g.controller.GetActionForKey(desc);
        IF action#actionNone THEN
          IF g.controller.DoAction(g,action) THEN
            RETURN TRUE;
          END;
        END;
      END;
    END;

    RETURN FALSE;
  END HandleKeyEvent;

  (* ----------------------------------- *)

  PROCEDURE (g : Layout) Disable*(disable : BOOLEAN);
    (**
      Disables all elements of the group object.
      Note, that inherited group objects may interpret beeing disabled
      different. VOTab f.e. disables itself.
    *)

  VAR
    visitor : DisableVisitorDesc;

  BEGIN
    visitor.disable:=disable;

    IF g.VisitChildren(visitor,FALSE) THEN END;
  END Disable;

  PROCEDURE (g : Layout) HandleMouseEvent*(event : E.MouseEvent;
                                           VAR grab : Object):BOOLEAN;
  (**
    The defaulthandler ask all members of the layout object for the focus.
  *)

  VAR
    visitor : MouseEventVisitorDesc;
    res     : BOOLEAN;

  BEGIN
    IF ~g.visible OR g.disabled THEN
      RETURN FALSE;
    END;

    visitor.event:=event;
    visitor.grab:=NIL;
    res:=~g.VisitChildren(visitor,TRUE);

    grab:=visitor.grab;

    RETURN res;
  END HandleMouseEvent;

  PROCEDURE (g : Layout) GetDnDObject*(x,y : LONGINT; drag : BOOLEAN):Object;
  (**
    Returns the object that coveres the given point and that supports
    drag and drop of data.

    If drag is TRUE, when want to find a object that we can drag data from,
    else we want an object to drop data on.
  *)

  VAR
    visitor : GetDnDVisitorDesc;

  BEGIN
    IF ~g.visible OR g.disabled THEN
      RETURN NIL;
    END;

    visitor.x:=x;
    visitor.y:=y;
    visitor.drag:=drag;
    visitor.object:=NIL;
    IF g.VisitChildren(visitor,TRUE) THEN END;

    IF visitor.object#NIL THEN
      RETURN visitor.object;
    ELSE
      RETURN g.GetDnDObject^(x,y,drag);
    END;
  END GetDnDObject;

  PROCEDURE (g : Layout) PreDrawChild*(child : Object);

  BEGIN
  END PreDrawChild;

  PROCEDURE (g : Layout) PostDrawChild*(child : Object);

  BEGIN
  END PostDrawChild;

  PROCEDURE (VAR v : DrawVisitorDesc) Visit*(object : Object):BOOLEAN;

  BEGIN
    v.layout.PreDrawChild(object);
    object.Draw(v.x,v.y,v.width,v.height);
    v.layout.PostDrawChild(object);

    RETURN TRUE;
  END Visit;


  PROCEDURE (g : Layout) Draw*(x,y,w,h : LONGINT);

  VAR
    draw        : D.DrawInfo;
    subVisitor  : SubRegionVisitorDesc;
    drawVisitor : DrawVisitorDesc;

  BEGIN
    IF ~g.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    g.Draw^(x,y,w,h);

    draw:=g.GetDrawInfo();

    draw.InstallClip(x,y,w,h);

    subVisitor.draw:=draw;
    IF g.VisitChildren(subVisitor,TRUE) THEN END;

    g.DrawBackground(g.x,g.y,g.width,g.height);

    draw.FreeLastClip;

    drawVisitor.layout:=g;
    drawVisitor.x:=x;
    drawVisitor.y:=y;
    drawVisitor.width:=w;
    drawVisitor.height:=h;

    IF g.VisitChildren(drawVisitor,TRUE) THEN END;
  END Draw;

  PROCEDURE (g : Layout) Hide*;

  VAR
    visitor : HideVisitorDesc;

  BEGIN
    IF g.visible THEN
      IF g.VisitChildren(visitor,TRUE) THEN END;
      g.Hide^;
    END;
  END Hide;

  PROCEDURE (g : Layout) Free*;

  VAR
    visitor : FreeVisitorDesc;

  BEGIN
    IF g.VisitChildren(visitor,TRUE) THEN END;

    g.Free^;
  END Free;

  (* ----------------------------------- *)

  PROCEDURE (g : Group) Init*;
  (**
    A group object is derived from Object. Its purpurse is to collect a list
    of object and represent them to the outer space as one object.
    It has some more methods and attributs.

    The relative layout of the list of children is left to the implementation
    of the derived classes.
  *)

  BEGIN
    g.Init^;

    g.count:=0;
    g.list:=NIL;
  END Init;

  PROCEDURE (g : Group) VisitChildren*(VAR visitor : VisitorDesc;
                                       onlyVisible : BOOLEAN):BOOLEAN;

    (**
      This implementation will iterate over the internal list of children.
    *)

  VAR
    entry : Object;

  BEGIN
    entry:=g.list;
    WHILE (entry#NIL) DO
      IF ~visitor.Visit(entry) THEN
        RETURN FALSE;
      END;
      entry:=entry.next;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (g : Group) Add*(object : Object);
  (**
    Add a new Object to the group
    Removing objects is currently not supported

    Note that some group-objects have a more special functions for adding
    members. However Add should always be supported
  *)

  BEGIN
    IF g.list=NIL THEN
      g.list:=object;
    ELSE
      g.last.next:=object;
    END;
    g.last:=object;
    object.SetParent(g);
    INC(g.count);
  END Add;

  PROCEDURE (s : ScrollableGadget) Init*;

  BEGIN
    s.Init^;

    s.hAdjustment:=A.CreateAdjustment();
    s.AttachModel(s.hAdjustment.GetTopModel());

    s.vAdjustment:=A.CreateAdjustment();
    s.AttachModel(s.vAdjustment.GetTopModel());
  END Init;

  PROCEDURE  GetAlignment*(name : ARRAY OF CHAR):LONGINT;
  (**
    Returns the alignment value corresponding to the the given string value.
    Returns -1, if the string contains no valid alignment name.
  *)

  VAR
    x : LONGINT;

  BEGIN
    FOR x:=0 TO alignmentCount-1 DO
      IF alignments[x]=name THEN
        RETURN x;
      END;
    END;
    RETURN -1;
  END GetAlignment;

BEGIN
  alignments[alignLeft]:="alignLeft";
  alignments[alignCenter]:="alignCenter";
  alignments[alignRight]:="alignRight";
  alignments[alignBound]:="alignBound";
  alignments[alignTop]:="alignTop";
  alignments[alignBottom]:="alignBottom";
END VO:Object.