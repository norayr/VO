/*
  Image storing subsystem for VisualOberon.
  Copyright (C) 2004 Tim Teulings (rael@edge.ping.de)

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
#include "VO/Image/Writer/JPG.d"

struct my_error_mgr
{
  struct jpeg_error_mgr pub;
  jmp_buf               setjmp_buffer;
};

typedef struct my_error_mgr *my_error_ptr;

void my_writer_error_exit (j_common_ptr cinfo)
{
  my_error_ptr  myerr = (my_error_ptr) cinfo->err;
  (*cinfo->err->output_message) (cinfo);
  longjmp (myerr->setjmp_buffer, 1);
}

OOC_CHAR8 VO_Image_Writer_JPG__Store(const OOC_CHAR8 file__ref[],
                                     OOC_LEN file_0d,
                                     VO_Image_Image__Image image,
                                     VO_Image_Writer__Options options)
{
  struct jpeg_compress_struct cinfo;
  struct my_error_mgr         jerr;
  FILE                        *outfile;
  JSAMPROW                    row_pointer[1];
  size_t                      src,dst,x;

  outfile=fopen(file__ref,"wb");
  if (outfile==NULL) {
    return 0;
  }

  cinfo.err=jpeg_std_error (&jerr.pub);
  jerr.pub.error_exit=my_writer_error_exit;
  if (setjmp(jerr.setjmp_buffer)) {
    jpeg_destroy_compress(&cinfo);
    fclose(outfile);
    return 0;
  }

  jpeg_create_compress(&cinfo);
  jpeg_stdio_dest(&cinfo,outfile);

  cinfo.image_width=image->oWidth;
  cinfo.image_height=image->oHeight;
  cinfo.input_components=3;
  cinfo.in_color_space=JCS_RGB;

  jpeg_set_defaults(&cinfo);

  jpeg_set_quality(&cinfo,options->quality,TRUE);

  if ((row_pointer[0]=(JSAMPROW)malloc(image->width*3))==NULL) {
    jpeg_destroy_compress(&cinfo);
    fclose(outfile);
    return 0;
  }

  jpeg_start_compress(&cinfo,TRUE);

  src=0;

  while (cinfo.next_scanline<cinfo.image_height) {
    size_t s,d;

    dst=0;
    for (x=0; x<cinfo.image_width; x++) {
      row_pointer[0][dst]=image->source[src].r;
      ++dst;
      row_pointer[0][dst]=image->source[src].g;
      ++dst;
      row_pointer[0][dst]=image->source[src].b;
      ++dst;

      ++src;
    }

    jpeg_write_scanlines(&cinfo,row_pointer,1);
  }

  jpeg_finish_compress(&cinfo);

  fclose(outfile);

  jpeg_destroy_compress(&cinfo);

  free(row_pointer[0]);

  return 1;
}

void OOC_VO_Image_Writer_JPG_init()
{
  // no code
}
