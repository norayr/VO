(**
  VOPlot - Visual Oberon object to plot bar charts, linear, semi-log
  and full logarithmic plots complete with labels and legends.
**)
MODULE VO:Plot;

(*
    VOPlot - Visual Oberon object to plot bar charts, linear, semi-log
    and full logarithmic plots complete with labels and legends.
    Copyright (C) 1998 Michael Griebling

    TODO: (Anyone is welcome to get these items working.  Most of
           the required source code is already included but needs
           to be made to work as a VO gadget in the Draw method.)

    1) Get barcharts, line plots, and scatter plots working.
    2) Get information box and min/max labelling working.
    3) Get colour selection stuff working -- limited by VO.

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

IMPORT D   := VO:Base:Display,
       O   := VO:Base:Object,

       FM  := VO:Model:Function,

       G   := VO:Object,

       m   := LRealMath,
              LowLReal,
       str := Strings;

CONST
  (* PlotKindType *)
  Normal * = 0;
  LogX   * = 1;
  LogY   * = 2;
  Log    * = 3;
  Line   * = 4;
  Bar    * = 5;

  (* PositionType *)
  UpperLeft   * = 0;
  UpperMiddle * = 1;
  UpperRight  * = 2;
  LowerLeft   * = 3;
  LowerMiddle * = 4;
  LowerRight  * = 5;

  (* ClassType *)
  Left   * = 0;
  Right  * = 1;
  Top    * = 2;
  Bottom * = 3;

TYPE
  String       * = ARRAY 1024 OF CHAR;

  LabelProc    * = PROCEDURE(x : INTEGER; VAR labels : ARRAY OF CHAR);

  PlotKindType * = SHORTINT;

  LineType     * = ARRAY 80 OF CHAR;
  PositionType * = SHORTINT;

  Points     = RECORD x, y: LONGREAL END;
  PointArray = POINTER TO ARRAY OF Points;

  ClassType * = SHORTINT;
  ClassSet  * = SET;
  PlotSet   * = SET;

CONST
  XLog = {LogX, Log};
  YLog = {LogY, Log};

TYPE
  Plot * = POINTER TO PlotDesc;
  PlotDesc * =
    RECORD (G.ImageDesc)
      model       : FM.FunctionLRealModel; (* The model used or value calculation *)
      Points      : PointArray;       (* quick refresh points       *)
      PlotIs      : PlotKindType;     (* type of plot               *)
      MinorColour : D.Color;          (* colour for the minor grids *)
      GridColour  : D.Color;          (* colour for the grid lines  *)
      TextColour  : D.Color;          (* colour to use for text     *)
      PlotColour  : D.Color;          (* colour to use for the plot *)
      GetLabel    : LabelProc;        (* user label routine         *)
      ScatterPlot : BOOLEAN;          (* scatter plots              *)
      ScatterChar : ARRAY 2 OF CHAR;  (* scatter plot character     *)
      ZeroLineOn  : BOOLEAN;          (* zero line on/off           *)
      Minx-,                          (* world min. x-coordinate    *)
      Miny-,                          (* world min. y-corrdinate    *)
      Maxx-,                          (* world max. x-coordinate    *)
      Maxy-       : LONGREAL;         (* world max. y-coordinate    *)
      GMxx,                           (* plot max. x-coordinate     *)
      GMxy        : LONGINT;          (* plot max. y-coordinate     *)
      Divx,                           (* major x & y divisions      *)
      Divy,
      SubDivx,                        (* minor x & y divisions      *)
      SubDivy,
      Decx, Decy  : INTEGER;          (* x & y axes decimal places  *)
      TopBorder   : LONGINT;          (* top border width           *)
      xscale,                         (* x/y scaling                *)
      yscale      : LONGREAL;
      xoff, yoff  : LONGINT;          (* plot offsets               *)
      GridDrawn   : BOOLEAN;          (* draw once                  *)
      CopyOfAPlot : BOOLEAN;          (* not original               *)
    END;

(*-------------------------------------------------------*)
(* The following are a number of utility routines used   *)
(* only within this module to facilitate the graphing.   *)


CONST
  ZERO  = 0.0D0;
  TEN   = 10.0D0;


PROCEDURE RealToString * (num:LONGREAL;
                          VAR str:ARRAY OF CHAR;
                          minchars:INTEGER;
                          fracchars:INTEGER;
                          pad:CHAR): BOOLEAN;
CONST
  RAcc = 15; (* digits of accuracy in LONGREAL we can count on *)
VAR
  D,s,exp : INTEGER;
  digit   : LONGINT;
  buffer  : ARRAY 80 OF CHAR;
  pos,i,j : INTEGER;
  useExp  : BOOLEAN;

  PROCEDURE PutCh(c:CHAR);
  BEGIN
    buffer[pos]:=c;
    INC(pos)
  END PutCh;

  PROCEDURE PutNumDig(c:LONGINT);
  BEGIN
    buffer[pos]:=CHR(c+ORD("0"));
    INC(pos);
  END PutNumDig;

  PROCEDURE PutExp(exp:INTEGER);
  BEGIN
    PutCh('E');
    IF exp<0 THEN
      PutCh('-');
      exp:=-exp;
    END;

    IF exp>10 THEN
      PutNumDig((exp MOD 100) DIV 10);
    END;

    PutNumDig(exp MOD 10);
  END PutExp;

BEGIN
  pos:=0;

  D := ABS(fracchars);
  useExp:= (fracchars < 0);

  IF num < ZERO THEN
    PutCh("-");
    num := -num;
  END;

  IF ABS(num) < 1.0E-5 THEN
    exp := 0;
    num := ZERO
  ELSE
    (* round to D digits to the right of the decimal *)
    IF D > RAcc THEN
      D := RAcc;
    END;
    num:=num+m.ipower(TEN, -D)*0.5;

    (* normalize number *)
    exp := LowLReal.exponent10(num);
    num := num / m.ipower(TEN, exp);

    (* check if rounding changed first digit of mantissa *)
    (* i.e., 9.99999 changed to 10.00000 *)
    IF num >= TEN THEN
      num := num / TEN;
      INC(exp);
    END;

    (* special case when ABS(num) < 1.0 *)
    IF num < 1.0 THEN
      num := num * TEN;
      DEC(exp);
    END;

    (* check if this number can be represented
       in ordinary form *)
    IF ABS(exp) > RAcc THEN
      useExp := TRUE;
    END;
  END;

  IF useExp THEN
    PutNumDig(ENTIER(LowLReal.intpart(num)));
    PutCh(".");

    j:=D;
    WHILE j>0 DO
      num := (num - LowLReal.intpart(num)) * TEN;
      PutNumDig(ENTIER(LowLReal.intpart(num)));
      DEC(j);
    END;

    PutExp(exp);

  ELSE
    s := exp;  (* begin with digits to left of decimal *)
    IF exp < 0 THEN
      s := 0;  (* begin at zero to left of decimal *)
    END;

    i := 0;
    FOR j := s TO (-D) BY -1 DO
      IF (i > RAcc) OR (exp < 0) THEN
      (* use dummy zeros to pad right *)
        PutCh("0");
      ELSE
        digit:=ENTIER(LowLReal.intpart(num));
        PutNumDig(digit);
        num := (num - digit) * TEN;
      END;
      INC(i);
      INC(exp);
      IF j = 0 THEN
        PutCh(".");
      END;
    END;
  END;

  PutCh(0X);

  IF (minchars>LEN(str)-1) OR (pos>LEN(str)-1) THEN
    RETURN FALSE;
  END;

  i:=0;                                 (* put padding *)
  WHILE i+pos<=minchars DO
    str[i]:=pad;
    INC(i);
  END;

  j:=-1;
  (* copy data into destination *)
  REPEAT
    INC(j);
    str[i]:=buffer[j];
    INC(i);
  UNTIL buffer[j]=0X;

  IF (j > 0) & (str[j-1] = '.') THEN
    (* remove trailing '.' *)
    str[j-1] := 0X;
  END;

  RETURN TRUE;
END RealToString;


PROCEDURE LogOf(x : LONGREAL) : LONGREAL;
BEGIN
  IF x <= 0.0 THEN (* capture illegal values *)
    RETURN 0.0;    (* and return log(1)      *)
  END;
  RETURN m.log(x, 10);
END LogOf;


PROCEDURE (p : Plot) xyToCoords(x, y       : LONGREAL;
                                VAR xG, yG : LONGINT);
(* Convert floating point world coordinates to graph space
   coordinates. *)
BEGIN
  xG := m.round((x-p.Minx)*(p.GMxx-p.x)/(p.Maxx-p.Minx))+p.x;
  yG := p.GMxy-m.round((y-p.Miny)*(p.GMxy-p.y)/(p.Maxy-p.Miny))
END xyToCoords;


PROCEDURE (p : Plot) CoordsToxy(xG, yG   : LONGINT;
                                VAR x, y : LONGREAL);
(* Convert graph space coordinates to floating point world
   coordinates. *)
BEGIN
  x := (xG-p.x)*(p.Maxx-p.Minx)/(p.GMxx-p.x)+p.Minx;
  y := (p.GMxy-yG)*(p.Maxy-p.Miny)/(p.GMxy-p.y)+p.Miny
END CoordsToxy;


PROCEDURE (p : Plot) OffsetPoint(VAR x, y : LONGINT);
(* Offset the graph points by the plot amounts *)
BEGIN
  INC(x, p.xoff);
  INC(y, p.yoff);
END OffsetPoint;


PROCEDURE (p : Plot) DrawLine(Colour             : D.Color;
                              Gx1, Gy1, Gx2, Gy2 : LONGINT;
                              draw : D.DrawInfo);
(* Line clipping algorithm : two points which make up a
   line are passed (Gx1, Gy1) and (Gx2, Gy2) to be
   clipped within the Plot space.  NOTE: The Amiga screen
   coordinates have y = 0 at the top of the screen.

   From an algorithm published in "Microcomputer Graphics
   for the IBM PC" by Roy E. Myers. *)
VAR
  x, y    : ARRAY 4 OF LONGINT;
  xl, xh  : LONGINT;
  yl, yh  : LONGINT;
  Bound   : ARRAY 4 OF ClassSet;
  Discard : BOOLEAN;
  i       : INTEGER;

  PROCEDURE Classify (VAR Boundary : ClassSet;
                      x, y         : LONGINT);
  BEGIN
    Boundary := {};           (* assume inside bounds  *)
    IF x < xl THEN
      INCL(Boundary, Left);   (* outside left bounds   *)
    ELSIF x > xh THEN
      INCL(Boundary, Right);  (* outside right bounds  *)
    END;
    IF y > yh THEN
      INCL(Boundary, Bottom); (* outside bottom bounds *)
    ELSIF y < yl THEN
      INCL(Boundary, Top);    (* outside top bounds    *)
    END;
  END Classify;

  PROCEDURE Clip (Boundary : ClassSet);
  VAR
    dy, dx : LONGINT;
  BEGIN
    (* NOTE: 32-bit calculations used to avoid range errors *)
    dy := y[2] - y[1];
    dx := x[2] - x[1];
    IF Left IN Boundary THEN
      x[i] := xl;
      y[i] := y[1] + dy * (xl - x[1]) DIV dx;
    ELSIF Right IN Boundary THEN
      x[i] := xh;
      y[i] := y[1] + dy * (xh - x[1]) DIV dx;
    ELSIF Top IN Boundary THEN
      x[i] := x[1] + dx * (yl - y[1]) DIV dy;
      y[i] := yl;
    ELSIF Bottom IN Boundary THEN
      x[i] := x[1] + dx * (yh - y[1]) DIV dy;
      y[i] := yh;
    END
  END Clip;

  PROCEDURE PlotLine (x1, y1, x2, y2 : LONGINT);
  (* Draw a clipped line to the screen. *)
  BEGIN
    draw.PushForeground(Colour);    (* set line colour *)
    IF p.ScatterPlot THEN
      (* move to the character centre and place char *)
      draw.DrawString(x1-D.display.spaceWidth DIV 2, y1+D.display.spaceHeight DIV 2, p.ScatterChar, 1)
    ELSE
      (* move to 1st pt and draw to 2nd point *)
      draw.DrawLine(x1, y1, x2, y2)
    END;
    draw.PopForeground
  END PlotLine;

BEGIN

  (* Initialize clipping routines *)
  x[1] := Gx1;  y[1] := Gy1;
  x[2] := Gx2;  y[2] := Gy2;
  xl := p.x; xh := p.GMxx;
  yl := p.y; yh := p.GMxy;

  (* Classify the endpoints *)
  Classify(Bound[1], x[1], y[1]);
  Classify(Bound[2], x[2], y[2]);

  (* Perform the line clipping *)
  IF Bound[1] + Bound[2] = {} THEN
    (* Within plot area -- just draw the line *)
    PlotLine(x[1], y[1], x[2], y[2]);
  ELSE
    (* Just output a clipped line segment *)
    i := 1;
    REPEAT
      Discard := Bound[1] * Bound[2] # {};
      IF ~Discard THEN
        IF Bound[i] # {} THEN
          (* Handle the line clipping *)
          Clip(Bound[i]);
          Classify(Bound[i], x[i], y[i]);
        ELSE
          INC(i);
        END;
      END;
    UNTIL (i > 2) OR Discard;
    IF ~Discard THEN
      PlotLine(x[1], y[1], x[2], y[2]);  (* Clipped line *)
    END;
  END;
END DrawLine;


PROCEDURE (p : Plot) IntPlotLine(Colour         : D.Color;
                                 x1, y1, x2, y2 : LONGREAL;
                                 draw           : D.DrawInfo);
(* Draw a line between points (x1,y1) and (x2,y2).

   This routine accepts log(x) values and displays them
   properly during log plots. *)
VAR
  Gx1, Gy1, Gx2, Gy2 : LONGINT;
BEGIN
  p.xyToCoords(x1, y1, Gx1, Gy1);  (* to pixel coords *)
  p.xyToCoords(x2, y2, Gx2, Gy2);
  p.OffsetPoint(Gx1, Gy1);         (* offset plot *)
  p.OffsetPoint(Gx2, Gy2);
  p.DrawLine(Colour, Gx1, Gy1, Gx2, Gy2,draw);
END IntPlotLine;


PROCEDURE (p : Plot) PlotBar(Colour : D.Color;
                             width  : LONGREAL;
                             x, y   : LONGREAL;
                             draw : D.DrawInfo);
(* Draw a bar centered around x of height y and width
   across. *)
VAR
  Half : LONGREAL;
  Gxl, Gyl, Gxu, Gyu : LONGINT;
BEGIN
  Half := ABS(width) / 2.0;
  IF y >= 0.0 THEN
    p.xyToCoords(x-Half, y, Gxl, Gyl);
    p.xyToCoords(x+Half, 0.0, Gxu, Gyu);
  ELSE
    p.xyToCoords(x-Half, 0.0, Gxl, Gyl);
    p.xyToCoords(x+Half, y, Gxu, Gyu);
  END;

  IF Gyl # Gyu THEN
    p.OffsetPoint(Gxl, Gyl);    (* offset bar *)
    p.OffsetPoint(Gxu, Gyu);
    draw.PushForeground(Colour);
    draw.FillRectangle(Gxl, Gyl, Gxu-Gxl, Gyu-Gyl);
    draw.PopForeground
  END
END PlotBar;


PROCEDURE (p : Plot) LabelX (Label : ARRAY OF CHAR;
                             x, y  : LONGINT;
                             draw : D.DrawInfo);
(* Place text horizontally on the plot *)
BEGIN
  (* Change bounds of screen to allow text outside plot *)
  IF (x >= 2)  & (x <= p.width-1) &
     (y >= 12) & (y <= p.height-1) THEN
    draw.PushForeground(p.TextColour); (* set text colour *)
    draw.DrawString(x, y, Label, str.Length(Label));
    draw.PopForeground
  END
END LabelX;


PROCEDURE (p : Plot) LabelY (Label : ARRAY OF CHAR;
                             x, y  : LONGINT;
                             draw : D.DrawInfo);
(* Place text vertically on the plot *)
VAR
  ChCnt : LONGINT;
  Str   : ARRAY 2 OF CHAR;
BEGIN
  Str[1] := 0X;
  FOR ChCnt := 1 TO str.Length(Label) DO
    Str[0] := Label[ChCnt-1];
    p.LabelX(Str, x, y,draw);
    INC(y, D.display.spaceHeight);
  END;
END LabelY;


PROCEDURE (p : Plot) PlotXLabel(int  : INTEGER;
                                x, y : LONGREAL;
                                draw : D.DrawInfo);
(* Place a label on the x-axis *)
VAR
  Gx, Gy : LONGINT;
  xlog   : LONGREAL;
  s      : ARRAY 40 OF CHAR;
BEGIN
  (* compensate for log scales along x-axis *)
  IF p.PlotIs IN XLog THEN
    xlog := m.power(TEN, x);
  ELSE
    xlog := x;
  END;

  (* produce the x-axis labels *)
  IF p.GetLabel#NIL THEN
    p.GetLabel(int, s);   (* call-back to get label   *)
  ELSIF ~RealToString(xlog, s, 2, p.Decx, " ") THEN
    s := "***";         (* number conversion failed *)
  END;

  (* label the axis *)
  p.xyToCoords(x, y, Gx, Gy);
  DEC(Gx, str.Length(s) * D.display.spaceWidth DIV 2);
  INC(Gy, 9 * D.display.spaceHeight DIV 4);
  p.LabelX(s, Gx, Gy,draw);
END PlotXLabel;


PROCEDURE (p : Plot) PlotYLabel(x, y : LONGREAL; draw : D.DrawInfo);
(* Place a label on the y-axis *)
VAR
  Gx, Gy : LONGINT;
  ylog   : LONGREAL;
  s      : ARRAY 40 OF CHAR;
BEGIN
  (* compensate for log scales along y-axis *)
  IF p.PlotIs IN YLog THEN
    ylog := m.power(TEN, y);
  ELSE
    ylog := y;
  END;

  (* produce the y-axis labels *)
  IF ~RealToString(ylog, s, 2, p.Decy, " ") THEN
    s := "***";
  END;
  p.xyToCoords(x, y, Gx, Gy);
  DEC(Gx, (str.Length(s) + 1) * D.display.spaceWidth);
  INC(Gy, D.display.spaceHeight DIV 2);
  p.LabelX(s, Gx, Gy,draw);
END PlotYLabel;


PROCEDURE (p : Plot) ClearPlot*;
(* Clear the plot area *)
VAR
  xl, xu, yl, yu : LONGINT;
  draw           : D.DrawInfo;
BEGIN
  draw:=p.GetDrawInfo();

  draw.PushForeground(D.backgroundColor);  (* clear to background colour *)
  xl := 8; xu := xl+p.width;
  yl := 8; yu := yl+p.height;
  draw.FillRectangle(xl, yl, xu-xl, yu-yl);
  p.GridDrawn := FALSE;
  draw.PopForeground
END ClearPlot;


PROCEDURE (p : Plot) SetPlotOffset * (xoff, yoff : LONGINT);
(* Alter the current plot base position -- useful for
   realigning bar charts or giving three dimensional
   looking graphs *)
BEGIN
  p.xoff := xoff;
  p.yoff := yoff;
END SetPlotOffset;


PROCEDURE (p : Plot) DrawGrid(draw : D.DrawInfo);
(* Create the graph grid. *)
VAR
  vCnt, hCnt : INTEGER;
  oldx, oldy : LONGINT;
  x, y, xint, yint : LONGREAL;
  ScatterState : BOOLEAN;

  PROCEDURE PlotMinorX;
  VAR
    Cnt : INTEGER;
    xm, xi : LONGREAL;
  BEGIN
    IF p.SubDivx > 1 THEN
      (* Output the minor grid lines *)
      IF p.PlotIs IN XLog THEN
        xi := m.power(TEN, xint) / (p.SubDivx+1);
        FOR Cnt := 2 TO p.SubDivx DO
          xm := x + LogOf(Cnt * xi);
          p.IntPlotLine(p.MinorColour, xm, p.Miny, xm, p.Maxy,draw);
        END
      ELSE
        xi := xint / p.SubDivx;
        FOR Cnt := 1 TO p.SubDivx-1 DO
          xm := x + Cnt * xi;
          p.IntPlotLine(p.MinorColour, xm, p.Miny, xm, p.Maxy,draw);
        END
      END
    END
  END PlotMinorX;

  PROCEDURE PlotMinorY;
  VAR
    Cnt : INTEGER;
    ym, yi : LONGREAL;
  BEGIN
    IF p.SubDivy > 1 THEN
      (* Output the minor grid lines *)
      IF p.PlotIs IN YLog THEN
        yi := m.power(TEN, yint) / (p.SubDivy+1);
        FOR Cnt := 2 TO p.SubDivy DO
          ym := y + LogOf(Cnt * yi);
          p.IntPlotLine(p.MinorColour, p.Minx, ym, p.Maxx, ym,draw);
        END;
      ELSE
        yi := yint / p.SubDivy;
        FOR Cnt := 1 TO p.SubDivy-1 DO
          ym := y + Cnt * yi;
          p.IntPlotLine(p.MinorColour, p.Minx, ym, p.Maxx, ym,draw);
        END
      END
    END
  END PlotMinorY;

BEGIN
  (* Draw the vertical grid lines or label bars *)
  ScatterState := p.ScatterPlot;
  p.ScatterPlot := FALSE;      (* draw lines!     *)
  p.ClearPlot();               (* clear plot area *)
  oldx := p.xoff;
  oldy := p.yoff;
  p.SetPlotOffset(0, 0);       (* no grid offset  *)

  IF p.Divx > 0 THEN
    xint := (p.Maxx - p.Minx) / p.Divx;
    FOR vCnt := 0 TO p.Divx DO
      x := p.Minx + vCnt * xint;
      PlotMinorX;
      p.IntPlotLine(p.GridColour, x, p.Miny, x, p.Maxy,draw);
      p.PlotXLabel(vCnt, x, p.Miny,draw);
    END;
  END;

  (* Draw the horizontal grid lines *)
  IF p.Divy > 0 THEN
    yint := (p.Maxy - p.Miny) / p.Divy;
    FOR hCnt := 0 TO p.Divy DO
      y := p.Miny + hCnt * yint;
      PlotMinorY;
      p.IntPlotLine(p.GridColour, p.Minx, y, p.Maxx, y,draw);
      p.PlotYLabel(p.Minx, y,draw);
    END;
  END;
  p.SetPlotOffset(oldx, oldy);   (* user offset *)

  p.GridDrawn := TRUE;
  p.ScatterPlot := ScatterState;
END DrawGrid;


(*-------------------------------------------------------*)
(* The main graphing routines.                           *)

PROCEDURE Empty * () : Plot;
(* Used to initialize or pass empty plot parameters *)
BEGIN
  RETURN NIL;
END Empty;


PROCEDURE (p : Plot) SetPlotLimits * (xMin, xMax, yMin, yMax : LONGREAL);
(* Alter the current plot limits -- useful for overlaying
   plots with different minima/maxima *)
BEGIN
  p.Miny := yMin;  p.Maxy := yMax;
  p.Minx := xMin;  p.Maxx := xMax;
  IF p.PlotIs IN XLog THEN
    p.Minx := LogOf(xMin);
    IF xMax <= 0.0 THEN (* make a log multiple of xMin *)
      p.Maxx := p.Minx + p.Divx;
    ELSE
      p.Maxx := LogOf(xMax);
    END;
  END;
  IF p.PlotIs IN YLog THEN
    p.Miny := LogOf(yMin);
    IF yMax <= 0.0 THEN (* make a log multiple of yMin *)
      p.Maxy := p.Miny + p.Divy;
    ELSE
      p.Maxy := LogOf(yMax);
    END;
  END;
END SetPlotLimits;


PROCEDURE (p : Plot) SetPlotScale * (xscale, yscale : LONGREAL);
(* Alter the plot scaling along x- and y-axes *)
BEGIN
  p.xscale := ABS(xscale);
  p.yscale := ABS(yscale);

  (* limit to 1/10 reduction *)
  IF p.xscale < 0.1 THEN
    p.xscale := 0.1;
  END;
  IF p.yscale < 0.1 THEN
    p.yscale := 0.1;
  END;
END SetPlotScale;


PROCEDURE (p : Plot) SetColourMap * (ColourIndex      : INTEGER;
                                     Red, Green, Blue : INTEGER);
(* Change the set of predefined colours for the plots *)
BEGIN
  (* g.SetRGB4(i.ViewPortAddress(Plot.Window),ColourIndex,Red,Green,Blue); *)
END SetColourMap;


PROCEDURE (p : Plot) SetScatterPlot * ;
(* Set to plot single points or a scatter plot *)
BEGIN
  p.ScatterPlot := TRUE;
  p.ScatterChar := "O";   (* default character *)
END SetScatterPlot;


PROCEDURE (p : Plot) SetScatterChar * (Ch    : CHAR);
(* Change the default `O' character for scatter plots *)
BEGIN
  p.ScatterChar[0] := Ch;
END SetScatterChar;


PROCEDURE (p : Plot) ClearPlotHistory * ;
BEGIN
  p.Points:=NIL
END ClearPlotHistory;


PROCEDURE (p : Plot) Init* ;
(* Set up the initial plot characteristics *)
BEGIN
  (* Initialize the parent object *)
  p.Init^;

  (* No scaling initially *)
  p.xscale := 1.0;
  p.yscale := 1.0;

  (* Miscellaneous plot values *)
  p.PlotColour  := D.shadowColor;     (* default plot colour  *)
  p.TextColour  := D.shadowColor;     (* default text colour  *)
  p.GridColour  := D.shineColor;     (* default grid colour  *)
  p.MinorColour := D.halfShineColor;     (* minor grid colour    *)
  p.PlotIs      := Normal;
  p.GridDrawn   := FALSE;
  p.GetLabel    := NIL;         (* use internal labels  *)
  p.ScatterPlot := FALSE;       (* not a scatter plot   *)
  p.ScatterChar := "O";         (* default scatter char *)
  p.ZeroLineOn  := TRUE;        (* zero line enabled    *)
  p.CopyOfAPlot := FALSE;       (* this is a copy       *)
  p.model       := NIL;         (* function model       *)
  p.Divx        := 3;           (* default divisions    *)
  p.Divy        := 3;
  p.SubDivx     := 0;
  p.SubDivy     := 0;
  p.Decx        := 0;           (* default decimal pts  *)
  p.Decy        := 1;
  p.GMxx        := 0;           (* unknown plot limits  *)
  p.GMxy        := 0;
  p.xoff        := 0;           (* offset to fit in window *)
  p.yoff        := 0;
  p.TopBorder   := 20;          (* top border width *)

  (* Initialize the plot minimum and maximums *)
  p.SetPlotLimits(0.0, 360.0, -1.0, 1.0);

  (* Stored points information *)
  p.Points := NIL;
END Init;

(**
  Set the function model which represents the current value.
**)

PROCEDURE (p : Plot) SetModel*(model : O.Model);

BEGIN
  IF p.model#NIL THEN
    p.UnattachModel(p.model);
  END;
  IF (model#NIL) & (model IS FM.FunctionLRealModel) THEN
    p.model:=model(FM.FunctionLRealModel);
    p.AttachModel(p.model);
    p.ClearPlotHistory;
  ELSE
    p.model:=NIL;
  END;
  IF p.visible THEN
    p.Redraw;
  END;
END SetModel;

(**
  This function is used to check if an argument to SetModel
  was successfully accepted.
 **)

PROCEDURE (p : Plot) ModelAccepted * (m : O.Model):BOOLEAN;

BEGIN
  RETURN m=p.model
END ModelAccepted;

PROCEDURE (p : Plot) SetPlotKind * (kind : LONGINT);
BEGIN
  p.PlotIs:=SHORT(SHORT(kind))
END SetPlotKind;


PROCEDURE (p : Plot) SetDivisions * (xDivs, yDivs, xMinor, yMinor: LONGINT);
BEGIN
  p.Divx:=SHORT(xDivs); p.Divy:=SHORT(yDivs);
  p.SubDivx:=SHORT(xMinor); p.SubDivy:=SHORT(yMinor)
END SetDivisions;


PROCEDURE (p : Plot) SetDecimals * (xDec, yDec: LONGINT);
BEGIN
  p.Decx:=SHORT(xDec); p.Decy:=SHORT(yDec)
END SetDecimals;


PROCEDURE DonePlot * (VAR p : Plot);
(* Close off the plot -- when done *)
BEGIN
  IF p # NIL THEN
    p := NIL
  END;
END DonePlot;


PROCEDURE (p : Plot) PlotZero(draw : D.DrawInfo);
(* Plot the zero line *)
BEGIN
  (* emphasize y = 0 line *)
  IF p.ZeroLineOn THEN
    IF p.ScatterPlot THEN
      p.ScatterPlot := FALSE;
      IF ~(p.PlotIs IN YLog) THEN
        p.IntPlotLine(D.warnColor, p.Minx, 0.0, p.Maxx, 0.0,draw);
      END;
      p.ScatterPlot := TRUE;
    ELSE
      IF ~(p.PlotIs IN YLog) THEN
        p.IntPlotLine(D.warnColor, p.Minx, 0.0, p.Maxx, 0.0,draw);
      END
    END
  END
END PlotZero;


PROCEDURE (p : Plot) NewYLimits * (Fx : FM.FunctionLRealModel);
VAR
  int, x, y : LONGREAL;
BEGIN
  p.model:=Fx;
  int := 5*(p.Maxx - p.Minx) / (p.GMxx - p.x);

  (* go through the range of x values and plot y values *)
  x := p.Minx; p.Miny := 1.0E10; p.Maxy := -1.0E10;
  REPEAT
    CASE p.PlotIs OF
      LogX :
        Fx.SetValue(0,m.power(TEN, x));
        y := Fx.Execute();
        |
      LogY :
        Fx.SetValue(0,x);
        y := LogOf(Fx.Execute());
        |
      Log :
        Fx.SetValue(0,m.power(TEN, x));
        y := LogOf(Fx.Execute());
        |
      ELSE
        Fx.SetValue(0,x);
        y := Fx.Execute();
    END;
    IF y < p.Miny THEN p.Miny := y END;
    IF y > p.Maxy THEN p.Maxy := y END;
    x := x + int
  UNTIL x > p.Maxx;
  IF p.Miny = p.Maxy THEN
    p.Maxy := p.Maxy + 0.5; p.Miny := p.Miny - 0.5
  END
END NewYLimits;


PROCEDURE (p : Plot) Draw * (x,y,w,h : LONGINT);
(* Plot the current function *)
VAR
  lastx, lasty, int, xl, yl, dx, dy : LONGREAL;
  OldMinx, OldMaxx, OldMiny, OldMaxy : LONGREAL;
  i       : LONGINT;
  Border1 : LONGINT;
  Border2 : LONGINT;
  DumStr  : ARRAY 40 OF CHAR;
  draw    : D.DrawInfo;
BEGIN
  IF ~p.Intersect(x,y,w,h) THEN
    RETURN;
  END;

  (* parent draw routine *)
  p.Draw^(x, y,w,h);
  draw:=p.GetDrawInfo();          (* graphics attributes *)

  (* save the old plot window dimensions *)
  OldMinx := p.Minx;  OldMaxx := p.Maxx;
  OldMiny := p.Miny;  OldMaxy := p.Maxy;

  (* calculate the border dimensions *)
  IF RealToString(p.Maxy, DumStr, 2, p.Decy, " ") THEN
    Border1 := (str.Length(DumStr) + 3) * D.display.spaceWidth
  ELSE Border1:=0
  END;
  IF RealToString(p.Miny, DumStr, 2, p.Decy, " ") THEN
    Border2 := (str.Length(DumStr) + 3) * D.display.spaceWidth
  ELSE Border2:=0
  END;
  IF Border1 > Border2 THEN
    p.x := Border1;
  ELSE
    p.x := Border2;
  END;
  p.y := p.TopBorder + p.yoff;
  p.GMxx := p.width - p.x DIV 2 + p.xoff;
  p.GMxy := p.height - D.display.spaceHeight * 4 + p.yoff;
  INC(p.x, p.xoff);
  p.SetPlotOffset(0, 0);

  (* calculate scaled plot window dimensions *)
  dx := (p.Maxx - p.Minx) / p.xscale;
  dy := (p.Maxy - p.Miny) / p.yscale;
  p.Minx := p.Minx + dx * (p.xscale - 1.0) * 0.5;
  p.Maxx := p.Minx + dx;
  p.Miny := p.Miny + dy * (p.yscale - 1.0) * 0.5;
  p.Maxy := p.Miny + dy;

  (* draw the plot grid *)
  p.DrawGrid(draw);

  (* initialize the plot variables *)
  lastx := p.Minx;
  p.model.SetValue(0,p.Minx);
  lasty := p.model.Execute();
  xl := lastx;
  yl := lasty;
  IF p.PlotIs IN {Bar, Line} THEN
    int := (p.Maxx - p.Minx) / p.Divx;
  ELSE
    int := 5*(p.Maxx - p.Minx) / (p.GMxx - p.x);
  END;

  IF p.Points # NIL THEN  (* do a quick redraw *)
    FOR i:=1 TO LEN(p.Points^)-1 DO
      p.IntPlotLine(p.PlotColour, p.Points[i-1].x, p.Points[i-1].y,
                                   p.Points[i].x,   p.Points[i].y,draw)
    END
  ELSE
    NEW(p.Points, ENTIER((p.Maxx-p.Minx)/int)+2);
    IF p.ScatterPlot THEN
      (* g.SetDrMd(p.Drawing, g.jam1); *)
    END;

    (* go through the range of x values and plot y values *)
    i:=0;
    REPEAT
      IF p.PlotIs = Bar THEN
        p.PlotBar(p.PlotColour, int * 0.25, xl, y,draw);
      ELSE
        p.IntPlotLine(p.PlotColour, lastx, lasty, xl, yl,draw);
      END;
      lastx := xl;
      lasty := yl;
      p.Points[i].x:=xl; p.Points[i].y:=yl; INC(i);
      xl := xl + int;
      CASE p.PlotIs OF
        LogX :
          p.model.SetValue(0,m.power(TEN, xl));
          yl := p.model.Execute();
          |
        LogY :
          p.model.SetValue(0,xl);
          yl := LogOf(p.model.Execute());
          |
        Log :
          p.model.SetValue(0,m.power(TEN, xl));
          yl := LogOf(p.model.Execute());
          |
        ELSE
          p.model.SetValue(0,xl);
          yl := p.model.Execute();
      END;
    UNTIL xl > p.Maxx+int;
  END;
  p.PlotZero(draw);

  (* restore the old plot window dimensions *)
  p.Minx := OldMinx;  p.Maxx := OldMaxx;
  p.Miny := OldMiny;  p.Maxy := OldMaxy
END Draw;


PROCEDURE (p : Plot) SetPlotColour * (Colour : INTEGER);
(* Change the plot colour *)
BEGIN
  p.PlotColour := Colour
END SetPlotColour;


PROCEDURE (p : Plot) SetTextColour * (Colour : INTEGER);
(* Change the plot colour *)
BEGIN
  p.TextColour := Colour
END SetTextColour;


PROCEDURE (p : Plot) SetGridColour * (Minor, Major : INTEGER);
(* Change the plot colour *)
BEGIN
  p.GridColour := Major;
  p.MinorColour := Minor
END SetGridColour;


PROCEDURE (p : Plot) SetZeroLine * (On : BOOLEAN);
(* Enable/disable zero line *)
BEGIN
  p.ZeroLineOn := On
END SetZeroLine;


PROCEDURE (p : Plot) SetLabelRoutine * (LabelRoutine : LabelProc);
(* Overrides the numerical labels with user-defined
   labels for each grid position along the x-axis *)
BEGIN
  p.GetLabel := LabelRoutine;
END SetLabelRoutine;


PROCEDURE (p : Plot) CenterLabelX * (Label : ARRAY OF CHAR;
                                     y     : LONGINT);
(* Center the text label horizontally *)
VAR
  x : LONGINT;
  draw : D.DrawInfo;
BEGIN
  draw:=p.GetDrawInfo();

  x := (p.GMxx - p.x) DIV 2 + p.x;   (* center position *)
  DEC(x, str.Length(Label) * D.display.spaceWidth DIV 2); (* offset *)
  p.LabelX(Label, x, y,draw);
END CenterLabelX;


PROCEDURE (p : Plot) CenterLabelY * (Label : ARRAY OF CHAR;
                                     x     : LONGINT);
(* Center the text label vertically *)
VAR
  y : LONGINT;
  draw : D.DrawInfo;
BEGIN
  draw:=p.GetDrawInfo();
  y := (p.GMxy - p.y) DIV 2 + p.y;   (* center position *)
  DEC(y, str.Length(Label) * D.display.spaceHeight DIV 2);
  p.LabelY(Label, x, y,draw);
END CenterLabelY;


PROCEDURE (p : Plot) LabelMinMax * (Fx : FM.FunctionLRealModel);
(* Label local minima and maxima by tracking whether the
   first derivative of Fx changes sign *)
CONST
  Positive = 0;
  Negative = 1;
TYPE
  SignType = SHORTINT;
VAR
  sign, signp : SignType;
  x, xlog, xplot, y, yp, yplot, delta : LONGREAL;
  Gx, Gy : LONGINT;
  s : ARRAY 40 OF CHAR;
  draw : D.DrawInfo;
BEGIN
  draw:=p.GetDrawInfo();

  x := p.Minx;
  signp := Positive;
  IF p.PlotIs IN {Bar, Line} THEN
    delta := (p.Maxx - p.Minx) / p.Divx;
  ELSE
    delta := (p.Maxx - p.Minx) / (p.GMxx - p.x);
  END;
  CASE p.PlotIs OF
    LogX :
      Fx.SetValue(0,m.power(TEN, x-delta));
      yp := Fx.Execute();
      |
    LogY :
      Fx.SetValue(0,x-delta);
      yp := LogOf(Fx.Execute());
      |
    Log :
      Fx.SetValue(0,x-delta);
      yp := LogOf(m.power(TEN, Fx.Execute()));
      |
    ELSE
      Fx.SetValue(0,x-delta);
      yp := Fx.Execute();
  END;
  REPEAT
    IF p.PlotIs IN XLog THEN
      xlog := m.power(TEN, x);
    ELSE
      xlog := x;
    END;
    IF p.PlotIs IN YLog THEN
      Fx.SetValue(0,xlog);
      y := LogOf(Fx.Execute());
    ELSE
      Fx.SetValue(0,xlog);
      y := Fx.Execute();
    END;
    IF y - yp >= 0.0 THEN
      sign := Positive;
    ELSE
      sign := Negative;
    END;
    IF (sign # signp) OR
       ((p.PlotIs = Bar) & (yp # 0.0)) THEN
      (* found a local minima/maxima *)
      IF p.PlotIs IN {Bar, Line} THEN
        xplot := x - delta;
        yplot := yp;
      ELSE
        xplot := x;
        yplot := y;
      END;
      p.xyToCoords(xplot, yplot, Gx, Gy);
      IF yplot <= 0.0 THEN
        INC(Gy, D.display.spaceHeight);  (* value below curve *)
      ELSE
        DEC(Gy, D.display.spaceHeight DIV 3);  (* above curve *)
      END;
      IF RealToString(yplot, s, 2, p.Decy+2, " ") THEN
        DEC(Gx, str.Length(s) * D.display.spaceWidth DIV 2);
        p.LabelX(s, Gx, Gy,draw);
      END;
      signp := sign;
    END;
    x := x + delta;
    yp := y;
  UNTIL x > p.Maxx;
END LabelMinMax;


PROCEDURE (p : Plot) Hide *;
BEGIN
  IF p.visible THEN
    p.DrawHide; p.Hide^
  END
END Hide;


PROCEDURE (p : Plot) CalcSize*;
BEGIN
  IF D.display.spaceWidth>D.display.spaceHeight THEN
    p.width:=40*D.display.spaceWidth;
    p.height:=40*D.display.spaceWidth;
  ELSE
    p.width:=40*D.display.spaceHeight;
    p.height:=40*D.display.spaceHeight;
  END;

  p.minWidth:=p.width;
  p.minHeight:=p.height;

  p.CalcSize^;
END CalcSize;

PROCEDURE (p : Plot) Resync*(model : O.Model; msg : O.ResyncMsg);

BEGIN
  p.ClearPlotHistory;
  IF p.visible THEN
    p.Redraw;
  END;
END Resync;

PROCEDURE (p : Plot) InformationBox * (Position      : PositionType;
                                       Lines         : ARRAY OF LineType;
                                       FillColour    : INTEGER;
                                       OutlineColour : INTEGER);
(* Place an information box in the plot area *)
VAR
  Gx, Gy    : LONGINT;
  Gxs, Gys  : LONGINT;
  Gw, Gh    : LONGINT;
  ChCnt     : LONGINT;
  LineCnt   : LONGINT;
  draw      : D.DrawInfo;
BEGIN
  draw:=p.GetDrawInfo();


  Gxs := 2 * D.display.spaceWidth;       (* side border width  *)
  Gys := 2 * D.display.spaceHeight;      (* upper/lower border *)

  (* Determine the text box width and height *)
  Gh := 2 * Gys + LEN(Lines) * D.display.spaceHeight;
  Gw := 2 * Gxs;
  ChCnt := 0;
  FOR LineCnt := 0 TO LEN(Lines)-1 DO
    IF str.Length(Lines[LineCnt]) > ChCnt THEN
      ChCnt := str.Length(Lines[LineCnt])
    END;
  END;
  INC(Gw, ChCnt * D.display.spaceWidth);

  (* Determine the text box position *)
  CASE Position OF
    UpperLeft :
      Gx := p.x;
      Gy := p.y;
      |
    UpperMiddle :
      Gx := (p.GMxx - p.x - Gw) DIV 2 + p.x;
      Gy := p.y;
      |
    UpperRight :
      Gx := p.GMxx - Gw;
      Gy := p.y;
      |
    LowerLeft :
      Gx := p.x;
      Gy := p.GMxy - Gh;
      |
    LowerMiddle :
      Gx := (p.GMxx - p.x - Gw) DIV 2 + p.x;
      Gy := p.GMxy - Gh;
      |
    LowerRight :
      Gx := p.GMxx - Gw;
      Gy := p.GMxy - Gh;
      |
  END;

  (* Draw the box *)
  draw.PushForeground(OutlineColour);
  draw.FillRectangle(Gx, Gy, Gw, Gh);
  draw.PopForeground;
  draw.PushForeground(OutlineColour);
  draw.FillRectangle(Gx+2, Gy+2, Gw-2, Gh-2);
  draw.PopForeground;

  (* Output the text strings *)
  INC(Gx, Gxs);
  INC(Gy, Gys);
  draw.PushBackground(FillColour);  (* set text background *)
  FOR LineCnt := 0 TO LEN(Lines)-1 DO
    INC(Gy, D.display.spaceHeight);
    p.LabelX(Lines[LineCnt], Gx, Gy,draw);
  END;
  draw.PopBackground;               (* normal background   *)
END InformationBox;

END VO:Plot.