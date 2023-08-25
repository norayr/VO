MODULE Directory [FOREIGN "C"; LINK FILE "Directory.c" END];

<* Warnings := FALSE *>
IMPORT C,
       IO,
       Object,
       OS:Path,
       Strings;

CONST
  (* file types *)
  normal    * = 0;
  directory * = 1;

  typeCount * = 2;

  rightRead    * = 0;
  rightWrite   * = 1;
  rightExecute * = 2;

  specialUID    * = 0;
  specialGID    * = 1;
  specialSticky * = 2;

  (* available attributes *)
  type  * = 0;
  size  * = 1;
  user  * = 2;
  group * = 3;
  other * = 4;
  link  * = 5;

TYPE
  DirEntry     * = POINTER TO DirEntryDesc;
  DirEntryDesc * = RECORD
                     attr*    : SET;     (** the attributes, that are set *)
                     type*    : LONGINT; (** the type of the file *)
                     size*    : LONGINT; (** the size of the file *)
                     user*,              (** the access rights for the user *)
                     group*,             (** the access rights for the group members *)
                     other*,             (** the access rights for all others *)
                     special* : SET;     (** other special file flags *)
                     link*    : BOOLEAN; (** file is a link *)
                   END;

  (** Sets current working directory *)
  PROCEDURE SetCwd*(dir : STRING) RAISES IO.Error;

  (** filter out all supported attributes *)
  PROCEDURE GetSupportedAttributes*(VAR attributes : SET);

  (** Splitting into directory and file path by opening the file *)
  PROCEDURE SplitDirFile*(path : ARRAY OF CHAR;
                          VAR dir,file : ARRAY OF CHAR):BOOLEAN;

  PROCEDURE GetDetails*(attributes : SET;
                        name : STRING;
                        VAR entry : DirEntryDesc):BOOLEAN;
END Directory.
