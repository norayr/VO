MODULE VO:Model:DirTable;

IMPORT Z   := VO:Base:Size,
       U   := VO:Base:Util,

       MH  := VO:Model:Header,
       SM  := VO:Model:Selection,
       MT  := VO:Model:Table,

       Dir := Directory,

       co  := IntStr;

TYPE

  DirEntry      * = POINTER TO DirEntryDesc;
  DirEntryDesc  * = RECORD (Dir.DirEntryDesc)
                      fileName* : STRING;
                    END;

  DirList       * = POINTER TO ARRAY OF DirEntry;

  DirModel     * = POINTER TO DirModelDesc;
  DirModelDesc * = RECORD (MT.TableModelDesc)
                      list   : DirList;
                      size   : LONGINT;
                      buffer : U.Text;
                    END;

  PROCEDURE (f : DirModel) Init*;

  VAR
    h : MH.AHeaderModel;

  BEGIN
    f.Init^;

    NEW(h);
    h.Init;

    f.header:=h;
    f.header(MH.AHeaderModel).SetLabel(0,"Filename");
    f.header.SetLabelSize(0,Z.stdCharWidth,25);
    f.header(MH.AHeaderModel).SetLabel(1,"Size");
    f.header.SetLabelSize(1,Z.stdCharWidth,8);
    f.header(MH.AHeaderModel).SetLabel(2,"Rights");
    f.header.SetLabelSize(2,Z.stdCharWidth,10);

    f.list:=NIL;
    f.size:=0;

    NEW(f.buffer,1024);
  END Init;

  PROCEDURE (f : DirModel) SetDir*(dir : DirList);

  VAR
    x,
    changes : LONGINT;
    switch  : BOOLEAN;
    entry   : DirEntry;

  BEGIN
    f.selection.Clear;

    f.list:=dir;
    f.size:=0;
    WHILE (f.size<LEN(f.list^)) & (f.list[f.size]#NIL) DO
      INC(f.size);
    END;

    (* Sorting (currently bubble sort, but we should switch to a better one) *)
    REPEAT
      changes:=0;
      FOR x:=0 TO f.size-2 DO
        switch:=FALSE;
        IF f.list[x].type#f.list[x+1].type THEN
          IF f.list[x+1].type=Dir.directory THEN
            switch:=TRUE;
          END;
        ELSE
          IF f.list[x].fileName.Compare(f.list[x+1].fileName)>0 THEN
            switch:=TRUE;
          END;
        END;

        IF switch THEN
          INC(changes);
          entry:=f.list[x+1];
          f.list[x+1]:=f.list[x];
          f.list[x]:=entry;
        END;
      END;
    UNTIL (changes=0);

    f.Notify(NIL);
  END SetDir;

  PROCEDURE (f : DirModel) GetAlignment*(x,y : LONGINT):LONGINT;

  BEGIN
    IF (x>=2) THEN
      RETURN MT.rightAlign;
    ELSE
      RETURN MT.leftAlign;
    END;
  END GetAlignment;

  PROCEDURE (f : DirModel) GetSelection*():DirEntry;

  VAR
    line : LONGINT;

  BEGIN
    line:=f.selection(SM.SingleLine).line;
    IF (f.list#NIL) & (line>=1) & (line<=f.size) THEN
      RETURN f.list[line-1];
    ELSE
      RETURN NIL;
    END;
  END GetSelection;

  PROCEDURE (f : DirModel) GetColumns*():LONGINT;

  BEGIN
    RETURN 3;
  END GetColumns;

  PROCEDURE (f : DirModel) GetRows*():LONGINT;

  BEGIN
    RETURN f.size;
  END GetRows;

  PROCEDURE (f : DirModel) GetColumnWidth*(index : LONGINT):LONGINT;

  BEGIN
    RETURN f.header.GetLabelSize(index);
  END GetColumnWidth;

  PROCEDURE (f : DirModel) GetString*(x,y : LONGINT):STRING;

  BEGIN
    IF x=1 THEN
      RETURN f.list[y-1].fileName;
    END;

    RETURN NIL;
  END GetString;

  PROCEDURE (f : DirModel) GetText*(x,y : LONGINT):U.Text;

  VAR
    size : LONGINT;

  BEGIN
    IF (f.list#NIL) & (y>=1) & (y<=f.GetRows()) & (x>=1) & (x<=f.GetColumns()) THEN
      IF x=2 THEN
        IF f.list[y-1].type=Dir.directory THEN
          COPY("(dir)",f.buffer^);
        ELSE
          size:=f.list[y-1].size(* DIV 1024;
          IF f.list[y-1].size MOD 1024>=512 THEN
            INC(size);
          END*);
          co.IntToStr(size,f.buffer^);
        END;
        RETURN f.buffer;
      ELSIF x=3 THEN
        COPY("---------",f.buffer^);
        IF Dir.rightExecute IN f.list[y-1].user THEN
          f.buffer[0]:="x";
        END;
        IF Dir.rightRead IN f.list[y-1].user THEN
          f.buffer[1]:="r";
        END;
        IF Dir.rightWrite IN f.list[y-1].user THEN
          f.buffer[2]:="w";
        END;
        IF Dir.rightExecute IN f.list[y-1].group THEN
          f.buffer[3]:="x";
        END;
        IF Dir.rightRead IN f.list[y-1].group THEN
          f.buffer[4]:="r";
        END;
        IF Dir.rightWrite IN f.list[y-1].group THEN
          f.buffer[5]:="w";
        END;
        IF Dir.rightExecute IN f.list[y-1].other THEN
          f.buffer[6]:="x";
        END;
        IF Dir.rightRead IN f.list[y-1].other THEN
          f.buffer[7]:="r";
        END;
        IF Dir.rightWrite IN f.list[y-1].other THEN
          f.buffer[8]:="w";
        END;
        RETURN f.buffer;
      END;
    END;

    RETURN NIL;
  END GetText;

END VO:Model:DirTable.