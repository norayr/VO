(*
    Generated parser for VisualOberon preferences.
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

MODULE VO:Prefs:Parser;

IMPORT
       U   := VO:Base:Util,

              XML:Builder,
(*              XML:Builder:Validation,*)
              XML:DTD,
              XML:Parser,
<*PUSH; Warnings:=FALSE; *>
              XML:UnicodeCodec:UTF8,
              XML:UnicodeCodec:ImportAll,
<* POP *>
              XML:Writer,

              Err,
              Exception,
       I   := IntStr,
              IO,
       f   := IO:FileChannel,
       LS  := LongStrings,
              Object,
       f2  := OS:Files,
              OS:Path,
              StdChannels,
       str := Strings,
       T   := XML:Writer;

TYPE
  Item*              = POINTER TO ItemDesc;
  ItemDesc*          = RECORD
                         next-,last : Item;

                         itemList-,
                         itemLast,
                         parent     : Item;

                         name-      : U.Text;
                       END;

  BlockItem*         = POINTER TO BlockItemDesc;
  BlockItemDesc*     = RECORD (ItemDesc);
                       END;

  ValueItem*         = POINTER TO ValueItemDesc;
  ValueItemDesc*     = RECORD (ItemDesc)
                         value- : STRING;
                       END;

  ConfigParser*      = POINTER TO ConfigParserDesc;
  ConfigParserDesc*  = RECORD (Builder.BuilderDesc)
                         top : Item;
                       END;

  PROCEDURE (v : ValueItem) SetValue*(name,value : ARRAY OF CHAR);

  BEGIN
    NEW(v.name,str.Length(name)+1);
    COPY(name,v.name^);
    v.value:=Object.NewLatin1(value);
  END SetValue;

  PROCEDURE (v : ValueItem) GetValue*(VAR value : ARRAY OF CHAR);

  VAR
    str8 : Object.String8;
    txt8 : Object.CharsLatin1;

  BEGIN
    str8:=v.value.ToString8(0X);
    txt8:=str8.CharsLatin1();
    COPY(txt8^,value);
  END GetValue;

  PROCEDURE (v : ValueItem) HasValue*(value : STRING):BOOLEAN;

  BEGIN
    IF v.value#NIL THEN
      RETURN v.value.Equals(value);
    ELSE
      RETURN value=NIL;
    END;
  END HasValue;

  PROCEDURE (v : ValueItem) SetBool*(name : ARRAY OF CHAR; value : BOOLEAN);

  BEGIN
    IF value THEN
      v.SetValue(name,"TRUE");
    ELSE
      v.SetValue(name,"FALSE");
    END;
  END SetBool;

  PROCEDURE (v : ValueItem) GetBool*():BOOLEAN;

  VAR
    str8 : Object.String8;
    txt8 : Object.CharsLatin1;
    txt  : U.Text;

  BEGIN
    str8:=v.value.ToString8(0X);
    txt8:=str8.CharsLatin1();
    NEW(txt,str8.length+1);
    COPY(txt8^,txt^);
    str.Capitalize(txt^);
    RETURN txt^="TRUE";
  END GetBool;

  PROCEDURE (v : ValueItem) SetInt*(name : ARRAY OF CHAR; value : LONGINT);

  VAR
    string : ARRAY 12 OF CHAR;

  BEGIN
    I.IntToStr(value,string);
    v.SetValue(name,string);
  END SetInt;

  PROCEDURE (v : ValueItem) GetInt*(VAR value : LONGINT):BOOLEAN;

  VAR
    res  : I.ConvResults;
    str8 : Object.String8;
    txt8 : Object.CharsLatin1;

  BEGIN
    str8:=v.value.ToString8(0X);
    txt8:=str8.CharsLatin1();
    I.StrToInt(txt8^,value,res);
    RETURN res=I.strAllRight;
  END GetInt;

  PROCEDURE (i : Item) Init*;

  BEGIN
    i.next:=NIL;
    i.last:=NIL;

    i.itemList:=NIL;
    i.itemLast:=NIL;
  END Init;

  PROCEDURE (i : Item) AddItem*(item : Item);

  BEGIN
    item.parent:=i;
    IF i.itemList=NIL THEN
      i.itemList:=item;
    ELSE
      i.itemLast.next:=item;
      item.last:=i.itemLast;
    END;
    i.itemLast:=item;
  END AddItem;

  PROCEDURE (i : Item) GetEntry*(path : ARRAY OF CHAR):Item;

  VAR
    rest    : U.Text;
    pos,len : INTEGER;
    item    : Item;

    PROCEDURE FindSlash():INTEGER;

    VAR
      pos : INTEGER;

    BEGIN
      pos:=0;
      WHILE pos<LEN(path) DO
        IF path[pos]="/" THEN
          RETURN pos;
        END;
        INC(pos);
      END;
      RETURN -1;
    END FindSlash;

  BEGIN
    pos:=FindSlash();
    IF pos>0 THEN
      path[pos]:=0X;
      item:=i.itemList;
      WHILE item#NIL DO
        IF (item.name#NIL) & (item.name^=path) THEN
          path[pos]:="/";
          len:=str.Length(path)-pos;
          NEW(rest,len+1);
          str.Extract(path,pos+1,len,rest^);
          RETURN item.GetEntry(rest^);
        END;
        item:=item.next;
      END;
      RETURN NIL;
    ELSE
      item:=i.itemList;
      WHILE item#NIL DO
        IF (item.name#NIL) & (item.name^=path) THEN
          RETURN item;
        END;
        item:=item.next;
      END;
      RETURN NIL;
    END;
  END GetEntry;

  PROCEDURE (i : Item) GetStringEntry*(name : ARRAY OF CHAR; VAR text : ARRAY OF CHAR):BOOLEAN;

  VAR
    value : Item;
    str8  : Object.String8;
    txt8  : Object.CharsLatin1;

  BEGIN
    value:=i.GetEntry(name);
    IF (value#NIL) & (value IS ValueItem) & (value(ValueItem).value#NIL) THEN
      str8:=value(ValueItem).value.ToString8(0X);
      txt8:=str8.CharsLatin1();
      COPY(txt8^,text);
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END;
  END GetStringEntry;

  PROCEDURE (i : Item) GetIntEntry*(name : ARRAY OF CHAR; default : LONGINT):LONGINT;

  VAR
    value  : Item;
    number : LONGINT;

  BEGIN
    number:=default;
    value:=i.GetEntry(name);
    IF (value#NIL) THEN
      WITH value : ValueItem DO
        IF value.GetInt(number) THEN
        END;
      ELSE
      END;
    END;

    RETURN number;
  END GetIntEntry;

  PROCEDURE (i : Item) GetBoolEntry*(name : ARRAY OF CHAR; default : BOOLEAN):BOOLEAN;

  VAR
    value : Item;
    bool  : BOOLEAN;

  BEGIN
    bool:=default;
    value:=i.GetEntry(name);
    IF value#NIL THEN
      WITH value : ValueItem DO
        bool:=value.GetBool();
      ELSE
      END;
    END;

    RETURN bool;
  END GetBoolEntry;

  PROCEDURE (i : Item) GetSubEntry*(item,name,value : ARRAY OF CHAR):Item;

    (**
      Searches for an entry @oparam{item}. If this item exists and a direct
      subitem with name @oparam{name} and value @oparam{value} exists then this
      item is returned. Else @code{NIL} will is returned.
    *)

  VAR
    entry  : Item;
    buffer : ARRAY 256 OF CHAR;

  BEGIN
    entry:=i.itemList;
    WHILE entry#NIL DO
      IF (entry.name#NIL) & (entry.name^=item) THEN
        IF entry.GetStringEntry(name,buffer) & (buffer=value) THEN
          RETURN entry;
        END;
      END;
      entry:=entry.next;
    END;

    RETURN NIL;
  END GetSubEntry;

  PROCEDURE (i : Item) PrintXML*(writer : T.Writer);

  BEGIN
  END PrintXML;

  PROCEDURE (v : BlockItem) SetName*(name : ARRAY OF CHAR);

  BEGIN
    NEW(v.name,str.Length(name)+1);
    COPY(name,v.name^);
  END SetName;

  PROCEDURE (b : BlockItem) PrintXML*(writer : T.Writer);

  VAR
    x    : LONGINT;
    help : Item;

  BEGIN
    writer.StartTagLatin1(b.name^,FALSE);

    x:=0;
    help:=b.itemList;
    WHILE help#NIL DO
      IF help IS ValueItem THEN
        help.PrintXML(writer);
        INC(x);
      END;
      help:=help.next;
    END;

    help:=b.itemList;
    WHILE help#NIL DO
      IF help IS BlockItem THEN
        help.PrintXML(writer);
      END;
      help:=help.next;
    END;

    writer.EndTag;
  END PrintXML;

  PROCEDURE CreateBlockItem*(name : ARRAY OF CHAR):BlockItem;

  VAR
    item : BlockItem;

  BEGIN
    NEW(item);
    item.Init;
    item.SetName(name);

    RETURN item;
  END CreateBlockItem;

  PROCEDURE (i : Item) AddItemValue*(name,value : ARRAY OF CHAR);

  VAR
    item : ValueItem;

  BEGIN
    NEW(item);
    item.Init;
    item.SetValue(name,value);
    i.AddItem(item);
  END AddItemValue;

  PROCEDURE (i : Item) AddItemBool*(name : ARRAY OF CHAR; value : BOOLEAN);

  VAR
    item : ValueItem;

  BEGIN
    NEW(item);
    item.Init;
    item.SetBool(name,value);
    i.AddItem(item);
  END AddItemBool;

  PROCEDURE (i : Item) AddItemInt*(name : ARRAY OF CHAR; value : LONGINT);

  VAR
    item : ValueItem;

  BEGIN
    NEW(item);
    item.Init;
    item.SetInt(name,value);
    i.AddItem(item);
  END AddItemInt;

  PROCEDURE (v : ValueItem) PrintXML*(writer : T.Writer);

  VAR
    buffer : ARRAY 256 OF LONGCHAR;

  BEGIN
    COPY(v.name^,buffer);
    writer.AttrObject(buffer,v.value);
  END PrintXML;

  (* --- *)

  PROCEDURE (p : ConfigParser) StartDocument*(documentEntity: DTD.ExternalEntity);

  VAR
    block : BlockItem;

  BEGIN
    block:=CreateBlockItem("TOP");
    p.top:=block;
  END StartDocument;

  PROCEDURE (p : ConfigParser) StartElement*(namespaceDecl: DTD.NamespaceDeclaration;
                                       localName: DTD.String);

  VAR
    block : BlockItem;

  BEGIN
    NEW(block);
    block.Init;
    NEW(block.name,LS.Length(localName^)+1);
    LS.Short(localName^,"?",block.name^);
    p.top.AddItem(block);
    p.top:=block;
  END StartElement;

  PROCEDURE (p : ConfigParser) EndElement*(namespaceDecl: DTD.NamespaceDeclaration;
                                     localName: DTD.String);

  BEGIN
    p.top:=p.top.parent;
  END EndElement;

  PROCEDURE (p : ConfigParser) Attribute*(namespaceDecl: DTD.NamespaceDeclaration;
                                    localName: DTD.String;
                                    attrDecl: DTD.AttrDecl;
                                    value: DTD.AttValue;
                                    specified: BOOLEAN);

  VAR
    item : ValueItem;
    res  : DTD.String;
    bool : BOOLEAN;

  BEGIN
    NEW(item);
    item.Init;
    NEW(item.name,LS.Length(localName^)+1);
    LS.Short(localName^,"?",item.name^);
    res:=value.FlattenValue(TRUE,bool);
    item.value:=Object.NewUTF16(res^);

    p.top.AddItem(item);
  END Attribute;

  PROCEDURE (p : ConfigParser) AttributesDone*;

  BEGIN
    (* nothing to do *)
  END AttributesDone;

  PROCEDURE LoadConfig*(file : STRING; VAR notFound : BOOLEAN):Item;

  VAR
    canon   : Parser.Parser;
    builder : Builder.Builder;
    ex      : Exception.Exception;
    config  : ConfigParser;
    name    : Object.CharsLatin1;

    PROCEDURE CreateParser(): Parser.Parser;

    VAR
      p    : Parser.Parser;
      ex   : Exception.Exception;

    BEGIN
      NEW(canon);
      NEW(config);
      builder:=config;
      p:=NIL;

      TRY
        p := Parser.NewFile(name^, NIL, NIL, NIL, builder);
        p. followExternalRef := TRUE;
        p. enforceQNames := FALSE;   (* enable QName and NCName checks *)
        p. validating := TRUE; (* enable parser-level validation *)
      CATCH IO.FileNotFound:
        notFound:=TRUE;
      CATCH IO.Error:
        ex:=Exception.Current();
        Err.String("Error loading '"); Err.String(name^); Err.String("': ");
        Err.Object(ex.GetMessage()); Err.Ln;
      END;
      RETURN p
    END CreateParser;

  BEGIN
    notFound:=FALSE;

    name:=Path.Encode(file);

    canon:=CreateParser();
    IF canon=NIL THEN
      RETURN NIL;
    END;

    TRY
      canon.ParseDocument;
    CATCH IO.Error:
      ex:=Exception.Current();
      Err.String("Error loading '"); Err.Object(file); Err.String("': ");
      Err.Object(ex.GetMessage()); Err.Ln;
      RETURN NIL;
    END;

    IF (canon.errList.msgCount # 0) THEN
      canon.errList.Write(StdChannels.stderr);
      RETURN NIL;
    ELSE
      RETURN config.top;
    END
  END LoadConfig;

  PROCEDURE SaveConfig*(fileName : STRING; top : Item);

  VAR
    name    : Object.CharsLatin1;
    current : Item;
    file    : IO.ByteChannel;
    writer  : Writer.Writer;
    ex      : Exception.Exception;

  BEGIN
    IF ~f2.Exists(Path.DirName(fileName)) THEN
      TRY
        f2.MkDir(Path.DirName(fileName),f2.defaultMode);
      CATCH IO.FileExists:
      CATCH IO.Error:
        ex:=Exception.Current();
        Err.String("Error creating directory '");
        Err.Object(Path.DirName(fileName));
        Err.String("': "); Err.Object(ex.GetMessage()); Err.Ln;
        RETURN;
      END;
    END;

    name:=Path.Encode(fileName);

    TRY
      file:=f.Open(Object.NewLatin1(name^),{f.write,f.create,f.truncate});
      writer:=Writer.New(file,UTF8.factory,TRUE,2);
      writer.WriteTextDecl("1.0","");
      writer.NewLine;

      current:=top;
      WHILE current#NIL DO
        current.PrintXML(writer);
        current:=current.next;
      END;

      writer.EndOfText;
      file.Close;
    CATCH IO.Error:
      ex:=Exception.Current();
      Err.String("Error saving '");Err.Object(fileName); Err.String("': ");
      Err.Object(ex.GetMessage()); Err.Ln;
    END;
  END SaveConfig;

END VO:Prefs:Parser.