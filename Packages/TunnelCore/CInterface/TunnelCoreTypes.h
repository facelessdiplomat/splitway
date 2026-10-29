#ifndef TUNNEL_CORE_TYPES_H
#define TUNNEL_CORE_TYPES_H

#include <stdint.h>

typedef enum __attribute__((enum_extensibility(closed))) TCStatus : int32_t {
    TCStatusOK = 0,
    TCStatusInvalidArgument = 1,
    TCStatusUnknownHandle = 2,
    TCStatusTunnelInterfaceUnavailable = 3,
    TCStatusConfigurationRejected = 4,
    TCStatusDeviceUnavailable = 5,
    TCStatusInternalFailure = 6,
} TCStatus;

typedef enum __attribute__((enum_extensibility(closed))) TCLogLevel : int32_t {
    TCLogLevelVerbose = 0,
    TCLogLevelError = 1,
} TCLogLevel;

typedef void (*TCLogCallback)(void *_Nullable context, TCLogLevel level, const char *_Nonnull message);

#endif
