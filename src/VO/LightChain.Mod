MODULE VO:LightChain;

  (**
    Implements @otype{LightChain}.
  *)

  (*
    Implements a onszilloskope-like object.
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

IMPORT s   := SYSTEM,

       BG  := VO:Base:Background,
       D   := VO:Base:Display,
       F   := VO:Base:Frame,
       O   := VO:Base:Object,
       Z   := VO:Base:Size,

       G   := VO:Object;

CONST
  (* Do not change this! *)
  charWidth*  = 8;
  charHeight* = 8;

  blinkPeriod = 80; (* half a scond *)

TYPE
  Prefs*     = POINTER TO PrefsDesc;
  PrefsDesc* = RECORD (G.PrefsDesc)
                 radius*,
                 space*   : Z.SizeDesc;
               END;

  Points = POINTER TO ARRAY OF BOOLEAN;

  Character* = ARRAY charWidth,charHeight OF BOOLEAN;
  CharStore* = ARRAY 2 OF LONGINT;
  Font*      = ARRAY 256 OF Character;

  LightChain*     = POINTER TO LightChainDesc;
  LightChainDesc* = RECORD (G.ImageDesc)
                      (**
                        Emulates a horizotal text scrolling area, consisting
                        of a matrix of small leds. Letters (patterns) are
                        created by switching on/off individual lights.

                        It uses it own internal charset that is a small subset
                        of ASCII-US. Small and capital letters are maped onto
                        the same character. Some special characters are
                        supported.

                        Some special effect are implemented but not currently
                        activated and acessible. It is planed to define some
                        state list that enables you to program a series of
                        multiple texts and effects in a speical order. But
                        nothing of that is implemented.
                      *)
                      radius,
                      space,
                      letters  : LONGINT;
                      points   : ARRAY charHeight OF Points;
                      text     : STRING;
                      pos      : LONGINT;
                      bit      : LONGINT;
                      timer    : D.Timer;
                      onColor,
                      offColor,
                      backColor: D.Color;
                    END;

VAR
  font1- : Font;
  store  : CharStore;

  prefs* : Prefs;

  PROCEDURE InitChar(VAR font : Font; letter : CHAR; store : CharStore);

  VAR
    x,y,set,div,bit,one : LONGINT;

  BEGIN
    FOR y:=0 TO charHeight-1 DO
      FOR x:=0 TO charWidth-1 DO
        set:=(y*charWidth+x) DIV (SIZE(LONGINT)*8);
        bit:=(y*charWidth+x) MOD (SIZE(LONGINT)*8);
        one:=1;
        div:=s.LSH(one,31-bit);
        IF div<0 THEN
          div:=s.LSH(one,31-bit-1);
          font[ORD(letter)][charWidth-1-x,y]:=((store[set] DIV 2) DIV div) MOD 2#0;
        ELSE
          font[ORD(letter)][charWidth-1-x,y]:=(store[set] DIV div) MOD 2#0;
        END;
      END;
    END;
  END InitChar;

  PROCEDURE (p : Prefs) Initialize*;

  BEGIN
    p.Initialize^;

    p.background:=BG.CreateBackgroundByFill(BG.CreatePlainFillByColorIndex(D.blackColorIndex));

    IF D.display.displayType=D.displayTypeTextual THEN
      p.frame:=F.CreateFrame(F.single);
    ELSE
      p.frame:=F.CreateFrame(F.double3DIn);
    END;

    p.radius.Init;
    p.space.Init;

    p.radius.SetSize(Z.unitP,100);
    p.space.SetSize(Z.unitP,25);
  END Initialize;


  PROCEDURE (l : LightChain) Init*;

  VAR
    x,y : LONGINT;

  BEGIN
    l.Init^;

    l.SetPrefs(prefs);

    FOR y:=0 TO charHeight-1 DO
      NEW(l.points[y],charWidth);
      FOR x:=0 TO charHeight-1 DO
        l.points[y][x]:=FALSE;
      END;
    END;

    l.letters:=1;

    l.text:="*";
    l.pos:=0;
    l.bit:=0;

    l.radius:=0;
    l.space:=0;

    l.onColor:=D.warnColor;
    l.offColor:=D.shadowColor;
    l.backColor:=D.blackColor;

    l.timer:=D.factory.CreateTimer();
    l.timer.SetSecs(0,blinkPeriod);
    l.timer.SetObject(l);
  END Init;

  PROCEDURE (l : LightChain) SetText*(text : STRING);
    (**
      Set the text to be displayed in the display. The text will permanently
      be scrolled in from right to left. Setting a new text will imediately take
      place by cutting the currently set text and start witht he new text,
    *)

  VAR
    x,y : LONGINT;

  BEGIN
    IF l.text.Equals(text) THEN
      RETURN;
    END;

    l.text:=text;
    l.pos:=0;
    l.bit:=0;

    FOR y:=0 TO charHeight-1 DO
      FOR x:=0 TO charHeight-1 DO
        l.points[y][x]:=FALSE;
      END;
    END;
  END SetText;

  PROCEDURE (l : LightChain) CalcSize*;

  BEGIN
    IF D.display.colorMode=D.monochromeMode THEN
      l.onColor:=D.blackColor;
      l.offColor:=D.whiteColor;
      l.backColor:=D.whiteColor;
    END;

    l.radius:=l.prefs(Prefs).radius.GetSize();
    l.space:=l.prefs(Prefs).space.GetSize();

    l.width:=charWidth*l.radius + (charWidth-1)*l.space;
    l.height:=charHeight*l.radius + (charHeight-1)*l.space;

    l.minWidth:=l.width;
    l.minHeight:=l.height;

    l.CalcSize^;
  END CalcSize;

  PROCEDURE (l : LightChain) Readapt(letters : LONGINT);
    (**
      Refresh internal datatstructures after an resize peration.
    *)

  VAR
    help  : ARRAY charHeight OF Points;
    x,y,h : LONGINT;

  BEGIN
    l.letters:=letters;

    FOR y:=0 TO charHeight-1 DO
      NEW(help[y],l.letters*charWidth);
      FOR x:=0 TO l.letters*charWidth-1 DO
        help[y][x]:=FALSE;
      END;
    END;

    (* copying *)

    FOR y:=0 TO charHeight-1 DO
      IF LEN(l.points[y]^)<=l.letters*charWidth THEN
        x:=0;
        h:=l.letters*charWidth-LEN(l.points[y]^);
        WHILE x<LEN(l.points[y]^) DO
          help[y][h]:=l.points[y][x];
          INC(x);
          INC(h);
        END;
      ELSE
        FOR x:=0 TO l.letters*charWidth-1 DO
          help[y][x]:=l.points[y][x+LEN(l.points[0]^)-l.letters*charWidth];
        END;
      END;
    END;

    FOR y:=0 TO charHeight-1 DO
      l.points[y]:=help[y];
    END;
  END Readapt;

  PROCEDURE (l : LightChain) Resize*(width,height : LONGINT);

  VAR
    w,letters : LONGINT;

  BEGIN
    IF (width>l.oMinWidth) & (width<l.oMaxWidth) THEN
      letters:=(width-l.objectFrame.leftBorder-l.objectFrame.rightBorder)
      DIV (charWidth*l.radius+(charWidth-1)*l.space);
      w:=letters*(charWidth*(l.radius+l.space));
      INC(w,l.objectFrame.leftBorder+l.objectFrame.rightBorder);
      l.Resize^(w,height);

      IF letters#l.letters THEN
        l.Readapt(letters);
      END;
    END;
  END Resize;

  PROCEDURE (l : LightChain) DrawPoint(x,y : LONGINT);

  VAR
    draw : D.DrawInfo;

  BEGIN
    draw:=l.GetDrawInfo();

    IF l.points[y][x] THEN
      draw.PushForeground(l.onColor);
    ELSE
      draw.PushForeground(l.offColor);
    END;
    draw.FillArc(l.x+x*(l.radius+l.space),
                 l.y+y*(l.radius+l.space),
                 l.radius,l.radius,0,360*64);
    draw.PopForeground;
  END DrawPoint;

  PROCEDURE (l : LightChain) Scroll;
    (**
      Scroll the display one character to the left.
    *)

  VAR
    x,y    : LONGINT;
    redraw : BOOLEAN;

  BEGIN
    IF l.letters>1 THEN
      FOR x:=0 TO (l.letters-1)*charWidth-1 DO
        FOR y:=0 TO charHeight-1 DO
          redraw:=l.points[y][x]#l.points[y][x+charWidth];
          l.points[y][x]:=l.points[y][x+charWidth];
          IF l.visible & redraw THEN
            l.DrawPoint(x,y);
          END;
        END;
      END;
    END;
  END Scroll;

  PROCEDURE (l : LightChain) Invert;
    (**
      Invert the display.
    *)

  VAR
    x,y : LONGINT;

  BEGIN
    FOR x:=0 TO l.letters*charWidth-1 DO
      FOR y:=0 TO charHeight-1 DO
        l.points[y][x]:=~l.points[y][x];
        IF l.visible THEN
          l.DrawPoint(x,y);
        END;
      END;
    END;
  END Invert;

  PROCEDURE (l : LightChain) SoftScroll;
    (**
      Scroll the display one pixel to the left.
    *)

  VAR
    x,y    : LONGINT;
    redraw : BOOLEAN;
(*    draw   : D.DrawInfo;*)

  BEGIN

    FOR x:=0 TO l.letters*charWidth-2 DO
      FOR y:=0 TO charHeight-1 DO
        redraw:=l.points[y][x]#l.points[y][x+1];
        l.points[y][x]:=l.points[y][x+1];
        IF l.visible & redraw THEN
          l.DrawPoint(x,y);
        END;
      END;
      (* Clear last vertical line *)
    END;
(*    IF l.visible THEN
      draw:=l.GetDrawInfo();

      draw.CopyArea(l.x+l.radius+l.space,
                    l.y,
                    l.width-l.radius-l.space,
                    l.height,
                    l.x,
                    l.y);
    END;*)
  END SoftScroll;

  PROCEDURE (l : LightChain) AddChar(char : Character; bit : LONGINT);
    (**
      Scroll the display one pixel left if needed and add the given row of the
      given character to the display.
    *)

  VAR
    y : LONGINT;

  BEGIN
    l.SoftScroll;

    FOR y:=0 TO charHeight-1 DO
      l.points[y][l.letters*charWidth-1]:=char[bit,y];
      IF l.visible THEN
        l.DrawPoint(l.letters*charWidth-1,y);
      END;
    END;
  END AddChar;

  PROCEDURE (l : LightChain) Draw*(x,y,w,h : LONGINT);

  VAR
   a,b  : LONGINT;
   draw : D.DrawInfo;

  BEGIN
    IF ~l.Intersect(x,y,w,h) THEN
      RETURN;
    END;

    l.Draw^(x,y,w,h);

    draw:=l.GetDrawInfo();

    l.DrawBackground(l.x,l.y,l.width,l.height);

    FOR a:=0 TO LEN(l.points[0]^)-1 DO
      FOR b:=0 TO charHeight-1 DO
        l.DrawPoint(a,b);
      END;
    END;

    IF ~l.timer.active THEN
      D.display.AddTimer(l.timer);
    END;
  END Draw;

  PROCEDURE (l : LightChain) Hide*;

  BEGIN
    IF l.timer.active THEN
      D.display.RemoveTimer(l.timer);
    END;

    IF l.visible THEN
      l.Hide^;
    END;
  END Hide;

  PROCEDURE (l : LightChain) Receive*(msg : O.Message);

  BEGIN
    WITH msg:
      D.TimerMsg DO
        IF l.visible THEN
          l.AddChar(font1[ORD(l.text.CharAt(l.pos))],l.bit);
          INC(l.bit);
          IF l.bit>=charWidth THEN
            l.bit:=0;
            INC(l.pos);
            IF l.pos>=l.text.length THEN
              l.pos:=0;
              l.bit:=0;
            END;
          END;
          D.display.AddTimer(l.timer);
        END;
    ELSE
    END;
  END Receive;

  PROCEDURE CreateLightChain*():LightChain;

    (**
      Creates a new instance of @otype{LightChain}.
    *)

  VAR
    lightChain : LightChain;

  BEGIN
    NEW(lightChain);
    lightChain.Init;

    RETURN lightChain;
  END CreateLightChain;

BEGIN

  NEW(prefs);
  prefs.Init;

  (*
    A number of characters
  *)

  store[0]:=008080808H;
  store[1]:=008080008H;
  InitChar(font1,"!",store);

  store[0]:=01B1B0000H;
  store[1]:=000000000H;
  InitChar(font1,CHR(34),store);

  store[0]:=0227F2222H;
  store[1]:=0227F2200H;
  InitChar(font1,"#",store);

  store[0]:=0083C0A1CH;
  store[1]:=0281E0800H;
  InitChar(font1,"$",store);

  store[0]:=046261008H;
  store[1]:=004323100H;
  InitChar(font1,"%",store);

  store[0]:=01C36166EH;
  store[1]:=03B336E00H;
  InitChar(font1,"&",store);

  store[0]:=006060300H;
  store[1]:=000000000H;
  InitChar(font1,"'",store);

  store[0]:=004020101H;
  store[1]:=001020400H;
  InitChar(font1,"(",store);

  store[0]:=010204040H;
  store[1]:=040201000H;
  InitChar(font1,")",store);

  store[0]:=0492A1C7FH;
  store[1]:=01C2A4900H;
  InitChar(font1,"*",store);

  store[0]:=00808087FH;
  store[1]:=008080800H;
  InitChar(font1,"+",store);

  store[0]:=000000000H;
  store[1]:=000020201H;
  InitChar(font1,",",store);

  store[0]:=00000007FH;
  store[1]:=000000000H;
  InitChar(font1,"-",store);

  store[0]:=000000000H;
  store[1]:=000030300H;
  InitChar(font1,".",store);

  store[0]:=040201008H;
  store[1]:=004020100H;
  InitChar(font1,"/",store);

  store[0]:=03E615149H;
  store[1]:=045433E00H;
  InitChar(font1,"0",store);

  store[0]:=00C0F0C0CH;
  store[1]:=00C0C3F00H;
  InitChar(font1,"1",store);

  store[0]:=01E33301CH;
  store[1]:=006033F00H;
  InitChar(font1,"2",store);

  store[0]:=03F40403FH;
  store[1]:=040403F00H;
  InitChar(font1,"3",store);

  store[0]:=020302824H;
  store[1]:=07E202000H;
  InitChar(font1,"4",store);

  store[0]:=07F01013FH;
  store[1]:=040403F00H;
  InitChar(font1,"5",store);

  store[0]:=03E01013FH;
  store[1]:=041413E00H;
  InitChar(font1,"6",store);

  store[0]:=07F201008H;
  store[1]:=004020100H;
  InitChar(font1,"7",store);

  store[0]:=03E41413EH;
  store[1]:=041413E00H;
  InitChar(font1,"8",store);

  store[0]:=03E41417EH;
  store[1]:=040403E00H;
  InitChar(font1,"9",store);

  store[0]:=000030300H;
  store[1]:=000030300H;
  InitChar(font1,":",store);

  store[0]:=000060600H;
  store[1]:=000060602H;
  InitChar(font1,";",store);

  store[0]:=008040201H;
  store[1]:=002040800H;
  InitChar(font1,"<",store);

  store[0]:=000007F00H;
  store[1]:=0007F0000H;
  InitChar(font1,"=",store);

  store[0]:=008102040H;
  store[1]:=020100800H;
  InitChar(font1,">",store);

  store[0]:=01E212018H;
  store[1]:=004000400H;
  InitChar(font1,"?",store);

  store[0]:=03E415D65H;
  store[1]:=07D013E00H;
  InitChar(font1,"@",store);

  store[0]:=03E41417FH;
  store[1]:=041414100H;
  InitChar(font1,"a",store);
  InitChar(font1,"A",store);

  store[0]:=03F41413FH;
  store[1]:=041413F00H;
  InitChar(font1,"b",store);
  InitChar(font1,"B",store);

  store[0]:=07E010101H;
  store[1]:=001017E00H;
  InitChar(font1,"c",store);
  InitChar(font1,"C",store);

  store[0]:=03F414141H;
  store[1]:=041413F00H;
  InitChar(font1,"d",store);
  InitChar(font1,"D",store);

  store[0]:=07F01013FH;
  store[1]:=001017F00H;
  InitChar(font1,"e",store);
  InitChar(font1,"E",store);

  store[0]:=07F01011FH;
  store[1]:=001010100H;
  InitChar(font1,"f",store);
  InitChar(font1,"F",store);

  store[0]:=03E010131H;
  store[1]:=041413E00H;
  InitChar(font1,"g",store);
  InitChar(font1,"G",store);

  store[0]:=04141417FH;
  store[1]:=041414100H;
  InitChar(font1,"h",store);
  InitChar(font1,"H",store);

  store[0]:=03E080808H;
  store[1]:=008083E00H;
  InitChar(font1,"i",store);
  InitChar(font1,"I",store);

  store[0]:=078404040H;
  store[1]:=04042423CH;
  InitChar(font1,"j",store);
  InitChar(font1,"J",store);

  store[0]:=021110907H;
  store[1]:=009112100H;
  InitChar(font1,"k",store);
  InitChar(font1,"K",store);

  store[0]:=001010101H;
  store[1]:=001017F00H;
  InitChar(font1,"l",store);
  InitChar(font1,"L",store);

  store[0]:=041635549H;
  store[1]:=041414100H;
  InitChar(font1,"m",store);
  InitChar(font1,"M",store);

  store[0]:=041434549H;
  store[1]:=051614100H;
  InitChar(font1,"n",store);
  InitChar(font1,"N",store);

  store[0]:=03E414141H;
  store[1]:=041413E00H;
  InitChar(font1,"o",store);
  InitChar(font1,"O",store);

  store[0]:=03F41413FH;
  store[1]:=001010100H;
  InitChar(font1,"p",store);
  InitChar(font1,"P",store);

  store[0]:=03E414141H;
  store[1]:=041513E40H;
  InitChar(font1,"q",store);
  InitChar(font1,"Q",store);

  store[0]:=03F41413FH;
  store[1]:=011214100H;
  InitChar(font1,"r",store);
  InitChar(font1,"R",store);

  store[0]:=07E01013EH;
  store[1]:=040403F00H;
  InitChar(font1,"s",store);
  InitChar(font1,"S",store);

  store[0]:=07F080808H;
  store[1]:=008080800H;
  InitChar(font1,"t",store);
  InitChar(font1,"T",store);

  store[0]:=041414141H;
  store[1]:=041413E00H;
  InitChar(font1,"u",store);
  InitChar(font1,"U",store);

  store[0]:=041412222H;
  store[1]:=014140800H;
  InitChar(font1,"v",store);
  InitChar(font1,"V",store);

  store[0]:=041414149H;
  store[1]:=055634100H;
  InitChar(font1,"w",store);
  InitChar(font1,"W",store);

  store[0]:=041221408H;
  store[1]:=014224100H;
  InitChar(font1,"x",store);
  InitChar(font1,"X",store);

  store[0]:=041221408H;
  store[1]:=008080800H;
  InitChar(font1,"y",store);
  InitChar(font1,"Y",store);

  store[0]:=07F201008H;
  store[1]:=004027F00H;
  InitChar(font1,"z",store);
  InitChar(font1,"Z",store);

  store[0]:=007010101H;
  store[1]:=001010700H;
  InitChar(font1,"[",store);

  store[0]:=001020408H;
  store[1]:=010204000H;
  InitChar(font1,"\",store);

  store[0]:=070404040H;
  store[1]:=040407000H;
  InitChar(font1,"]",store);

  store[0]:=008142241H;
  store[1]:=000000000H;
  InitChar(font1,"^",store);

  store[0]:=000000000H;
  store[1]:=00000007FH;
  InitChar(font1,"_",store);

  store[0]:=003030600H;
  store[1]:=000000000H;
  InitChar(font1,"`",store);

  store[0]:=004020201H;
  store[1]:=002020400H;
  InitChar(font1,"{",store);

  store[0]:=001010101H;
  store[1]:=001010100H;
  InitChar(font1,"|",store);

  store[0]:=010202040H;
  store[1]:=020201000H;
  InitChar(font1,"}",store);

  store[0]:=026190000H;
  store[1]:=000000000H;
  InitChar(font1,"~",store);

  store[0]:=055AA55AAH;
  store[1]:=055AA55AAH;
  InitChar(font1,"",store);

END VO:LightChain.