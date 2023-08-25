MODULE VO:Prefs:GUI;

(**
  Module for handling of the various preferences GUIs.
  Offers a flexible settings dialog.
*)

(*
    Implements a unvisible tab gadget.
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

IMPORT D   := VO:Base:Display,
       O   := VO:Base:Object,

       PP  := VO:Prefs:Parser,

       B   := VO:Button,
       BR  := VO:ButtonRow,
       G   := VO:Object,
       OON := VO:ViewOneOfN,
       P   := VO:Panel,
       S   := VO:Space,
       T   := VO:Text,
       W   := VO:Window,
       WG  := VO:WindowGroup,

              Err,
              Object;


CONST
  prefsNameSize* = 20;

  useId    = 1;
  saveId   = 2;
  closeId  = 3;

TYPE
  PrefsItem*        = POINTER TO PrefsItemDesc;
  PrefsItemDesc*    = RECORD
                        window- : W.Window;
                        next,
                        last    : PrefsItem;
                        name-   : ARRAY prefsNameSize OF CHAR;
                      END;

  Settings*         = POINTER TO SettingsDesc;
  SettingsDesc*     = RECORD ( W.WindowDesc)
                        exitIt     : BOOLEAN;
                      END;



  AboutItem         = POINTER TO AboutItemDesc;
  AboutItemDesc     = RECORD (PrefsItemDesc);
                      END;
	
  Prefs             = POINTER TO PrefsDesc;
  PrefsDesc         = RECORD
                        itemList,
                        itemLast  : PrefsItem;
                      END;

  PrefsCallback     = POINTER TO PrefsCallbackDesc;
  PrefsCallbackDesc = RECORD (D.PrefsCallbackDesc)
                        config,
                        theme    : PP.Item;
                        notFound : BOOLEAN;
                      END;

VAR
  settings*     : Settings;
  prefsCallback : PrefsCallback;
  prefs         : Prefs;

  PROCEDURE (p : PrefsItem) SetName*(name : ARRAY OF CHAR);

  BEGIN
    COPY(name,p.name);
  END SetName;

  PROCEDURE  (p : PrefsItem) ErrorWrongData*(name,value : ARRAY OF CHAR);

  BEGIN
    Err.String("Unknown value for '");
    Err.String(p.name);
    Err.String("/");
    Err.String(name);
    Err.String("': ");
    Err.String(value);
    Err.Ln;
  END ErrorWrongData;

  PROCEDURE (i : PrefsItem) GetObject*():G.Object;

  BEGIN
    RETURN NIL;
  END GetObject;

  PROCEDURE (o : PrefsItem) Apply*;

  BEGIN
  END Apply;

  PROCEDURE (o : PrefsItem) Refresh*;

  BEGIN
  END Refresh;

  PROCEDURE (p : PrefsItem) LoadPrefs*(top : PP.Item);
  (**
    The preferences subsystem calls this method on start for each @otype{PrefsItem}
    object. @oparam{top} is the config node for the specific @otype{PrefsItem}
    instance. @oproc{p.LoadPrefs} should try to extract all preferences information
    fromt he given subtree.

    The baseclass does nothing.
  *)

  BEGIN
  END LoadPrefs;

  PROCEDURE (p : PrefsItem) LoadTheme*(top : PP.Item);
  (**
    The preferences subsystem calls this method on start for each @otype{PrefsItem}
    object. @oparam{top} is the config node for the specific @otype{PrefsItem}
    instance. @oproc{p.LoadTheme} should try to extract all theming information
    from the given subtree.

    The baseclass does nothing.
  *)

  BEGIN
  END LoadTheme;

  PROCEDURE (o : PrefsItem) SavePrefs*(block : PP.BlockItem);

  BEGIN
  END SavePrefs;


  (* ------- *)

  PROCEDURE (p : Prefs) Init;

  BEGIN
    p.itemList:=NIL;
    p.itemLast:=NIL;
  END Init;

  PROCEDURE (s : Prefs) AddItem(item : PrefsItem);

  BEGIN
    IF s.itemList=NIL THEN
      s.itemList:=item;
    ELSE
      s.itemLast.next:=item;
      item.last:=s.itemLast;
    END;
    item.next:=NIL;
    s.itemLast:=item;
  END AddItem;

  PROCEDURE (p : PrefsItem) Init*;

  BEGIN
    p.next:=NIL;
    p.last:=NIL;
    p.name[0]:=0X;
    prefs.AddItem(p);
  END Init;

  PROCEDURE (s : Prefs) ApplyPrefs*;

  VAR
    item : PrefsItem;

  BEGIN
    item:=s.itemList;
    WHILE item#NIL DO
      item.Apply;
      item:=item.next;
    END;
  END ApplyPrefs;

  PROCEDURE (s : Prefs) SavePrefs*;

  VAR
    item  : PrefsItem;
    top,
    block : PP.BlockItem;

  BEGIN
    NEW(top);
    top.Init;
    top.SetName("Config");

    item:=s.itemList;
    WHILE item#NIL DO
      block:=PP.CreateBlockItem(item.name);

      item.SavePrefs(block);

      top.AddItem(block);

      item:=item.next;
    END;

    PP.SaveConfig(D.display.GetPrefsName(),top);
  END SavePrefs;

  PROCEDURE (s : Prefs) ReadDisplayPrefs(config : PP.Item);

  VAR
    item  : PrefsItem;
    entry : PP.Item;

  BEGIN
    config:=config.GetEntry("Config");
    IF config=NIL THEN
      RETURN;
    END;

    item:=s.itemList;
    WHILE item#NIL DO
      IF item.name="Display" THEN
        entry:=config.GetEntry(item.name);
        IF entry#NIL THEN
          item.LoadPrefs(entry);
        END;

        RETURN;
      END;
      item:=item.next;
    END;
  END ReadDisplayPrefs;

  PROCEDURE (s : Prefs) ReadOtherPrefs(config : PP.Item);

  VAR
    item  : PrefsItem;
    entry : PP.Item;

  BEGIN
    config:=config.GetEntry("Config");
    IF config=NIL THEN
      RETURN;
    END;

    item:=s.itemList;
    WHILE item#NIL DO
      IF item.name#"Display" THEN
        entry:=config.GetEntry(item.name);
        IF entry#NIL THEN
          item.LoadPrefs(entry);
        END;
      END;
      item:=item.next;
    END;
  END ReadOtherPrefs;

  PROCEDURE (s : Prefs) ReadDisplayTheme(config : PP.Item);

  VAR
    item  : PrefsItem;
    entry : PP.Item;

  BEGIN
    config:=config.GetEntry("Config");
    IF config=NIL THEN
      RETURN;
    END;

    item:=s.itemList;
    WHILE item#NIL DO
      IF item.name="Display" THEN
        entry:=config.GetEntry(item.name);
        IF entry#NIL THEN
          item.LoadTheme(entry);
        END;
      END;
      item:=item.next;
    END;
  END ReadDisplayTheme;

  PROCEDURE (s : Prefs) ReadOtherTheme(config : PP.Item);

  VAR
    item  : PrefsItem;
    entry : PP.Item;

  BEGIN
    config:=config.GetEntry("Config");
    IF config=NIL THEN
      RETURN;
    END;

    item:=s.itemList;
    WHILE item#NIL DO
      IF item.name#"Display" THEN
        entry:=config.GetEntry(item.name);
        IF entry#NIL THEN
          item.LoadTheme(entry);
        END;
      END;
      item:=item.next;
    END;
  END ReadOtherTheme;

  (* ------- *)

  PROCEDURE (s : Settings) Init*;

  BEGIN
    s.Init^;

    s.SetTitle("VisualOberon - Settings");

    s.exitIt:=FALSE;
  END Init;

  PROCEDURE (s : Settings) ExitOnClose*(exit : BOOLEAN);
  (**
    If you want the dialog to quit the application, set this to true.

    This is usefull, if the configuration dialog is a standalone
    window.
  *)

  BEGIN
    s.exitIt:=exit;
  END ExitOnClose;

  PROCEDURE (s : Settings) PreInit*;

  VAR
    top         : P.Panel;
    row         : BR.ButtonRow;
    button      : B.Button;
    msg2Exit    : W.Msg2Exit;
    space       : S.Space;
    item        : PrefsItem;
    wGroup      : WG.WindowGroup;
    one         : OON.ViewOneOfN;
    object      : G.Object;

  BEGIN
    top:=P.CreateVPanel();
    top.SetFlags({G.horizontalFlex,G.verticalFlex});

    one:=OON.CreateViewOneOfN();
    one.SetFlags({G.horizontalFlex,G.verticalFlex});
    one.RequestFocus();
    top.Add(one);

    item:=prefs.itemList;
    WHILE item#NIL DO
      item.window:=s;
      object:=item.GetObject();
      IF object#NIL THEN
        object.SetName(Object.NewLatin1(item.name));
        one.AddView(object.name,object);
      END;
      item:=item.next;
    END;

    space:=S.CreateVSpace();
    top.Add(space);

    row:=BR.CreateButtonRow();
    row.SetFlags({G.horizontalFlex});

    button:=B.CreateButton();
    button.SetId(saveId);
    button.SetFlags({G.horizontalFlex});
    button.RequestFocus();
    button.SetLabelString("_Save");
    button.Forward(B.pressedMsg,s);
    row.Add(button);

    button:=B.CreateButton();
    button.SetId(useId);
    button.SetFlags({G.horizontalFlex});
    button.RequestFocus();
    button.SetLabelString("_Apply");
    button.Forward(B.pressedMsg,s);
    row.Add(button);

    button:=B.CreateButton();
    button.SetId(closeId);
    button.SetFlags({G.horizontalFlex});
    button.RequestFocus();
    button.SetLabelString("_Close^");
    NEW(msg2Exit);
    msg2Exit.destination:=s;
    button.AddHandler(msg2Exit,B.pressedMsg);
    row.Add(button);

    top.Add(row);

    wGroup:=WG.CreateWindowGroup();
    wGroup.Set(NIL,top,TRUE);

    s.SetTop(wGroup);

    NEW(msg2Exit);
    msg2Exit.destination:=s;
    s.AddHandler(msg2Exit,W.closeMsg);

    s.PreInit^;
  END PreInit;

  PROCEDURE (s : Settings) Open*():BOOLEAN;

  VAR
    item : PrefsItem;

  BEGIN
    IF ~s.Open^() THEN
      RETURN FALSE;
    END;

    item:=prefs.itemList;
    WHILE item#NIL DO
      item.Refresh;
      item:=item.next;
    END;

    RETURN TRUE;
  END Open;

  PROCEDURE (s : Settings) Receive*(message : O.Message);

  BEGIN
    WITH
      message : B.PressedMsg DO
        CASE message.source.id OF
          closeId:
            IF s.exitIt THEN
              D.display.Exit;
            ELSE
              s.Exit;
            END;
        | useId:
            prefs.ApplyPrefs;
            D.display.ReinitWindows;
        | saveId:
            prefs.ApplyPrefs;
            D.display.ReinitWindows;
            prefs.SavePrefs;
        END;
    | message : W.ExitMsg DO
        IF s.exitIt THEN
          D.display.Exit;
        ELSE
          s.Exit;
        END;
    ELSE
      s.Receive^(message);
    END;
  END Receive;

  PROCEDURE (a : AboutItem) Init*;

  BEGIN
    a.Init^;
    a.SetName("About");
  END Init;


  PROCEDURE (a : AboutItem) GetObject*():G.Object;

  BEGIN
    RETURN T.MakeLeftText("\ec\es\e9VisualOberon\n\e4\en\n\ecCopyright 1997-2003\nTim Teulings\n(rael@edge.ping.de)");
  END GetObject;

  PROCEDURE (p : PrefsCallback) LoadPrefs*(appName : ARRAY OF CHAR);

  VAR
    about : AboutItem;

  BEGIN
    NEW(about);
    about.Init;
    prefs.AddItem(about);

    p.config:=PP.LoadConfig(D.display.GetPrefsName(),p.notFound);
  END LoadPrefs;

  PROCEDURE (p : PrefsCallback) ReadDisplayPrefs*;

  BEGIN
    IF p.config#NIL THEN
      prefs.ReadDisplayPrefs(p.config);
    END;
  END ReadDisplayPrefs;

  PROCEDURE (p : PrefsCallback) ReadOtherPrefs*;

  BEGIN
    IF p.notFound THEN
      prefs.SavePrefs;
    END;

    IF p.config#NIL THEN
      prefs.ReadOtherPrefs(p.config);
    END;
  END ReadOtherPrefs;

  PROCEDURE (p : PrefsCallback) LoadTheme*(theme : STRING);

  VAR
    notFound : BOOLEAN;

  BEGIN
    p.theme:=PP.LoadConfig(D.display.GetThemeName(theme),notFound);
    IF p.theme=NIL THEN
      RETURN;
    END;

  END LoadTheme;

  PROCEDURE (p : PrefsCallback) ReadDisplayTheme*;

  BEGIN
    IF p.theme#NIL THEN
      prefs.ReadDisplayTheme(p.theme);
    END;
  END ReadDisplayTheme;

  PROCEDURE (p : PrefsCallback) ReadOtherTheme*;

  BEGIN
    IF p.theme#NIL THEN
      prefs.ReadOtherTheme(p.theme);
    END;
  END ReadOtherTheme;

  PROCEDURE (p : PrefsCallback) Free*;

  BEGIN
    p.config:=NIL;
    p.theme:=NIL;
  END Free;

  PROCEDURE ShowSettings*(parent : W.Window);

  VAR
    settings : Settings;

  BEGIN
    NEW(settings);
    settings.Init;

    settings.SetParent(parent);
    settings.SetPosition(D.centerOnParent,D.centerOnParent);
    IF settings.Open() THEN
      settings.EventLoop;
      settings.Close;
    END;
  END ShowSettings;

BEGIN
  settings:=NIL;
  prefs:=NIL;
  NEW(prefs);
  prefs.Init;

  NEW(prefsCallback);
  D.prefsCallback:=prefsCallback;
END VO:Prefs:GUI.