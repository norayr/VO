MODULE VO:Tree;

  (**
    Implements @otype{Tree}.
  *)

  (*
    A tree object displaying simple tree-like data.
    Copyright (C) 1998 Tim Teulings (rael@edge.ping.de)

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

IMPORT BG   := VO:Base:Background,
       D    := VO:Base:Display,
       E    := VO:Base:Event,
       F    := VO:Base:Frame,
       O    := VO:Base:Object,
       U    := VO:Base:Util,

       TM   := VO:Model:Tree,

       G    := VO:Object;

CONST
  selectedMsg* = 0;

TYPE
  Prefs*     = POINTER TO PrefsDesc;

  (**
    In this class all preferences stuff of the button is stored.
  **)

  PrefsDesc* = RECORD (G.PrefsDesc)
                 focusFrame* : F.Frame;
                 selection*  : G.Background;
               END;

  Tree*     = POINTER TO TreeDesc;
  TreeDesc* = RECORD (G.ScrollableGadgetDesc)
                (**
                  A tree object displaying simple tree-like data.
                *)
                font         : D.Font;

                focFrame     : F.Frame;

                model-       : TM.TreeModel;
                selected-    : TM.TreeItem;
                selectedPos  : LONGINT;

                colHeight    : LONGINT;
               END;

  SelectedMsg*      = POINTER TO SelectedMsgDesc;
  SelectedMsgDesc*  = RECORD (O.MessageDesc)
                        item* : TM.TreeItem;
                      END;

VAR
  prefs* : Prefs;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.tableBackgroundColorIndex));
    p.selection:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.fillColorIndex));
    p.focusFrame:=F.CreateFrame(F.dottedFocus);
  END Initialize;

  PROCEDURE (t : Tree) Init*;

  BEGIN
    t.Init^;

    t.SetPrefs(prefs);

    t.SetFlags({G.canFocus}); (* We can show a focus frame *)
    t.RemoveFlags({G.stdFocus}); (* we do the displaying of the focus frame ourself *)

(*    t.SetObjectFrame(F.double3DIn);*)

    t.focFrame:=t.prefs(Prefs).focusFrame;

    t.model:=NIL;
    t.selected:=NIL;
    t.selectedPos:=-1;
  END Init;

  PROCEDURE (t : Tree) CalcSize*;

  BEGIN
    t.font:=D.normalFont;

    t.width:=10*D.display.spaceWidth;
    t.height:=10*D.display.spaceHeight;

    t.minWidth:=t.width;
    t.minHeight:=t.height;

    t.colHeight:=t.font.height+D.display.spaceHeight DIV 2;

    t.CalcSize^;
  END CalcSize;

  PROCEDURE (t : Tree) GetClickedEntryPos(y : LONGINT):LONGINT;

  VAR
    pos : LONGINT;

  BEGIN
    IF t.model=NIL THEN
      RETURN -1;
    END;

    pos:=(y-t.y) DIV t.colHeight;
    IF (y-t.y) MOD t.colHeight>0 THEN
      INC(pos);
    END;

    INC(pos,t.vAdjustment.GetTop()-1);

    IF (pos>=1) & (pos<=t.model.visible) THEN
      RETURN pos;
    ELSE
      RETURN -1;
    END;
  END GetClickedEntryPos;

  PROCEDURE (t : Tree) MakeVisible(y : LONGINT);

  BEGIN
    IF y<t.vAdjustment.GetTop() THEN
      t.vAdjustment.SetTop(y);
    ELSIF y>t.vAdjustment.GetTop()+t.vAdjustment.GetVisible()-1 THEN
      t.vAdjustment.SetTop(U.MaxLong(1,y-t.vAdjustment.GetVisible()));
    END;
  END MakeVisible;

  PROCEDURE (t : Tree) DrawItem(item : TM.TreeItem; VAR y : LONGINT;
                                offset : LONGINT; goUp : BOOLEAN;
                                draw : D.DrawInfo);

  VAR
    string   : STRING;
    extent   : D.FontExtentDesc;
    x,yPos,
    byPos    : LONGINT;

  BEGIN
    WHILE (item#NIL) & (y<=t.height) DO

      string:=item.GetString();
      IF string#NIL THEN
        t.font.StrExtent(string,{},extent);
        x:=t.x+offset*3*D.display.spaceWidth;
        yPos:=t.y+y;
        byPos:=yPos+(t.colHeight-t.font.height) DIV 2;
        IF item.HasChildren() THEN
          draw.PushForeground(D.tableTextColor);
          draw.DrawLine(x,byPos,x+2*D.display.spaceWidth,byPos);
          draw.DrawLine(x+2*D.display.spaceWidth,byPos,
                        x+2*D.display.spaceWidth,byPos+t.font.height-1);
          draw.DrawLine(x+2*D.display.spaceWidth,byPos+t.font.height-1,
                        x,byPos+t.font.height-1);
          draw.DrawLine(x,byPos+t.font.height-1,x,byPos);

          draw.DrawLine(x+D.display.spaceWidth DIV 2,byPos+t.font.height DIV 2,
                        x+2*D.display.spaceWidth-D.display.spaceWidth DIV 2,
                        byPos+t.font.height DIV 2);
          IF ~item.shown THEN
            draw.DrawLine(x+D.display.spaceWidth,byPos+t.font.height DIV 4,
                          x+D.display.spaceWidth,byPos+t.font.height-t.font.height DIV 4-1);
          END;

          draw.PopForeground;
        END;
        IF item=t.selected THEN
          t.selectedPos:=t.vAdjustment.GetTop()+y DIV t.colHeight;
          t.prefs(Prefs).selection.DrawRelObject(draw,t,
                                                 x+3*D.display.spaceWidth,
                                                 yPos+(t.colHeight-t.font.height) DIV 2,
                                                 extent.width,t.font.height);
          IF t.HasFocus() THEN
            t.focFrame.Draw(draw,
                            x+3*D.display.spaceWidth,
                            yPos+(t.colHeight-t.font.height) DIV 2,
                            extent.width,t.font.height);
          END;

          draw.PushForeground(D.fillTextColor);
        ELSE
          draw.PushForeground(D.tableTextColor);
        END;
        draw.PushFont(D.normalFont,{});
        draw.DrawStr(x-extent.lbearing+3*D.display.spaceWidth,
                     yPos+t.font.ascent+(t.colHeight-t.font.height) DIV 2,
                     string);
        draw.PopFont;
        draw.PopForeground;
      END;

      IF item.HasChildren() & item.shown THEN
        INC(y,t.colHeight);
        t.DrawItem(item.firstChild,y,offset+1,FALSE,draw);
      ELSE
        INC(y,t.colHeight);
      END;

      IF goUp THEN
        WHILE (item#NIL) & (item.next=NIL) DO
          item:=item.parent;
          DEC(offset);
        END;
        IF item#NIL THEN
          item:=item.next;
        END;
      ELSE
        item:=item.next;
      END;
    END;
  END DrawItem;

  PROCEDURE (t : Tree) DrawTree;

  VAR
    yPos,
    offset : LONGINT;
    top    : TM.TreeItem;
    draw   : D.DrawInfo;

  BEGIN
    draw:=t.GetDrawInfo();

    t.selectedPos:=-1;

    t.DrawBackground(t.x,t.y,t.width,t.height);

    IF (t.model#NIL) & (t.model.top#NIL) THEN

      IF t.vAdjustment.GetTop()+t.height DIV t.colHeight-1>t.model.visible THEN
        t.vAdjustment.SetDimension(t.model.visible-t.vAdjustment.GetTop()+1,t.model.visible);
      ELSE
        t.vAdjustment.SetDimension(U.MinLong(t.height DIV t.colHeight,t.model.visible),t.model.visible);
      END;

      draw.InstallClip(t.x,t.y,t.width,t.height);
      yPos:=0;
      top:=t.model.GetVisibleItem(t.vAdjustment.GetTop(),offset);
      t.DrawItem(top,yPos,offset,TRUE,draw);
      draw.FreeLastClip;
    ELSE
      t.vAdjustment.SetDimension(0,0);
    END;
  END DrawTree;

  PROCEDURE (t : Tree) HandleClick(event : E.MouseEvent);

  VAR
    pos,offset : LONGINT;
    item       : TM.TreeItem;
    selected   : SelectedMsg;

  BEGIN
    pos:=t.GetClickedEntryPos(event.y);
    IF pos>0 THEN
      item:=t.model.GetVisibleItem(pos,offset);

      IF (event.x>=t.x+offset*3*D.display.spaceWidth)
       & (event.x<=t.x+offset*3*D.display.spaceWidth+2*D.display.spaceWidth) THEN
        IF item.childs>0 THEN
          IF item.shown THEN
            item.HideChildren;
          ELSE
            item.ShowChildren;
          END;
        END;
      ELSIF (event.x>t.x+offset*3*D.display.spaceWidth+2*D.display.spaceWidth)
          & (event.x<t.x+t.width) THEN
        IF item#t.selected THEN
          t.selected:=item;
          NEW(selected);
          selected.item:=t.selected;
          t.Send(selected,selectedMsg);

          t.DrawTree;
        END;
      END;
    END;
  END HandleClick;

  PROCEDURE (t : Tree) HandleMouseEvent*(event : E.MouseEvent;
                                         VAR grab : G.Object):BOOLEAN;

  BEGIN
    IF ~t.visible OR t.disabled OR (t.model=NIL) THEN
      RETURN FALSE;
    END;

    WITH event : E.ButtonEvent DO
      IF (event.type=E.mouseDown) & t.PointIsIn(event.x,event.y)
      & (event.button=E.button1) THEN
        t.HandleClick(event);

        grab:=t;
        RETURN TRUE;
      ELSIF (event.button=E.button1) & (event.type=E.mouseUp) THEN

        grab:=NIL;
        RETURN TRUE;
      END;
    ELSE
    END;

    RETURN FALSE;
  END HandleMouseEvent;

  PROCEDURE (t : Tree) HandleKeys(event :  E.KeyEvent):BOOLEAN;

  VAR
    item     : TM.TreeItem;
    oldPos   : LONGINT;
    selected : SelectedMsg;

  BEGIN
    CASE event.key OF
      E.left:
        IF t.selected#NIL THEN
          IF t.selected.HasChildren() & t.selected.shown THEN
            t.selected.HideChildren;
          END;
        END;
    | E.right:
        IF t.selected#NIL THEN
          IF t.selected.HasChildren() & ~t.selected.shown THEN
            t.selected.ShowChildren;
          END;
        END;
    | E.up:
        IF t.selected#NIL THEN
          oldPos:=t.selectedPos;
          item:=t.selected.Last();
          IF (item#NIL) & (item#t.selected) THEN
            t.selected:=item;
            NEW(selected);
            selected.item:=t.selected;
            t.Send(selected,selectedMsg);

            t.DrawTree;
            IF oldPos>0 THEN
              t.MakeVisible(oldPos-1);
            END;
          END;
        END;
    | E.down:
        IF t.selected#NIL THEN
          oldPos:=t.selectedPos;
          item:=t.selected.Next();
          IF (item#NIL) & (item#t.selected) THEN
            t.selected:=item;
            NEW(selected);
            selected.item:=t.selected;
            t.Send(selected,selectedMsg);

            t.DrawTree;
            IF oldPos>0 THEN
              t.MakeVisible(oldPos+1);
            END;
          END;
        END;
    | E.home:
    | E.end:
    ELSE
      RETURN FALSE;
    END;
    RETURN TRUE;
  END HandleKeys;

  PROCEDURE (t : Tree) HandleKeyEvent*(event : E.KeyEvent):BOOLEAN;

  BEGIN
    IF event.type=E.keyDown THEN
      RETURN t.HandleKeys(event);
    ELSE
      RETURN FALSE;
    END;
  END HandleKeyEvent;

  PROCEDURE (t : Tree) ReInit;

  BEGIN
    t.hAdjustment.SetTop(1);
    t.vAdjustment.SetTop(1);

    IF t.visible THEN
      t.DrawTree;
    END;
  END ReInit;

  PROCEDURE (t : Tree) SetModel*(model : O.Model);

  BEGIN
    IF t.model#NIL THEN
      t.UnattachModel(t.model);
    END;

    t.selected:=NIL;
    IF (model#NIL) & (model IS TM.TreeModel) THEN
      t.model:=model(TM.TreeModel);
      t.AttachModel(t.model);
      t.ReInit;
    ELSE
      t.model:=NIL;
    END;
  END SetModel;

  (**
    This function is used to check if an argument to SetModel
    was successfully accepted.
   **)

  PROCEDURE (t : Tree) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=t.model
  END ModelAccepted;


  PROCEDURE (t : Tree) Draw*(x,y,w,h : LONGINT);

  BEGIN
    IF ~t.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    t.Draw^(x,y,w,h);

    t.DrawTree;
  END Draw;

  (**
    Draw the keyboard focus.
  **)

  PROCEDURE (t : Tree) DrawFocus*;

  BEGIN
    t.DrawTree;
  END DrawFocus;

  (**
    Hide the keyboard focus.
  **)

  PROCEDURE (t : Tree) HideFocus*;

  BEGIN
    t.DrawTree;
  END HideFocus;

  PROCEDURE (t : Tree) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF model=t.model THEN
      IF msg#NIL THEN
        WITH msg : TM.ItemSwitchedMsg DO
          IF t.selected#NIL THEN
            t.selected:=t.selected.VisibleParent();
          END;
          IF t.vAdjustment.GetTop()>t.model.visible THEN
            t.vAdjustment.SetTop(t.model.visible);
          ELSE
            t.DrawTree;
          END;
        ELSE
          t.ReInit;
        END;
      ELSE
        t.ReInit;
      END;
    ELSIF t.visible THEN
      t.DrawTree;
    END;
  END Resync;

  PROCEDURE CreateTree*():Tree;

  VAR
    tree : Tree;

  BEGIN
    NEW(tree);
    tree.Init;

    RETURN tree;
  END CreateTree;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Tree.