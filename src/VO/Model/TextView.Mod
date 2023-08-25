(**
   An abstract model for readonly multiline text.
**)

MODULE VO:Model:TextView;

(*
    A class  for readonly text models.
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


IMPORT O   := VO:Base:Object,

              Object,
       Ch  := Channel,
       T   := TextRider;

CONST

  (* Notifies *)
  resyncMsg * = 0;
  resizeMsg * = 1;

TYPE
  Reader*         = POINTER TO ReaderDesc;
  TextModel*      = POINTER TO TextModelDesc;

  (**
    A reader for the textmodel.
  **)

  ReaderDesc*     = RECORD
                      model-: TextModel;
                      next-,
                      last- : Reader;
                      pos - : LONGINT;
                    END;

  (**
    The textmodel baseclass.
  **)

  TextModelDesc* = RECORD (O.ModelDesc)
                     lines- : LONGINT;
                   END;

  Line*          = POINTER TO LineDesc;
  LineDesc*      = RECORD
                     chars- : STRING;
                   END;

  ReloadMsg*     = POINTER TO ReloadMsgDesc;
  ReloadMsgDesc* = RECORD (O.ResyncMsgDesc)
                   END;

  (* textmodel imlementations *)

  ListLine           = POINTER TO ListLineDesc;
  ListLineDesc       = RECORD (LineDesc)
                         next,
                         last  : ListLine;
                       END;


  ListReader*        = POINTER TO ListReaderDesc;
  ListTextModel*     = POINTER TO ListTextModelDesc;

  ListTextModelDesc* = RECORD (TextModelDesc)
                         first,
                         last   : ListLine;
                       END;

  ListReaderDesc*    = RECORD (ReaderDesc)
                         line : ListLine;
                       END;


  PROCEDURE (t : TextModel) Init*;

  BEGIN
    t.Init^;

    t.lines:=0;
  END Init;

  PROCEDURE (t : TextModel) ResyncMsg*;

  VAR
    msg : O.Notify;

  BEGIN
    NEW(msg);

    msg.notify:=resyncMsg;

    t.Notify(msg);
  END ResyncMsg;

  PROCEDURE (t : TextModel) ResizeMsg*;

  VAR
    msg : O.Notify;

  BEGIN
    NEW(msg);
    msg.notify:=resizeMsg;

    t.Notify(msg);
  END ResizeMsg;

  PROCEDURE (t : TextModel) GetReader*():Reader;

  BEGIN
    RETURN NIL;
  END GetReader;

  PROCEDURE (r : Reader) Init*;

  BEGIN
    r.model:=NIL;
    r.pos:=0;
    r.last:=NIL;
    r.next:=NIL;
  END Init;

  PROCEDURE (r : Reader) IsValid*():BOOLEAN;

  BEGIN
    RETURN r.pos>0;
  END IsValid;

  PROCEDURE (r : Reader) Assign*(reader : Reader);

  BEGIN
    r.model:=reader.model;
    r.pos:=reader.pos;
  END Assign;

  PROCEDURE (r : Reader) Position*(line : LONGINT);

  BEGIN
    IF r.pos>0 THEN
      r.pos:=line;
    END;
  END Position;

  PROCEDURE (r : Reader) Forward*(lines : LONGINT);

  BEGIN
    IF r.pos>0 THEN
      INC(r.pos,lines);
    END;
  END Forward;

  PROCEDURE (r : Reader) Backward*(lines : LONGINT);

  BEGIN
    IF r.pos>0 THEN
      DEC(r.pos,lines);
    END;
  END Backward;

  PROCEDURE (r : Reader) Next*;

  BEGIN
    r.Forward(1);
  END Next;

  PROCEDURE (r : Reader) Last*;

  BEGIN
    r.Backward(1);
  END Last;

  PROCEDURE (r : Reader) GetLine*(VAR line : LineDesc);

  BEGIN
    (*    line.chars:=NIL;*)
  END GetLine;




  PROCEDURE (t : ListTextModel) Init*;

  BEGIN
    t.Init^;

    t.first:=NIL;
    t.last:=NIL;
  END Init;

  PROCEDURE (t : ListTextModel) GetReader*():Reader;

  VAR
    reader : ListReader;

  BEGIN
    NEW(reader);
    reader.Init;

    reader.model:=t;
    reader.line:=t.first;
    IF t.first#NIL THEN
      reader.pos:=1;
    ELSE
      reader.pos:=0;
    END;

    RETURN reader;
  END GetReader;

  PROCEDURE (t : ListTextModel) Clear*;

  BEGIN
    t.first:=NIL;
    t.last:=NIL;
    t.lines:=0;

    t.ResyncMsg;
  END Clear;

  PROCEDURE (t : ListTextModel) AddText*(text : ARRAY OF CHAR);

  BEGIN
    ASSERT(FALSE);
  END AddText;

  PROCEDURE (t : ListTextModel) AddLn*;

  BEGIN
    ASSERT(FALSE);
  END AddLn;

  PROCEDURE (t : ListTextModel) AddLine*(text : STRING);

  VAR
    line : ListLine;

  BEGIN
    NEW(line);
    line.chars:=text;

    line.next:=NIL;
    IF t.first=NIL THEN
      t.first:=line;
      line.last:=NIL;
    ELSE
      line.last:=t.last;
      t.last.next:=line;
    END;
    t.last:=line;

    INC(t.lines);

    t.ResizeMsg;
  END AddLine;

  PROCEDURE (t : ListTextModel) RemoveLastLine*;

  BEGIN
    ASSERT(FALSE);
  END RemoveLastLine;

  PROCEDURE (t : ListTextModel) LoadFromChannel*(channel : Ch.Channel):BOOLEAN;

  VAR
    reader : T.Reader;
    buffer : ARRAY 1024 OF CHAR;
    line   : ListLine;

  BEGIN
    reader:=T.ConnectReader(channel);
    IF reader#NIL THEN
      t.Clear;

      WHILE (channel.res=Ch.done) & (reader.Available()>0) DO
        reader.ReadLine(buffer);
        NEW(line);
        INC(t.lines);
        IF t.last#NIL THEN
          line.last:=t.last;
          t.last.next:=line;
        ELSE
          t.first:=line;
        END;
        t.last:=line;

        line.chars:=Object.NewLatin1(buffer);
      END;

      t.ResyncMsg();
      RETURN channel.res=Ch.done;
    END;
    RETURN FALSE;
  END LoadFromChannel;

  PROCEDURE (r : ListReader) Init*;

  BEGIN
    r.Init^;

    r.line:=NIL;
  END Init;

  PROCEDURE (r : ListReader) Attach;

  BEGIN
    IF r.pos=0 THEN
      r.line:=r.model(ListTextModel).first;
      IF r.line#NIL THEN
        r.pos:=1;
      END;
    END;
  END Attach;

  PROCEDURE (r : ListReader) IsValid*():BOOLEAN;

  BEGIN
    r.Attach;

    RETURN r.IsValid^();
  END IsValid;

  PROCEDURE (r : ListReader) Assign*(reader : Reader);

  BEGIN
    reader(ListReader).Attach;

    r.Assign^(reader);

    r.line:=reader(ListReader).line;
  END Assign;

  PROCEDURE (r : ListReader) Position*(line : LONGINT);

  BEGIN
    r.Attach;

    IF r.pos>0 THEN
      IF line>r.pos THEN
        r.Forward(line-r.pos);
      ELSIF line<r.pos THEN
        r.Backward(r.pos-line);
      END;

      r.Position^(line);
    END;
  END Position;

  PROCEDURE (r : ListReader) Forward*(lines : LONGINT);

  VAR
    x : LONGINT;

  BEGIN
    r.Attach;

    IF r.pos>0 THEN
      FOR x:=1 TO lines DO
        r.line:=r.line.next;
      END;

      r.Forward^(lines);
    END;
  END Forward;

  PROCEDURE (r : ListReader) Backward*(lines : LONGINT);

  VAR
    x : LONGINT;

  BEGIN
    r.Attach;

    IF r.pos>0 THEN
      FOR x:=1 TO lines DO
        r.line:=r.line.last;
      END;

      r.Backward^(lines);
    END;
  END Backward;

  PROCEDURE (r : ListReader) GetLine*(VAR line : LineDesc);

  BEGIN
    r.GetLine^(line);

    IF r.line#NIL THEN
      line.chars:=r.line.chars;
    END;
  END GetLine;

END VO:Model:TextView.