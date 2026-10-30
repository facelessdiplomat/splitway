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
    TCStatusConnectionFailed = 7,
    TCStatusTimedOut = 8,
    TCStatusLookupFailed = 9,
    TCStatusNetworkStopped = 10,
    TCStatusConnectionClosed = 11,
} TCStatus;

typedef enum __attribute__((enum_extensibility(closed))) TCConnectionClosing : int32_t {
    TCConnectionClosingWrite = 0,
    TCConnectionClosingRead = 1,
    TCConnectionClosingBoth = 2,
} TCConnectionClosing;

typedef enum __attribute__((enum_extensibility(closed))) TCLogLevel : int32_t {
    TCLogLevelVerbose = 0,
    TCLogLevelError = 1,
} TCLogLevel;

typedef void (*TCLogCallback)(void *_Nullable context, TCLogLevel level, const char *_Nonnull message);

typedef void (*TCConnectionReceiveCallback)(void *_Nullable context, const uint8_t *_Nonnull bytes, int32_t length);
typedef void (*TCConnectionFinishCallback)(void *_Nullable context, TCStatus status);

typedef struct TCConnectionCallbacks {
    TCConnectionReceiveCallback _Nonnull receive;
    TCConnectionFinishCallback _Nonnull finish;
    void *_Nullable context;
} TCConnectionCallbacks;

#endif
