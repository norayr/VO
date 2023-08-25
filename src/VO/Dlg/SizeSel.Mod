MODULE VO:Dlg:SizeSel [OOC_EXTENSIONS];

(**
  A dialog for showing and changing objects of type @code{VO:Base:Size}.
*)

(*
    A dialog for showing and changing objects of type VO:Base:Size.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

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

IMPORT Z   := VO:Base:Size,

       V   := VO:Model:Value,

       S   := VO:String,

       co  := IntStr,
              Object,
       str := Strings;

TYPE
  SizeSelString*     = POINTER TO SizeSelStringDesc;
  SizeSelStringDesc* = RECORD (S.StringDesc)
                         size : Z.SizeDesc;
                       END;


  PROCEDURE (s : SizeSelString) Init*;

  VAR
    model : V.StringModel;

  BEGIN
    s.Init^;

    NEW(model);
    model.Init;
    model.SetString("");
    s.SetModel(model);

    s.SetReadOnly(TRUE);
  END Init;

  PROCEDURE (s : SizeSelString) EvaluateSize;

  VAR
    value : ARRAY 1024 OF CHAR;

  BEGIN
    co.IntToStr(s.size.size,value);

    CASE s.size.mode OF
      Z.pixel:
      str.Append(" pixel",value);
    | Z.screenHRel:
      str.Append("% screen width",value);
    | Z.screenVRel:
      str.Append("% screen height",value);
    | Z.unit:
      str.Append("unit(s)",value);
    | Z.unitP:
      str.Append("% unit(s)",value);
    | Z.softUnit:
      str.Append("softunit(s)",value);
    | Z.softUnitP:
      str.Append("% softunit(s)",value);
    ELSE
      RETURN;
    END;

    s.string.SetString(Object.NewLatin1(value));
  END EvaluateSize;

  PROCEDURE (s : SizeSelString) SetSize*(size[NO_COPY] : Z.SizeDesc);

  BEGIN
    s.size:=size;

    s.EvaluateSize;
  END SetSize;

  PROCEDURE CreateSizeSelString*():SizeSelString;

  VAR
    string : SizeSelString;

  BEGIN
    NEW(string);
    string.Init;

    RETURN string;
  END CreateSizeSelString;

END VO:Dlg:SizeSel.