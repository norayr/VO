(**
  A model for nummerical data as a result of a multi-dimensional function
  y=f(x_i), fir 0<= i < infinity, and y a scalar value.
**)

(*
    A model for nummerical data as a result of a multi-dimensional function.
    Copyright (C) 1998  Tim Teulings (rael@edge.ping.de)

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

MODULE VO:Model:Function;

IMPORT O   := VO:Base:Object,
       U   := VO:Base:Util,

       str := Strings;

TYPE
  FunctionLRealModel*     = POINTER TO FunctionLRealModelDesc;
  FunctionLRealModelDesc* = RECORD (O.ModelDesc)
                              descr- : U.Text;
                            END;

  Label*     = POINTER TO LabelDesc;
  LabelDesc* = RECORD (O.ResyncMsgDesc)
               END;

VAR
  label : Label;

  PROCEDURE (f : FunctionLRealModel) SetValue*(dim : LONGINT; value : LONGREAL);

    (**
      Assigns a new value for x_i to the model.
    *)

  BEGIN
  END SetValue;

  PROCEDURE (f : FunctionLRealModel) SetDescribtion*(descr : ARRAY OF CHAR);

    (**
      Assign a describtion for the function to the model. A viewer can use
      this describtion. He will get a Label msg, if the label changes.
    *)

  BEGIN
    NEW(f.descr,str.Length(descr)+1);
    COPY(descr,f.descr^);

    f.Notify(label);
  END SetDescribtion;

  PROCEDURE (f : FunctionLRealModel) Dimension*():LONGINT;

    (**
      Returns the dimension of the function, that is i.
    *)

  BEGIN
    RETURN 0;
  END Dimension;

  PROCEDURE (f : FunctionLRealModel) Execute*():LONGREAL;

    (**
      Executes the function with the current values of x_i.
    *)

  BEGIN
    RETURN 0;
  END Execute;

  PROCEDURE (f : FunctionLRealModel) NotifyFunctionChange*;

    (**
      Notifies all viewers, that the function has changed. As a result,
      all viewers should reassign all x_i and recalculate the function.

      NOTE
      For speed, no special notification object will be created.
    *)

  BEGIN
    f.Notify(NIL);
  END NotifyFunctionChange;

BEGIN
  NEW(label);
END VO:Model:Function.