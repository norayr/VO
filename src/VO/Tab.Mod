MODULE VO:Tab;

  (**
    Implements a tab groupobject.
  *)

  (*
    Implements a tab gadget.
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


IMPORT D  := VO:Base:Display,
       E  := VO:Base:Event,
       F  := VO:Base:Frame,
       O  := VO:Base:Object,
       U  := VO:Base:Util,
       Z  := VO:Base:Size,

       G  := VO:Object,
       T  := VO:Text;


CONST
  changedMsg * = 0;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 riderBackground*,
                 riderSelectBackground* : G.Background;
                 tabFrame*,
                 riderFrame*            : F.Frame;
                 topBarHeight*,
                 riderHSpace*,
                 riderVSpace*,
                 contentHSpace*,
                 contentVSpace*         : Z.SizeDesc;
                 hilightSelection*,
                 hilightActive*,
                 hilightActiveFrame*    : BOOLEAN;
               END;

  TabEntry     = POINTER TO TabEntryDesc;
  TabEntryDesc = RECORD
                   (**
                     Internal structure to hold list of tabriders
                   *)
                   next   : TabEntry;
                   label  : G.Object;
                   object : G.Object;
                 END;

  Tab*     = POINTER TO TabDesc;
  TabDesc* = RECORD (G.GadgetDesc)
               (**
                 Implements a tab groupobject.
               *)
               mw       : LONGINT; (* greatest width of all tab-objects *)
               mh       : LONGINT; (* greatest height of all tab-object *)

               tabList,
               lastTab  : TabEntry;
               current  : G.Object;
               selected-: LONGINT; (* The selected tab (1..n) *)
               curCount : LONGINT; (* the currently selected tab during clicking *)
               isIn     : BOOLEAN; (* used during selection action *)
               count    : LONGINT; (* number of tabs *)
             END;

  (* messages *)

  ChangedMsg*     = POINTER TO ChangedMsgDesc;
  ChangedMsgDesc* = RECORD (O.MessageDesc)
                      (**
                        The PressedMsg generated everytime the button get clicked.
                      *)
                      pos* : LONGINT;
                    END;

VAR
  prefs* : Prefs;


  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hilightSelection:=TRUE;
    p.hilightActive:=FALSE;
    p.hilightActiveFrame:=FALSE;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.riderFrame:=F.CreateFrame(F.none);
    ELSE
      p.riderFrame:=F.CreateFrame(F.tabRider);
    END;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.tabFrame:=F.CreateFrame(F.single);
    ELSE
      p.tabFrame:=F.CreateFrame(F.tab);
    END;

    p.riderHSpace.Init;
    p.riderVSpace.Init;
    p.riderHSpace.SetSize(Z.unitP,50);
    p.riderVSpace.SetSize(Z.softUnitP,50);

    p.topBarHeight.Init;
    IF D.display.displayType=D.displayTypeTextual THEN
      p.topBarHeight.SetSize(Z.pixel,0);
    ELSE
      p.topBarHeight.SetSize(Z.pixel,2);
    END;

    p.contentHSpace.Init;
    p.contentVSpace.Init;
    IF D.display.displayType=D.displayTypeTextual THEN
      p.contentHSpace.SetSize(Z.pixel,0);
      p.contentVSpace.SetSize(Z.pixel,0);
    ELSE
      p.contentHSpace.SetSize(Z.softUnit,2);
      p.contentVSpace.SetSize(Z.softUnit,2);
    END;

    p.riderBackground:=NIL;
    p.riderSelectBackground:=NIL;
  END Initialize;

  PROCEDURE (t : Tab) Init*;

  BEGIN
    t.Init^;

    t.SetFlags({G.canFocus});
    t.RemoveFlags({G.stdFocus});

    t.SetPrefs(prefs); (* We set the prefs *)

    t.tabList:=NIL;
    t.lastTab:=NIL;
    t.current:=NIL;
    t.count:=0;

    t.curCount:=0;
    t.selected:=1;

    t.isIn:=FALSE;

    t.mw:=0;
    t.mh:=0;
  END Init;

  PROCEDURE (t : Tab) VisitChildren*(VAR visitor : G.VisitorDesc;
                                      onlyVisible : BOOLEAN):BOOLEAN;

  VAR
    entry : TabEntry;

  BEGIN
    IF onlyVisible THEN
      IF t.current#NIL THEN
        IF ~visitor.Visit(t.current) THEN
          RETURN FALSE;
        END;

        entry:=t.tabList;
        WHILE entry#NIL DO
          IF ~visitor.Visit(entry.label) THEN
            RETURN FALSE;
          END;
          entry:=entry.next;
        END;
      END;
    ELSE
      entry:=t.tabList;
      WHILE entry#NIL DO
        IF ~visitor.Visit(entry.label) THEN
          RETURN FALSE;
        END;

        IF ~visitor.Visit(entry.object) THEN
          RETURN FALSE;
        END;

        entry:=entry.next;
      END;
    END;
    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (t : Tab) AddTab*(label, object : G.Object);

  VAR
    entry : TabEntry;

  BEGIN
    label.SetParent(t);
    label.SetBackgroundObject(t.prefs(Prefs).riderBackground);
    label.SetSelectionBackgroundObject(t.prefs(Prefs).riderSelectBackground);
    object.SetParent(t);

    NEW(entry);
    entry.label:=label;
    entry.object:=object;
    entry.next:=NIL;

    IF t.tabList=NIL THEN
      t.tabList:=entry;
    ELSE
      t.lastTab.next:=entry;
    END;
    t.lastTab:=entry;
    INC(t.count);
  END AddTab;

  PROCEDURE (t : Tab) AddTextTab*(string : ARRAY OF CHAR; object : G.Object);

  BEGIN
    t.AddTab(T.MakeCenterText(string),object);
  END AddTextTab;

  PROCEDURE (t : Tab) AddStringTab*(string : STRING; object : G.Object);

  BEGIN
    t.AddTab(T.MakeCenterString(string),object);
  END AddStringTab;

  PROCEDURE (t : Tab) CalcSize*;

  VAR
    entry : TabEntry;
    ow,oh : LONGINT;

  BEGIN
    t.width:=0;
    t.height:=0;
    t.mw:=0;
    t.mh:=0;
    ow:=0;
    oh:=0;

    IF ~t.StdFocus() & t.MayFocus() THEN
      entry:=t.tabList;
      WHILE entry#NIL DO
        entry.label.SetFlags({G.mayFocus});
        entry:=entry.next;
      END;
    END;

    entry:=t.tabList;
    WHILE entry#NIL DO
      IF entry.label.StdFocus() THEN
        t.SetFlags({G.stdFocus});
      END;

      entry.label.CalcSize;
      t.mw:=U.MaxLong(t.mw,entry.label.oWidth);
      t.mh:=U.MaxLong(t.mh,entry.label.oHeight);

      entry.object.CalcSize;
      ow:=U.MaxLong(ow,entry.object.oWidth);
      oh:=U.MaxLong(oh,entry.object.oHeight);

      entry:=entry.next;
    END;

    INC(t.mw,2*t.prefs(Prefs).riderHSpace.GetSize()+
        t.prefs(Prefs).riderFrame.minWidth);
    INC(t.mh,2*t.prefs(Prefs).riderVSpace.GetSize()+
        t.prefs(Prefs).riderFrame.minHeight);
    INC(ow,2*t.prefs(Prefs).contentHSpace.GetSize());
    INC(oh,2*t.prefs(Prefs).contentVSpace.GetSize());

    t.height:=t.mh+oh+t.prefs(Prefs).tabFrame.minHeight+t.prefs(Prefs).topBarHeight.GetSize();
    t.width:=U.MaxLong(ow+t.prefs(Prefs).tabFrame.minWidth,t.count*t.mw);

    t.minWidth:=t.width;
    t.minHeight:=t.height;

    t.CalcSize^;
  END CalcSize;

  PROCEDURE (t : Tab) GetEntry(pos :LONGINT): TabEntry;

  VAR
    entry : TabEntry;

  BEGIN
    entry:=t.tabList;
    WHILE pos>1 DO
      entry:=entry.next;
      DEC(pos);
    END;
    RETURN entry;
  END GetEntry;

  PROCEDURE (t : Tab) GetLabel(pos :LONGINT): G.Object;

  VAR
    entry : TabEntry;

  BEGIN
    entry:=t.tabList;
    WHILE pos>1 DO
      entry:=entry.next;
      DEC(pos);
    END;
    RETURN entry.label;
  END GetLabel;

  PROCEDURE (t : Tab) GetEntryAtPoint(x,y :LONGINT):LONGINT;

  VAR
    entry : TabEntry;
    pos   : LONGINT;

  BEGIN
    entry:=t.tabList;
    pos:=1;
    WHILE entry#NIL DO
      IF entry.label.PointIsIn(x,y) THEN
        RETURN pos;
      END;
      entry:=entry.next;
      INC(pos);
    END;
    RETURN 0;
  END GetEntryAtPoint;

  PROCEDURE (t : Tab) DrawTab(pos : LONGINT; selected : BOOLEAN);

    (**
      Draw a single tabrider.
    *)

  VAR
    x      : LONGINT;
    entry  : TabEntry;
    object : G.Object;
    draw   : D.DrawInfo;

  BEGIN
    draw:=t.GetDrawInfo();

    entry:=t.GetEntry(pos);
    object:=entry.label;

    IF ~object.StdFocus() THEN
      IF t.HasFocus() & (pos=t.selected)  THEN
        object.SetFlags({G.showFocus});
      ELSE
        object.RemoveFlags({G.showFocus});
      END;
    END;

    x:=t.x+(pos-1)*t.mw;

    IF TRUE(*t.prefs(Prefs).riderFrame.alpha*) THEN
      (**
        Some space under the tob of the rider is filled with the parent background
        color, because the rider are not completely rectangular and the background
        shines through.
      *)
      t.DrawParentBackground(x,t.y,t.mw,t.mh);
    END;


    IF selected & t.prefs(Prefs).hilightSelection THEN
      draw.mode:={D.selected};
    ELSIF (pos=t.selected) & t.prefs(Prefs).hilightActive THEN
      draw.mode:={D.selected};
    END;
    object.SetFlags({G.horizontalFlex,G.verticalFlex});
    object.Resize(t.mw-t.prefs(Prefs).riderFrame.minWidth,
                  t.mh-t.prefs(Prefs).riderFrame.minHeight);
    object.Move(x  +t.prefs(Prefs).riderFrame.leftBorder,
                t.y+t.prefs(Prefs).riderFrame.topBorder);
    object.Draw(t.oX,t.oY,t.oWidth,t.oHeight);
    draw.mode:={};

    IF selected & t.prefs(Prefs).hilightSelection THEN
      draw.mode:={D.selected};
    ELSIF (pos=t.selected) & t.prefs(Prefs).hilightActiveFrame THEN
      draw.mode:={D.selected};
    END;
    t.prefs(Prefs).riderFrame.Draw(draw,x,t.y,t.mw,t.mh);
    draw.mode:={};
  END DrawTab;

  PROCEDURE (t : Tab) DrawTabs;

    (**
      Draw all tabriders.
    *)

  VAR
    x : LONGINT;

  BEGIN
    (**
      The space behind the last tab rider will be filled the the parent background
      color.
    *)
    t.DrawParentBackground(t.x+t.mw*t.count,
                           t.y,
                           t.width-t.mw*t.count,
                           t.mh);

    FOR x:=1 TO t.count DO
      t.DrawTab(x,FALSE);
    END;
  END DrawTabs;

  PROCEDURE (t : Tab) DrawTop;

    (**
      Draws the selection line that marks the current tab rider
    *)

  VAR
    draw : D.DrawInfo;

  BEGIN
    draw:=t.GetDrawInfo();

    IF t.prefs(Prefs).topBarHeight.GetSize()>0 THEN
      draw.PushForeground(D.shineColor);
      draw.FillRectangle(t.x,
                         t.y+t.mh,
                         t.width,
                         t.prefs(Prefs).topBarHeight.GetSize());
      draw.PopForeground;

      t.DrawBackground(t.x+(t.selected-1)*t.mw,
                       t.y+t.mh,
                       t.mw,
                       t.prefs(Prefs).topBarHeight.GetSize());
    END;

    IF t.disabled THEN
      draw.PushForeground(D.disabledColor);
      draw.PushBitmap(D.smallChess,D.fgPattern);
      draw.FillRectangle(t.x,t.y,t.width,t.mh);
      draw.PopBitmap;
      draw.PopForeground;
    END;
  END DrawTop;

  PROCEDURE (t : Tab) DrawObject(pos : LONGINT; x,y,w,h : LONGINT);

    (**
      Draw the object that is shown by the currently selected tab.
    *)

  VAR
    entry  : TabEntry;
    draw   : D.DrawInfo;
    xPos,
    yPos,
    width,
    height : LONGINT;

  BEGIN
    draw:=t.GetDrawInfo();

    entry:=t.GetEntry(pos);
    IF (t.current#entry.object) & (t.current#NIL) THEN
      (*
        This is a little trick:
        We must hide the old object, but we do not want it to clean up the
        covered area, since it will be overwritten by the new object anyway.
        So we create a clipping region that completely covers the top be drawn
        area :-)
      *)
      draw.InstallClip(t.current.x,t.current.y,t.current.width,t.current.height);
      draw.SubRegion(t.current.x,t.current.y,t.current.width,t.current.height);
      t.current.Hide;
      draw.FreeLastClip;
    END;

    t.current:=entry.object;
    t.selected:=pos;

    xPos:=t.x+t.prefs(Prefs).tabFrame.leftBorder;
    yPos:=t.y+t.mh+t.prefs(Prefs).topBarHeight.GetSize()+t.prefs(Prefs).tabFrame.topBorder;
    width:=t.width-t.prefs(Prefs).tabFrame.minWidth;
    height:=t.height-t.mh-t.prefs(Prefs).topBarHeight.GetSize()-t.prefs(Prefs).tabFrame.minHeight;

    t.current.Resize(width-2*t.prefs(Prefs).contentHSpace.GetSize(),
                     height-2*t.prefs(Prefs).contentVSpace.GetSize());

    draw.InstallClip(xPos,yPos,width,height);
    draw.SubRegion(xPos+(width-t.current.oWidth) DIV 2,
                   yPos+(height-t.current.oHeight) DIV 2,
                   t.current.oWidth,t.current.oHeight);

    t.DrawBackground(xPos,yPos,width,height);

    draw.FreeLastClip;

    t.current.Move(xPos+(width-t.current.oWidth) DIV 2,
                   yPos+(height-t.current.oHeight) DIV 2);
    t.current.Draw(x,y,w,h);
  END DrawObject;

  PROCEDURE (t : Tab) RedrawObject(pos : LONGINT);

  BEGIN
    t.DrawObject(pos,t.x,t.y,t.width,t.height);
  END RedrawObject;

  PROCEDURE (t : Tab) HandleMouseEvent*(event : E.MouseEvent;
                                        VAR grab : G.Object):BOOLEAN;

  VAR
    changed : ChangedMsg;
    object  : G.Object;
    old,
    pos     : LONGINT;

  BEGIN
    IF ~t.visible OR t.disabled THEN
      RETURN FALSE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & t.PointIsIn(event.x,event.y)
      & (event.button=E.button1) THEN
        pos:=t.GetEntryAtPoint(event.x,event.y);
        IF (pos>0) & (pos#t.selected) THEN
          t.curCount:=pos;
          t.DrawTab(t.curCount,TRUE);
          t.isIn:=TRUE;

          grab:=t;
          RETURN TRUE;
        END;
      ELSIF (grab#NIL) & (event.type=E.mouseUp) & (event.button=E.button1) THEN
        object:=t.GetLabel(t.curCount);
        IF object.PointIsIn(event.x,event.y) THEN
          old:=t.selected;
          t.selected:=t.curCount;
          t.DrawTab(old,FALSE);
          t.DrawTab(t.selected,FALSE);
          t.RedrawObject(t.selected);
          t.DrawTop;

          NEW(changed);
          changed.pos:=t.selected;
          t.Send(changed,changedMsg);
        END;

        grab:=NIL;
        RETURN TRUE;
      END;
    | event : E.MotionEvent DO
      IF grab=t THEN
        object:=t.GetLabel(t.curCount);
        IF object.PointIsIn(event.x,event.y) THEN
          IF ~t.isIn THEN
            t.DrawTab(t.curCount,TRUE);
            t.isIn:=TRUE;
          END;
        ELSIF t.isIn THEN
          t.DrawTab(t.curCount,FALSE);
          t.isIn:=FALSE;
        END;
        RETURN TRUE;
      END;

    ELSE
    END;

    IF t.current#NIL THEN
      RETURN t.current.HandleMouseEvent(event,grab);
    ELSE
      RETURN FALSE;
    END;
  END HandleMouseEvent;

  PROCEDURE (t : Tab) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  VAR
    old : LONGINT;

  BEGIN
    IF event.type=E.keyDown THEN
      IF event.key=E.left THEN
        IF t.count>1 THEN
          old:=t.selected;
          DEC(t.selected);
          IF t.selected<1 THEN
            t.selected:=t.count;
          END;
          t.RedrawObject(t.selected);
          t.DrawTab(old,FALSE);
          t.DrawTab(t.selected,FALSE);
          t.DrawTop;
        END;
        RETURN TRUE;
      ELSIF event.key=E.right THEN
        IF t.count>1 THEN
          old:=t.selected;
          INC(t.selected);
          IF t.selected>t.count THEN
            t.selected:=1;
          END;
          t.RedrawObject(t.selected);
          t.DrawTab(old,FALSE);
          t.DrawTab(t.selected,FALSE);
          t.DrawTop;
        END;
        RETURN TRUE;
      END;
    END;
    RETURN FALSE;
  END HandleKeyEvent;

  PROCEDURE (t : Tab) GetDnDObject*(x,y : LONGINT; drag : BOOLEAN):G.Object;

  VAR
    object : TabEntry;
    return : G.Object;

  BEGIN
    IF t.current=NIL THEN
      RETURN NIL;
    END;

    return:=t.current.GetDnDObject(x,y,drag);
    IF return#NIL THEN
      RETURN return;
    END;

    object:=t.tabList;
    WHILE object#NIL DO
      return:=object.label.GetDnDObject(x,y,drag);
      IF return#NIL THEN
        RETURN return;
      END;
      object:=object.next;
    END;
    RETURN NIL;
  END GetDnDObject;

  PROCEDURE (t : Tab) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~t.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    t.Draw^(x,y,w,h);


    t.DrawTabs;

    draw:=t.GetDrawInfo();
    t.prefs(Prefs).tabFrame.Draw(draw,
                                 t.x,t.y+t.mh+t.prefs(Prefs).topBarHeight.GetSize(),
                                 t.width,t.height-t.mh-t.prefs(Prefs).topBarHeight.GetSize());

    t.DrawObject(t.selected,x,y,w,h);
    t.DrawTop;
  END Draw;

  PROCEDURE (t : Tab) DrawFocus*;

  VAR
    entry : TabEntry;
    draw  : D.DrawInfo;

  BEGIN
    draw:=t.GetDrawInfo();

    IF t.prefs(Prefs).hilightActive THEN
      draw.mode:={D.selected};
    END;

    (* If our image can draw a keyboard focus, delegate it *)
    entry:=t.GetEntry(t.selected);
    IF (entry#NIL) & ~entry.label.StdFocus() THEN
      t.DrawTab(t.selected,FALSE);
    ELSE
      (* Delegate drawing to the baseclass *)
      t.DrawFocus^;
    END;

    draw.mode:={};
  END DrawFocus;

  PROCEDURE (t : Tab) HideFocus*;

  VAR
    entry : TabEntry;

  BEGIN
    (* If our image can draw a keyboard focus, delegate it *)
    entry:=t.GetEntry(t.selected);
    IF (entry#NIL) & ~entry.label.StdFocus() THEN
      t.DrawTab(t.selected,FALSE);
    ELSE
      (* Delegate drawing to the baseclass *)
      t.HideFocus^;
    END;
  END HideFocus;

  PROCEDURE (t : Tab) Hide*;

  VAR
    entry : TabEntry;

  BEGIN
    IF t.visible THEN
      entry:=t.tabList;
      WHILE entry#NIL DO
        entry.label.Hide;
        entry:=entry.next;
      END;
      t.current.Hide;
      t.Hide^;
    END;
  END Hide;

  PROCEDURE CreateTab*():Tab;

  VAR
    tab : Tab;

  BEGIN
    NEW(tab);
    tab.Init;

    RETURN tab;
  END CreateTab;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Tab.