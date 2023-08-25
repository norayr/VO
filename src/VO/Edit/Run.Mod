MODULE VO:Edit:Run [OOC_EXTENSIONS];

  (*
    Part of the VO internal multiline text edit control.
    Copyright (C) 2003 Tim Teulings

    This module is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with OOC. If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

IMPORT s   := SYSTEM,
       B   := VO:Edit:Block,

              Err;

TYPE
  Run*         = POINTER TO RunDesc;

  (**
    A text consists of Runs. A Run represents a certain amount of
    characters within a text or special logical information.
    Because of the editor implementation Runs are never longer
    than a line. Run itself is only a abstract baseclass.
    There are a number of special Runs. Since the base allready
    knows of LineRuns the baseclass supports moving through text.
  **)

  RunDesc*     = RECORD
                   next*,              (* Pointer to the next Run *)
                   last*   : Run;      (* Pointer to the last Run *)
                   block*  : B.Block;  (* Pointer to the text block           *)
                   pos*,               (* Position in the block 0..blockLen-1 *)
                   length* : LONGINT;  (* Length of text the in block         *)
                 END;

(* ------------------------------------------------------------------------ *)

  PROCEDURE (r : Run) Init*;

  BEGIN
   r.last:=NIL;
   r.next:=NIL;
   r.block:=NIL;
   r.pos:=-1;
   r.length:=-1;
  END Init;

  PROCEDURE (r : Run) Append*(run : Run);

  BEGIN
    r.next:=run;
    run.last:=r;
  END Append;

  PROCEDURE (r : Run) InsertAfter*(new : Run);

  (**
    Insert the given Run after the current one.
  *)

  BEGIN
    IF r.next#NIL THEN
      r.next.last:=new;
    END;
    new.next:=r.next;
    r.next:=new;
    new.last:=r;
  END InsertAfter;

  PROCEDURE (r : Run) InsertBefore*(new : Run);

  (**
    Insert the given Run before the current one.
  *)

  BEGIN
    IF r.last#NIL THEN
      r.last.next:=new;
    END;
    new.last:=r.last;
    WHILE new.next#NIL DO
      new:=new.next;
    END;
    r.last:=new;
    new.next:=r;
  END InsertBefore;

  PROCEDURE (r : Run) Remove*;

  (**
    Removes the Run from the list.
  *)

  BEGIN
    IF r.last#NIL THEN
      r.last.next:=r.next;
    END;

    IF r.next#NIL THEN
      r.next.last:=r.last;
    END;
  END Remove;

  (**
    Makes the given Run follower of the current run.
  **)
(*
  PROCEDURE (r : Run) Join*(run : Run);

  BEGIN
    r.next:=run;
    IF run#NIL THEN
      run.last:=r;
    END;
  END Join;

  PROCEDURE (r : Run) Nice*;

  BEGIN
    IF r.run.length=0 THEN
      ASSERT(r.next#NIL);

      run.block:=run.next.block;
    run:=l.next;

    WHILE (run#NIL) & ~(run IS LineRun) DO
      WITH
        run : TextRun DO
          IF run.length<=0 THEN
            run.Remove;
          ELSIF (run.next#NIL) & (run.next IS TextRun) THEN
            b:=run.next(TextRun);
            IF (run.block=b.block) & (run.pos+run.length=b.pos) THEN
              INC(run.length,b.length);
              b.Remove;
            END;
          END;
      ELSE
      END;
      run:=run.next;
    END;
  END Nice;
*)

  PROCEDURE (r : Run) Copy*():Run;

  (**
    Create an exact copy of the given run.
  *)

  VAR
    run : Run;

  BEGIN
    NEW(run);
    run^:=r^;

    RETURN run;
  END Copy;

  PROCEDURE (r : Run) SplitBackward(pos : LONGINT);

  (**
    Splits the given Run at the given position into two
    text Runs. r will still point to pos.

    RESULT
    It is possible that splitting a Run changes the run.
  *)

  VAR
    new : Run;

  BEGIN
    NEW(new);
    new.Init;
    new.block:=r.block;
    new.pos:=r.pos;
    new.length:=pos-r.pos;

    r.length:=r.pos+r.length-pos;
    r.pos:=pos;

    r.InsertBefore(new);
  END SplitBackward;

  PROCEDURE (r : Run) SplitForward(pos : LONGINT);

  (**
    Splits the given Run at the given position into two
    text Runs. r will point to the text before pos.

    RESULT
    It is possible that splitting a Run changes the run.
  *)

  VAR
    new : Run;

  BEGIN
    NEW(new);
    new.Init;
    new.block:=r.block;
    new.pos:=pos;
    new.length:=r.length-(pos-r.pos);

    DEC(r.length,new.length);

    r.InsertAfter(new);
  END SplitForward;

  PROCEDURE (r : Run) Print*;

  (**
    This function is only for debugging purposes.
  *)

  VAR
    x : LONGINT;

  BEGIN
    FOR x:=r.pos TO r.pos+r.length-1 DO
      Err.Char(r.block.text[x]);
    END;
  END Print;

  PROCEDURE (r : Run) DumpEnviroment*;

  BEGIN
    Err.String(">>>>>"); Err.Ln;
    Err.String("(");
    IF r.last#NIL THEN
      Err.Hex(s.VAL(LONGINT,r.last),8);Err.Char(",");
      Err.LongInt(r.last.pos,0); Err.Char(","); Err.LongInt(r.last.length,0);
      Err.Char("|");
      r.last.Print;
    END;
    Err.String(")");

    Err.String("[");
    Err.Hex(s.VAL(LONGINT,r),8);Err.Char(",");
    Err.LongInt(r.pos,0); Err.Char(","); Err.LongInt(r.length,0);
    Err.Char("|");
    r.Print;
    Err.String("]");

    Err.String("(");
    IF r.next#NIL THEN
      Err.Hex(s.VAL(LONGINT,r.next),8);Err.Char(",");
      Err.LongInt(r.next.pos,0); Err.Char(","); Err.LongInt(r.next.length,0);
      Err.Char("|");
      r.next.Print;
    END;
    Err.String(")");

    Err.Ln;
    Err.String("<<<<<"); Err.Ln;
  END DumpEnviroment;

  PROCEDURE (r : Run) InsertRunBefore*(pos : LONGINT; run : Run);

  BEGIN
    IF pos=r.pos THEN
      (*Err.String("Inserting before"); Err.Ln;*)
      r.InsertBefore(run);
    ELSE (* in between *)
      (*Err.String("Splitting"); Err.Ln;*)
      r.SplitBackward(pos);
      r.InsertBefore(run);
    END;
  END InsertRunBefore;

(*
  PROCEDURE (r : Run) InsertRunAfter*(pos : LONGINT; run : Run);

  BEGIN
    IF pos+1>=r.pos+r.length-1 THEN (* after the run *)
      r.InsertAfter(run);
    ELSE (* in between *)
      r.SplitForward(pos+1);
      r.InsertAfter(run);
    END;
  END InsertRunAfter;
*)

  PROCEDURE JoinRuns*(run1 : Run; pos : LONGINT;
                      VAR run2 : Run; VAR pos2 : LONGINT):Run;

  (**
    Example:
    "0123456"
    run1 points to "2" and run2 points to "4"
    THEN "23" is deleted

    run2 stays valid (run1 will get invalid, since it points within
    the deleted area). To point to the currect char you should point
    point to run2.pos (however run.öpos will not be changed during Join
    so just leave it as it is).

    RETURN
    The delete run(s), correctly terminated.
  *)

  VAR
    res : Run;

  BEGIN
    (*run2.DumpEnviroment;*)

    (* TODO: This can get simlified! *)

(*    Err.LongInt(pos,0); Err.String("->"); Err.LongInt(pos2,0); Err.Ln;

    run1.DumpEnviroment;
    run2.DumpEnviroment;*)

    IF run1=run2 THEN
(*      Err.String("run1=run2"); Err.Ln;*)
      IF (run1.pos=pos) & (run2.pos#pos2) THEN
        (*Err.String("run1.pos=pos & run2.pos#pos"); Err.Ln;*)
        run1:=run1.last;
        run2.SplitBackward(pos2);
        res:=run2.last;
        run2.last:=run2.last.last;
        IF run2.last#NIL THEN
          run2.last.next:=run2;
        END;
        res.last:=NIL;
        res.next:=NIL;
      ELSIF (run1.pos#pos) & (run2.pos=pos2) THEN
(*        Err.String("run1.pos#pos & run2.pos=pos"); Err.Ln;*)
        (*
          Should not be possible: run run2 always points after run1,
          so if run1=run2 run2 cannot point to start of run.
        *)
        ASSERT(FALSE);
      ELSIF (run1.pos=pos) & (run2.pos=pos2) THEN
        (*Err.String("run1.pos=pos & run2.pos=pos"); Err.Ln;*)
        (*
          Should not be possible: run run2 always points after run1,
          so run1 and run2 cannot point to the same code.
        *)
        ASSERT(FALSE);
      ELSE
        (*Err.String("run1.pos#pos & run2.pos#pos"); Err.Ln;*)
        run1.SplitForward(pos);
        run2:=run1.next;
        run2.SplitBackward(pos2);
        res:=run2.last;
        run2.last:=run2.last.last;
        IF run2.last#NIL THEN
          run2.last.next:=run2;
        END;
        res.last:=NIL;
        res.next:=NIL;
      END;
    ELSE
(*      Err.String("run1#run2"); Err.Ln;*)
      IF (run1.pos=pos) & (run2.pos#pos2) THEN
(*        Err.String("run1.pos=pos & run2.pos#pos"); Err.Ln;*)
        res:=run1;
        run1:=run1.last;
        res.last:=NIL;

        run2.SplitBackward(pos2);
        run2.last.next:=NIL; (* terminating res *)
        run2.last:=run1;
        IF run2.last#NIL THEN
          run2.last.next:=run2;
        END;
      ELSIF (run1.pos#pos) & (run2.pos=pos2) THEN
(*        Err.String("run1.pos#pos & run2.pos=pos"); Err.Ln;*)
        run1.SplitForward(pos);
        res:=run1.next;
        res.last:=NIL;

        run2.last.next:=NIL; (* terminating res *)
        run2.last:=run1;
        IF run2.last#NIL THEN
          run2.last.next:=run2;
        END;
      ELSIF (run1.pos=pos) & (run2.pos=pos2) THEN
(*        Err.String("run1.pos=pos & run2.pos=pos"); Err.Ln;*)
        res:=run1;
        run1:=run1.last;
        res.last:=NIL;

        run2.last.next:=NIL; (* terminating res *)
        run2.last:=run1;
        IF run2.last#NIL THEN
          run2.last.next:=run2;
        END;
      ELSE
(*        Err.String("run1.pos#pos & run2.pos#pos"); Err.Ln;*)
        run1.SplitForward(pos);
        res:=run1.next;
        res.last:=NIL;

        run2.SplitBackward(pos2);
        run2.last.next:=NIL; (* terminating res *)
        run2.last:=run1;
        IF run2.last#NIL THEN
          run2.last.next:=run2;
        END;

      END;
    END;

    ASSERT(pos2=run2.pos);

(*    IF run1#NIL THEN
      run1.DumpEnviroment;
    END;
    run2.DumpEnviroment;
    res.DumpEnviroment;*)

    RETURN res;
  END JoinRuns;

  PROCEDURE CreateRunChar*(char : CHAR):Run;

  VAR
    text : Run;

  BEGIN
    NEW(text);
    text.Init;
    text.pos:=B.StoreCharInBlock(char);
    text.block:=B.block;
    text.length:=1;

    RETURN text;
  END CreateRunChar;


  PROCEDURE CreateRunChars*(char : CHAR; count : LONGINT):Run;

  VAR
    text : Run;

  BEGIN
    ASSERT(count<=B.blockLen);

    NEW(text);
    text.Init;
    text.pos:=B.StoreCharsInBlock(char,count);
    text.block:=B.block;
    text.length:=count;

    RETURN text;
  END CreateRunChars;

  PROCEDURE CreateRunString*(string[NO_COPY] : ARRAY OF CHAR; length : LONGINT):Run;

  VAR
    first,
    last,
    current : Run;
    pos     : LONGINT;

  BEGIN
    (*
      Todo: Create a list of runs!
    *)
    first:=NIL;
    last:=NIL;
    pos:=0;

    WHILE pos<length DO
      NEW(current);
      current.Init;
      IF length-pos>B.blockLen THEN
        current.pos:=B.StoreAreaInBlock(string,pos,B.blockLen);
        current.length:=B.blockLen;
        INC(pos,B.blockLen);
      ELSE
        current.pos:=B.StoreAreaInBlock(string,pos,length-pos);
        current.length:=length-pos;
        INC(pos,length-pos);
      END;
      current.block:=B.block;

      IF first=NIL THEN
        first:=current;
      ELSE
        last.next:=current;
        current.last:=last;
        current.next:=NIL;
      END;
      last:=current;
    END;

    RETURN first;
  END CreateRunString;

  PROCEDURE DuplicateRunList*(run : Run):Run;

  VAR
    start,
    last,
    current: Run;

  BEGIN
    start:=NIL;
    last:=NIL;
    WHILE run#NIL DO
      current:=run.Copy();
      IF start=NIL THEN
        start:=current;
        start.last:=NIL;
      ELSE
        last.next:=current;
        current.last:=last;
      END;
      last:=current;

      run:=run.next;
    END;

    last.next:=NIL;

    RETURN start;
  END DuplicateRunList;

END VO:Edit:Run.