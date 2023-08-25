(**

**)

MODULE VO:PatternLegend;

(*
    ???
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

IMPORT D := VO:Base:Display,
       F := VO:Base:Frame,
       U := VO:Base:Util,
       Z := VO:Base:Size,

       G := VO:Object;

TYPE
  Prefs*             = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc*         = RECORD (G.PrefsDesc)
                         width,
                         height,
                         hSpace,
                         vSpace :  Z.SizeDesc;
                       END;

  PatternLegend*     = POINTER TO PatternLegendDesc;
  PatternLegendDesc* = RECORD (G.GroupDesc)
                         frame   : F.Frame;
                       END;
VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.width.Init;
    p.height.Init;
    p.hSpace.Init;
    p.vSpace.Init;
    p.width.SetSize(Z.unit,5);
    p.height.SetSize(Z.unit,3);
    p.hSpace.SetSize(Z.unit,1);
    p.vSpace.SetSize(Z.unit,1);
  END Initialize;

  PROCEDURE (p : PatternLegend) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.frame:=F.CreateFrame(F.single3DOut);
  END Init;

  PROCEDURE (p : PatternLegend) CalcSize*;

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

      p.width:=U.MaxLong(p.width,object.oWidth);
      p.minWidth:=U.MaxLong(p.minWidth,object.oMinWidth);

      INC(p.height,U.MaxLong(p.prefs(Prefs).height.GetSize()+p.frame.minHeight,
                             object.oHeight));
      INC(p.minHeight,U.MaxLong(p.prefs(Prefs).height.GetSize()+p.frame.minHeight,
                                object.oMinHeight));

      object:=object.next;
    END;

    IF p.count>0 THEN
      INC(p.height,(p.count-1)*p.prefs(Prefs).vSpace.GetSize());
      INC(p.minHeight,(p.count-1)*p.prefs(Prefs).vSpace.GetSize());
    END;

    INC(p.width,p.prefs(Prefs).width.GetSize()+
        p.frame.minWidth+
        p.prefs(Prefs).hSpace.GetSize());
    INC(p.minWidth,p.prefs(Prefs).width.GetSize()+
        p.frame.minWidth+
        p.prefs(Prefs).hSpace.GetSize());

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : PatternLegend) Layout*;

  VAR
    pos    : LONGINT;
    object : G.Object;

  BEGIN
    pos:=p.y;
    object:=p.list;
    WHILE object#NIL DO
      object.Move(p.x+
                  p.prefs(Prefs).width.GetSize()+
                  p.prefs(Prefs).hSpace.GetSize()+
                  p.frame.minWidth,
                  pos);

      INC(pos,object.oHeight+p.prefs(Prefs).vSpace.GetSize());
      object:=object.next;
    END;

    p.Layout^;
  END Layout;

  PROCEDURE (p : PatternLegend) Draw*(x,y,w,h : LONGINT);

  VAR
    pos,count : LONGINT;
    object    : G.Object;
    draw      : D.DrawInfo;

  BEGIN
    IF ~p.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    p.Draw^(x,y,w,h);

    draw:=p.GetDrawInfo();

    pos:=p.y;
    count:=1;
    object:=p.list;
    WHILE object#NIL DO
      draw.PushUniqueFillPattern(count,p.count);
      draw.FillRectangle(p.x+p.frame.leftBorder,
                         pos+p.frame.topBorder,
                         p.prefs(Prefs).width.GetSize(),
                         p.prefs(Prefs).height.GetSize());
      draw.PopUniqueFillPattern(count,p.count);
      p.frame.Draw(draw,p.x,pos,
                   p.prefs(Prefs).width.GetSize()+p.frame.minWidth,
                   p.prefs(Prefs).height.GetSize()+p.frame.minHeight);
      object.Draw(x,y,w,h);


      INC(pos,object.oHeight+p.prefs(Prefs).vSpace.GetSize());
      INC(count);
      object:=object.next;
    END;
  END Draw;

  PROCEDURE CreatePatternLegend*(): PatternLegend;

  VAR
    legend : PatternLegend;

  BEGIN
    NEW(legend);
    legend.Init;

    RETURN legend;
  END CreatePatternLegend;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:PatternLegend.