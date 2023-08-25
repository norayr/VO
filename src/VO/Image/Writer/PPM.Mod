MODULE VO:Image:Writer:PPM;

  (*
    Image storing subsystem for VisualOberon.
    Copyright (C) 2003 Stewart Greenhill (sgreenhill@users.sf.net)

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

IMPORT I := VO:Image:Image,
            VO:Image:Writer,

            Files,
            Err,
            Msg,
            TextRider;

  PROCEDURE WritePPM*(wr : TextRider.Writer; w,h : LONGINT; data : I.Data);

  VAR
    i : LONGINT;

  BEGIN
    (* magic number *)
    wr.WriteString("P6"); wr.WriteLn;

    (* dimensionis *)
    wr.WriteLInt(w,0); wr.WriteChar(' '); wr.WriteLInt(h,0); wr.WriteLn;

    (* maximum colour value : 255 for 8-bit channels *)
    wr.WriteLInt(255,0); wr.WriteLn;

    FOR i:=0 TO w*h-1 DO
      wr.WriteChar(data[i].r);
      wr.WriteChar(data[i].g);
      wr.WriteChar(data[i].b);
    END;
  END WritePPM;

  PROCEDURE WriteData*(name : ARRAY OF CHAR; w,h : LONGINT; data : I.Data);

  VAR
    f   : Files.File;
    res : Msg.Msg;
    wr  : TextRider.Writer;
    msg : ARRAY 128 OF CHAR;

  BEGIN
    f:=Files.New(name,{Files.write},res);
    IF res=Files.done THEN
      wr:=TextRider.ConnectWriter(f);
      WritePPM(wr,w,h,data);
      f.Close;
    ELSE
      res.GetText(msg);
      Err.String(msg); Err.Ln;
    END;
  END WriteData;

  PROCEDURE Store*(name : ARRAY OF CHAR;
                   image : I.Image;
                   options : Writer.Options):BOOLEAN;

  BEGIN
    WriteData(name,image.width,image.height,image.current);

    RETURN TRUE;
  END Store;

END VO:Image:Writer:PPM.
