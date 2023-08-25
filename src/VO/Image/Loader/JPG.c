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
#include <jpeglib.h>
#include <setjmp.h>

#include "__oo2c.h"
#include "VO/Image/Loader/JPG.d"


OOC_CHAR8 VO_Image_Loader_JPG__LoaderDesc_CanLoad(VO_Image_Loader_JPG__Loader l,
                                                  const OOC_CHAR8 file__ref[],
                                                  OOC_LEN file_0d)
{
  size_t length;

  length=strlen(file__ref);
  if (length>4) {
    if (strcmp(&file__ref[length-4],".jpg")==0) {
      return 1;
    }
  }

  return 0;
}

struct my_error_mgr
{
  struct jpeg_error_mgr pub;
  jmp_buf               setjmp_buffer;
};

typedef struct my_error_mgr *my_error_ptr;

void my_error_exit (j_common_ptr cinfo)
{
  my_error_ptr  myerr = (my_error_ptr) cinfo->err;
  (*cinfo->err->output_message) (cinfo);
  longjmp (myerr->setjmp_buffer, 1);
}

OOC_CHAR8 VO_Image_Loader_JPG__LoaderDesc_Load(VO_Image_Loader_JPG__Loader l,
                                               const OOC_CHAR8 file__ref[],
                                               OOC_LEN file_0d,
                                               VO_Image_Image__Image image)
{
  struct jpeg_decompress_struct cinfo;
  struct my_error_mgr jerr;
  FILE         *infile;
  JSAMPARRAY    buffer;
  int           i,j,y;

  infile = fopen(file__ref,"rb");
  if (infile==NULL) {
    return 0;
  }

  cinfo.err = jpeg_std_error (&jerr.pub);
  jerr.pub.error_exit = my_error_exit;
  if (setjmp (jerr.setjmp_buffer)) {
    jpeg_destroy_decompress (&cinfo);
    fclose (infile);
    return 0;
  }

  jpeg_create_decompress (&cinfo);
  jpeg_stdio_src (&cinfo, infile);
  (void)jpeg_read_header (&cinfo, TRUE);
  cinfo.quantize_colors = FALSE;       /* we don't want no stinking colormaps ! */
  cinfo.output_gamma = 1/*gamma*/;
  (void)jpeg_start_decompress (&cinfo);

  image->source=RT0__NewObject(_td_VO_Image_Image__Data.baseTypes[0],
                               cinfo.output_width*cinfo.output_height);
  buffer =(*cinfo.mem->alloc_sarray)((j_common_ptr) & cinfo, JPOOL_IMAGE,
                            									cinfo.output_width * cinfo.output_components, 1);

  y=-1;
  j=0;
  while ( ++y < cinfo.output_height )
  {
    (void)jpeg_read_scanlines (&cinfo, buffer, 1);

    for( i=0 ; i<cinfo.output_width; i++) {
      image->source[j].r=buffer[0][i*3];
      image->source[j].g=buffer[0][i*3+1];
      image->source[j].b=buffer[0][i*3+2];
      image->source[j].a=255;
      j++;
    }
  }

  if (cinfo.output_scanline < cinfo.output_height) {
    jpeg_abort_decompress (&cinfo);
  }
  else {
    (void)jpeg_finish_decompress (&cinfo);
  }
  jpeg_destroy_decompress (&cinfo);

  fclose (infile);

  image->oWidth=cinfo.output_width;
  image->oHeight=cinfo.output_height;
  image->width=cinfo.output_width;
  image->height=cinfo.output_height;
  image->alpha=0;
  image->current=image->source;

  return 1;
}

void OOC_VO_Image_Loader_JPG_init()
{
  VO_Image_Loader_JPG__loader=RT0__NewObject(OOC_TYPE_DESCR(VO_Image_Loader_JPG,
                                                            LoaderDesc));
  DYN_TBCALL(VO_Image_Loader,ManagerDesc,Register,
             VO_Image_Loader__manager,
             (VO_Image_Loader__manager,
              (VO_Image_Loader__Loader)VO_Image_Loader_JPG__loader));
}
