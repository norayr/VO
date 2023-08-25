MODULE VO:Header;

  (**
    Implements @otype{Header}.
  *)

  (*
    A header object .
    Copyright (C) 2000 Tim Teulings (rael@edge.ping.de)

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
       O   := VO:Base:Object,
       Z   := VO:Base:Size,
       U   := VO:Base:Util,

       A   := VO:Model:Adjustment,
       HM  := VO:Model:Header,

       G   := VO:Object,
       T   := VO:Text;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 headerFrame* : F.Frame;
               END;

  Objects     = POINTER TO ARRAY OF G.Object;

  Header*     = POINTER TO HeaderDesc;
  HeaderDesc* = RECORD (G.GadgetDesc)
                  (**
                    A scrollable of table column labels. Only used internaly
                    by the VisualOberon table implementation. Don't use it
                    outside!
                  *)
                  frame      : F.Frame;        (** Frame of cells *)
                  model-     : HM.HeaderModel; (** The model we listen to *)
                  objects    : Objects;        (** Internal table of columns *)

                  adjustment : A.Adjustment;   (** The horizontal adjustment we listen to *)

                  offset     : LONGINT;        (** For grabbing the offset of our point in relation to the mouse *)
                  grabStart  : LONGINT;        (** The start of the column currently grabbed *)
                  grabColumn : LONGINT;        (** The column that gets grabbed *)
               END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.buttonBackgroundColorIndex));

    p.frame:=F.CreateFrame(F.none);
    IF D.display.displayType=D.displayTypeTextual THEN
      p.headerFrame:=F.CreateFrame(F.none);
    ELSE
      p.headerFrame:=F.CreateFrame(F.double3DOut);
    END;
  END Initialize;

  PROCEDURE (h : Header) Init*;

  BEGIN
    h.Init^;

    h.SetPrefs(prefs);

    h.frame:=h.prefs(Prefs).headerFrame;

    h.model:=NIL;
    h.objects:=NIL;
    h.adjustment:=NIL;
  END Init;

  PROCEDURE (h : Header) VisitChildren*(VAR visitor : G.VisitorDesc;
                                        onlyVisible : BOOLEAN):BOOLEAN;

  VAR
    x : LONGINT;

  BEGIN
    IF h.objects#NIL THEN
      FOR x:=0 TO LEN(h.objects^)-1 DO
        IF h.objects[x]#NIL THEN
          IF ~visitor.Visit(h.objects[x]) THEN
            RETURN FALSE;
          END;
        END;
      END;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (h : Header) SetAdjustment*(adjustment : A.Adjustment);

  BEGIN
    h.adjustment:=adjustment;
    h.AttachModel(h.adjustment.GetTopModel());
  END SetAdjustment;

  PROCEDURE (h : Header) CalcSize*;

  VAR
    font  : D.Font;
    x     : LONGINT;
    label : STRING;

  BEGIN
    IF h.model=NIL THEN
      font:=D.normalFont;

      h.width:=D.display.spaceWidth*10;
      h.height:=font.height+h.frame.minHeight+D.display.spaceHeight DIV 4;
    ELSE
      NEW(h.objects,h.model.GetEntries());

      h.height:=0;
      FOR x:=0 TO h.model.GetEntries()-1 DO
        label:=h.model.GetLabel(x);
        IF label=NIL THEN
          h.objects[x]:=T.MakeCenterString("");
        ELSE
          h.objects[x]:=T.MakeCenterString(label);
        END;
        h.objects[x].SetFlags({G.horizontalFlex});
        h.objects[x].SetParent(h);
        h.objects[x].SetBackgroundObject(NIL);
        h.objects[x].CalcSize;
        IF h.model.GetLabelSize(x)=0 THEN
          h.model.SetLabelSize(x,Z.pixel,h.objects[x].oWidth+h.frame.minWidth);
        END;
        h.height:=U.MaxLong(h.height,h.objects[x].oMinHeight);
      END;

      h.width:=0;
      INC(h.height,h.frame.minHeight+D.display.spaceHeight DIV 2);
    END;

    h.minWidth:=h.width;
    h.minHeight:=h.height;

    h.CalcSize^;
  END CalcSize;

  PROCEDURE (h : Header) DrawHeader(draw : D.DrawInfo; start : LONGINT);

  VAR
    x,
    count,
    size  : LONGINT;

  BEGIN
    IF h.model#NIL THEN
      (* Draw header *)
      draw.InstallClip(h.x,h.y,h.width,h.height);

      x:=h.x;
      IF h.adjustment#NIL THEN
        DEC(x,h.adjustment.GetTop()-1);
      END;
      size:=0;
      FOR count:=0 TO LEN(h.objects^)-1 DO
        h.objects[count].Resize(h.model.GetLabelSize(count)-h.frame.minWidth,
                                h.height-h.frame.minHeight);
        h.objects[count].Move(x+h.frame.leftBorder,
                              h.y+(h.height-h.objects[count].oHeight) DIV 2);

        (* If visible *)
        IF (count>=start) &
          ~((x>=h.x+h.width) OR
            (x+h.model.GetLabelSize(count)+h.frame.minWidth<h.x)) THEN
          IF h.model.IsSortColumn(count+1) THEN
            draw.mode:={D.selected};
          END;
          h.objects[count].Draw(h.oX,h.oY,h.oWidth,h.oHeight);
          draw.mode:={};
          h.frame.Draw(draw,
                       x,h.y,
                       h.model.GetLabelSize(count),
                       h.height);
        END;

        INC(x,h.model.GetLabelSize(count));
        INC(size,h.model.GetLabelSize(count));
      END;

      IF x<h.x+h.width THEN
        (* fill space behind last header *)
        h.DrawBackground(x,h.y,h.width-(x-h.x),h.height);
      END;
      draw.FreeLastClip;

      IF h.adjustment#NIL THEN
        h.adjustment.SetDimension(h.width,size);
      END;
    ELSE
      h.DrawBackground(h.x,h.y,h.width,h.height);
    END;
  END DrawHeader;

  PROCEDURE (h : Header) SetModel*(model : O.Model);

  BEGIN
    IF h.model#NIL THEN
      h.UnattachModel(h.model);
    END;
    IF (model#NIL) & (model IS HM.HeaderModel) THEN
      h.model:=model(HM.HeaderModel);
      h.AttachModel(model);
    ELSE
      h.model:=NIL
    END;
  END SetModel;

  PROCEDURE (h : Header) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=h.model
  END ModelAccepted;

  PROCEDURE (q : Header) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~q.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    q.Draw^(x,y,w,h);

    q.DrawHeader(q.GetDrawInfo(),0);
  END Draw;

  PROCEDURE (h : Header) HandleMouseEvent*(event : E.MouseEvent;
                                           VAR grab : G.Object):BOOLEAN;

  VAR
    pos,
    current : LONGINT;
    window  : D.Window;

  BEGIN
    IF ~h.visible OR h.disabled OR (h.model=NIL) THEN
      RETURN FALSE;
    END;

    WITH
      event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & h.PointIsIn(event.x,event.y)
        & (event.button=E.button1) THEN

        pos:=h.x;
        IF h.adjustment#NIL THEN
          DEC(pos,h.adjustment.GetTop()-1);
        END;

        FOR current:=0 TO LEN(h.objects^)-1 DO
          INC(pos,h.model.GetLabelSize(current));
          grab:=h;

          IF ABS(pos-event.x)<=2 THEN
            window:=h.GetWindow();
            IF window.IsDoubleClicked() THEN
              h.model.RequestFit(current);
            ELSE
              h.offset:=event.x-pos;
              h.grabStart:=pos-h.model.GetLabelSize(current);
              h.grabColumn:=current;
            END;
            RETURN TRUE;
          END;
        END;
        RETURN FALSE;
      ELSIF (grab=h) & (event.type=E.mouseUp) THEN

        grab:=NIL;

        RETURN TRUE;
      END;
    | event : E.MotionEvent DO
      IF grab=h THEN
        IF (event.x-h.offset-h.grabStart)>D.display.spaceWidth THEN
          h.model.SetLabelSize(h.grabColumn,Z.pixel,event.x-h.offset-h.grabStart);
        END;
      END;
    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (h : Header) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF model=h.model THEN
      IF msg=NIL THEN
        h.Redraw;
      ELSE
        WITH
          msg : HM.ResizedColumn DO
          IF h.visible THEN
            h.DrawHeader(h.GetDrawInfo(),msg.column);
          END;
        ELSE
        END;
      END;
    ELSIF (model=h.adjustment.GetTopModel()) THEN
      IF h.visible & ~h.disabled THEN
        h.DrawHeader(h.GetDrawInfo(),0);
      END;
    END;
  END Resync;

  PROCEDURE CreateHeader*():Header;

    (**
      Creates a new instance of @otype{Header}.
    *)

  VAR
    header : Header;

  BEGIN
    NEW(header);
    header.Init;

    RETURN header;
  END CreateHeader;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Header.