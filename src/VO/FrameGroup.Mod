MODULE VO:FrameGroup;

  (**
   Implements @otype{FrameGroup}.
  *)

  (*
    Makes an frame around an object.
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

IMPORT D := VO:Base:Display,
       F := VO:Base:Frame,
       U := VO:Base:Util,
       Z := VO:Base:Size,

       G := VO:Object,
       T := VO:Text;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hSpace*,
                 vSpace* : Z.SizeDesc;
                 mode*   : SET; (* Mode for text of text label *)
               END;


  FrameGroup*     = POINTER TO FrameGroupDesc;
  FrameGroupDesc* = RECORD (G.LayoutDesc)
                      (**
                        A layout object that draws a frame (with some optional
                        space) around its only child. Usefull for simple visual
                        grouping.
                      *)
                      frame-     : F.Frame;
                      object,
                      text       : G.Object;
                      horizSpace,
                      vertSpace  : LONGINT;
                      space      : BOOLEAN;
                    END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hSpace.Init;
    p.vSpace.Init;
    p.hSpace.SetSize(Z.unit,2);
    p.vSpace.SetSize(Z.unit,2);

    p.mode:={T.smart};
  END Initialize;

  PROCEDURE (f : FrameGroup) Init*;

  BEGIN
    f.Init^;

    f.SetPrefs(prefs);

    f.space:=TRUE;

    f.object:=NIL;
    f.text:=NIL;

    IF D.display.displayType=D.displayTypeTextual THEN
      f.frame:=F.CreateFrame(F.none);
    ELSE
      f.frame:=F.CreateFrame(F.group3D);
    END;
  END Init;

  PROCEDURE (f : FrameGroup) VisitChildren*(VAR visitor : G.VisitorDesc;
                                            onlyVisible : BOOLEAN):BOOLEAN;

  BEGIN
    IF f.object#NIL THEN
      IF ~visitor.Visit(f.object) THEN
        RETURN FALSE;
      END;
    END;

    IF f.text#NIL THEN
      IF ~visitor.Visit(f.text) THEN
        RETURN FALSE;
      END;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (f : FrameGroup) SetObject*(object : G.Object);

  BEGIN
    f.object:=object;
    object.SetParent(f);
  END SetObject;

  PROCEDURE (f : FrameGroup) SetFrame*(frame : F.Frame);

    (**
      using this method you can set the frame to be used.
    *)

  BEGIN
    f.frame:=frame;

    IF f.visible THEN
      f.Redraw;
    END;
  END SetFrame;

  PROCEDURE (f : FrameGroup) SetSpace*(space : BOOLEAN);

    (**
      If @oparam{space} is @code{TRUE} some space is left between the frame
      and its content.
    *)

  BEGIN
    f.space:=space;
  END SetSpace;

  PROCEDURE (f : FrameGroup) SetLabel*(text : G.Object);

    (**
      Some frames allows an aditional (textual) label drawn as part of the
      frame. Call this method to set the object to be displayed.
    *)

  BEGIN
    f.text:=text;
    f.text.SetParent(f);
  END SetLabel;

  PROCEDURE (f : FrameGroup) SetTextLabel*(string : ARRAY OF CHAR);

    (**
      Similar to @oproc{FrameGroup.SetLabel}, but creates an instance of
      @otype{T.Text} from @oparam{string} to be assigned to the frame.
    *)

  VAR
    text : T.Text;

  BEGIN
    text:=T.MakeLeftText(string);

    f.SetLabel(text);
  END SetTextLabel;

  PROCEDURE (f : FrameGroup) SetStringLabel*(string : STRING);

    (**
      Similar to @oproc{FrameGroup.SetLabel}, but creates an instance of
      @otype{T.Text} from @oparam{string} to be assigned to the frame.
    *)

  VAR
    text : T.Text;

  BEGIN
    text:=T.MakeLeftString(string);

    f.SetLabel(text);
  END SetStringLabel;

  PROCEDURE (f : FrameGroup) CalcSize*;

  BEGIN
    IF f.space THEN
      f.horizSpace:=f.prefs(Prefs).hSpace.GetSize();
      f.vertSpace:=f.prefs(Prefs).hSpace.GetSize();
    ELSE
      f.horizSpace:=0;
      f.vertSpace:=0;
    END;

    IF f.text#NIL THEN
      f.text.CalcSize;
      f.frame.SetGap(f.text.oWidth,f.text.oHeight);
    END;

    f.width:=f.frame.leftBorder+f.frame.rightBorder+f.horizSpace;
    f.height:=f.frame.topBorder+f.frame.bottomBorder+f.vertSpace;

    f.minWidth:=f.width;
    f.minHeight:=f.height;

    IF f.object#NIL THEN
      f.object.CalcSize;
      INC(f.width,f.object.oWidth);
      INC(f.height,f.object.oHeight);
      INC(f.minWidth,f.object.oMinWidth);
      INC(f.minHeight,f.object.oMinHeight);
    END;

    IF f.text#NIL THEN
      f.minWidth:=U.MaxLong(f.minWidth,f.frame.minWidth);
      f.minHeight:=U.MaxLong(f.minHeight,f.frame.minHeight);
      f.width:=U.MaxLong(f.width,f.frame.minWidth);
      f.height:=U.MaxLong(f.height,f.frame.minHeight);
    END;

    f.CalcSize^;
  END CalcSize;

  PROCEDURE (f : FrameGroup) Layout*;

  BEGIN
    IF f.object#NIL THEN
      f.object.Resize(f.width-f.frame.leftBorder-f.frame.rightBorder-f.horizSpace,
                    f.height-f.frame.topBorder-f.frame.bottomBorder-f.vertSpace);
      f.object.Move(f.x+(f.width-f.object.oWidth) DIV 2,
                  f.y+f.frame.topBorder+(f.height-f.frame.topBorder-f.frame.bottomBorder-f.object.oHeight) DIV 2);
    END;

    IF f.text#NIL THEN
      f.text.Move(f.x+f.frame.gx,f.y+f.frame.gy);
    END;

    f.Layout^;
  END Layout;

  PROCEDURE (f : FrameGroup) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~f.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    (*
      In this case we use much of the drawing code from the layout object.
      Keep that in mind!
    *)
    f.Draw^(x,y,w,h);

    f.frame.Draw(f.GetDrawInfo(),f.x,f.y,f.width,f.height);
  END Draw;

  PROCEDURE CreateFrameGroup*():FrameGroup;

    (**
      Creates a new instance of @otype{FrameGroup}.
    *)

  VAR
    frameGroup : FrameGroup;

  BEGIN
    NEW(frameGroup);
    frameGroup.Init;

    RETURN frameGroup;
  END CreateFrameGroup;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:FrameGroup.