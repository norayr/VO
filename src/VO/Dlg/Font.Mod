MODULE VO:Dlg:Font;

IMPORT D   := VO:Base:Display,
       O   := VO:Base:Object,
       Z   := VO:Base:Size,

              VO:Dlg:Msg,

       SM  := VO:Model:Selection,
       MT  := VO:Model:Table,
       MV  := VO:Model:Value,

       B   := VO:Button,
       BR  := VO:ButtonRow,
       G   := VO:Object,
       P   := VO:Panel,
       S   := VO:Space,
       ST  := VO:String,
       TB  := VO:Table,
       W   := VO:Window,
       WG  := VO:WindowGroup,

       co  := IntStr,
       str := Strings,Err;

TYPE
  Info*      = POINTER TO InfoDesc;
  InfoDesc*  = RECORD
                 unicodeOnly- : BOOLEAN;
               END;


  Foundry      = POINTER TO FoundryDesc;
  FoundryDesc  = RECORD (MT.ListEntryDesc)
                   family  : D.FontFamily;
                   foundry : D.FontFoundry;
                 END;

  Encoding     = POINTER TO EncodingDesc;
  EncodingDesc = RECORD (MT.ListEntryDesc)
                   encoding  : D.FontEncoding;
                 END;

  Size         = POINTER TO SizeDesc;
  SizeDesc     = RECORD (MT.ListEntryDesc)
                   size   : D.FontSize;
                   pixel : LONGINT;
                 END;

  Font*        = POINTER TO FontDesc;
  FontDesc*    = RECORD (W.WindowDesc)
                   info      : Info;

                   testText  : MV.ValueModel;

                   fModel,
                   eModel,
                   sModel    : MT.LTableModel;

                   fTable,
                   eTable,
                   sTable    : TB.Table;

                   string    : ST.String;

                   family    : D.FontFamily;
                   foundry   : D.FontFoundry;
                   encoding  : D.FontEncoding;
                   size      : Size;

                   font      : D.Font;

                   result-   : BOOLEAN;
                 END;

VAR
  standardSizes : ARRAY 16 OF LONGINT; (* in pixel *)

  PROCEDURE (e: Size) IsGreater*(other: MT.ListEntryBase; column: LONGINT): BOOLEAN;

  BEGIN
    RETURN e.pixel>other(Size).pixel;
  END IsGreater;

  PROCEDURE (d : Font) Init*;

  BEGIN
    d.Init^;

    d.foundry:=NIL;
    d.encoding:=NIL;
    d.size:=NIL;
  END Init;

  PROCEDURE (d : Font) SetInfo*(info : Info);

  BEGIN
    d.info:=info;
  END SetInfo;

  PROCEDURE (d : Font) PreInit*;

  VAR
    vPanel,
    hPanel  : P.Panel;
    button  : B.Button;
    row     : BR.ButtonRow;
    wGroup  : WG.WindowGroup;
    parent  : D.Window;

  BEGIN
    vPanel:=P.CreateVPanel();
    vPanel.SetFlags({G.horizontalFlex,G.verticalFlex});

    hPanel:=P.CreateHPanel();
    hPanel.SetFlags({G.horizontalFlex,G.verticalFlex});

      NEW(d.fModel);
      d.fModel.Init;
      d.fModel.SetSelection(SM.CreateSingleLine());
      d.fModel.Forward(MT.selectionMsg,d);

      d.fTable:=TB.CreateTable();
      d.fTable.SetFlags({G.horizontalFlex,G.verticalFlex});
      d.fTable.SetMinWidth(Z.unit,50);
      d.fTable.SetMinHeight(Z.unit,50);
      d.fTable.RequestFocus();
      d.fTable.SetShowHeader(FALSE);
      d.fTable.SetShowScroller(FALSE,TRUE);
      d.fTable.SetModel(d.fModel);
    hPanel.Add(d.fTable);

    hPanel.Add(S.CreateHSpace());

      NEW(d.eModel);
      d.eModel.Init;
      d.eModel.SetSelection(SM.CreateSingleLine());
      d.eModel.Forward(MT.selectionMsg,d);

    IF ~d.info.unicodeOnly THEN
      d.eTable:=TB.CreateTable();
      d.eTable.SetFlags({(*G.horizontalFlex,*)G.verticalFlex});
      d.eTable.SetMinWidth(Z.unit,10);
      d.eTable.RequestFocus();
      d.eTable.SetShowHeader(FALSE);
      d.eTable.SetShowScroller(FALSE,TRUE);
      d.eTable.SetModel(d.eModel);
      hPanel.Add(d.eTable);

      hPanel.Add(S.CreateHSpace());
    END;

      NEW(d.sModel);
      d.sModel.Init;
      d.sModel.SetSelection(SM.CreateSingleLine());
      d.sModel.Forward(MT.selectionMsg,d);

      d.sTable:=TB.CreateTable();
      d.sTable.SetFlags({(*G.horizontalFlex,*)G.verticalFlex});
      d.sTable.SetMinWidth(Z.unit,3);
      d.sTable.RequestFocus();
      d.sTable.SetShowHeader(FALSE);
      d.sTable.SetShowScroller(FALSE,TRUE);
      d.sTable.SetModel(d.sModel);
    hPanel.Add(d.sTable);

    vPanel.Add(hPanel);

    vPanel.Add(S.CreateVSpace());

      d.testText:=MV.CreateStringModel();
      d.testText.SetString("There is more in the world than meets the eye.");

      d.string:=ST.CreateString();
      d.string.SetFlags({G.horizontalFlex});
      d.string.SetReadOnly(TRUE);
      d.string.SetWidth(Z.unit,100);
      d.string.SetHeight(Z.unit,20);
      d.string.SetModel(d.testText);

    vPanel.Add(d.string);

    vPanel.Add(S.CreateVSpace());

      row:=BR.CreateButtonRow();
      row.SetFlags({G.horizontalFlex});

        button:=B.CreateButton();
        button.SetFlags({G.horizontalFlex,G.verticalFlex});
        button.RequestFocus();
        button.SetLabelString("OK*");
        button.SetId(0);
        button.Forward(B.pressedMsg,d);
      row.Add(button);

        button:=B.CreateButton();
        button.SetFlags({G.horizontalFlex,G.verticalFlex});
        button.RequestFocus();
        button.SetLabelString("Cancel^");
        button.SetId(1);
        button.Forward(B.pressedMsg,d);
      row.Add(button);
    vPanel.Add(row);

    wGroup:=WG.CreateWindowGroup();
    parent:=d.GetParent();
    IF parent#NIL THEN
      wGroup.SetWidth(Z.pixel,(80*parent.GetWidth()) DIV 100);
      wGroup.SetHeight(Z.pixel,(80*parent.GetHeight()) DIV 100);
    END;
    wGroup.Set(NIL,vPanel,TRUE);

    d.SetTop(wGroup);

    d.Forward(W.closeMsg,d);

    d.result:=FALSE;

    d.PreInit^;
  END PreInit;

  PROCEDURE (d : Font) ShowFont;

  VAR
    font : D.Font;

  BEGIN
    IF (d.family#NIL) & (d.foundry#NIL) & (d.encoding#NIL) & (d.size#NIL) THEN
      font:=D.factory.CreateFont();

      font.features:={D.fontFoundry,D.fontName,D.fontCharSet,D.fontHeight};
      font.foundry:=d.foundry.name;
      font.name:=d.family.name;
      font.charSet:=d.encoding.encoding;
      font.pixelHeight:=d.size.pixel;

      font:=font.Load();

      IF font#NIL THEN
        IF d.font#NIL THEN
          d.font.Free;
        END;
        d.font:=font;

        d.string.SetFont(d.font);
      ELSE
        Err.String("Error loading new font"); Err.Ln;
      END;
    END;
  END ShowFont;

  PROCEDURE (d : Font) OnFoundryChange;

  VAR
    sel      : MT.ListEntryBase;
    entry    : Encoding;
    foundry  : Foundry;
    encoding : D.FontEncoding;

  BEGIN
    sel:=d.fModel.GetEntry(d.fModel.selection(SM.SingleLine).line);

    IF sel#NIL THEN
      foundry:=sel(Foundry);
      d.foundry:=foundry.foundry;
      d.family:=foundry.family;
      d.encoding:=NIL;
      d.size:=NIL;

      d.sModel.DeleteAll;

      d.eModel.Off;
      d.eModel.DeleteAll;

      encoding:=d.foundry.encodings;
      WHILE encoding#NIL DO
        IF (d.info.unicodeOnly & (encoding.encoding^="iso10646-1")) OR ~d.info.unicodeOnly THEN
          NEW(entry);
          entry.Init(d.eModel);
          entry.SetString(1,encoding.encoding^);
          entry.encoding:=encoding;
          d.eModel.AppendEntry(entry);
        END;

        encoding:=encoding.next;
      END;

      d.eModel.Sort(1,TRUE);

      IF d.foundry.encodings#NIL THEN
        d.eModel.selection(SM.SingleLine).SelectLine(1);
      END;

      d.eModel.On;
    END;
  END OnFoundryChange;

  PROCEDURE (d : Font) OnEncodingChange;

  VAR
    sel      : MT.ListEntryBase;
    entry    : Size;
    encoding : Encoding;
    size     : D.FontSize;
    buffer   : ARRAY 256 OF CHAR;
    x,idx    : LONGINT;

  BEGIN
    sel:=d.eModel.GetEntry(d.eModel.selection(SM.SingleLine).line);

    IF sel#NIL THEN
      encoding:=sel(Encoding);
      d.encoding:=encoding.encoding;
      d.size:=NIL;

      d.sModel.Off;
      d.sModel.DeleteAll;

      idx:=1;

      size:=d.encoding.sizes;
      IF size#NIL THEN
        x:=0;
        WHILE size#NIL DO
          NEW(entry);
          entry.Init(d.sModel);
          co.IntToStr(size.size,buffer);
          entry.SetString(1,buffer);
          entry.size:=size;
          entry.pixel:=size.size;
          d.sModel.AppendEntry(entry);

          IF entry.pixel=14 THEN
            idx:=x+1;
          END;

          size:=size.next;
          INC(x);
        END;
      ELSE
        FOR x:=0 TO LEN(standardSizes)-1 DO
          NEW(entry);
          entry.Init(d.sModel);
          co.IntToStr(standardSizes[x],buffer);
          entry.SetString(1,buffer);
          entry.size:=NIL;
          entry.pixel:=standardSizes[x];
          d.sModel.AppendEntry(entry);

          IF entry.pixel=14 THEN
            idx:=x+1;
          END;

        END;
      END;

      d.sModel.Sort(1,TRUE);

      IF d.sModel.GetRows()>0 THEN
        IF idx>0 THEN
          d.sModel.selection(SM.SingleLine).SelectLine(idx);
        ELSE
          d.sModel.selection(SM.SingleLine).SelectLine(1);
        END;
      END;

      d.sModel.On;
    END;
  END OnEncodingChange;

  PROCEDURE (d : Font) OnSizeChange;

  VAR
    sel : MT.ListEntryBase;

  BEGIN
    sel:=d.sModel.GetEntry(d.sModel.selection(SM.SingleLine).line);
    d.size:=sel(Size);

    d.ShowFont;
  END OnSizeChange;

  PROCEDURE (d : Font) HasUnicode(foundry : D.FontFoundry):BOOLEAN;

  VAR
    encoding : D.FontEncoding;

  BEGIN
    encoding:=foundry.encodings;
    WHILE encoding#NIL DO
      IF encoding.encoding^="iso10646-1" THEN
        RETURN TRUE;
      END;

      encoding:=encoding.next;
    END;

    RETURN FALSE;
  END HasUnicode;

  PROCEDURE (d : Font) OnOpened*;

  VAR
    buffer  : ARRAY 1024 OF CHAR;
    list    : D.FontList;
    family  : D.FontFamily;
    foundry : D.FontFoundry;
    entry   : Foundry;

  BEGIN
    d.OnOpened^;

    list:=D.display.GetFontList();
    IF list#NIL THEN
      d.fModel.Off;

      family:=list.families;
      WHILE family#NIL DO
        foundry:=family.foundries;
        WHILE foundry#NIL DO
          IF (d.info.unicodeOnly & d.HasUnicode(foundry)) OR ~d.info.unicodeOnly THEN
            NEW(entry);
            entry.Init(d.fModel);
            COPY(family.name^,buffer);

            IF family.foundries.next#NIL THEN
              str.Append(" [",buffer);
              str.Append(foundry.name^,buffer);
              str.Append("]",buffer);
            END;

            entry.SetString(1,buffer);
            entry.family:=family;
            entry.foundry:=foundry;
            d.fModel.AppendEntry(entry);
          END;

          foundry:=foundry.next;
        END;

        family:=family.next;
      END;

      d.fModel.Sort(1,TRUE);

      IF d.fModel.GetRows()>0 THEN
        d.fModel.selection(SM.SingleLine).SelectLine(1);
      END;

      d.fModel.On;
    END;
  END OnOpened;

  PROCEDURE (d : Font) Receive*(message : O.Message);

  BEGIN
    WITH
      message : B.PressedMsg DO
      IF message.source.id=0 THEN
        IF (d.family#NIL) & (d.foundry#NIL) & (d.encoding#NIL) & (d.size#NIL) THEN
          d.result:=TRUE;
          IF d.font#NIL THEN
            d.font.Free;
          END;
          d.Exit;
        ELSE
          IF Msg.Dialog(d,"Error!","You must select a complete font","_OK#",Msg.atention)#NIL THEN
          END;
        END;
      ELSE
        d.result:=FALSE;
        IF d.font#NIL THEN
          d.font.Free;
        END;
        d.Exit;
      END;
    | message : W.CloseMsg DO
      d.result:=FALSE;
      IF d.font#NIL THEN
        d.font.Free;
      END;
      d.Exit;
    | message : MT.SelectionMsg DO
      IF message.source=d.fModel THEN
        d.OnFoundryChange;
      ELSIF message.source=d.eModel THEN
        d.OnEncodingChange;
      ELSIF message.source=d.sModel THEN
        d.OnSizeChange;
      END;
    ELSE
      d.Receive^(message);
    END;
  END Receive;

  PROCEDURE GetFont*(parent : D.Window;
                     title : STRING;
                     info : Info):D.Font;

  VAR
    dlg : Font;

  BEGIN
    NEW(dlg);
    dlg.Init;
    dlg.SetInfo(info);
    dlg.SetParent(parent);
    dlg.SetPosition(D.centerOnParent,D.centerOnParent);
    dlg.SetTitle(title);
    IF dlg.Open() THEN
      dlg.EventLoop;
      dlg.Close;

      IF dlg.result THEN
        RETURN dlg.font;
      END;
    END;

    RETURN NIL;
  END GetFont;

  PROCEDURE (i : Info) Init*;

  BEGIN
    i.unicodeOnly:=FALSE;
  END Init;

  PROCEDURE (i : Info) SetUnicodeOnly*(unicodeOnly : BOOLEAN);

  BEGIN
    i.unicodeOnly:=unicodeOnly;
  END SetUnicodeOnly;

  PROCEDURE CreateInfo*():Info;

  VAR
    info : Info;

  BEGIN
    NEW(info);
    info.Init;

    RETURN info;
  END CreateInfo;

BEGIN
  standardSizes[ 0]:= 8;
  standardSizes[ 1]:= 9;
  standardSizes[ 2]:=10;
  standardSizes[ 3]:=11;
  standardSizes[ 4]:=12;
  standardSizes[ 5]:=14;
  standardSizes[ 6]:=16;
  standardSizes[ 7]:=18;
  standardSizes[ 8]:=20;
  standardSizes[ 9]:=22;
  standardSizes[10]:=24;
  standardSizes[11]:=26;
  standardSizes[12]:=28;
  standardSizes[13]:=36;
  standardSizes[14]:=48;
  standardSizes[15]:=72;
END VO:Dlg:Font.