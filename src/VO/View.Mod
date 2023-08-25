(**
   Implements full featured table on top of VOTableView..
**)

MODULE VO:View;

(*
   Implements full featured table on top of VOTableView..
    Copyright (C) 2000  Tim Teulings (rael@edge.ping.de)

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
       F  := VO:Base:Frame,
       O  := VO:Base:Object,

       G  := VO:Object,
       GR := VO:Grid,
       S  := VO:Scroller;

TYPE
  Prefs*     = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the cycle is stored.
  **)


  PrefsDesc* = RECORD (G.PrefsDesc)
               END;

  View*      = POINTER TO ViewDesc;
  ViewDesc*  = RECORD (G.LayoutDesc)
                 grid     : GR.Grid;
                 gadget-  : G.ScrollableGadget;

                 hScroll,
                 vScroll  : BOOLEAN;
               END;

VAR
  prefs*          : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.single);
    ELSE
      p.frame:=F.CreateFrame(F.double3DIn);
    END;
  END Initialize;


  PROCEDURE (v : View) Init*;

  BEGIN
    v.Init^;

    v.SetPrefs(prefs);

    v.grid:=NIL;

    v.hScroll:=TRUE;
    v.vScroll:=TRUE;

    v.gadget:=NIL;
  END Init;

  PROCEDURE (v : View) VisitChildren*(VAR visitor : G.VisitorDesc;
                                      onlyVisible : BOOLEAN):BOOLEAN;

  BEGIN
    IF v.grid#NIL THEN (* if grid was created (after CalcSize) *)
      IF ~visitor.Visit(v.grid) THEN
        RETURN FALSE;
      END;
    ELSIF v.gadget#NIL THEN (* if grid was not yet created (before calcSize) *)
      IF ~visitor.Visit(v.gadget) THEN
        RETURN FALSE;
      END;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (v : View) SetShowScroller*(hScroll,vScroll : BOOLEAN);

  BEGIN
    v.hScroll:=hScroll;
    v.vScroll:=vScroll;
  END SetShowScroller;

  PROCEDURE ( v : View) SetGadget*(gadget : G.ScrollableGadget);

  BEGIN
    v.gadget:=gadget;
    v.gadget.SetFlags({G.horizontalFlex,G.verticalFlex});
  END SetGadget;

  PROCEDURE (v : View) SetModel*(model : O.Model);

  BEGIN
    v.gadget.SetModel(model);
  END SetModel;

  (**
    This function is used to check if an argument to SetModel
    was successfully accepted.
   **)

  PROCEDURE (v : View) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN v.gadget.ModelAccepted(m);
  END ModelAccepted;

  PROCEDURE (v : View) CalcSize*;

  VAR
    scroller : S.Scroller;

  BEGIN
    ASSERT(v.gadget#NIL);

    v.grid:=GR.CreateGrid();
    v.grid.SetParent(v);
    v.grid.SetFlags({G.horizontalFlex,G.verticalFlex});

    IF v.hScroll THEN
      v.grid.SetGridSize(2,2);
    ELSE
      v.grid.SetGridSize(2,1);
    END;

    v.grid.SetObject(0,0,v.gadget);

    IF v.vScroll THEN
      scroller:=S.CreateVScroller();
      scroller.SetFlags({G.verticalFlex});
      scroller.RemoveFlags({G.canFocus});
      scroller.SetModel(v.gadget.vAdjustment);
      v.grid.SetObject(1,0,scroller);
    END;

    IF v.hScroll THEN
      scroller:=S.CreateHScroller();
      scroller.SetFlags({G.horizontalFlex});
      scroller.RemoveFlags({G.canFocus});
      scroller.SetModel(v.gadget.hAdjustment);
      v.grid.SetObject(0,1,scroller);
    END;

    v.grid.CalcSize;

    v.minWidth:=v.grid.oMinWidth;
    v.minHeight:=v.grid.oMinHeight;

    v.width:=v.grid.oWidth;
    v.height:=v.grid.oHeight;

    v.CalcSize^;
  END CalcSize;

  PROCEDURE (v : View) Layout*;

  BEGIN
    v.grid.MoveResize(v.x,v.y,v.width,v.height);

    v.Layout^;
  END Layout;

  PROCEDURE CreateView*(gadget : G.ScrollableGadget):View;

  VAR
    view : View;

  BEGIN
    NEW(view);
    view.Init;

    view.SetGadget(gadget);

    RETURN view;
  END CreateView;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:View.