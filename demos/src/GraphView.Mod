MODULE GraphView;

IMPORT 
  Strings,
  IntStr,
  Geometry, 
  RealMath,
  E := VO:Base:Event,
  D := VO:Base:Display,
  O := VO:Base:Object,
  G := VO:Object,
  GraphModel;

CONST
  UseBitmap = TRUE;

  NodeSize = 3; (* FIXME *)


  dragNode = 1;
  dragNone = 0;
  dragRotate = 2;
  dragAddEdge = 3;

  head = 0;
  fillHead = 1;
  tail  = 2;
  fillTail = 3;
  
  optShowLabels = 0;
  optShowNodes = 1;
  optShowDirection = 2;
  optShowGrid = 3;
  optShowAxes = 4;
  optShowEdges = 5;
  optFancyLabel = 6;

  propModel = 0;
  propAngle = 1;
  propOptions = 2;
  propColour = 3;

TYPE
  Prefs* = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
    threeD* : BOOLEAN;
    gridCell* : BOOLEAN;
    options* : SET;
    freeNodeColour* : D.Color;
    lockedNodeColour* : D.Color;
    edgeColour* : D.Color;
    labelColour* : D.Color;
    axesColour* : D.Color;
    xAngle*, yAngle* : REAL;
    separation* : REAL;
  END;

  DisplayPoint = RECORD
    x, y : LONGINT;
    z : REAL;
    dx, dy : REAL;
  END;

  Graph * = POINTER TO GraphDesc;
  GraphDesc * = RECORD (G.GadgetDesc)
    transformValid : BOOLEAN;
    t, t0 : Geometry.Transform;
    t2 : Geometry.Transform;
    model: GraphModel.Model;
    xAngle, yAngle : REAL;
    options : SET;
    freeNodeColour : D.Color;
    lockedNodeColour : D.Color;
    edgeColour : D.Color;
    labelColour : D.Color;
    axesColour : D.Color;
    points : POINTER TO ARRAY OF DisplayPoint;
    drag : RECORD
      moved, wasFixed : BOOLEAN;
      target : LONGINT;
      type : INTEGER;
      xPos, yPos : LONGINT;
      xStart, yStart : LONGINT; zStart : REAL;
      xAngle, yAngle : REAL;
    END;
    wOld, hOld : LONGINT;
    font : D.Font;
    bitmap : D.Bitmap;
  END;

VAR
  prefs* : Prefs;

(* View *)

PROCEDURE Init* (g : Graph; d : D.Display);
BEGIN
  g.points := NIL;
  g.xAngle := 0;
  g.yAngle := 0;
  g.options := {optShowNodes, optShowLabels, optShowGrid, optShowAxes, optShowEdges};
  g.freeNodeColour := D.blackColor;
  g.lockedNodeColour := D.warnColor;
  g.edgeColour := D.blackColor;
  g.labelColour := D.blackColor;
  g.axesColour := D.blackColor;
  g.transformValid := FALSE;
  g.font := D.normalFont;
  (* g.SetBackground(D.whiteColor); *)
  g.bitmap := NIL;
END Init;

(* 

PROCEDURE (v: View) Internalize- (VAR rd: Stores.Reader);
  VAR version: INTEGER; st: Stores.Store;
BEGIN
  v.Init;
  IF ~rd.cancelled THEN
    rd.ReadVersion(minVersion, maxVersion, version);
    IF ~rd.cancelled THEN
      rd.ReadStore(st);
      IF (st # NIL) & (st IS Model) THEN
        IF debug THEN Out.String("Internalised graph"); Out.Ln; END;
        v.InitModel(st(Model));
        rd.ReadReal(v.xAngle);
        rd.ReadReal(v.yAngle);
        rd.ReadSet(v.options);
        rd.ReadInt(v.freeNodeColour);
        rd.ReadInt(v.lockedNodeColour);
        rd.ReadInt(v.edgeColour);
        rd.ReadInt(v.labelColour);
        rd.ReadInt(v.axesColour);
      ELSE
        IF debug THEN Out.String("Couldn't internalise graph"); Out.Ln; END;
        rd.TurnIntoAlien(Stores.alienComponent) (* cancel internalization of v *)
      END
    END
  END;
END Internalize;

PROCEDURE (v: View) Externalize- (VAR wr: Stores.Writer);
BEGIN
  ASSERT(v.model # NIL, 20);
  wr.WriteVersion(maxVersion);
  wr.WriteStore(v.model);
  wr.WriteReal(v.xAngle);
  wr.WriteReal(v.yAngle);
  wr.WriteSet(v.options);
  wr.WriteInt(v.freeNodeColour);
  wr.WriteInt(v.lockedNodeColour);
  wr.WriteInt(v.edgeColour);
  wr.WriteInt(v.labelColour);
  wr.WriteInt(v.axesColour);
END Externalize;

PROCEDURE (v: View) InitFrom- (source: Views.View; model : Models.Model);
BEGIN
  v.Init;
  WITH source: View DO
    v.xAngle := source.xAngle;
    v.yAngle := source.yAngle;
    v.options := source.options;
    v.freeNodeColour := source.freeNodeColour;
    v.lockedNodeColour := source.lockedNodeColour;
    v.edgeColour := source.edgeColour;
    v.labelColour := source.labelColour;
    v.axesColour := source.axesColour;
    v.font := source.font;
    v.model := model(Model);
  END
END InitFrom;

PROCEDURE (v: View) InitModel* (m: Models.Model);
BEGIN
  ASSERT(m # NIL, 20);
  ASSERT(m IS Model, 23);
  v.model := m(Model)
END InitModel;

PROCEDURE (v: View) ThisModel* (): Models.Model;
BEGIN
  ASSERT(v.model # NIL, 100);
  RETURN v.model
END ThisModel;
*)

PROCEDURE (v : Graph) CalcSize*;
BEGIN
  v.width := 200;
  v.height := 200;
  v.minWidth := v.width;
  v.minHeight := v.height;
  v.CalcSize^;
END CalcSize;

PROCEDURE (v : Graph) TransformPoints();
VAR
  tr, tx, ty, tr0, tx0, ty0, t1, t2 : Geometry.Transform;
  pIn, pOut : Geometry.Point;
  node : GraphModel.Node; count, pos : LONGINT;
  scaleX, scaleY : REAL;
  xRot, yRot : REAL;
  g : GraphModel.Model;
BEGIN
  (* If we already have a valid transform, there's no need to do it again *)

  IF v.transformValid & (v.width = v.wOld) & (v.height = v.hOld) THEN RETURN END;
  g := v.model;
  scaleX := v.width / g.width; scaleY := v.height / g.height;
  
  (* compute individual transforms *)
  xRot := v.xAngle * RealMath.pi / 180;
  yRot := -v.yAngle * RealMath.pi / 180;
  tr.Translate(-g.width/2, -g.height/2, -g.depth/2);
  tr0.Translate(g.width / 2, g.height / 2, g.depth / 2);
  tx.Rotate(Geometry.zAxis, xRot);
  tx0.Rotate(Geometry.zAxis, -xRot);
  ty.Rotate(Geometry.xAxis, yRot);
  ty.matrix[Geometry.sAxis,Geometry.sAxis] := 1.4;
  ty0.Rotate(Geometry.xAxis, -yRot);
  ty0.matrix[Geometry.sAxis,Geometry.sAxis] := 1/1.4;
  
  (* now combine to give overall transform *)
  tr.PostMultiply(tx, t1);
  t1.PostMultiply(ty, t2);
  t2.PostMultiply(tr0, v.t);
  
  tx.PostMultiply(ty, v.t2);
  
  (* now calculate overall inverse transform (could use matrix inverse ?) *)
  tr.PostMultiply(ty0, t1);
  t1.PostMultiply(tx0, t2);
  t2.PostMultiply(tr0, v.t0);
  
  (* now allocate an array sufficient to hold transformed points *)
  IF (v.points = NIL) OR (g.nNodes >  LEN(v.points^)) THEN
    count := g.nNodes; IF count < 10 THEN count := 10; END;
    NEW(v.points, count);
  END;

  (* transform node coordinates to points array, setting node position as we go *)
  node := g.nodes; pos := 0;  
  WHILE node # NIL DO
    node.pos := pos;
    pIn.Set(node.x, node.y, node.z, 1);
    v.t.Multiply(pIn, pOut, TRUE);
    v.points[pos].x := ENTIER(pOut.p[Geometry.xAxis] * scaleX);
    v.points[pos].y := ENTIER(pOut.p[Geometry.yAxis] * scaleY);
    v.points[pos].z := pOut.p[Geometry.zAxis];
    IF optFancyLabel IN v.options THEN
      pIn.Set(node.drx, node.dry, node.drz, 1);
      v.t2.Multiply(pIn, pOut, TRUE);
      v.points[pos].dx := pOut.p[Geometry.xAxis];
      v.points[pos].dy := pOut.p[Geometry.yAxis];
    END;
    node := node.next; INC(pos);
  END;
  v.hOld := v.height;
  v.wOld := v.width;
  v.transformValid := TRUE;
END TransformPoints;

PROCEDURE (v : Graph) PutGridLine(d : D.DrawInfo; ox, oy : LONGINT; x1, y1, z1, x2, y2, z2 : REAL);
VAR 
  scaleX, scaleY : REAL;
  p1, p2, p3, p4 : Geometry.Point;
BEGIN
  scaleX := v.width  / v.model.width;
  scaleY := v.height / v.model.height;
  p1.p[0] := x1; p1.p[1] := y1; p1.p[2] := z1; p1.p[3] := 1;
  p2.p[0] := x2; p2.p[1] := y2; p2.p[2] := z2; p2.p[3] := 1;
  v.t.Multiply(p1, p3, TRUE);
  v.t.Multiply(p2, p4, TRUE);
  d.DrawLine(ox+ENTIER(p3.p[0]*scaleX), oy+ENTIER(p3.p[1]*scaleY), 
    ox+ENTIER(p4.p[0]*scaleX), oy+ENTIER(p4.p[1]*scaleY));
END PutGridLine;

PROCEDURE Wedge (d : D.DrawInfo; x1, y1, dlx, dly, dhx, dhy : LONGINT; fill : BOOLEAN);
VAR
  p : ARRAY 3 OF D.PointDesc;
BEGIN
  p[0].x := x1 + dlx; p[0].y := y1 + dly;
  p[1].x := x1; p[1].y := y1;
  p[2].x := x1 + dhx; p[2].y := y1 + dhy;
  IF fill THEN
    d.FillPolygon(p, 3);
  ELSE
    d.DrawLine(p[0].x, p[0].y, p[1].x, p[1].y);
    d.DrawLine(p[1].x, p[1].y, p[2].x, p[2].y);
  END
END Wedge;

PROCEDURE ArrowHead(d : D.DrawInfo; x1, y1, x2, y2, length : LONGINT; dang : REAL; type : SET);
VAR
  dlx, dly, dhx, dhy : LONGINT;
  pi, angle, hiang, loang : REAL;
BEGIN
  pi := RealMath.pi;
  angle := RealMath.arctan2(x1-x2, y1-y2);
  hiang := angle+dang;  
  loang := angle-dang;
  IF hiang > pi THEN hiang := hiang - 2 * pi END;
  IF loang < -pi THEN loang := loang + 2 * pi END;

  d.DrawLine(x1, y1, x2, y2);
  dhx := ENTIER(RealMath.sin(hiang)*length);
  dhy := ENTIER(RealMath.cos(hiang)*length);
  dlx:= ENTIER(RealMath.sin(loang)*length);
  dly:= ENTIER(RealMath.cos(loang)*length);
  IF head IN type THEN Wedge(d, x2,y2,dlx,dly,dhx,dhy, fillHead IN type) END;
  IF tail IN type THEN Wedge(d, x1,y1,dlx,dly,dhx,dhy, fillTail IN type) END
END ArrowHead;

PROCEDURE (v: Graph) DrawFrame*;
VAR
  xOff, yOff : LONGINT;
  px, py, x, y, size : LONGINT;
  g : GraphModel.Model; 
  e : GraphModel.Edge; 
  n : GraphModel.Node;
  from, to : LONGINT;
  wd, d : D.DrawInfo;
  angle, ww, hh, dd, p : REAL;
  dx, dy : REAL;
  len, i : LONGINT;
  fe : D.FontExtentDesc;
BEGIN
  IF UseBitmap THEN
    IF (v.bitmap=NIL) OR (v.bitmap.width#v.width) OR (v.bitmap.height#v.height) THEN
      IF v.bitmap#NIL THEN
        D.display.FreeBitmap(v.bitmap);
      END;
      v.bitmap:=D.display.CreateBitmap(v.width,v.height);
    END;
  END;

  wd := v.GetDrawInfo();
  IF v.bitmap = NIL THEN
    d := wd;
    xOff := v.x; yOff := v.y;
    d.InstallClip(xOff, yOff, v.width, v.height);
  ELSE
    d := v.bitmap.draw;
    xOff := 0; yOff := 0;
  END;
  d.PushForeground(D.backgroundColor);
  d.FillRectangle(xOff,yOff,v.width,v.height);
  d.PopForeground;

  size := NodeSize;

  g := v.model;
  v.TransformPoints();
  ww := g.width; hh := g.height; dd := g.depth; 
  d.PushForeground(v.axesColour);
  IF g.gridCell & (optShowGrid IN v.options) THEN
    FOR i := 0 TO g.gridX-1 DO
      p := i * 2 * g.k; v.PutGridLine(d, xOff, yOff, p, 0, 0, p, hh, 0);
    END;
    FOR i := 0 TO g.gridY-1 DO
      p := i * 2 * g.k; v.PutGridLine(d, xOff, yOff, 0, p, 0, ww, p, 0);
    END;
  END;
  IF optShowAxes IN v.options THEN
    v.PutGridLine(d, xOff, yOff, 0, 0, 0, 0, hh, 0);  
    v.PutGridLine(d, xOff, yOff, 0, hh, 0, ww, hh, 0);  
    v.PutGridLine(d, xOff, yOff, ww, hh, 0, ww, 0,  0);
    v.PutGridLine(d, xOff, yOff, ww, 0, 0, 0, 0, 0);
    v.PutGridLine(d, xOff, yOff, 0, 0, dd, 0, hh, dd);
    v.PutGridLine(d, xOff, yOff, 0, hh, dd, ww, hh, dd);  
    v.PutGridLine(d, xOff, yOff, ww, hh, dd, ww, 0,  dd);
    v.PutGridLine(d, xOff, yOff, ww, 0, dd, 0, 0, dd);
    v.PutGridLine(d, xOff, yOff, 0, 0, 0, 0, 0, dd);
    v.PutGridLine(d, xOff, yOff, ww, 0, 0, ww, 0, dd);
    v.PutGridLine(d, xOff, yOff, ww, hh, 0, ww, hh, dd);
    v.PutGridLine(d, xOff, yOff, 0, hh, 0, 0, hh, dd);
    v.PutGridLine(d, xOff, yOff, ww / 2, hh / 2, 0, ww / 2, hh / 2, dd);
  END;
  d.PopForeground();

  n := g.nodes;
  d.PushFont(D.smallFont, {}); 
  WHILE n # NIL DO
    x := v.points[n.pos].x + xOff; y := v.points[n.pos].y + yOff;
    IF n.fixed THEN
      d.PushForeground(v.lockedNodeColour);
    ELSE
      d.PushForeground(v.freeNodeColour);
    END;
    IF optShowNodes IN v.options THEN 
      d.FillArc(x-size, y-size, size*2, size*2, 0, 360*64);
    END;
    d.PopForeground();
    IF (n.strKey # NIL) & (optShowLabels IN v.options) THEN
      d.PushForeground(v.labelColour);
      len := Strings.Length(n.strKey^);
      IF (optFancyLabel IN v.options) THEN
        dy := v.points[n.pos].dy;
        dx := v.points[n.pos].dx;
        angle := RealMath.arctan2(dy, dx);
        px := ENTIER(x+size*RealMath.cos(angle));
        py := ENTIER(y+size*RealMath.sin(angle));
        v.font.TextExtent(n.strKey^, len, {}, fe);
        IF dx < 0 THEN DEC(px, fe.width) END;
        IF dy < 0 THEN DEC(py, fe.descent) ELSE INC(py, fe.ascent) END;
        d.DrawString(px, py, n.strKey^, len);
      ELSE
        d.DrawString(x+size, y, n.strKey^, len);
      END;
      d.PopForeground()
    END; 
    n := n.next;
  END;
  d.PopFont();

  angle := RealMath.pi / 6;
  IF optShowEdges IN v.options THEN 
    d.PushForeground(v.edgeColour);
    e := g.edges;
    WHILE e # NIL DO
      from := e.from.pos; to := e.to.pos;
      IF optShowDirection IN v.options THEN
        ArrowHead(d, xOff+v.points[from].x, yOff+v.points[from].y, xOff+v.points[to].x, yOff+v.points[to].y, size * 2, angle, {fillHead, head});
      ELSE
        d.DrawLine(xOff+v.points[from].x, yOff+v.points[from].y, xOff+v.points[to].x, yOff+v.points[to].y);
      END;
      e := e.next;
    END;
    d.PopForeground();
  END;
  IF v.bitmap#NIL THEN
    wd.CopyFromBitmap(v.bitmap,0,0,v.width,v.height,v.x,v.y);
  ELSE
    d.FreeLastClip();
  END;
END DrawFrame;

PROCEDURE (v: Graph) Draw* (drawx, drawy, draww, drawh : LONGINT);
BEGIN
  v.Draw^(drawx, drawy, draww, drawh);

  IF ~v.Intersect(drawx, drawy, draww, drawh) THEN RETURN END;

  v.DrawFrame();
END Draw;
 
(*
PROCEDURE (v : View) Refresh(f : Views.Frame);
VAR
  w, h : LONGINT;
  pt : Ports.Port;
  rd : Ports.Rider;
  l,t,r,b : LONGINT;
BEGIN
  v.context.GetSize(w,h);
  rd := f.rider;
  rd.GetRect(l,t,r,b);
  pt := rd.Base();
  pt.OpenBuffer(l, t, r, b);
  f.DrawRect(0,0,w, h,-1, Ports.background);
  v.Restore(f, 0, 0, w, h);
  pt.CloseBuffer();
END Refresh;
*)

PROCEDURE (v : Graph) Refresh;
BEGIN
  IF ~v.visible OR v.disabled THEN RETURN END;
  v.Draw(v.x, v.y, v.width, v.height);
END Refresh;

PROCEDURE (v : Graph) Resync* (model : O.Model; msg : O.ResyncMsg);
BEGIN
  v.transformValid := FALSE;
  v.Refresh();
END Resync;

PROCEDURE (v : Graph) ModelAccepted* (m : O.Model) : BOOLEAN;
BEGIN
  RETURN m = v.model;
END ModelAccepted;

PROCEDURE (v : Graph) SetModel* (m : O.Model);
BEGIN
  IF v.model # NIL THEN
    v.UnattachModel(v.model);
  END;
  IF (m # NIL) & (m IS GraphModel.Model) THEN
    v.model := m(GraphModel.Model);
    v.AttachModel(m);
    m.On;
  ELSE
    v.model := NIL;
  END;
END SetModel;

(*
PROCEDURE (v: View) HandleModelMsg- (VAR msg: Models.Message);
BEGIN
  WITH msg: Models.UpdateMsg DO
    WITH msg: UpdateMsg DO
      v.transformValid := FALSE;
      Views.Update(v,Views.keepFrames);
    ELSE
      Views.Update(v, Views.keepFrames) (* restore v in any frame that displays it *)
    END
  ELSE  (* ignore other messages. eg Omnicasts *)
  END
END HandleModelMsg;
*)

PROCEDURE (v : Graph) CalcTransformedLocation(x, y : LONGINT; VAR pOut : Geometry.Point);
VAR pIn : Geometry.Point;
BEGIN
  pIn.p[Geometry.xAxis] := x * v.model.width / v.width;
  pIn.p[Geometry.yAxis] := y * v.model.height / v.height;
  pIn.p[Geometry.zAxis] := v.drag.zStart;
  pIn.p[Geometry.sAxis] := 1;
  v.t0.Multiply(pIn, pOut, TRUE);
END CalcTransformedLocation;

PROCEDURE (v : Graph) CalcRotPos(x, y : LONGINT; VAR a, b : REAL);
BEGIN
  a := v.drag.xAngle + (x-v.drag.xStart) * 180 / v.width;
  b := v.drag.yAngle + (y-v.drag.yStart) * 180 / v.height;
END CalcRotPos;

PROCEDURE (v : Graph) SetRotPos(x,  y : REAL);
BEGIN
  IF x<0 THEN x := x + 360
  ELSIF x>360THEN x := x - 360
  END;
  IF y<0 THEN y := y + 360
  ELSIF y>360 THEN  y := y - 360
  END;
  v.xAngle := x;
  v.yAngle := y;
  v.transformValid := FALSE;
  (* IncEra; *)
END SetRotPos;

PROCEDURE (v : Graph) HitNode(x, y, size : LONGINT) : GraphModel.Node;
VAR
  nx, ny : LONGINT;
  node : GraphModel.Node;
BEGIN
  node := v.model.nodes;
  WHILE node # NIL DO
    nx := v.points[node.pos].x; ny := v.points[node.pos].y;
    IF (ABS(nx-x)<=size) & (ABS(ny-y)<=size) THEN
      RETURN node;
    END;
    node := node.next;
  END;
  RETURN NIL;
END HitNode;

PROCEDURE (v : Graph) NewNode (x, y : LONGINT; VAR n : GraphModel.Node);
VAR
  name : ARRAY 20 OF CHAR;
  pOut : Geometry.Point;
BEGIN
    v.CalcTransformedLocation(x, y, pOut);
    IntStr.IntToStr(v.model.nNodes, name);
    ASSERT(v.model.AddNode(v.model.nNodes, name, pOut.p[0], pOut.p[1], pOut.p[2], FALSE, n));
END NewNode;

PROCEDURE (v : Graph) HandleMouseEvent* (event : E.MouseEvent; VAR graph : G.Object) : BOOLEAN;
VAR
  x,  y : LONGINT;
  size : LONGINT;
  m : SET;
  isDown : BOOLEAN;
  a, b : REAL;
  pOut : Geometry.Point;
  n : GraphModel.Node; e : GraphModel.Edge;
  update : BOOLEAN;
  saved : LONGINT;
  d : D.DrawInfo;
BEGIN
  IF ~v.visible OR v.disabled THEN RETURN FALSE END;

  update := FALSE;
  size := NodeSize;

  x := event.x; y := event.y; 
  WITH event : E.ButtonEvent DO
    IF (event.type=E.mouseDown) & v.PointIsIn(event.x, event.y) THEN
      IF (event.button=E.button1) THEN
        v.drag.xStart := x; v.drag.yStart := y; 
        v.drag.xPos := x; v.drag.yPos := y;
        v.drag.xAngle := v.xAngle; v.drag.yAngle := v.yAngle;
        n := v.HitNode(x-v.x, y-v.y, size);
        IF event.qualifier * {E.qShiftLeft, E.qShiftRight} # {} THEN
          IF n = NIL THEN
            v.NewNode(x-v.x, y-v.y, n);
            v.model.UpdateModel(); v.Refresh();
          END;
          v.drag.type := dragAddEdge;
          v.drag.target := n.intKey;
        ELSE
          IF n = NIL THEN
            v.drag.type := dragRotate;
          ELSE
            v.drag.type := dragNode;
            v.drag.zStart := v.points[n.pos].z;
            v.drag.target := n.intKey;
            v.drag.moved := FALSE;
            v.drag.wasFixed := n.fixed;
            n.fixed := TRUE;
            v.Refresh();
          END;
        END;
      END
    ELSIF (event.type = E.mouseUp) THEN
      CASE v.drag.type OF
      dragNode:
        IF ~v.drag.moved & v.model.FindNodeByKey(v.drag.target, n) THEN
          n.fixed := ~v.drag.wasFixed;
          v.model.Layout;
          update := TRUE;
        END;
      | dragAddEdge:
        n := v.HitNode(x-v.x, y-v.y, size);
        IF n = NIL THEN
          v.NewNode(x-v.x, y-v.y, n);
        END;
        IF v.drag.target # n.intKey THEN
          ASSERT(v.model.AddEdge (v.model.nEdges, v.drag.target, n.intKey, e));
        END;
        update := TRUE;
      ELSE
      END;
      v.drag.type := dragNone;
   END;
  | event : E.MotionEvent DO
    IF (x # v.drag.xPos) OR (y # v.drag.yPos) THEN
      CASE v.drag.type OF
      | dragNode:
        v.CalcTransformedLocation(x-v.x, y-v.y, pOut);
        v.model.MoveNodeByKey(v.drag.target,
          pOut.p[Geometry.xAxis], pOut.p[Geometry.yAxis], pOut.p[Geometry.zAxis]);
        v.drag.moved := TRUE;
        v.model.Layout;
        update := TRUE;
        v.transformValid := FALSE;
        v.Refresh()
      | dragRotate:
        v.CalcRotPos(x, y, a, b);
        v.SetRotPos(a, b);
        v.Refresh()
      | dragAddEdge:
        d := v.GetDrawInfo();
        d.PushDrawMode(D.invert);
        d.PushForeground(D.whiteColor);
        (* Erase old line *)
        d.DrawLine(v.drag.xStart, v.drag.yStart, v.drag.xPos, v.drag.yPos);
        (* Draw new line *)
        d.DrawLine(v.drag.xStart, v.drag.yStart, x, y);
        d.PopForeground();
        d.PopDrawMode();
      | dragNone:
      END;
      v.drag.xPos := x; v.drag.yPos := y;
    END
  END;
  IF update THEN
    v.model.UpdateModel();
  END;
  RETURN TRUE
END HandleMouseEvent;

(*
PROCEDURE (v: View) HandleCtrlMsg* (f: Views.Frame; VAR msg: Controllers.Message; VAR focus : Views.View);
VAR 
  c: Containers.Controller;
  p : Prop; n : Node;
BEGIN
  ASSERT(focus = NIL, 23);
  WITH msg: Controllers.PollOpsMsg DO
    (* specify which editing operations are supported *)
  | msg: Controllers.TrackMsg DO
    v.HandleTrackMessage(f, msg);
  | msg : Controllers.PollCursorMsg DO
    n := v.HitNode(msg.x, msg.y, Ports.mm);
    IF n # NIL THEN
      msg.cursor := Ports.bitmapCursor
    ELSE
      msg.cursor := Ports.arrowCursor
    END;
  | msg: Properties.EmitMsg DO Views.HandlePropMsg(v, msg.set)
  | msg: Properties.CollectMsg DO Views.HandlePropMsg(v, msg.poll)
  | msg : Controllers.MarkMsg DO
  | msg: Controllers.EditMsg DO
    (* implement editing operations *)
  ELSE  (* ignore other messages *)
  END
END HandleCtrlMsg;
*)

BEGIN
  NEW(prefs);
END GraphView.

