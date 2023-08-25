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
#include <png.h>
#include <time.h>

#include "__oo2c.h"
#include "VO/Image/Writer/PNG.d"


OOC_CHAR8 VO_Image_Writer_PNG__Store(const OOC_CHAR8 file__ref[],
                                     OOC_LEN file_0d,
                                     VO_Image_Image__Image image,
                                     VO_Image_Writer__Options options)
{
  FILE        *file;
  png_structp png_ptr;
  png_infop   info_ptr;
  png_uint_32 i;
  png_bytepp  row_pointers=NULL;
  png_color_8 sig_bit;
  png_time    pngTime;

  /* open the file */
  file=fopen(file__ref,"w+b");

  if (file==NULL) {
    return 0;
  }

  /* could pass pointers to user-defined error handlers instead of NULLs: */
  png_ptr=png_create_write_struct(PNG_LIBPNG_VER_STRING,NULL,NULL,NULL);
  if (!png_ptr) {
    fclose(file);
    return 0;   /* out of memory */
  }

  info_ptr=png_create_info_struct(png_ptr);
  if (!info_ptr) {
    png_destroy_write_struct(&png_ptr,NULL);
    fclose(file);
    return 0;   /* out of memory */
  }

  if (setjmp(png_jmpbuf(png_ptr))) {
    png_destroy_write_struct(&png_ptr,&info_ptr);
    fclose(file);
    return 0;
  }

  /* allocate memory for row pointer vector */
  if ((row_pointers=(png_bytepp)malloc(image->height*sizeof(png_bytep)))==NULL) {
    png_destroy_write_struct(&png_ptr,&info_ptr);
    fclose(file);
    return 0;
  }

  /* build up array of row pointers */
  for (i=0; i<image->oHeight; ++i) {
    row_pointers[i]=(void*)image->source+i*4*image->oWidth;
  }

  png_init_io(png_ptr,file);

  png_set_IHDR(png_ptr,info_ptr,
               image->oWidth,image->oHeight,
               8,PNG_COLOR_TYPE_RGB_ALPHA,
               PNG_INTERLACE_NONE,
               PNG_COMPRESSION_TYPE_DEFAULT,
               PNG_FILTER_TYPE_DEFAULT);

/*  if (!image->alpha) {*/
/*    png_set_filler(png_ptr,0,PNG_FILLER_AFTER);*/
/*  }*/

  /* if there is no valid alpha channel, initialize it to non-transparanrt */
  if (!image->alpha) {
    for (i=0; i<image->oHeight*image->oHeight; ++i) {
      image->source[i].a=255;
    }
  }

  /* assign data */
  png_set_rows(png_ptr,info_ptr,row_pointers);

  /* Write the current time in a sepcial 'time of creation' chunk */
  png_convert_from_time_t(&pngTime,time(NULL));
  png_set_tIME(png_ptr,info_ptr,&pngTime);

  /*
  TODO: fill in more headers
  */

  png_write_png(png_ptr,info_ptr,0,NULL);
  png_write_end(png_ptr,info_ptr);

  png_destroy_write_struct(&png_ptr,&info_ptr);
  free(row_pointers);
  fclose(file);

  return 1;
}

void OOC_VO_Image_Writer_PNG_init()
{
  // no code
}
