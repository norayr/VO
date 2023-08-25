MODULE VO:Grid;

  (**
    Implements @otype{Grid}.
  *)

  (*
    Implements a grid gadget.
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


IMPORT U  := VO:Base:Util,
       Z  := VO:Base:Size,

       G  := VO:Object;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hSpace*,
                 vSpace* : Z.SizeDesc;
               END;

  InfoDesc  = RECORD
                minSize,
                size,
                maxSize,
                pos      : LONGINT;
              END;

  Row       = POINTER TO ARRAY OF G.Object;
  Rows      = POINTER TO ARRAY OF Row;
  Size      = POINTER TO ARRAY OF InfoDesc;

  Grid*     = POINTER TO GridDesc;
  GridDesc* = RECORD (G.LayoutDesc)
                (**
                  A grid is an layouting object that devides the available space
                  into a table, where each cell in a row ha sthe same height and
                  cell in a column the same width. You can assign an object to a
                  subset of cells.
                *)
                rows        : Rows;

                rowHeight,
                columnWidth : Size;

                hSpace,
                vSpace      : BOOLEAN;
              END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hSpace.Init;
    p.vSpace.Init;
    p.hSpace.SetSize(Z.unit,1);
    p.vSpace.SetSize(Z.unit,1);
  END Initialize;

  PROCEDURE (g : Grid) Init*;

  BEGIN
    g.Init^;

    g.SetPrefs(prefs); (* We set the prefs *)

    g.rows:=NIL;
    g.rowHeight:=NIL;
    g.columnWidth:=NIL;

    g.hSpace:=FALSE;
    g.vSpace:=FALSE;
  END Init;

  PROCEDURE (g : Grid) VisitChildren*(VAR visitor : G.VisitorDesc;
                                      onlyVisible : BOOLEAN):BOOLEAN;

  VAR
    x,y : LONGINT;

  BEGIN
    y:=0;
    WHILE y<LEN(g.rows^) DO
      x:=0;
      WHILE x<LEN(g.rows[y]^) DO
        IF g.rows[y][x]#NIL THEN
          IF ~visitor.Visit(g.rows[y][x]) THEN
            RETURN FALSE;
          END;
        END;

        INC(x);
      END;

      INC(y);
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (g : Grid) SetSpace*(horizontal, vertical : BOOLEAN);

    (**
      Specifies if space should be left between columns (@oparam{horizontal})
      and rows (@oparam{vertical}).
    *)

  BEGIN
    g.hSpace:=horizontal;
    g.vSpace:=vertical;
  END SetSpace;

  PROCEDURE (g : Grid) SetGridSize*(width, height : LONGINT);

    (**
      Sets the size of the grid. If you assign an object outside the grid
      the grid will automatically be resized (if not yet drawn). So it is
      not necessary to assign a size to the grid, because it will size itself,
      but for a larger grid presizing the grid may be faster.
    *)

  VAR
    x,y     : LONGINT;
    oldRows : Rows;
    oldRow  : Row;

  BEGIN
    IF (g.rows=NIL) OR (LEN(g.rows^)<height) THEN
      oldRows:=g.rows;

      NEW(g.rows,height);
      y:=0;
      IF oldRows#NIL THEN
        WHILE y<LEN(oldRows^) DO
          g.rows[y]:=oldRows[y];
          INC(y);
        END;
      END;

      WHILE y<height DO
        NEW(g.rows[y],width);
        FOR x:=0 TO width-1 DO
          g.rows[y][x]:=NIL;
        END;
        INC(y);
      END;
    END;

    FOR y:=0 TO LEN(g.rows^)-1 DO
      IF (g.rows[y]=NIL) OR (LEN(g.rows[y]^)<width) THEN
        oldRow:=g.rows[y];
        NEW(g.rows[y],width);

        x:=0;
        IF oldRow#NIL THEN
          WHILE x<LEN(oldRow^) DO
            g.rows[y][x]:=oldRow[x];
            INC(x);
          END;
        END;

        WHILE x<width DO
          g.rows[y][x]:=NIL;
          INC(x);
        END;
      END;
    END;
  END SetGridSize;

  PROCEDURE (g : Grid) SetObject*(x,y : LONGINT; object : G.Object);

    (**
      Assign an object to a cell. Coordinates are zero based (0..size-1).
    *)

  BEGIN
    g.SetGridSize(x+1,y+1);

    IF object#NIL THEN
      object.SetParent(g);
    END;

    g.rows[y][x]:=object;
  END SetObject;

  PROCEDURE (g : Grid) CalcSize*;

  VAR
    x,y : LONGINT;

  BEGIN
    NEW(g.rowHeight,LEN(g.rows^));
    FOR y:=0 TO LEN(g.rows^)-1 DO
      g.rowHeight[y].minSize:=0;
      g.rowHeight[y].size:=0;
      g.rowHeight[y].maxSize:=MAX(LONGINT)-4;
    END;

    NEW(g.columnWidth,LEN(g.rows[0]^));
    FOR x:=0 TO LEN(g.rows[0]^)-1 DO
      g.columnWidth[x].minSize:=0;
      g.columnWidth[x].size:=0;
      g.columnWidth[x].maxSize:=MAX(LONGINT)-4;
    END;

    y:=0;
    WHILE y<LEN(g.rows^) DO
      x:=0;
      WHILE x<LEN(g.rows[y]^) DO
        IF g.rows[y][x]#NIL THEN
          g.rows[y][x].CalcSize;

          g.rowHeight[y].minSize:=U.MaxLong(g.rowHeight[y].minSize,g.rows[y][x].oMinHeight);
          g.rowHeight[y].size:=U.MaxLong(g.rowHeight[y].size,g.rows[y][x].oHeight);
          g.rowHeight[y].maxSize:=U.MinLong(g.rowHeight[y].maxSize,g.rows[y][x].oMaxHeight);

          g.columnWidth[x].minSize:=U.MaxLong(g.columnWidth[x].minSize,g.rows[y][x].oMinWidth);
          g.columnWidth[x].size:=U.MaxLong(g.columnWidth[x].size,g.rows[y][x].oWidth);
          g.columnWidth[x].maxSize:=U.MinLong(g.columnWidth[x].maxSize,g.rows[y][x].oMaxWidth);
        END;

        INC(x);
      END;

      INC(y);
    END;

    g.minWidth:=0;
    g.width:=0;
(*    g.maxWidth:=0; MAX(LONGINT)-4;*)
    FOR x:=0 TO LEN(g.columnWidth^)-1 DO
      INC(g.minWidth,g.columnWidth[x].minSize);
      INC(g.width,g.columnWidth[x].size);
(*      INC(g.maxWidth,g.columnWidth[x].maxSize);*)
    END;

    g.minHeight:=0;
    g.height:=0;
(*    g.maxHeight:=0; MAX(LONGINT)-4;*)
    FOR y:=0 TO LEN(g.rowHeight^)-1 DO
      INC(g.minHeight,g.rowHeight[y].minSize);
      INC(g.height,g.rowHeight[y].size);
(*      INC(g.maxHeight,g.rowHeight[y].maxSize);*)
    END;

    IF g.hSpace THEN
      INC(g.minWidth,(LEN(g.columnWidth^)-1)*g.prefs(Prefs).hSpace.GetSize());
      INC(g.width,(LEN(g.columnWidth^)-1)*g.prefs(Prefs).hSpace.GetSize());
    END;

    IF g.vSpace THEN
      INC(g.minHeight,(LEN(g.rowHeight^)-1)*g.prefs(Prefs).vSpace.GetSize());
      INC(g.height,(LEN(g.rowHeight^)-1)*g.prefs(Prefs).vSpace.GetSize());
    END;

    g.CalcSize^;
  END CalcSize;

  PROCEDURE (g : Grid) CalculatePos();

  VAR
    x,y : LONGINT;

  BEGIN
    g.columnWidth[0].pos:=0;
    FOR x:=1 TO LEN(g.columnWidth^)-1 DO
      g.columnWidth[x].pos:=g.columnWidth[x-1].pos+g.columnWidth[x-1].size;

      IF g.hSpace THEN
        INC(g.columnWidth[x].pos,g.prefs(Prefs).hSpace.GetSize());
      END;
    END;

    g.rowHeight[0].pos:=0;
    FOR y:=1 TO LEN(g.rowHeight^)-1 DO
      g.rowHeight[y].pos:=g.rowHeight[y-1].pos+g.rowHeight[y-1].size;

      IF g.vSpace THEN
        INC(g.rowHeight[y].pos,g.prefs(Prefs).vSpace.GetSize());
      END;
    END;
  END CalculatePos;

  PROCEDURE (g : Grid) Layout*;

  VAR
    X,Y,
    oldSize,
    newSize,
    count,
    old     : LONGINT;
    object  : G.Object;

  BEGIN
    oldSize:=0;
    FOR X:=0 TO LEN(g.columnWidth^)-1 DO
      INC(oldSize,g.columnWidth[X].size);
    END;

    newSize:=g.width;
    IF g.hSpace THEN
      DEC(newSize,(LEN(g.columnWidth^)-1)*g.prefs(Prefs).hSpace.GetSize());
    END;

    (* resize columns *)
    LOOP
      (* count number of resizable objects *)
      count:=0;
      FOR X:=0 TO LEN(g.columnWidth^)-1 DO
        IF ((oldSize<newSize) & (g.columnWidth[X].size<g.columnWidth[X].maxSize)) OR
           ((newSize<oldSize) & (g.columnWidth[X].size>g.columnWidth[X].minSize)) THEN
          INC(count);
        END;
      END;

      (* we leave the loop if there are no objects (anymore) that can be resized *)
      IF count=0 THEN
        EXIT;
      END;

      FOR X:=0 TO LEN(g.columnWidth^)-1 DO
        IF ((oldSize<newSize) & (g.columnWidth[X].size<g.columnWidth[X].maxSize)) OR
           ((newSize<oldSize) & (g.columnWidth[X].size>g.columnWidth[X].minSize)) THEN
          old:=g.columnWidth[X].size;
          INC(g.columnWidth[X].size,U.UpDiv(newSize-oldSize,count));
          g.columnWidth[X].size:=U.RoundRange(g.columnWidth[X].size,
                                              g.columnWidth[X].minSize,
                                              g.columnWidth[X].maxSize);
          INC(oldSize,g.columnWidth[X].size-old);
          DEC(count);
        END;
      END;

      (* no space left to delegate *)
      IF oldSize=newSize THEN
        EXIT;
      END;
    END;

    oldSize:=0;
    FOR X:=0 TO LEN(g.rowHeight^)-1 DO
      INC(oldSize,g.rowHeight[X].size);
    END;

    newSize:=g.height;
    IF g.vSpace THEN
      DEC(newSize,(LEN(g.rowHeight^)-1)*g.prefs(Prefs).vSpace.GetSize());
    END;

    (* resize rows *)
    LOOP
      (* count number of resizable objects *)
      count:=0;
      FOR X:=0 TO LEN(g.rowHeight^)-1 DO
        IF ((oldSize<newSize) & (g.rowHeight[X].size<g.rowHeight[X].maxSize)) OR
           ((newSize<oldSize) & (g.rowHeight[X].size>g.rowHeight[X].minSize)) THEN
          INC(count);
        END;
      END;

      (* we leave the loop if there are no objects (anymore) that can be resized *)
      IF count=0 THEN
        EXIT;
      END;

      FOR X:=0 TO LEN(g.rowHeight^)-1 DO
        IF ((oldSize<newSize) & (g.rowHeight[X].size<g.rowHeight[X].maxSize)) OR
           ((newSize<oldSize) & (g.rowHeight[X].size>g.rowHeight[X].minSize)) THEN
          old:=g.rowHeight[X].size;
          INC(g.rowHeight[X].size,U.UpDiv(newSize-oldSize,count));
          g.rowHeight[X].size:=U.RoundRange(g.rowHeight[X].size,
                                              g.rowHeight[X].minSize,
                                              g.rowHeight[X].maxSize);
          INC(oldSize,g.rowHeight[X].size-old);
          DEC(count);
        END;
      END;

      (* no space left to delegate *)
      IF oldSize=newSize THEN
        EXIT;
      END;
    END;

    g.CalculatePos;

    Y:=0;
    WHILE Y<LEN(g.rows^) DO
      X:=0;
      WHILE X<LEN(g.rows[Y]^) DO
        IF g.rows[Y][X]#NIL THEN
          object:=g.rows[Y][X];
          object.Resize(g.columnWidth[X].size,g.rowHeight[Y].size);
          object.Move(g.x+g.columnWidth[X].pos,g.y+g.rowHeight[Y].pos);
        END;
        INC(X);
      END;
      INC(Y);
    END;

    g.Layout^;
  END Layout;

  PROCEDURE CreateGrid*(): Grid;

    (**
      Creates a new instance of @otype{Grid}.
    *)

  VAR
    grid : Grid;

  BEGIN
    NEW(grid);
    grid.Init;

    RETURN grid;
  END CreateGrid;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Grid.