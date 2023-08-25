MODULE VO:Panel;

  (*
    Implements a layouting group.
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

IMPORT U := VO:Base:Util,

       G := VO:Object;

CONST
  horizontal* = 0; (** Objects are arranged horizontal *)
  vertical*   = 1; (** Objects are arranged vertical *)

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
               END;


  Panel*     = POINTER TO PanelDesc;
  PanelDesc* = RECORD (G.GroupDesc)
                 (**
                   A layouting class for grouping objects horizontaly or verticaly.
                   Does some complex resizing operations to make the arrangement
                   of its children look lice.

                   On initialisation @otype{Panel} tries to use maximum space by
                   resizing resizable cotnrols to aclaim all available space.

                   On resize the same space is given and taken from all controls
                   that can change their size.

                   If space is still left, object will be drawing from left to right
                   or top to bottom depending on the direction of @otype{Panel}.
                 *)
                 type : LONGINT;
               END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Panel) Init*;

  BEGIN
    p.Init^;

    p.SetPrefs(prefs);

    p.type:=vertical;
  END Init;

  PROCEDURE (p : Panel) Set*(type : LONGINT);

    (**
      Set the direction (horizontal or vertical) of the panel.
    *)

  BEGIN
    p.type:=type;
  END Set;

  PROCEDURE (p : Panel) CalcSize*;

  VAR
    object : G.Object;

  BEGIN
    p.width:=0;
    p.height:=0;
    p.minWidth:=0;
    p.minHeight:=0;

    object:=p.list;
    WHILE object#NIL DO
      object.CalcSize;
      object:=object.next;
    END;

    object:=p.list;
    WHILE object#NIL DO
      IF p.type=vertical THEN
        p.width:=U.MaxLong(p.width,object.oWidth);
        INC(p.height,object.oHeight);

        p.minWidth:=U.MaxLong(p.minWidth,object.oMinWidth);
        INC(p.minHeight,object.oMinHeight);
      ELSE
        INC(p.width,object.oWidth);
        p.height:=U.MaxLong(p.height,object.oHeight);

        INC(p.minWidth,object.oMinWidth);
        p.minHeight:=U.MaxLong(p.minHeight,object.oMinHeight);
      END;

      object:=object.next;
    END;

    p.CalcSize^;
  END CalcSize;

  PROCEDURE (p : Panel) Layout*;

  VAR
    size,
    count,
    old,
    pos    : LONGINT;
    object : G.Object;

  BEGIN
    IF p.type=horizontal THEN
      size:=0;
      object:=p.list;
      WHILE object#NIL DO
        object.Resize(object.oMinWidth,p.height);
        INC(size,object.oMinWidth);
        object:=object.next;
      END;
    ELSE (* vertical *)
      size:=0;
      object:=p.list;
      WHILE object#NIL DO
        object.Resize(p.width,object.oMinHeight);
        INC(size,object.oMinHeight);
        object:=object.next;
      END;
    END;

    IF p.type=horizontal THEN
      LOOP
        (* count number of resizable objects *)
        count:=0;
        object:=p.list;
        WHILE object#NIL DO
          IF object.CanResize(p.width>=size,TRUE) THEN
            INC(count);
          END;
          object:=object.next;
        END;

        (* we leave the loop if there are no objects (anymore) that can be resized *)
        IF count=0 THEN
          EXIT;
        END;

        object:=p.list;
        WHILE object#NIL DO
          IF object.CanResize(p.width>=size,TRUE) THEN
            old:=object.oWidth;
            object.Resize(object.oWidth+U.UpDiv(p.width-size,count),-1);
            INC(size,object.oWidth-old);
            DEC(count);
          END;
          object:=object.next;
        END;

          (* no space left to delegate *)
        IF size=p.width THEN
          EXIT;
        END;
      END;
    ELSE (* vertical *)
      LOOP
        (* count number of resizable objects *)
        count:=0;
        object:=p.list;
        WHILE object#NIL DO
          IF object.CanResize(p.height>size,FALSE) THEN
            INC(count);
          END;
          object:=object.next;
        END;

        (* we leave the loop if there are no objects (anymore) that can be resized *)
        IF count=0 THEN
          EXIT;
        END;

        object:=p.list;
        WHILE object#NIL DO
          IF object.CanResize(p.height>size,FALSE) THEN
            old:=object.oHeight;
            object.Resize(-1,object.oHeight+U.UpDiv(p.height-size,count));
            INC(size,object.oHeight-old);
            DEC(count);
          END;
          object:=object.next;
        END;

        (* no space left to delegate *)
        IF size=p.height THEN
          EXIT;
        END;
      END;
    END;

    IF p.type=horizontal THEN
      pos:=p.x;
      object:=p.list;
      WHILE object#NIL DO
        object.Move(pos,p.y+(p.height-object.oHeight) DIV 2);
        INC(pos,object.oWidth);
        object:=object.next;
      END;
    ELSE (* vertical *)
      pos:=p.y;
      object:=p.list;
      WHILE object#NIL DO
        object.Move(p.x+(p.width-object.oWidth) DIV 2,pos);
        INC(pos,object.oHeight);
        object:=object.next;
      END;
    END;

    p.Layout^;
  END Layout;

  PROCEDURE CreatePanel*():Panel;

    (**
      Creates a new instance of @otype{Panel}.
    *)

  VAR
    panel : Panel;

  BEGIN
    NEW(panel);
    panel.Init;

    RETURN panel;
  END CreatePanel;

  PROCEDURE CreateHPanel*():Panel;

    (**
      Creates a new instance of @otype{Panel} with horizontal direction.
    *)

  VAR
    panel : Panel;

  BEGIN
    panel:=CreatePanel();
    panel.Set(horizontal);

    RETURN panel;
  END CreateHPanel;

  PROCEDURE CreateVPanel*():Panel;

    (**
      Creates a new instance of @otype{Panel} with vertical direction.
    *)

  VAR
    panel : Panel;

  BEGIN
    panel:=CreatePanel();
    panel.Set(vertical);

    RETURN panel;
  END CreateVPanel;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Panel.