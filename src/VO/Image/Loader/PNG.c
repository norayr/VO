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

#include "__oo2c.h"
#include "VO/Image/Loader/PNG.d"

OOC_CHAR8 VO_Image_Loader_PNG__LoaderDesc_CanLoad(VO_Image_Loader_PNG__Loader l,
                                                  const OOC_CHAR8 file__ref[],
                                                  OOC_LEN file_0d)
{
  FILE          *file;
  unsigned char sig[8];

  /* open the file */
  file=fopen(file__ref,"rb");

  if (file==NULL) {
    return 0;
  }

  /* check, if its a PNG */
  fread(sig, 1, 8, file);
  if (!png_check_sig(sig, 8)) {
    fclose(file);
    return 0;   /* bad signature */
  }
  else {
    fclose(file);
    return 1;   /* bad signature */
  }
}

OOC_CHAR8 VO_Image_Loader_PNG__LoaderDesc_Load(VO_Image_Loader_PNG__Loader l,
                                               const OOC_CHAR8 file__ref[],
                                               OOC_LEN file_0d,
                                               VO_Image_Image__Image image)
{
  FILE          *file;
  png_structp   png_ptr;
  png_infop     info_ptr;
  png_uint_32   width, height;
  int           bit_depth, color_type;
  int           channels, intent;
  double        screen_gamma;
  png_uint_32   i,j, rowbytes;
  png_bytepp    row_pointers = NULL;
  unsigned char *image_data = NULL;

  /* open the file */
  file=fopen(file__ref,"rb");

  if (file==NULL) {
    return 0;
  }

  /* could pass pointers to user-defined error handlers instead of NULLs: */

  png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!png_ptr) {
    fclose(file);
    return 0;   /* out of memory */
  }

  info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr) {
    png_destroy_read_struct(&png_ptr, NULL, NULL);
    fclose(file);
    return 0;   /* out of memory */
  }

  if (setjmp(png_jmpbuf(png_ptr))) {
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(file);
    return 0;
  }

  png_init_io(png_ptr,file);
  png_read_info(png_ptr,info_ptr);

  png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type,
               NULL, NULL, NULL);

  if (setjmp(png_jmpbuf(png_ptr))) {
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(file);
    return 0;
  }

  /* We always want RGB or RGBA */
  if (color_type==PNG_COLOR_TYPE_PALETTE) {
    png_set_expand(png_ptr);
  }

  if (color_type==PNG_COLOR_TYPE_GRAY && bit_depth < 8) {
    png_set_expand(png_ptr);
  }

  if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS)) {
    png_set_expand(png_ptr);
  }

  if (bit_depth==16) {
    png_set_strip_16(png_ptr);
  }

  if (color_type==PNG_COLOR_TYPE_GRAY || color_type==PNG_COLOR_TYPE_GRAY_ALPHA) {
    png_set_gray_to_rgb(png_ptr);
  }

  screen_gamma=2.2; /* TODO: Make it configurable */

  if (png_get_sRGB(png_ptr,info_ptr,&intent)) {
    png_set_gamma(png_ptr,screen_gamma,0.45455);
  }
  else {
    double image_gamma;
    if (png_get_gAMA(png_ptr, info_ptr, &image_gamma)) {
      png_set_gamma(png_ptr, screen_gamma,image_gamma);
    }
    else {
      png_set_gamma(png_ptr, screen_gamma,0.45455);
    }
  }

  png_read_update_info(png_ptr, info_ptr);

  rowbytes = rowbytes = png_get_rowbytes(png_ptr, info_ptr);
  channels = (int)png_get_channels(png_ptr, info_ptr);

  if ((image_data = (unsigned char *)malloc(rowbytes*height)) == NULL) {
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(file);
    return 0;
  }

  if ((row_pointers = (png_bytepp)malloc(height*sizeof(png_bytep))) == NULL) {
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    free(image_data);
    fclose(file);
    return 0;
  }

  for (i = 0;  i < height;  ++i) {
    row_pointers[i] = image_data + i*rowbytes;
  }

  png_read_image(png_ptr, row_pointers);

  free(row_pointers);
  row_pointers = NULL;

  png_read_end(png_ptr, NULL);

  image->oWidth=width;
  image->oHeight=height;
  image->width=width;
  image->height=height;
  image->alpha=0;

  image->source=RT0__NewObject(_td_VO_Image_Image__Data.baseTypes[0],width*height);

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

      if (image->source[i].a!=255) {
        image->alpha=1;
      }

      j++;
    }
    else {
      image->source[i].a=255;
    }

    i++;
  }

  image->current=image->source;

  png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
  free(image_data);
  fclose(file);

  return 1; //image_data;
}

void OOC_VO_Image_Loader_PNG_init()
{
  VO_Image_Loader_PNG__loader=RT0__NewObject(OOC_TYPE_DESCR(VO_Image_Loader_PNG,
                                                            LoaderDesc));
  DYN_TBCALL(VO_Image_Loader,ManagerDesc,Register,
             VO_Image_Loader__manager,
             (VO_Image_Loader__manager,
              (VO_Image_Loader__Loader)VO_Image_Loader_PNG__loader));
}
