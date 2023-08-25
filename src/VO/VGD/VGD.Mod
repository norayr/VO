MODULE VO:VGD:VGD [OOC_EXTENSIONS];

IMPORT D   := VO:Base:Display,
       Z   := VO:Base:Size,

       PP  := VO:Prefs:Parser,

       G   := VO:Object,
       Q   := VO:QuickHelp,
       T   := VO:Text,

              ADT:Dictionary,
              ADT:StringBuffer,
              Err,
              Object;


CONST
  stringType*       = 0;
  boolType*         = 1;
  sizeType*         = 2;
  intType*          = 3;
  singleChildType*  = 4;
  defaultChildType* = 5;

TYPE
  VGD*                  = POINTER TO VGDDesc;
  VGDDesc               = RECORD
                            (**
                              Representation of a VGD file.
                            *)
                            top- : PP.Item;
                          END;

  ErrorEntry*           = POINTER TO ErrorEntryDesc;
  ErrorEntryDesc*       = RECORD
                            next-  : ErrorEntry;
                            error- : STRING;
                            item-  : PP.Item;
                          END;

  Context*              = POINTER TO ContextDesc;
  ContextDesc*          = RECORD
                            vgd-       : VGD;
                            errorList-,
                            lastError  : ErrorEntry;
                          END;

  Attribute             = POINTER TO AttributeDesc;
  AttributeDesc        = RECORD (Object.ObjectDesc)
                           (**
                             VGD tries to directly support simple typed attributes.
                             A parser can register an attribute, gets a id for that
                             attribute and then will be called back if that
                             attribute has been found.

                             This class hold the registration information for
                             an attribute.
                           *)
                           id   : LONGINT;
                           type : LONGINT;
                           desc : STRING;
                          END;

  Parser*               = POINTER TO ParserDesc;
  ParserDesc*           = RECORD [ABSTRACT] (Object.ObjectDesc)
                            (**
                              Abstract base class for all VGD parsers.
                            *)
                            name- : STRING;  (** The name of the parser *)
                            desc  : STRING;  (** Description of the parser *)
                          END;

  ObjectParser*         = POINTER TO ObjectParserDesc;
  ObjectParserDesc*     = RECORD [ABSTRACT] (ParserDesc)
                            (**
                              Parser for objects.
                            *)
                            nextId       : LONGINT; (** The next attribute id to be used *)
                            attributes   : Dictionary.Dictionary(STRING,Attribute);

                            nameId,
                            hFlexId,
                            vFlexId,
                            widthId,
                            minWidthId,
                            heightId,
                            minHeightId,
                            quickHelpId,
                            focusId       : LONGINT;
                          END;

  WindowParser*         = POINTER TO WindowParserDesc;
  WindowParserDesc*     = RECORD [ABSTRACT] (ParserDesc)
                            (**
                              Special VGD parser for windows.
                            *)
                          END;

  ParserFactory         = POINTER TO ParserFactoryDesc;
  ParserFactoryDesc*    = RECORD
                            objects- : Dictionary.Dictionary(STRING,ObjectParser);
                            windows- : Dictionary.Dictionary(STRING,WindowParser);
                          END;

  DataDesc*             = RECORD
                            sizeMode-,
                            sizeValue-,
                            int-       : LONGINT;
                            string-    : STRING;
                            bool-      : BOOLEAN;
                            object-    : G.Object;
                          END;

VAR
  factory- : ParserFactory;

  PROCEDURE (c : Context) Init*;

  BEGIN
    c.errorList:=NIL;
    c.lastError:=NIL;
  END Init;

  PROCEDURE (c : Context) AddError*(item : PP.Item; error : STRING);

  VAR
    entry : ErrorEntry;

  BEGIN
    NEW(entry);
    entry.error:=error;
    entry.item:=item;
    entry.next:=NIL;

    IF c.errorList=NIL THEN
      c.errorList:=entry;
    ELSE
      c.lastError.next:=entry;
    END;
    c.lastError:=entry;
  END AddError;

  PROCEDURE (c : Context) DumpErrors*;

  VAR
    entry : ErrorEntry;

  BEGIN
    entry:=c.errorList;
    WHILE entry#NIL DO
      Err.String("Error item '");
      Err.String(entry.item.name^);
      Err.String("': ");
      Err.Object(entry.error);
      Err.Ln;
      entry:=entry.next;
    END;
  END DumpErrors;

  PROCEDURE (a : Attribute) GetTypeName():STRING;

  BEGIN
    CASE a.type OF
      stringType:
      RETURN "STRING";
    | boolType:
      RETURN "BOOLEAN";
    | sizeType:
      RETURN "SIZE";
    | intType:
      RETURN "LONGINT";
    | singleChildType,
      defaultChildType:
      RETURN "OBJECT";
    END;
  END GetTypeName;


  PROCEDURE (f : ParserFactory) Init;

  BEGIN
    f.objects:=NEW(Dictionary.Dictionary(STRING,ObjectParser));
    f.windows:=NEW(Dictionary.Dictionary(STRING,WindowParser));
  END Init;

  PROCEDURE (f : ParserFactory) RegisterObjectParser*(parser : ObjectParser);

  BEGIN
    ASSERT(parser.name#NIL);
    f.objects.Set(parser.name,parser);
  END RegisterObjectParser;

  PROCEDURE (f : ParserFactory) GetObjectParser*(name : STRING):ObjectParser;

  BEGIN
    IF f.objects.HasKey(name) THEN
      RETURN f.objects.Get(name);
    ELSE
      RETURN NIL;
    END;
  END GetObjectParser;

  PROCEDURE (f : ParserFactory) RegisterWindowParser*(parser : WindowParser);

  BEGIN
    ASSERT(parser.name#NIL);
    f.windows.Set(parser.name,parser);
  END RegisterWindowParser;

  PROCEDURE (f : ParserFactory) GetWindowParser*(name : STRING):WindowParser;

  BEGIN
    IF f.windows.HasKey(name) THEN
      RETURN f.windows.Get(name);
    ELSE
      RETURN NIL;
    END;
  END GetWindowParser;

  PROCEDURE (p : Parser) Init*;

  BEGIN
    p.name:=NIL;
    p.desc:=NIL;
  END Init;

  PROCEDURE (p : Parser) SetName*(name : STRING);

  BEGIN
    p.name:=name;
  END SetName;

  PROCEDURE (p : Parser) SetDescription*(desc : STRING);

  BEGIN
    p.desc:=desc;
  END SetDescription;

  PROCEDURE (p : Parser) GetDocumentation*(buffer : StringBuffer.StringBuffer);

  BEGIN
    IF p.desc#NIL THEN
      buffer.Append(p.desc);
      buffer.AppendLn;
    END;
  END GetDocumentation;

  PROCEDURE (p : Parser) ParseSize*(item : PP.Item;
                                    context : Context;
                                    VAR mode, value : LONGINT):BOOLEAN;

  BEGIN
    mode:=-1;
    value:=-1;

    item:=item.itemList;
    WHILE item#NIL DO
      IF item.name^="mode" THEN
        WITH item : PP.ValueItem DO
          IF item.HasValue("pixel") THEN
            mode:=Z.pixel;
          ELSIF item.HasValue("screenHRel") THEN
            mode:=Z.screenHRel;
          ELSIF item.HasValue("screenVRel") THEN
            mode:=Z.screenVRel;
          ELSIF item.HasValue("unit") THEN
            mode:=Z.unit;
          ELSIF item.HasValue("unitP") THEN
            mode:=Z.unitP;
          ELSIF item.HasValue("softUnit") THEN
            mode:=Z.softUnit;
          ELSIF item.HasValue("softUnitP") THEN
            mode:=Z.softUnitP;
          ELSE
            context.AddError(item,"Unknown size mode");
            RETURN FALSE;
          END;
        ELSE
          context.AddError(item,"Expected value");
          RETURN FALSE;
        END;
      ELSIF item.name^="value" THEN
        WITH item : PP.ValueItem DO
          IF ~item.GetInt(value) THEN
            context.AddError(item,"Expected numeric value");
            RETURN FALSE;
          END;
        ELSE
          context.AddError(item,"Expected value");
          RETURN FALSE;
        END;
      ELSE
        context.AddError(item,"Unexpected attribute");
        RETURN FALSE;
      END;
      item:=item.next;
    END;

    RETURN (mode>=0) & (value>=0);
  END ParseSize;

  PROCEDURE (p : ObjectParser) RegisterAttribute*(name : STRING;
                                                  type : LONGINT;
                                                  desc : STRING):LONGINT;

  VAR
    attribute : Attribute;

  BEGIN
    NEW(attribute);
    attribute.id:=p.nextId;
    INC(p.nextId);
    attribute.type:=type;
    attribute.desc:=desc;

    p.attributes.Set(name,attribute);

    RETURN attribute.id;
  END RegisterAttribute;

  PROCEDURE (p : ObjectParser) RegisterDefaultAttribute*(type : LONGINT;
                                                         desc : STRING):LONGINT;

  BEGIN
    RETURN p.RegisterAttribute("",type,desc);
  END RegisterDefaultAttribute;

  PROCEDURE (p : ObjectParser) Init*;

  BEGIN
    p.Init^;

    p.nextId:=0;
    p.attributes:=NEW(Dictionary.Dictionary(STRING,Attribute));

    p.nameId:=p.RegisterAttribute("name",stringType,"Name of the object");
    p.hFlexId:=p.RegisterAttribute("hFlex",boolType,"Object is horizontally resizeable");
    p.vFlexId:=p.RegisterAttribute("vFlex",boolType,"Object is vertically resizeable");
    p.widthId:=p.RegisterAttribute("width",sizeType,"Width of the object");
    p.minWidthId:=p.RegisterAttribute("minWidth",sizeType,"Minimal width of the object");
    p.heightId:=p.RegisterAttribute("height",sizeType,"Height of the object");
    p.minHeightId:=p.RegisterAttribute("minHeight",sizeType,"Minimal height of the object");
    p.quickHelpId:=p.RegisterAttribute("quickHelp",stringType,"Help string for this object");
    p.focusId:=p.RegisterAttribute("focus",boolType,"Object should be part of the focus chain of the window");
  END Init;

  PROCEDURE (p : ObjectParser) GetDocumentation*(buffer : StringBuffer.StringBuffer);

  VAR
    items : Dictionary.ItemArrayPtr(STRING,Attribute);
    x     : LONGINT;

  BEGIN
    p.GetDocumentation^(buffer);

    items:=p.attributes.Items();
    FOR x:=0 TO LEN(items^)-1 DO
      IF items[x].key.Equals("") THEN
        buffer.Append("<default>");
      ELSE
        buffer.Append(items[x].key);
      END;
      buffer.AppendLatin1(" : ");
      buffer.Append(items[x].value.GetTypeName());
      buffer.AppendLatin1(";");
      IF items[x].value.desc#NIL THEN
        buffer.AppendLatin1(" (* ");
        buffer.Append(items[x].value.desc);
        buffer.AppendLatin1(" *)");
      END;
      buffer.AppendLn;
    END;
  END GetDocumentation;

  PROCEDURE (p : ObjectParser) [ABSTRACT] CreateInstance*():G.Object;
  END CreateInstance;

  PROCEDURE (p : ObjectParser) SetAttribute*(object : G.Object;
                                             id : LONGINT; VAR data : DataDesc;
                                             item : PP.Item;
                                             context : Context);

  BEGIN
    IF id=p.nameId THEN
      object.SetName(data.string);
    ELSIF id=p.hFlexId THEN
      IF data.bool THEN
        object.SetFlags({G.horizontalFlex});
      ELSE
        object.RemoveFlags({G.horizontalFlex});
      END;
    ELSIF id=p.vFlexId THEN
      IF data.bool THEN
        object.SetFlags({G.verticalFlex});
      ELSE
        object.RemoveFlags({G.verticalFlex});
      END;
    ELSIF id=p.widthId THEN
      object.SetWidth(data.sizeMode,data.sizeValue);
    ELSIF id=p.minWidthId THEN
      object.SetMinWidth(data.sizeMode,data.sizeValue);
    ELSIF id=p.heightId THEN
      object.SetHeight(data.sizeMode,data.sizeValue);
    ELSIF id=p.minHeightId THEN
      object.SetMinHeight(data.sizeMode,data.sizeValue);
    ELSIF id=p.quickHelpId THEN
      object.SetHelpObject(Q.InitHelp(T.MakeLeftString(data.string),object));
    ELSIF id=p.focusId THEN
      object.RequestFocus();
    END;
  END SetAttribute;

  PROCEDURE ^ (p : ObjectParser) Parse*(vgd : PP.Item; context : Context):G.Object;

  PROCEDURE (p : Parser) GetChild*(item : PP.Item; context : Context):G.Object;

  VAR
    parser : ObjectParser;

  BEGIN
    parser:=factory.GetObjectParser(Object.NewLatin1(item.name^));
    IF parser=NIL THEN
      context.AddError(item,"Cannot find parser for object");
    ELSE
      RETURN parser.Parse(item,context);
    END;

    RETURN NIL;
  END GetChild;

  PROCEDURE (p : ObjectParser) ParseItem*(item : PP.Item;
                                          object : G.Object;
                                          context : Context):BOOLEAN;

  VAR
    attribute : Attribute;
    data      : DataDesc;
    name      : STRING;

  BEGIN
    name:=Object.NewLatin1(item.name^);
    IF p.attributes.HasKey(name) THEN
      attribute:=p.attributes.Get(name);
    ELSIF p.attributes.HasKey("") THEN
      attribute:=p.attributes.Get("");
    ELSE
      RETURN FALSE;
    END;

    CASE attribute.type OF
      sizeType:
      IF ~p.ParseSize(item,context,data.sizeMode,data.sizeValue) THEN
        context.AddError(item,"Expected value of type 'Size'");
        RETURN FALSE;
      END;
    | stringType:
      WITH item : PP.ValueItem DO
        data.string:=item.value;
      ELSE
        context.AddError(item,"Expected value of type 'STRING'");
        RETURN FALSE;
      END;
    | boolType:
      WITH item : PP.ValueItem DO
        data.bool:=item.HasValue("TRUE");
      ELSE
        context.AddError(item,"Expected value of type 'BOOLEAN'");
        RETURN FALSE;
      END;
    | intType:
      WITH item : PP.ValueItem DO
        IF ~item.GetInt(data.int) THEN
          context.AddError(item,"Expected value of type 'LONGINT'");
          RETURN FALSE;
        END;
      ELSE
        context.AddError(item,"Expected value of type 'LONGINT'");
        RETURN FALSE;
      END;
    | singleChildType:
      IF ~((item.itemList#NIL) & (item.itemList.next=NIL)) THEN
        context.AddError(item,"Attribute requests exactly one child");
        RETURN FALSE;
      END;
      data.object:=p.GetChild(item.itemList,context);
      IF data.object=NIL THEN
        context.AddError(item,"Attribute requests exactly one child");
        RETURN FALSE;
      END;
    | defaultChildType:
      data.object:=p.GetChild(item,context);
      IF data.object=NIL THEN
        RETURN FALSE;
      END;
    END;

    p.SetAttribute(object,attribute.id,data,item,context);

    RETURN TRUE;
  END ParseItem;

  PROCEDURE (p : ObjectParser) CheckPostConditions*(context : Context):BOOLEAN;

  BEGIN
    RETURN TRUE;
  END CheckPostConditions;

  PROCEDURE (p : ObjectParser) Parse*(vgd : PP.Item; context : Context):G.Object;

  VAR
    block  : PP.Item;
    object : G.Object;

  BEGIN
    object:=p.CreateInstance();

    block:=vgd.itemList;
    WHILE block#NIL DO
      IF ~p.ParseItem(block,object,context) THEN
        context.AddError(block,"Cannot parse item");
        RETURN NIL;
      END;
      block:=block.next;
    END;

    IF ~p.CheckPostConditions(context) THEN
      RETURN NIL;
    END;

    RETURN object;
  END Parse;

  PROCEDURE (p : WindowParser) [ABSTRACT] Parse*(window : D.Window;
                                                 vgd : PP.Item;
                                                 context : Context):BOOLEAN;

  END Parse;

  PROCEDURE LoadVGD*(fileName : STRING):VGD;

  VAR
    prefs    : VGD;
    notFound : BOOLEAN;

  BEGIN
    NEW(prefs);
    prefs.top:=PP.LoadConfig(fileName,notFound);
    IF (prefs.top=NIL) OR
      (prefs.top.itemList=NIL) OR
      (prefs.top.itemList.next#NIL) THEN
      RETURN NIL;
    END;

    prefs.top:=prefs.top.itemList;

    IF prefs.top=NIL THEN
      RETURN NIL;
    ELSE
      RETURN prefs;
    END;
  END LoadVGD;

  PROCEDURE LoadWindow*(window : D.Window; vgd : VGD;
                        name : STRING;
                        context : Context):BOOLEAN;

  VAR
    block,
    item,
    win    : PP.Item;
    parser : WindowParser;

  BEGIN
    context.vgd:=vgd;

    block:=vgd.top(PP.BlockItem).itemList;
    win:=NIL;
    WHILE (block#NIL) & (win=NIL) DO
      item:=block.itemList;
      WHILE (item#NIL) & (win=NIL) DO
        IF (item.name^="name") & (item IS PP.ValueItem) & item(PP.ValueItem).HasValue(name) THEN
          win:=block;
        END;

        item:=item.next;
      END;

      IF win=NIL THEN
        block:=block.next;
      END;
    END;

    IF win=NIL THEN
      context.AddError(vgd.top,"Window '"+name+"' not found");
      RETURN FALSE;
    END;

    parser:=factory.GetWindowParser(Object.NewLatin1(block.name^));
    IF parser=NIL THEN
      context.AddError(vgd.top,"No parser found");
      RETURN FALSE;
    END;

    RETURN parser.Parse(window,win,context);
  END LoadWindow;

BEGIN
  NEW(factory);
  factory.Init;
END VO:VGD:VGD.
