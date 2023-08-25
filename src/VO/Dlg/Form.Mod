MODULE VO:Dlg:Form;

IMPORT V := VO:Model:View,

       G := VO:Object,
       W := VO:Window;

CONST
  modeView* = 0;
  modeEdit* = 1;
  modeNew*  = 2;

TYPE
  Entry        = POINTER TO EntryDesc;
  EntryDesc    = RECORD
                   view : V.View;
                   next : Entry;
                 END;

  Form     * = POINTER TO FormDesc;
  FormDesc * = RECORD (W.WindowDesc)
                 (**
                   A form is a special type of window. It supplies additional
                   high level functions for dialogs that are data input orientated,
                   that means, they contain of a number of data controls working
                   on models plus some processing control like undo, redo,
                   save, ok and cancel.

                   Form work together with instances of @code{VO:Model:View},
                   which is in turn a collection of models.

                   The form represents the display layer while the view represents
                   the data layer. Both layer work independetly and can be changed
                   separatly while automatically updating each other.

                   A form can have a input mode. The form automatically controls
                   creation and deletion of backup levels depending of the form.

                   Using simple name matching it automatically links controls and
                   models.
                 *)
                 mode-   : LONGINT; (** the current mode the dialog is in *)
                 list    : Entry;   (** The list of views *)
                 result- : BOOLEAN; (** the result of the dialog after completion *)
               END;

               PROCEDURE (f : Form) Init*;

  BEGIN
    f.Init^;

    f.list:=NIL;
    f.result:=FALSE;
    f.mode:=modeView;
  END Init;

  PROCEDURE (f : Form) LinkModels;

    (**
      Link all models of all connected views with their equal named control
      (if available)
    *)

  VAR
    view   : Entry;
    entry  : V.Entry;
    object : G.Object;

  BEGIN
    view:=f.list;
    WHILE view#NIL DO
      entry:=view.view.list;
      WHILE entry#NIL DO
        object:=f.top.GetObjectByName(entry.name);

        IF (object#NIL) & (object IS G.Control) THEN
          object(G.Control).SetModel(entry.model);
        END;

        entry:=entry.next;
      END;

      view:=view.next;
    END;
  END LinkModels;

  PROCEDURE (f : Form) AttachView*(view : V.View);

    (**
      Attach a view to the dialog.

      Currently views must be attached before @code{VO:Base:Window.Open} gets
      called.
    *)

  VAR
    entry : Entry;

  BEGIN
    NEW(entry);
    entry.view:=view;
    entry.next:=f.list;

    f.list:=entry;
  END AttachView;

  PROCEDURE (f : Form) DeattachViews*;

    (**
      Detach all views. This is currently not completely implemented
      and might chane in the future.
    *)

  BEGIN
    f.list:=NIL;
  END DeattachViews;

  PROCEDURE (f : Form) DisableObjects(disable : BOOLEAN);

  VAR
    view   : Entry;
    entry  : V.Entry;
    object : G.Object;

  BEGIN
    view:=f.list;
    WHILE view#NIL DO
      entry:=view.view.list;
      WHILE entry#NIL DO
        object:=f.top.GetObjectByName(entry.name);
        IF object#NIL THEN
          object.Disable(disable);
        END;

        entry:=entry.next;
      END;

      view:=view.next;
    END;
  END DisableObjects;

  PROCEDURE (f : Form) Backup;

  VAR
    entry : Entry;

  BEGIN
    entry:=f.list;
    WHILE entry#NIL DO
      entry.view.Backup;
      entry:=entry.next;
    END;
  END Backup;

  PROCEDURE (f : Form) DropBackup;

  VAR
    entry : Entry;

  BEGIN
    entry:=f.list;
    WHILE entry#NIL DO
      entry.view.DropBackup;
      entry:=entry.next;
    END;
  END DropBackup;

  PROCEDURE (f : Form) StoreCurrent;

  VAR
    entry : Entry;

  BEGIN
    entry:=f.list;
    WHILE entry#NIL DO
      entry.view.StoreCurrent;
      entry:=entry.next;
    END;
  END StoreCurrent;

  PROCEDURE (f : Form) Restore*;

    (**
      This resets the current value of all models to their value before
      the current edit session.

      Only call it, if you are in @code{modeEdit} or @code{modeNew}.
    *)

  VAR
    entry : Entry;

  BEGIN
    ASSERT((f.mode=modeNew) OR (f.mode=modeEdit));

    entry:=f.list;
    WHILE entry#NIL DO
      entry.view.Restore;
      entry:=entry.next;
    END;
  END Restore;

  PROCEDURE (f : Form) ExitOK*;

  BEGIN
    f.result:=TRUE;
    f.Exit;
  END ExitOK;

  PROCEDURE (f : Form) ExitCancel*;

  BEGIN
    f.result:=FALSE;
    f.Exit;
  END ExitCancel;

  PROCEDURE (f : Form) Open*():BOOLEAN;

  BEGIN
    f.result:=FALSE;

    IF ~f.Open^() THEN
      RETURN FALSE;
    END;

    f.LinkModels;
    f.mode:=modeView;
    f.DisableObjects(TRUE);

    RETURN TRUE;
  END Open;

  PROCEDURE (f : Form) Close*;

  BEGIN
    (* f.UnlinkModels *)

    f.Close^;

    IF (f.mode=modeEdit) OR (f.mode=modeNew) THEN
      IF f.result THEN
        f.StoreCurrent;
      END;

      f.DropBackup;
    END;
  END Close;

  PROCEDURE (f : Form) SetMode*(mode : LONGINT);

    (**
      Set the mode of the dialog. Backuplevels will be automatically
      created and destroyed for each model link through a view.
    *)

  BEGIN
    IF mode=f.mode THEN
      RETURN;
    END;

    CASE f.mode OF
      modeView:
      IF (mode=modeEdit) OR (mode=modeNew) THEN
        f.Backup;
        f.mode:=mode;
        f.DisableObjects(FALSE);
      END;
    | modeEdit,
      modeNew:
      IF mode=modeView THEN
        f.DropBackup;
        f.mode:=mode;
        f.DisableObjects(TRUE);
      END;
    ELSE
    END;
  END SetMode;

END VO:Dlg:Form.