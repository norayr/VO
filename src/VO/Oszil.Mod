MODULE VO:Oszil;

  (**
    Implements @otype{Oszil}.
  *)

  (*
    Implements a onszilloskope-like object.
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

IMPORT BG := VO:Base:Background,
       D  := VO:Base:Display,
       F  := VO:Base:Frame,
       O  := VO:Base:Object,

       S  := VO:Model:DataStream,

       G  := VO:Object;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;


  Points     = POINTER TO ARRAY OF LONGINT;

  Oszil*     = POINTER TO OszilDesc;
  OszilDesc* = RECORD (G.ImageDesc)
                 (**
                   An oszilloscope-like object to display a continious
                   number of values in (near) timeline by using a two
                   dimensional graph, where the values is represented by the
                   y-axis and the time by the x-axis. The new values are scrolled
                   in from right to left.

                   More then one value can be shown. Different colors can be used
                   for different values.
                 *)
                 top,
                 bottom,
                 horizInt,
                 vertInt,
                 min-,max-  : LONGINT;
                 startPos   : LONGINT;
                 points     : POINTER TO ARRAY OF Points;
                 colors-    : POINTER TO ARRAY OF D.Color;
                 count      : LONGINT;
                 model      : S.StreamLongModel;
                 framed     : BOOLEAN;
                 foreColor-,
                 scaleColor : D.Color;
               END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.blackColorIndex));

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.single);
    ELSE
      p.frame:=F.CreateFrame(F.double3DIn);
    END;
  END Initialize;

  PROCEDURE (o : Oszil) Init*;

  BEGIN
    o.Init^;

    o.SetPrefs(prefs);

    o.framed:=TRUE;

    o.top:=100;
    o.bottom:=0;
    o.horizInt:=10;
    o.vertInt:=10;

    o.min:=0;
    o.max:=0;

    o.model:=NIL;

    o.startPos:=0;

    o.foreColor:=D.warnColor;
    o.scaleColor:=D.shadowColor;

    NEW(o.points,1);
    NEW(o.points[0],1);
    o.points[0][0]:=0;
    NEW(o.colors,1);
    o.colors[0]:=o.foreColor;
    o.count:=0;
  END Init;

  PROCEDURE (o : Oszil) ShowFrame*(framed : BOOLEAN);

    (**
      Tell, if the object should be framed. Defaults to @code{TRUE}.
    *)

  BEGIN
    (* We cannot switch back to using no frame if we already generated one *)
(*    ASSERT(o.objectFrame=NIL);*)

    o.framed:=framed;
  END ShowFrame;

  PROCEDURE (o : Oszil) CalcMinMax();

  VAR
    x,y : LONGINT;

  BEGIN
    o.min:=o.points[0][0];
    o.max:=o.points[0][0];

    FOR y:=0 TO LEN(o.points^)-1 DO
      FOR x:=0 TO o.count-1 DO
        IF o.points[y][x]>o.max THEN
          o.max:=o.points[y][x];
        ELSIF o.points[y][x]<o.min THEN
          o.min:=o.points[y][x];
        END;
      END;
    END;
  END CalcMinMax;

  PROCEDURE (o : Oszil) ResizePoints(width : LONGINT);

  VAR
    help : Points;
    x,y  : LONGINT;

  BEGIN

    (* TODO: Create o.points if NIL *)

    FOR y:=0 TO LEN(o.points^)-1 DO
      NEW(help,width);
      IF o.points[y]#NIL THEN
        IF LEN(o.points[y]^)<=width THEN
          FOR x:=0 TO o.count-1 DO
            help[x]:=o.points[y][x];
          END;
        ELSE
          IF o.count>width THEN
            FOR x:=0 TO width-1 DO
              help[x]:=o.points[y][x+o.count-width];
            END;
            o.count:=width;
          ELSE
            FOR x:=0 TO o.count-1 DO
              help[x]:=o.points[y][x];
            END;
          END;
        END;
      END;

      o.points[y]:=help;
    END;

    o.CalcMinMax;
  END ResizePoints;

  PROCEDURE (o : Oszil) ResizeSize(size : LONGINT);

  VAR
    x : LONGINT;

  BEGIN
    NEW(o.points,size);
    NEW(o.colors,size);
    FOR x:=0 TO size-1 DO
      o.colors[x]:=o.foreColor;
      o.points[x]:=NIL;
    END;
    (* TODO: try to save as many old color settings as possible *)

    IF G.inited IN o.flags THEN
      o.ResizePoints(o.width);
    ELSE
      o.ResizePoints(1);
    END;
    o.count:=0;
  END ResizeSize;

  PROCEDURE (o : Oszil) DrawPoint(x : LONGINT; scroll : BOOLEAN);

  VAR
    xo,yo,h,pos,y : LONGINT;
    draw          : D.DrawInfo;

  BEGIN
    draw:=o.GetDrawInfo();

    xo:=o.x;
    h:=o.height;
    yo:=o.y+h-1;

    IF scroll THEN
      draw.CopyArea(o.x+1,o.y,
                    o.width-1,
                    o.height,
                    o.x,o.y);

      o.DrawBackground(o.x+o.width-1,o.y,1,o.height);
    END;

    draw.InstallClip(o.x,o.y,o.width,o.height);


    IF scroll THEN
      draw.PushForeground(o.scaleColor);
      IF (o.horizInt>0) & ((o.startPos+o.count) MOD o.vertInt#0) THEN
        pos:=(o.bottom DIV o.horizInt-1)*o.horizInt;
        WHILE pos<=(o.top DIV o.horizInt+1)*o.horizInt DO
          draw.DrawPoint(o.x+o.width-1,
                          yo-((pos-o.bottom)*h) DIV (o.top-o.bottom+1));
          INC(pos,o.horizInt);
        END;
      END;

      IF (o.vertInt>0) & ((o.startPos+o.count) MOD o.vertInt=0) THEN
        draw.DrawLine(o.x+o.width-1,
                      o.y,
                      o.x+o.width-1,
                      o.y+o.height-1);
      END;
      draw.PopForeground;
      INC(o.startPos);
    END;

    DEC(x); (* because of index starting from 0 where x starts with 1 *)

    FOR y:=0 TO LEN(o.points^)-1 DO
      draw.PushForeground(o.colors[y]);

      IF x=0 THEN
        draw.DrawPoint(xo+x,
                       yo-((o.points[y][x]-o.bottom)*h) DIV (o.top-o.bottom+1));
      ELSE
        draw.DrawLine(xo+x-1,
                      yo-((o.points[y][x-1]-o.bottom)*h) DIV (o.top-o.bottom+1),
                      xo+x,
                      yo-((o.points[y][x]-o.bottom)*h) DIV (o.top-o.bottom+1));
      END;
      draw.PopForeground;
    END;

    draw.FreeLastClip;
  END DrawPoint;

  PROCEDURE (o : Oszil) SetRange*(bottom,top : LONGINT);

    (**
      Set the bottom and top value of the visible area. Values outside this area
      are clipped and thus will not be displayed.
    *)

  BEGIN
    IF (top#o.top) OR (bottom#o.bottom) THEN
      o.top:=top;
      o.bottom:=bottom;

      IF o.visible THEN
        o.Redraw;
      END;
    END;

    o.CalcMinMax;
  END SetRange;

  PROCEDURE (o : Oszil) SetInterval*(horizInt,vertInt : LONGINT);

    (**
      The the interval at which horizontal and vertical
      scaling lines will be displayed.
    *)

  BEGIN
    IF (horizInt#o.horizInt) OR (vertInt#o.vertInt)THEN
      o.horizInt:=horizInt;
      o.vertInt:=vertInt;

      IF o.visible THEN
        o.Redraw;
      END;
    END;
  END SetInterval;

  PROCEDURE (o : Oszil) SetModel*(model : O.Model);

    (**
      Set the streaming model (@otype{S.StreamLongModel}) which represents
      the current value.
    *)

  BEGIN
    IF o.model#NIL THEN
      o.UnattachModel(o.model);
    END;
    IF (model#NIL) & (model IS S.StreamLongModel) THEN
      o.model:=model(S.StreamLongModel);
      o.AttachModel(o.model);
      o.ResizeSize(LEN(o.model.value^));
    ELSE
      o.model:=NIL;
    END;
    IF o.visible THEN
      o.Redraw;
    END;
    o.CalcMinMax;
  END SetModel;

  PROCEDURE (o : Oszil) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=o.model
  END ModelAccepted;

  PROCEDURE (o : Oszil) SetColor*(channel : LONGINT; color : D.Color);

    (**
      Set a color for the given channel of the channel model. Colors will currently
      be reset when the channel size of the model changes.
    *)

  BEGIN
    o.colors[channel]:=color;
  END SetColor;

  PROCEDURE (o : Oszil) CalcSize*;

  VAR
    y : LONGINT;

  BEGIN
    IF ~(G.inited IN o.flags) THEN
      IF D.display.colorMode=D.monochromeMode THEN
        o.foreColor:=D.blackColor;
        o.scaleColor:=D.blackColor;
      ELSE
        D.display.AllocateNamedColor("green",o.foreColor,o.foreColor);
      END;
    END;

    FOR y:=0 TO LEN(o.colors^)-1 DO
      (* Don´t overwrite custom set colors *)
      IF o.colors[y]=D.warnColor THEN
        o.colors[y]:=o.foreColor;
      END;
    END;

    o.width:=10;
    o.height:=10;

    IF o.framed THEN
      o.SetObjectFrame(o.prefs.frame);
    ELSE
      o.SetObjectFrame(F.CreateFrame(F.none));
    END;

    o.minWidth:=o.width;
    o.minHeight:=o.height;

    o.CalcSize^;

    o.ResizePoints(o.width);
  END CalcSize;

  PROCEDURE (o : Oszil) Draw*(x,y,w,h : LONGINT);

  VAR
    pos,pos2,
    xo,yo     : LONGINT;
    draw      : D.DrawInfo;

  BEGIN
    IF ~o.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    o.Draw^(x,y,w,h);

    draw:=o.GetDrawInfo();

    IF o.width#LEN(o.points[0]^) THEN
      o.ResizePoints(o.width);
    END;

    o.DrawBackground(o.x,o.y,o.width,o.height);

    draw.InstallClip(o.x,o.y,o.width,o.height);

    xo:=o.x;
    yo:=o.y+o.height-1;

    draw.PushForeground(o.scaleColor);
    IF o.horizInt>0 THEN
      pos:=(o.bottom DIV o.horizInt-1)*o.horizInt;
      WHILE pos<=(o.top DIV o.horizInt+1)*o.horizInt DO
        draw.DrawLine(xo,
                      yo-((pos-o.bottom)*o.height) DIV (o.top-o.bottom+1),
                      o.x+o.width-1,
                      yo-((pos-o.bottom)*o.height) DIV (o.top-o.bottom+1));
        INC(pos,o.horizInt);
      END;
    END;

    IF o.vertInt>0 THEN
      FOR pos:=0 TO LEN(o.points[0]^)-1 DO
        IF (o.startPos+pos) MOD o.vertInt=0 THEN
          draw.DrawLine(o.x+pos,
                        o.y,
                        o.x+pos,
                        o.y+o.height-1);
        END;
      END;
    END;
    draw.PopForeground;

    FOR pos2:=0 TO LEN(o.points^)-1 DO
      draw.PushForeground(o.colors[pos2]);
      FOR pos:=0 TO o.count-1 DO
        IF pos=0 THEN
          draw.DrawPoint(xo+pos,
                        yo-((o.points[pos2][pos]-o.bottom)*o.height) DIV (o.top-o.bottom+1));
        ELSE
          draw.DrawLine(xo+pos-1,
                        yo-((o.points[pos2][pos-1]-o.bottom)*o.height) DIV (o.top-o.bottom+1),
                        xo+pos,
                        yo-((o.points[pos2][pos]-o.bottom)*o.height) DIV (o.top-o.bottom+1));
        END;
      END;
      draw.PopForeground;
    END;

    draw.FreeLastClip;
  END Draw;

  PROCEDURE (o : Oszil) Resync*(model : O.Model; msg : O.ResyncMsg);

  VAR
    x,y : LONGINT;

  BEGIN
    IF LEN(o.points^)#LEN(o.model.value^) THEN
      o.ResizePoints(LEN(o.model.value^));
    END;

    IF o.count>=LEN(o.points[0]^) THEN
      FOR y:=0 TO LEN(o.points^)-1 DO
        FOR x:=0 TO LEN(o.points[y]^)-2 DO
          o.points[y][x]:=o.points[y][x+1];
        END;
      END;
    ELSE
      INC(o.count);
    END;

    FOR y:=0 TO LEN(o.points^)-1 DO
      o.points[y][o.count-1]:=o.model.value[y];
    END;

    o.CalcMinMax;

    IF o.visible THEN
      o.DrawPoint(o.count,o.count>=LEN(o.points[0]^));
    END;
  END Resync;

  PROCEDURE (o : Oszil) Free*;

  BEGIN
    D.display.FreeColor(o.foreColor);
  END Free;

  PROCEDURE CreateOszil*():Oszil;

    (**
      Creates a new instance of @otype{Oszil}.
    *)

  VAR
    oszil : Oszil;

  BEGIN
    NEW(oszil);
    oszil.Init;

    RETURN oszil;
  END CreateOszil;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Oszil.