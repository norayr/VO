(**
  Implements a statusline group object.
**)

MODULE VO:StatusLine;

(*
    Implements a statusline group object.
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
  Prefs*     = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff is stored.
  **)

  PrefsDesc* = RECORD (G.PrefsDesc)
                 hSpace*,  (* Space between object and frame *)
                 vSpace*,  (* Space between object and frame *)
                 hpSpace*,
                 vpSpace* : Z.SizeDesc; (* Space between parts *)
                 iFrame*  : F.Frame;
               END;

  StatusLine*     = POINTER TO StatusLineDesc;
  StatusLineDesc* = RECORD (G.GroupDesc)
                      frame : F.Frame;
                      xRest,
                      yRest : LONGINT;
                    END;


VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hSpace.Init;
    p.vSpace.Init;
    p.hpSpace.Init;
    p.vpSpace.Init;

    IF D.display.displayType=D.displayTypeTextual THEN
      p.hSpace.SetSize(Z.unit,1);
      p.vSpace.SetSize(Z.pixel,0);
      p.hpSpace.SetSize(Z.unit,1);
      p.vpSpace.SetSize(Z.pixel,0);
      p.iFrame:=F.CreateFrame(F.none);
      p.frame:=F.CreateFrame(F.none);
    ELSE
      p.hSpace.SetSize(Z.softUnitP,25);
      p.vSpace.SetSize(Z.softUnitP,25);
      p.hpSpace.SetSize(Z.unitP,50);
      p.vpSpace.SetSize(Z.unitP,50);
      p.iFrame:=F.CreateFrame(F.single3DIn);
      p.frame:=F.CreateFrame(F.single3DOut);
    END;
  END Initialize;

  PROCEDURE (s : StatusLine) Init*;

  BEGIN
    s.Init^;

    s.SetPrefs(prefs);

    s.frame:=NIL;
  END Init;

  PROCEDURE (s : StatusLine) CalcSize*;

  VAR
    object : G.Object;

  BEGIN
    s.width:=0;
    s.height:=0;
    s.minWidth:=0;
    s.minHeight:=0;

    object:=s.list;
    WHILE object#NIL DO
      object.CalcSize;

      INC(s.width,object.oWidth);
      s.height:=U.MaxLong(s.height,object.oHeight);

      INC(s.minWidth,object.oMinWidth);
      s.minHeight:=U.MaxLong(s.minHeight,object.oMinHeight);

      object:=object.next;
    END;

    IF s.frame=NIL THEN
      s.frame:=s.prefs(Prefs).iFrame;
    END;

    s.xRest:=s.count*(s.frame.leftBorder+s.frame.rightBorder)+
             s.count*s.prefs(Prefs).hSpace.GetSize()*2+ (* Width between object and frame *)
             (s.count+1)*s.prefs(Prefs).hpSpace.GetSize(); (* space between objects *)
    s.yRest:=s.prefs(Prefs).vSpace.GetSize()*2+s.prefs(Prefs).vpSpace.GetSize()*2+
             s.frame.topBorder+s.frame.bottomBorder;
    INC(s.width,s.xRest);
    INC(s.minWidth,s.xRest);
    INC(s.height,s.yRest);
    INC(s.minHeight,s.yRest);

    s.CalcSize^;
  END CalcSize;

  PROCEDURE (s : StatusLine) Layout*;

  VAR
    pos,
    minSize,
    FCount,
    old      : LONGINT;
    object   : G.Object;

  BEGIN
    minSize:=0;
    object:=s.list;
    WHILE object#NIL DO
      INC(minSize,object.oWidth);
      object:=object.next;
    END;

    LOOP
      FCount:=0;
      object:=s.list;
      WHILE object#NIL DO
        IF object.CanResize(s.width-s.xRest>minSize,TRUE) THEN
          INC(FCount);
        END;
        object:=object.next;
      END;

      IF FCount=0 THEN
        EXIT;
      END;

      object:=s.list;
      WHILE object#NIL DO
        IF object.CanResize(s.width-s.xRest>minSize,TRUE) THEN
          old:=object.oWidth;
          object.Resize(object.oWidth + U.UpDiv(s.width-s.xRest-minSize,FCount),
          s.height-s.yRest);
          INC(minSize,object.oWidth-old);
          DEC(FCount);
        END;
        object:=object.next;
      END;

      IF minSize=s.width-s.xRest THEN
        EXIT;
      END;
    END;

    pos:=s.x+s.prefs(Prefs).hpSpace.GetSize();

    object:=s.list;
    WHILE object#NIL DO
      INC(pos,s.frame.leftBorder+s.prefs(Prefs).hSpace.GetSize());

      object.Move(pos,s.y+(s.height-object.oHeight) DIV 2);

      INC(pos,object.oWidth+s.prefs(Prefs).hSpace.GetSize()+s.frame.leftBorder+
          s.prefs(Prefs).hpSpace.GetSize());
      object:=object.next;
    END;

    s.Layout^;
  END Layout;

  PROCEDURE (s : StatusLine) Draw*(x,y,w,h : LONGINT);

  VAR
    pos      : LONGINT;
    object   : G.Object;
    draw     : D.DrawInfo;

  BEGIN
    IF ~s.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    s.Draw^(x,y,w,h);

    draw:=s.GetDrawInfo();

    pos:=s.x+s.prefs(Prefs).hpSpace.GetSize();

    object:=s.list;
    WHILE object#NIL DO
      s.frame.Draw(draw,
                    pos,
                    s.y+s.prefs(Prefs).vpSpace.GetSize(),
                    object.oWidth+s.prefs(Prefs).hSpace.GetSize()*2+
                    s.frame.leftBorder+s.frame.rightBorder,
                    s.height-s.prefs(Prefs).vpSpace.GetSize()*2);
      INC(pos,s.frame.leftBorder+s.prefs(Prefs).hSpace.GetSize());

      INC(pos,object.oWidth+s.prefs(Prefs).hSpace.GetSize()+s.frame.leftBorder+
          s.prefs(Prefs).hpSpace.GetSize());
      object:=object.next;
    END;
  END Draw;

  PROCEDURE CreateStatusLine*():StatusLine;

  VAR
    status : StatusLine;

  BEGIN
    NEW(status);
    status.Init;

    RETURN status;
  END CreateStatusLine;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:StatusLine.