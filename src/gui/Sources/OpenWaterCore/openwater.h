#ifndef openwater_core_h
#define openwater_core_h

#include <stdint.h>

// #ifdef __cplusplus
// extern "C" {
// #endif

#if defined(WIN32)
    #define EXPORT __declspec(dllexport)
#else
    #define EXPORT
#endif

EXPORT const char* openwater_init(void);
// EXPORT void free_string(char* s);

// #ifdef __cplusplus
// }
// #endif

#endif /* openwater_core_h */
