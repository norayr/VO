MODULE VO:Menu;

  (**
    Implements popup menues.

    Some implementation details:
    Menu handling works by grabing the mouse cursor. The first window that
    popups up (either the direct @otype{PullDownMenu} from a @otype{MenuStrip}
    or the popup menu opening on mouse menu button click) grabs the mouse
    and controls opening and closing of all subwindows.

    It is also responsible for triggering redraw, if the selection changes.

    It is also responsible for handling events for the menu strip while
    its window is open.
  *)

  (*
    Implements menues.
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


IMPORT BG  := VO:Base:Background,
       D   := VO:Base:Display,
       E   := VO:Base:Event,
       F   := VO:Base:Frame,
       I   := VO:Base:Image,
       O   := VO:Base:Object,
       U   := VO:Base:Util,
       VB  := VO:Base:VecImage,

       G   := VO:Object,
       T   := VO:Text,
       W   := VO:Window,

              Object;

CONST
  selectedMsg * = 0; (** Send if a menuitem has been selected *)

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 arrow*      : I.Image;
                 menuFrame*,                 (** the frame to use for the menu *)
                 stripFrame* : F.Frame;      (** the frame to use for the menustrip *)
                 bgPulldown* : G.Background; (** the background for pulldown menues *)
               END;

  (* menu stuff *)

  Menu*         = POINTER TO MenuDesc;

  (* Menustrip stuff *)

  MenuStrip*     = POINTER TO MenuStripDesc;
  MenuStripDesc* = RECORD (G.GroupDesc)
                     (**
                       Always visible menu bar containing a number of
                       pulldown menues which in turn can contain any number of
                       menu items and sub menues.
                     *)
                     selection : Menu;
                     stickyMode  : BOOLEAN;
                   END;

  PullDownMenu     = POINTER TO PullDownMenuDesc;
  PullDownMenuDesc = RECORD (G.GadgetDesc);
                       (**
                         Entry for a menu strip.
                       *)
                       label   : G.Image;
                       subMenu : Menu;
                       strip   : MenuStrip;
                       sc      : UCS4CHAR;
                     END;

  (* menu stuff *)

  MenuEntry*    = POINTER TO MenuEntryDesc;
  MenuEntryDesc = RECORD (G.GadgetDesc)
                    (**
                      Common base class for all menu entries.
                    *)
                    w1,w2  : LONGINT;
                    menu   : Menu;
                    sc     : UCS4CHAR;
                  END;

  MenuItem*     = POINTER TO MenuItemDesc;
  MenuItemDesc  = RECORD (MenuEntryDesc)
                    (**
                      A selectable emnu item for a menu.
                    *)
                    label,
                    shortcut  : G.Object;
                    qualifier : SET;
                    key       : STRING;
                  END;

  MenuTitle*    = POINTER TO MenuTitleDesc;
  MenuTitleDesc = RECORD (MenuEntryDesc)
                    (**
                      A (non-selectable) menu title object as part of a
                      menu.
                    *)
                    label : G.Object;
                  END;

  Separator*    = POINTER TO SeparatorDesc;
  SeparatorDesc = RECORD (MenuEntryDesc)
                    (**
                      A separator for a menu.
                    *)
                  END;

  SubMenu*      = POINTER TO SubMenuDesc;
  SubMenuDesc   = RECORD(MenuEntryDesc)
                    (**
                      A special menu entry that opens a new sub menu.
                    *)
                    label   : G.Object;
                    arrow   : I.Image;
                    subMenu : Menu;
                  END;

  MenuBox       = POINTER TO MenuBoxDesc;
  MenuBoxDesc   = RECORD (G.GroupDesc)
                    (**
                      Conatiner for a list of menu entries.
                    *)
                  END;

  MenuDesc*     = RECORD (D.WindowDesc)
                    prefs            : Prefs;
                    parentMenu       : SubMenu;   (** Parent menu *)

                    child            : Menu;      (** Currently open child menu *)

                    top              : MenuBox;   (** Layout container object *)

                    selected         : MenuEntry; (** The currently selected entry *)

                    (* Pulldown stuff *)
                    reference        : G.Object;
                    strip            : MenuStrip; (** If #NIL this is a pulldown menu and points to the menu strip *)
                    pWindow          : D.Window;  (** Parent window *)

                    popup            : BOOLEAN;   (** Top menu of a popup menu *)
                    registered       : BOOLEAN;
                  END;

  SelectedMsg*     = POINTER TO SelectedMsgDesc;
  SelectedMsgDesc* = RECORD (O.MessageDesc)
                       (**
                         Message that will be send, if a menu item has been
                         selected.
                       *)
                       id* : LONGINT; (**
                                        Previously assigned id of the selected
                                        menu item.
                                       *)
                     END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.arrow:=I.CreateVecImage(VB.simpleRight);
      p.menuFrame:=F.CreateFrame(F.single);
      p.stripFrame:=F.CreateFrame(F.none);
    ELSE
      p.arrow:=I.CreateVecImage(VB.arrowRight);
      p.menuFrame:=F.CreateFrame(F.double3DOut);
      p.stripFrame:=F.CreateFrame(F.double3DOut);
    END;

    p.bgPulldown:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.buttonBackgroundColorIndex));
  END Initialize;

  (* ---------- Menu stuff ------------------*)

  PROCEDURE (m : Menu) Init*;

  BEGIN
    m.Init^;

    m.prefs:=prefs;   (* We set the prefs *)

    m.SetType(D.windowTypeMenu);

    m.selected:=NIL;
    m.parentMenu:=NIL;
    m.child:=NIL;
    m.reference:=NIL;
    m.strip:=NIL;
    m.popup:=TRUE;
    m.registered:=FALSE;

    m.pWindow:=NIL;

    NEW(m.top);
    m.top.Init;
    m.top.SetWindow(m);
  END Init;

  (* ---------- Pulldown menu ------------------*)

  PROCEDURE (m : PullDownMenu) Init*;

  BEGIN
    m.Init^;

    m.SetPrefs(prefs);

    m.SetFlags({G.horizontalFlex,G.verticalFlex});
    m.label:=NIL;
    m.subMenu:=NIL;
    m.sc:=0X;
  END Init;

  PROCEDURE (m : PullDownMenu) SetLabel(label : G.Image);

  BEGIN
    m.label:=label;
    m.label.SetParent(m);
  END SetLabel;

  PROCEDURE (m : PullDownMenu) SetHotkey(sc : UCS4CHAR);

  BEGIN
    m.sc:=sc;
  END SetHotkey;

  (* ---------- Menustrip stuff ------------------*)

  PROCEDURE (m : MenuStrip) Init*;

  BEGIN
    m.Init^;

    m.SetFlags({G.horizontalFlex});

    m.SetPrefs(prefs);

    m.SetObjectFrame(m.prefs(Prefs).stripFrame);
    m.selection:=NIL;
    m.stickyMode:=FALSE;
  END Init;

  PROCEDURE (m : MenuStrip) FindLabel(menu : Menu):G.Object;

  VAR
    object : G.Object;

  BEGIN
    object:=m.list;
    WHILE object#NIL DO
      IF object(PullDownMenu).subMenu=menu THEN
        RETURN object;
      END;
      object:=object.next;
    END;
    RETURN NIL;
  END FindLabel;

  PROCEDURE (m : MenuStrip) SetSelection(new : Menu);

    (**
      Select the given (direct) sub menu.
    *)

  BEGIN
    IF (m.selection#NIL) & m.selection.IsOpen() THEN
      m.selection.Close;
    END;
    m.selection:=new;
    IF m.selection#NIL THEN
      IF m.selection.Open() THEN END;
    END;
    m.Redraw;
  END SetSelection;

  PROCEDURE (m : MenuStrip) SelectPrevious;

    (**
      Select the previous entry in the menu strip.
    *)

  VAR
    prev,
    object : G.Object;

  BEGIN
    IF m.selection=NIL THEN
      RETURN;
    END;

    object:=m.FindLabel(m.selection);

    prev:=m.list;
    IF prev=object THEN
      WHILE prev.next#NIL DO
        prev:=prev.next;
      END;
      m.SetSelection(prev(PullDownMenu).subMenu);
    ELSE
      WHILE prev.next#object DO
        prev:=prev.next;
      END;
      m.SetSelection(prev(PullDownMenu).subMenu);
    END;
  END SelectPrevious;

  PROCEDURE (m : MenuStrip) SelectNext;

    (**
      Select the next entry in the menu strip.
    *)

  VAR
    object : G.Object;

  BEGIN
    IF m.selection=NIL THEN
      RETURN;
    END;

    object:=m.FindLabel(m.selection);

    IF (object.next#NIL) THEN
      m.SetSelection(object.next(PullDownMenu).subMenu);
    ELSIF m.list#NIL THEN
      m.SetSelection(m.list(PullDownMenu).subMenu);
    END;
  END SelectNext;

  PROCEDURE (m : MenuStrip) GetMouseSelected():G.Object;

    (**
      Return the (label) object currently unde rthe mouse or
      @code{NIL}, if there is no label under the mouse.
    *)

  VAR
    object : G.Object;

  BEGIN
    object:=m.list;
    WHILE (object#NIL) & ~ object.MouseIsIn() DO
      object:=object.next;
    END;

    RETURN object;
  END GetMouseSelected;

  PROCEDURE (m : MenuStrip) AddPullDownMenu*(label : G.Image;
                                             sc : UCS4CHAR;
                                             subMenu : Menu);

  VAR menu : PullDownMenu;

  BEGIN
    NEW(menu);
    menu.Init;
    menu.SetLabel(label);
    menu.SetHotkey(sc);
    menu.subMenu:=subMenu;
    menu.strip:=m;

    subMenu.strip:=m;
    subMenu.reference:=menu;

    m.Add(menu);
  END AddPullDownMenu;

  PROCEDURE (m : MenuStrip) AddPullDownMenuString*(title   : STRING;
                                                   subMenu : Menu);

  VAR
    text  : T.Text;
    sc,x,
    length : LONGINT;
    char   : UCS4CHAR;

  BEGIN
    sc:=-1;
    char:=0X;

    length:=title.length;
    x:=0;
    WHILE x<length DO
      CASE title.CharAt(x) OF
      | "_" :
        IF x+1<length THEN
          sc:=x;
          char:=CHR(ORD(title.CharAt(x+1)));
        END;
      ELSE
      END;
      INC(x);
    END;

    IF sc>=0 THEN
      title:=title.Substring(0,sc)+
      "\eu"+title.Substring(sc+1,sc+2)+
      "\en"+title.Substring(sc+2,length);
    END;

    text:=T.MakeCenterString(title);
    text.SetFlags({G.horizontalFlex,G.verticalFlex});
    m.AddPullDownMenu(text,char,subMenu);
  END AddPullDownMenuString;

  PROCEDURE (m : MenuStrip) CalcSize*;

  VAR
    object : G.Object;

  BEGIN
    m.width:=0;
    m.height:=0;

    object := m.list;
    WHILE object#NIL DO
      object.CalcSize;
      object.Resize(object.oWidth + 2 * D.display.spaceWidth, - 1);
      m.height:=U.MaxLong(m.height,object.oHeight);
      INC(m.width,object.oWidth);

      object:=object.next;
    END;

    INC(m.height,D.display.spaceHeight);
    m.CalcSize^;
  END CalcSize;

  PROCEDURE (m : MenuStrip) Layout*;

  VAR
    pos    : LONGINT;
    object : G.Object;

  BEGIN
    pos:=m.x;
    object:=m.list;
    WHILE object#NIL DO
      object.Resize(-1,m.height);
      object.Move(pos,m.y + (m.height-object.oHeight) DIV 2);
      INC(pos,object.oWidth);

      object:=object.next;
    END;

    m.Layout^;
  END Layout;

  PROCEDURE (m : MenuStrip) PreDrawChild*(child : G.Object);

  VAR
    draw : D.DrawInfo;

  BEGIN
    draw:=m.GetDrawInfo();

    IF child=m.FindLabel(m.selection) THEN
      draw.mode:={D.selected};
    END;
  END PreDrawChild;

  PROCEDURE (m : MenuStrip) PostDrawChild*(child : G.Object);

  VAR
    draw : D.DrawInfo;

  BEGIN
    draw:=m.GetDrawInfo();
    draw.mode:={};
  END PostDrawChild;

  (* ---------- PullDownMenu stuff ------------------*)

  PROCEDURE (m : PullDownMenu) CalcSize*;

  VAR
    window : D.Window;

  BEGIN
    m.label.CalcSize;

    m.width:=m.label.width;
    m.height:=m.label.height;

    window:=m.GetWindow();
    m.subMenu.SetParent(window);
    IF (m.sc#0X) & (window IS W.Window) THEN
      window(W.Window).RegisterShortcut(m.strip,E.altMask,Object.NewUCS4Char(m.sc),0,m);
    END;

    m.CalcSize^;
  END CalcSize;

  PROCEDURE (m : PullDownMenu) Layout*;

  BEGIN
    m.label.Resize(m.width,m.height);
    m.label.Move(m.x,m.y);

    m.Layout^;
  END Layout;

  PROCEDURE (m : PullDownMenu) HandleMouseEvent*(event : E.MouseEvent;
                                                 VAR grab : G.Object):BOOLEAN;

  BEGIN
    IF ~m.visible OR m.disabled THEN
      RETURN FALSE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & m.PointIsIn(event.x,event.y)
        & ((event.button=E.button1) OR (event.button=E.button3)) THEN
        m.strip.SetSelection(m.subMenu);
      END;
    | event : E.MotionEvent DO
      IF ~m.subMenu.IsOpen() THEN
        IF m.PointIsIn(event.x,event.y) THEN
          IF ({E.button1}=event.qualifier) OR ({E.button3}=event.qualifier) OR
            m.strip.stickyMode THEN
            m.strip.SetSelection(m.subMenu);
          END;
        END;
      END;
    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (m : PullDownMenu) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~m.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    m.Draw^(x,y,w,h);

    m.DrawBackground(m.x,m.y,m.width,m.height);

    m.label.Draw(x,y,w,h);
  END Draw;

  PROCEDURE (m : PullDownMenu) Hide*;

  BEGIN
    IF m.visible THEN
      m.label.Hide;
    END;
    m.Hide^;
  END Hide;

  PROCEDURE (m : PullDownMenu) Receive*(message : O.Message);

  BEGIN
    WITH message : W.ShortcutMsg DO
      IF message.state=W.shortcutReleased THEN
        m.strip.stickyMode:=TRUE;
        m.strip.SetSelection(m.subMenu);
      END;
    ELSE
      m.Receive^(message);
    END;
  END Receive;

  (* ---------- Menu stuff ------------------*)

  PROCEDURE (e : MenuEntry) Init*;

  BEGIN
    e.Init^;

    e.SetPrefs(prefs);

    e.SetFlags({G.scAlways});

    e.w1:=0;
    e.w2:=0;
    e.menu:=NIL;
    e.sc:=0X;
  END Init;

  PROCEDURE (e : MenuEntry) SetHotkey(key : UCS4CHAR);

  BEGIN
    e.sc:=key;
  END SetHotkey;

  PROCEDURE (e : MenuEntry) RegisterToParentWindow(parent : D.Window);

  BEGIN
    (* no code *)
  END RegisterToParentWindow;

  PROCEDURE (i : MenuItem) Init*;

  BEGIN
    i.Init^;

    i.label:=NIL;
    i.shortcut:=NIL;
    i.qualifier:={};
    i.key:=NIL;
  END Init;

  PROCEDURE (i : MenuItem) SetLabel*(label : G.Object);

  BEGIN
    i.label:=label;
  END SetLabel;

  PROCEDURE (i : MenuItem) SetTextLabel*(label : STRING);

  VAR
    text  : T.Text;
    sc,x,
    length : LONGINT;
    char   : UCS4CHAR;

  BEGIN
    sc:=-1;
    char:=0X;

    length:=label.length;
    x:=0;
    WHILE x<length DO
      CASE label.CharAt(x) OF
      | "_" :
        IF x+1<length THEN
          sc:=x;
          char:=CHR(ORD(label.CharAt(x+1)));
        END;
      ELSE
      END;
      INC(x);
    END;

    IF sc>=0 THEN
      i.SetHotkey(label.CharAt(sc+1));
      label:=label.Substring(0,sc)+
      "\eu"+label.Substring(sc+1,sc+2)+
      "\en"+label.Substring(sc+2,length);
    END;

    text:=T.MakeLeftString(label);

    i.SetLabel(text);
  END SetTextLabel;

  PROCEDURE (i : MenuItem) SetShortcut*(qualifier : SET; key : STRING);

  VAR
    shortcut : STRING;

  BEGIN
    D.display.KeyToKeyDescription(qualifier,key,shortcut);
    i.shortcut:=T.MakeLeftString(shortcut);
    i.qualifier:=qualifier;
    i.key:=key;
  END SetShortcut;

  PROCEDURE (i : MenuItem) CalcSize*;

  BEGIN
    ASSERT(i.label#NIL);

    i.label.SetParent(i);
    i.label.SetFlags({G.horizontalFlex,G.verticalFlex});
    i.label.CalcSize;
    i.w1:=i.label.width+D.display.spaceWidth DIV 2;
    i.height:=i.label.height;

    IF i.shortcut#NIL THEN
      i.shortcut.SetParent(i);
      i.shortcut.SetFlags({G.horizontalFlex,G.verticalFlex});
      i.shortcut.CalcSize;
      i.w2:=i.shortcut.width+2*D.display.spaceWidth+D.display.spaceWidth DIV 2;
      i.height:=U.MaxLong(i.shortcut.height,i.label.height);
    ELSE
      i.w2:=D.display.spaceWidth DIV 2;
    END;

    i.width:=i.w1+i.w2;

    IF D.display.displayType#D.displayTypeTextual THEN
      INC(i.height,D.display.spaceHeight);
    END;

    i.CalcSize^;
  END CalcSize;

  PROCEDURE (i : MenuItem) Draw*(x,y,w,h : LONGINT);

  VAR
    draw   : D.DrawInfo;

  BEGIN
    IF ~i.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    i.Draw^(x,y,w,h);

    draw:=i.GetDrawInfo();

    IF i.menu.selected=i THEN
      INCL(draw.mode,D.selected);
    END;

    i.DrawBackground(i.x,i.y,i.width,i.height);

    i.label.Move(i.x+D.display.spaceWidth DIV 2,
                 i.y+(i.height-i.label.height) DIV 2);
    i.label.Draw(x,y,w,h);

    IF i.shortcut#NIL THEN
      i.shortcut.Move(i.x+i.w1+2*D.display.spaceWidth,
                      i.y+(i.height-i.shortcut.height) DIV 2);
      i.shortcut.Draw(x,y,w,h);
    END;

    draw.mode:={};
  END Draw;

  PROCEDURE (i : MenuItem) Receive*(message : O.Message);

  VAR
    menu     : Menu;
    help     : D.Window;
    selected : SelectedMsg;

  BEGIN
    WITH message : W.ShortcutMsg DO
      IF message.state=W.shortcutReleased THEN
        help:=i.GetMenuObject();
        menu:=help(Menu);
        NEW(selected);
        selected.id:=i.id;
        menu.Send(selected,selectedMsg);
      END;
    ELSE
      i.Receive^(message);
    END;
  END Receive;

  PROCEDURE (s : MenuItem) RegisterToParentWindow(parent : D.Window);

  BEGIN
    s.RegisterToParentWindow^(parent);

    IF s.key#NIL THEN
      ASSERT(parent#NIL);
      WITH parent : W.Window DO
        parent.RegisterShortcut(s,s.qualifier,s.key,s.id,NIL);
      ELSE
      END;
    END;
  END RegisterToParentWindow;

  (* MenuTitle *)

  PROCEDURE (i : MenuTitle) SetLabel*(label : G.Object);

  BEGIN
    i.label:=label;
  END SetLabel;

  PROCEDURE (i : MenuTitle) CalcSize*;

  BEGIN
    i.label.SetParent(i);
    i.label.SetFlags({G.horizontalFlex,G.verticalFlex});
    i.label.CalcSize;
    i.w1:=i.label.width+D.display.spaceWidth;
    i.height:=i.label.height+D.display.spaceHeight;
    INC(i.height,3);

    i.CalcSize^;
  END CalcSize;

  PROCEDURE (i : MenuTitle) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~i.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    i.Draw^(x,y,w,h);

    draw:=i.GetDrawInfo();

    i.DrawBackground(i.x,i.y,i.width,i.height);

    draw.mode:={};
    i.label.Move(i.x+(i.width-i.label.width) DIV 2,i.y);
    i.label.Draw(x,y,w,h);

    draw.PushForeground(D.shadowColor);
    draw.DrawLine(i.x,i.y+i.label.height,i.x+i.width-1,i.y+i.label.height);
    draw.PopForeground;

    draw.PushForeground(D.shineColor);
    draw.DrawLine(i.x,i.y+i.label.height+1,i.x+i.width-1,i.y+i.label.height+1);
    draw.PopForeground;
  END Draw;

  (* Separator *)

  PROCEDURE (s : Separator) CalcSize*;

  BEGIN
    s.w1:=2;
    IF D.display.displayType=D.displayTypeTextual THEN
      s.height:=1;
    ELSE
      s.height:=2+D.display.spaceHeight;
    END;

    s.CalcSize^;
  END CalcSize;

  PROCEDURE (s : Separator) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    draw:=s.GetDrawInfo();

    s.DrawBackground(s.x,s.y,s.width,s.height);

    IF D.display.displayType=D.displayTypeTextual THEN
    ELSE
      draw.PushForeground(D.shadowColor);
      draw.DrawLine(s.x,s.y+D.display.spaceHeight DIV 2,
                    s.x+s.width-1,s.y+D.display.spaceHeight DIV 2);
      draw.PopForeground;

      draw.PushForeground(D.shineColor);
      draw.DrawLine(s.x,s.y+1+D.display.spaceHeight DIV 2,
                    s.x+s.width-1,s.y+1+D.display.spaceHeight DIV 2);
      draw.PopForeground;
    END;
  END Draw;

  (* SubMenu *)

  PROCEDURE (s : SubMenu) SetLabel*(label : G.Object);

  BEGIN
    s.label:=label;
  END SetLabel;

  PROCEDURE (s : SubMenu) SetTextLabel*(label : STRING);

  VAR
    text  : T.Text;
    sc,x,
    length : LONGINT;
    char   : UCS4CHAR;

  BEGIN
    sc:=-1;
    char:=0X;

    length:=label.length;
    x:=0;
    WHILE x<length DO
      CASE label.CharAt(x) OF
      | "_" :
        IF x+1<length THEN
          sc:=x;
          char:=CHR(ORD(label.CharAt(x+1)));
        END;
      ELSE
      END;
      INC(x);
    END;

    IF sc>=0 THEN
      s.SetHotkey(label.CharAt(sc+1));
      label:=label.Substring(0,sc)+
      "\eu"+label.Substring(sc+1,sc+2)+
      "\en"+label.Substring(sc+2,length);
    END;

    text:=T.MakeLeftString(label);

    s.SetLabel(text);
  END SetTextLabel;

  PROCEDURE (s : SubMenu) SetMenu*(menu : Menu);

  BEGIN
    s.subMenu:=menu;
    s.subMenu.parentMenu:=s;
  END SetMenu;

  PROCEDURE (s : SubMenu) RegisterToParentWindow(parent : D.Window);

  BEGIN
    s.RegisterToParentWindow^(parent);

    s.subMenu.SetParent(parent);
  END RegisterToParentWindow;

  PROCEDURE (m : SubMenu) CalcSize*;

  BEGIN
    m.label.SetParent(m);
    m.label.SetFlags({G.horizontalFlex,G.verticalFlex});
    m.label.CalcSize;

    m.arrow:=m.prefs(Prefs).arrow;

    m.w1:=m.label.width+D.display.spaceWidth DIV 2;
    m.w2:=m.arrow.width+2*D.display.spaceWidth+D.display.spaceWidth DIV 2;

    m.width:=m.w1+m.w2;
    m.height:=U.MaxLong(m.label.height,m.arrow.height)+D.display.spaceHeight;

    m.CalcSize^;
  END CalcSize;

  PROCEDURE (s : SubMenu) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    draw:=s.GetDrawInfo();

    IF s.menu.selected=s THEN
      INCL(draw.mode,D.selected);
    END;

    s.DrawBackground(s.x,s.y,s.width,s.height);

    IF s.menu.selected=s THEN
      IF ~s.subMenu.IsOpen() THEN
        IF s.subMenu.Open() THEN
          s.menu.child:=s.subMenu;
        END;
      END;
    ELSIF s.menu.selected#s THEN
      IF s.subMenu.IsOpen() THEN
        s.subMenu.Close;
        s.menu.child:=NIL;
      END;
    END;

    s.arrow.Draw(draw,
                 s.x+s.w1+2*D.display.spaceWidth,
                 s.y+(s.height-s.arrow.height) DIV 2,
                 s.arrow.width,
                 s.arrow.height);

    s.label.Move(s.x+D.display.spaceWidth DIV 2,
                 s.y+(s.height-s.label.height) DIV 2);
    s.label.Draw(x,y,w,h);

    draw.mode:={};
  END Draw;

  PROCEDURE CreateMenuStrip*():MenuStrip;

  VAR
    strip : MenuStrip;

  BEGIN
    NEW(strip);
    strip.Init;

    RETURN strip;
  END CreateMenuStrip;

  PROCEDURE CreateMenuItem*():MenuItem;

  VAR
    m : MenuItem;

  BEGIN
    NEW(m);
    m.Init;

    RETURN m;
  END CreateMenuItem;

  PROCEDURE CreateMenuTitle*():MenuTitle;

  VAR
    m : MenuTitle;

  BEGIN
    NEW(m);
    m.Init;

    RETURN m;
  END CreateMenuTitle;

  PROCEDURE CreateSeparator*():Separator;

  VAR
    s : Separator;

  BEGIN
    NEW(s);
    s.Init;

    RETURN s;
  END CreateSeparator;

  PROCEDURE CreateSubMenu*():SubMenu;

  VAR
    s : SubMenu;

  BEGIN
    NEW(s);
    s.Init;

    RETURN s;
  END CreateSubMenu;

  PROCEDURE (e : MenuBox) Init*;

  BEGIN
    e.Init^;

    e.SetPrefs(prefs);

    e.SetBackgroundObject(prefs.bgPulldown.Copy());
  END Init;

  PROCEDURE (e : MenuBox) RegisterToParentWindow(parent : D.Window);

  VAR
    item : G.Object;

  BEGIN
    item:=e.list;
    WHILE item#NIL DO
      WITH item : MenuEntry DO
        item.RegisterToParentWindow(parent);
      ELSE
      END;

      item:=item.next;
    END;
  END RegisterToParentWindow;

  PROCEDURE (e : MenuBox) CalcSize*;

  VAR
    entry   : G.Object;
    w1,w2,h : LONGINT;

  BEGIN
    IF D.display.displayType=D.displayTypeTextual THEN
    ELSE
      e.SetObjectFrame(prefs.menuFrame);
    END;

    w1:=0;
    w2:=0;
    h:=0;

    entry:=e.list;
    WHILE entry#NIL DO
      entry.CalcSize;
      INC(h,entry.height);

      WITH entry : MenuEntry DO
        w1:=U.MaxLong(w1,entry.w1);
        w2:=U.MaxLong(w2,entry.w2);
      ELSE
      END;
      entry:=entry.next;
    END;

    entry:=e.list;
    WHILE entry#NIL DO
      WITH entry :  MenuEntry DO
        entry.w1:=w1;
        entry.w2:=w2;
      ELSE
      END;

      entry.Resize(w1+w2,entry.height);
      entry:=entry.next;
    END;

    e.width:=w1+w2;
    e.height:=h;

    e.CalcSize^;
  END CalcSize;

  PROCEDURE (e : MenuBox) Layout*;

  VAR
    entry : G.Object;
    yPos  : LONGINT;


  BEGIN
    yPos:=e.y;

    entry:=e.list;
    WHILE entry#NIL DO
      entry.Move(e.x,yPos);
      entry.Resize(e.width,entry.height); (* Does not work? *)

      INC(yPos,entry.height);

      entry:=entry.next;
    END;

    e.Layout^;
  END Layout;

  PROCEDURE (m : Menu) SetParent*(parent : D.Window);

    (**
      Private. This method is overloaded to get the parent window once.
      We need the parent window to register our shortcuts.
    *)

  BEGIN
    IF ~m.registered THEN
      m.top.RegisterToParentWindow(parent);
      m.registered:=TRUE;
      m.pWindow:=parent;
      m.SetParent^(parent);
    END;
  END SetParent;

  PROCEDURE (m : Menu) Add*(entry : MenuEntry);

    (**
      Initializes an empty menu.
    *)

  BEGIN
    entry.SetFlags({G.horizontalFlex});
    entry.SetWindow(m);
    entry.SetMenuObject(m);
    entry.menu:=m;

    m.top.Add(entry);
  END Add;

  PROCEDURE (m : Menu) AddItem*(label : G.Object;
                                qualifier : SET; key : STRING; id : LONGINT);

  VAR
    item : MenuItem;

  BEGIN
    item:=CreateMenuItem();
    item.SetLabel(label);
    IF key#NIL THEN
      item.SetShortcut(qualifier,key);
    END;
    item.SetId(id);

    m.Add(item);
  END AddItem;

  PROCEDURE (m : Menu) AddTextItemSC*(label : STRING; id : LONGINT;
                                      qualifier : SET; key : STRING);

  VAR
    item : MenuItem;

  BEGIN
    item:=CreateMenuItem();
    item.SetTextLabel(label);
    IF key#NIL THEN
      item.SetShortcut(qualifier,key);
    END;
    item.SetId(id);

    m.Add(item);
  END AddTextItemSC;

  PROCEDURE (m : Menu) AddTextItem*(label : STRING; id : LONGINT);

  BEGIN
    m.AddTextItemSC(label,id,{},NIL);
  END AddTextItem;

  PROCEDURE (m : Menu) AddSeparator*;

  BEGIN
    m.Add(CreateSeparator());
  END AddSeparator;

  PROCEDURE (m : Menu) AddTitle*(name : G.Object);

  VAR
    item : MenuTitle;

  BEGIN
    item:=CreateMenuTitle();
    item.SetLabel(name);

    m.Add(item);
  END AddTitle;

  PROCEDURE (m : Menu) AddTextTitle*(label : ARRAY OF CHAR);

  BEGIN
    m.AddTitle(T.MakeCenterText(label));
  END AddTextTitle;

  PROCEDURE (m : Menu) AddSubMenu*(name : G.Object; menu : Menu);

  VAR
    sub : SubMenu;

  BEGIN
    sub:=CreateSubMenu();
    sub.SetLabel(name);
    sub.SetMenu(menu);

    m.Add(sub);
  END AddSubMenu;

  PROCEDURE (m : Menu) AddTextSubMenu*(label : ARRAY OF CHAR; menu : Menu);

  BEGIN
    m.AddSubMenu(T.MakeLeftText(label),menu);
  END AddTextSubMenu;

  PROCEDURE (m : Menu) CalcSize;

  VAR
  BEGIN
    m.top.CalcSize;

    m.SetSize(m.top.oWidth,m.top.oHeight);
  END CalcSize;

  PROCEDURE (m : Menu) Send*(message : O.Message; type : LONGINT);

  VAR
    menu : Menu;
    help : D.Window;

  BEGIN
    menu:=m;
    WHILE (menu.parentMenu#NIL) & (menu.parentMenu.GetMenuObject()#NIL) DO
      help:=menu.parentMenu.GetMenuObject();
      menu:=help(Menu);
    END;

    IF menu.strip#NIL THEN
      menu.strip.Send(message,type);
    ELSE
      IF menu#m THEN
        menu.Send(message,type);
      ELSE
      menu.Send^(message,type);
      END;
    END;
  END Send;

  PROCEDURE (m : Menu) GetSelected():MenuEntry;

    (**
      Get menu entry the mouse currently is over or @code{NIL}.
    *)

  VAR
    entry  : G.Object;
    rx,ry,
    x,y    : LONGINT;

  BEGIN
    m.GetMousePos(rx,ry,x,y);

    entry:=m.top.list;
    WHILE entry#NIL DO
      IF entry.PointIsIn(x,y) THEN
        RETURN entry(MenuEntry);
      END;
      entry:=entry.next;
    END;

    RETURN NIL;
  END GetSelected;

  PROCEDURE (m : Menu) GetStrip():MenuStrip;

    (**
      Return menu strip or @code{NIL}, if there is no menu strip (popup menu).
    *)

  VAR
    current : Menu;
    help    : D.Window;

  BEGIN
    current:=m;
    WHILE current#NIL DO
      IF current.strip#NIL THEN
        RETURN current.strip;
      END;

      IF current.parentMenu#NIL THEN
        help:=current.parentMenu.GetMenuObject();
        current:=help(Menu);
      ELSE
        current:=NIL;
      END;
    END;

    RETURN NIL;
  END GetStrip;

  PROCEDURE (m : Menu) GetTop():Menu;

    (**
      Return top most menu.
    *)

  VAR
    current : Menu;
    help    : D.Window;

  BEGIN
    current:=m;
    WHILE current.parentMenu#NIL DO
      help:=current.parentMenu.GetMenuObject();
      current:=help(Menu);
    END;

    RETURN current;
  END GetTop;

  PROCEDURE (m : Menu) PreInit*;

  VAR
    rx,ry,
    cx,cy,
    x,y    : LONGINT;
    help   : D.Window;

  BEGIN
    m.CalcSize;

    m.selected:=NIL;

    IF (m.strip#NIL) & (m.reference#NIL) THEN
      help:=m.reference.GetWindow();
      x:=help.GetX();
      y:=help.GetY();
      INC(x,m.reference.x);
      INC(y,m.reference.y+m.reference.height);
      m.Grab(TRUE);
    ELSE
      IF m.parentMenu#NIL THEN (* submenu *)
        help:=m.parentMenu.GetMenuObject();
        x:=help.GetX()+help.GetWidth();
        y:=help.GetY()+m.parentMenu.y-help(Menu).top.list.y;
      ELSE (* main-menu *)
        m.pWindow.GetMousePos(rx,ry,cx,cy);
        IF m.popup THEN
          x:=rx+D.display.spaceWidth;
          y:=ry+D.display.spaceHeight;
        ELSE
          x:=rx-m.selected.x-m.selected.width DIV 2;
          y:=ry-m.selected.y-m.selected.height DIV 2;
        END;
        IF m.strip=NIL THEN
          m.Grab(TRUE);
        END;
      END;
    END;

    x:=U.RoundRange(x,0,D.display.scrWidth-1-m.GetWidth());
    y:=U.RoundRange(y,0,D.display.scrHeight-1-m.GetHeight());

    m.SetPos(x,y);
    m.SetPosition(D.manualPos,D.manualPos);

    m.PreInit^;
  END PreInit;

  PROCEDURE (m : Menu) Close*;

    (**
      Close menu.
    *)

  BEGIN
    IF m.child#NIL THEN
      m.child.Close;
    END;
    IF m.parentMenu#NIL THEN
      m.parentMenu.menu.child:=NIL;
    END;

    m.Close^;

    m.top.Free;
  END Close;

  PROCEDURE (m : Menu) CloseAll;

    (**
      Close current and all parent menues.
    *)

  VAR
    current : Menu;
    help    : D.Window;
    strip   : MenuStrip;

  BEGIN
    current:=m;
    WHILE current#NIL DO
      current.Close;
      IF current.parentMenu#NIL THEN
        help:=current.parentMenu.GetMenuObject();
        current:=help(Menu);
      ELSE
        current:=NIL;
      END;
    END;

    strip:=m.GetStrip();
    IF strip#NIL THEN
      strip.SetSelection(NIL);
    END;
  END CloseAll;

  PROCEDURE (m : Menu) EndAction;

    (**
      Close down menu and finish menu selection.
    *)

  VAR
    strip : MenuStrip;

  BEGIN
    strip:=m.GetStrip();

    IF strip#NIL THEN
      strip.stickyMode:=FALSE;
    END;

    m.CloseAll;
  END EndAction;

  PROCEDURE (m : Menu) OnRedraw*(x,y,width,height : LONGINT);

  BEGIN
    m.top.Move(0,0);
    m.top.Draw(x,y,width,height);
  END OnRedraw;

  PROCEDURE (m : Menu) OnHidden*;

  BEGIN
    m.OnHidden^;

    m.CloseAll;
  END OnHidden;

  PROCEDURE (m : Menu) SendSelectionEvent(item : MenuItem);

  VAR
    selected : SelectedMsg;

  BEGIN
    NEW(selected);
    selected.id:=item.id;
    m.Send(selected,selectedMsg);
  END SendSelectionEvent;

  PROCEDURE (m : Menu) Select(entry : MenuEntry);

  VAR
    old : MenuEntry;

  BEGIN
    old:=m.selected;
    IF (entry#old) THEN
      m.selected:=entry;

      IF old#NIL THEN
        old.Redraw;
      END;

      IF entry#NIL THEN
        entry.Redraw;
      END;
    END;
  END Select;

  PROCEDURE (m : Menu) SelectDown;

    (**
      Select next menu item in menu.
    *)

  VAR
    entry,
    new : G.Object;
    menu   : Menu;

  BEGIN
    menu:=m;
    WHILE (menu#NIL) & menu.IsOpen() & (menu.selected#NIL) & (menu.selected IS SubMenu) &
      (menu.selected(SubMenu).subMenu.selected#NIL) DO
      menu:=menu.selected(SubMenu).subMenu;
    END;

    IF (menu.top.count=0) OR ((menu.top.count=1) & (menu.selected=menu.top.list)) THEN
      (* nothing to do *)
      RETURN;
    END;

    new:=menu.selected;
    REPEAT
      IF new=NIL THEN
        new:=menu.top.list;
      ELSE
        entry:=menu.top.list;
        WHILE entry#new DO
          entry:=entry.next;
        END;
        entry:=entry.next;

        IF entry#NIL THEN
          new:=entry;
        ELSE
          new:=menu.top.list;
        END;
      END;
    UNTIL (new IS MenuItem) OR (new IS SubMenu);

    menu.Select(new(MenuEntry));
  END SelectDown;

  PROCEDURE (m : Menu) SelectUp;

    (**
      Select previous menu item in menu.
    *)

  VAR
    entry,
    new    : G.Object;
    menu   : Menu;

  BEGIN
    menu:=m;
    WHILE (menu#NIL) & menu.IsOpen() & (menu.selected#NIL) & (menu.selected IS SubMenu) &
      (menu.selected(SubMenu).subMenu.selected#NIL) DO
      menu:=menu.selected(SubMenu).subMenu;
    END;

    IF (menu.top.count=0) OR ((menu.top.count=1) & (menu.selected=menu.top.list)) THEN
      (* nothing to do *)
      RETURN;
    END;

    new:=menu.selected;
    REPEAT
      IF (new=NIL) OR (new=menu.top.list) THEN
        (* Select last entry *)
        entry:=menu.top.list;
        WHILE entry.next#NIL DO
          entry:=entry.next;
        END;
      ELSE
        (* Select previous entry *)
        entry:=menu.top.list;
        WHILE entry.next#new DO
          entry:=entry.next;
        END;
      END;
      new:=entry;
    UNTIL (new IS MenuItem) OR (new IS SubMenu);

    menu.Select(new(MenuEntry));
  END SelectUp;

  PROCEDURE (m : Menu) SelectLeft;

    (**
      Select parent menu if available or previous entry in menu strip.
    *)

  VAR
    menu  : Menu;
    strip : MenuStrip;

  BEGIN
    menu:=m;
    WHILE (menu#NIL) & menu.IsOpen() & (menu.selected#NIL) & (menu.selected IS SubMenu) &
      (menu.selected(SubMenu).subMenu.selected#NIL) DO
      menu:=menu.selected(SubMenu).subMenu;
    END;

    IF menu.parentMenu#NIL THEN
      menu.Select(NIL);
    ELSE
      strip:=m.GetStrip();
      IF strip#NIL THEN
        strip.SelectPrevious;
      END;
    END;
  END SelectLeft;

  PROCEDURE (m : Menu) SelectRight;

    (**
      Select sub menu if available or next entry in menu strip.
    *)

  VAR
    menu  : Menu;
    strip : MenuStrip;

  BEGIN
    menu:=m;
    WHILE (menu#NIL) & menu.IsOpen() & (menu.selected#NIL) & (menu.selected IS SubMenu) &
      (menu.selected(SubMenu).subMenu.selected#NIL) DO
      menu:=menu.selected(SubMenu).subMenu;
    END;

    IF (menu.selected#NIL) & (menu.selected IS SubMenu) THEN
      menu.selected(SubMenu).subMenu.SelectDown;
    ELSE
      strip:=m.GetStrip();
      IF strip#NIL THEN
        strip.SelectNext;
      END;
    END;
  END SelectRight;

  PROCEDURE (m : Menu) SelectKey(key : UCS4CHAR);

    (**
      Select menu item with the given hotkey.
    *)

  VAR
    menu  : Menu;
    entry : G.Object;

  BEGIN
    menu:=m;
    WHILE (menu#NIL) & menu.IsOpen() & (menu.selected#NIL) & (menu.selected IS SubMenu) &
      (menu.selected(SubMenu).subMenu.selected#NIL) DO
      menu:=menu.selected(SubMenu).subMenu;
    END;

    entry:=menu.top.list;
    WHILE entry#NIL DO
      WITH entry : MenuEntry DO
        IF CAP(key)=CAP(entry.sc) THEN
          WITH entry : MenuItem DO
            menu.EndAction;
            m.SendSelectionEvent(entry);
          ELSE
            menu.Select(entry);
          END;
          RETURN;
        END;
      END;
      entry:=entry.next;
    END;
  END SelectKey;

  (* ---------------------------------- *)

  PROCEDURE (m : Menu) HandleEvent*(event : E.Event):BOOLEAN;

  VAR
    menu   : Menu;
    object : G.Object;
    strip  : MenuStrip;

  BEGIN
    IF m.HandleEvent^(event) THEN
      RETURN TRUE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseUp)
        &  ((event.button=E.button3) OR (event.button=E.button1)) THEN
        menu:=m;
        WHILE (menu#NIL) & (menu.GetSelected()=NIL) & (menu.selected#NIL) DO
          IF menu.selected IS SubMenu THEN
            menu:=menu.selected(SubMenu).subMenu;
          ELSE
            menu:=NIL;
          END;
        END;
        IF menu#NIL THEN
          menu.selected:=menu.GetSelected();
        END;

        strip:=m.GetStrip();

        IF ~((menu#NIL) & (menu.selected#NIL) & (menu.selected IS MenuItem))
          & (strip#NIL) THEN
          (* No menu item selected *)
          IF ~strip.stickyMode & m.strip.MouseIsIn() THEN
            object:=strip.GetMouseSelected();
            IF (object#NIL) & (object(PullDownMenu).subMenu=m.GetTop()) THEN
              strip.stickyMode:=TRUE;
              RETURN TRUE;
            END;
          END;
        END;

        m.EndAction;

        IF (menu#NIL) & (menu.selected#NIL) & (menu.selected IS MenuItem) THEN
          (* Menu item selected *)
          m.SendSelectionEvent(menu.selected(MenuItem));
        END;
      END;

    | event : E.MotionEvent DO
      (*
        We got a motion event. Walk down the menu selection tree until you
        find a menu the mouse is currently over.
      *)
      menu:=m;
      WHILE (menu#NIL) & menu.IsOpen() & (menu.selected#NIL) & ~menu.CursorIsIn() DO
        IF (menu.selected IS SubMenu) THEN
          menu:=menu.selected(SubMenu).subMenu;
        ELSE
          menu:=NIL;
        END;
      END;

      IF menu#NIL THEN (* We found a submenu *)
        IF menu.CursorIsIn() THEN
          (*
            Select the select entry
          *)
          menu.Select(menu.GetSelected());
        ELSIF m.strip#NIL THEN
          (*
            If the mouse is over the strip, check if a new pulldown
            menu has been selected. If, close the old one.
          *)
          IF m.strip.MouseIsIn() THEN
            object:=m.strip.GetMouseSelected();
            IF (object#NIL) & (m.reference#object) THEN
              m.CloseAll();
            END;
          END;
        END;

      ELSE
        (*
          The mouse is currently over no menu. Now, find the leaf of the current
          menu selection tree.
        *)
        menu:=m;
        WHILE (menu#NIL) & menu.IsOpen() & (menu.selected#NIL) & (menu.selected IS SubMenu) DO
          menu:=menu.selected(SubMenu).subMenu;
        END;

        IF (menu#NIL) & (menu.selected#NIL) THEN
          (*
            Deselect the last selected entry, because it is not
            selected by the mouse anymore.

            This code sequence is only necessary for driver that do not handle
            OnMouseLeft!
          *)
          menu.Select(NIL);
        END;
      END;
    | event : E.KeyEvent DO
      IF event.type=E.keyDown THEN
        CASE event.key OF
          E.escape:
          m.EndAction;
        | E.return:
          IF (m.selected#NIL) & (m.selected IS MenuItem) THEN
            m.EndAction;
            m.SendSelectionEvent(m.selected(MenuItem));
          END;
        | E.up:
          m.SelectUp;
        | E.down:
          m.SelectDown;
        | E.left:
          m.SelectLeft;
        | E.right:
          m.SelectRight;
        ELSE
          IF event.text[0]#0X THEN
            m.SelectKey(event.text[0]);
          END;
        END;
      END;
    ELSE
    END;
    RETURN TRUE;
  END HandleEvent;

  PROCEDURE (m : Menu) OnMouseLeft*;

  VAR
    oldSelected : MenuEntry;

  BEGIN
    IF (m.selected#NIL) & ~(m.selected IS SubMenu) THEN
      oldSelected:=m.selected;
      m.selected:=NIL;
      oldSelected.Redraw;
    END;
  END OnMouseLeft;

  PROCEDURE CreateMenu*():Menu;

  VAR
    m : Menu;

  BEGIN
    NEW(m);
    m.Init;

    RETURN m;
  END CreateMenu;

  PROCEDURE InitMenu*():Menu;

  BEGIN
    RETURN CreateMenu();
  END InitMenu;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Menu.