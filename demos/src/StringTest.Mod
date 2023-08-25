MODULE StringTest;

IMPORT D   := VO:Base:Display,

       V   := VO:Model:Value,

              VO:OS:Probe,

<* PUSH; Warnings:=FALSE *>
              VO:Prefs:All,  (* Include preferences for all objects *)

       X1  := VO:VGD:All,
<* POP *>
              VO:VGD:VGD,

       B   := VO:Button,
       S   := VO:String,
       G   := VO:Object,
       W   := VO:Window,

              Err,Locales;

VAR
  w        : W.Window;

  object   : G.Object;
  string   : S.String;

  sm       : V.StringModel;

  msg2Close : W.Msg2Close;

  desc     : VGD.VGD;
  context  : VGD.Context;

  buffer   : ARRAY 256 OF CHAR;

BEGIN
  Locales.Set(Locales.ALL,"",buffer);

  IF ~Probe.OpenDisplay("StringTest") THEN
    Err.String("Cannot open to display!"); Err.Ln;
    HALT(1);
  END;

  desc:=VGD.LoadVGD("StringTest.vgd");
  IF desc=NIL THEN
    Err.String("Cannot load GUI description file"); Err.Ln;
    D.display.Close;
    HALT(1);
  END;

  NEW(w);
  w.Init;

  NEW(context);
  context.Init;
  IF ~VGD.LoadWindow(w,desc,"Main",context) THEN
    Err.String("Error: Cannot instantiate windows from vgd file!");
    Err.Ln;
    context.DumpErrors;
    HALT(1);
  END;

  NEW(sm);
  sm.Init();
  sm.SetString("It's cool, hu hu huh!");

  object:=w.top.GetObjectByName("String1");
  ASSERT(object#NIL);
  string:=object(S.String);
  string.SetStringAlignment(S.leftAligned);
  string.SetModel(sm);

  object:=w.top.GetObjectByName("String2");
  string:=object(S.String);
  string.SetStringAlignment(S.centerAligned);
  string.SetMode(S.password);
  string.SetModel(sm);

  object:=w.top.GetObjectByName("String3");
  string:=object(S.String);
  string.SetStringAlignment(S.rightAligned);
  string.SetModel(sm);

  object:=w.top.GetObjectByName("Close");
  NEW(msg2Close);
  msg2Close.destination:=w;
  object.AddHandler(msg2Close,B.pressedMsg);


  w.Forward(W.closeMsg,w);

  IF w.Open() THEN
    w.EventLoop;
  END;

  D.display.Close;
END StringTest.