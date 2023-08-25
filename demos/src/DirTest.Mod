MODULE DirTest;

IMPORT D   := VO:Base:Display,

       DF  := VO:Dlg:File,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,
<* POP *>

              Err,
              IO,
       pp  := OS:ProcessParameters;

VAR
  file    : STRING;
  options : DF.Options;

BEGIN
  IF ~Probe.OpenDisplay("DirTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  TRY
    file:=pp.GetCwd();
    file:=DF.FixDir(file);
  CATCH IO.Error:
    file:="/";
  END;

  options:=DF.CreateOptions();
  options.AllowExistingOnly(TRUE);
  options.SetMode(DF.modeFile);

  IF DF.GetFile(NIL,"DirTest",options,file) THEN
    Err.String("Selected: "); Err.Object(file); Err.Ln;
  ELSE
    Err.String("Nothing selected!"); Err.Ln;
  END;

  D.display.Close;
END DirTest.