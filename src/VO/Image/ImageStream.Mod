MODULE VO:Image:ImageStream;

  (*
    Image subsystem for VisualOberon.
    Copyright (C) 2003 Stewart Greenhill

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

(* 

ImageStreams may support optional handlers to add additional functionality.
For example, Movie input streams may support positioning, digitiser input
streams may allow control of image size, brightness, etc. Currently, it works
as follows:

- Each image stream implements GetHandler, which maps an identifier to a
  handler object. If an interface is not supported by the stream, it returns
  NIL.
- Standard handlers are defined in this module, and extend the abstract Handler
  type. Example: Position.
- Standard identifiers are defined in this module. For now, an integer value is
  associated with each handler interface. Example: idPosition.

NOTE: This looks rather like the COM QueryInterface/IUnknown approach. It may
be more sensible to generalise this mechanism, since it could be useful
elsewhere too.

*)

IMPORT 
  I := VO:Image:Image;

CONST
  idPosition* = 0;
  (** Identifier for Position interface. *)

TYPE 
  TimeStamp* = LONGINT;
  (**Time used for identifying positions within an image stream. Values of this
     type will be implementation specific. For example, QuickTime usually 
     defines 600 units per second but other implementations may vary. *)

TYPE
  InputStream* = POINTER TO InputStreamDesc;
  InputStreamDesc* = RECORD [ABSTRACT, VTABLE]
    (**An input stream produces a sequence of images of the same size. This
       abstract interface covers simple operations for reading image sources
       such as movies files and video digitisers. *)
  END;

TYPE
  Handler* = POINTER TO HandlerDesc;
  HandlerDesc* = RECORD [ABSTRACT, VTABLE]
    (**Abstract base class for all optional handlers. *)
  END;

TYPE
  Position* = POINTER TO PositionDesc;
  PositionDesc* = RECORD [ABSTRACT, VTABLE] (HandlerDesc)
    (**A position handler is used to control a positionable image stream (eg.
       a movie file). *)
  END;

(* ImageStream interface methods. *)

PROCEDURE (s : InputStream) [ABSTRACT] GetImageSize*(VAR width : LONGINT;
                                                     VAR height : LONGINT);
(**Return the dimensions in pixels of images produced by this stream. *)
END GetImageSize;

PROCEDURE (s : InputStream) [ABSTRACT] ReadImage* (result : I.Image) : BOOLEAN;
(**Read the next available image from the stream into the image
@oparam{result}. The result image must be allocated by the user. This
function returns @code{FALSE} to indicate failure in the following situations:
@itemize @bullet

@item 
The value of @oparam{result} is @code{NIL}.

@item 
The value of @ofield{result.source} is @code{NIL}.

@item 
The dimensions of the image @oparam{result} are different from the dimensions
associtated with the stream (ie. returned by @oproc{s.GetImageSize}).

@end itemize
*)
END ReadImage;

PROCEDURE (s : InputStream) [ABSTRACT] HasMore* () : BOOLEAN;
(**Returns @code{TRUE} only when there are more images available to be
produced by this stream. *)
END HasMore;

PROCEDURE (s : InputStream) [ABSTRACT] Close*;
(**Closes this image stream, freeing any associated resources. *)
END Close;

PROCEDURE (s : InputStream) [ABSTRACT] GetHandler* (id : LONGINT) : Handler;
(**Return a handler for an optional interface. *)
END GetHandler;


(* Position interface methods. *)

PROCEDURE (h : Position) [ABSTRACT] GetDuration* (VAR start, end : TimeStamp);
(**Return the start and end times for a positionable image stream. *)
END GetDuration;

PROCEDURE (h : Position) [ABSTRACT] GetPosition* (VAR position : TimeStamp) : BOOLEAN;
(**Return the time-stamp associated with the next image to be returned by this
   stream. If unsuccessful, this function returns @code{FALSE}. *)
END GetPosition;

PROCEDURE (h : Position) [ABSTRACT] SetPosition* (VAR position : TimeStamp) : BOOLEAN;
(**Set the time-stamp for the next image to be returned by this stream. If
   unsucessful, this function returns @code{FALSE}. *)
END SetPosition;

END VO:Image:ImageStream.
