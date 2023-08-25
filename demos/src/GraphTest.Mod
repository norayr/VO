MODULE GraphTest;

IMPORT
  VO:OS:Probe,
  ProgramArgs,
  TextRider,
  D := VO:Base:Display,     (* Display stuff *)
  O := VO:Object,
  GraphModel,
  GraphView,

      
  T := VO:Text,        (* The textclass *)
  W := VO:Window,      (* Window class *)
  WG := VO:WindowGroup, (* The window group object *)

  Err;           (* Simple error IO *)


TYPE
  Window     = POINTER TO WindowDesc;
  WindowDesc = RECORD (W.WindowDesc)
                 model : GraphModel.Model;
               END;

VAR
  w : Window;
  model : GraphModel.Model;

  msg2Exit : D.Msg2Exit;     (* a simple message converter *)

  PROCEDURE (w : Window) InitModel(model : GraphModel.Model);
  BEGIN
    w.model := model;
  END InitModel;

  PROCEDURE (w : Window) PreInit*;

  VAR
    wGroup : WG.WindowGroup; (* The window group *)
    v : GraphView.Graph;
    i : LONGINT;
  BEGIN
    NEW(v);
    GraphView.Init(v, D.display);
    v.SetModel(w.model);
    v.SetFlags({O.horizontalFlex, O.verticalFlex});

    NEW(wGroup);

    wGroup.Init;

    (*
      Set the contents of the window group.
      * First parameter is a pointer to a menu strip, here NIL,
        since we don't have one.
      * Second parameter is a pointer to a (group)object, that represents
        the rest of the window contents.
        Here we use a convenience function of the text class, that
        generates a standard text object that is centered. The escape
        sequences tell text object to display the text smart (i.e.
        black on white), italic and with the larges fontsize (0-9)
        available.
      * Third parameter tell the window groub object to put some space
        around the text object.

    *)

    wGroup.Set(NIL,v,TRUE);

    (* Set the top object of the window to the window group *)
    w.SetTop(wGroup);

    w.PreInit^;
  END PreInit;

PROCEDURE Usage(); 
BEGIN
  Err.String("GraphTest circle <n>"); Err.Ln;
  Err.String("  Create circle with <n> nodes"); Err.Ln;
  Err.String("GraphTest tree <depth> <branch>"); Err.Ln;
  Err.String("  Create tree with depth <depth> and branching factor <branch>"); Err.Ln;
  Err.String("GraphTest cube <n>"); Err.Ln;
  Err.String("  Create hyper-cube of order <n> (2=square, 3=cube)"); Err.Ln;
  Err.String("GraphTest empty"); Err.Ln; 
  Err.String("  Create empty graph. Use shift-click to add nodes"); Err.Ln;
END Usage;

PROCEDURE ParseArgs () : GraphModel.Model;
VAR
  in : TextRider.Reader;
  root, count, depth, branch : LONGINT;
  command : ARRAY 32 OF CHAR;
  m : GraphModel.Model;
  error : BOOLEAN;

  PROCEDURE Error() : BOOLEAN;
  VAR message : ARRAY 128 OF CHAR;
  BEGIN
    IF in.res # TextRider.done THEN
      in.res.GetText(message);
      Err.String("Error: "); Err.String(message); Err.Ln;
      Usage();
      error := TRUE;
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END Error;

BEGIN
  NEW(m);
  GraphModel.Init(m, 10, 10, 10);
  root := 0;

  IF ProgramArgs.args.ArgNumber() = 0 THEN
    m.CircleGraph(root, 20);
  ELSE
    in := TextRider.ConnectReader(ProgramArgs.args);
  
    in.ReadLn();
    in.ReadIdentifier(command); in.ReadLn;
    IF Error() THEN RETURN NIL END;
  
    IF command = "circle" THEN
      in.ReadLInt(count); in.ReadLn;
      IF Error() THEN RETURN NIL END;
      m.CircleGraph(root, count);
    ELSIF command = "tree" THEN
      in.ReadLInt(depth); in.ReadLn;
      in.ReadLInt(branch); in.ReadLn;
      IF Error() THEN RETURN NIL END;
      m.TreeGraph(root, depth, branch);
    ELSIF command = "cube" THEN
      in.ReadLInt(depth); in.ReadLn;
      IF Error() THEN RETURN NIL END;
      m.CubeGraph(root, depth);
    ELSIF command = "empty" THEN
    ELSE
      Err.String("Unknown graph type: "); Err.String(command); Err.Ln;
      Usage();
      RETURN NIL;
    END
  END;

  m.Scatter();
  m.Layout();
  RETURN m;
END ParseArgs;

BEGIN
  model := ParseArgs();
  IF model = NIL THEN
    Err.String("Invalid model specified"); Err.Ln;
    RETURN
  END;

  IF ~Probe.OpenDisplay("GraphTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;
  D.display.SetAppName("GraphTest");

  NEW(w);
  w.InitModel(model);
  w.Init;
  w.SetTitle("Graph Test");

  NEW(msg2Exit);
  msg2Exit.destination:=D.display;
  w.AddHandler(msg2Exit,W.closeMsg);

  IF w.Open() THEN
    D.display.EventLoop;
  END;

  D.display.Close;
END GraphTest.
