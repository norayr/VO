/*
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
*/

#include <unistd.h>
#include <stdio.h>
#include <X11/xpm.h>

#include "__oo2c.h"

/*
  This is a very special hack. The problem is, that the symbols from X11.oh
  indiretcly included by VO:Image:Image conflicts with the "normal" symbols
  from X11/X.h and friends. The trick is to not read X11.oh by defining the
  preprocessor symbol and to fake all necessary X11 symbols.
*/
typedef void* X11__DisplayPtr;
typedef void* X11__VisualPtr;
typedef void* X11__XImagePtr;
typedef void* X11__GC;

#define _MODULE_X11_
#include "VO/Image/Loader/XPM.d"


  OOC_CHAR8 VO_Image_Loader_XPM__LoaderDesc_CanLoad(VO_Image_Loader_XPM__Loader l,
                                                    const OOC_CHAR8 file__ref[],
                                                    OOC_LEN file_0d)
  {
    size_t length;

    length=strlen(file__ref);
    if (length>4) {
      if (strcmp(&file__ref[length-4],".xpm")==0) {
        return 1;
      }
    }

    return 0;
  }

  OOC_CHAR8 VO_Image_Loader_XPM__LoaderDesc_Load(VO_Image_Loader_XPM__Loader l,
                                                 const OOC_CHAR8 file__ref[],
                                                 OOC_LEN file_0d,
                                                 VO_Image_Image__Image image)
  {
    XpmImage xpmImage;
    int      res,i;

    res=XpmReadFileToXpmImage((char*)file__ref,&xpmImage,NULL);

    if (res!=XpmSuccess) {
      printf("Cannot load image '%s'\n",file__ref);
      return 0;
    }

    image->oWidth=xpmImage.width;
    image->oHeight=xpmImage.height;
    image->width=xpmImage.width;
    image->height=xpmImage.height;
    image->alpha=0; //(channels==3) ? 0 : 1;

    i=0;
    while (i<xpmImage.width*xpmImage.height) {
      printf("%s\n",xpmImage.colorTable[xpmImage.data[i]].c_color);

      i++;
    }

    return 0;
/*    image->source=RT0__NewObject(_td_VO_Image_Image__Data.baseTypes[0],width*height);

    i=0;
    j=0;
    while (i<width*height) {
      image->source[i].r=image_data[j];
      j++;
      image->source[i].g=image_data[j];
      j++;
      image->source[i].b=image_data[j];
      j++;

      if (channels==4) {
        image->source[i].a=image_data[j];
        j++;
      }
      else {
        image->source[i].a=255;
      }

      i++;
    }

    image->current=image->source;

    return 1; //image_data;*/
  }

  void OOC_VO_Image_Loader_XPM_init()
  {
    VO_Image_Loader_XPM__loader=RT0__NewObject(OOC_TYPE_DESCR(VO_Image_Loader_XPM,
                                                              LoaderDesc));
    DYN_TBCALL(VO_Image_Loader,ManagerDesc,Register,
               VO_Image_Loader__manager,
               (VO_Image_Loader__manager,
                (VO_Image_Loader__Loader)VO_Image_Loader_XPM__loader));
  }
