MODULE VO:Prefs:Display;

(*
    Copyright (C) 1999 Tim Teulings (rael@edge.ping.de)

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

IMPORT D     := VO:Base:Display,
       Z     := VO:Base:Size,

       V     := VO:Model:Value,

       PG    := VO:Prefs:GUI,
       PP    := VO:Prefs:Parser,

       C     := VO:ColorArea,
       G     := VO:Object,
       LA    := VO:Label,
       SL    := VO:Slider,
       ST    := VO:String,
       T     := VO:Text,
       TA    := VO:Tab,

       Codec := XML:UnicodeCodec,
<* PUSH; Warnings:=FALSE *>
                XML:UnicodeCodec:Latin1,
                Latin9,
<* POP *>
                Err,
       co    := IntStr,
                Object,
       str   := Strings;

TYPE
  DisplayItem*     = POINTER TO DisplayItemDesc;
  DisplayItemDesc* = RECORD (PG.PrefsItemDesc)
                       contextTimer : V.ValueModel;
                     END;

VAR
  prefs : DisplayItem;

  PROCEDURE (d : DisplayItem) Init*;

  BEGIN
    d.Init^;
    d.SetName("Display");

    d.contextTimer:=V.CreateIntModel();
  END Init;

  PROCEDURE (d : DisplayItem) GetObject*():G.Object;

  VAR
    tab    : TA.Tab;
    label  : LA.Label;
    area   : C.ColorArea;
    slider : SL.Slider;
    string : ST.String;
    model  : V.ValueModel;
    x      : LONGINT;
    tmp,
    tmp2   : ARRAY 1024 OF CHAR;

  BEGIN
    NEW(tab);
    tab.Init;
    tab.SetFlags({G.horizontalFlex,G.verticalFlex});
    tab.RequestFocus;

      label:=LA.CreateLabel();
      label.SetFlags({G.horizontalFlex,G.verticalFlex});

        NEW(model);
        model.Init;
        model.SetString(Object.NewLatin1(D.prefs.theme));

        string:=ST.CreateString();
        string.Disable(TRUE);
        string.SetFlags({G.horizontalFlex});
        string.SetModel(model);
      label.AddStringLabel("Theme",string);
    tab.AddTab(T.MakeCenterText("Theme"),label);

      label:=LA.CreateLabel();
      label.SetFlags({G.horizontalFlex,G.verticalFlex});

      FOR x:=0 TO LEN(D.colorNames)-1 DO
        NEW(model);
        model.Init;
        model.SetString(Object.NewLatin1(D.prefs.colors[x]));

          area:=C.CreateColorArea();
          area.SetFlags({G.horizontalFlex,G.verticalFlex});
          area.SetColor(D.GetColorByName(D.colorNames[x]));
        label.AddStringLabel(Object.NewLatin1(D.colorNames[x]),area);
      END;

    tab.AddTab(T.MakeCenterText("Colors"),label);

      label:=LA.CreateLabel();
      label.SetFlags({G.horizontalFlex,G.verticalFlex});

      FOR x:=0 TO LEN(D.fontNames)-1 DO
        NEW(model);
        model.Init;
        tmp:="";
        IF D.prefs.fonts[x]#NIL THEN
          IF D.prefs.fonts[x].name#NIL THEN
            COPY(D.prefs.fonts[x].name^,tmp);
            str.Append(",",tmp);
          END;
          co.IntToStr(D.prefs.fonts[x].pixelHeight,tmp2);
          str.Append(tmp2,tmp);
        END;

        model.SetString(Object.NewLatin1(tmp));

        string:=ST.CreateString();
        string.Disable(TRUE);
        string.SetFlags({G.horizontalFlex});
        string.SetModel(model);

        label.AddStringLabel(Object.NewLatin1(D.fontNames[x]),string);
      END;

    tab.AddTab(T.MakeCenterText("Fonts"),label);

      label:=LA.CreateLabel();
      label.SetFlags({G.horizontalFlex,G.verticalFlex});

        slider:=SL.CreateHSlider();
        slider.SetFlags({G.horizontalFlex});
        slider.SetMinWidth(Z.unit,20);
        slider.SetRange(5,50);
        slider.SetModel(d.contextTimer);
      label.AddStringLabel("QuickHelp (1/10 sec.)",slider);

    tab.AddTab(T.MakeCenterText("Timers"),label);

    RETURN tab;
  END GetObject;

  PROCEDURE (d : DisplayItem) Refresh*;

  BEGIN
    d.Refresh^;

    d.contextTimer.SetLongint(D.prefs.contextTimer DIV 100);
  END Refresh;

  PROCEDURE (p : DisplayItem) Apply*;

  BEGIN
    p.Apply^;

    D.prefs.contextTimer:=p.contextTimer.GetLongint()*100;
  END Apply;

  PROCEDURE LoadColor*(top : PP.Item; name : ARRAY OF CHAR; VAR color : ARRAY OF CHAR);

  VAR
    item : PP.Item;

  BEGIN
    item:=top.GetSubEntry("Color","name",name);
    IF item#NIL THEN
      IF item.GetStringEntry("value",color) THEN
      END;
    END;
  END LoadColor;

  PROCEDURE LoadFont*(top : PP.Item; name : ARRAY OF CHAR; VAR font : D.Font);

  VAR
    item   : PP.Item;
    buffer : ARRAY 1024 OF CHAR;

  BEGIN
    item:=top.GetSubEntry("Font","type",name);
    IF (item#NIL) & (font#NIL) THEN
      font.features:={};

      IF item.GetStringEntry("foundry",buffer) THEN
        NEW(font.foundry,str.Length(buffer)+1);
        COPY(buffer,font.foundry^);
        INCL(font.features,D.fontFoundry);
      END;

      IF item.GetStringEntry("name",buffer) THEN
        NEW(font.name,str.Length(buffer)+1);
        COPY(buffer,font.name^);
        INCL(font.features,D.fontName);
      END;

      font.pixelHeight:=-1;
      font.pixelHeight:=item.GetIntEntry("size",font.pixelHeight);
      IF font.pixelHeight>0 THEN
        INCL(font.features,D.fontHeight);
      END;
    END;
  END LoadFont;

  PROCEDURE SaveFont*(top : PP.Item; name : ARRAY OF CHAR; font : D.Font);

  VAR
    block : PP.BlockItem;

  BEGIN
    IF font#NIL THEN

      block:=PP.CreateBlockItem("Font");
      block.AddItemValue("type",name);

      IF D.fontFoundry IN font.features THEN
        block.AddItemValue("foundry",font.foundry^);
      END;
      IF D.fontName IN font.features THEN
        block.AddItemValue("name",font.name^);
      END;
      IF D.fontHeight IN font.features THEN
        block.AddItemInt("size",font.pixelHeight);
      END;

      top.AddItem(block);
    END;
  END SaveFont;

  PROCEDURE (p : DisplayItem) LoadPrefs*(top : PP.Item);

  VAR
    x      : LONGINT;
    sub    : PP.Item;
    buffer : ARRAY 1024 OF CHAR;

  BEGIN
    sub:=top.GetEntry("LocaleCodec");
    IF sub#NIL THEN
      IF sub.GetStringEntry("name",buffer) THEN
        D.prefs.localeCodecFactory:=Codec.GetFactory(buffer);
      ELSE
        D.prefs.localeCodecFactory:=NIL;
      END;
    END;

    IF D.prefs.localeCodecFactory=NIL THEN
      Err.String("Configured locale codec '");
      Err.String(buffer);
      Err.String("' not found, falling back to ISO-8859-1!");
      Err.Ln;

      D.prefs.localeCodecFactory:=Codec.GetFactory("ISO-8859-1");
    END;

    ASSERT(D.prefs.localeCodecFactory#NIL);
    D.prefs.localeCodec:=D.prefs.localeCodecFactory.NewCodec();

    sub:=top.GetEntry("Fonts");
    IF sub#NIL THEN
      FOR x:=0 TO D.fontCount-1 DO
        LoadFont(sub,D.fontNames[x],D.prefs.fonts[x]);
      END;
    END;

    D.prefs.contextTimer:=top.GetIntEntry("contextTimer",D.prefs.contextTimer);

    D.prefs.theme:="";
    IF top.GetStringEntry("theme",D.prefs.theme) THEN END;
  END LoadPrefs;

  PROCEDURE (p : DisplayItem) LoadTheme*(top : PP.Item);

  VAR
    x   : LONGINT;
    sub : PP.Item;

  BEGIN
    p.LoadTheme^(top);

    sub:=top.GetEntry("Colors");
    IF sub#NIL THEN
      FOR x:=0 TO D.colorCount-1 DO
        LoadColor(sub,D.colorNames[x],D.prefs.colors[x]);
      END;
    END;
  END LoadTheme;

  PROCEDURE (p : DisplayItem) SavePrefs*(top : PP.BlockItem);

  VAR
    block  : PP.BlockItem;
    x      : LONGINT;
    buffer : ARRAY 1024 OF CHAR;

  BEGIN
    block:=PP.CreateBlockItem("LocaleCodec");
    D.prefs.localeCodecFactory.GetEncodingName(buffer);
    block.AddItemValue("name",buffer);
    top.AddItem(block);

    block:=PP.CreateBlockItem("Fonts");
    FOR x:=0 TO D.fontCount-1 DO
      SaveFont(block,D.fontNames[x],D.prefs.fonts[x]);
    END;
    top.AddItem(block);

    top.AddItemInt("contextTimer",D.prefs.contextTimer);
    top.AddItemValue("theme",D.prefs.theme);
  END SavePrefs;

BEGIN
  NEW(prefs);
  prefs.Init;
END VO:Prefs:Display.