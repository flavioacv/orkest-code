#ifndef ORKEST_GPU_ENVIRONMENT_H_
#define ORKEST_GPU_ENVIRONMENT_H_

#include <string>

// Applies Orkest's process-local hybrid GPU policy before GTK/EGL starts.
// Returns a content-free description suitable for the startup log.
std::string configure_linux_gpu_environment();

#endif  // ORKEST_GPU_ENVIRONMENT_H_
