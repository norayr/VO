MODULE VGDDoc;

  (**
    Lists all attributes an objects supports in VGD.
  *)

  (*
    Show attributes supported in VGD.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

    This file is part of VisualOberon.

    VisualOberon is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    VisualOberon is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with VisualOberon. If not, write to the Free Software
    Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

IMPORT        VO:VGD:All,
              VO:VGD:VGD,

              ADT:StringBuffer,
              Err,
              Object,
              Out,
       PA  := ProgramArgs,
       TR  := TextRider;

VAR
  buffer : StringBuffer.StringBuffer;
  arg    : STRING;

  PROCEDURE ParseArgs():BOOLEAN;

  VAR
    reader : TR.Reader;
    buffer : ARRAY 1024 OF CHAR;

  BEGIN
    reader:=TR.ConnectReader(PA.args);
    IF reader#NIL THEN
      reader.ReadLine(buffer);

      IF PA.args.ArgNumber()#1 THEN
        Err.String("Error: Expected exactly one argument!"); Err.Ln;
        Err.String("Usage: "); Err.String("VGDDoc <ObjectName|'ALL'|'LIST'>"); Err.Ln;
        RETURN FALSE;
      END;

      reader.ReadLine(buffer);
      arg:=Object.NewLatin1(buffer);
    END;

    RETURN TRUE;
  END ParseArgs;

  PROCEDURE DumpObjects;

  VAR
    objects : Object.ObjectArrayPtr(VGD.ObjectParser);
    windows : Object.ObjectArrayPtr(VGD.WindowParser);
    x       : LONGINT;

  BEGIN
    Out.String("Objects:");Out.Ln;
    objects:=VGD.factory.objects.Values();
    FOR x:=0 TO LEN(objects^)-1 DO
      Out.Object(objects[x].name);Out.Ln;
    END;
    Out.Ln;

    Out.String("Windows:");Out.Ln;
    windows:=VGD.factory.windows.Values();
    FOR x:=0 TO LEN(windows^)-1 DO
      Out.Object(windows[x].name);Out.Ln;
    END;
  END DumpObjects;


  PROCEDURE DumpDocumentation(parser : VGD.Parser);

  BEGIN
    Out.Object(parser.name);Out.Ln;
    buffer.Clear;
    parser.GetDocumentation(buffer);
    Out.Object(buffer);Out.Ln;
  END DumpDocumentation;

  PROCEDURE DumpAllDocumentation;

  VAR
    objects : Object.ObjectArrayPtr(VGD.ObjectParser);
    windows : Object.ObjectArrayPtr(VGD.WindowParser);
    x       : LONGINT;

  BEGIN
    Out.String("Objects:");Out.Ln;
    objects:=VGD.factory.objects.Values();
    FOR x:=0 TO LEN(objects^)-1 DO
      DumpDocumentation(objects[x]);Out.Ln;
    END;
    Out.Ln;

    Out.String("Windows:");Out.Ln;
    windows:=VGD.factory.windows.Values();
    FOR x:=0 TO LEN(windows^)-1 DO
      DumpDocumentation(windows[x]);Out.Ln;
    END;
  END DumpAllDocumentation;

BEGIN
  buffer:=NEW(StringBuffer.StringBuffer,1000);

  IF ~ParseArgs() THEN
    HALT(1);
  END;

  IF arg.Equals("ALL") THEN
    DumpAllDocumentation;
  ELSIF arg.Equals("LIST") THEN
    DumpObjects;
  ELSE
    IF VGD.factory.objects.HasKey(arg) THEN
      DumpDocumentation(VGD.factory.objects.Get(arg));
    ELSIF VGD.factory.windows.HasKey(arg) THEN
      DumpDocumentation(VGD.factory.windows.Get(arg));
    ELSE
      Err.String("Unkown object!");Err.Ln;
    END;
  END;
END VGDDoc.