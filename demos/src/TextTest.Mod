(**
  Visualizes the VOTextTest object. The object draws some drawing primites
  together with some test markes to see if the primitives are positioned
  and sized correctly.
**)

MODULE TextTest;

(*
    Demo for VisualOberon. Checks correctnes of some drawing primitives.
    Copyright (C) 1999  Tim Teulings (rael@edge.ping.de)

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

IMPORT D   := VO:Base:Display,     (* Display stuff *)

              VO:Prefs:All,  (* Include preferences for all objects *)

              VO:OS:Probe,

       G   := VO:Object,
       W   := VO:Window,      (* Window class *)
       WG  := VO:WindowGroup, (* The window group object *)

              Err,           (* Simple error IO *)
              Strings;

CONST
  text = "Polilop";

TYPE
  Prefs*        = POINTER TO PrefsDesc;
  PrefsDesc*    = RECORD (G.PrefsDesc)
                  END;

  TextTest*     = POINTER TO TextTestDesc;
  TextTestDesc* = RECORD (G.ImageDesc)
                  END;

  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  w        : Window;       (* The window *)
  msg2Exit : D.Msg2Exit;     (* a simple message converter *)

  prefs    : Prefs;

  PROCEDURE (w : Window) PreInit*;

  VAR
    test   : TextTest;
    wGroup : WG.WindowGroup; (* The window group *)

  BEGIN
    (*
      Allocate an instance of the window group class.
      This group handles positioning of menustrip and window contents.
    *)
    NEW(wGroup);

    (* Every instance must be initialized *)
    wGroup.Init;

      NEW(test);
      test.Init;

    wGroup.Set(NIL,test,TRUE);

    (* Set the top object of the window to the window group *)
    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

  PROCEDURE (d : TextTest) Init*;

  BEGIN
    d.Init^;

    d.SetPrefs(prefs);
  END Init;

  PROCEDURE (d : TextTest) CalcSize*;

  BEGIN
    d.width:=120;
    d.height:=120;

    d.minWidth:=d.width;
    d.minHeight:=d.height;

    d.CalcSize^;
  END CalcSize;

  PROCEDURE (d : TextTest) Draw*(x,y,w,h : LONGINT);

  VAR
    draw   : D.DrawInfo;
    extent : D.FontExtentDesc;

  BEGIN
    IF ~d.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    d.Draw^(x,y,w,h);

    draw:=d.GetDrawInfo();

    D.normalFont.TextExtent(text,Strings.Length(text),{},extent);

    Err.String("width: "); Err.LongInt(extent.width,0); Err.Ln;
    Err.String("height: "); Err.LongInt(extent.height,0); Err.Ln;
    Err.String("lbearing: "); Err.LongInt(extent.lbearing,0); Err.Ln;
    Err.String("rbraring: "); Err.LongInt(extent.rbearing,0); Err.Ln;
    Err.String("font ascent: "); Err.LongInt(D.normalFont.ascent,0); Err.Ln;
    Err.String("font descent: "); Err.LongInt(D.normalFont.descent,0); Err.Ln;
    Err.String("font height: "); Err.LongInt(D.normalFont.height,0); Err.Ln;

    Err.Ln;
    Err.String("font ascent: "); Err.LongInt(D.fixedFont.ascent,0); Err.Ln;
    Err.String("font descent: "); Err.LongInt(D.fixedFont.descent,0); Err.Ln;
    Err.String("font height: "); Err.LongInt(D.fixedFont.height,0); Err.Ln;

    (* Lines *)
    d.DrawBackground(d.x,d.y,d.width,d.height);

    draw.PushForeground(D.blackColor);
    draw.PushFont(D.normalFont,{});
    draw.DrawString(d.x-extent.lbearing+(d.width-(extent.rbearing-extent.lbearing)) DIV 2,
                    d.y+extent.ascent+(d.height-extent.height) DIV 2,
                    text,Strings.Length(text));
    draw.PopFont;
    draw.PopForeground;

    draw.PushForeground(D.whiteColor);
    draw.DrawLine(d.x,
                  d.y+d.height DIV 2,
                  d.x+d.width-1,
                  d.y+d.height DIV 2);

    draw.DrawLine(d.x+(d.width-(extent.rbearing-extent.lbearing)) DIV 2,
                  d.y+(d.height-extent.height) DIV 2,
                  d.x+(d.width-(extent.rbearing-extent.lbearing)) DIV 2+(extent.rbearing-extent.lbearing)-1,
                  d.y+(d.height-extent.height) DIV 2+extent.height);
    draw.PopForeground;
  END Draw;

BEGIN
  NEW(prefs);
  prefs.Init;

  (*
    Try to initialize it.
    This call make the connection to the X server and allocates
    fonts, colors and that stuff
  *)
  IF ~Probe.OpenDisplay("TextTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  (* Create an instance of the window class *)
  NEW(w);

  (* Initialize it *)
  w.Init;

  (* Set the title of the window *)
  w.SetTitle("TextTest");

  (*
    Allocate an instance of this special message handler.
    A handler is a class that can convert any or a special
    input message to an other message and sends the resulting
    message to the given destination. However the baseclas just
    returns the input message.

    Most converters are handwritten, but some special converters are
    given by the corresponding objects.

    This converter converts the close-message generated when clicking
    the closing gadget of the window to an exist-message of the display
    class.
  *)
  NEW(msg2Exit);

  (*
    Send the resulting exit message to the display, which will finish
    the event loop and receiving.
  *)
  msg2Exit.destination:=D.display;

  (*
    Add the handler to window and tell the window that it should call
    this hndler when a close message gets send.
  *)
  w.AddHandler(msg2Exit,W.closeMsg);

  (* Open the main window *)
  IF w.Open() THEN
    (*
      Start the main event loop. The event loop will get finished when
      the display receives a close message or its exit method gets called.
    *)
    D.display.EventLoop;
  END;

  (* Free possible ressources of the display. *)
  D.display.Close;
END TextTest.