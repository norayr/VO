<* PUSH; Warnings:=FALSE *>

MODULE VO:VGD:All;
  (**
    Convinience module that includes all VGD modules.
  *)

  (*
    Includes all modules neccessary for using VGD stuff.
    Copyright (C) 2002 Tim Teulings (rael@edge.ping.de)

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

IMPORT VO:VGD:Array,
       VO:VGD:Bool,
       VO:VGD:Button,
       VO:VGD:ButtonRow,
       VO:VGD:Clock,
       VO:VGD:ColorArea,
       VO:VGD:Combo,
       VO:VGD:DigiClock,
       VO:VGD:FrameGroup,
       VO:VGD:FuelGauge,
       VO:VGD:Image,
       VO:VGD:Label,
       VO:VGD:LED,
       VO:VGD:LightChain,
       VO:VGD:Menu,
       VO:VGD:MenuStrip,
       VO:VGD:Oszil,
       VO:VGD:Pane,
       VO:VGD:Panel,
       VO:VGD:PatternLegend,
       VO:VGD:PieChart,
       VO:VGD:Power,
       VO:VGD:Radio,
       VO:VGD:Slider,
       VO:VGD:QuickHelp,
       VO:VGD:Space,
       VO:VGD:StatusLine,
       VO:VGD:String,
       VO:VGD:StringClock,
       VO:VGD:Tab,
       VO:VGD:Table,
       VO:VGD:Text,
       VO:VGD:TextView,
       VO:VGD:Toolbar,
       VO:VGD:Tree,
       VO:VGD:View,
       VO:VGD:ViewOneOfN,
       VO:VGD:Window,
       VO:VGD:WindowGroup,
       VO:VGD:WireFrame;

END VO:VGD:All.

<* POP *>