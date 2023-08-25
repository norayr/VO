MODULE xpm [INTERFACE "C"; LINK LIB "Xpm" ("X11") END];

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

IMPORT
  C,
  X11;

(*
 * first some identification numbers:
 * the version and revision numbers are determined with the following rule:
 * SO Major number = LIB minor version number.
 * SO Minor number = LIB sub-minor version number.
 * e.g: Xpm version 3.2f
 *      we forget the 3 which is the format number, 2 gives 2, and f gives 6.
 *      thus we have XpmVersion = 2 and XpmRevision = 6
 *      which gives  SOXPMLIBREV = 2.6
 *
 * Then the XpmIncludeVersion number is built from these numbers.
 *)

CONST
  XpmFormat*         = 3;
  XpmVersion*        = 4;
  XpmRevision*       = 8;
  XpmIncludeVersion* = (XpmFormat * 100 + XpmVersion) * 100 + XpmRevision;

TYPE
  Pixel* = C.longint;

(* Return ErrorStatus codes:
 * null     if full success
 * positive if partial success
 * negative if failure
 *)

CONST

  XpmColorError*   =  1;
  XpmSuccess*      =  0;
  XpmOpenFailed*   = -1;
  XpmFileInvalid*  = -2;
  XpmNoMemory*     = -3;
  XpmColorFailed*  = -4;

TYPE
  XpmColorSymbolPtr* = POINTER TO XpmColorSymbol;
  XpmColorSymbol* = RECORD
                      name*  : C.charPtr1d; (* Symbolic color name *)
                      value* : C.charPtr1d; (* Color value *)
                      pixel* : Pixel;       (* Color pixel *)
                    END;

  XpmExtensionPtr* = POINTER TO XpmExtension;
  XpmExtension* = RECORD
                    name*   : C.charPtr1d; (* name of the extension *)
                    nlines* : C.longint;	 (* number of lines in this extension *)
                    lines*  : C.charPtr2d; (* pointer to the extension array of strings *)
                  END;


  XpmColorPtr* = POINTER TO XpmColor;
  XpmColor* = RECORD
                string*   : C.charPtr1d; (* characters string *)
                symbolic* : C.charPtr1d; (* symbolic name *)
                m_color*  : C.charPtr1d; (* monochrom default *)
                g4_color* : C.charPtr1d; (* 4 level grayscale default *)
                g_color*  : C.charPtr1d; (* other level grayscale default *)
                c_color*  : C.charPtr1d; (* color default *)
              END;

  ColorTable* = POINTER TO ARRAY OF XpmColor;

  XpmImagePtr* = POINTER TO XpmImage;
  XpmImage* = RECORD
                width*      : C.int;	(* image width *)
                height*     : C.int;	(* image height *)
                cpp*        : C.int;	(* number of characters per pixel *)
                ncolor*     : C.int;	(* number of colors *)
                colorTable* : ColorTable; (* list of related colors *)
                data*       : POINTER TO ARRAY OF C.int; (* image data *)
              END;

  ExtensionTable* = POINTER TO ARRAY OF XpmExtension;

  XpmInfoPtr* = POINTER TO XpmInfo;
  XpmInfo* = RECORD
               valuemask*   : C.longint;   (* Specifies which attributes are defined *)
               hints_cmt*   : C.charPtr1d; (* Comment of the hints section *)
               colors_cmt*  : C.charPtr1d; (* Comment of the colors section *)
               pixels_cmt*  : C.charPtr1d; (* Comment of the pixels section *)
               x_hotspot*   : C.int;       (* Returns the x hotspot's coordinate *)
               y_hotsport*  : C.int;       (* Returns the y hotspot's coordinate *)
               nextensions* : C.int;       (* number of extensions *)
               extensions*  : ExtensionTable; (* pointer to array of extensions *)
             END;


  ColorSymbolTable* = POINTER TO ARRAY OF XpmColorSymbol;

  XpmAttributesPtr* = POINTER TO XpmAttributes;
  XpmAttributes*= RECORD
                    valuemask*    : SET;           (* Specifies which attributes are defined *)
                    visual*       : X11.VisualPtr; (* Specifies the visual to use *)
                    colormap*     : X11.Colormap;  (* Specifies the colormap to use *)
                    depth*        : C.int;         (* Specifies the depth *)
                    width*        : C.int;         (* Returns the width of the created pixmap *)
                    height*       : C.int;         (* Returns the height of the created pixmap *)
                    x_hotspot*    : C.int;         (* Returns the x hotspot's coordinate *)
                    y_hotspot*    : C.int;         (* Returns the y hotspot's coordinate *)
                    cpp*          : C.int;         (* Specifies the number of char per pixel *)
                    pixels*       : POINTER TO ARRAY OF Pixel; (* List of used color pixels *)
                    npixels*      : C.int;	   (* Number of used pixels *)
                    colorsymbols* : ColorSymbolTable; (* Array of color symbols to override *)
                    numsymbols*   : C.int;         (* Number of symbols *)
                    rgb_fname*    : C.charPtr1d;   (* RGB text file name *)
                    nextensions*  : C.int;         (* number of extensions *)
                    extensions*   : ExtensionTable;(* pointer to array of extensions *)

                    ncolors*      : C.int;         (* Number of colors *)
                    colorTable*   : ColorTable;    (* Color table pointer *)
                    (* 3.2 backward compatibility code *)
                    hints_cmt*    : C.charPtr1d;   (* Comment of the hints section *)
                    colors_cmt*   : C.charPtr1d;   (* Comment of the colors section *)
                    pixels_cmt*   : C.charPtr1d;   (* Comment of the pixels section *)
                    (* end 3.2 bc *)
                    mask_pixel*   : C.int;         (* Transparent pixel's color table index *)

                   (* Color Allocation Directives *)
                    exactColors*  : X11.Bool;			 (* Only use exact colors for visual *)
                    closeness*    : C.int; 		     (* Allowable RGB deviation *)
                    red_closeness*: C.int;		     (* Allowable red deviation *)
                    green_closeness* : C.int;	     (* Allowable green deviation *)
                    blue_closeness* : C.int;	   (* Allowable blue deviation *)
                    color_key*    : C.int;			   (* Use colors from this color set *)

                    alloc_pixels* : POINTER TO ARRAY OF Pixel; (* Returns the list of alloc'ed color pixels *)
                    nalloc_pixels*: X11.Bool;			 (* Returns the number of alloc'ed color pixels *)

                    alloc_close_colors* : X11.Bool;(* Specify whether close colors should be allocated using XAllocColor or not *)
                    bitmap_format*: C.int;			   (* Specify the format of 1bit depth images: ZPixmap or XYBitmap *)
                  END;

CONST
(* XpmAttributes value masks bits *)
  XpmVisual*            =  0;
  XpmColormap*	        =  1;
  XpmDepth*	            =  2;
  XpmSize*		          =  3;  (* width & height *)
  XpmHotspot*	          =  4;	(* x_hotspot & y_hotspot *)
  XpmCharsPerPixel*     =  5;
  XpmColorSymbols*	    =  6;
  XpmRgbFilename*	      =  7;
(* 3.2 backward compatibility code *)
  XpmInfos*	            =  8;
  XpmReturnInfos*       = XpmInfos;
(* end 3.2 bc *)
  XpmReturnPixels*      =  9;
  XpmExtensions*        = 10;
  XpmReturnExtensions*  = XpmExtensions;

  XpmExactColors*       = 11;
  XpmCloseness*	        = 12;
  XpmRGBCloseness*      = 13;
  XpmColorKey*	        = 14;

  XpmColorTable*        = 15;
  XpmReturnColorTable*  = XpmColorTable;

  XpmReturnAllocPixels* = 16;
  XpmAllocCloseColors*  = 17;
  XpmBitmapFormat*      = 18;

(* XpmInfo value masks bits *)
  XpmComments*          =  XpmInfos;
  XpmReturnComments*    = XpmComments;

(* XpmAttributes mask_pixel value when there is no mask *)  (* ??? *)
(*#ifndef FOR_MSW
#define XpmUndefPixel 0x80000000
#else
/* int is only 16 bit for MSW */
#define XpmUndefPixel 0x8000
#endif
*)

(*
 * color keys for visual type, they must fit along with the number key of
 * each related element in xpmColorKeys[] defined in XpmI.h
 *)
 XPM_MONO*  = 2;
 XPM_GREY4* = 3;
 XPM_GRAY4* = 3;
 XPM_GREY*  = 4;
 XPM_GRAY*  = 4;
 XPM_COLOR* = 5;

(*
 * functions declarations
 *)

PROCEDURE XpmCreatePixmapFromData* (display : X11.DisplayPtr;
    d : X11.Drawable;
    data : C.charPtr2d;
    VAR pixmap : X11.Pixmap;
    VAR shapemask_return : X11.Pixmap;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateDataFromPixmap* (display : X11.DisplayPtr;
    VAR data_return : C.charPtr2d;
    pixmap : X11.Pixmap;
    shapemask : X11.Pixmap;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmReadFileToPixmap* (display : X11.DisplayPtr;
    d : X11.Drawable;
    filename : ARRAY OF CHAR;
    VAR pixmap : X11.Pixmap;
    VAR shapemask_return : X11.Pixmap;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmWriteFileFromPixmap* (display : X11.DisplayPtr;
    filename : ARRAY OF CHAR;
    pixmap : X11.Pixmap;
    shapemask : X11.Pixmap;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateImageFromData* (display : X11.DisplayPtr;
    data : C.charPtr2d;
    VAR image_return : X11.XImagePtr;
    VAR hapemask_return : X11.XImagePtr;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateDataFromImage* (display : X11.DisplayPtr;
    VAR data_return : C.charPtr2d;
    image : X11.XImagePtr;
    shapeimage : X11.XImagePtr;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmReadFileToImage* (display : X11.DisplayPtr;
   filename : ARRAY OF CHAR;
   VAR image_return : X11.XImagePtr;
   VAR shapeimage_return : X11.XImagePtr;
   attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmWriteFileFromImage* (display : X11.DisplayPtr;
    filename : ARRAY OF CHAR;
    image : X11.XImagePtr;
    shapeimage : X11.XImagePtr;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateImageFromBuffer* (display : X11.DisplayPtr;
    buffer : ARRAY OF CHAR;
    VAR image_return : X11.XImagePtr;
    VAR shapemask_return : X11.XImagePtr;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreatePixmapFromBuffer* (display : X11.DisplayPtr;
    d : X11.Drawable;
    buffer : ARRAY OF CHAR;
    VAR pixmap : X11.Pixmap;
    VAR shapemask_return : X11.Pixmap;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateBufferFromImage* (display : X11.DisplayPtr;
    VAR buffer_return : C.charPtr1d;
    image : X11.XImagePtr;
    shapeimage : X11.XImagePtr;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateBufferFromPixmap* (display : X11.DisplayPtr;
    VAR buffer_return : C.charPtr1d;
    pixmap : X11.Pixmap;
    shapemask : X11.Pixmap;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmReadFileToBuffer* (filename : ARRAY OF CHAR; VAR buffer_return : C.charPtr1d):C.int;
PROCEDURE XpmWriteFileFromBuffer* (filename : ARRAY OF CHAR; buffer : ARRAY OF CHAR):C.int;

PROCEDURE XpmReadFileToData* (filename : ARRAY OF CHAR; VAR data_return : C.charPtr2d):C.int;
PROCEDURE XpmWriteFileFromData* (filename : ARRAY OF CHAR; data : C.charPtr2d):C.int;

PROCEDURE XpmAttributesSize* ():C.int;
PROCEDURE XpmFreeAttributes* (attributes : XpmAttributesPtr);
PROCEDURE XpmFreeExtensions* (extensions : XpmExtensionPtr; nextensions : C.int);

PROCEDURE XpmFreeXpmImage* (image : XpmImagePtr);
PROCEDURE XpmFreeXpmInfo* (info : XpmInfoPtr);
PROCEDURE XpmGetErrorString* (errcode : C.int):C.charPtr1d;
PROCEDURE XpmLibraryVersion* ():C.int;

     (* XpmImage functions *)
PROCEDURE XpmReadFileToXpmImage* (filename : ARRAY OF CHAR;
    image : XpmImagePtr;
    info : XpmInfoPtr):C.int;

PROCEDURE XpmWriteFileFromXpmImage* (filename : ARRAY OF CHAR;
    image : XpmImagePtr;
    info : XpmInfoPtr):C.int;

PROCEDURE XpmCreatePixmapFromXpmImage* (display : X11.DisplayPtr;
    d : X11.Drawable;
    image : XpmImagePtr;
    VAR pixmap : X11.Pixmap;
    VAR shapemask_return : X11.Pixmap;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateImageFromXpmImage* (display : X11.DisplayPtr;
    image : XpmImagePtr;
    VAR image_return : X11.XImagePtr;
    VAR shapeimage_return : X11.XImagePtr;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateXpmImageFromImage* (display : X11.DisplayPtr;
    image : X11.XImagePtr;
    shapeimage : X11.XImagePtr;
    xpmimage : XpmImagePtr;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateXpmImageFromPixmap* (display : X11.DisplayPtr;
    pixmap : X11.Pixmap;
    shapemask : X11.Pixmap;
    xpmimage : XpmImagePtr;
    attributes : XpmAttributesPtr):C.int;

PROCEDURE XpmCreateDataFromXpmImage* (VAR data_return : C.charPtr2d;
    image : XpmImagePtr;
    info : XpmInfoPtr):C.int;

PROCEDURE XpmCreateXpmImageFromData* (data : C.charPtr2d;
    image : XpmImagePtr;
    info : XpmInfoPtr):C.int;

PROCEDURE XpmCreateXpmImageFromBuffer* (buffer : ARRAY OF CHAR;
    image : XpmImagePtr;
    info : XpmInfoPtr):C.int;

PROCEDURE XpmCreateBufferFromXpmImage* (VAR buffer_return : C.charPtr1d;
    image : XpmImagePtr;
    info : XpmInfoPtr):C.int;

END xpm.
