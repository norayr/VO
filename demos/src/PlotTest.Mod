(**
    Demo for VisualOberon. Demonstrates the plot object.
**)

MODULE PlotTest;

(*
    Demo for VisualOberon. Demonstrates the plot object.
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

       FM  := VO:Model:Function,

              VO:Prefs:All,  (* Include preferences for all objects *)

       G   := VO:Object,
       P   := VO:Panel,
       PL  := VO:Plot,
       W   := VO:Window,

              Err,
       M   := LRealMath;

TYPE
  SinModel*     = POINTER TO SinModelDesc;
  SinModelDesc* = RECORD (FM.FunctionLRealModelDesc)
                    value : LONGREAL;
                  END;

VAR
  w        : W.Window;

  panel    : P.Panel;
  plot     : PL.Plot;
  model    : SinModel;
  lines    : ARRAY 1 OF PL.LineType;

  msg2Exit : D.Msg2Exit;

  PROCEDURE (s : SinModel) Init*;

  BEGIN
    s.Init^;

    s.SetDescribtion("sin(x)");
  END Init;

  PROCEDURE (s : SinModel) SetValue*(dim : LONGINT; value : LONGREAL);

  BEGIN
    ASSERT(dim=0);

    s.value:=value;
  END SetValue;

  PROCEDURE (s : SinModel) Dimension*():LONGINT;

  BEGIN
    RETURN 1;
  END Dimension;

  PROCEDURE (s : SinModel) Execute*():LONGREAL;

  BEGIN
    RETURN M.sin(s.value);
  END Execute;

BEGIN
  D.display.SetAppName("PlotTest");
  IF ~D.display.Open() THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  NEW(panel);
  panel.Init;
  panel.Set(P.horizontal);
  panel.SetFlags({G.horizontalFlex,G.verticalFlex});

    NEW(model);
    model.Init;

    NEW(plot);
    plot.Init;
    plot.SetFlags({G.horizontalFlex,G.verticalFlex});
    plot.SetPlotLimits(-10,10,-1.2,1.2);
    plot.SetPlotScale(1,1);
    lines[0]:="Hallo!";
    plot.SetModel(model);
  panel.Add(plot);

  NEW(w);
  w.Init;
  w.SetTop(panel);
  w.SetTitle("PlotTest");
  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
  END;

  D.display.Close;
END PlotTest.