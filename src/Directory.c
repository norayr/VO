/* our own includes */
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

#ifdef __MINGW32__
#define S_IRGRP S_IRUSR
#define S_IWGRP S_IWUSR
#define S_IXGRP S_IXUSR
#define S_IROTH S_IRUSR
#define S_IWOTH S_IWUSR
#define S_IXOTH S_IXUSR
#define S_ISUID 0
#define S_ISGID 0
#define S_ISVTX 0
#define S_ISLNK(x) 0
#endif

/*#include "__config.h"*/

#include "__oo2c.h"
#include "Directory.d"

void Directory__SetCwd(Object__String name)
{
  Object__CharsLatin1 tmp;

  tmp=OS_Path__Encode(name);

  if (chdir(tmp)!=0) {
    IO_StdChannels__IOError(NULL);
  }
}

OOC_BOOLEAN Directory__SplitDirFile(const OOC_CHAR8* path__ref, OOC_INT32 path_0d,
                                    OOC_CHAR8* dir, OOC_INT32 dir_0d,
                                    OOC_CHAR8* file, OOC_INT32 file_0d)
{
  struct stat info;
  int         len,pos;

  if (stat(path__ref,&info)==0) {
    if (S_ISDIR(info.st_mode)) {
      _copy_8(path__ref,dir,dir_0d);
      _copy_8("",file,file_0d);
    }
    else {
      len=Strings__Length(path__ref,path_0d);
      pos=len;
      while (pos>=0 && path__ref[pos]!='/') {
        --pos;
      }
      Strings__Extract(path__ref,path_0d,0,pos,dir,dir_0d);
      Strings__Extract(path__ref,path_0d,pos+1,len-pos,file,file_0d);
    }
    return 1;
  }
  else {
    return 0;
  }
}


OOC_BOOLEAN Directory__GetDetails(OOC_UINT32 attributes, Object__String name,
                                  struct Directory__DirEntryDesc *entry,
                                  RT0__Struct entry__tag)
{
  struct stat         info;
  Object__CharsLatin1 file;

  file=OS_Path__Encode(name);

  entry->attr=0;

#ifndef __MINGW32__
  /* lstat() and symbolic links don't exist under Win32 */
  if (attributes & (1<<Directory__link)) {
    if (lstat(file,&info)==0) {
      entry->link=S_ISLNK(info.st_mode);
    }
    else {
      entry->link=0;
    }
    entry->attr=entry->attr | Directory__link;
  }
#endif

  if (stat(file,&info)==0) {
    if (S_ISDIR(info.st_mode)) {
      entry->attr=entry->attr | Directory__type;
      entry->type=Directory__directory;
    }
    else if (S_ISLNK(info.st_mode)) {
      entry->attr=entry->attr | Directory__type;
      entry->type=Directory__link;
    }
    else {
      entry->attr=entry->attr | Directory__type;
      entry->type=Directory__normal;
    }
    entry->attr=entry->attr | Directory__size;
    entry->size=info.st_size;

    entry->user=0;
    if (info.st_mode & S_IRUSR) {
      entry->user=entry->user | 1<<Directory__rightRead;
    }
    if (info.st_mode & S_IWUSR) {
      entry->user=entry->user | 1<<Directory__rightWrite;
    }
    if (info.st_mode & S_IXUSR) {
      entry->user=entry->user | 1<<Directory__rightExecute;
    }

    entry->group=0;
    if (info.st_mode & S_IRGRP) {
      entry->group=entry->group | 1<<Directory__rightRead;
    }
    if (info.st_mode & S_IWGRP) {
      entry->group=entry->group | 1<<Directory__rightWrite;
    }
    if (info.st_mode & S_IXGRP) {
      entry->group=entry->group | 1<<Directory__rightExecute;
    }

    entry->other=0;
    if (info.st_mode & S_IROTH) {
      entry->other=entry->other | 1<<Directory__rightRead;
    }
    if (info.st_mode & S_IWOTH) {
      entry->other=entry->other | 1<<Directory__rightWrite;
    }
    if (info.st_mode & S_IXOTH) {
      entry->other=entry->other | 1<<Directory__rightExecute;
    }

    entry->special=0;
    if (info.st_mode & S_ISUID) {
      entry->special=entry->special | Directory__specialUID;
    }
    if (info.st_mode & S_ISGID) {
      entry->special=entry->special | Directory__specialGID;
    }
    if (info.st_mode & S_ISVTX) {
      entry->special=entry->special | Directory__specialSticky;
    }

    return 1;
  }
  else {
    return 0;
  }
}

void OOC_Directory_init(void) {
}
