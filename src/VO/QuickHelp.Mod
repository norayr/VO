(**
  Implements toolstips as known from other GUI systems.
**)

MODULE VO:QuickHelp;

(*
    Implements tooltips.
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


IMPORT BG  := VO:Base:Background,
       D   := VO:Base:Display,
       E   := VO:Base:Event,
       F   := VO:Base:Frame,
       U   := VO:Base:Util,
       Z   := VO:Base:Size,

       P   := VO:Prefs:Base,

       FG  := VO:FrameGroup,
       G   := VO:Object;

TYPE
  Prefs*     = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc* = RECORD (P.PrefsDesc)
                 background* : G.Background;
                 frame*      : F.Frame; (* the frame to use for the button *)
                 hOffset*,
                 vOffset*    : Z.SizeDesc;
               END;

  Help*         = POINTER TO HelpDesc;
  HelpDesc*     = RECORD (D.WindowDesc)
                    prefs      : Prefs;
                    top-,
                    reference- : G.Object;
                    refWin     : D.Window;
                    frame      : FG.FrameGroup;
                  END;

VAR
  prefs* : Prefs;


  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.helpBackgroundColorIndex));

    p.frame:=F.CreateFrame(F.single);
    p.hOffset.Init;
    p.vOffset.Init;

    p.hOffset.SetSize(Z.softUnit,2);
    p.vOffset.SetSize(Z.softUnit,2);
  END Initialize;

  PROCEDURE (h : Help) Init*;

  BEGIN
    h.Init^;

    h.prefs:=prefs;

    h.top:=NIL;
    h.reference:=NIL;
    h.frame:=NIL;
  END Init;

  PROCEDURE (h : Help) SetTop*(top : G.Object);

  BEGIN
    h.top:=top;
  END SetTop;

  PROCEDURE (h : Help) SetReference*(reference : G.Object);

  BEGIN
    h.reference:=reference;
  END SetReference;

  PROCEDURE (h : Help) CalcSize;

  BEGIN
    h.frame:=FG.CreateFrameGroup();
    h.frame.SetBackgroundObject(h.prefs.background);
    h.frame.SetFrame(h.prefs.frame);
    h.frame.SetFlags({G.horizontalFlex,G.verticalFlex});
    h.frame.SetSpace(TRUE);
    h.frame.SetObject(h.top);
    h.frame.SetWindow(h);

    h.frame.CalcSize;
    h.SetSize(h.frame.width,h.frame.height);
  END CalcSize;

  PROCEDURE (h : Help) PreInit*;

  VAR
    rx,ry,
    wx,wy,
    x,y    : LONGINT;

  BEGIN
    h.CalcSize;

    h.Grab(TRUE);
    h.SetType(D.windowTypePopup);

    h.refWin:=h.reference.GetWindow();

    h.refWin.GetMousePos(rx,ry,wx,wy);
    x:=rx+h.prefs.hOffset.GetSize();
    y:=ry+h.prefs.vOffset.GetSize();

    x:=U.RoundRange(x,0,D.display.scrWidth-1-h.GetWidth());
    y:=U.RoundRange(y,0,D.display.scrHeight-1-h.GetHeight());

    h.SetPos(x,y);
    h.SetPosition(D.manualPos,D.manualPos);

    h.PreInit^;
  END PreInit;

  PROCEDURE (h : Help) Close*;

  BEGIN
    h.Close^;

    h.frame.Free;
  END Close;

  (**
    Redraw the given area of the window.
  **)

  PROCEDURE (h : Help) OnRedraw*(x,y,width,height : LONGINT);

  BEGIN
    h.frame.Draw(x,y,width,height);
  END OnRedraw;

  PROCEDURE (h : Help) OnMouseLeft*;

  BEGIN
    h.OnMouseLeft^;

    h.Close;
  END OnMouseLeft;

  PROCEDURE (h : Help) OnHidden*;

  BEGIN
    h.OnHidden^;

    h.Close;
  END OnHidden;

  PROCEDURE (h : Help) HandleEvent*(event : E.Event):BOOLEAN;

  BEGIN
    IF h.HandleEvent^(event) THEN
      RETURN TRUE;
    END;

    WITH
      event : E.ButtonEvent DO
        h.Close;
        D.display.PutBackEvent(event,h.refWin);
    | event : E.MotionEvent DO
        h.Close;
    | event : E.KeyEvent DO
        h.Close;
        D.display.PutBackEvent(event,h.refWin);
    ELSE
    END;
    RETURN TRUE;
  END HandleEvent;

  PROCEDURE CreateHelp*(top,reference : G.Object):Help;
    (**
      Initializes a tooltip with @oparam{top} as child which ooccurs
      directly beneath @oparam{reference}.

      You must explicitly assign the tooltip to the object you want to
      give help for. This is not done automatically by this function.
    *)

  VAR
    h : Help;

  BEGIN
    NEW(h);
    h.Init;

    h.SetTop(top);
    h.SetReference(reference);

    RETURN h;
  END CreateHelp;

  PROCEDURE InitHelp*(top,reference : G.Object):Help;
    (**
      Initializes a tooltip with @oparam{top} as child which ooccurs
      directly beneath @oparam{reference}.

      You must explicitly assign the tooltip to the object you want to
      give help for. This is not done automatically by this function.
    *)

  BEGIN
    RETURN CreateHelp(top,reference);
  END InitHelp;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:QuickHelp.