MODULE Geometry;

IMPORT RealMath;

CONST
  xAxis*=0;
  yAxis*=1;
  zAxis*=2;
  sAxis*=3;
  
TYPE
  Axis* = INTEGER;
  
  Point* = RECORD
    p* : ARRAY 4 OF REAL;
  END;
  
  Transform* = RECORD
    matrix* : ARRAY 4,4 OF REAL;
  END;

PROCEDURE (VAR p : Point) Set*(x, y, z, scale : REAL);
BEGIN
  p.p[xAxis] := x;
  p.p[yAxis] := y;
  p.p[zAxis] := z;
  p.p[sAxis] := scale;
END Set;
  
PROCEDURE (VAR t : Transform) Unity*();
VAR i, j : INTEGER;
BEGIN
  FOR i := 0 TO 3 DO
    FOR j := 0 TO 3 DO
      IF i=j THEN
        t.matrix[i,j] := 1 
      ELSE
        t.matrix[i,j] := 0;
      END
    END
  END
END Unity;

PROCEDURE (VAR t : Transform) Translate*(x, y, z : REAL);
BEGIN
  t.Unity();
  t.matrix[sAxis,xAxis] := x;
  t.matrix[sAxis,yAxis] := y;
  t.matrix[sAxis,zAxis] := z;
END Translate;

PROCEDURE (VAR t : Transform) Rotate*(a : Axis; angle : REAL);
VAR
  first, second : Axis;
  s, c : REAL;
BEGIN
  s := RealMath.sin(angle); c := RealMath.cos(angle);
  CASE a OF
    xAxis:  first := yAxis; second := zAxis;
  | yAxis:  first := xAxis; second := zAxis;
  | zAxis:  first := xAxis; second := yAxis;
  ELSE
    RETURN
  END;
  t.Unity();
  t.matrix[first, first] := c;
  t.matrix[second, second] := c;
  t.matrix[first, second] := -s;
  t.matrix[second, first] := s;
END Rotate;

PROCEDURE (VAR t : Transform) Project*(a : Axis; factor : REAL);
BEGIN
  t.Unity();
  t.matrix[a,sAxis] := factor;
END Project;

PROCEDURE (VAR t : Transform) PostMultiply*(VAR in, out : Transform);
VAR
  i, j, k : INTEGER;
  sum : REAL;
BEGIN
  FOR i := 0 TO 3 DO
    FOR j := 0 TO 3 DO
      sum := 0;
      FOR k := 0 TO 3 DO
        sum := sum + t.matrix[i, k] * in.matrix[k, j]
      END;
      out.matrix[i, j] := sum
    END
  END
END PostMultiply;

PROCEDURE (VAR t : Transform) PreMultiply*(VAR in, out : Transform);
VAR
  i, j, k : INTEGER;
  sum : REAL;
BEGIN
  FOR i := 0 TO 3 DO
    FOR j := 0 TO 3 DO
      sum := 0;
      FOR k := 0 TO 3 DO
        sum := sum + in.matrix[i, k] * t.matrix[k, j]
      END;
      out.matrix[i, j] := sum
    END
  END
END PreMultiply;

PROCEDURE (VAR t : Transform) Multiply*(VAR in, out : Point; normalise : BOOLEAN);
VAR
  i, j : INTEGER;
  sum, scale : REAL;
BEGIN
  FOR i := 0 TO 3 DO
    sum := 0;
    FOR j := 0 TO 3 DO 
      sum := sum + in.p[j] * t.matrix[j,i]
    END;
    out.p[i] := sum
  END;
  IF normalise THEN
    (* multiply is faster than divide *)
    ASSERT(out.p[sAxis] # 0);
    scale := 1 / out.p[sAxis];
    out.p[xAxis] := out.p[xAxis] * scale;
    out.p[yAxis] := out.p[yAxis] * scale;
    out.p[zAxis] := out.p[zAxis] * scale;
    out.p[sAxis] := 1;
  END
END Multiply;

END Geometry.
