MODULE VO:Pane;

  (**
    Implements @otype{Pane}.
  *)

  (*
    Implements a layouting group.
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

IMPORT D  := VO:Base:Display,
       E  := VO:Base:Event,
       IB := VO:Base:Image,
       U  := VO:Base:Util,
       VB := VO:Base:VecImage,

       G  := VO:Object,
       I  := VO:Image;

CONST
  horizontal* = 0; (** Pane is horizontal *)
  vertical*   = 1; (** Pane is vertical *)

  (* Differen modes for DrawSelection *)

  start       = 0;
  refresh     = 1;
  end         = 2;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hMover,
                 vMover : IB.Image;
               END;

  Pane*     = POINTER TO PaneDesc;
  PaneDesc* = RECORD (G.LayoutDesc)
                (**
                  A layouting class for grouping objects horizontaly or verticaly.
                  The size of the objects can be changed by some automatically
                  added sliders. The minimum and maximum size of the individual
                  controls will be respected.
                *)
                list*,               (* A linked list of all members *)
                last*  : G.Object;
                count* : LONGINT;    (* The number of members *)
                type   : LONGINT;
                oldPos : LONGINT;
                o1,o2,
                mover  : G.Object; (* The objects before and after the mover and the mover itself *)
              END;

VAR
  prefs : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hMover:=IB.CreateVecImage(VB.w95HMover);
    p.vMover:=IB.CreateVecImage(VB.w95VMover);
  END Initialize;


  PROCEDURE (p : Pane) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.list:=NIL;
    p.last:=NIL;
    p.count:=0;

    p.o1:=NIL;
    p.o2:=NIL;
    p.mover:=NIL;

    p.type:=vertical;
  END Init;

  PROCEDURE (p : Pane) VisitChildren*(VAR visitor : G.VisitorDesc;
                                      onlyVisible : BOOLEAN):BOOLEAN;

  VAR
    object : G.Object;

  BEGIN
    object:=p.list;
    WHILE object#NIL DO
      IF ~visitor.Visit(object) THEN
        RETURN FALSE;
      END;
      object:=object.next;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (p : Pane) Set*(type : LONGINT);

    (**
      Tell if the objects should be arranged horizontally or vertically.
    *)

  BEGIN
    p.type:=type;
  END Set;

  PROCEDURE (p : Pane) Add*(object : G.Object);

    (**
      Add an object to the group. Pane will add mover objects automatically
      when appropiate.
    *)

  VAR
    image : I.Image;

  BEGIN
    IF p.list=NIL THEN
      p.list:=object;
    ELSE
      image:=I.CreateImage();
      image.SetParent(p);
      IF p.type=vertical THEN
        image.SetImage(p.prefs(Prefs).vMover);
        image.SetFlags({G.horizontalFlex});
      ELSE
        image.SetImage(p.prefs(Prefs).hMover);
        image.SetFlags({G.verticalFlex});
      END;
      INC(p.count);

      p.last.next:=image;
      image.next:=object;
    END;
    p.last:=object;
    object.SetParent(p);
    INC(p.count);
  END Add;

  PROCEDURE (p : Pane) CalcSize*;

  VAR
    object : G.Object;

  BEGIN
    p.width:=0;
    p.height:=0;
    p.minWidth:=0;
    p.minHeight:=0;

    object:=p.list;
    WHILE object#NIL DO

      object.CalcSize;

      IF p.type=vertical THEN
        p.width:=U.MaxLong(p.width,object.oWidth);
        INC(p.height,object.oHeight);

        p.minWidth:=U.MaxLong(p.minWidth,object.oMinWidth);
        INC(p.minHeight,object.oMinHeight);
      ELSE
        INC(p.width,object.oWidth);
        p.height:=U.MaxLong(p.height,object.oHeight);

        INC(p.minWidth,object.oMinWidth);
        p.minHeight:=U.MaxLong(p.minHeight,object.oMinHeight);
      END;

      object:=object.next;
    END;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : Pane) MoveObjects(o1,o2,mover : G.Object; pos : LONGINT);

  VAR
    old : LONGINT;

  BEGIN
    o1.Hide;
    o2.Hide;
    mover.Hide;

    IF p.type=horizontal THEN
      pos:=U.MinLong(p.x+p.width-1-o2.oMinWidth-mover.oWidth,pos);
      pos:=U.MaxLong(p.x+o1.oMinWidth-1,pos);

      old:=p.width-mover.oWidth;

      o1.Resize(pos-o1.oX,-1);
      o2.Resize(old-o1.oWidth,-1);
      mover.Move(o1.oX+o1.oWidth,mover.oY);
      o2.Move(o1.oX+o1.oWidth+mover.oWidth,o2.oY);
    ELSE
      pos:=U.MinLong(p.y+p.height-1-o2.oMinHeight-mover.oHeight,pos);
      pos:=U.MaxLong(p.y+o1.oMinHeight-1,pos);

      old:=p.height-mover.oHeight;

      o1.Resize(-1,pos-o1.oY);
      o2.Resize(-1,old-o1.oHeight);
      mover.Move(mover.oX,o1.oY+o1.oHeight);
      o2.Move(o2.oX,o1.oY+o1.oHeight+mover.oHeight);
    END;

    o1.Draw(p.oX,p.oY,p.oWidth,p.oHeight);
    mover.Draw(p.oX,p.oY,p.oWidth,p.oHeight);
    o2.Draw(p.oX,p.oY,p.oWidth,p.oHeight);
  END MoveObjects;

  PROCEDURE (p : Pane) DrawSel(mode : INTEGER; x,y : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    draw:=p.GetDrawInfo();

    draw.PushDrawMode(D.invert);
    draw.PushForeground(D.blackColor);
    IF p.type=horizontal THEN
      IF (mode=refresh) OR (mode=end) THEN (* clear old *)
        draw.DrawLine(p.oldPos,p.y,p.oldPos,p.y+p.height-1);
      END;
      IF (mode=refresh) OR (mode=start) THEN (* draw new *)
        draw.DrawLine(x,p.y,x,p.y+p.height-1);
        p.oldPos:=x;
      END;
    ELSE
      IF (mode=refresh) OR (mode=end) THEN (* clear old *)
        draw.DrawLine(p.x,p.oldPos,p.x+p.width-1,p.oldPos);
      END;
      IF (mode=refresh) OR (mode=start) THEN (* draw new *)
        draw.DrawLine(p.x,y,p.x+p.width-1,y);
        p.oldPos:=y;
      END;
    END;
    draw.PopDrawMode;
    draw.PopForeground;

(*
    IF p.type=horizontal THEN
      p.MoveObjects(p.o1,p.o2,p.mover,x);
    ELSE
      p.MoveObjects(p.o1,p.o2,p.mover,y);
    END;*)
  END DrawSel;

  PROCEDURE (p : Pane) HandleMouseEvent*(event : E.MouseEvent;
                                         VAR grab : G.Object):BOOLEAN;

  VAR
    object,
    last   : G.Object;

  BEGIN
    IF ~p.visible OR p.disabled THEN
      RETURN FALSE;
    END;


    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & (event.button=E.button1) THEN

        (*
          Going trough the list of objects and investigate every second object
          which should be a mover image.
         *)
        object:=p.list;
        last:=NIL;
        IF object#NIL THEN
          last:=object;
          object:=object.next;
        END;

        WHILE object#NIL DO

          IF object.PointIsIn(event.x,event.y) THEN
            p.o1:=last;
            p.mover:=object;
            p.o2:=object.next;
            p.DrawSel(start,event.x,event.y);

            grab:=p;
            RETURN TRUE;
          END;

          object:=object.next;
          IF object#NIL THEN
            last:=object;
            object:=object.next;
          END;
        END;

      ELSIF (grab=p) & (event.type=E.mouseUp) & (event.button=E.button1) THEN
        p.DrawSel(end,event.x,event.y);
        IF p.type=horizontal THEN
          p.MoveObjects(p.o1,p.o2,p.mover,event.x);
        ELSE
          p.MoveObjects(p.o1,p.o2,p.mover,event.y);
        END;

        grab:=NIL;
        RETURN TRUE;
      END;
    | event : E.MotionEvent DO
      IF grab=p THEN
        p.DrawSel(refresh,event.x,event.y);
        RETURN TRUE;
      END;
    ELSE
    END;

    (* We first check all childs *)
    object:=p.list;
    WHILE object#NIL DO
      IF object.HandleMouseEvent(event,grab) THEN
        RETURN TRUE;
      END;
      object:=object.next;
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (p : Pane) Layout*;

  VAR
    pos  : LONGINT;
    help : G.Object;

  BEGIN
    IF p.type=vertical THEN

      (* Liste abarbeiten *)

      help:=p.list;
      pos:=p.y;
      WHILE help#NIL DO
        help.Resize(p.width,-1);
        IF help.next=NIL THEN
          help.Resize(-1,p.y+p.height-pos+1);
        END;
        help.Move(p.x + (p.width-help.oWidth) DIV 2,pos);
        INC(pos,help.oHeight);
        help:=help.next;
      END;

    ELSE

      (* Liste abarbeiten *)

      help:=p.list;
      pos:=p.x;
      WHILE help#NIL DO
        help.Resize(-1,p.height);
        IF help.next=NIL THEN
          help.Resize(p.x+p.width-pos+1,-1);
        END;
        help.Move(pos,p.y + (p.height-help.oHeight) DIV 2);
        INC(pos,help.oWidth);
        help:=help.next;
      END;

    END;

    p.Layout^;
  END Layout;

  PROCEDURE CreatePane*():Pane;

    (**
      Creates a new instance of @otype{Pane}.
    *)

  VAR
    pane : Pane;

  BEGIN
    NEW(pane);
    pane.Init;

    RETURN pane;
  END CreatePane;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Pane.