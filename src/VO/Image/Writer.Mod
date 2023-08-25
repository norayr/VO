MODULE VO:Image:Writer;

  (*
    Image storing subsystem for VisualOberon.
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

TYPE
  Options*     = POINTER TO OptionsDesc;
  OptionsDesc* = RECORD
                   (**
                     Common option, that can be handed over to a writer
                     implementation. Please create an instance using
                     @oproc{CreateOptions} to ensure that it is initialized
                     with valid default values. Note, that the values of
                     @otype{Options} are always proposals. The image writing
                     function is always free to ignore the options because
                     limitations of the writer itself or the format.
                   *)
                   quality- : LONGINT; (** quality, between 0 (min) and 100 (max and default). *)
                 END;

  PROCEDURE (o : Options) Init;

    (**
      Initializes the @otype{Options} instance. You must call @oproc{Options.Init}
      before you can use the instance.
    *)

  BEGIN
    o.quality:=100;
  END Init;

  PROCEDURE (o : Options) SetQuality*(quality : LONGINT);

    (**

    *)

  BEGIN
    ASSERT((0<=quality) & (quality<=100));

    o.quality:=quality;
  END SetQuality;

  PROCEDURE CreateOptions*():Options;

  VAR
    o : Options;

  BEGIN
    NEW(o);
    o.Init;

    RETURN o;
  END CreateOptions;

END VO:Image:Writer.