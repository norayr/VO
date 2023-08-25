MODULE VO:Edit:Syntax:Standard;

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

IMPORT ES := VO:Edit:Syntax;

VAR
  syntax- : ES.TokenSyntax;

BEGIN
  NEW(syntax);
  syntax.Init("Standard");

  ES.SetGlobalSettings(syntax);

  syntax.SetDelimiter(" ,;.()");
  syntax.SetTabSize(8);

  syntax.SetScheme(0,ES.NormalStyle);

  ES.RegisterSyntax(syntax);
END VO:Edit:Syntax:Standard.

