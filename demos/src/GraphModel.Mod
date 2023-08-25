MODULE GraphModel;

IMPORT 
  RandomNumbers,
  RealMath,
  IntStr,
  O := VO:Base:Object,
  Err,
  SYSTEM (* for bit-wise XOR *);

CONST
  tiny = 0.01;

TYPE
  StringKey = POINTER TO ARRAY OF CHAR;

  Node* = POINTER TO NodeDesc;
  NodeDesc* = RECORD 
    next- : Node;
    intKey- : LONGINT;
    strKey- : StringKey;
    x-, y-, z- : REAL;
    dx-, dy-, dz- : REAL;
    drx-, dry-, drz- : REAL;
    fixed* : BOOLEAN;
    xCell, yCell, zCell : LONGINT;
    pos* : LONGINT;
  END;

  Edge* = POINTER TO EdgeDesc;
  EdgeDesc* = RECORD 
    next- : Edge;
    intKey- : LONGINT;
    from-, to- : Node;
  END;

  Model* = POINTER TO ModelDesc;
  ModelDesc* = RECORD (O.ModelDesc)
    nodes- : Node;
    edges- : Edge;
    nNodes-, nEdges- : LONGINT;
    width-,  height-, depth- : REAL;
    threeD*, gridCell* : BOOLEAN;
    separation : REAL;
    k-, area : REAL;
    gridX-, gridY-, gridZ- : LONGINT;
    nIterations : LONGINT;
  END;

PROCEDURE CopyString (str : ARRAY OF CHAR; VAR p : StringKey);
VAR
  len : LONGINT;
BEGIN
  len := 0;
  WHILE str[len] # 0X DO INC(len) END;
  IF len = 0 THEN
    p:=NIL
  ELSE
    NEW(p,len+1);
    IF p=NIL THEN RETURN END;
    COPY(str, p^);
  END;
END CopyString;

PROCEDURE Init* (m : Model; width, height, depth : REAL);
BEGIN
  m.width := width; m.height := height; m.depth := depth;
  m.separation := 1.0;
  m.threeD := TRUE;
  m.gridCell := FALSE;
  m.nIterations := 30;
  m.nEdges := 0;
  m.nNodes := 0;
  m.nodes := NIL;
  m.edges := NIL;
END Init;

PROCEDURE ceiling* (r : REAL) : LONGINT;
VAR i : LONGINT;
BEGIN
  i := ENTIER(r);
  IF i < r THEN RETURN i+1 ELSE RETURN i END;
  RETURN i;
END ceiling;

PROCEDURE min* (a, b : REAL) : REAL;
BEGIN
  IF a < b THEN RETURN a ELSE RETURN b END
END min;

PROCEDURE max* (a, b : REAL) : REAL;
BEGIN
  IF a > b THEN RETURN a ELSE RETURN b END
END max;

PROCEDURE (m : Model) Layout*;
VAR
  u, v : Node;
  e : Edge;
  i : LONGINT;
  loXCell, hiXCell, loYCell, hiYCell, loZCell, hiZCell : LONGINT;
  k2, kk, k2k2, t : REAL;
  dx, dy, dz, d2, d  : REAL;
  fr, fa : REAL;
  len, scale : REAL;
BEGIN
  m.area := m.width * m.depth;
  IF (m.nNodes=0) OR (m.nEdges=0) THEN
    (* If there are no edges, set parameters so an empty display looks right *)
    m.k := m.area / 2; m.gridX := 1; m.gridY := 1; m.gridZ := 1;
    RETURN;
  END;
  
  (* compute layout parameters *)
  m.k := RealMath.sqrt(m.area / m.nNodes) / 5;
  IF m.gridCell THEN 
    m.k := m.k * 2
  END;
  m.k := m.k * m.separation;
  k2 := m.k * 2;
  kk := m.k * m.k;
  k2k2 := k2 * k2;
  m.gridX := ceiling(m.width / k2);
  m.gridY := ceiling(m.height / k2);
  m.gridZ := ceiling(m.depth / k2);
  
  FOR i := 0 TO m.nIterations-1 DO
    (* t is the maximum allowed displacement. This decreases with time to simulate a cooling process *)
    t := (m.nIterations - i)  * m.width / 10 / m.nIterations;
    
    (* compute repulsive forces *)
    v := m.nodes;
    WHILE v # NIL DO
      (* zero resultant forces *)
      v.dx := 0; v.dy := 0; v.dz := 0;
      IF ~ m.threeD THEN v.z := 0 END;
      (* assign cell to node. calculate adjacent cells *)
      IF m.gridCell THEN
        v.xCell := SHORT(SHORT(ENTIER(v.x / k2)));  loXCell := v.xCell - 1; hiXCell := v.xCell + 1;
        v.yCell := SHORT(SHORT(ENTIER(v.y / k2)));  loYCell := v.yCell - 1; hiYCell := v.yCell + 1;
        v.zCell := SHORT(SHORT(ENTIER(v.z / k2)));  loZCell := v.zCell - 1; hiZCell := v.zCell + 1;
      END;
      u := m.nodes;
      WHILE u # v DO
        (* compute for vertices in adjacent cells (gridCell) OR all vertices (~gridCell) *)
        IF ~m.gridCell OR ((u.xCell>=loXCell) & (u.xCell<=hiXCell) &
          (u.yCell>=loYCell) & (u.yCell<=hiYCell) & (u.zCell>=loZCell) & (u.zCell<=hiZCell)) THEN
          dx := v.x - u.x;  dy := v.y - u.y;  dz := v.z - u.z;
          d2 := dx * dx + dy * dy + dz * dz;
          IF m.gridCell & (d2>k2k2) THEN
            (* vertices are too far apart in gridCell model *)
          ELSE
            IF d2 < tiny THEN d2 := tiny END;
            fr := kk / d2;
            dx := dx * fr; dy := dy * fr;
            v.dx := v.dx + dx;   v.dy := v.dy + dy;
            u.dx := u.dx - dx;  u.dy := u.dy - dy;
            IF m.threeD THEN
              dz := dz * fr; 
              v.dz := v.dz + dz;  u.dz := u.dz - dz
            END (* IF *)
          END (* IF *)
        END (* IF *);
        u := u.next;
      END (* WHILE u *);
      v := v.next;
    END (* WHILE v *);
    
    v := m.nodes;
    WHILE v # NIL DO
      v.drx := v.dx; v.dry := v.dy; v.drz := v.dz;
      v := v.next;
    END;

    (* compute attractive forces *)
    e := m.edges;
    WHILE e # NIL DO
      v:= e.from; u := e.to;
      dx := v.x - u.x;  dy := v.y - u.y;  dz := v.z - u.z;
      d := RealMath.sqrt(dx * dx + dy * dy + dz * dz);
      fa := d / m.k;
      dx := dx * fa;  dy := dy * fa;
      u.dx := u.dx + dx;  u.dy := u.dy + dy;
      v.dx := v.dx - dx;  v.dy := v.dy - dy;
      IF m.threeD THEN
        dz := dz * fa;
        v.dz := v.dz - dz;  u.dz := u.dz + dz;
      END;
      e := e.next;
    END (* WHILE e  *);
    
    (* Displace nodes that are not fixed. 
    Limit the displacement to t, and ensure that nodes do not leave the graph space *)
    v := m.nodes;
    WHILE v # NIL DO
      IF ~ v.fixed THEN
        len := RealMath.sqrt(v.dx * v.dx + v.dy * v.dy + v.dz * v.dz);
        IF len > t THEN
          scale := t / len;
          v.dx := v.dx * scale; v.dy := v.dy * scale; v.dz := v.dz * scale;
        END;
        v.x := v.x + v.dx;  v.y := v.y + v.dy;  v.z := v.z + v.dz
      END;
      v.x := min(max(0, v.x), m.width);
      v.y := min(max(0, v.y), m.height);
      v.z := min(max(0, v.z), m.depth);
      v := v.next;
    END (* WHILE v *)
  END (* FOR *);
END Layout;

PROCEDURE (m : Model) Scatter*;
VAR n : Node;
BEGIN
  n := m.nodes;
  WHILE n # NIL DO
    n.x := RandomNumbers.Random() * m.width;
    n.y := RandomNumbers.Random() * m.height;
    n.z := RandomNumbers.Random() * m.depth;
    n.drx := 0; n.dry := 0; n.drz := 0;
    n := n.next;
  END;
END Scatter;

(* Node Functions *)

PROCEDURE (m : Model) AddNode* (intKey : LONGINT; strKey : ARRAY OF CHAR; x, y, z : REAL; fixed : BOOLEAN; VAR n : Node) : BOOLEAN;
BEGIN
  NEW(n);
  IF n # NIL THEN
    n.intKey := intKey;
    CopyString(strKey, n.strKey);
    n.x := x; n.y := y; n.z := z;
    n.fixed := fixed;
    n.next := m.nodes;
    m.nodes := n;
    INC(m.nNodes);
    RETURN TRUE
  END;
  RETURN FALSE
END AddNode;

PROCEDURE (m : Model) FindNodeByKey* (intKey : LONGINT; VAR node : Node) : BOOLEAN;
VAR n : Node;
BEGIN
  n := m.nodes;
  WHILE n # NIL DO
    IF n.intKey = intKey THEN
      node := n;
      RETURN TRUE
    END;
    n := n.next;
  END;
  RETURN FALSE;
END FindNodeByKey;

(* Edge Functions *)

PROCEDURE (m : Model) AddEdge* (intKey : LONGINT; from, to : LONGINT; VAR e : Edge) : BOOLEAN;
VAR
  fNode, tNode : Node;
BEGIN
  IF m.FindNodeByKey(from, fNode) & m.FindNodeByKey(to, tNode) THEN
    NEW(e);
    IF e # NIL THEN
      e.intKey := intKey;
      e.from:=fNode(Node); e.to:= tNode(Node);
      e.next := m.edges;
      m.edges := e;
      INC(m.nEdges);
      RETURN TRUE;
    END
  END;
  RETURN FALSE;
END AddEdge;

PROCEDURE (m : Model) FindEdgeByKey* (intKey : LONGINT; VAR edge : Edge) : BOOLEAN;
VAR e : Edge;
BEGIN
  e := m.edges;
  WHILE e # NIL DO
    IF e.intKey = intKey THEN
      edge := e;
      RETURN TRUE;
    END;
    e := e.next;
  END;
  RETURN FALSE;
END FindEdgeByKey;

PROCEDURE (m : Model) FindEdgeBetween* (from, to : LONGINT; VAR edge : Edge) : BOOLEAN;
VAR e : Edge;
BEGIN
  e := m.edges;
  WHILE e # NIL DO
    IF (e.from.intKey = from) & (e.to.intKey = to) THEN
      edge := e;
      RETURN TRUE;
    END;
    e := e.next;
  END;
  RETURN FALSE;
END FindEdgeBetween;

PROCEDURE (m : Model) MoveNodeByKey* (intKey : LONGINT; x, y, z : REAL);
VAR
  n : Node;
BEGIN
  IF m.FindNodeByKey(intKey, n) THEN
    n.x := x; n.y := y; n.z := z; 
  END;
END MoveNodeByKey;

PROCEDURE (m : Model) UpdateModel* ();
BEGIN
  m.Notify(NIL);
END UpdateModel;

(*
PROCEDURE (m : Model) InternalizeNodes(VAR rd : Stores.Reader);
VAR
  i : INTEGER;
  n : Node;
BEGIN
  FOR i := m TO m.nNodes DO
    IF rd.cancelled THEN RETURN END;
    NEW(n);
    ASSERT(n # NIL);
    rd.ReadInt(n.intKey);
    ReadStringKey(rd, n.strKey);
    rd.ReadReal(n.x);
    rd.ReadReal(n.y);
    rd.ReadReal(n.z);
    rd.ReadReal(n.drx);
    rd.ReadReal(n.dry);
    rd.ReadReal(n.drz);
    rd.ReadBool(n.fixed);
    n.next := g.nodes;
    g.nodes := n;
  END
END InternalizeNodes;

PROCEDURE (g : Model) InternalizeEdges(VAR rd : Stores.Reader);
VAR
  i, from, to : INTEGER;
  e : Edge;
BEGIN
  FOR i := 1 TO g.nEdges DO
    IF rd.cancelled THEN RETURN END;
    NEW(e);
    ASSERT(e#NIL);
    rd.ReadInt(e.intKey);
    rd.ReadInt(from);
    rd.ReadInt(to);
    ASSERT(g.FindNodeByKey(from, e.from) & g.FindNodeByKey(to, e.to));
    e.next := g.edges;
    g.edges := e;
  END
END InternalizeEdges;

PROCEDURE (m: Model) Internalize- (VAR rd: Stores.Reader);
VAR 
  version: INTEGER;
BEGIN
  IF ~rd.cancelled THEN
    rd.ReadVersion(minVersion, maxVersion, version);
    IF ~rd.cancelled THEN
      (* read Graph fields *)
      rd.ReadReal(m.width);
      rd.ReadReal(m.height);
      rd.ReadReal(m.depth);
      rd.ReadBool(m.threeD);
      rd.ReadBool(m.gridCell);
      rd.ReadReal(m.separation);
      rd.ReadInt(m.nIterations);
      rd.ReadInt(m.nNodes);
      rd.ReadInt(m.nEdges);
      m.InternalizeNodes(rd);
      m.InternalizeEdges(rd)
    END
  END
END Internalize;

PROCEDURE (m: Model) Externalize- (VAR wr: Stores.Writer);
VAR
  e : Edge; n : Node;
BEGIN
  wr.WriteVersion(maxVersion);
  wr.WriteReal(m.width);
  wr.WriteReal(m.height);
  wr.WriteReal(m.depth);
  wr.WriteBool(m.threeD);
  wr.WriteBool(m.gridCell);
  wr.WriteReal(m.separation);
  wr.WriteInt(m.nIterations);
  wr.WriteInt(m.nNodes);
  wr.WriteInt(m.nEdges);

  (* write nodes *) 
  n := m.nodes;
  WHILE n # NIL DO
    wr.WriteInt(n.intKey);
    WriteStringKey(wr, n.strKey);
    wr.WriteReal(n.x);
    wr.WriteReal(n.y);
    wr.WriteReal(n.z);
    wr.WriteReal(n.drx);  (* these may be needed for label-placement in some viewer options *)
    wr.WriteReal(n.dry);
    wr.WriteReal(n.drz);
    wr.WriteBool(n.fixed);
    n := n.next;
  END;  
  
  (* write edges *)
  e := m.edges;
  WHILE e # NIL DO
    wr.WriteInt(e.intKey);
    wr.WriteInt(e.from.intKey);
    wr.WriteInt(e.to.intKey);
    e := e.next;
  END;
END Externalize;

PROCEDURE (m: Model) CopyFrom- (source: Stores.Store);
VAR
  n, n2 : Node; e, e2 : Edge;
  result : BOOLEAN;
BEGIN
  WITH source: Model DO
    m.width := source.width;
    m.height := source.height;
    m.depth := source.depth;
    m.gridCell  := source.gridCell;
    m.separation := source.separation;
    m.nIterations := source.nIterations;
    m.threeD := source.threeD;
    m.nEdges := 0; m.nNodes := 0;
    n := source.nodes;
    WHILE n # NIL DO
      IF n.strKey # NIL THEN
        result := m.AddNode(n.intKey, n.strKey^, n.x, n.y, n.z, n.fixed, n2);
      ELSE
        result := m.AddNode(n.intKey, "", n.x, n.y, n.z, n.fixed, n2);
      END;
      n2.drx := n.drx; n2.dry := n.dry; n2.drz := n.drz;  (* needed for some viewer options *)
      n := n.next;
    END;
    e := source.edges;
    WHILE e # NIL DO
      result := m.AddEdge(e.intKey, e.from.intKey, e.to.intKey, e2);
      e := e.next;
    END;
  END
END CopyFrom;
*)

PROCEDURE (m : Model) CircleGraph* (VAR root : LONGINT; n : LONGINT);
VAR
  i : LONGINT;
  result : BOOLEAN;
  name : ARRAY 10 OF CHAR;
  newNode : Node;
  newEdge  : Edge;
BEGIN
  root := m.nNodes;
  FOR i := 0 TO n-1 DO
    IntStr.IntToStr(i, name);
    result := m.AddNode(root+i, name, 5, 5, 5, FALSE, newNode);
  END;
  FOR i := 0 TO n-1 DO
    result := m.AddEdge(m.nEdges, root+i, root + (i+1) MOD n, newEdge);
  END;
END CircleGraph;

PROCEDURE (m : Model) CubeGraph* (VAR root : LONGINT; depth : LONGINT);
VAR 
  i, j, link : LONGINT;
  count : LONGINT;
  name : ARRAY 10 OF CHAR;
  newNode : Node;
  newEdge : Edge;
  result : BOOLEAN;

BEGIN
  root := m.nNodes;
  count := 1;
  FOR i := 0 TO depth-1 DO count := count * 2 END;
  FOR i := 0 TO count-1 DO
    IntStr.IntToStr(i, name);
    result := m.AddNode(root + i, name, 5, 5, 5, FALSE, newNode);
  END;

  FOR i := 0 TO count-1 DO
    FOR j := 0 TO depth - 1 DO
      link := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, i) / {j});
      IF link > i THEN
        result := m.AddEdge(m.nEdges, i, link, newEdge);
      END;
    END;
  END;
END CubeGraph;

PROCEDURE (m : Model) TreeGraph* (VAR root : LONGINT; depth, branches : LONGINT);
  
  PROCEDURE Tree1(VAR idThis : LONGINT; level : LONGINT);
  VAR
    name : ARRAY 10 OF CHAR;
    result : BOOLEAN;
    i, child : LONGINT;
    newNode : Node;
    newEdge  : Edge;
  BEGIN
    idThis := m.nNodes;
    IntStr.IntToStr(idThis, name); 
    result := m.AddNode(idThis, name, 5, 5, 5, FALSE, newNode);
    IF level > 0 THEN
      FOR i := 1 TO branches DO
        Tree1(child, level-1);
        result := m.AddEdge(m.nEdges, idThis, child, newEdge);
      END;
    END;
  END Tree1;
  
BEGIN
  ASSERT(depth >= 0, 20);
  Tree1(root, depth);
END TreeGraph;

(*
PROCEDURE (m : Model) Show();
VAR
  n : Node; e : Edge;
BEGIN
  Out.String("Graph ("); 
  Out.Real(m.width,0,0); Out.String(","); Out.Real(m.height,0,0); Out.String(","); Out.Real(m.depth,0,0); Out.String(")"); Out.Ln;
  n := m.nodes;
  WHILE n # NIL DO
    Out.String("Node("); Out.LongInt(n.intKey,0); Out.String(","); Out.String(n.strKey^);  Out.String(")");
    n := n.next;
  END;
  Out.Ln;
  e := m.edges;
  WHILE e # NIL DO
    Out.String("Edge("); Out.LongInt(e.intKey,0); Out.String(")");
    e := e.next;
  END;
  Out.Ln;
END Show;
*)

END GraphModel.

