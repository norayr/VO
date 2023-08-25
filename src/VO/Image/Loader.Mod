MODULE VO:Image:Loader [OOC_EXTENSIONS];

  (*
    Image loading subsystem for VisualOberon.
    Copyright (C) 2003 Tim Teulings (rael@edge.ping.de)

    This file is part of VisualOberon.

    VisualOberon is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    VisualOberon is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with VisualOberon. If not, write to the Free Software
    Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
  *)

IMPORT VO:Base:Display,
       VO:Image:Image,

       Object,
       OS:Path;


TYPE
  Loader*      = POINTER TO LoaderDesc;
  LoaderDesc*  = RECORD [ABSTRACT]
                   next : Loader;
                 END;

  Manager*     = POINTER TO ManagerDesc;
  ManagerDesc* = RECORD
                   loader : Loader;
                 END;

VAR
  manager- : Manager;

  PROCEDURE (l : Loader) [ABSTRACT] CanLoad*(file : ARRAY OF CHAR):BOOLEAN;
  END CanLoad;

  PROCEDURE (l : Loader) [ABSTRACT] Load*(file : ARRAY OF CHAR;
                                          image : Image.Image):BOOLEAN;
  END Load;

  PROCEDURE (m : Manager) Init*;

  BEGIN
    m.loader:=NIL;
  END Init;

  PROCEDURE (m : Manager) Register*(loader : Loader);

  BEGIN
    loader.next:=m.loader;
    m.loader:=loader;
  END Register;

  PROCEDURE (m : Manager) Load*(file : ARRAY OF CHAR;
                                VAR image : Image.Image):BOOLEAN;

  VAR
    loader : Loader;

  BEGIN
    loader:=m.loader;
    WHILE (loader#NIL) & ~loader.CanLoad(file) DO
      loader:=loader.next;
    END;

    IF loader#NIL THEN
      RETURN loader.Load(file,image);
    ELSE
      RETURN FALSE;
    END;
  END Load;

  PROCEDURE (m : Manager) LoadThemed*(file : ARRAY OF CHAR;
                                      VAR image : Image.Image):BOOLEAN;

  VAR
    path : STRING;
    txt  : Object.CharsLatin1;

  BEGIN
    IF ~m.Load(file,image) THEN
      path:=Display.display.GetThemePath(Object.NewLatin1(Display.prefs.theme))+Object.NewLatin1(file);
      txt:=Path.Encode(path);
      RETURN m.Load(txt^,image);
    ELSE
      RETURN TRUE;
    END;
  END LoadThemed;

BEGIN
  NEW(manager);
  manager.Init;
END VO:Image:Loader.