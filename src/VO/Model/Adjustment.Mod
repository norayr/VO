MODULE VO:Model:Adjustment;

(*

    Copyright (C) 2001  Tim Teulings (rael@edge.ping.de)

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

IMPORT O  := VO:Base:Object,
       U  := VO:Base:Util,

       VM := VO:Model:Value;

TYPE
  (**
    New implementation uses Adjustment as a model
    which contains top, visible and total entries.
   **)

  Adjustment *  = POINTER TO AdjustmentDesc;
  AdjustmentDesc * = RECORD (O.ModelDesc)
                    top,
                    visible,
                    total    : VM.ValueModel;
                  END;

  (* -------------------------------------------- *)

  (**
    Init Adjustment-Model.
    post: top, visible and total have the value 1.
      a.top, a.visible and a.total are never set back to NIL.
   **)
  PROCEDURE (a : Adjustment) Init*;
  BEGIN
    a.Init^;
    NEW(a.top);
    a.top.Init;
    a.top.SetLongint(1);
    NEW(a.visible);
    a.visible.Init;
    a.visible.SetLongint(0);
    NEW(a.total);
    a.total.Init;
    a.total.SetLongint(0);
  END Init;

  (**
    As it is impossible to ensure that the relation between
    top, visible and total is not invalidated, this procedure
    provides a simple check.
    post: 0<top<=total and 0<visible OR result is FALSE.
   **)
  PROCEDURE (a : Adjustment) IsValid*():BOOLEAN;
  BEGIN
    RETURN ~ ( a.top.IsNull() OR a.visible.IsNull() OR a.total.IsNull()
            OR (a.visible.GetLongint()<0)
            OR (a.visible.GetLongint()>a.total.GetLongint())
            OR (a.top.GetLongint()<1)
       (*     OR (a.top.GetLongint()+a.visible.GetLongint()
                  #a.total.GetLongint())*) )
  END IsValid;

  PROCEDURE (a : Adjustment) GetTop*():LONGINT;
  BEGIN
    IF ~a.top.IsNull() THEN
      RETURN a.top.GetLongint()
    ELSE
      RETURN -1;
    END;
  END GetTop;

  PROCEDURE (a : Adjustment) GetBottom*():LONGINT;
  BEGIN
    IF ~a.top.IsNull() & ~a.visible.IsNull() THEN
      RETURN a.top.GetLongint()+a.visible.GetLongint()-1;
    ELSE
      RETURN -1;
    END;
  END GetBottom;

  PROCEDURE (a : Adjustment) GetVisible*():LONGINT;
  BEGIN
    IF ~a.visible.IsNull() THEN
      RETURN a.visible.GetLongint()
    ELSE
      RETURN -1;
    END;
  END GetVisible;

  PROCEDURE (a : Adjustment) GetTotal*():LONGINT;
  BEGIN
    IF ~a.total.IsNull() THEN
      RETURN a.total.GetLongint()
    ELSE
      RETURN -1;
    END;
  END GetTotal;

  (**
    Set a new value for top, visible and total.
    post: if visible>=1 then new value is accepted.
    post: top will be corrected to fit visible and total
   **)
  PROCEDURE (a : Adjustment) Set*(top,visible,total : LONGINT);

  BEGIN
    IF (visible>0) & (total>0) THEN
      IF visible>total THEN
        visible:=total;
      END;

      IF visible=total THEN
        top:=1;
      END;

      IF top+visible>total THEN
        top:=total-visible+1;
      END;

      a.total.SetLongint(total);
      a.visible.SetLongint(visible);
      a.top.SetLongint(top);
    END;
  END Set;

  (**
    Invalidate values.
   **)
  PROCEDURE (a : Adjustment) SetInvalid*;

  BEGIN
    a.top.SetNull;
    a.visible.SetNull;
    a.total.SetNull;
  END SetInvalid;

  (**
    Set a new value for top.
    post: if top>=1 & top<=total then new value is accepted.
   **)
  PROCEDURE (a : Adjustment) SetTop* (top:LONGINT);
  BEGIN
    IF (top>=1) & (top<=a.total.GetLongint()) THEN
      a.top.SetLongint( top );
    END;
  END SetTop;

  (**
    Set a new value for visible and total.
    post: if visible>=1 then new value is accepted.
    post: top will be corrected to fit visible and total
   **)
  PROCEDURE (a : Adjustment) SetDimension* (visible,total : LONGINT);

  VAR
    top : LONGINT;

  BEGIN
    IF (visible>0) & (total>0) THEN
      IF a.IsValid() THEN
        top:=a.GetTop();
      ELSE
        top:=1;
      END;

      IF visible>total THEN
        visible:=total;
      END;

      IF visible=total THEN
        top:=1;
      END;

      IF top+visible>total THEN
        top:=total-visible+1;
      END;

      a.total.SetLongint(total);
      a.visible.SetLongint(visible);
      a.top.SetLongint(top);
    END;
  END SetDimension;

  PROCEDURE (a : Adjustment) SetTopModel* (top:VM.ValueModel);
  BEGIN
    IF top#NIL THEN
      a.top:=top;
      a.Notify(NIL);
    END;
  END SetTopModel;

  PROCEDURE (a : Adjustment) SetVisibleModel* (visible:VM.ValueModel);
  BEGIN
    IF visible#NIL THEN
      a.visible:=visible;
      a.Notify(NIL);
    END;
  END SetVisibleModel;

  PROCEDURE (a : Adjustment) SetTotalModel* (total:VM.ValueModel);
  BEGIN
    IF total#NIL THEN
      a.total:=total;
      a.Notify(NIL);
    END;
  END SetTotalModel;

  PROCEDURE (a : Adjustment) GetTopModel* ():VM.ValueModel;
  BEGIN
    RETURN a.top
  END GetTopModel;

  PROCEDURE (a : Adjustment) GetVisibleModel* ():VM.ValueModel;
  BEGIN
    RETURN a.visible
  END GetVisibleModel;

  PROCEDURE (a : Adjustment) GetTotalModel* ():VM.ValueModel;
  BEGIN
    RETURN a.total
  END GetTotalModel;

  PROCEDURE (a : Adjustment) IncTop*;
  BEGIN
    IF a.IsValid() THEN
      IF a.total.GetInteger()-a.visible.GetInteger()>=a.top.GetInteger() THEN
        a.top.Inc;
      END;
    END;
  END IncTop;

  PROCEDURE (a : Adjustment) DecTop*;
  BEGIN
    IF a.IsValid() THEN
      IF 1<a.top.GetInteger() THEN
        a.top.Dec;
      END;
    END;
  END DecTop;

  PROCEDURE (a : Adjustment) PageBack*;
  BEGIN
    IF a.IsValid() THEN
      IF a.top.GetLongint()>a.visible.GetLongint() THEN
        a.top.Sub(a.visible.GetLongint());
      ELSE
        a.top.SetLongint(1);
      END;
    END;
  END PageBack;

  PROCEDURE (a : Adjustment) PageForward*;
  BEGIN
    IF a.IsValid() THEN
      IF a.top.GetLongint()+a.visible.GetLongint()<a.total.GetLongint()-a.visible.GetLongint()+1 THEN
        a.top.Add(a.visible.GetLongint());
      ELSE
        a.top.SetLongint(a.total.GetLongint()-a.visible.GetLongint()+1);
      END;
    END;
  END PageForward;

  PROCEDURE (a : Adjustment) MakeVisible*(pos : LONGINT);

  BEGIN
    IF (pos>=1) & (pos<=a.total.GetLongint()) THEN
      IF pos<a.top.GetLongint() THEN
        a.top.SetLongint(pos);
      ELSIF pos>a.top.GetLongint()+a.visible.GetLongint()-1 THEN
        a.top.SetLongint(U.MaxLong(1,pos-a.visible.GetLongint()+1));
      END;
    END;
  END MakeVisible;

  PROCEDURE CreateAdjustment*():Adjustment;

  VAR
    adjustment : Adjustment;

  BEGIN
    NEW(adjustment);
    adjustment.Init;

    RETURN adjustment;
  END CreateAdjustment;

END VO:Model:Adjustment.