#ifdef __MINGW32__
#define ACCESSOR_CALLS_ARE_FUNCTIONS 1
#include <QTML.h>
#include <Movies.h>
#include <MoviesFormat.h>
#include <Quickdraw.h>
#include <stdio.h>
#include <stdlib.h>
#else
#include <QuickTime/QuickTime.h>
#include <Carbon/Carbon.h>
extern "C" int NativePathNameToFSSpec(const char * name, FSSpec * spec, int what);
#endif

extern "C" {
#include "__oo2c.h"
#include <VO/Image/ImageStream.oh>
}

static int videoFormat = k32ARGBPixelFormat;
int videoHints = hintsHighQuality;
	// hintsHighQuality | hintsOffscreen | hintsDontUseVideoOverlaySurface;;

static void PrintError(int res, char * explain) {
	if (res != 0) {
		fprintf(stderr, "QuickTime Error code: %d during %s\n", res, explain);
	}
}

static void CheckError(int res, char * explain) {
	PrintError(res, explain);
	if (res != 0) 
		exit(0);
}

/* Convert image from native format to RGBA. QuickTime does not seem to like
 * to render to RGBA, but ARGB is more or less universally supported. Therefore,
 * we use ARGB for rendering, and do the conversion here. */

typedef struct SourceDataDesc {
	char a, r, g, b;
} * NativePixelData;

void ConvertImageToRGBA(int nPixels, NativePixelData src, VO_Image_Image__Data dest) {
	int i;

	for (i = 0; i<nPixels; i++) {
		dest[i].r = src[i].r;
		dest[i].g = src[i].g;
		dest[i].b = src[i].b;
		dest[i].a = src[i].a;
	}
}

/* Allocate a buffer to hold an ARGB bitmap. Allocate a GWorld for the
 * buffer, specifying ARGB format. */

int AllocateGWorld(Rect * rect, NativePixelData * buffer, GWorldPtr * offScreen) {
	int res;
	int width = rect->right - rect->left;
	int stride = width * 4;
	int height = rect->bottom - rect->top;
	int size = width * stride;

	*buffer = (NativePixelData) malloc(size);
	res = NewGWorldFromPtr(offScreen, videoFormat, rect,
				NULL, NULL, 0, (Ptr) *buffer, stride);
	return res;
}

/* Determine if an image passed as an argument to ReadImage is compatible for
 * us to write RGBA data. */

bool WritableImage(VO_Image_Image__Image result, int width, int height) {
	if (result == NULL)
		return false;

	if (result ->source == NULL) {
    	result->oWidth=width;
    	result->oHeight=height;
    	result->width=width;
    	result->height=height;
    	result->alpha=0;
    	result->source=(VO_Image_Image__Data)RT0__NewObject(_td_VO_Image_Image__Data.baseTypes[0], width * height);
		result->current = result->source;
	} else {
		return (result ->width == width) && (result->height == height);
	}

	return result->source != NULL;
}


/* VTABLE interface defined by VO:Image:ImageStream.InputStream. */

class Handler {
};

class Position : public Handler {
public:
	virtual bool GetDuration(int & start, int & end) = 0;
	virtual bool GetPosition(int & position) = 0;
	virtual bool SetPosition(int & position) = 0;
};

class ImageInputStream {
public:
	virtual void GetImageSize(int & width, int & height) = 0;
	virtual bool ReadImage(VO_Image_Image__Image result) = 0;
	virtual bool HasMore(void) = 0;
	virtual void Close(void) = 0;
	virtual Handler * GetHandler(int id);
};

class QTVideoDecoder : public ImageInputStream, Position {
	bool isOpen;			/* true if the image stream is open for reading */
	Movie movie;			/* QT movie handle */
	short movieRefNumber;	/* QT movie reference number */
	TimeValue currentTime;	/* time associated with next frame */
	TimeValue startTime;	/* time associated with next frame */
	TimeValue duration;		/* duration of this movie */
	GWorldPtr offScreen;	/* off-screen graphics world for rendering */
	NativePixelData buffer;	/* image buffer associated with offscreen gworld */
	Rect rect;				/* image dimensions for this movie */
	short width;			/* width of image in pixels */
	short height;			/* height of image in pixels */

public:

bool OpenFile(char * name) {
	OSErr res;
	short resID = 0;
	Str255 strName;
	Boolean bWasChanged;
	FSSpec spec;
	Rect portRect;

	movie = NULL;
	res = NativePathNameToFSSpec(name, &spec, 0);
	CheckError(res, "NativePathNameToFSSPec");

	isOpen = false;
	res = OpenMovieFile(&spec, &movieRefNumber, fsRdPerm);
	if (res == 0) {
		res = NewMovieFromFile(&movie, movieRefNumber, &resID, strName, 
			newMovieActive, &bWasChanged);
		CheckError(res, "NewMovieFromFile");
		/* ListFormats(movie); */

		GetMovieBox(movie, &rect);
		width = rect.right - rect.left ;
		height = rect.bottom - rect.top;
		currentTime = GetMovieTime(movie, NULL);
		startTime = currentTime;
		duration = GetMovieDuration(movie);
		offScreen = NULL;
		/* printf("Decoder: image size is %d x %d\n", width, height); */

		res = AllocateGWorld(&rect, &buffer, &offScreen);

		if (res == 0) {
			SetMovieGWorld(movie, (CGrafPtr) offScreen, GetGWorldDevice(offScreen));
			SetMoviePlayHints(movie, videoHints, videoHints);
			isOpen = true;
		}
	} else CheckError(res, "OpenMovieFile");
	return isOpen;
}

QTVideoDecoder() {
	isOpen = false;
}

bool ReadImage(VO_Image_Image__Image result) {
	if (!isOpen) 
		return false;
	if (!WritableImage(result, width, height))
		return false;

    OSType  whichMediaType = VIDEO_TYPE;

	GetMovieNextInterestingTime(movie,
			nextTimeMediaSample, 
			1, 
			&whichMediaType, 
			currentTime, 
			1, 
			&currentTime, 
			NULL);
	SetMovieTimeValue(movie, currentTime);
    /* printf("time=%d\n", currentTime); */
	MoviesTask(movie, 0);
	ConvertImageToRGBA(width * height, buffer, result->source);
    DYN_TBCALL(VO_Image_Image,ImageDesc,FreeOSStructures,result,(result));
	return true;
}

void Close(void) {
	isOpen = false;
	CheckError(CloseMovieFile(movieRefNumber), "CloseMovieFile");
	if (movie) {
		DisposeMovie(movie);
		movie = NULL;
	}
	if (offScreen) {
		DisposeGWorld(offScreen);
		offScreen = NULL;
	}
}

void GetImageSize(int & width, int & height) {
	width = this -> width;
	height = this -> height;
}

bool HasMore(void) {
	return currentTime >= 0;
}

Handler * GetHandler(int id) {
	switch (id) {
	case 0:
		return (Position *) this;
	default:
		return NULL;
	}
}

bool GetDuration(int & start, int & end) {
	start = startTime;
	end = startTime + duration;
	return true;
}

bool GetPosition(int & position) {
	position =  currentTime;
	return true;
}

bool SetPosition(int & position) {
	currentTime = position;
	return true;
}

};

extern "C" ImageInputStream * NewMovieInputStream(char * name) { 
	QTVideoDecoder * dec = new QTVideoDecoder();
	if (dec->OpenFile(name)) {
		return dec;
	} else {
		delete dec;
		return NULL;
	}
}

extern "C" ComponentResult myGrabFrameComplete (SGChannel c, short bufferNum,
	Boolean * done, long refCon);

class QTDigitiser : public ImageInputStream {
	SeqGrabComponent anSG;
	SGChannel videoChannel;
	Rect bounds;
	int width, height;
	bool isOpen;
	GWorldPtr offScreen;
	VO_Image_Image__Data imageData;
	NativePixelData buffer;
public:
	volatile bool done;

void Close(void) {
	if (videoChannel) {
		SGDisposeChannel(anSG, videoChannel);
		videoChannel = NULL;
	}
	if (anSG) {
		CloseComponent(anSG);
		anSG = NULL;
	}
	if (offScreen) {
		DisposeGWorld(offScreen);
		offScreen = NULL;
	}
	if (buffer) {
		free(buffer);
		buffer = NULL;
	}
}

bool Open(char * name, int w, int h) {
	OSErr err = noErr;

	done = false;
	isOpen = false;

	videoChannel = NULL;
	anSG = NULL;
	offScreen = NULL;
	buffer = NULL;
	imageData = NULL;

	width = w; height = h;
	bounds.left = 0; bounds.right = w;
	bounds.top = 0; bounds.bottom = h;

	/* open up the default sequence grabber */
	anSG = OpenDefaultComponent (SeqGrabComponentType, 0);
	if (anSG) {
		/* initialize the default sequence grabber component */
		err = SGInitialize (anSG);
		if (!err) {
			err = AllocateGWorld(&bounds, &buffer, &offScreen);
/*
			if (!err) {
				err = SGSetGWorld(anSG, (CGrafPtr) offScreen, NULL);
			}
*/
		}
		if (err) {
			PrintError(err, "Initialising component");
		}
	} else {
		printf("Cannot open default component\n");
		return false;
	}

	if (!err) {
		/* set up video channel */
		long usage;
		usage = seqGrabRecord;
		err = SGNewChannel(anSG, VideoMediaType, &videoChannel);
		if (!err) {
			err = SGSetChannelBounds(videoChannel, &bounds);
			if (!err) {
				err = SGSetChannelUsage(videoChannel, usage);
			}
		}
		if (err) {
			PrintError(err, "Setting channel characteristics");
		}
	}

	/* set up video bottleneck functions */
	if (!err) {
		err = SGSetChannelRefCon(videoChannel, (long) this);
		if (!err) {
			VideoBottles vb;

			vb.procCount = 9;
			err = SGGetVideoBottlenecks(videoChannel, &vb);
			if (!err) {
				vb.grabCompleteProc = myGrabFrameComplete;
				err = SGSetVideoBottlenecks(videoChannel, &vb);
			}
		}
		if (err) {
			PrintError(err, "Setting up video bottlenecks");
		}
	}

	if (!err) {
		SGSettingsDialog (anSG, videoChannel, 0, NULL,
			DoTheRightThing, NULL, 0);
	}

	if (err) {
		Close();
		return false;
	} else {
		isOpen = true;
		return true;
	}
}

bool ReadImage(VO_Image_Image__Image result) {
	if (!isOpen) return false;
	if (result == NULL) 
		return false;
	if (!WritableImage(result, width, height))
		return false;

	imageData = result->source;

	OSErr err;

	err = noErr; /* SGSetChannelMaxFrames(videoChannel, 1); */
	if (err) PrintError(err, "SGSetChannelMaxFrames");
	if (!err) {
		done = false;
		err = SGStartRecord(anSG);
		if (err) 
			PrintError(err, "SGSetStartRecord");
		else {
			while (!done) {
				err = SGIdle(anSG);
			}
		}

		err = SGStop(anSG);
	}

	if (err) {
		PrintError(err, "ReadImage");
		return false;
	} else {
        DYN_TBCALL(VO_Image_Image,ImageDesc,FreeOSStructures,result,(result));
		return true;
	}
}

void HandlePixmap(PixMapHandle pmh) {
	if ((buffer == NULL) || (imageData == NULL)) return;
	CopyBits((const BitMap *) pmh[0], GetPortBitMapForCopyBits(offScreen), &bounds, &bounds, srcCopy, NULL);
	ConvertImageToRGBA(width * height, (NativePixelData) buffer, imageData);
	imageData = NULL;
	done = true;
}

bool HasMore(void) { 
	return isOpen; 
}

void GetImageSize(int & w, int & h) {
	w = width;
	h = height;
}

Handler * GetHandler(int id) {
	return NULL;
}

};

ComponentResult myGrabFrameComplete (SGChannel c, short bufferNum,
	Boolean * done, long refCon) {
	ComponentResult err;
	PixMapHandle bufferPM;
	Rect bufferRect;
	QTDigitiser * dig = (QTDigitiser *) refCon;

	err = SGGrabFrameComplete(c, bufferNum, done);
	if (!err) {
		if (*done) {
			err = SGGetBufferInfo(c, bufferNum, &bufferPM, &bufferRect,
				NULL, NULL);
			if (!err) {
				dig->HandlePixmap(bufferPM);
			}
		}
	}

	if (err) {
		PrintError(err, "myGrabFrameComplete");
	}
	return err;
}

extern "C" ImageInputStream * NewDigitiserInputStream(char * name, int w, int h) { 
	QTDigitiser * dec = new QTDigitiser();
	if (dec->Open(name, w, h)) {
		return dec;
	} else {
		delete dec;
		return NULL;
	}
}

extern "C" void OOC_VO_Image_ImageStream_QTImageStream_init0(void) {
#ifdef __MINGW32__
	InitializeQTML(0L);
#endif
	EnterMovies();
}

#if 0

/* Miscellaneous support functions, not currently used. */

/*
Boolean CanRenderMovieToPixelFormat(Movie  inMovie,
                                    OSType inPixelFormat)
{
  Track videoTrack, secondVisualTrack;
  ImageDescriptionHandle imageDesc = NULL;
  Boolean canRenderNonRGB = false;
  MatrixRecord matrix;
  Media videoMedia;
  OSType codecType;
  ComponentDescription cd = { decompressorComponentType, 0, 0, 0,
                              cmpIsMissing };
  Component decompressor = 0;

  // values of 1, 2, 4, 8, 16, 24 and 32 specify standard RGB
  // pixel formats while values of 33, 34, 36 and 40 specify
  // standard gray-scale pixel formats -- don't use this
  // approach for these pixel formats 
  if (inPixelFormat <= 40) return true;

  // check that the Movie matrix is no worse than scale+translate
  GetMovieMatrix(inMovie, &matrix);
  if (GetMatrixType(&matrix) > scaleTranslateMatrixType) goto nope;

  // get the first video track
  videoTrack = GetMovieIndTrackType(inMovie, 1, VideoMediaType,
                                    movieTrackMediaType);
  if (!videoTrack) goto nope;

  // make sure there are no other visual tracks
  // (video tracks are always visual)
  secondVisualTrack = GetMovieIndTrackType(inMovie, 2,
                                        VisualMediaCharacteristic,
                                        movieTrackCharacteristic);
  if (secondVisualTrack) goto nope;

  // check that the video track matrix is no worse than
  // scale+translate
  GetTrackMatrix(videoTrack, &matrix);
  if (GetMatrixType(&matrix) > scaleTranslateMatrixType) goto nope;

  // check that there's only one sample description
  videoMedia = GetTrackMedia(videoTrack);
  if (1 != GetMediaSampleDescriptionCount(videoMedia)) goto nope;

  // get the codec type out of that sample description
  imageDesc = (ImageDescriptionHandle)NewHandle(0);
  GetMediaSampleDescription(videoMedia, 1,
                            (SampleDescriptionHandle)imageDesc);
  if (noErr != GetMoviesError()) goto nope;
  codecType = (*imageDesc)->cType;

  // find decompressors for this codec type -- we'll need to find
  // at least one that lists a matching pixel format in its
  // cpix public resource
  cd.componentSubType = codecType;
  decompressor = FindNextComponent(0, &cd);
  if (!decompressor) goto nope;

  do {
    Handle cpix = NULL;
    // 'cpix' resources are used by codecs to list their
    // supported non-RGB pixel formats
    if (noErr == GetComponentPublicResource(decompressor,
                         FOUR_CHAR_CODE('cpix'), 1, &cpix)) {
      int i;
      int cpixFormatCount = GetHandleSize(cpix) / sizeof(OSType);
      for (i = 0; i < cpixFormatCount; i++) {
        if (inPixelformat == (*(OSType**)cpix)[i]) {
          canRenderNonRGB = true;
        }
      }
      DisposeHandle( cpix );
    }
    decompressor = FindNextComponent(decompressor, &cd);
  } while (decompressor && false == canRenderNonRGB);

nope:
  if (imageDesc) DisposeHandle((Handle)imageDesc);

  return canRenderNonRGB;
}
*/

void ListFormats(Movie  inMovie) {
  Track videoTrack, secondVisualTrack;
  ImageDescriptionHandle imageDesc = NULL;
  Boolean canRenderNonRGB = false;
  MatrixRecord matrix;
  Media videoMedia;
  OSType codecType;
  ComponentDescription cd = { decompressorComponentType, 0, 0, 0,
                              cmpIsMissing };
  Component decompressor = 0;

  // check that the Movie matrix is no worse than scale+translate
  GetMovieMatrix(inMovie, &matrix);
  if (GetMatrixType(&matrix) > scaleTranslateMatrixType) goto nope;

  // get the first video track
  videoTrack = GetMovieIndTrackType(inMovie, 1, VideoMediaType,
                                    movieTrackMediaType);
  if (!videoTrack) goto nope;

  // make sure there are no other visual tracks
  // (video tracks are always visual)
  secondVisualTrack = GetMovieIndTrackType(inMovie, 2,
                                        VisualMediaCharacteristic,
                                        movieTrackCharacteristic);
  if (secondVisualTrack) goto nope;

  // check that the video track matrix is no worse than
  // scale+translate
  GetTrackMatrix(videoTrack, &matrix);
  if (GetMatrixType(&matrix) > scaleTranslateMatrixType) goto nope;

  // check that there's only one sample description
  videoMedia = GetTrackMedia(videoTrack);
  if (1 != GetMediaSampleDescriptionCount(videoMedia)) goto nope;

  // get the codec type out of that sample description
  imageDesc = (ImageDescriptionHandle)NewHandle(0);
  GetMediaSampleDescription(videoMedia, 1,
                            (SampleDescriptionHandle)imageDesc);
  if (noErr != GetMoviesError()) goto nope;
  codecType = (*imageDesc)->cType;

  // find decompressors for this codec type -- we'll need to find
  // at least one that lists a matching pixel format in its
  // cpix public resource
  cd.componentSubType = codecType;
  decompressor = FindNextComponent(0, &cd);
  if (!decompressor) goto nope;

  do {
    Handle cpix = NULL;
	char *  name;
    // 'cpix' resources are used by codecs to list their
    // supported non-RGB pixel formats
    if (noErr == GetComponentPublicResource(decompressor,
                         FOUR_CHAR_CODE('cpix'), 1, &cpix)) {
      int i;
      int cpixFormatCount = GetHandleSize(cpix) / sizeof(OSType);
	  GetComponentInfo(decompressor, &cd, (Handle) &name, NULL, NULL);
		printf("Decompressor: %s\n", name);
      for (i = 0; i < cpixFormatCount; i++) {
		int value = (*(OSType**)cpix)[i] ;
        printf("Format: %08x (%c%c%c%c)\n", value,
			value & 0xff, (value >>8) & 0xff,
			(value >> 16) & 0xff, (value >>24) & 0xff);
		canRenderNonRGB = true;
      }
      DisposeHandle( cpix );
    }
    decompressor = FindNextComponent(decompressor, &cd);
  } while (decompressor && false == canRenderNonRGB);

nope:
  if (imageDesc) DisposeHandle((Handle)imageDesc);

  if (!canRenderNonRGB) {
    printf("Can only render RGB\n");
  }
}
#endif
