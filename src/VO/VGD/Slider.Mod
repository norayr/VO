MODULE VO:VGD:Slider;
  (**
    VGD parser for VO:Slider.
  *)

  (*
    VGD parser for VO:Slider.
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

       G   := VO:Object,
       S   := VO:Slider;


TYPE
  SliderParser     = POINTER TO SliderParserDesc;
  SliderParserDesc = RECORD (VGD.ObjectParserDesc)
                       directionId : LONGINT;
                       scaleId     : LONGINT;
                     END;

VAR
  sliderParser : SliderParser;

  PROCEDURE (p : SliderParser) Init*;

  BEGIN
    p.Init^;

    p.SetName("Slider");
    p.directionId:=p.RegisterAttribute("direction",VGD.stringType,"Direction of the slider");
    p.scaleId:=p.RegisterAttribute("scale",VGD.boolType,"Show a scale besides the slider");
  END Init;

  PROCEDURE (p : SliderParser) SetAttribute*(object : G.Object;
                                             id : LONGINT; VAR data : VGD.DataDesc;
                                             item : PP.Item;
                                             context : VGD.Context);

  BEGIN
    IF id=p.directionId THEN
      IF data.string.Equals("horizontal") THEN
        object(S.Slider).Set(FALSE);
      ELSIF data.string.Equals("vertical") THEN
        object(S.Slider).Set(TRUE);
      ELSE
        context.AddError(item,"Unknown direction");
      END;
    ELSIF id=p.scaleId THEN
      object(S.Slider).UseScale(data.bool);
    ELSE
      p.SetAttribute^(object,id,data,item,context);
    END;
  END SetAttribute;

  PROCEDURE (p : SliderParser) CreateInstance*():G.Object;

  BEGIN
    RETURN S.CreateSlider();
  END CreateInstance;

BEGIN
  NEW(sliderParser);
  sliderParser.Init;
  VGD.factory.RegisterObjectParser(sliderParser);
END VO:VGD:Slider.