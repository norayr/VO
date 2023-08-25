MODULE VO:Edit:Syntax [OOC_EXTENSIONS];

  (*
    Part of the VO internal multiline text edit control.
    Copyright (C) 2003 Tim Teulings

    This module is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with OOC. If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)

IMPORT U   := VO:Base:Util,

              Ascii,
       str := Strings;


CONST
  Word             * =  0;
  Escape           * =  1;
  RecurseUp        * =  2;
  RecurseDown      * =  3;
  Push             * =  4;
  Pop              * =  5;
  BlockStart       * =  6;
  BlockEnd         * =  7;
(*  Indent           * =  8;
  Exdent           * =  9;
  IndentAbsolute   * = 10;
  AlignAbsolute    * = 11;*)

  stateRecursionDepth  = 10;

TYPE
  StateType * = SHORTINT;
  StateCount* = SHORTINT;

  IndentType*  = SHORTINT;
  IndentCount* = SHORTINT;

CONST
  maxState   = MAX(StateType);

TYPE
  StateStackEntry = RECORD
                      state      : StateType;   (** the state the first character of row is in *)
                      stateCount : StateCount;  (** For recursive states, the current cursion count *)
                    END;

  StateInfo* = RECORD
                 stack   : ARRAY stateRecursionDepth OF StateStackEntry;
                 current : StateCount;
               END;

  StyleData*     = POINTER TO StyleDataDesc;
  StyleDataDesc* = RECORD
                   END;

  Style*     = POINTER TO StyleDesc;
  StyleDesc* = RECORD
                 data- : StyleData;
               END;

  Token*      = POINTER TO TokenDesc;
  Syntax*     = POINTER TO SyntaxDesc;

  TokenDesc   = RECORD
                  next       : Token;
                  nextState  : StateType;
                  style      : Style;
                  syntax     : Syntax;
                  flags-     : SET;
                END;

  Keyword*    = POINTER TO KeywordDesc;
  KeywordDesc = RECORD (TokenDesc)
                  name-  : U.Text;
                  match  : Token;
                END;

  Letter*     = POINTER TO LetterDesc;
  LetterDesc  = RECORD (TokenDesc)
                END;

  Number*     = POINTER TO NumberDesc;
  NumberDesc  = RECORD (TokenDesc)
                END;

  Default*    = POINTER TO DefaultDesc;
  DefaultDesc = RECORD (TokenDesc)
                END;

  StateDesc   = RECORD
                  starters  : ARRAY 256 OF Token;
                  style     : Style;
                  default   : Default;
                END;

  SyntaxDesc* = RECORD
                  next          : Syntax;
                  name-         : STRING;
                  word-         : ARRAY 256 OF BOOLEAN;

                  tabSize-      : LONGINT;
                END;

  TokenSyntax*     = POINTER TO TokenSyntaxDesc;
  TokenSyntaxDesc* = RECORD (SyntaxDesc)
                       stateMachine  : ARRAY maxState OF StateDesc;
                     END;

VAR
  syntaxList : Syntax;

  NormalStyle-,
  KeywordStyle-,
  StringStyle-,
  CommentStyle-,
  DocuStyle-,
  SpecialStyle-,
  CursorStyle-,
  MarkStyle-,
  SelectionStyle-,
  BookmarkStyle-,
  LineStyle-,
  OperatorStyle-,
  PreprocessStyle-,
  DatatypeStyle-,
  NumberStyle-,
  FunctionStyle-,
  IncludeStyle-,
  Quote1Style-,
  Quote2Style-,
  Quote3Style-,
  Quote4Style-,
  HeaderStyle-,
  WarningStyle-,
  ErrorStyle-   : Style;

  PROCEDURE (VAR s : StateInfo) Init*;

  BEGIN
    s.current:=0;
    s.stack[0].state:=0;
    s.stack[0].stateCount:=0;
  END Init;

  PROCEDURE (VAR s : StateInfo) Push*(state : StateType);

  BEGIN
    INC(s.current);
    s.stack[s.current].state:=state;
    s.stack[s.current].stateCount:=1;
  END Push;

  PROCEDURE (VAR s : StateInfo) Pop*;

  BEGIN
    DEC(s.current);
  END Pop;

  PROCEDURE (VAR s : StateInfo) Inc*();

  BEGIN
    INC(s.stack[s.current].stateCount);
  END Inc;

  PROCEDURE (VAR s : StateInfo) Dec*();

  BEGIN
    DEC(s.stack[s.current].stateCount);
    IF (s.stack[s.current].stateCount=0) & (s.current>0) THEN
      DEC(s.current);
    END;
  END Dec;

  PROCEDURE (VAR s : StateInfo) GetState*():StateType;

  BEGIN
    RETURN s.stack[s.current].state;
  END GetState;

  PROCEDURE (VAR s : StateInfo) GetCount*():StateCount;

  BEGIN
    RETURN s.stack[s.current].stateCount;
  END GetCount;

  PROCEDURE (VAR s : StateInfo) Equals*(other[NO_COPY] : StateInfo):BOOLEAN;

  BEGIN
    RETURN (s.stack[s.current].state=other.stack[other.current].state)
         & (s.stack[s.current].stateCount=other.stack[other.current].stateCount);
  END Equals;

  PROCEDURE (s : Syntax) Init*(name : STRING);

  VAR
    x : LONGINT;

  BEGIN
    s.name:=name;

    FOR x:=0 TO 255 DO
      s.word[x]:=TRUE;
    END;

    s.word[ORD(Ascii.lf)]:=FALSE;
    s.word[ORD(Ascii.ht)]:=FALSE;

    s.tabSize:=8;
  END Init;

  PROCEDURE (d : Default) Init*(style : Style; flags : SET);

  BEGIN
    d.next:=NIL;
    d.nextState:=0;
    d.syntax:=NIL;
    d.style:=style;
    d.flags:=flags;
  END Init;

  PROCEDURE (s : TokenSyntax) Init*(name : STRING);

  VAR
    x,y : LONGINT;

  BEGIN
    s.Init^(name);
    FOR x:=0 TO LEN(s.stateMachine) -1 DO
      FOR y:=0 TO LEN(s.stateMachine[x].starters)-1 DO
        s.stateMachine[x].starters[y]:=NIL;
      END;
      s.stateMachine[x].style:=NormalStyle;
      NEW(s.stateMachine[x].default);
      s.stateMachine[x].default.Init(NormalStyle,{});
    END;
  END Init;

  PROCEDURE (s : Syntax) SetDelimiterChar*(delimiter : CHAR);

  BEGIN
    s.word[ORD(delimiter)]:=FALSE;
  END SetDelimiterChar;

  PROCEDURE (s : Syntax) SetDelimiter*(delimiter : ARRAY OF CHAR);

  VAR
    x : LONGINT;

  BEGIN
    FOR x:=0 TO str.Length(delimiter)-1 DO
      s.SetDelimiterChar(delimiter[x]);
    END;
  END SetDelimiter;

  PROCEDURE (s : Syntax) SetTabSize*(size : LONGINT);

  BEGIN
    s.tabSize:=size;
  END SetTabSize;

  PROCEDURE (s : Syntax) ParseToken*(text : U.Text;
                                     VAR x : LONGINT;
                                     VAR y : LONGINT;
                                     VAR state : StateInfo):Token;

  BEGIN
    RETURN NIL;
  END ParseToken;

  PROCEDURE (s : Syntax) GetStyle*(VAR state(*[NO_COPY]*) : StateInfo):Style;

  BEGIN
   RETURN NormalStyle;
  END GetStyle;

  (* --- TokenSyntax --- *)

  PROCEDURE (s : TokenSyntax) SetScheme*(state : StateType; style : Style);

  BEGIN
    s.stateMachine[state].style:=style;
    s.stateMachine[state].default.style:=style;
  END SetScheme;

  PROCEDURE (s : TokenSyntax) AddKeywordInternal(state     : StateType;
                                                 name      : ARRAY OF CHAR;
                                                 length    : LONGINT;
                                                 style     : Style;
                                                 flags     : SET;
                                                 nextState : StateType);

  VAR
    token : Keyword;
    key   : U.Text;

  BEGIN
    NEW(key,length+1);
    COPY(name,key^);


    NEW(token);
    token.name:=key;
    token.style:=style;
    token.flags:=flags;
    token.nextState:=nextState;
    token.syntax:=s;
    token.match:=NIL;

    token.next:=s.stateMachine[state].starters[ORD(key[0])];
    s.stateMachine[state].starters[ORD(key[0])]:=token;
  END AddKeywordInternal;

  PROCEDURE (s : TokenSyntax) AddKeyword*(state     : StateType;
                                          name      : ARRAY OF CHAR;
                                          style     : Style;
                                          flags     : SET;
                                          nextState : StateType);
  BEGIN
    s.AddKeywordInternal(state,name,str.Length(name),style,flags,nextState);
  END AddKeyword;

  PROCEDURE (s : TokenSyntax) AddLetter*(state     : StateType;
                                         char      : CHAR;
                                         style     : Style;
                                         flags     : SET;
                                         nextState : StateType);

  VAR
    letter : Letter;

  BEGIN
    NEW(letter);
    letter.style:=style;
    letter.flags:=flags;
    letter.nextState:=nextState;
    letter.syntax:=s;

    letter.next:=s.stateMachine[state].starters[ORD(char)];
    s.stateMachine[state].starters[ORD(char)]:=letter;
  END AddLetter;

  PROCEDURE (s : TokenSyntax) AddNumber*(state     : StateType;
                                         style     : Style;
                                         flags     : SET;
                                         nextState : StateType);

  VAR
    number : Number;
    x      : LONGINT;

  BEGIN
    FOR x:=ORD("0") TO ORD("9") DO
      NEW(number);
      number.style:=style;
      number.flags:=flags;
      number.nextState:=nextState;
      number.syntax:=s;

      number.next:=s.stateMachine[state].starters[x];
      s.stateMachine[state].starters[x]:=number;
    END;
  END AddNumber;

  PROCEDURE (s : TokenSyntax) AddKeywordMatch*(state : StateType; a, b : ARRAY OF CHAR);

  VAR
    t1,t2 : Keyword;
    k     : Token;

  BEGIN
    t1:=NIL;
    t2:=NIL;

    k:=s.stateMachine[state].starters[ORD(a[0])];
    WHILE (k#NIL) & (t1=NIL) DO
      WITH k : Keyword DO
        IF k.name^=a THEN
          t1:=k;
        END;
      ELSE
      END;
      k:=k.next;
    END;

    k:=s.stateMachine[state].starters[ORD(b[0])];
    WHILE (k#NIL) & (t2=NIL) DO
      WITH k : Keyword DO
        IF k.name^=b THEN
          t2:=k;
        END;
      ELSE
      END;
      k:=k.next;
    END;

    IF (t1#NIL) & (t2#NIL) THEN
      t1.match:=t2;
      t2.match:=t1;
    END;
  END AddKeywordMatch;

  PROCEDURE (t : Token) Match(string : U.Text;
                              x : LONGINT;
                              VAR y : LONGINT):BOOLEAN;

  BEGIN
    RETURN FALSE;
  END Match;

  PROCEDURE (s : TokenSyntax) ParseToken*(text : U.Text;
                                          VAR x : LONGINT;
                                          VAR y : LONGINT;
                                          VAR state : StateInfo):Token;

  VAR
    token : Token;
    st    : StateType;

  BEGIN
    st:=state.GetState();
    token:=s.stateMachine[st].starters[ORD(text[x])];
    WHILE token#NIL DO
      IF token.Match(text,x,y) THEN
        IF RecurseUp IN token.flags THEN
          state.Inc();
        ELSIF RecurseDown IN token.flags THEN
          state.Dec();
        ELSIF Push IN token.flags THEN
          state.Push(token.nextState);
        ELSIF Pop IN token.flags THEN
          state.Pop();
        END;

        IF Escape IN token.flags THEN
          INC(x);
        END;

        RETURN token;
      END;

      token:=token.next;
    END;

    y:=1;
    RETURN s.stateMachine[st].default;
  END ParseToken;

(*  PROCEDURE (s : Syntax) Dump;

  VAR
    state,x : LONGINT;
    keyword : Keyword;

  BEGIN
    state:=0;
    WHILE state<maxState DO
      x:=0;
      WHILE x<256 DO
        keyword:=s.stateMachine[state].starters[x];
        IF keyword#NIL THEN
          Err.LongInt(state,0); Err.String("S|"); Err.LongInt(x,0);
          WHILE keyword#NIL DO
            Err.String(":");
            Err.String(keyword.name^);
            Err.String("->");
            Err.LongInt(keyword.nextState,0);
            keyword:=keyword.next;
          END;
          Err.String(":");Err.Ln;
        END;
        INC(x);
      END;

      INC(state);
    END;
  END Dump;*)

  PROCEDURE RegisterSyntax*(syntax : Syntax);

  BEGIN
    syntax.next:=syntaxList;
    syntaxList:=syntax;
  END RegisterSyntax;

  PROCEDURE GetSyntax*(name : STRING):Syntax;

  VAR
    syntax : Syntax;

  BEGIN
    syntax:=syntaxList;
    WHILE ~syntax.name.Equals(name) DO
      syntax:=syntax.next;
    END;

    RETURN syntax;
  END GetSyntax;

  PROCEDURE (s : TokenSyntax) GetStyle*(VAR state(*[NO_COPY]*) : StateInfo):Style;

  BEGIN
   RETURN s.stateMachine[state.GetState()].style;
  END GetStyle;


  PROCEDURE (t : Token) GetStyle*(stateCount : StateCount):Style;

  BEGIN
    RETURN t.style;
  END GetStyle;

  PROCEDURE (t : Keyword) Match(string : U.Text;
                                x : LONGINT;
                                VAR y : LONGINT):BOOLEAN;

  VAR
    found : BOOLEAN;

  BEGIN
    y:=1;
    WHILE (t.name[y]#0X) & (t.name[y]=string[x+y]) DO
      INC(y);
    END;
    found:=t.name[y]=0X;

    (* if it has to be a complete word, check if its surrounded by word delimiter *)
    IF found & (Word IN t.flags) THEN
      found:=((x=0) OR (~t.syntax.word[ORD(string[x-1])])) &
             ((string[x+y]=0X) OR (~t.syntax.word[ORD(string[x+y])]));
    END;

    RETURN found;
  END Match;

  PROCEDURE (l : Letter) Match(string : U.Text;
                               x : LONGINT;
                               VAR y : LONGINT):BOOLEAN;

  BEGIN
    y:=1;
    IF (Word IN l.flags) THEN
      RETURN ((x=0) OR (~l.syntax.word[ORD(string[x-1])])) &
             ((string[x+y]=0X) OR (~l.syntax.word[ORD(string[x+y])]));
    ELSE
      RETURN TRUE;
    END;
  END Match;

  PROCEDURE (n : Number) Match(string : U.Text;
                               x : LONGINT;
                               VAR y : LONGINT):BOOLEAN;

  BEGIN
    y:=1;
    WHILE (string[x+y]>="0") & (string[x+y]<="9") DO
      INC(y);
    END;

    IF (Word IN n.flags) THEN
      RETURN ((x=0) OR (~n.syntax.word[ORD(string[x-1])])) &
             ((string[x+y]=0X) OR (~n.syntax.word[ORD(string[x+y])]));
    ELSE
      RETURN TRUE;
    END;
  END Match;

  PROCEDURE SetGlobalSettings*(syntax : TokenSyntax);

  VAR
    x : LONGINT;

  BEGIN
    FOR x:=0 TO 31 DO
      IF (x=ORD(Ascii.lf)) OR (x=ORD(Ascii.ht)) THEN
        (* Do nothing *)
      ELSE
        syntax.AddLetter(0,CHR(x),SpecialStyle,{},0);
      END;
    END;
  END SetGlobalSettings;

  PROCEDURE (s : Style) Set*(data : StyleData);

  BEGIN
    s.data:=data;;
  END Set;

  PROCEDURE CreateStyle():Style;

  VAR
    style : Style;

  BEGIN
    NEW(style);
    style.data:=NIL;

    RETURN style;
  END CreateStyle;

BEGIN
  syntaxList:=NIL;

  NormalStyle:=CreateStyle();
  KeywordStyle:=CreateStyle();
  StringStyle:=CreateStyle();
  CommentStyle:=CreateStyle();
  DocuStyle:=CreateStyle();
  SpecialStyle:=CreateStyle();
  CursorStyle:=CreateStyle();
  MarkStyle:=CreateStyle();
  SelectionStyle:=CreateStyle();
  BookmarkStyle:=CreateStyle();
  LineStyle:=CreateStyle();
  OperatorStyle:=CreateStyle();
  PreprocessStyle:=CreateStyle();
  DatatypeStyle:=CreateStyle();
  NumberStyle:=CreateStyle();
  FunctionStyle:=CreateStyle();
  IncludeStyle:=CreateStyle();
  Quote1Style:=CreateStyle();
  Quote2Style:=CreateStyle();
  Quote3Style:=CreateStyle();
  Quote4Style:=CreateStyle();
  HeaderStyle:=CreateStyle();
  WarningStyle:=CreateStyle();
  ErrorStyle:=CreateStyle();
END VO:Edit:Syntax.