MODULE VO:Label;

  (**
    Implements @otype{Label}.
  *)

  (*
    A layouting class that gives you labels.
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

IMPORT D   := VO:Base:Display,
       U   := VO:Base:Util,
       Z   := VO:Base:Size,

       G   := VO:Object,
       P   := VO:Panel,
       T   := VO:Text;

CONST
  left*  = 0;
  right* = 1;

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 hSpace*,
                 vSpace*      : Z.SizeDesc;
                 labelPos*    : LONGINT;
                 labelAlign*  : LONGINT;
                 objectAlign* : LONGINT;
               END;


  Text       = POINTER TO TextDesc;
  TextDesc   = RECORD
                 next     : Text;
                 object,
                 text     : G.Object;
               END;

  Label*     = POINTER TO LabelDesc;
  LabelDesc* = RECORD(G.LayoutDesc)
                 (**
                   A layoutobject that generates a vertical list of aligned
                   textlabel and object pairs.

                   It automatically adds spaces and corretcly aligns the
                   labels and controls for optimal look.
                 *)
                 count      : LONGINT;
                 lSize,
                 rSize      : LONGINT;
                 labelList,
                 lLast      : Text;
                 labelFlex  : BOOLEAN;
               END;

  RealignVisitorDesc = RECORD (G.VisitorDesc)
                         me : Label;;
                       END;


VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.hSpace.Init;
    p.vSpace.Init;
    IF D.display.displayType=D.displayTypeTextual THEN
      p.hSpace.SetSize(Z.unit,1);
      p.vSpace.SetSize(Z.pixel,0);
    ELSE
      p.hSpace.SetSize(Z.unit,1);
      p.vSpace.SetSize(Z.unit,1);
    END;

    p.labelPos:=left;
    p.labelAlign:=right;
    p.objectAlign:=left;
  END Initialize;

  PROCEDURE (l : Label) Init*;

  BEGIN
    l.Init^;

    l.SetPrefs(prefs);

    l.labelList:=NIL;
    l.lLast:=NIL;
    l.count:=0;
    l.lSize:=0;
    l.rSize:=0;

    l.labelFlex:=FALSE;
  END Init;

  PROCEDURE (l : Label) VisitChildren*(VAR visitor : G.VisitorDesc;
                                       onlyVisible : BOOLEAN):BOOLEAN;

  VAR
    label : Text;

  BEGIN
    label:=l.labelList;
    WHILE label#NIL DO
      IF label.object#NIL THEN
        IF ~visitor.Visit(label.object) THEN
          RETURN FALSE;
        END;
      END;

      IF label.text#NIL THEN
        IF ~visitor.Visit(label.text) THEN
          RETURN FALSE;
        END;
      END;
      label:=label.next;
    END;

    RETURN TRUE;
  END VisitChildren;

  PROCEDURE (l : Label) AddLabel*(text, object : G.Object);

    (**
      Add a new entry to the label. A label entry consists of two objects.
      @oparam{text} should be a textual label, while @oparam{object} is the
      object @oparam{text} is the label for.
    *)

  VAR
    label : Text;

  BEGIN
    text.SetParent(l);
    object.SetParent(l);

    NEW(label);
    label.next:=NIL;
    label.object:=object;
    label.text:=text;

    IF l.labelList=NIL THEN
      l.labelList:=label;
    ELSE
      l.lLast.next:=label;
    END;
    l.lLast:=label;

    INC(l.count);

    object.SetLabelObject(text);
  END AddLabel;

  PROCEDURE (l : Label) AddStringLabel*(string : STRING; object : G.Object);

    (**
      Add a textual label entry. The label object will generate a text object out of
      the given string and will then assign it as label object to the other object
      by calling @oproc{Label.AddLabel}.
    *)

  VAR
    text : T.Text;

  BEGIN
    text:=T.MakeLeftString(string);
    l.AddLabel(text,object);
  END AddStringLabel;

  PROCEDURE ( l : Label) Set*(labelFlex : BOOLEAN);

    (**
      Tell, if the label object should stretch the label or the object when
      beeing resized horizontally.
    *)

  BEGIN
    l.labelFlex:=labelFlex;
  END Set;

  PROCEDURE (l : Label) CalcSize*;

  VAR
    label     : Text;
    rMinWidth : LONGINT;
    visitor   : RealignVisitorDesc;

  BEGIN
    l.height:=0;
    l.minHeight:=0;
    l.lSize:=0;
    l.rSize:=0;
    rMinWidth:=0;

    label:=l.labelList;
    WHILE (label#NIL) DO

      label.object.CalcSize;
      label.text.CalcSize;

      l.lSize:=U.MaxLong(label.text.width,l.lSize);
      l.rSize:=U.MaxLong(l.rSize,label.object.oWidth);
      rMinWidth:=U.MaxLong(rMinWidth,label.object.oMinWidth);

      INC(l.height,U.MaxLong(label.object.oHeight,label.text.oHeight));
      INC(l.minHeight,U.MaxLong(label.object.oMinHeight,label.text.oMinHeight));

      label:=label.next;
    END;

    IF l.count>1 THEN
      INC(l.height,(l.count-1)*l.prefs(Prefs).vSpace.GetSize());
      INC(l.minHeight,(l.count-1)*l.prefs(Prefs).vSpace.GetSize());
    END;

    l.width:=l.lSize+l.prefs(Prefs).hSpace.GetSize()+l.rSize;
    l.minWidth:=l.lSize+l.prefs(Prefs).hSpace.GetSize()+rMinWidth;

    l.CalcSize^;

    IF l.labelFlex THEN
      l.lSize:=l.width-l.rSize-l.prefs(Prefs).hSpace.GetSize();
    ELSE
      l.rSize:=l.width-l.lSize-l.prefs(Prefs).hSpace.GetSize();
    END;
(*
    IF (l.parent#NIL) & (l.parent IS P.Panel) THEN (* if we are in a panel*)
      (*
        Now we use a visitor to walk over all children of our parent (all
        objects in the same parent panel). If CalcSize was already called for
        them, we resize them to the smae lSize and rSize values and relayout them.

        See Label.ReLayout And local visitor implementation.
      *)
      visitor.me:=l;
      IF l.parent.VisitChildren(visitor,TRUE) THEN
      END;
    END;*)
  END CalcSize;

  PROCEDURE (l : Label) ReLayout(li,re : LONGINT);

  BEGIN
    l.lSize:=li;
    l.rSize:=re;
    l.width:=l.lSize+l.prefs(Prefs).hSpace.GetSize()+l.rSize;

    l.CalcSize;
  END ReLayout;

  PROCEDURE (l : Label) Layout*;

  VAR
    label     : Text;
    pos,
    curHeight,
    old,
    count     : LONGINT;

  BEGIN
    IF l.labelFlex THEN
      l.lSize:=l.width-l.rSize-l.prefs(Prefs).hSpace.GetSize();
    ELSE
      l.rSize:=l.width-l.lSize-l.prefs(Prefs).hSpace.GetSize();
    END;

    curHeight:=0;
    label:=l.labelList;
    WHILE (label#NIL) DO
      IF label.object.oHeight<label.text.oHeight THEN
        label.object.Resize(-1,label.text.oHeight);
        INC(curHeight,label.text.oHeight);
      ELSIF label.object.oHeight>label.text.oHeight THEN
        label.text.Resize(-1,label.object.oHeight);
        INC(curHeight,label.object.oHeight);
      ELSE
        INC(curHeight,label.object.oHeight);
      END;
      label.text.Resize(l.lSize,-1);
      label.object.Resize(l.rSize,-1);
      label:=label.next;
    END;

    IF l.count>1 THEN
      INC(curHeight,(l.count-1)*l.prefs(Prefs).vSpace.GetSize());
    END;

    IF curHeight#l.height THEN
      LOOP
        count:=0;
        label:=l.labelList;
        WHILE label#NIL DO
          IF label.object.CanResize(l.height>curHeight,FALSE) THEN
            INC(count);
          END;
          label:=label.next;
        END;

        IF count=0 THEN
          EXIT;
        END;

        label:=l.labelList;
        WHILE label#NIL DO
          IF label.object.CanResize(l.height>curHeight,FALSE) THEN
            old:=label.object.oHeight;
            label.object.Resize(-1,label.object.oHeight+U.UpDiv(l.height-curHeight,count));
            label.text.Resize(-1,label.object.oHeight);
            INC(curHeight,label.object.oHeight-old);
            DEC(count);
          END;
          label:=label.next;
        END;

        IF curHeight=l.height THEN
          EXIT;
        END;
      END;
    END;

    (* Draw all objects *)

    label:=l.labelList;
    pos:=l.y;
    WHILE (label#NIL) DO

      IF l.prefs(Prefs).labelPos=right THEN
        IF l.prefs(Prefs).objectAlign=left THEN
          label.object.Move(l.x,pos);
        ELSE
          label.object.Move(l.x+l.rSize-label.object.oWidth,pos);
        END;
        IF l.prefs(Prefs).labelAlign=right THEN
          label.text.Move(l.x+l.rSize+l.prefs(Prefs).hSpace.GetSize()+l.lSize-label.text.oWidth,
                          pos+label.object.oHeight-label.text.oHeight);
        ELSE
          label.text.Move(l.x+l.rSize+l.prefs(Prefs).hSpace.GetSize(),
                          pos+label.object.oHeight-label.text.oHeight);
        END;
      ELSE
        IF l.prefs(Prefs).objectAlign=left THEN
          label.object.Move(l.x+l.lSize+l.prefs(Prefs).hSpace.GetSize(),pos);
        ELSE
          label.object.Move(l.x+l.lSize+l.prefs(Prefs).hSpace.GetSize()+l.rSize-label.object.oWidth,pos);
        END;
        IF l.prefs(Prefs).labelAlign=right THEN
          label.text.Move(l.x+l.lSize-label.text.oWidth,
                          pos+label.object.oHeight-label.text.oHeight);
        ELSE
          label.text.Move(l.x,pos+label.object.oHeight-label.text.oHeight);
        END;
      END;

      IF label.object.oHeight>label.text.height THEN
        INC(pos,label.object.oHeight);
      ELSE
        INC(pos,label.text.height);
      END;

      INC(pos,l.prefs(Prefs).vSpace.GetSize());

      label:=label.next;
    END;

    l.Layout^;
  END Layout;

  PROCEDURE (VAR v : RealignVisitorDesc) Visit*(object : G.Object):BOOLEAN;

  BEGIN
    WITH object : Label DO
      IF (object#v.me) & (object.parent=v.me.parent) & (G.inited IN object.flags) THEN
        object.ReLayout(v.me.lSize,v.me.rSize);
      END;
    ELSE
    END;

    RETURN TRUE;
  END Visit;

  PROCEDURE CreateLabel*():Label;

    (**
      Creates a new instance of @otype{Label}.
    *)

  VAR
    label : Label;

  BEGIN
    NEW(label);
    label.Init;

    RETURN label;
  END CreateLabel;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Label.