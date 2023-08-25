MODULE VO:OS:Probe [OOC_EXTENSIONS];

IMPORT
  D          := VO:Base:Display,

  <*PUSH; Warnings:=FALSE; *>

  <* IF HAVE_PACKAGE_CURSES THEN *>
  Curses    := VO:OS:Curses:Display,
  <* END *>

  <* IF HAVE_PACKAGE_X11 THEN *>
  X11       := VO:OS:X11:Display,

  X11Im     := VO:OS:X11:Image,

  <* END *>

  <* IF HAVE_PACKAGE_CARBON THEN *>
  Carbon    := VO:OS:Carbon:Display,

  CarbonIm  := VO:OS:Carbon:Image,

  <* END *>

  <* IF HAVE_PACKAGE_WINDOWS THEN *>
  Windows := VO:OS:Windows:Display,

  WinIm     := VO:OS:Windows:Image,

  <* END *>

  <* POP *>

               OS:ProcessParameters;

CONST
  defaultDriverEnvName = "VISUALOBERON_DRIVER";

TYPE
  List = ARRAY 100 OF D.Factory;

VAR
  list    : List;
  count   : LONGINT;

  PROCEDURE AddDriver*(factory : D.Factory);

    (**
      Registers adriver. Normally there is no need
      to register a driver manually.
    *)

  BEGIN
    list[count]:=factory;
    INC(count);
  END AddDriver;

  PROCEDURE SortDrivers;

    (* The easy bubble sort *)

  VAR
    changed : BOOLEAN;
    pos     : LONGINT;
    help    : D.Factory;

  BEGIN
    IF (count=0) OR (count=1) THEN
      RETURN;
    END;

    REPEAT
      changed:=FALSE;
      pos:=0;
      WHILE (pos+1<count) DO
        IF list[pos].priority<list[pos+1].priority THEN
          (* Swap *)
          help:=list[pos+1];
          list[pos+1]:=list[pos];
          list[pos]:=help;
          changed:=TRUE;
        END;

        INC(pos);
      END;
    UNTIL ~changed;

    pos:=0;
    WHILE pos<count DO
      INC(pos);
    END;
  END SortDrivers;

  PROCEDURE OpenDisplay*(appName : STRING):BOOLEAN;

  VAR
    current : LONGINT;
    default : STRING;

  BEGIN
    default:=ProcessParameters.GetEnv(defaultDriverEnvName);

    IF (default#NIL) & (default.length#0) THEN
      current:=0;
      WHILE (current<count) & ~list[current].driverName.Equals(default) DO
        INC(current);
      END;

      IF current<count THEN
        D.SetFactory(list[current]);

        D.display.SetAppName(appName);
        IF D.display.Open() THEN
          RETURN TRUE;
        END;
      END;
    END;

    FOR current:=0 TO count-1 DO
      IF ~list[current].driverName.Equals(default) THEN
        D.SetFactory(list[current]);

        D.display.SetAppName(appName);
        IF D.display.Open() THEN
          RETURN TRUE;
        END;
      END;
    END;

    RETURN FALSE;
  END OpenDisplay;

BEGIN
  count:=0;

  <* IF HAVE_PACKAGE_CURSES THEN *>
  AddDriver(Curses.factory);
  <* END *>

  <* IF HAVE_PACKAGE_X11 THEN *>
  AddDriver(X11.factory);
  <* END *>

  <* IF HAVE_PACKAGE_CARBON THEN *>
  AddDriver(Carbon.factory);
  <* END *>

  <* IF HAVE_PACKAGE_WINDOWS THEN *>
  AddDriver(Windows.factory);
  <* END *>

  SortDrivers;

END VO:OS:Probe.
