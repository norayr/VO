(**
  Displays size of all disks.
**)

MODULE DiskSize;

(*
    Displays size of all disks (demo).
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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
       Z   := VO:Base:Size,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)
<* POP *>

       G   := VO:Object,
       P   := VO:Panel,
       PC  := VO:PieChart,
       PL  := VO:PatternLegend,
(*       Q   := VOQuickHelp,*)
       SP  := VO:Space,
       T   := VO:Text,
       TA  := VO:Tab,
       W   := VO:Window,
       WG  := VO:WindowGroup,

              Err;

TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
               END;

VAR
  w        : Window;

  msg2Exit : D.Msg2Exit;

  PROCEDURE (w : Window) PreInit*;

  VAR
    x      : LONGINT;

    wGroup : WG.WindowGroup;
    horiz  : P.Panel;
    legend : PL.PatternLegend;
    pie    : PC.PieChart;
    space  : SP.Space;
    text   : T.Text;
    tab    : TA.Tab;

  BEGIN
    NEW(wGroup);
    wGroup.Init;

      NEW(tab);
      tab.Init;
      tab.SetFlags({G.horizontalFlex,G.verticalFlex});
      tab.RequestFocus();

        FOR x:=1 TO 4 DO

          NEW(horiz);
          horiz.Init;
          horiz.Set(P.horizontal);
          horiz.SetFlags({G.horizontalFlex,G.verticalFlex});

            NEW(legend);
            legend.Init;
            legend.Add(T.MakeLeftText("used"));
            legend.Add(T.MakeLeftText("free"));
            legend.Add(T.MakeLeftText("reserved"));
            legend.SetFlags({G.verticalFlex});
          horiz.Add(legend);

            NEW(space);
            space.Init;
            space.Set(FALSE,SP.huge);
          horiz.Add(space);

            NEW(pie);
            pie.Init;
            pie.SetFlags({G.horizontalFlex,G.verticalFlex});
            pie.SetWidth(Z.unit,30);
            pie.SetHeight(Z.unit,30);

            CASE x OF
              1: pie.SetTotal(45835);
                 pie.AddValue(30243);
                 pie.AddValue(12972);
                 pie.AddValue(45835-30243-12972);
            | 2: pie.SetTotal(523904);
                 pie.AddValue(330784);
                 pie.AddValue(193120);
            | 3: pie.SetTotal(575475);
                 pie.AddValue(434132);
                 pie.AddValue(110601);
                 pie.AddValue(575475-434132-110601);
            | 4: pie.SetTotal(307829);
                 pie.AddValue(218979);
                 pie.AddValue(72422);
                 pie.AddValue(307829-218979-72422);
            END;

          horiz.Add(pie);

            CASE x OF
              1: tab.AddTab(T.MakeCenterText("/"),horiz);
            | 2: tab.AddTab(T.MakeCenterText("/dos"),horiz);
            | 3: tab.AddTab(T.MakeCenterText("/usr"),horiz);
            | 4: tab.AddTab(T.MakeCenterText("/home"),horiz);
            END;
        END;

        NEW(text);
        text.Init;
      tab.AddTab(T.MakeCenterText("About..."),T.MakeLeftText("\ec\es\e9DiskSize\ep\n\en\ec(functionless demo for \esVisualOberon\en)\n\nCopyright 1997\nTim Teulings\n(rael@edge.ping.de)"));
    wGroup.Set(NIL,tab,TRUE);

    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

BEGIN
  IF ~Probe.OpenDisplay("DiskSize") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  NEW(w);
  w.Init;
  w.SetTitle("DiskSize");

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
  END;

  D.display.Close;
END DiskSize.