MODULE VO:Load;

  (**
    Implements @otype{Load}.
  *)

  (*
    Implements a load-like percentage display.
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

IMPORT BG  := VO:Base:Background,
       D   := VO:Base:Display,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,
       U   := VO:Base:Util,

       V   := VO:Model:Value,

       G   := VO:Object,
       S   := VO:Segment,

       co  := IntStr,
       str := Strings;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 gap* : LONGINT;
               END;

  Load*     = POINTER TO LoadDesc;
  LoadDesc* = RECORD (G.ImageDesc)
                (**
                  Implements a load-like percentage display. It consists
                  of a number of colored segments that a drawing as on or
                  off (by using different colors) depending of the current
                  value is shown. Different colors are used for different values.
                *)
                labelTxt : S.Segment;
                labelSfx : U.Text;
                top,
                bottom   : LONGINT;
                onColor,
                maxColor,
                mediumColor,
                offColor : LONGINT;
                current  : V.ValueModel;
                framed,
                vertical,
                labeled  : BOOLEAN;
              END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.blackColorIndex));
    p.frame:=F.CreateFrame(F.double3DIn);

    p.gap:=1;
  END Initialize;

  PROCEDURE (l : Load) Init*;

  BEGIN
    l.Init^;

    l.SetPrefs(prefs);

    l.top:=100;
    l.bottom:=0;

    l.current:=NIL;

    l.labelTxt:=NIL;
    l.labelSfx:=NIL;

    l.vertical:=TRUE;
    l.framed:=TRUE;
    l.labeled:=FALSE;

    l.onColor:=D.shineColor;
    l.maxColor:=D.shineColor;
    l.mediumColor:=D.shineColor;
    l.offColor:=D.shadowColor;
  END Init;

  PROCEDURE (l : Load) SetVertical*(vertical : BOOLEAN);

  (**
    Tell, if the load should be display horizontally or
    vertically.

    Default is vertical.
  *)

  BEGIN
    l.vertical:=vertical;
    IF l.visible THEN
      l.Redraw;
    END;
  END SetVertical;

  PROCEDURE (l : Load) ShowLabel*(useLabel : BOOLEAN);

    (**
      Tell, if the object should display its value as label.
    *)

  BEGIN
    l.labeled:=useLabel;
    IF l.visible THEN
      l.Redraw;
    END;
  END ShowLabel;

  PROCEDURE (l : Load) ShowFrame*(framed : BOOLEAN);

    (**
      Tell, if the object should be framed. Defaults to TRUE.
    *)

  BEGIN
    l.framed:=framed;
  END ShowFrame;

  PROCEDURE (l : Load) SetModel*(model : O.Model);

    (**
      Set the integer model which represents the current value.
    *)

  BEGIN
    IF l.current#NIL THEN
      l.UnattachModel(l.current);
    END;
    IF (model#NIL) & (model IS V.ValueModel) THEN
      l.current:=model(V.ValueModel);
      l.AttachModel(l.current);
      IF l.visible THEN
        l.Redraw;
      END;
    ELSE
      l.current:=NIL;
    END;
  END SetModel;

  PROCEDURE (l : Load) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=l.current
  END ModelAccepted;

  PROCEDURE (l : Load) CalcSize*;

  BEGIN
    IF ~(G.inited IN l.flags) THEN
      IF D.display.colorMode=D.colorMode THEN
        D.display.AllocateNamedColor("green",l.onColor,l.onColor);
        D.display.AllocateNamedColor("yellow",l.mediumColor,l.mediumColor);
        D.display.AllocateNamedColor("red",l.maxColor,l.maxColor);
      ELSIF D.display.colorMode=D.monochromeMode THEN
        l.onColor:=D.blackColor;
        l.maxColor:=l.onColor;
        l.mediumColor:=l.onColor;
        l.offColor:=D.whiteColor;
      END;
    END;

    IF l.framed THEN
      l.SetObjectFrame(l.prefs.frame);
    ELSE
      l.SetObjectFrame(F.CreateFrame(F.none));
    END;

    l.width:=2*D.display.spaceWidth;
    l.height:=2*D.display.spaceHeight;

    IF l.labeled THEN
      l.labelTxt:=S.CreateSegment();
      l.labelTxt.SetParent(l);
      l.labelTxt.SetStringWidth(3);
      l.labelTxt.SetForeground(l.onColor);
      l.labelTxt.CalcSize;

      IF l.vertical THEN
        l.width:=U.MaxLong(l.width,l.labelTxt.oWidth);
        INC(l.height,D.display.spaceHeight DIV 2 + l.labelTxt.oHeight);
      ELSE
        INC(l.width,D.display.spaceWidth DIV 2 + l.labelTxt.oWidth);
        l.height:=U.MaxLong(l.height,l.labelTxt.oHeight);
      END;
    END;

    l.minWidth:=l.width;
    l.minHeight:=l.height;

    l.CalcSize^;
  END CalcSize;

  PROCEDURE (l : Load) SetRange*(bottom,top : LONGINT);

    (**
      Set the bottom and top value the object should use for displaying.

      By default @oparam{bottom} is set to @code{0} and @oparam{top} is set
      to @code{100}.
    *)

  BEGIN
    IF (bottom#l.bottom) OR (top#l.top) THEN
      l.bottom:=bottom;
      l.top:=top;

      IF l.visible THEN
        l.Redraw;
      END;
    END;
  END SetRange;

  PROCEDURE (l : Load) DrawLoad;

    (**
      Refresh loadmeter and text.
    *)

  VAR
    boxWidth,
    boxHeight,
    lines,
    current,
    top,left,
    mark,help,
    maxMark,
    mediumMark,
    value      : LONGINT;
    text       : ARRAY 4 OF CHAR;
    draw       : D.DrawInfo;

  BEGIN
    draw:=l.GetDrawInfo();


    IF l.current.IsNull() THEN
      value:=l.bottom;
    ELSE
      value:=l.current.GetLongint();
    END;

    boxHeight:=l.height;
    boxWidth:=l.width;

    IF l.labeled THEN
      IF l.vertical THEN
        DEC(boxHeight,D.display.spaceHeight DIV 2+l.labelTxt.oHeight);
      ELSE
        DEC(boxWidth,D.display.spaceWidth DIV 2+l.labelTxt.oWidth);
      END;
    END;

    IF l.vertical THEN
      lines:=boxHeight DIV (l.prefs(Prefs).gap*2);
    ELSE
      lines:=boxWidth DIV (l.prefs(Prefs).gap*2);
    END;

    help:=((value-l.bottom)*100) DIV (l.top-l.bottom+1);

    mark:=(help*lines) DIV 100;
    IF (help*lines) MOD 100>=50 THEN
      INC(mark);
    END;

    maxMark:=(75*lines) DIV 100;
    IF (75*lines) MOD 100>=50 THEN
      INC(maxMark);
    END;

    mediumMark:=(50*lines) DIV 100;
    IF (50*lines) MOD 100>=50 THEN
      INC(mediumMark);
    END;

    IF l.labeled THEN
      help:=((value-l.bottom)*100) DIV (l.top-l.bottom+1);
      IF ((value-l.bottom)*100) DIV (l.top-l.bottom+1)>=50 THEN
        INC(help);
      END;
      IF help>=75 THEN
        l.labelTxt.SetForeground(l.maxColor);
      ELSIF help>=50 THEN
        l.labelTxt.SetForeground(l.mediumColor);
      ELSE
        l.labelTxt.SetForeground(l.onColor);
      END;
      co.IntToStr(help,text);
      IF help<100 THEN
        IF help>=10 THEN
          str.Insert(" ",0,text);
        ELSE
          str.Insert("  ",0,text);
        END;
      END;
      l.labelTxt.SetString(text);
    END;

    current:=1;
    IF l.vertical THEN
      top:=l.y;
      left:=l.x+(l.width-boxWidth) DIV 2;
      WHILE current<=lines DO
        IF current>lines-mark THEN
          IF current<=lines-maxMark THEN
            draw.PushForeground(l.maxColor);
          ELSIF current<=lines-mediumMark THEN
            draw.PushForeground(l.mediumColor);
          ELSE
            draw.PushForeground(l.onColor);
          END;
        ELSE
          draw.PushForeground(l.offColor);
        END;
        draw.FillRectangle(left,top,boxWidth,l.prefs(Prefs).gap);
        draw.PopForeground;
        INC(top,l.prefs(Prefs).gap*2);
        INC(current);
      END;
      IF l.labeled THEN
        l.labelTxt.Move(l.x+(l.width-l.labelTxt.oWidth) DIV 2,
                        l.y+l.height-1-l.labelTxt.oHeight);
        l.labelTxt.Draw(l.oX,l.oY,l.oWidth,l.oHeight);
      END;
    ELSE
      top:=l.y+(l.height-boxHeight) DIV 2;
      left:=l.x;
      WHILE current<=lines DO
        IF current<=mark THEN
          IF current>maxMark THEN
            draw.PushForeground(l.maxColor);
          ELSIF current>mediumMark THEN
            draw.PushForeground(l.mediumColor);
          ELSE
            draw.PushForeground(l.onColor);
          END;
        ELSE
          draw.PushForeground(l.offColor);
        END;
        draw.FillRectangle(left,top,l.prefs(Prefs).gap,boxHeight);
        draw.PopForeground;
        INC(left,l.prefs(Prefs).gap*2);
        INC(current);
      END;
    END;
  END DrawLoad;

  PROCEDURE (l : Load) Draw*(x,y,w,h : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    IF ~l.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    l.Draw^(x,y,w,h);

    draw:=l.GetDrawInfo();

    l.DrawBackground(l.x,l.y,l.width,l.height);

    l.DrawLoad;
  END Draw;

  PROCEDURE (l : Load) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF l.visible THEN
      l.DrawLoad;
    END;
  END Resync;

  PROCEDURE (l : Load) Free*;

  BEGIN
    D.display.FreeColor(l.onColor);
    D.display.FreeColor(l.mediumColor);
    D.display.FreeColor(l.maxColor);
  END Free;

  PROCEDURE CreateLoad*():Load;

    (**
      Creates a new instance of @otype{Load}.
    *)

  VAR
    load : Load;

  BEGIN
    NEW(load);
    load.Init;

    RETURN load;
  END CreateLoad;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Load.