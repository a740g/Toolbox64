//----------------------------------------------------------------------------------------------------------------------
// File, path and filesystem routines
// Copyright (c) 2023 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "Common.h"
#include <cstring>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

static DIR *pDir = nullptr;

qb_bool __OpenDirectory(const char *path)
{
  pDir = opendir(path);
  if (!pDir)
    return QB_FALSE;

  return QB_TRUE;
}

const char *GetDirectoryEntry(qb_bool *isDir, size_t *fileSize)
{
  static char dirName[4096]; // 4k static buffer

  dirName[0] = 0; // set to empty string

  auto next_entry = readdir(pDir);

  if (!next_entry)
    return dirName; // return an empty string to indicate we have nothing

  struct stat entry_info;
  stat(next_entry->d_name, &entry_info);

  *isDir = S_ISDIR(entry_info.st_mode) ? QB_TRUE : QB_FALSE;
  *fileSize = entry_info.st_size;

  strncpy(dirName, next_entry->d_name, sizeof(dirName));
  dirName[sizeof(dirName)] = 0; // overflow protection

  return dirName; // QB64-PE does the right thing with this
}

void CloseDirectory()
{
  closedir(pDir);
  pDir = nullptr;
}
