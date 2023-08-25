MODULE VO:Multi;

  (**
    Implements @otype{Multi}.
  *)

  (*
    Implements a invisible tab gadget.
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
       O  := VO:Base:Object,
       U  := VO:Base:Util,

       G  := VO:Object;

CONST
  setMsg* = 0;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;


  Multi*     = POINTER TO MultiDesc;
  MultiDesc* = RECORD (G.LayoutDesc)
                 (**
                   Multi allows you to show one item ot of @code{n} at a time -
                   similar to a tab object. However the currently show object
                   can only be changed programatically and not by any direct
                   user interaction. @otype{Multi} is used as a building block
                   for other controls most of the time.
                 *)
               list-,                 (** A linked list of all members *)
               last       : G.Object;
               count-     : LONGINT;  (** The number of members *)
               current-   : G.Object; (** The currently displayed object *)
               currentPos : LONGINT;  (** The position of the currently displayed object *)
             END;

  SetMsg*        = POINTER TO SetMsgDesc;
  SetMsgDesc*    = RECORD (O.MessageDesc)
                     pos* : LONGINT;
                   END;

VAR
  prefs* : Prefs;

  PROCEDURE (m : Multi) Init*;

  BEGIN
    m.Init^;

    m.SetPrefs(prefs);

    m.list:=NIL;
    m.last:=NIL;
    m.count:=0;

    m.current:=NIL;
    m.currentPos:=-1;
  END Init;

  PROCEDURE (m : Multi) VisitChildren*(VAR visitor : G.VisitorDesc;
                                       onlyVisible : BOOLEAN):BOOLEAN;

  VAR
    current : G.Object;

  BEGIN
    IF onlyVisible THEN
      IF m.current#NIL THEN
        IF ~visitor.Visit(m.current) THEN
          RETURN FALSE;
        END;
      END;
    ELSE
      current:=m.list;
      WHILE current#NIL DO
        IF ~visitor.Visit(m.current) THEN
          RETURN FALSE;
        END;
        current:=current.next;
      END;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (m : Multi) CalcSize*;

  VAR
    entry : G.Object;

  BEGIN
    m.width:=0;
    m.height:=0;
    m.minWidth:=0;
    m.minHeight:=0;

    entry:=m.list;
    WHILE entry#NIL DO
      entry.SetParent(m);
      entry.CalcSize;

      m.width:=U.MaxLong(m.width,entry.oWidth);
      m.height:=U.MaxLong(m.height,entry.oHeight);

      m.minWidth:=U.MaxLong(m.minWidth,entry.oMinWidth);
      m.minHeight:=U.MaxLong(m.minHeight,entry.oMinHeight);

      entry:=entry.next;
    END;

    m.CalcSize^;
  END CalcSize;

  PROCEDURE (m : Multi) Add*(object : G.Object);

  (**
    Add a new object to the list.
  *)

  BEGIN
    IF m.list=NIL THEN
      m.list:=object;
    ELSE
      m.last.next:=object;
    END;
    m.last:=object;
    object.next:=NIL; (* To be safe *)
    object.SetParent(m);
    INC(m.count);

    IF G.inited IN m.flags THEN
      object.CalcSize;
    END;
  END Add;

  PROCEDURE (m : Multi) GetEntry(pos : LONGINT): G.Object;

  (**
    Get the nth entry (1..n) in the list.
  *)

  VAR
    entry : G.Object;

  BEGIN
    ASSERT((pos>=1) & (pos<=m.count));

    entry:=m.list;
    WHILE (pos>1) & (entry#NIL) DO
      entry:=entry.next;
      DEC(pos);
    END;
    RETURN entry;
  END GetEntry;

  PROCEDURE (m : Multi) SetEntry*(pos : LONGINT);

  (**
    Show the nth entry (1..n) in the list.
  *)

  VAR
    old  : G.Object;
    draw : D.DrawInfo;

  BEGIN
    ASSERT((pos>=1) & (pos<=m.count));

    old:=m.current;
    m.current:=m.GetEntry(pos);
    m.currentPos:=pos;
    IF m.current#old THEN
      IF old#NIL THEN
        (*
          This is a little trick:
          We must hide the old object, but we do not want it to clean up the
          covered area, since it will be overwritten by the new object anyway.
          So we create a clipping region that completely covers the top be drawn
          area :-)
        *)
        draw:=m.GetDrawInfo();
        draw.InstallClip(m.x,m.y,m.width,m.height);
        draw.SubRegion(m.x,m.y,m.width,m.height);
        old.Hide;
        draw.FreeLastClip;
      END;
      m.SetRelayout;
      m.Redraw;
    END;
  END SetEntry;

  PROCEDURE (m : Multi) ShowLastEntry*;

  (**
    Show the entry before the current one. If the control already shows the first
    object the method displays the last one (wrap around).
  *)

  BEGIN
    IF m.list=m.last THEN (* only one child *)
      IF m.current=NIL THEN
        m.SetEntry(1);
      END;
      RETURN;
    END;

    IF m.currentPos=1 THEN
      m.SetEntry(m.count);
    ELSE
      m.SetEntry(m.currentPos-1);
    END;
  END ShowLastEntry;

  PROCEDURE (m : Multi) ShowNextEntry*;

  (**
    Show the entry after the current one.  If the control already shows the last
    object the method displays the first one (wrap around).
  *)

  BEGIN
    IF m.list=m.last THEN (* only one child *)
      IF m.current=NIL THEN
        m.SetEntry(1);
      END;
      RETURN;
    END;

    IF m.currentPos=m.count THEN
      m.SetEntry(1);
    ELSE
      m.SetEntry(m.currentPos+1);
    END;
  END ShowNextEntry;

  PROCEDURE (m : Multi) Remove*(pos : LONGINT);

  (**
    Remove the nth entry (1..n) in the list. If the deleted entry is the currently
    visible one, the next object is show. If the deleted object was the last one,
    the first object will be shown.
  *)

  VAR
    entry : G.Object;
    x     : LONGINT;

  BEGIN
    IF (pos=1) & (m.count=1) THEN (* the only one *)
      m.list:=NIL;
      m.last:=NIL;
      m.SetEntry(1);
    ELSIF pos=1 THEN (* deleting the first *)
      m.list:=m.list.next;
      DEC(m.count);
    ELSE
      (* find the entry before pos *)
      entry:=m.list;
      x:=pos;
      WHILE x>2 DO
        entry:=entry.next;
        DEC(x);
      END;

      IF m.last=entry.next THEN
        m.last:=entry;
      END;

      entry.next:=entry.next.next;

      DEC(m.count);
    END;

    IF pos=m.currentPos THEN
      IF pos<=m.count THEN (* setting the next one in row *)
        m.SetEntry(pos);
      ELSE                 (* if selected one wasd the last one, we set the first one *)
        m.SetEntry(1);
      END;
    ELSIF m.currentPos>=pos THEN
      DEC(m.currentPos);
    END;
  END Remove;

  PROCEDURE (m : Multi) Layout*;

  BEGIN
    IF m.current#NIL THEN
      m.current.Resize(m.width,m.height);
      m.current.Move(m.x+(m.width-m.current.oWidth) DIV 2,
                     m.y+(m.height-m.current.oHeight) DIV 2);
    END;

    m.Layout^;
  END Layout;

  PROCEDURE (m : Multi) Receive*(message : O.Message);

  BEGIN
    WITH
      message: SetMsg DO
        m.SetEntry(message.pos);
    ELSE
    END;
  END Receive;

  PROCEDURE CreateMulti*():Multi;

    (**
      Creates a new instance of @otype{Multi}.
    *)

  VAR
    multi : Multi;

  BEGIN
    NEW(multi);
    multi.Init;

    RETURN multi;
  END CreateMulti;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Multi.