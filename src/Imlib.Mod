MODULE Imlib [INTERFACE "C"; LINK LIB "Xext"  ("X11");

(*
    Copyright (C) 1999  Tim Teulings (rael@edge.ping.de)

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

<* IF HAVE_LIB_M=TRUE THEN *>
                                  LIB "m";
<* END *>
<* IF HAVE_LIB_Z=TRUE THEN *>
                                  LIB "z";
<* END *>
<* IF HAVE_LIB_JPEG=TRUE THEN *>
                                  LIB "jpeg"  ("m");
<* END *>
<* IF HAVE_LIB_TIFF=TRUE THEN *>
                                  LIB "tiff"  ("m");
<* END *>
<* IF HAVE_LIB_PNG=TRUE THEN *>
                                  LIB "png"   ("z", "m");
<* END *>
<* IF HAVE_LIB_GIF=TRUE THEN *>
                                  LIB "gif"   ("m", "X11");
<* END *>
                                  LIB "Imlib" ("X11","Xext"
<* IF HAVE_LIB_M=TRUE THEN *>
                                               ,"m"
<* END *>
<* IF HAVE_LIB_JPEG=TRUE THEN *>
                                               ,"jpeg"
<* END *>
<* IF HAVE_LIB_PNG=TRUE THEN *>
                                               ,"png"
<* END *>
<* IF HAVE_LIB_GIF=TRUE THEN *>
                                               ,"gif"
<* END *>
<* IF HAVE_LIB_TIFF=TRUE THEN *>
                                               ,"tiff"
<* END *>
                                               ) END];

IMPORT
  C,
  X11:X11;

CONST
  RT_PLAIN_PALETTE*       = 0;
  RT_PLAIN_PALETTE_FAST*  = 1;
  RT_DITHER_PALETTE*      = 2;
  RT_DITHER_PALETTE_FAST* = 3;
  RT_PLAIN_TRUECOL*       = 4;
  (* a special high-quality renderer for people with 15 and 16bpp that dithers *)
  RT_DITHER_TRUECOL*      = 5;

CONST
  (* We just calculate the size of this struct, so we not not to define it *)
  XShmSegmentInfoSize = SIZE(C.longint)+SIZE(C.int)+SIZE(C.charPtr1d)+SIZE(C.char);

TYPE
  BorderPtr* = POINTER TO Border;
  Border*    = RECORD
                 left*,right*,
                 top*,bottom* : C.int;
               END;

  ColorPtr* = POINTER TO Color;
  Color*    = RECORD
                r*,g*,b* : C.int;
                pixel*   : C.int;
              END;

  ColorModifierPtr* = POINTER TO ColorModifier;
  ColorModifier*    = RECORD
                        gamma*      : C.int;
                        brightness* : C.int;
                        contrast*   : C.int;
                      END;

  ImagePtr* = POINTER TO Image;
  Image*    = RECORD
                rgb_width*,
                rgb_height*  : C.int;
                rgb_data*    : C.charPtr1d;
                alpha_data*  : C.charPtr1d;
                filename*    : C.charPtr1d;
                (* the below information is private *)
                width*,
                height*      : C.int;
                shape_color* : Color;
                border*      : Border;
                pixmap*      : X11.Pixmap;
                shape_mask*  : X11.Pixmap;
                cache*       : C.char; (* BOOLEAN? *)
                mod*,
                rmod*,
                gmod*,
                bmod*        : ColorModifier;
                rmap*,
                gmap*,
                bmap*        : ARRAY 256 OF C.char; (* BYTE? *)
              END;

  ImageCachePtr* = POINTER TO ImageCache;
  ImageCache*    = RECORD
                     file*   : C.charPtr1d;
                     im*     : ImagePtr;
                     refnum* : C.int;
                     dirty*  : C.char; (* BOOEAN? *)
                     prev*,
                     next*   : ImageCachePtr;
                   END;

  PixmapCachePtr* = POINTER TO PixmapCache;
  PixmapCache*    = RECORD
                      im*         : ImagePtr;
                      file*       : C.charPtr1d;
                      dirty*      : C.char; (* BOOLEAN? *)
                      width*,
                      height*     : C.int;
                      pmap*,
                      shape_mask* : X11.Pixmap;
                      xim*,
                      sxim*       : X11.XImagePtr;
                      refnum*     : C.int;
                      prev*,
                      next*       : PixmapCachePtr;
                    END;

  XdataPtr* = POINTER TO Xdata;
  Xdata*    = RECORD
                display*      : X11.DisplayPtr;
                screen*       : C.int;
                root*         : X11.Window;
                visual*       : X11.VisualPtr;
                depth*        : C.int;
                render_depth* : C.int;
                root_cmap*    : X11.Colormap;
                shm*          : C.char; (* BOOLEAN? *)
                shm_event*    : C.char;
                last_xim*,
                last_sxim*    : X11.XImagePtr;
                last_shminfo*,
                last_sshminfo*: ARRAY XShmSegmentInfoSize OF CHAR; (*X11.XShmSegementInfo;*)
                base_window*  : X11.Window;
              END;

  DataPtr* = POINTER TO Data;
  Data*    = RECORD
               num_colors*   : C.int;
               palette*      : C.address;
               palette_orig* : C.address;
               fast_rgb*     : C.address;
               fast_err*     : C.address;
               fast_erg*     : C.address;
               fast_erb*     : C.address;
               render_type*  : C.int;
               max_shm*      : C.int;
               x*            : Xdata;
               byte_order*   : C.int;
               cache*        : RECORD
                                 on_image*    : C.char;
                                 size_image*,
                                 num_image*,
                                 used_image*  : C.int;
                                 image*       : ImageCachePtr;
                                 on_pixmap*   : C.char;
                                 size_pixmap*,
                                 num_pixmap*,
                                 used_pixmap* : C.int;
                                 pixmap*      : PixmapCachePtr;
                               END;
               fastrend*     : C.char; (* BOOLEAN? *)
               hiq*          : C.char;
               mod*,
               rmod*,
               gmod*,
               bmod*         : ColorModifier;
               rmpa*,
               gmap*,
               bmap*         : ARRAY 256 OF C.char;
               fallback*     : C.char; (*  BOOLEAN? *)
             END;

PROCEDURE Imlib_init*(disp : X11.DisplayPtr):DataPtr;

(*
int Imlib_get_render_type(ImlibData *id);
void Imlib_set_render_type(ImlibData *id, int rend_type);
int Imlib_load_colors(ImlibData *id, char *file);
*)

PROCEDURE Imlib_load_image*(id : DataPtr; file : ARRAY OF CHAR):ImagePtr;

(*
int Imlib_best_color_match(ImlibData *id, int *r, int *g, int *b);
*)

PROCEDURE Imlib_render*(id : DataPtr; image : ImagePtr; width,height : C.int):C.int;

PROCEDURE Imlib_copy_image*(id : DataPtr; image : ImagePtr):X11.Pixmap;
PROCEDURE Imlib_copy_mask*(id : DataPtr; image : ImagePtr):X11.Pixmap;

PROCEDURE Imlib_move_image*(id : DataPtr; image : ImagePtr):X11.Pixmap;
PROCEDURE Imlib_move_mask*(id : DataPtr; image : ImagePtr):X11.Pixmap;

PROCEDURE Imlib_destroy_image*(id : DataPtr; image : ImagePtr);
PROCEDURE Imlib_kill_image*(id : DataPtr; image : ImagePtr);

PROCEDURE Imlib_free_colors*(id : DataPtr);
PROCEDURE Imlib_free_pixmap*(id : DataPtr; pixmap: X11.Pixmap);

(*
void Imlib_get_image_border(ImlibData *id, ImlibImage *image, ImlibBorder *border);
void Imlib_set_image_border(ImlibData *id, ImlibImage *image, ImlibBorder *border);
void Imlib_get_image_shape(ImlibData *id, ImlibImage *image, ImlibColor *color);
*)

PROCEDURE Imlib_set_image_shape*(id : DataPtr; image : ImagePtr; VAR color : Color);
(*
int Imlib_save_image_to_eim(ImlibData *id, ImlibImage *image, char *file);
int Imlib_add_image_to_eim(ImlibData *id, ImlibImage *image, char *file);
int Imlib_save_image_to_ppm(ImlibData *id, ImlibImage *image, char *file);
int Imlib_load_file_to_pixmap(ImlibData *id, char *filename, Pixmap *pmap, Pixmap *mask);
void Imlib_set_image_modifier(ImlibData *id, ImlibImage *im, ImlibColorModifier *mod);
void Imlib_set_image_red_modifier(ImlibData *id, ImlibImage *im, ImlibColorModifier *mod);
void Imlib_set_image_green_modifier(ImlibData *id, ImlibImage *im, ImlibColorModifier *mod);
void Imlib_set_image_blue_modifier(ImlibData *id, ImlibImage *im, ImlibColorModifier *mod);
void Imlib_get_image_modifier(ImlibData *id, ImlibImage *im, ImlibColorModifier *mod);
void Imlib_get_image_red_modifier(ImlibData *id, ImlibImage *im, ImlibColorModifier *mod);
void Imlib_get_image_green_modifier(ImlibData *id, ImlibImage *im, ImlibColorModifier *mod);
void Imlib_get_image_blue_modifier(ImlibData *id, ImlibImage *im, ImlibColorModifier *mod);
void Imlib_set_image_red_curve(ImlibData *id, ImlibImage *im, unsigned char *mod);
void Imlib_set_image_green_curve(ImlibData *id, ImlibImage *im, unsigned char *mod);
void Imlib_set_image_blue_curve(ImlibData *id, ImlibImage *im, unsigned char *mod);
void Imlib_get_image_red_curve(ImlibData *id, ImlibImage *im, unsigned char *mod);
void Imlib_get_image_green_curve(ImlibData *id, ImlibImage *im, unsigned char *mod);
void Imlib_get_image_blue_curve(ImlibData *id, ImlibImage *im, unsigned char *mod);
void Imlib_apply_modifiers_to_rgb(ImlibData *id, ImlibImage *im);
void Imlib_changed_image(ImlibData *id, ImlibImage *im);
void Imlib_apply_image(ImlibData *id, ImlibImage *im, Window p);
void Imlib_paste_image(ImlibData *id, ImlibImage *im, Window p, int x, int y, int w, int h);
void Imlib_paste_image_border(ImlibData *id, ImlibImage *im, Window p, int x, int y, int w, int h);
void Imlib_flip_image_horizontal(ImlibData *id, ImlibImage *im);
void Imlib_flip_image_vertical(ImlibData *id, ImlibImage *im);
void Imlib_rotate_image(ImlibData *id, ImlibImage *im, int d);
ImlibImage *Imlib_create_image_from_data(ImlibData *id, unsigned char *data, unsigned char *alpha, int w, int h);
ImlibImage *Imlib_clone_image(ImlibData *id, ImlibImage *im);
ImlibImage *Imlib_clone_scaled_image(ImlibData *id, ImlibImage *im, int w, int h);
int Imlib_get_fallback(ImlibData *id);
void Imlib_set_fallback(ImlibData *id, int fallback);
Visual *Imlib_get_visual(ImlibData *id);
Colormap Imlib_get_colormap(ImlibData *id);
char *Imlib_get_sysconfig(ImlibData *id);
ImlibImage *Imlib_create_image_from_xpm_data(ImlibData *id, char **data);
int Imlib_data_to_pixmap(ImlibData *id, char **data, Pixmap *pmap, Pixmap *mask);
void Imlib_crop_image(ImlibData *id, ImlibImage *im, int x, int y, int w, int h);
*)

END Imlib.
