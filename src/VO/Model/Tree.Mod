(**
  A model for tree-like data structures.
**)

MODULE VO:Model:Tree;

(*
    A model for table-like data.
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

IMPORT O    := VO:Base:Object,

               Object;

TYPE
  TreeModel*     = POINTER TO TreeModelDesc;
  TreeItem*      = POINTER TO TreeItemDesc;


  TreeItemDesc*  = RECORD
                     model        : TreeModel;
                     parent-,
                     last-,
                     next-,
                     firstChild-,
                     lastChild-   : TreeItem;
                     visible-,
                     childs-      : LONGINT;
                     shown-       : BOOLEAN;
                   END;

  TextItem*      = POINTER TO TextItemDesc;
  TextItemDesc*  = RECORD (TreeItemDesc)
                     string : STRING;
                   END;


  TreeModelDesc* = RECORD (O.ModelDesc)
                     top-     : TreeItem;
                     total-,
                     childs,
                     visible- : LONGINT;
                   END;

  (*
    Notify, that an item has changed the visibility state of its childs.
  *)

  ItemSwitchedMsg*     = POINTER TO ItemSwitchedMsgDesc;
  ItemSwitchedMsgDesc* = RECORD (O.ResyncMsgDesc)
                         END;

  PROCEDURE (t : TreeItem) Init*(model : TreeModel);

    (**
      Initialize the treeitem
    *)

  BEGIN
    ASSERT(model#NIL);

    t.model:=model;
    t.parent:=NIL;
    t.last:=NIL;
    t.next:=NIL;
    t.firstChild:=NIL;
    t.lastChild:=NIL;
    t.childs:=0;
    t.visible:=0;
    t.shown:=FALSE;
  END Init;

  PROCEDURE (t : TreeItem) GetString*():STRING;

    (**
      Return the text belonging to the treeitem. It is allowed to return NIL.
      This method always returns NIL. You have to derive from TreeItem and implement
      this method. This way you can influence the way the item stores the text.
    *)

  BEGIN
    RETURN NIL;
  END GetString;

  PROCEDURE (t : TreeItem) UpdateChildCount(count : LONGINT);

  BEGIN
    INC(t.childs,count);
    IF t.parent#NIL THEN
      t.parent.UpdateChildCount(count);
    ELSE
      INC(t.model.total,count);
    END;
  END UpdateChildCount;

  PROCEDURE (t : TreeModel) RecalcVisible;

  VAR
    item : TreeItem;

  BEGIN
    t.visible:=0;
    item:=t.top;
    WHILE item#NIL DO
      INC(t.visible,item.visible+1);
      item:=item.next;
    END;
  END RecalcVisible;

  PROCEDURE (t : TreeItem) RecalcVisible;

  VAR
    item : TreeItem;

  BEGIN
    t.visible:=0;
    IF t.shown THEN
      item:=t.firstChild;
      WHILE item#NIL DO
        INC(t.visible,item.visible+1);
        item:=item.next;
      END;
    END;

    IF t.parent#NIL THEN
      IF t.parent.shown THEN
        t.parent.RecalcVisible;
      END;
    ELSE
      t.model.RecalcVisible;
    END;
  END RecalcVisible;

  PROCEDURE (t : TreeItem) AddChild*(item : TreeItem);

    (**
      Append a new child to the list of existing childs of the current item.
    *)

  BEGIN
    ASSERT(item#NIL);

    IF t.firstChild=NIL THEN
      t.firstChild:=item;
      item.last:=NIL;
    ELSE
      t.lastChild.next:=item;
      item.last:=t.lastChild;
    END;
    t.lastChild:=item;

    item.parent:=t;

    INC(t.childs);
    IF t.shown THEN
      INC(t.visible);
    END;

    t.UpdateChildCount(item.childs+1);
    IF t.shown THEN
      t.RecalcVisible;
    END;

    t.model.Notify(NIL);
  END AddChild;

  (**

  **)

  PROCEDURE (t : TreeItem) InsertAfter*(item : TreeItem);

  BEGIN
    ASSERT(item#NIL);

    item.next:=t.next;
    IF t.next#NIL THEN
      t.next.last:=item;
    END;
    item.last:=t;
    t.next:=item;
    item.parent:=t.parent;

    t.UpdateChildCount(item.childs+1);

    IF t.parent#NIL THEN
      IF t.parent.shown THEN
        t.parent.RecalcVisible;
      END;
    ELSE
      INC(t.model.visible,item.visible+1);
      INC(t.model.childs);
    END;
  END InsertAfter;

  PROCEDURE (t : TreeItem) ShowChildren*;

    (**
      Show the children of this item.
    *)

  VAR
    switched : ItemSwitchedMsg;

  BEGIN
    t.shown:=TRUE;
    t.RecalcVisible;

    NEW(switched);
    t.model.Notify(switched);
  END ShowChildren;

  PROCEDURE (t : TreeItem) HideChildren*;

    (**
      Hide the children of this item.
    *)

  VAR
    switched : ItemSwitchedMsg;

  BEGIN
    t.shown:=FALSE;
    t.RecalcVisible;

    NEW(switched);
    t.model.Notify(switched);
  END HideChildren;

  PROCEDURE (t : TreeItem) HasChildren*():BOOLEAN;

    (**
      returns TRUE if the item has children.
    *)

  BEGIN
    RETURN t.firstChild#NIL;
  END HasChildren;

  PROCEDURE (t : TreeItem) IsVisible*():BOOLEAN;

    (**
      Return TRUE, if the item is currently visible. This routine is possibly
      expensive, since it walks up in the tree to check if all parents are visible.
    *)

  VAR
    item : TreeItem;

  BEGIN
    item:=t.parent;
    WHILE (item#NIL) & item.shown DO
      item:=item.parent;
    END;

    RETURN item=NIL;
  END IsVisible;

  PROCEDURE (t : TreeItem) VisibleParent*():TreeItem;

    (**
      Return the next visible parent or the object itself, if it is visible.
      As isVisible this method is rather expensive.
    *)

  VAR
    item : TreeItem;

  BEGIN
    item:=t;
    WHILE (item#NIL) & ~item.IsVisible() DO
      item:=item.parent;
    END;

    RETURN item;
  END VisibleParent;

  PROCEDURE (t : TreeItem) Last*():TreeItem;

    (**
      Returns the last visible entry.
      It is current exspected that the current item is already visible.
    *)

  BEGIN
    IF t.last#NIL THEN
      IF (t.last.lastChild#NIL) & t.last.lastChild.IsVisible() THEN
        RETURN t.last.lastChild;
      ELSE
        RETURN t.last;
      END;
    ELSE
      RETURN t.parent;
    END;
  END Last;

  PROCEDURE (t : TreeItem) Next*():TreeItem;

    (**
      Returns the next visible entry.
      It is current exspected that the current item is already visible.
    *)

  VAR
    item : TreeItem;

  BEGIN
    IF (t.firstChild#NIL) & t.firstChild.IsVisible() THEN
      RETURN t.firstChild;
    ELSIF t.next#NIL THEN
      RETURN t.next;
    ELSE
      item:=t.parent;
      WHILE (item#NIL) & (item.next=NIL) & ~item.IsVisible() DO
        item:=item.parent;
      END;
      IF item#NIL THEN
        RETURN item.next;
      ELSE
        RETURN NIL;
      END;
    END;
  END Next;

  PROCEDURE (t : TextItem) Init*(model : TreeModel);

  BEGIN
    t.Init^(model);

    t.string:=NIL;
  END Init;

  PROCEDURE (t : TextItem) SetString*(string : STRING);

  BEGIN
    t.string:=string;

    t.model.Notify(NIL);
  END SetString;

  PROCEDURE (t : TextItem) SetText*(text : ARRAY OF CHAR);

  BEGIN
    t.SetString(Object.NewLatin1(text));
  END SetText;

  PROCEDURE (t : TextItem) GetString*():STRING;

  BEGIN
    RETURN t.string;
  END GetString;

  PROCEDURE (t : TreeModel) Init*;

  BEGIN
    t.Init^;

    t.top:=NIL;
    t.total:=0;
    t.childs:=0;
    t.visible:=0;
  END Init;

  PROCEDURE (t : TreeModel) SetTop*(item : TreeItem);

  BEGIN
    t.top:=item;
    t.total:=item.childs+1;
    t.visible:=t.top.visible+1;

    t.childs:=0;
    WHILE item#NIL DO
      INC(t.childs);
      item:=item.next;
    END;

    t.Notify(NIL);
  END SetTop;

  PROCEDURE (t : TreeModel) GetVisibleItem*(pos : LONGINT; VAR indent : LONGINT):TreeItem;

  VAR
    item : TreeItem;
    help : LONGINT;

  BEGIN
    item:=t.top;
    indent:=0;
    help:=1;
    WHILE (help#pos) & (item#NIL) DO
      IF help+item.visible<pos THEN
        INC(help,item.visible+1);
        item:=item.next;
      ELSE
        item:=item.firstChild;
        INC(indent);
        INC(help);
      END;
    END;

    RETURN item;
  END GetVisibleItem;

  PROCEDURE CreateStringItem*(model : TreeModel; string : STRING):TextItem;

  VAR
    item : TextItem;

  BEGIN
    NEW(item);
    item.Init(model);
    item.SetString(string);

    RETURN item;
  END CreateStringItem;

  PROCEDURE CreateTextItem*(model : TreeModel; text : ARRAY OF CHAR):TextItem;

  VAR
    item : TextItem;

  BEGIN
    NEW(item);
    item.Init(model);
    item.SetText(text);

    RETURN item;
  END CreateTextItem;

END VO:Model:Tree.