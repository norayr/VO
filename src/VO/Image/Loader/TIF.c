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
#include <tiffio.h>

#include "__oo2c.h"
#include "VO/Image/Loader/TIF.d"

OOC_CHAR8 VO_Image_Loader_TIF__LoaderDesc_CanLoad(VO_Image_Loader_TIF__Loader l,
                                                  const OOC_CHAR8 file__ref[],
                                                  OOC_LEN file_0d)
{
  size_t length;

  length=strlen(file__ref);
  if (length>4) {
    if (strcmp(&file__ref[length-4],".tif")==0) {
      return 1;
    }
  }

  return 0;
}

OOC_CHAR8 VO_Image_Loader_TIF__LoaderDesc_Load(VO_Image_Loader_TIF__Loader l,
                                               const OOC_CHAR8 file__ref[],
                                               OOC_LEN file_0d,
                                               VO_Image_Image__Image image)
{
  TIFF          *tif;
  unsigned int  width, height;
  unsigned long *data;

  if ((tif=TIFFOpen(file__ref,"r"))==NULL) {
    return 0;
  }

  TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &width);
  TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &height);
  if ((data=(unsigned long*)_TIFFmalloc(width*height*sizeof(unsigned long)))!=NULL) {

    image->source=RT0__NewObject(_td_VO_Image_Image__Data.baseTypes[0],width*height);
    image->alpha=0;

    if (TIFFReadRGBAImage(tif, width, height, data, 0)) {
      unsigned long pos;
      register unsigned long *row = data;
      int y = height;

      pos=width*height-1;
      while (--y>=0) {
        int x;

        for (x=width-1; x>=0 ; --x) {
          unsigned long c = row[x];

          image->source[pos].a=(c>>24)&0x00FF;
          image->source[pos].r=(c    )&0x00FF;
          image->source[pos].g=(c>>8 )&0x00FF;
          image->source[pos].b=(c>>16)&0x00FF;

          if (image->source[pos].a!=255) {
            image->alpha=1;
          }

          pos--;
        }

        row+=width;
      }
    }
    _TIFFfree(data);
  }

  TIFFClose(tif);

  image->oWidth=width;
  image->oHeight=height;
  image->width=width;
  image->height=height;

  image->current=image->source;

  return 1;
}

void OOC_VO_Image_Loader_TIF_init()
{
  VO_Image_Loader_TIF__loader=RT0__NewObject(OOC_TYPE_DESCR(VO_Image_Loader_TIF,
                                                            LoaderDesc));
  DYN_TBCALL(VO_Image_Loader,ManagerDesc,Register,
             VO_Image_Loader__manager,
             (VO_Image_Loader__manager,
              (VO_Image_Loader__Loader)VO_Image_Loader_TIF__loader));
}
