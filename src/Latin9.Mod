MODULE Latin9;

(*
Please check file ../Codec.Mod for the specifications.

Name: ISO_8859-1:1987                                    [RFC1345,KXS2]
MIBenum: 4
Source: ECMA registry
Alias: iso-ir-100
Alias: ISO_8859-1
Alias: ISO-8859-1 (preferred MIME name)
Alias: latin1
Alias: l1
Alias: IBM819
Alias: CP819
Alias: csISOLatin1
*)

IMPORT
  UC := XML:UnicodeCodec;


TYPE
  Codec* = POINTER TO CodecDesc;
  CodecDesc = RECORD
    (UC.CodecDesc)
  END;

TYPE
  Factory* = POINTER TO FactoryDesc;
  FactoryDesc = RECORD
    (UC.FactoryDesc)
  END;

VAR
  factory-: Factory;

PROCEDURE Init (codec: Codec; bom: SHORTINT);
  BEGIN
    UC.Init (codec, bom)
  END Init;

PROCEDURE New (bom: SHORTINT): Codec;
  VAR
    c: Codec;
  BEGIN
    NEW (c);
    Init (c, bom);
    RETURN c
  END New;


PROCEDURE (codec: Codec) Decode* (VAR source: ARRAY OF CHAR;
                                  sourceStart, sourceEnd: LONGINT;
                                  VAR dest: ARRAY OF LONGCHAR;
                                  destStart, destEnd: LONGINT;
                                  VAR sourceDone, destDone: LONGINT);
  BEGIN
    IF (sourceEnd-sourceStart > destEnd-destStart) THEN
      sourceEnd := (destEnd-destStart)+sourceStart
    END;
    WHILE (sourceStart # sourceEnd) DO
      CASE source[sourceStart] OF
        0A4X:
        dest[destStart]:=020ACX;
      | 0A6X:
        dest[destStart]:=0160X;
      | 0A8X:
        dest[destStart]:=0161X;
      | 0B4X:
        dest[destStart]:=017DX;
      | 0B8X:
        dest[destStart]:=017EX;
      | 0BCX:
        dest[destStart]:=0152X;
      | 0BDX:
        dest[destStart]:=0153X;
      | 0BEX:
        dest[destStart]:=0178X;
      ELSE
        dest[destStart] := source[sourceStart];
      END;
      INC (sourceStart);
      INC (destStart)
    END;
    sourceDone := sourceStart;
    destDone := destStart
  END Decode;

PROCEDURE (codec: Codec) Encode* (VAR source: ARRAY OF LONGCHAR;
                                  sourceStart, sourceEnd: LONGINT;
                                  VAR dest: ARRAY OF CHAR;
                                  destStart, destEnd: LONGINT;
                                  VAR sourceDone, destDone: LONGINT);
  VAR
    i, j, testSourceEnd: LONGINT;

  CONST
    offsetSource = UC.maxUCS2EncodingLength-1;

  BEGIN
    (* adjust the interval end to save some tiresome out of bounds checks
       in the main loop *)
    testSourceEnd := sourceEnd-offsetSource;

    (* iterate over all characters in the source interval *)
    i := sourceStart; j := destStart;
    WHILE (i < testSourceEnd) & (j # destEnd) DO
      (* Handle special characters >0FFX *)
      CASE source[i] OF
        020ACX:
        dest[j]:=0A4X;
      | 0160X:
        dest[j]:=0A6X;
      | 0161X:
        dest[j]:=0A8X;
      | 017DX:
        dest[j]:=0B4X;
      | 017EX:
        dest[j]:=0B8X;
      | 0152X:
        dest[j]:=0BCX;
      | 0153X:
        dest[j]:=0BDX;
      | 0178X:
        dest[j]:=0BEX;
      ELSE
        IF (source[i]>0FFX) THEN
          (* All other character above 0FFX cannot be converted *)
          INC (codec.invalidChars);
          dest[j] := UC.encodeError;
        ELSE
          CASE source[sourceStart] OF
            (* Thischaracters below 0FFX cannot be converted, too *)
            0A4X,
            0A6X,
            0A8X,
            0B4X,
            0B8X,
            0BCX,
            0BDX,
            0BEX:
            INC (codec.invalidChars);
            dest[j] := UC.encodeError;
          ELSE
            (* The rest is OK *)
            dest[j]:=SHORT(source[i]);
          END;
        END;
      END;
      INC(i);
      INC(j);
    END;

    sourceDone := i; destDone := j
  END Encode;


PROCEDURE InitFactory (f: Factory);
  BEGIN
    UC.InitFactory (f, UC.bomNotApplicable)
  END InitFactory;

PROCEDURE (f: Factory) NewCodec* (): Codec;
  BEGIN
    RETURN New (f. bom)
  END NewCodec;

PROCEDURE (f: Factory) NewCodecBOM* (VAR source: ARRAY OF CHAR;
                                  sourceStart, sourceEnd: LONGINT;
                                  VAR sourceDone: LONGINT): Codec;
  BEGIN
    sourceDone := sourceStart;
    RETURN New (f. bom)
  END NewCodecBOM;

PROCEDURE (f: Factory) GetEncodingName* (VAR name: ARRAY OF CHAR);
  BEGIN
    COPY ("ISO-8859-15", name)
  END GetEncodingName;

BEGIN
  NEW (factory);
  InitFactory (factory);

(*  UC.Register ("ISO_8859-1:1987", factory);
  UC.Register ("iso-ir-100", factory);*)
  UC.Register ("ISO_8859-15", factory);
  UC.Register ("ISO-8859-15", factory);  (* preferred MIME name *)
  UC.Register ("latin9", factory);
  UC.Register ("l9", factory);
(*  UC.Register ("IBM819", factory);
  UC.Register ("CP819", factory);*)
  UC.Register ("csISOLatin9", factory)
END Latin9.
