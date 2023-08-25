MODULE VisualOberonLib;

(**
  A pseudo module to generate a shared/static library for VisualOberon
  by using oo2c.
*)

  <* PUSH; Warnings := FALSE *>

(*
    Pseudo module for shared/static library.
    Copyright (C) 1997  Tim Teulings (rael@edge.ping.de)

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

IMPORT
        VO:Base:Background,
  XA := VO:Base:Display,
        VO:Base:DragDrop,
  XB := VO:Base:Event,
        VO:Base:Frame,
  XC := VO:Base:Image,
        VO:Base:Object,
        VO:Base:Size,
        VO:Base:Util,
  XD := VO:Base:VecImage,

        VO:Dlg:About,
        VO:Dlg:ColSel,
        VO:Dlg:File,
        VO:Dlg:Font,
        VO:Dlg:Form,
        VO:Dlg:FrmSel,
        VO:Dlg:ImgSel,
        VO:Dlg:Msg,
        VO:Dlg:SizeSel,

  XII:= VO:Image:Image,
        VO:Image:Loader,
  XLA:= VO:Image:Loader:All,
        VO:Image:Writer,
  <* IF HAVE_LIB_PNG=TRUE THEN *>
  XLP:= VO:Image:Loader:PNG,
  XWP:= VO:Image:Writer:PNG,
  <* END *>

  XLM:= VO:Image:Writer:PPM,

  <* IF HAVE_LIB_JPEG=TRUE THEN *>
  XLJ:= VO:Image:Loader:JPG,
  XWJ:= VO:Image:Writer:JPG,
  <* END *>

  <* IF HAVE_LIB_GIF=TRUE THEN *>
  XLG:= VO:Image:Loader:GIF,
  <* END *>

  <* IF HAVE_LIB_TIFF=TRUE THEN *>
  XLT:= VO:Image:Loader:TIF,
  <* END *>
        VO:Image:ImageStream,

        VO:Model:Adjustment,
        VO:Model:DataStream,
        VO:Model:DateTime,
        VO:Model:DirTable,
        VO:Model:Function,
        VO:Model:Header,
        VO:Model:Selection,
        VO:Model:Table,
        VO:Model:TextView,
        VO:Model:Tree,
        VO:Model:Value,
        VO:Model:View,

        VO:OS:Probe,

<* IF HAVE_PACKAGE_CURSES THEN *>
  XE := VO:OS:Curses:Display,
  XF := VO:OS:Curses:Event,
<* END *>

<* IF HAVE_PACKAGE_X11 THEN *>
  XG := VO:OS:X11:Display,
  XH := VO:OS:X11:Event,
  XI := VO:OS:X11:Image,
<* END *>

        VO:Prefs:All,
        VO:Prefs:Base,
        VO:Prefs:GUI,
        VO:Prefs:Parser,

  PA := VO:Prefs:Array,
  PBO:= VO:Prefs:Bool,
  PBU:= VO:Prefs:Button,
  PBR:= VO:Prefs:ButtonRow,
  PCL:= VO:Prefs:Clock,
  PCO:= VO:Prefs:Combo,
  PDA:= VO:Prefs:Date,
  PDC:= VO:Prefs:DigiClock,
  PDI:= VO:Prefs:Display,
  PFG:= VO:Prefs:FrameGroup,
  PFF:= VO:Prefs:FuelGauge,
  PGR:= VO:Prefs:Grid,
  PHD:= VO:Prefs:Header,
  PKN:= VO:Prefs:Knob,
  PLA:= VO:Prefs:Label,
  PLE:= VO:Prefs:LED,
  PLI:= VO:Prefs:LightChain,
  PLO:= VO:Prefs:Load,
  PME:= VO:Prefs:Menu,
  PMU:= VO:Prefs:Multi,
  POB:= VO:Prefs:Object,
  POZ:= VO:Prefs:Oszil,
  PAN:= VO:Prefs:Panel,
  PPA:= VO:Prefs:PatternLegend,
  PPI:= VO:Prefs:PieChart,
  PPL:= VO:Prefs:Plate,
  PPO:= VO:Prefs:Power,
  PQU:= VO:Prefs:QuickHelp,
  PRA:= VO:Prefs:Radio,
  PSC:= VO:Prefs:Scale,
  PSR:= VO:Prefs:Scroller,
  PSL:= VO:Prefs:Slider,
  PSP:= VO:Prefs:Space,
  PST:= VO:Prefs:StatusLine,
  PSG:= VO:Prefs:String,
  PSO:= VO:Prefs:StringClock,
  PTA:= VO:Prefs:Tab,
  PTB:= VO:Prefs:Table,
  PTV:= VO:Prefs:TableView,
  PTX:= VO:Prefs:Text,
  PTO:= VO:Prefs:Toolbar,
  PTR:= VO:Prefs:Tree,
  PVO:= VO:Prefs:ViewOneOfN,
  PWI:= VO:Prefs:Window,
  PWG:= VO:Prefs:WindowGroup,

  V  := VO:VGD:All,
  VV := VO:VGD:VGD,

  VAA:= VO:VGD:Array,
  VBO:= VO:VGD:Bool,
  VB := VO:VGD:Button,
  VBR:= VO:VGD:ButtonRow,
  VCL:= VO:VGD:Clock,
  VCA:= VO:VGD:ColorArea,
  VCO:= VO:VGD:Combo,
  VDC:= VO:VGD:DigiClock,
  VFU:= VO:VGD:FuelGauge,
  VFG:= VO:VGD:FrameGroup,
  VIM:= VO:VGD:Image,
  VLA:= VO:VGD:Label,
  VLE:= VO:VGD:LED,
  VLC:= VO:VGD:LightChain,
  VME:= VO:VGD:Menu,
  VMS:= VO:VGD:MenuStrip,
  VOS:= VO:VGD:Oszil,
  VPE:= VO:VGD:Pane,
  VPN:= VO:VGD:Panel,
  VPA:= VO:VGD:PatternLegend,
  VPI:= VO:VGD:PieChart,
  VPO:= VO:VGD:Power,
  VQ := VO:VGD:QuickHelp,
  VRA:= VO:VGD:Radio,
  VSD:= VO:VGD:Slider,
  VSP:= VO:VGD:Space,
  VSL:= VO:VGD:StatusLine,
  VST:= VO:VGD:String,
  VSC:= VO:VGD:StringClock,
  VTA:= VO:VGD:Tab,
  VTB:= VO:VGD:Table,
  VT := VO:VGD:Text,
  VTV:= VO:VGD:TextView,
  VTO:= VO:VGD:Toolbar,
  VTR:= VO:VGD:Tree,
  VON:= VO:VGD:ViewOneOfN,
  VW := VO:VGD:Window,
  VWG:= VO:VGD:WindowGroup,
  VWF:= VO:VGD:WireFrame,

        VO:Array,
	      VO:BackgroundArea,
        VO:Bool,
        VO:Button,
        VO:ButtonRow,
        VO:Clock,
        VO:ColorArea,
        VO:Combo,
        VO:Date,
        VO:DigiClock,
        VO:Edit:Edit,
        VO:Edit:Block,
  XS := VO:Edit:Function,
        VO:Edit:Run,
        VO:Edit:Syntax,
        VO:Edit:Syntax:Standard,
  XT := VO:Edit:Text,
        VO:FrameGroup,
        VO:FuelGauge,
        VO:Grid,
  XU := VO:Header,
        VO:Image,
        VO:Knob,
        VO:LED,
        VO:Label,
        VO:LightChain,
        VO:Line,
        VO:Load,
        VO:Menu,
        VO:Multi,
  XV := VO:Object,
        VO:Oszil,
        VO:Pane,
        VO:Panel,
        VO:PatternLegend,
        VO:PercentBar,
        VO:PieChart,
        VO:Plate,
        VO:Power,
        VO:QuickHelp,
        VO:Radio,
        VO:Scale,
        VO:Scroller,
        VO:Segment,
        VO:Segment7,
        VO:Slider,
        VO:Space,
        VO:State,
  	    VO:StatusLine,
        VO:String,
        VO:StringClock,
        VO:Tab,
  XW := VO:Table,
        VO:TableView,
        VO:Text,
        VO:TextEdit,
  XX := VO:TextView,
        VO:Time,
        VO:Toolbar,
  XY := VO:Tree,
  XZ := VO:View,
        VO:ViewOneOfN,
        VO:Window,
        VO:WindowGroup,
        VO:WireFrame,

        Directory,
        Latin9,
        ChannelFDWrapper;

  <* POP *>

END VisualOberonLib.
