MODULE VO:VGD:FuelGauge;
  (**
    VGD parser for VO:FuelGauge.
  *)

  (*
    VGD parser for VO:FuelGauge.
    Copyright (C) 2002 Tim Teulings (rael@edge.ping.de)

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

IMPORT        VO:VGD:VGD,

       PP  := VO:Prefs:Parser,

       F   := VO:FuelGauge,
       G   := VO:Object;


TYPE
  FuelGaugeParser          = POINTER TO FuelGaugeParserDesc;
  FuelGaugeParserDesc      = RECORD (VGD.ObjectParserDesc)
                               directionId : LONGINT;
                             END;

VAR
  fuelGaugeParser : FuelGaugeParser;

  PROCEDURE (p : FuelGaugeParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("FuelGauge");
    p.directionId:=p.RegisterAttribute("direction",VGD.stringType,"Direction of the fuel gauge");
  END Init;

  PROCEDURE (p : FuelGaugeParser) SetAttribute*(object : G.Object;
                                                id : LONGINT; VAR data : VGD.DataDesc;
                                                item : PP.Item;
                                                context : VGD.Context);

  BEGIN
    IF id=p.directionId THEN
      IF data.string.Equals("horizontal") THEN
        object(F.FuelGauge).SetDirection(FALSE);
      ELSIF data.string.Equals("vertical") THEN
        object(F.FuelGauge).SetDirection(TRUE);
      ELSE
        context.AddError(item,"Unknown direction");
      END;
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : FuelGaugeParser) CreateInstance*():G.Object;

  BEGIN
    RETURN F.CreateFuelGauge();
  END CreateInstance;

BEGIN
  NEW(fuelGaugeParser);
  fuelGaugeParser.Init;
  VGD.factory.RegisterObjectParser(fuelGaugeParser);
END VO:VGD:FuelGauge.