(**
   A model for all basic datatypes.
**)

MODULE VO:Model:Value;

(*
    A model for all basic datatypes.
    Copyright (C) 1999  Tim Teulings (rael@edge.ping.de)

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

IMPORT O   := VO:Base:Object,
       U   := VO:Base:Util,

       co  := IntStr,
       lco := LRealConv,
       ls  := LRealStr,
       rco := RealConv,
       rs  := RealStr,
              Object;

CONST
  (*
     datatypes of value stored in model

     TODO: support more datatypes
  *)

  unknown*           =  0;
  char*              =  1;
  text*              =  2;
  real*              =  3;
  longreal*          =  4;
  shortint*          =  5;
  integer*           =  6;
  longint*           =  7;
  boolean*           =  8;

TYPE
  Value*             = POINTER TO ValueDesc;
  ValueDesc*         = RECORD
                         string   : STRING;
                         longint  : LONGINT;
                         real     : REAL;
                         longreal : LONGREAL;
                         char     : UCS4CHAR;
                         boolean  : BOOLEAN;
                         isNull   : BOOLEAN;
                         last     : Value;
                       END;

  ValueModel*        = POINTER TO ValueModelDesc;
  ValueModelDesc*    = RECORD (O.ModelDesc)
                         type-    : LONGINT;
                         value    : ValueDesc;
                       END;

  BoolModel*         = POINTER TO BoolModelDesc;
  BoolModelDesc*     = RECORD (ValueModelDesc)
                       END;

  IntModel*          = POINTER TO IntModelDesc;
  IntModelDesc*      = RECORD (ValueModelDesc)
                       END;

  LongRealModel*     = POINTER TO LongRealModelDesc;
  LongRealModelDesc* = RECORD (ValueModelDesc)
                       END;

  StringModel*       = POINTER TO StringModelDesc;
  StringModelDesc*   = RECORD (ValueModelDesc)
                       END;

  (* --- Value object --- *)

  PROCEDURE (VAR v : ValueDesc) Equal*(value : Value; type : LONGINT):BOOLEAN;

  BEGIN
    IF v.isNull OR value.isNull THEN
      RETURN v.isNull & value.isNull;
    END;

    CASE type OF
      unknown:
      RETURN TRUE;
    | char:
      RETURN value.char=v.char;
    | text:
      RETURN value.string.Equals(v.string);
    | real:
      RETURN value.real=v.real;
    | longreal:
      RETURN value.longreal=v.longreal;
    | shortint,
      integer,
      longint:
      RETURN value.longint=v.longint;
    | boolean:
      RETURN value.boolean=v.boolean;
    END;
  END Equal;

  (**
    Initialize object to type unknown.
  **)

  PROCEDURE (v : ValueModel) Init*;

  BEGIN
    v.Init^;

    v.type:=unknown;
    v.value.isNull:=TRUE;
    v.value.last:=NIL;
    v.value.string:=NIL;
  END Init;

  (**
    Convert data from type "from" to destination type "to", if possible.
  **)

  PROCEDURE (v : ValueModel) Convert(from, to : LONGINT):BOOLEAN;


  VAR
    ret    : co.ConvResults;
    string : STRING;
    tmp    : Object.CharsLatin1;
    str8   : Object.String8;
    tmp2   : ARRAY 20 OF CHAR;

  BEGIN
    IF v.value.isNull THEN
      RETURN FALSE;
    END;

    IF from=to THEN
      RETURN TRUE;
    END;

    CASE from OF
      unknown:
      CASE to OF
        char:
        v.value.char:=0X;
        RETURN TRUE;
      | text:
        v.value.string:=Object.emptyString;
        RETURN TRUE;
      | real:
        v.value.real:=0.0;
        RETURN TRUE;
      | longreal:
        v.value.longreal:=0.0;
        RETURN TRUE;
      | shortint,
        integer,
        longint:
        v.value.longint:=0;
        RETURN TRUE;
      | boolean:
        v.value.boolean:=v.value.char#0X;
        RETURN TRUE;
      END;


    | char:
      CASE to OF
        unknown:
      | text:
        v.value.string:=Object.NewUCS4Char(v.value.char);
        RETURN TRUE;
      | real:
      | longreal:
      | shortint:
      | integer:
      | longint:
      | boolean:
        v.value.boolean:=v.value.char#0X;
        RETURN TRUE;
      END;

    | text:
      CASE to OF
        unknown:
      | char:
        v.value.char:=v.value.string.CharAt(0);
        RETURN TRUE;
      | real:
        string:=v.value.string;
        str8:=string.ToString8(0X);
        tmp:=str8.CharsLatin1();
        IF rco.FormatReal(tmp^)=rco.strAllRight THEN
          v.value.real:=rco.ValueReal(tmp^);
          RETURN TRUE;
        END;
      | longreal:
        string:=v.value.string;
        str8:=string.ToString8(0X);
        tmp:=str8.CharsLatin1();
        IF lco.FormatReal(tmp^)=lco.strAllRight THEN
          v.value.longreal:=lco.ValueReal(tmp^);
          RETURN TRUE;
        END;
      | shortint,
        integer,
        longint:
        string:=v.value.string;
        str8:=string.ToString8(0X);
        tmp:=str8.CharsLatin1();
        co.StrToInt(tmp^,v.value.longint,ret);
        IF ret=co.strAllRight THEN
          RETURN TRUE;
        END;
        RETURN ret=co.strAllRight;
      | boolean:
        IF v.value.string.Equals("true") OR v.value.string.Equals("TRUE") THEN
          v.value.boolean:=TRUE;
        ELSIF v.value.string.Equals("false") OR v.value.string.Equals("FALSE") THEN
          v.value.boolean:=FALSE;
        ELSE
          v.value.boolean:=v.value.string.length>0;
        END;
        RETURN TRUE;
      END;

    | real:
      CASE to OF
        unknown:
      | char:
      | text:
        rs.RealToStr(v.value.real,tmp2);
        v.value.string:=Object.NewLatin1(tmp2);
        RETURN TRUE;
      | longreal:
        v.value.longreal:=LONG(v.value.real);
        RETURN TRUE;
      | shortint:
      | integer:
      | longint:
      | boolean:
        v.value.boolean:=v.value.real#0.0;
        RETURN TRUE;
      END;

    | longreal:
      CASE to OF
        unknown:
      | char:
      | text:
        ls.RealToStr(v.value.longreal,tmp2);
        v.value.string:=Object.NewLatin1(tmp2);
        RETURN TRUE;
      | real:
        v.value.real:=SHORT(v.value.longreal);
        RETURN TRUE;
      | shortint:
      | integer:
      | longint:
      | boolean:
        v.value.boolean:=v.value.longreal#0.0;
        RETURN TRUE;
      END;

    | shortint,
      integer,
      longint:
      CASE to OF
        unknown:
      | char:
      | text:
        co.IntToStr(v.value.longint,tmp2);
        v.value.string:=Object.NewLatin1(tmp2);
        RETURN TRUE;
      | real:
        v.value.real:=v.value.longint;
        RETURN TRUE;
      | longreal:
        v.value.longreal:=v.value.longint;
        RETURN TRUE;
      | shortint,
        integer,
        longint:
        RETURN TRUE;
      | boolean:
        v.value.boolean:=v.value.longint#0;
        RETURN TRUE;
      END;

    | boolean:
      CASE to OF
        unknown:
      | char:
      | text:
        IF v.value.boolean THEN
          v.value.string:=Object.NewLatin1("true");
        ELSE
          v.value.string:=Object.NewLatin1("false");
        END;
      | real:
        IF v.value.boolean THEN
          v.value.real:=1.0;
        ELSE
          v.value.real:=0.0;
        END;
        RETURN TRUE;
      | longreal:
        IF v.value.boolean THEN
          v.value.longreal:=1.0;
        ELSE
          v.value.longreal:=0.0;
        END;
        RETURN TRUE;
      | shortint,
        integer,
        longint:
        IF v.value.boolean THEN
          v.value.longint:=1;
        ELSE
          v.value.longint:=0;
        END;
        RETURN TRUE;
      END;
    END;

    RETURN FALSE;
  END Convert;

  (**
    (Re)set the datatype type of the model.
    All backup levels are lost.
  **)

  PROCEDURE (v : ValueModel) SetType*(type : LONGINT);

  VAR
    oldType : LONGINT;

  BEGIN
    IF v.type=type THEN
      RETURN;
    END;

    v.value.last:=NIL;

    oldType:=v.type;
    v.type:=type;
    IF ~v.Convert(oldType,type) & ~v.value.isNull THEN
      v.value.isNull:=TRUE;
      v.Notify(NIL);
    END;
  END SetType;

  PROCEDURE (v : ValueModel) Push*;

  VAR
    value : Value;

  BEGIN
    NEW(value);
    value^:=v.value;

    v.value.last:=value;
  END Push;

  PROCEDURE (v : ValueModel) Undo*;

  VAR
    changed : BOOLEAN;
    tmp     : Value;

  BEGIN
    ASSERT(v.value.last#NIL);

    changed:=~v.value.Equal(v.value.last,v.type);

    IF changed THEN
      tmp:=v.value.last;
      v.value:=v.value.last^;
      v.value.last:=tmp;
      v.Notify(NIL);
    END;
  END Undo;

  PROCEDURE (v : ValueModel) Save*;

  VAR
    tmp : Value;

  BEGIN
    ASSERT(v.value.last#NIL);

    tmp:=v.value.last.last;
    v.value.last^:=v.value;
    v.value.last.last:=tmp;
  END Save;

  PROCEDURE (v : ValueModel) Pop*;

  VAR
    changed : BOOLEAN;

  BEGIN
    ASSERT(v.value.last#NIL);

    changed:=~v.value.Equal(v.value.last,v.type);

    v.value:=v.value.last^;

    IF changed THEN
      v.Notify(NIL);
    END;
  END Pop;

  PROCEDURE (v : ValueModel) SetLongint*(value : LONGINT);

  BEGIN
    IF v.type=unknown THEN
      v.type:=longint;
      v.value.isNull:=FALSE;
      v.value.longint:=value;
      v.Notify(NIL);
    ELSIF v.type=longint THEN
      IF v.value.isNull OR (v.value.longint#value) THEN
        v.value.isNull:=FALSE;
        v.value.longint:=value;
        v.Notify(NIL);
      END;
    ELSE
      v.value.longint:=value;
      v.value.isNull:=~v.Convert(longint,v.type);
      v.Notify(NIL);
    END;
  END SetLongint;

  PROCEDURE (v : ValueModel) SetReal*(value : REAL);

  BEGIN
    IF v.type=unknown THEN
      v.type:=real;
      v.value.real:=value;
      v.value.isNull:=FALSE;
      v.Notify(NIL);
    ELSIF v.type=real THEN
      IF v.value.isNull OR (v.value.real#value) THEN
        v.value.isNull:=FALSE;
        v.value.real:=value;
        v.Notify(NIL);
      END;
    ELSE
      v.value.real:=value;
      v.value.isNull:=~v.Convert(real,v.type);
      v.Notify(NIL);
    END;
  END SetReal;

  PROCEDURE (v : ValueModel) SetLongreal*(value : LONGREAL);

  BEGIN
    IF v.type=unknown THEN
      v.type:=longreal;
      v.value.longreal:=value;
      v.value.isNull:=FALSE;
      v.Notify(NIL);
    ELSIF v.type=longreal THEN
      IF v.value.isNull OR (v.value.longreal#value) THEN
        v.value.isNull:=FALSE;
        v.value.longreal:=value;
        v.Notify(NIL);
      END;
    ELSE
      v.value.longreal:=value;
      v.value.isNull:=~v.Convert(longreal,v.type);
      v.Notify(NIL);
    END;
  END SetLongreal;

  PROCEDURE (v : ValueModel) SetString*(value : STRING);

  VAR
    old : STRING;

  BEGIN
    old:=v.value.string;
    v.value.string:=value;
    IF v.type=unknown THEN
      v.type:=text;
      v.value.isNull:=FALSE;
      v.Notify(NIL);
    ELSIF v.type=text THEN
      IF v.value.isNull OR (old=NIL) OR ~old.Equals(v.value.string) THEN
        v.value.isNull:=FALSE;
        v.Notify(NIL);
      END;
    ELSE
      v.value.isNull:=~v.Convert(text,v.type);
      v.Notify(NIL);
    END;
  END SetString;

  PROCEDURE (v : ValueModel) SetText*(value : U.Text);

  VAR
    old : STRING;

  BEGIN
    old:=v.value.string;
    v.value.string:=Object.NewLatin1(value^);
    IF v.type=unknown THEN
      v.type:=text;
      v.value.isNull:=FALSE;
      v.Notify(NIL);
    ELSIF v.type=text THEN
      IF v.value.isNull OR (old=NIL) OR ~old.Equals(v.value.string) THEN
        v.value.isNull:=FALSE;
        v.Notify(NIL);
      END;
    ELSE
      v.value.isNull:=~v.Convert(text,v.type);
      v.Notify(NIL);
    END;
  END SetText;

  PROCEDURE (v : ValueModel) SetBoolean*(value : BOOLEAN);

  BEGIN
    IF v.type=unknown THEN
      v.type:=boolean;
      v.value.boolean:=value;
      v.value.isNull:=FALSE;
      v.Notify(NIL);
    ELSIF v.type=boolean THEN
      IF v.value.isNull OR (v.value.boolean#value) THEN
        v.value.isNull:=FALSE;
        v.value.boolean:=value;
        v.Notify(NIL);
      END;
    ELSE
      v.value.boolean:=value;
      v.value.isNull:=~v.Convert(boolean,v.type);
      v.Notify(NIL);
    END;
  END SetBoolean;

  PROCEDURE (v : ValueModel) SetNull*;

  BEGIN
    IF ~v.value.isNull THEN
      v.value.isNull:=TRUE;
      v.Notify(NIL);
    END;
  END SetNull;

  PROCEDURE (v : ValueModel) GetShortint*():SHORTINT;

  BEGIN
    IF v.Convert(v.type,shortint) THEN
      RETURN SHORT(SHORT(v.value.longint));
    ELSE
      ASSERT(FALSE);
    END;
  END GetShortint;

  PROCEDURE (v : ValueModel) GetInteger*():INTEGER;

  BEGIN
    IF v.Convert(v.type,integer) THEN
      RETURN SHORT(v.value.longint);
    ELSE
      ASSERT(FALSE);
    END;
  END GetInteger;

  PROCEDURE (v : ValueModel) GetLongint*():LONGINT;

  BEGIN
    IF v.Convert(v.type,longint) THEN
      RETURN v.value.longint;
    ELSE
      ASSERT(FALSE);
    END;
  END GetLongint;

  PROCEDURE (v : ValueModel) GetReal*():REAL;

  BEGIN
    IF v.Convert(v.type,real) THEN
      RETURN v.value.real;
    ELSE
      ASSERT(FALSE);
    END;
  END GetReal;

  PROCEDURE (v : ValueModel) GetLongreal*():LONGREAL;

  BEGIN
    IF v.Convert(v.type,longreal) THEN
      RETURN v.value.longreal;
    ELSE
      ASSERT(FALSE);
    END;
  END GetLongreal;

  PROCEDURE (v : ValueModel) GetChar*():CHAR;

  BEGIN
    IF v.Convert(v.type,char) THEN
      RETURN CHR(ORD(v.value.char));
    ELSE
      ASSERT(FALSE);
    END;
  END GetChar;

  PROCEDURE (v : ValueModel) GetString*():STRING;

  BEGIN
    IF v.Convert(v.type,text) THEN
      RETURN v.value.string;
    ELSE
      ASSERT(FALSE);
    END;
  END GetString;

  PROCEDURE (v : ValueModel) GetText*():U.Text;

  VAR
    string : STRING;
    tmp    : Object.CharsLatin1;
    value  : U.Text;

  BEGIN
    IF v.Convert(v.type,text) THEN
      IF v.value.string=NIL THEN
        RETURN NIL;
      END;

      string:=v.value.string;
      WITH
        string : Object.String8 DO
        tmp:=string.CharsLatin1();
        NEW(value,string.length+1);
        COPY(tmp^,value^);
        RETURN value;
      ELSE
        RETURN NIL;
      END;
    ELSE
      ASSERT(FALSE);
    END;
  END GetText;

  PROCEDURE (v : ValueModel) GetTextLength*():LONGINT;

  BEGIN
    IF v.Convert(v.type,text) THEN
      IF v.value.string=NIL THEN
        RETURN 0;
      ELSE
        RETURN v.value.string.length;
      END;
    ELSE
      RETURN 0;
    END;
  END GetTextLength;

  PROCEDURE (v : ValueModel) GetBoolean*():BOOLEAN;

  BEGIN
    IF v.Convert(v.type,boolean) THEN
      RETURN v.value.boolean;
    ELSE
      ASSERT(FALSE);
    END;
  END GetBoolean;

  PROCEDURE (v : ValueModel) IsNull*():BOOLEAN;

  BEGIN
    RETURN (v.type=unknown) OR v.value.isNull;
  END IsNull;

  PROCEDURE ( v : ValueModel) IsShortint*():BOOLEAN;

  BEGIN
    RETURN v.Convert(v.type,shortint);
  END IsShortint;

  PROCEDURE ( v : ValueModel) IsInteger*():BOOLEAN;

  BEGIN
    RETURN v.Convert(v.type,integer);
  END IsInteger;

  PROCEDURE ( v : ValueModel) IsLongint*():BOOLEAN;

  BEGIN
    RETURN v.Convert(v.type,longint);
  END IsLongint;

  PROCEDURE ( v : ValueModel) IsReal*():BOOLEAN;

  BEGIN
    RETURN v.Convert(v.type,real);
  END IsReal;

  PROCEDURE ( v : ValueModel) IsLongReal*():BOOLEAN;

  BEGIN
    RETURN v.Convert(v.type,longreal);
  END IsLongReal;

  PROCEDURE ( v : ValueModel) IsChar*():BOOLEAN;

  BEGIN
    RETURN v.Convert(v.type,char);
  END IsChar;

  PROCEDURE ( v : ValueModel) IsText*():BOOLEAN;

  BEGIN
    RETURN v.Convert(v.type,text);
  END IsText;

  PROCEDURE ( v : ValueModel) IsBoolean*():BOOLEAN;

  BEGIN
    RETURN v.Convert(v.type,boolean);
  END IsBoolean;


  (*
    boolean representation
   *)

  PROCEDURE (v : ValueModel) ToggleBoolean*;

  BEGIN
    IF ~v.value.isNull THEN
      IF v.Convert(v.type,boolean) THEN
        v.value.boolean:=~v.value.boolean;
        IF ~v.Convert(boolean,v.type) THEN
          v.value.isNull:=TRUE;
        END;
        v.Notify(NIL);
      ELSE
        v.value.isNull:=TRUE;
        v.Notify(NIL);
      END;
    END;
  END ToggleBoolean;

  (*
    integer representation
   *)

  PROCEDURE (v : ValueModel) Inc*;

  BEGIN
    IF ~v.value.isNull THEN
      IF v.Convert(v.type,longint) THEN
        INC(v.value.longint);
        IF ~v.Convert(longint,v.type) THEN
          v.value.isNull:=TRUE;
        END;
        v.Notify(NIL);
      ELSE
        v.value.isNull:=TRUE;
        v.Notify(NIL);
      END;
    END;
  END Inc;

  PROCEDURE (v : ValueModel) Dec*;

  BEGIN
    IF ~v.value.isNull THEN
      IF v.Convert(v.type,longint) THEN
        DEC(v.value.longint);
        IF ~v.Convert(longint,v.type) THEN
          v.value.isNull:=TRUE;
        END;
        v.Notify(NIL);
      ELSE
        v.value.isNull:=TRUE;
        v.Notify(NIL);
      END;
    END;
  END Dec;

  PROCEDURE (v : ValueModel) Add*(value : LONGINT);

  BEGIN
    IF ~v.value.isNull & (value#0) THEN
      IF v.Convert(v.type,longint) THEN
        INC(v.value.longint,value);
        IF ~v.Convert(longint,v.type) THEN
          v.value.isNull:=TRUE;
        END;
        v.Notify(NIL);
      ELSE
        v.value.isNull:=TRUE;
        v.Notify(NIL);
      END;
    END;
  END Add;

  PROCEDURE (v : ValueModel) Sub*(value : LONGINT);

  BEGIN
    IF ~v.value.isNull & (value#0) THEN
      IF v.Convert(v.type,longint) THEN
        DEC(v.value.longint,value);
        IF ~v.Convert(longint,v.type) THEN
          v.value.isNull:=TRUE;
        END;
        v.Notify(NIL);
      ELSE
        v.value.isNull:=TRUE;
        v.Notify(NIL);
      END;
    END;
  END Sub;

  (*
    string representation
   *)

  PROCEDURE (v : ValueModel) Delete*(startPos, count : LONGINT);

  VAR
    old : STRING;

  BEGIN
    IF ~v.value.isNull (*& startPos<s.length*) THEN
      IF v.Convert(v.type,text) THEN
        old:=v.value.string;
        v.value.string:=old.Substring(0,startPos);
        IF startPos+count<old.length THEN
          v.value.string:=v.value.string+old.Substring(startPos+count,old.length);
        END;
        IF ~v.Convert(text,v.type) THEN
          v.value.isNull:=TRUE;
        END;
        v.Notify(NIL);
      ELSE
        v.value.isNull:=TRUE;
        v.Notify(NIL);
      END;
    END;
  END Delete;

  PROCEDURE (v : ValueModel) Insert*(source : STRING; startPos : LONGINT);

  BEGIN
    IF ~v.value.isNull (*& startPos<=s.length*) THEN
      IF v.Convert(v.type,text) THEN
        v.value.string:=v.value.string.Substring(0,startPos)+
                        source+
                        v.value.string.Substring(startPos,v.value.string.length);
        IF ~v.Convert(text,v.type) THEN
          v.value.isNull:=TRUE;
        END;
        v.Notify(NIL);
      ELSE
        v.value.isNull:=TRUE;
        v.Notify(NIL);
      END;
    ELSIF startPos=0 THEN
      v.value.string:=source;
      v.value.isNull:=FALSE;
      IF ~v.Convert(text,v.type) THEN
        v.value.isNull:=TRUE;
      END;
      v.Notify(NIL);
    END;
  END Insert;

   PROCEDURE (b : BoolModel) Init*;

   BEGIN
     b.Init^;

    b.SetType(boolean);
   END Init;

   PROCEDURE (i : IntModel) Init*;

   BEGIN
     i.Init^;

     i.SetType(longint);
   END Init;

   PROCEDURE (s : StringModel) Init*;

   BEGIN
     s.Init^;

     s.SetType(text);
   END Init;

   PROCEDURE CreateBoolModel*():BoolModel;

   VAR
     model : BoolModel;

   BEGIN
     NEW(model);
     model.Init;

     RETURN model;
   END CreateBoolModel;

   PROCEDURE CreateIntModel*():IntModel;

   VAR
     model : IntModel;

   BEGIN
     NEW(model);
     model.Init;

     RETURN model;
   END CreateIntModel;

   PROCEDURE CreateStringModel*():StringModel;

   VAR
     model : StringModel;

   BEGIN
     NEW(model);
     model.Init;

     RETURN model;
   END CreateStringModel;

   PROCEDURE CreateLongRealModel*():LongRealModel;

   VAR
     model : LongRealModel;

   BEGIN
     NEW(model);
     model.Init;

     RETURN model;
   END CreateLongRealModel;

END VO:Model:Value.
