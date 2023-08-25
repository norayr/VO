(**
    Demo for VisualOberon. Demonstrates the image object.
**)

MODULE VisualShow;

(*
    Demo for VisualOberon. Demonstrates the image object.
    Copyright (C) 1998  Tim Teulings (rael@edge.ping.de)

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

IMPORT D   := VO:Base:Display,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>
       G   := VO:Object,
       I   := VO:Image,
       W   := VO:Window,

              Err,
              Object,
       A   := ProgramArgs,
       TR  := TextRider;


VAR
  w        : W.Window;

  image    : I.Image;

  reader   : TR.Reader;
  file     : ARRAY 256 OF CHAR;

BEGIN
  IF ~Probe.OpenDisplay("VisualShow") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  reader:=TR.ConnectReader(A.args);
  IF reader#NIL THEN
    reader.ReadLine(file);
    IF A.args.ArgNumber()=1 THEN
      reader.ReadLine(file);
    ELSE
      Err.String("VisualShow <image>"); Err.Ln;
      HALT(1);
    END;
  ELSE
    HALT(1);
  END;

  image:=I.CreateImage();
  image.SetFlags({G.horizontalFlex,G.verticalFlex});
  image.SetFilename(Object.NewLatin1(file));

  NEW(w);
  w.Init;
  w.SetTop(image);
  w.SetTitle("VisualShow");
  w.Forward(W.closeMsg,w);

  IF w.Open() THEN
    w.EventLoop;
  END;

  D.display.Close;
END VisualShow.