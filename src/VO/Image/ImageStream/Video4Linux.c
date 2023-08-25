#include "__oo2c.h"
#include "VO/Image/Image.oh"
#include "VO/Image/ImageStream/Video4Linux.d"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <getopt.h>
#include <fcntl.h>
#include <signal.h>
/*#include <time.h>
#include <sys/types.h>*/
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <linux/videodev.h>

typedef struct Private
{
  int                     handle,memoryMaped,bufferSize;
  struct video_capability capabilities;
  struct video_channel    channel;
  struct video_picture    picture;
  struct video_mbuf       buffer;
  struct video_window     window;
  char                    *videoBuffer;
} Private;

VO_Image_ImageStream_Video4Linux__InputStream VO_Image_ImageStream_Video4Linux__Open(const OOC_CHAR8 device__ref[],
                                                                                     OOC_LEN device_0d,
                                                                                     OOC_INT32 channel)
{
  int                                           handle;
  Private*                                      private;
  VO_Image_ImageStream_Video4Linux__InputStream stream;

  handle=open(device__ref,O_RDWR);

  if (handle==-1) {
    return NULL;
  }

  private=(Private*)RT0__NewBlock(sizeof(Private));
  private->handle=handle;

  /* get capabilities like image size */
  if (ioctl(handle,VIDIOCGCAP,&private->capabilities)==-1) {
    perror("ioctl (VIDIOCGCAP)");
    RT0__FreeBlock(private);
    close(handle);
    return NULL;
  }

  /* Get default picture values */
  if (ioctl(handle,VIDIOCGPICT, &private->picture)==-1) {
    perror("ioctl (VIDIOCGPICT)");
    RT0__FreeBlock(private);
    close(handle);
    return NULL;
  }

  /* Set default picture values */
  private->picture.brightness=32767;
  private->picture.hue=32767;
  private->picture.colour=32767;
  private->picture.contrast=32767;
  private->picture.whiteness=32767;
  private->picture.depth=24;
  private->picture.palette=VIDEO_PALETTE_RGB24; /* we could choose different, since we must copy anyway */

  if (ioctl(handle,VIDIOCSPICT,&private->picture)==-1) {
    perror("ioctl (VIDIOCSPICT)");
    RT0__FreeBlock(private);
    close(handle);
    return NULL;
  }

  private->channel.channel=channel;
  private->channel.norm=VIDEO_MODE_PAL; /* we should make this configurable */

  if (ioctl(handle,VIDIOCSCHAN,&private->channel)==-1) {
    perror("ioctl (VIDIOCSCHAN)");
    RT0__FreeBlock(private);
    close(handle);
    return NULL;
  }

  if (ioctl(handle,VIDIOCGMBUF,&private->buffer)==-1) {
    private->memoryMaped=0;
    if (ioctl(handle,VIDIOCGWIN,&private->window) != -1) {
      private->window.width=private->capabilities.maxwidth;
      private->window.height=private->capabilities.maxheight;
      if (ioctl(private->handle,VIDIOCSWIN,&private->window)==-1) {
        perror("ioctl (VIDIOCSWIN)");
        RT0__FreeBlock(private);
        close(handle);
        return NULL;
      }
    }
    private->bufferSize=private->capabilities.maxwidth*private->capabilities.maxheight*3;
  }
  else {
    private->memoryMaped=1;
    private->bufferSize=private->buffer.size;
  }

  private->videoBuffer=malloc(private->bufferSize);

  stream=RT0__NewObject(OOC_TYPE_DESCR(VO_Image_ImageStream_Video4Linux,InputStreamDesc));
  stream->internal=private;

  return stream;
}

void VO_Image_ImageStream_Video4Linux__InputStreamDesc_GetImageSize(VO_Image_ImageStream_Video4Linux__InputStream s,
                                                                    OOC_INT32 *width,
                                                                    OOC_INT32 *height)
{
  Private *private;

  if (s==NULL) {
    return;
  }

  private=(Private*)s->internal;

  *width=private->capabilities.maxwidth;
  *height=private->capabilities.maxheight;
}


OOC_CHAR8 VO_Image_ImageStream_Video4Linux__InputStreamDesc_ReadImage(VO_Image_ImageStream_Video4Linux__InputStream s,
                                                                      VO_Image_Image__Image result)
{
  Private           *private;
  char              *map;
  struct video_mmap memoryMap;
  int               x,y;

  if (s==NULL) {
    return;
  }

  private=(Private*)s->internal;

  if ((result==NULL) ||
      ((result->source!=NULL) &&
       ((result->oWidth!=private->capabilities.maxwidth) || (result->oHeight!=private->capabilities.maxheight)))) {
    return 0;
  }

  if (private->memoryMaped) {
    map = mmap(0,private->bufferSize,PROT_READ | PROT_WRITE,MAP_SHARED,private->handle,0);
    if ((unsigned char *)-1==(unsigned char *)map) {
        perror("mmap()");
        return 0;
    }

    memoryMap.format=VIDEO_PALETTE_RGB24;
    memoryMap.frame=0;
    memoryMap.width=private->capabilities.maxwidth;
    memoryMap.height=private->capabilities.maxheight;
    if (ioctl(private->handle,VIDIOCMCAPTURE,&memoryMap)==-1) {
        perror("VIDIOCMCAPTURE");
        munmap(map,private->bufferSize);
        return 0;
    }
    if (ioctl(private->handle,VIDIOCSYNC,&memoryMap)==-1) {
        perror("VIDIOCSYNC");
        munmap(map,private->bufferSize);
        return 0;
    }
    memcpy(private->videoBuffer,map,private->bufferSize);
    munmap(map,private->bufferSize);
  }
  else {
    if (read(private->handle,private->videoBuffer,private->bufferSize)<=0) {
      return 0;
    }
  }

  if (result->source==NULL) {
    result->oWidth=private->capabilities.maxwidth;
    result->oHeight=private->capabilities.maxheight;
    result->width=private->capabilities.maxwidth;
    result->height=private->capabilities.maxheight;
    result->alpha=0;
    result->source=RT0__NewObject(_td_VO_Image_Image__Data.baseTypes[0],
                                  private->capabilities.maxwidth*private->capabilities.maxheight);

  }

  x=0;
  y=0;
  while (y<private->capabilities.maxwidth*private->capabilities.maxheight) {
    result->source[y].b=private->videoBuffer[x];
    x++;
    result->source[y].g=private->videoBuffer[x];
    x++;
    result->source[y].r=private->videoBuffer[x];
    x++;
    result->source[y].a=255;

    y++;
  }

  result->current=result->source;

  DYN_TBCALL(VO_Image_Image,ImageDesc,FreeOSStructures,result,(result));

  return 1;
}

OOC_CHAR8 VO_Image_ImageStream_Video4Linux__InputStreamDesc_HasMore(VO_Image_ImageStream_Video4Linux__InputStream s)
{
  return 1;
}

void VO_Image_ImageStream_Video4Linux__InputStreamDesc_Close(VO_Image_ImageStream_Video4Linux__InputStream s)
{
  Private *private;

  if (s==NULL) {
    return;
  }

  private=(Private*)s->internal;

  free(private->videoBuffer);

  close(private->handle);
  RT0__FreeBlock(private);
}

VO_Image_ImageStream__Handler VO_Image_ImageStream_Video4Linux__InputStreamDesc_GetHandler(VO_Image_ImageStream_Video4Linux__InputStream s, OOC_INT32 id) {
  return NULL;
}

void OOC_VO_Image_ImageStream_Video4Linux_init(void)
{
  /* no code */
}

