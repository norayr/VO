(**
  A layout group, that layout menues and the top group object within a window.
**)

MODULE VO:WindowGroup;

(*
    A layout group, that layouts a number of buttons horizontaly.
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

IMPORT U := VO:Base:Util,
       Z := VO:Base:Size,

       G := VO:Object;

TYPE
  Prefs*     = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc* = RECORD (G.PrefsDesc)
                 hSpace*,
                 vSpace* : Z.SizeDesc;
               END;

  WindowGroup*     = POINTER TO WindowGroupDesc;
  WindowGroupDesc* = RECORD(G.LayoutDesc)
                       men-,
                       top-,
                       tool-,
                       status- : G.Object;
                       space   : BOOLEAN;
                   END;


VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hSpace.Init;
    p.vSpace.Init;
    p.hSpace.SetSize(Z.unit,1);
    p.vSpace.SetSize(Z.unit,1);
  END Initialize;

  (**
    WindowGroup inherits horizontalFlex & verticalFlex from top.
  **)

  PROCEDURE (w : WindowGroup) Init*;

  BEGIN
    w.Init^;

    w.SetPrefs(prefs);

    w.men:=NIL;
    w.top:=NIL;
    w.tool:=NIL;
    w.status:=NIL;
    w.space:=TRUE;
  END Init;

  PROCEDURE (w : WindowGroup) Set*(menu, top : G.Object; space : BOOLEAN);

  BEGIN
    w.men:=menu;
    IF w.men#NIL THEN
      w.men.SetParent(w);
    END;

    w.top:=top;
    IF w.top#NIL THEN
      w.top.SetParent(w);
    END;

    w.space:=space;
  END Set;

  PROCEDURE (w : WindowGroup) SetSpace*(space : BOOLEAN);

  BEGIN
    w.space:=space;
  END SetSpace;

  PROCEDURE (w : WindowGroup) SetMenu*(menu : G.Object);

  BEGIN
    w.men:=menu;
    IF w.men#NIL THEN
      w.men.SetParent(w);
    END;
  END SetMenu;

  PROCEDURE (w : WindowGroup) SetToolbar*(toolbar : G.Object);

  BEGIN
    w.tool:=toolbar;
    IF w.tool#NIL THEN
      w.tool.SetParent(w);
    END;
  END SetToolbar;

  PROCEDURE (w : WindowGroup) SetMain*(main : G.Object);

  BEGIN
    w.top:=main;
    IF w.top#NIL THEN
      w.top.SetParent(w);
    END;
  END SetMain;

  PROCEDURE (w : WindowGroup) SetStatusLine*(status : G.Object);

  BEGIN
    w.status:=status;
    IF w.status#NIL THEN
      w.status.SetParent(w);
    END;
  END SetStatusLine;

  PROCEDURE (w : WindowGroup) VisitChildren*(VAR visitor : G.VisitorDesc;
                                             onlyVisible : BOOLEAN):BOOLEAN;

  BEGIN
    IF w.men#NIL THEN
      IF ~visitor.Visit(w.men) THEN
        RETURN FALSE;
      END;
    END;

    IF w.top#NIL THEN
      IF ~visitor.Visit(w.top) THEN
        RETURN FALSE;
      END;
    END;

    IF w.tool#NIL THEN
      IF ~visitor.Visit(w.tool) THEN
        RETURN FALSE;
      END;
    END;

    IF w.status#NIL THEN
      IF ~visitor.Visit(w.status) THEN
        RETURN FALSE;
      END;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (w : WindowGroup) CalcSize*;

  BEGIN
    w.width:=0;
    w.height:=0;
    w.minWidth:=0;
    w.minHeight:=0;

    IF w.men#NIL THEN
      w.men.CalcSize;
      w.width:=w.men.oWidth;
      w.height:=w.men.oHeight;
      w.minWidth:=w.men.oMinWidth;
      w.minHeight:=w.men.oMinHeight;
    END;

    IF w.tool#NIL THEN
      w.tool.CalcSize;
      INC(w.height,w.tool.oHeight);
      INC(w.minHeight,w.tool.oMinHeight);
      w.width:=U.MaxLong(w.width,w.tool.oWidth);
      w.minWidth:=U.MaxLong(w.minWidth,w.tool.oMinWidth);
    END;

    IF w.status#NIL THEN
      w.status.CalcSize;
      INC(w.height,w.status.oHeight);
      INC(w.minHeight,w.status.oMinHeight);
      w.width:=U.MaxLong(w.width,w.status.oWidth);
      w.minWidth:=U.MaxLong(w.minWidth,w.status.oMinWidth);
    END;

    IF w.top#NIL THEN
      w.top.CalcSize;
      INC(w.height,w.top.oHeight);
      INC(w.minHeight,w.top.oMinHeight);

      IF w.space THEN
        INC(w.height,2*w.prefs(Prefs).vSpace.GetSize());
        INC(w.minHeight,2*w.prefs(Prefs).vSpace.GetSize());
        w.width:=U.MaxLong(w.width,
                           w.top.oWidth+2*w.prefs(Prefs).hSpace.GetSize());
        w.minWidth:=U.MaxLong(w.minWidth,
                              w.top.oMinWidth+2*w.prefs(Prefs).hSpace.GetSize());
      ELSE
        w.width:=U.MaxLong(w.width,w.top.oWidth);
        w.minWidth:=U.MaxLong(w.minWidth,w.top.oMinWidth);
      END;

      IF (G.horizontalFlex IN w.top.flags) THEN
        w.SetFlags({G.horizontalFlex});
      END;
      IF G.verticalFlex IN w.top.flags THEN
        w.SetFlags({G.verticalFlex});
      END;
    END;
    w.CalcSize^;
  END CalcSize;

  PROCEDURE (w : WindowGroup) Layout*;

  VAR
    yPos,height : LONGINT;

  BEGIN
    yPos:=w.y;
    height:=w.height;

    IF w.men#NIL THEN
      w.men.Resize(w.width,-1);
      w.men.Move(w.x,yPos);
      INC(yPos,w.men.oHeight);
      DEC(height,w.men.oHeight);
    END;

    IF w.tool#NIL THEN
      w.tool.Resize(w.width,-1);
      w.tool.Move(w.x,yPos);
      INC(yPos,w.tool.oHeight);
      DEC(height,w.tool.oHeight);
    END;

    IF w.status#NIL THEN
      w.status.Resize(w.width,-1);
      w.status.Move(w.x,w.height-w.status.oHeight);
      DEC(height,w.status.oHeight);
    END;

    IF w.top#NIL THEN
      IF w.space THEN
        w.top.Resize(w.width-2*w.prefs(Prefs).vSpace.GetSize(),
                     height-2*w.prefs(Prefs).vSpace.GetSize());
      ELSE
        w.top.Resize(w.width,height);
      END;

      w.top.Move(w.x+(w.width-w.top.oWidth) DIV 2,
                 yPos+(height-w.top.oHeight) DIV 2);
    END;

    w.Layout^;
  END Layout;

  PROCEDURE CreateWindowGroup*():WindowGroup;

  VAR
    windowGroup : WindowGroup;

  BEGIN
    NEW(windowGroup);
    windowGroup.Init;

    RETURN windowGroup;
  END CreateWindowGroup;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:WindowGroup.