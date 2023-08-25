MODULE FontTest;

IMPORT D   := VO:Base:Display,

       FF  := VO:Dlg:Font,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,
<* POP *>

              Err;

VAR
  info : FF.Info;
  font : D.Font;

BEGIN
  IF ~Probe.OpenDisplay("FontTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  info:=FF.CreateInfo();
  info.SetUnicodeOnly(TRUE);
  font:=FF.GetFont(NIL,"FontTest",info);
  IF font#NIL THEN
    Err.String("Selected: ");

    IF D.fontName IN font.features THEN
      Err.String(font.name^);
    ELSE
      Err.String("???");
    END;

    Err.String(", ");

    IF D.fontPointHeight IN font.features THEN
      Err.LongInt(font.pointHeight DIV 10,0);
    ELSE
      Err.String("???");
    END;

    Err.Ln;
  ELSE
    Err.String("Nothing selected!"); Err.Ln;
  END;

  D.display.Close;
END FontTest.