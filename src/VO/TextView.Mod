(**
   A gadget, that displays text offered by a derived class from TextViewModel.
**)

MODULE VO:TextView;

(*
    Implements a textviewer gadget based on the text model.

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

IMPORT D   := VO:Base:Display,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,

       TM  := VO:Model:TextView,
       V   := VO:Model:Value,

       G   := VO:Object;


TYPE
  TextView*     = POINTER TO TextViewDesc;
  TextViewDesc* = RECORD (G.ScrollableGadgetDesc)
                    model   : TM.TextModel;
                    top     : TM.Reader;
                    vis-,
                    topPos- : V.ValueModel;
                    font    : D.Font;
                  END;

  PROCEDURE (t : TextView) Init*;

  BEGIN
    t.Init^;

    t.model:=NIL;
    t.top:=NIL;

    t.topPos:=t.vAdjustment.GetTopModel();
    t.vis:=t.vAdjustment.GetVisibleModel();

    t.SetObjectFrame(F.CreateFrame(F.none));
  END Init;

  PROCEDURE (t : TextView) SetModel*(model : O.Model);

  BEGIN
    IF t.model#NIL THEN
      t.UnattachModel(t.model);
    END;

    IF (model#NIL) & (model IS TM.TextModel) THEN
      t.model:=model(TM.TextModel);

      t.top:=t.model.GetReader();
      ASSERT(t.top#NIL);

(*    t.top:=model.Get(1);
    t.topPos.Set(1);*)
      t.AttachModel(t.model);
    ELSE
      t.model:=NIL;
    END;
  END SetModel;

  (**
    This function is used to check if an argument to SetModel
    was successfully accepted.
   **)

  PROCEDURE (t : TextView) ModelAccepted * (m : O.Model):BOOLEAN;

  BEGIN
    RETURN m=t.model
  END ModelAccepted;

  PROCEDURE (t : TextView) CalcSize*;

  VAR
    width : LONGINT;

  BEGIN
    t.font:=D.fixedFont;

    width:=t.font.TextWidth("X",1,{});

    t.width:=3*width;
    t.height:=3*t.font.height;

    t.minWidth:=t.width;
    t.minHeight:=t.height;

    t.CalcSize^;
  END CalcSize;

  PROCEDURE (t : TextView) Draw*(x,y,w,h : LONGINT);

  VAR
    reader     : TM.Reader;
    line       : TM.LineDesc;
    lines,
    width,i,
    xPos,yPos  : LONGINT;
    draw       : D.DrawInfo;

  BEGIN
    IF ~t.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    t.Draw^(x,y,w,h);

    draw:=t.GetDrawInfo();

    lines:=t.height DIV t.font.height;
    xPos:=t.x;
    yPos:=t.y;

    IF t.model#NIL THEN
      t.vAdjustment.Set(t.top.pos,lines,t.model.lines);

      draw.InstallClip(t.x,t.y,t.width,t.height);

      reader:=t.model.GetReader();
      reader.Assign(t.top);

      IF reader.IsValid() THEN
        IF lines>t.model.lines-t.top.pos+1 THEN
          lines:=t.model.lines-t.top.pos+1;
        END;

        draw.PushFont(D.fixedFont,{});
        draw.PushForeground(D.blackColor);
        draw.PushBackground(D.whiteColor);

        FOR i:=1 TO lines DO

          reader.GetLine(line);

          IF line.chars#NIL THEN
            width:=t.font.StrWidth(line.chars,{});
            draw.DrawFillStr(xPos,yPos+t.font.ascent,line.chars);
          ELSE
            width:=0;
          END;
          IF width<t.width THEN
            draw.PushForeground(D.whiteColor);
            draw.FillRectangle(xPos+width,yPos,t.width-width,t.font.height);
            draw.PopForeground;
          END;

          reader.Next;

          INC(yPos,t.font.height);
        END;

        draw.PopBackground;
        draw.PopForeground;
        draw.PopFont;
      END;

      IF yPos<t.y+t.height THEN
        draw.PushForeground(D.whiteColor);
        draw.FillRectangle(xPos,yPos,t.width,t.y+t.height-yPos);
        draw.PopForeground;
      END;

      draw.FreeLastClip;

    ELSE
      t.vAdjustment.SetInvalid;
    END;
  END Draw;

  PROCEDURE (t : TextView) Resync*(model : O.Model; msg : O.ResyncMsg);

  BEGIN
    IF model=t.model THEN
      IF msg#NIL THEN
        WITH msg : O.Notify DO
          CASE msg.notify OF
            TM.resyncMsg:
              t.top:=t.model.GetReader();
              t.Redraw;
          | TM.resizeMsg:
              t.Redraw;
          ELSE
          END;
        ELSE
          t.Redraw;
        END;
      END;
    ELSIF model=t.topPos THEN
      IF t.model#NIL THEN
        t.top.Position(t.topPos.GetLongint());
        t.Redraw;
      END;
    END;
  END Resync;

  PROCEDURE (t : TextView) ShowBottom*;

  BEGIN
    IF t.model#NIL THEN
      IF t.topPos.GetLongint()+t.vis.GetLongint()<=t.model.lines THEN
        t.topPos.SetLongint(t.model.lines-t.vis.GetLongint()+1);
      END;
    END;
  END ShowBottom;

  PROCEDURE CreateTextView*():TextView;

    (**
      Creates a new instance of @otype{TextView}.
    *)

  VAR
    textView : TextView;

  BEGIN
    NEW(textView);
    textView.Init;

    RETURN textView;
  END CreateTextView;

END VO:TextView.