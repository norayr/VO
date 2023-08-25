MODULE ChannelFDWrapper;

  (*
    Provides a simple channel wrapper to enable select on
    file descriptors with no channel attached.
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

IMPORT SYSTEM,
       IO;

TYPE
  Channel*     = POINTER TO ChannelDesc;
  ChannelDesc* = RECORD (IO.ByteChannelDesc)
                   fd: IO.FileDescriptor;
                 END;

  PROCEDURE Init*(ch: Channel; fd: IO.FileDescriptor);

  BEGIN
    IO.InitByteChannel(ch);
    ch.fd:=fd;
  END Init;

  PROCEDURE (ch: Channel) Read*(VAR buffer: ARRAY OF SYSTEM.BYTE;
                                start, length: LONGINT): LONGINT RAISES IO.Error;

  BEGIN
    IO.RaiseNotImplemented;
  END Read;

  PROCEDURE (ch: Channel) Write*(buffer[NO_COPY]: ARRAY OF SYSTEM.BYTE;
                                 start, length: LONGINT): LONGINT RAISES IO.Error;

  BEGIN
    IO.RaiseNotImplemented;
  END Write;

  PROCEDURE (ch: Channel) SetBlocking*(block: BOOLEAN) RAISES IO.Error;

  BEGIN
  END SetBlocking;

  PROCEDURE (ch: Channel) FileDescriptor*(): IO.FileDescriptor;

  BEGIN
    RETURN ch.fd;
  END FileDescriptor;

  PROCEDURE (ch: Channel) ResetReadyOps*();

  BEGIN
    ch.readyOps:={};
  END ResetReadyOps;

END ChannelFDWrapper.
