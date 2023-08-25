MODULE VO:Dlg:File;

IMPORT D   := VO:Base:Display,
       E   := VO:Base:Event,
       O   := VO:Base:Object,
       Z   := VO:Base:Size,

       MF  := VO:Model:DirTable,
       SM  := VO:Model:Selection,
       MT  := VO:Model:Table,
       MV  := VO:Model:Value,

       BO  := VO:Bool,
       B   := VO:Button,
       BR  := VO:ButtonRow,
       G   := VO:Object,
       P   := VO:Panel,
       L   := VO:Label,
       S   := VO:Space,
       ST  := VO:String,
       T   := VO:Toolbar,
       TB  := VO:Table,
       TV  := VO:TableView,
       W   := VO:Window,
       WG  := VO:WindowGroup,

       Dir := Directory,

              Ascii,
              Exception,
       f   := OS:Files,
              IO,
              OS:Path,
       pp  := OS:ProcessParameters;

CONST
  okId     = 0;
  cancelId = 1;
  parentId = 2;
  homeId   = 3;
  rootId   = 4;
  reloadId = 5;

  modeFile*      = 0;
  modeDirectory* = 1;

TYPE
  Options*      = POINTER TO OptionsDesc;
  OptionsDesc*  = RECORD
                    (**
                      Holds all options for the file dialog. Please create
                      all instances using @oproc{CreateOptions} to be sure
                      to have all options initialized to a default value.
                    *)
                    mode-         : LONGINT;
                    existingOnly- : BOOLEAN;
                  END;

  FileDlg     * = POINTER TO FileDlgDesc;
  FileDlgDesc * = RECORD (W.WindowDesc)
                    full-   : MV.StringModel;
                    path-   : MV.StringModel;
                    file-   : MV.StringModel;
                    fullStr : ST.String;
                    hidden- : MV.BoolModel;
                    options-: Options;
                    model   : MF.DirModel;
                    table-  : TB.Table;
                    result- : BOOLEAN;
                  END;

  PROCEDURE (o : Options) Init*;

  BEGIN
    o.mode:=modeFile;
    o.existingOnly:=FALSE;
  END Init;

  PROCEDURE (o : Options) SetMode*(mode : LONGINT);

    (**
      The mode for the dialog that should be used. Currebntly supported
      are mode @oconst{modeFile}, which forces you to select a file, and
      mode @oconst{modeDirectory}, which forces you to select a directory.
    *)

  BEGIN
    o.mode:=mode;
  END SetMode;

  PROCEDURE (o : Options) AllowExistingOnly*(allow : BOOLEAN);

    (**
      You can only select files and/or directories that do exists.
    *)

  BEGIN
    o.existingOnly:=allow;
  END AllowExistingOnly;

  PROCEDURE AbsoluteDir(dir : STRING):STRING RAISES IO.Error;

  VAR
    old,new : STRING;

  BEGIN
    IF dir.length=0 THEN
      RETURN pp.GetCwd();
    ELSE
      old:=pp.GetCwd();
      Dir.SetCwd(dir);
      new:=pp.GetCwd();
      Dir.SetCwd(old);

      RETURN new;
    END;
  END AbsoluteDir;

  PROCEDURE Append*(directory : STRING; sub : STRING):STRING;

    (**
      Appends @oparam{sub} to @oparam{directory}. Takes care of
      inserting a @code{/} if necessary.
    *)

  BEGIN
    IF directory.CharAt(directory.length-1)="/" THEN
      RETURN directory+sub;
    ELSE
      RETURN directory+"/"+sub;
    END;
  END Append;

  PROCEDURE FixDir*(dir : STRING):STRING;

    (**
      Treads @oparam{dir} a s a directoray and will apend a trailing @code{/}
      if it does not exists.
    *)

  BEGIN
    IF dir.CharAt(dir.length-1)#"/" THEN
      RETURN dir+"/";
    ELSE
      RETURN dir;
    END;
  END FixDir;

  PROCEDURE ReadDir(name : STRING; hidden,dirOnly : BOOLEAN):MF.DirList;

  VAR
    array   : f.NameArray;
    list    : MF.DirList;
    current : MF.DirEntry;
    pos,x   : LONGINT;
    full    : STRING;
    ex      : Exception.Exception;

  BEGIN
    TRY
      array:=f.ListDir(name);
    CATCH IO.Error:
      ex:=Exception.Current();
      RETURN NIL;
    END;

    NEW(list,LEN(array^)+2);

    pos:=0;
    x:=0;
    WHILE (x<LEN(array^)) & (array[x]#NIL) DO
      IF hidden OR (array[x].CharAt(0)#".") THEN
        NEW(current);
        current.fileName:=array[x];
        full:=Append(name,array[x]);
        IF Dir.GetDetails({Dir.type,Dir.size},full,current^)
          & (~dirOnly OR ((current.type=Dir.directory))) THEN
          list[pos]:=current;
          INC(pos);
        END;
      END;
      INC(x);
    END;

    IF pos<LEN(list^) THEN
      list[pos]:=NIL;
    END;

    RETURN list;
  END ReadDir;

  PROCEDURE (d : FileDlg) Init*;

  VAR
    string : STRING;

  BEGIN
    d.Init^;

    TRY
      string:=FixDir(pp.GetCwd());
    CATCH IO.Error:
      string:="/";
    END;

    NEW(d.full);
    d.full.Init;
    d.full.SetString(string);

    NEW(d.path);
    d.path.Init;
    d.path.SetString(Path.DirName(string));

    NEW(d.file);
    d.file.Init;
    d.file.SetString("");

    NEW(d.hidden);
    d.hidden.Init;
    d.hidden.SetBoolean(FALSE);
    d.hidden.AddObject(d);
  END Init;

  PROCEDURE (d : FileDlg) SetPath*(path : STRING);

    (**
      Set the path/file for the dialog to show to @oparam{path}. Note,
      that @oparam{path} should be an absolute apth and that it must
      have a trailing @code{/} if it is a path instead of a file.
    *)

  VAR
    res   : MF.DirList;
    file  : STRING;
    x     : LONGINT;

  BEGIN
    d.full.SetString(FixDir(Path.DirName(path))+Path.BaseName(path));
    d.path.SetString(FixDir(Path.DirName(path)));
    d.file.SetString(Path.BaseName(path));
    IF d.IsMaped() THEN
      res:=ReadDir(d.path.GetString(),
                   d.hidden.GetBoolean(),
                   d.options.mode=modeDirectory);
      IF res#NIL THEN
        file:=d.file.GetString();
        d.model.SetDir(res);
        x:=0;
        WHILE (x<LEN(res^)) & (res[x]#NIL) & ~res[x].fileName.Equals(file) DO
          INC(x);
        END;

        IF (x<LEN(res^)) & (res[x]#NIL) THEN
          d.model.selection.SelectCell(1,x+1);
          d.table.table.MakeVisible(1,x+1);
        ELSE
          d.model.selection.SelectCell(1,1);
        END;
      ELSE
        NEW(res,0);
        d.model.SetDir(res);
      END;
    END;
  END SetPath;

  PROCEDURE (d : FileDlg) HandleFullString():BOOLEAN;

  VAR
    info  : MF.DirEntryDesc;
    full,
    file,
    dir   : STRING;
    repos : BOOLEAN;

  BEGIN
    full:=d.full.GetString();

    IF full.length=0 THEN
      (* cannot handle empty string *)
      d.SetPath(d.path.GetString());
      RETURN FALSE;
    END;

    IF ~Dir.GetDetails({Dir.type},full,info) THEN
      IF d.options.existingOnly THEN
        d.SetPath(d.path.GetString());
        RETURN FALSE;
      ELSE
        d.SetPath(full);
        RETURN TRUE;
      END;
    END;

    repos:=d.fullStr.cursor>=full.length;

    IF info.type=Dir.directory THEN
      dir:=full;
      file:="";
    ELSE
      dir:=Path.DirName(full);
      file:=Path.BaseName(full);
    END;

    TRY
      dir:=AbsoluteDir(dir);
    CATCH IO.Error:
      d.SetPath(d.path.GetString());
      RETURN FALSE;
    END;

    full:=FixDir(dir)+file;

    d.SetPath(full);

    IF repos THEN
      d.fullStr.SetCursorPos(-1);
    END;

    (*
      We only close the dialog, when selecting a file and we are in modeFile.
    *)
    RETURN (info.type#Dir.directory) & (d.options.mode=modeFile);
  END HandleFullString;

  PROCEDURE (d : FileDlg) PreInit*;

  VAR
    vPanel  : P.Panel;
    tool    : T.Toolbar;
    button  : B.Button;
    row     : BR.ButtonRow;
(*    string2 : ST.String;*)
    wGroup  : WG.WindowGroup;
    parent  : D.Window;
    bool    : BO.Bool;
    label   : L.Label;

  BEGIN
    vPanel:=P.CreateVPanel();
    vPanel.SetFlags({G.horizontalFlex,G.verticalFlex});

    tool:=T.CreateToolbar();
    tool.SetFlags({G.horizontalFlex});

    button:=B.CreateButton();
    button.SetFlags({G.horizontalFlex,G.verticalFlex});
    button.SetLabelString("Up");
    button.SetId(parentId);
    button.Forward(B.pressedMsg,d);
    tool.Add(button);

    button:=B.CreateButton();
    button.SetFlags({G.horizontalFlex,G.verticalFlex});
    button.SetLabelString("Home");
    button.SetId(homeId);
    button.Forward(B.pressedMsg,d);
    tool.Add(button);

    button:=B.CreateButton();
    button.SetFlags({G.horizontalFlex,G.verticalFlex});
    button.SetLabelString("/");
    button.SetId(rootId);
    button.Forward(B.pressedMsg,d);
    tool.Add(button);

    button:=B.CreateButton();
    button.SetFlags({G.horizontalFlex,G.verticalFlex});
    button.SetLabelString("Reload");
    button.SetId(reloadId);
    button.Forward(B.pressedMsg,d);
    tool.Add(button);

    vPanel.Add(S.CreateVSpace());

      NEW(d.model);
      d.model.Init;
      d.model.SetSelection(SM.CreateSingleLine());
      d.model.Forward(MT.selectionMsg,d);

      d.table:=TB.CreateTable();
      d.table.SetFlags({G.horizontalFlex,G.verticalFlex});
      d.table.SetMinWidth(Z.screenHRel,30);
      d.table.SetMinHeight(Z.screenVRel,30);
      d.table.RequestFocus;
      d.table.SetShowHeader(TRUE);
      d.table.SetModel(d.model);
      d.table.table.Forward(TV.doubleClickMsg,d);
    vPanel.Add(d.table);

    vPanel.Add(S.CreateVSpace());

      label:=L.CreateLabel();
      label.SetFlags({G.horizontalFlex});

        bool:=BO.CreateBool();
        bool.RequestFocus();
        bool.SetModel(d.hidden);
      label.AddStringLabel("Show hidden files",bool);
    vPanel.Add(label);

    vPanel.Add(S.CreateVSpace());

(*      string2:=ST.CreateString();
      string2.SetFlags({G.horizontalFlex});
      string2.SetReadOnly(TRUE);
      string2.SetModel(d.path);
    vPanel.Add(string2);

    vPanel.Add(S.CreateVSpace());

      string2:=ST.CreateString();
      string2.SetFlags({G.horizontalFlex});
      string2.SetReadOnly(TRUE);
      string2.SetModel(d.file);
    vPanel.Add(string2);

    vPanel.Add(S.CreateVSpace());*)

      NEW(d.fullStr);
      d.fullStr.Init;
      d.fullStr.SetFlags({G.horizontalFlex});
      d.fullStr.RequestFocus;
      d.fullStr.SetModel(d.full);
      d.fullStr.Forward(ST.enteredMsg,d);
    vPanel.Add(d.fullStr);

    vPanel.Add(S.CreateVSpace());

      row:=BR.CreateButtonRow();
      row.SetFlags({G.horizontalFlex});

        button:=B.CreateButton();
        button.SetFlags({G.horizontalFlex,G.verticalFlex});
        button.RequestFocus();
        button.SetLabelString("_OK*");
        button.SetId(okId);
        button.Forward(B.pressedMsg,d);
      row.Add(button);

        button:=B.CreateButton();
        button.SetFlags({G.horizontalFlex,G.verticalFlex});
        button.RequestFocus();
        button.SetLabelString("_Cancel^");
        button.SetId(cancelId);
        button.Forward(B.pressedMsg,d);
      row.Add(button);
    vPanel.Add(row);

    wGroup:=WG.CreateWindowGroup();
    parent:=d.GetParent();
    IF parent#NIL THEN
      wGroup.SetWidth(Z.pixel,(80*parent.GetWidth()) DIV 100);
      wGroup.SetHeight(Z.pixel,(80*parent.GetHeight()) DIV 100);
    END;

    wGroup.SetToolbar(tool);
    wGroup.SetMain(vPanel);

    d.SetTop(wGroup);

    d.Forward(W.closeMsg,d);

    d.result:=FALSE;

    d.RegisterCommitShortcut(d.table.table,okId,d);
    d.RegisterCancelShortcut(d.table.table,cancelId,d);
    d.RegisterShortcut(d.table.table,{},Ascii.bs,parentId,d);
    d.RegisterShortcut(d.table.table,E.altMask,"u",parentId,d);
    d.RegisterShortcut(d.table.table,E.altMask,"h",homeId,d);
    d.RegisterShortcut(d.table.table,E.altMask,"/",rootId,d);
    d.RegisterShortcut(d.table.table,E.altMask,"r",reloadId,d);

    d.PreInit^;
  END PreInit;

  PROCEDURE (d : FileDlg) OnSelectionChange;

  VAR
    entry : MF.DirEntry;

  BEGIN
    entry:=d.model.GetSelection();
    IF (entry#NIL) & (entry.fileName#NIL)
      & ~entry.fileName.Equals(".") & ~entry.fileName.Equals("..") THEN
      IF entry.type=Dir.directory THEN
        d.file.SetString(FixDir(entry.fileName));
        d.full.SetString(FixDir(d.path.GetString()));
      ELSE
        d.file.SetString(entry.fileName);
        d.full.SetString(Append(d.path.GetString(),entry.fileName));
      END;
    END;
  END OnSelectionChange;

  PROCEDURE (d: FileDlg) GotoChildDirectory(dir : STRING);

  BEGIN
    d.SetPath(FixDir(Append(d.path.GetString(),dir)));
  END GotoChildDirectory;

  PROCEDURE (d: FileDlg) GotoParent;

  VAR
    path : STRING;

  BEGIN
    path:=d.path.GetString();

    IF path.Equals("/") THEN
      RETURN;
    END;

    IF (path.length>0) & (path.CharAt(path.length-1)="/") THEN
      path:=path.Substring(0,path.length-1);
    END;

    path:=FixDir(Path.DirName(path));

    d.SetPath(path);
  END GotoParent;

  PROCEDURE (d : FileDlg) GotoHome;

  BEGIN
    d.SetPath(FixDir(pp.GetEnv("HOME")));
  END GotoHome;

  PROCEDURE (d : FileDlg) GotoRoot;

  BEGIN
    d.SetPath("/");
  END GotoRoot;

  PROCEDURE (d: FileDlg) Reload;

  BEGIN
    d.SetPath(d.full.GetString());
  END Reload;

  PROCEDURE (d : FileDlg) OnOk;

  VAR
    info : MF.DirEntryDesc;
    full : STRING;

  BEGIN
    full:=d.full.GetString();
    IF ~Dir.GetDetails({Dir.type},full,info) THEN
      IF d.options.existingOnly THEN
        RETURN;
      END;

      IF (full.length>0) & (full.CharAt(full.length-1)="/") & (d.options.mode#modeDirectory) THEN
        RETURN;
      END;
    ELSE
      IF ((d.options.mode=modeDirectory) & (info.type#Dir.directory)) OR
        ((d.options.mode=modeFile) & (info.type=Dir.directory)) THEN
        RETURN;
      END;
    END;

    d.result:=TRUE;
    d.Exit;
  END OnOk;

  PROCEDURE (d : FileDlg) OnDoubleClick;

  VAR
    entry : MF.DirEntry;

  BEGIN
    entry:=d.model.GetSelection();
    IF (entry#NIL) & (entry.fileName#NIL) & ~entry.fileName.Equals(".") THEN
      IF entry.type=Dir.directory THEN
        d.GotoChildDirectory(entry.fileName);
      ELSE (* Doubleclick on file *)
        d.OnOk;
      END;
    END;
  END OnDoubleClick;


  PROCEDURE (d : FileDlg) OnOpened*;

  BEGIN
    d.OnOpened^;

    d.SetPath(d.full.GetString());
  END OnOpened;

  PROCEDURE (d : FileDlg) Receive*(message : O.Message);

  BEGIN
    WITH
      message : B.PressedMsg DO
      IF message.source.id=okId THEN
        d.result:=TRUE;
        d.Exit;
      ELSIF message.source.id=cancelId THEN
        d.result:=FALSE;
        d.Exit;
      ELSIF message.source.id=parentId THEN
        d.GotoParent;
      ELSIF message.source.id=homeId THEN
        d.GotoHome;
      ELSIF message.source.id=rootId THEN
        d.GotoRoot;
      ELSIF message.source.id=reloadId THEN
        d.Reload;
      END;
    | message : W.CloseMsg DO
        d.result:=FALSE;
        d.Exit;
    | message : TV.DoubleClickMsg DO
        d.OnDoubleClick;
    | message : MT.SelectionMsg DO
        d.OnSelectionChange;
    | message : ST.EnteredMsg DO
      IF d.HandleFullString() THEN
        d.OnOk;
      END;
    | message : W.ShortcutMsg DO
      IF message.state=W.shortcutReleased THEN
        CASE message.id OF
          okId:
          d.OnDoubleClick;
        | cancelId:
          d.result:=FALSE;
          d.Exit;
        | parentId:
          d.GotoParent;
        | homeId:
          d.GotoHome;
        | rootId:
          d.GotoRoot;
        | reloadId:
          d.Reload;
        END;
      END;
    ELSE
      d.Receive^(message);
    END;
  END Receive;

  PROCEDURE (d : FileDlg) Resync*(model : O.Model; msg : O.ResyncMsg);

  VAR
    res : MF.DirList;

  BEGIN
    IF model=d.hidden THEN
      res:=ReadDir(d.path.GetString(),
                   d.hidden.GetBoolean(),
                   d.options.mode=modeDirectory);
      IF res#NIL THEN
        d.model.SetDir(res);
      END;
    END;
  END Resync;

  PROCEDURE CreateOptions*():Options;

  VAR
    options : Options;

  BEGIN
    NEW(options);
    options.Init;

    RETURN options;
  END CreateOptions;


  PROCEDURE GetFile*(parent : D.Window;
                     title : STRING;
                     options : Options;
                     VAR full : STRING):BOOLEAN;

    (**
      Opens a dialog to select a file.

      The dialog will open with @oparam{full} as the initialy selected file.
      Please make sure that @oparam{full} has a trailing slash if it is a directory.
    *)

  VAR
    dlg : FileDlg;

  BEGIN
    NEW(dlg);
    dlg.Init;
    dlg.options:=options;
    dlg.SetPath(full);
    dlg.SetParent(parent);
    dlg.SetPosition(D.centerOnParent,D.centerOnParent);
    dlg.SetTitle(title);
    IF dlg.Open() THEN
      dlg.EventLoop;
      dlg.Close;

      IF dlg.result THEN
        full:=dlg.full.GetString();
        RETURN TRUE;
      END;
    END;

    full:=NIL;
    RETURN FALSE;
  END GetFile;

  PROCEDURE GetExistingFile*(parent : D.Window; title : STRING;
                             VAR full : STRING):BOOLEAN;

    (**
      Opens a dialog to select an existing file .

      See also general purpose function @oproc{GetFile}.
    *)

  VAR
    options : Options;

  BEGIN
    options:=CreateOptions();
    options.AllowExistingOnly(TRUE);
    options.SetMode(modeFile);

    RETURN GetFile(parent,title,options,full);
  END GetExistingFile;

  PROCEDURE GetDir*(parent : D.Window; title : STRING;
                    VAR full : STRING):BOOLEAN;

    (**
      Opens a dialog to select a (possibly not existing) directory.

      See also general purpose function @oproc{GetFile}.
    *)

  VAR
    options : Options;

  BEGIN
    options:=CreateOptions();
    options.AllowExistingOnly(FALSE);
    options.SetMode(modeDirectory);

    RETURN GetFile(parent,title,options,full);
  END GetDir;

  PROCEDURE GetExistingDir*(parent : D.Window; title : STRING;
                            VAR full : STRING):BOOLEAN;

    (**
      Opens a dialog to select amn existing directory.

      See also general purpose function @oproc{GetFile}.
    *)

  VAR
    options : Options;

  BEGIN
    options:=CreateOptions();
    options.AllowExistingOnly(TRUE);
    options.SetMode(modeDirectory);

    RETURN GetFile(parent,title,options,full);
  END GetExistingDir;


END VO:Dlg:File.
