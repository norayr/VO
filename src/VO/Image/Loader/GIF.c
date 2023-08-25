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
#include <gif_lib.h>

#include "__oo2c.h"
#include "VO/Image/Loader/GIF.d"

OOC_CHAR8 VO_Image_Loader_GIF__LoaderDesc_CanLoad(VO_Image_Loader_GIF__Loader l,
                                                  const OOC_CHAR8 file__ref[],
                                                  OOC_LEN file_0d)
{
  size_t length;

  length=strlen(file__ref);
  if (length>4) {
    if (strcmp(&file__ref[length-4],".gif")==0) {
      return 1;
    }
  }

  return 0;
}

OOC_CHAR8 VO_Image_Loader_GIF__LoaderDesc_Load(VO_Image_Loader_GIF__Loader l,
                                               const OOC_CHAR8 file__ref[],
                                               OOC_LEN file_0d,
                                               VO_Image_Image__Image image)
{
  int            status = GIF_ERROR;
  GifFileType    *gif;
  SavedImage*    sp;
  ColorMapObject *cmap;
  GifRowType     row_pointer;
  unsigned int   transparent = -1;
  unsigned long  pos;
  unsigned int	 width=0, height=0;
  unsigned char  do_alpha=0;

  /* open the file */
  int subimage=0;

  gif=DGifOpenFileName(file__ref);

  if (gif==NULL) {
   return 0;
  }

  if (DGifSlurp(gif)!=GIF_OK) {
    DGifCloseFile(gif);
    return 0;
  }

  sp=gif->SavedImages;

  cmap=(sp->ImageDesc.ColorMap == NULL) ? gif->SColorMap : sp->ImageDesc.ColorMap;
  row_pointer=sp->RasterBits;

  width=sp->ImageDesc.Width;
  height=sp->ImageDesc.Height;

  // look for the transparent color extension
  for (pos = 0; pos<sp->ExtensionBlockCount; ++pos) {
    ExtensionBlock* eb = sp->ExtensionBlocks + pos;
    if (eb->Function == 0xF9 && eb->ByteCount == 4) {
      if ((eb->Bytes[0] & 1) == 1) {
        transparent = eb->Bytes[3];
      }
    }
  }

  image->alpha=0;

  if (cmap!=NULL && row_pointer!=NULL) {

    int bg_color=gif->SBackGroundColor;

    image->source=RT0__NewObject(_td_VO_Image_Image__Data.baseTypes[0],width*height);


/*    for (pos=0; pos<cmap->ColorCount; pos++) {
      printf("%d/%d/%d\n",cmap->Colors[pos].Red,cmap->Colors[pos].Green,cmap->Colors[pos].Blue);
    }*/

    if (gif->Image.Interlace) {
/*      int group;

      for(group=0,i=0;group<4;group++) {
        for(y=startline[group];y<giftype->SHeight;y+=offset[group],i++) {
          for(x=0;x<giftype->SWidth;x++) {
            colorvalue = giftype->SavedImages->RasterBits[i*giftype->SWidth+x];
            XPutPixel(image, x, y, pixels[colorvalue]);
          }
        }
      }*/
    }
    else {
      for (pos=0; pos<width*height; ++pos) {
        int c=row_pointer[pos];
        if (c==transparent) {
          c=bg_color;
          do_alpha=1;
          image->source[pos].a=0;
          }
          else {
          image->source[pos].a=255;
          }
        image->source[pos].r=cmap->Colors[c].Red;
        image->source[pos].g=cmap->Colors[c].Green;
        image->source[pos].b=cmap->Colors[c].Blue;
      }
    }

    if (do_alpha) {
      image->alpha=1;
    }
  }

  DGifCloseFile(gif);

  image->oWidth=width;
  image->oHeight=height;
  image->width=width;
  image->height=height;

  image->current=image->source;

  return 1;
}

void OOC_VO_Image_Loader_GIF_init()
{
  VO_Image_Loader_GIF__loader=RT0__NewObject(OOC_TYPE_DESCR(VO_Image_Loader_GIF,
                                                            LoaderDesc));
  DYN_TBCALL(VO_Image_Loader,ManagerDesc,Register,
             VO_Image_Loader__manager,
             (VO_Image_Loader__manager,
              (VO_Image_Loader__Loader)VO_Image_Loader_GIF__loader));
}
