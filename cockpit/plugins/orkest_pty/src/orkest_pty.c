#include "orkest_pty.h"

#include "include/dart_api_dl.c"

#if _WIN32
#include "orkest_pty_win.c"
#else
#include "forkpty.c"
#include "orkest_pty_unix.c"
#endif