MODULE VO:Text;

  (**
    This module implements @otype{Text}.
  *)

  (*
    Implements a text image.
    Copyright (C) 1997 Tim Teulings (rael@edge.ping.de)

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

IMPORT D   := VO:Base:Display,
       DD  := VO:Base:DragDrop,
       F   := VO:Base:Frame,
       I   := VO:Base:Image,
       VB  := VO:Base:VecImage,

       G   := VO:Object,

              Ascii,
              Object;

CONST

  (* PartDesc.style *)

  smart      * =  D.maxStyle+1;  (** That nice 3-D effect with bright color on dark color *)
  highlight  * =  D.maxStyle+2;  (** Use shinePen instead of textpen                     *)
  warn       * =  D.maxStyle+3;  (** Use a color for warnings                             *)

  (* LineDesc.justification *)

  leftAlligned  * = 0; (** Text will be displayed left aligned. *)
  rightAlligned * = 1; (** Text will displayed right aligned. *)
  centered      * = 2; (** Text will be displayed centered. *)

  (*
    This is the special escape-character introducting special commands
    for the layout-engine.

    Format is always ESCAPE <command>, where command is a special character
    introduced below...

    An extension of the syntax for command like ESCAPE <command> <onechaparameter>
    should be made. For example for colordefinitions.

    It is of cause no problem to implement commands
    for drawing horizontal lines or other nifty things...

    A usefull thing of cause would be support for datatype-objects...
  *)
  (* The different letters than can follow escape *)

  NORMAL     = "n";
  BOLD       = "b";
  ITALIC     = "i";
  SLANTED    = "a";
  UNDERLINED = "u";
  SMART      = "s";
  HIGHLIGHT  = "h";
  WARN       = "w";

  LEFT       = "l";
  RIGHT      = "r";
  CENTERED   = "c";

  RETURNI    = "R"; (* Insert the return image at this place *)
  ESCAPE     = "E"; (* Insert the escape image at this place *)
  DEFAULT    = "D"; (* Insert the default image at this place *)

  FIXED      = "f";
  PROP       = "p";

  (* This are also characters which need special care: *)

  EOT  = Ascii.nul; (* Should be obsolent now, checking against LEN(text)     *)


  (* --------------------------------------------------------- *)


TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 focusFrame* : F.Frame;
                 return*,
                 escape*,
                 default*    : I.Image;
               END;


  Part      = POINTER TO PartDesc;
  PartDesc  = RECORD
                next   : Part;     (* all parts of a line are linked    *)
                width,             (* width and height of this part
                                      calculated by TextImage.CalcSize  *)
                height : LONGINT;
              END;

  TextPart     = POINTER TO TextPartDesc;
  TextPartDesc = RECORD (PartDesc)
                   style   : SET;        (* every part has a special drawmode *)
                   (*aColor,               (* every part has special colors
                                            this is not supported yet         *)
                   bColor  : INTEGER;*)
                   text    : STRING;     (* The text to be drawn              *)
                   font    : D.Font;

                   offset  : LONGINT;
                 END;

  TabPart     = POINTER TO TabPartDesc;
  TabPartDesc = RECORD (PartDesc)
                  nextTab : TabPart;
                END;

  ImagePart     = POINTER TO ImagePartDesc;
  ImagePartDesc = RECORD (PartDesc)
                    image : I.Image;
                  END;

  Line     = POINTER TO LineDesc;
  LineDesc = RECORD
               next, last    : Line;      (* lines are double-linked, maybe someday we add a scroller *)
               justification : SHORTINT;  (* Every line can have it's special justification           *)
               parts         : Part;      (* Every line consists of a number of parts, each of them
                                             with special layout-paameters                            *)
               lastPart      : Part;      (* last entry in parts-list                                 *)
               currentPart   : Part;      (* curent, not yet appended entry                           *)
               width,                     (* width and height of line -> TextClass.CalcSize           *)
               height        : LONGINT;
               tabCount      : LONGINT;   (* Number of tabs in line. Usefull for optimations in
                                             TextClass.CalcSize                                       *)
             END;

  TabList      = POINTER TO ARRAY OF LONGINT;

  (* --------------------------------------------------------- *)

  Text *    = POINTER TO TextDesc;
  TextDesc* = RECORD (G.ImageDesc)
                (**
                  Implements multiline complex formatted text.

                  The text is draggable.

                  A number of escape sequences are supported.
                  @itemize
                  @item \n
                  Newline
                  @item \t
                  Tab
                  @item \\
                  Escape the backslash
                  @item \en
                  Normal text
                  @item \eb
                  Bold text
                  @item \ei
                  Italic text
                  @item \ea
                  Slanted text
                  @item \eu
                  Underlined text

                  @item \el
                  Left aligned text
                  @item \er
                  Right aligned text
                  @item \ec
                  Centered text

                  @item \e[0..9]
                  Set the relative font size. Default is 4, bigger
                  number will result in bigger fotns, smaller values
                  will result in smaller fonts.

                  @item \ef
                  Set a fixed font
                  @item \ep
                  Set a proportional font

                  ...
                  @end itemize
                *)
                textList     : Line;          (* A text is first just a number of lines    *)
                lastLine     : Line;          (* last line of textList                     *)
                currentLine  : Line;          (* Pointer to current line, not in textList  *)
                lines        : LONGINT;       (* number of lines in text                   *)
                currentJust  : SHORTINT;      (* current justification for current and
                                                 following lines/parts                     *)
                currentStyle : SET;           (* current style for current and
                                                 following lines/parts                     *)
                currentFont  : D.Font;
                textWidth-,                   (* with and high of total text
                                                 calclated by TextClass.CalcSize           *)
                textHeight-,
                lineSpace    : LONGINT;       (* Space between lines                       *)
                tabList      : TabList;
                calced       : BOOLEAN;

                defaultJust  : SHORTINT;
                defaultDraw  : SET;
                defaultFont  : D.Font;
              END;

VAR
  prefs* : Prefs;

  PROCEDURE GetFont(pos : LONGINT):D.Font;

  BEGIN
    CASE pos OF
      D.tinyFontIndex:
        RETURN D.tinyFont;
    | D.scriptFontIndex:
        RETURN D.scriptFont;
    | D.footnoteFontIndex:
        RETURN D.footnoteFont;
    | D.smallFontIndex:
        RETURN D.smallFont;
    | D.normalFontIndex:
        RETURN D.normalFont;
    | D.largeFontIndex:
        RETURN D.largeFont;
    | D.LargeFontIndex:
        RETURN D.LargeFont;
    | D.LARGEFontIndex:
        RETURN D.LARGEFont;
    | D. hugeFontIndex:
        RETURN D.hugeFont;
    | D.HUGEFontIndex:
        RETURN D.HUGEFont;
    ELSE
      RETURN D.normalFont;
    END;
  END GetFont;

  (* --------------------------------------------------------- *)

  (*  *)

  PROCEDURE (t : TextPart) HasText():BOOLEAN;

  BEGIN
    RETURN (t.text#NIL);
  END HasText;

  (* --------------------------------------------------------- *)

  (* Appends given part to the list of pats for this line *)

  PROCEDURE (l : Line) AppendPart (p : Part);

  BEGIN
    IF l.parts=NIL THEN
      l.parts:=p;
    ELSE
      l.lastPart.next:=p;
    END;
    l.lastPart:=p;
  END AppendPart;

  (* --------------------------------------------------------- *)

  (*
     Closes current part
     If there is a currentPart with a given text, it will appended to the list
     of parts of the current line (Line.AddPart) and currentPart will be set to NIL
   *)

  PROCEDURE (l : Line) ClosePart;

  BEGIN
    IF l.currentPart#NIL THEN
      IF (l.currentPart IS TextPart) & (~l.currentPart(TextPart).HasText()) THEN
        l.currentPart:=NIL;
      ELSE
        l.AppendPart(l.currentPart);
      END;
    END;
    l.currentPart:=NIL;
  END ClosePart;

  (* --------------------------------------------------------- *)

  (* Closes last part and creates a new TextPart in Line.currentPart *)

  PROCEDURE (l : Line) NewTextPart(defaultStyle : SET; defaultFont : D.Font);

  VAR
    help : TextPart;

  BEGIN
    l.ClosePart;

    NEW(help);
    help.next:=NIL;
    help.text:=NIL;
    help.style:=defaultStyle;
    help.font:=defaultFont;

    l.currentPart:=help;
  END NewTextPart;

  (* --------------------------------------------------------- *)

  (* Closes last part and creates a new TabPart in Line.currentPart *)

  PROCEDURE (l : Line) NewTabPart(t : Text);

  VAR
    newOne : TabList;
    x      : LONGINT;
    help   : TabPart;

  BEGIN
    l.ClosePart;
    NEW(help);
    help.next:=NIL;
    help.nextTab:=NIL;
    l.currentPart:=help;

    IF (t.tabList=NIL) THEN
      NEW(t.tabList,10);
      FOR x:=0 TO LEN(t.tabList^)-1 DO
        t.tabList[x]:=0;
      END;
    END;

    IF l.tabCount>LEN(t.tabList^) THEN
      NEW(newOne,LEN(t.tabList^)+10);
      FOR x:=0 TO LEN(t.tabList^)-1 DO
        newOne[x]:=t.tabList[x];
      END;
      FOR x:=LEN(t.tabList^) TO LEN(newOne^)-1 DO
        newOne[x]:=0;
      END;
      t.tabList:=newOne;
    END;

    INC(l.tabCount);
  END NewTabPart;

  (* --------------------------------------------------------- *)

  (* Closes last part and creates a new ImagePart in Line.currentPart *)

  PROCEDURE (l : Line) NewImagePart(image : I.Image);

  VAR
    help : ImagePart;

  BEGIN
    l.ClosePart;
    NEW(help);
    help.next:=NIL;
    help.image:=NIL;
    l.currentPart:=help;
    l.currentPart(ImagePart).image:=image;
  END NewImagePart;


  (* --------------------------------------------------------- *)

  (* Sets the curent style *)

  PROCEDURE (l : Line) SetStyle(style : SET);

  BEGIN
    l.currentPart(TextPart).style:=style;
  END SetStyle;

  (* --------------------------------------------------------- *)


  (* Sets the curent Font *)

  PROCEDURE (l : Line) SetFont(font : D.Font);

  BEGIN
    l.currentPart(TextPart).font:=font;
  END SetFont;

  (* --------------------------------------------------------- *)
  (* Appends the given line to TextClassDesc.textList *)

  PROCEDURE (t : Text) AppendLine(l : Line);

  BEGIN
    IF t.textList=NIL THEN
      t.textList:=l;
    ELSE
      t.lastLine.next:=l;
      l.last:=t.lastLine;
    END;
    t.lastLine:=l;
    INC(t.lines);
  END AppendLine;

  (* --------------------------------------------------------- *)

  (*
     Checks if there is a valid line in TextClassDesc.currentLine and
     appends it to TextClassDesc.textList using AppendLine
   *)

  PROCEDURE (t : Text) CloseLine;

  BEGIN
    IF t.currentLine#NIL THEN
      t.AppendLine(t.currentLine);
      t.currentLine:=NIL;
    END;
  END CloseLine;

  (* --------------------------------------------------------- *)

  (*
     Handles existing TextClassDesc.currentLine, appends its using AppendLine
     and creates a new line in TextClassDesc.curentLine
   *)

  PROCEDURE (t : Text) NewLine;

  BEGIN

    (* Allready a line on the stack -> Close the line and append it *)

    t.CloseLine;

    NEW(t.currentLine);
    t.currentLine.next:=NIL;
    t.currentLine.last:=NIL;
    t.currentLine.parts:=NIL;
    t.currentLine.lastPart:=NIL;
    t.currentLine.currentPart:=NIL;
    t.currentLine.justification:=t.currentJust;
    t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
  END NewLine;

  (* --------------------------------------------------------- *)

  (* Adds the given text to the part in t.currentLine.currentPart *)

  PROCEDURE (t : Text) AddTextToPart(text : STRING; start, stop : LONGINT);

  BEGIN
    IF stop-start>=0 THEN
      t.currentLine.currentPart(TextPart).text:=text.Substring(start,stop+1);
    END;
    t.currentLine.ClosePart;
    t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
  END AddTextToPart;
  (* --------------------------------------------------------- *)

  (* Sets current justification *)

  PROCEDURE (t : Text) SetJustification(type : SHORTINT);

  BEGIN
    t.currentLine.justification:=type;
    t.currentJust:=type;
  END SetJustification;

  (* --------------------------------------------------------- *)

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.focusFrame:=F.CreateFrame(F.dottedFocus);

    IF D.display.displayType=D.displayTypeTextual THEN
      p.return:=I.CreateVecImage(VB.none);
      p.escape:=I.CreateVecImage(VB.none);
      p.default:=I.CreateVecImage(VB.none);
    ELSE
      p.return:=I.CreateVecImage(VB.return);
      p.escape:=I.CreateVecImage(VB.escape);
      p.default:=I.CreateVecImage(VB.default);
    END;
  END Initialize;

  (* --------------------------------------------------------- *)

  PROCEDURE (t : Text) Init*;

  BEGIN
    t.Init^;

    t.SetPrefs(prefs);

    t.RemoveFlags({G.stdFocus});
    t.SetFlags({G.canDisable});

    t.textHeight:=0;
    t.textWidth:=0;

    t.lines:=0;
    t.textList:=NIL;
    t.lastLine:=NIL;
    t.currentLine:=NIL;
    t.lineSpace:=0;
    t.tabList:=NIL;
    t.calced:=FALSE;

    t.defaultJust:=leftAlligned;
    t.defaultDraw:={};
    t.defaultFont:=D.normalFont;

    (* Initialize text to an empty line *)

    t.NewLine;
    t.CloseLine;
  END Init;

  (* ---- Drag and drop stuff *)

  PROCEDURE (t : Text) GetDnDObject*(x,y : LONGINT; drag : BOOLEAN):G.Object;

  BEGIN
    IF t.visible & t.PointIsIn(x,y) THEN
      (* we can drag and drop *)
      RETURN t;
    ELSE
      RETURN NIL;
    END;
  END GetDnDObject;

  PROCEDURE (t : Text) GetDragInfo*(VAR dragInfo : DD.DnDDataInfo);

  BEGIN
    dragInfo.AddDataType(DD.text,DD.none,{DD.copy},DD.copy);
  END GetDragInfo;

  PROCEDURE (t : Text) GetDragData*(group, type, action : LONGINT):DD.DnDData;

  VAR
    data : DD.DnDStringData;
    l    : Line;
    p    : Part;
    h    : ARRAY 2 OF CHAR;
    help :STRING;

  BEGIN
    IF group=DD.text THEN

      h[0]:=Ascii.lf;
      h[1]:=0X;
      help:=Object.NewLatin1(h);

      NEW(data);
      data.string:="";

      l:=t.textList;
      WHILE l#NIL DO
        p:=l.parts;
        WHILE p#NIL DO
          WITH p : TextPart DO
            IF p.HasText() THEN
              data.string:=data.string+p.text;
            END;
          ELSE
          END;
          p:=p.next;
        END;
        IF l.next#NIL THEN
          data.string:=data.string+help;
        END;
        l:=l.next;
      END;

      RETURN data;
    ELSE
      RETURN NIL;
    END;
  END GetDragData;

  PROCEDURE (t : Text) CalcTextSize*;

  (**
    Calculates the size of TextClass.textList in respect to given font and rastPort.
  *)


  VAR
    l        : Line;
    p,last   : Part;
    mSize,
    tabCount,
    tSize    : LONGINT;
    extent   : D.FontExtentDesc;

  BEGIN
    t.textHeight:=0;
    t.textWidth:=0;

    mSize:=0;

    l:=t.textList;
    WHILE l#NIL DO

      tabCount:=0;
      tSize:=0;
      p:=l.parts;
      last:=NIL;
      WHILE p#NIL DO

        WITH
          p : TextPart DO
              p.font.StrExtent(p.text,p.style,extent);
              p.width:=extent.rbearing;
              p.height:=p.font.height;
              p.offset:=0;

              IF (last=NIL) OR ~(last IS TextPart) THEN
                p.offset:=extent.lbearing;
                DEC(p.width,extent.lbearing);
              END;

              IF p.next=NIL THEN
                DEC(p.width,extent.rbearing-extent.width);
              END;

              IF (smart IN p.style)(* OR (G.canDisable IN t.flags)*) THEN
                INC(p.height);
                INC(p.width);
              END;

              INC(tSize,p.width);

        | p : TabPart DO
              INC(tSize,mSize);
              p.height:=0; (*font.height;*)

              IF tSize>t.tabList[tabCount] THEN
                t.tabList[tabCount]:=tSize;
              END;

              tSize:=0;
              INC(tabCount);

        | p : ImagePart DO
              p.height:=p.image.height;
              p.width:=p.image.width+2*D.display.spaceWidth;
        END;

        INC(l.width,p.width);

        last:=p;
        p:=p.next;
      END;

      l:=l.next;
    END;

    l:=t.textList;
    WHILE l#NIL DO

      l.width:=0;
      IF l.parts#NIL THEN
        l.height:=0;
      ELSE
        l.height:=D.normalFont.height;
      END;

      tabCount:=0;
      tSize:=0;
      p:=l.parts;
      WHILE p#NIL DO

        WITH

          p : TextPart DO
              INC(tSize,p.width);

        | p : TabPart DO
              p.width:=t.tabList[tabCount]-tSize+1;

              tSize:=0;
              INC(tabCount);

        | p : ImagePart DO
              INC(tSize,p.width);

        END;

        INC(l.width,p.width);
        IF p.height>l.height THEN
          l.height:=p.height;
        END;

        p:=p.next;
      END;

      IF l.width>t.textWidth THEN
        t.textWidth:=l.width;
      END;

      INC(t.textHeight,l.height);

      l:=l.next;
    END;

    INC(t.textHeight,(t.lines-1)*t.lineSpace);

  END CalcTextSize;

  (* --------------------------------------------------------- *)

  PROCEDURE (t : Text) SetString*(text : STRING);

    (**
      Parses text and builds up TextClass.textList
    *)

  VAR
    start,
    stop,
    pos    : LONGINT;

  BEGIN
    start:=0;
    stop:=0;
    pos:=0;
    t.lines:=0;
    t.textList:=NIL;
    t.lastLine:=NIL;
    t.currentLine:=NIL;
    t.currentJust:=t.defaultJust;
    t.currentStyle:=t.defaultDraw;
    t.currentFont:=t.defaultFont;
    t.tabList:=NIL;

    t.NewLine;

    LOOP
      IF pos>=text.length THEN
        stop:=pos-1;
        t.AddTextToPart(text,start,stop);
        t.CloseLine;
        EXIT;
      END;

      CASE text.CharAt(pos) OF
      | EOT : stop:=pos-1;
              t.AddTextToPart(text,start,stop);
              t.CloseLine;
              EXIT;
      | "\" : stop:=pos-1;
              INC(pos);

              IF pos>=text.length THEN
                stop:=pos-1;
                t.AddTextToPart(text,start,stop);
                t.CloseLine;
                EXIT;
              END;

              CASE text.CharAt(pos) OF
                "\" :
                t.AddTextToPart(text,start,stop+1);
              | "n" :
                t.AddTextToPart(text,start,stop);
                t.CloseLine;
                t.NewLine;
                start:=pos+1;
              | "e" :
                IF stop>=start THEN
                  t.AddTextToPart(text,start,stop);
                  t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
                END;

                INC(pos);

                CASE text.CharAt(pos) OF

                | NORMAL:
                  t.currentStyle:={};
                  t.currentLine.SetStyle(t.currentStyle);
                | BOLD:
                  INCL(t.currentStyle,D.bold);
                  t.currentLine.SetStyle(t.currentStyle);
                | ITALIC:
                  INCL(t.currentStyle,D.italic);
                  t.currentLine.SetStyle(t.currentStyle);
                | SLANTED:
                  INCL(t.currentStyle,D.slanted);
                  t.currentLine.SetStyle(t.currentStyle);
                | UNDERLINED:
                  INCL(t.currentStyle,D.underlined);
                  t.currentLine.SetStyle(t.currentStyle);
                | SMART:
                  IF D.display.displayType#D.displayTypeTextual THEN
                    INCL(t.currentStyle,smart);
                    t.currentLine.SetStyle(t.currentStyle);
                  END;
                | HIGHLIGHT:
                  INCL(t.currentStyle,highlight);
                  t.currentLine.SetStyle(t.currentStyle);
                | WARN:
                  INCL(t.currentStyle,warn);
                  t.currentLine.SetStyle(t.currentStyle);

                | LEFT:
                  t.SetJustification(leftAlligned);
                | RIGHT:
                  t.SetJustification(rightAlligned);
                | CENTERED:
                  t.SetJustification(centered);

                | RETURNI:
                  IF D.display.displayType#D.displayTypeTextual THEN
                    t.currentLine.NewImagePart(t.prefs(Prefs).return);
                    t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
                  END;
                | ESCAPE:
                  IF D.display.displayType#D.displayTypeTextual THEN
                    t.currentLine.NewImagePart(t.prefs(Prefs).escape);
                    t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
                  END;
                | DEFAULT:
                  IF D.display.displayType#D.displayTypeTextual THEN
                    t.currentLine.NewImagePart(t.prefs(Prefs).default);
                    t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
                  END;

                | FIXED:
                  t.currentFont:=D.fixedFont;
                  t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
                | PROP:
                  t.currentFont:=D.normalFont;
                  t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
                | "0".."9":
                  t.currentFont:=GetFont(ORD(text.CharAt(pos))-ORD("0"));
                  t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
                ELSE
                  t.AddTextToPart(text,pos,pos);
                  t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
                END;

                start:=pos+1;

              | "t" :
                IF stop>=start THEN
                  t.AddTextToPart(text,start,stop);
                  t.currentLine.NewTextPart(t.currentStyle,t.currentFont);
                END;
                start:=pos+1; (* skip next char *)
                t.currentLine.NewTabPart(t);
                t.currentLine.NewTextPart(t.currentStyle,t.currentFont);

              ELSE
                (* Wer are skipping "normal" characters *)
              END;
      ELSE
      END;
      INC(pos);
    END;

    IF t.calced THEN
      t.CalcTextSize;
      IF t.visible THEN
        t.Redraw;
      END;
    END;
  END SetString;

  PROCEDURE (t : Text) SetText*(text : ARRAY OF CHAR);

  BEGIN
    t.SetString(Object.NewLatin1(text));
  END SetText;

  PROCEDURE (t : Text) SetLongText*(text : ARRAY OF LONGCHAR);

  BEGIN
    t.SetString(Object.NewUTF16(text));
  END SetLongText;

  (* --------------------------------------------------------- *)

  PROCEDURE (t : Text) SetDefaultFont*(drawMode : SET; font : D.Font);

    (**
      The default draw mode and font to use. These settings can be overwritten
      later on by in-text format escape sequences.
    *)

  BEGIN
    t.defaultDraw:=drawMode;
    t.defaultFont:=font;
  END SetDefaultFont;

  PROCEDURE (t : Text) SetDefaultAdjustment*(adjustment : SHORTINT);

    (**
      The default adjustment for the text assigned to use. These settings can
      be overwritten later on by in-text format escape sequences.
    *)

  BEGIN
    t.defaultJust:=adjustment;
  END SetDefaultAdjustment;

  PROCEDURE (t : Text) SetDefault*(adjustment : SHORTINT; drawMode : SET; font : D.Font);

    (**
      Depreceated! Use @oproc{Text.SetDefaultFont} or
      @oproc{Text.SetDefaultAdjustment} instead!
    *)

  BEGIN
    t.defaultJust:=adjustment;
    t.defaultDraw:=drawMode;
    t.defaultFont:=font;
  END SetDefault;

  (* --------------------------------------------------------- *)


  PROCEDURE (t : Text) CalcSize*;

  BEGIN
    t.CalcTextSize;

    t.calced:=TRUE;
    t.width:=t.textWidth;
    t.height:=t.textHeight;
    t.minWidth:=t.textWidth;
    t.minHeight:=t.textHeight;

    t.CalcSize^;
  END CalcSize;

  (* --------------------------------------------------------- *)

  (*
    Draws the text in TextClass.textList based upon the calculations of
    TextClass.CalcSize in the given window
  *)

  PROCEDURE (t : Text) Draw*(x,y,w,h : LONGINT);

  VAR
    l     : Line;
    p     : Part;

    xPos  : LONGINT;
    yPos,
    y2    : LONGINT;

    frame : F.Frame;

    draw  : D.DrawInfo;

  BEGIN
    IF ~t.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    t.Draw^(x,y,w,h);

    draw:=t.GetDrawInfo();

    IF t.DisplayFocus() & (D.display.displayType=D.displayTypeTextual) THEN
      draw.PushForeground(D.fillColor);
      draw.FillRectangle(t.x,t.y,t.width,t.height);
      draw.PopForeground;
    ELSE
      t.DrawBackground(t.x,t.y,t.width,t.height);
    END;

    IF t.DisplayFocus() & (D.display.displayType=D.displayTypeTextual) THEN
      draw.PushForeground(D.fillTextColor);
    ELSIF (D.selected IN draw.mode) THEN
      draw.PushForeground(D.fillTextColor);
    ELSE
      draw.PushForeground(D.textColor);
    END;

    draw.InstallClip(t.x,t.y,t.width,t.height);

    yPos:=t.y;

    IF t.height>t.textHeight THEN
      INC(yPos,(t.height-t.textHeight) DIV 2);
    END;

    l:=t.textList;
    WHILE l#NIL DO

      CASE l.justification OF
      | leftAlligned  : xPos:=t.x;
      | rightAlligned : xPos:=t.x+t.width-t.textWidth+(t.textWidth-l.width);
      | centered      : xPos:=t.x+(t.width-t.textWidth) DIV 2 + (t.textWidth-l.width) DIV 2;
      ELSE
        xPos:=t.x;
      END;

      p:=l.parts;
      WHILE p#NIL DO

        WITH
          p : TextPart DO

            draw.PushFont(p.font,p.style);

            y2:=yPos+p.font.ascent;

            IF (t.disabled) OR (D.disabled IN draw.mode) THEN

              draw.PushForeground(D.halfShadowColor);
              draw.DrawStr(xPos-p.offset,y2,p.text);
              draw.PopForeground;
(*
                draw.PushForeground(D.halfShineColor);
                draw.DrawString(xPos-p.offset+1,y2+1,p.text^,p.Length());*)
(*              draw.PopForeground;*)

            ELSE

              IF highlight IN p.style THEN
                draw.PushForeground(D.whiteColor);
              ELSIF warn IN p.style THEN
                draw.PushForeground(D.warnColor);
              END;

              IF smart IN p.style THEN
                draw.DrawStr(xPos+1-p.offset,y2+1,p.text);
                draw.PushForeground(D.whiteColor);
                draw.DrawStr(xPos-p.offset,y2,p.text);
              ELSE
                draw.DrawStr(xPos-p.offset,y2,p.text);
              END;

              IF (smart IN p.style) OR (highlight IN p.style) OR (warn IN p.style) THEN
                draw.PopForeground;
              END;

            END;

            INC(xPos,p.width);

            draw.PopFont;

        | p : TabPart DO
            INC(xPos,p.width);

        | p : ImagePart DO
          p.image.Draw(draw,
                       xPos+(p.width-p.image.width) DIV 2,
                       yPos+(l.height-p.image.height) DIV 2,
                       p.image.width,
                       p.image.height);
        END;

        p:=p.next;
      END;

      INC(yPos,l.height+t.lineSpace);
      l:=l.next;
    END;

    IF t.DisplayFocus() & (D.display.displayType#D.displayTypeTextual) THEN
      IF t.focus=NIL THEN
        frame:=t.prefs(Prefs).focusFrame;
        t.SetFocusObject(frame);
      ELSE
        frame:=t.focus;
      END;

(*      IF (t.width>=t.textWidth+frame.leftBorder+frame.rightBorder+4)
      & (t.height>=t.textHeight+frame.topBorder+frame.bottomBorder+4) THEN
        frame.Draw(t.GetDrawInfo(),t.x+2,t.y+2,t.width-4,t.height-4);
      ELSE*)
      frame.Draw(t.GetDrawInfo(),t.x,t.y,t.width,t.height);
        (*      END;*)
    END;

    draw.FreeLastClip;
    draw.PopForeground;
  END Draw;

  PROCEDURE (t : Text) DrawFocus*;

  BEGIN
    t.SetFlags({G.showFocus});
    t.Redraw;
  END DrawFocus;

  PROCEDURE (t : Text) HideFocus*;

  BEGIN
    t.RemoveFlags({G.showFocus});
    t.Redraw;
  END HideFocus;

  PROCEDURE CreateText*():Text;

  VAR
    text : Text;

  BEGIN
    NEW(text);
    text.Init;

    RETURN text;
  END CreateText;

  PROCEDURE MakeLeftText*(string : ARRAY OF CHAR):Text;

  VAR
    text : Text;

  BEGIN
    text:=CreateText();
    text.SetFlags({G.horizontalFlex,G.verticalFlex});
    text.SetText(string);
    RETURN text;
  END MakeLeftText;

  PROCEDURE MakeCenterText*(string : ARRAY OF CHAR):Text;

  VAR
    text : Text;

  BEGIN
    text:=CreateText();
    text.SetFlags({G.horizontalFlex,G.verticalFlex});
    text.SetDefault(centered,{},D.normalFont);
    text.SetText(string);
    RETURN text;
  END MakeCenterText;

  PROCEDURE MakeLeftString*(string : STRING):Text;

  VAR
    text : Text;

  BEGIN
    text:=CreateText();
    text.SetFlags({G.horizontalFlex,G.verticalFlex});
    text.SetString(string);
    RETURN text;
  END MakeLeftString;

  PROCEDURE MakeCenterString*(string : STRING):Text;

  VAR
    text : Text;

  BEGIN
    text:=CreateText();
    text.SetFlags({G.horizontalFlex,G.verticalFlex});
    text.SetDefault(centered,{},D.normalFont);
    text.SetString(string);
    RETURN text;
  END MakeCenterString;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Text.