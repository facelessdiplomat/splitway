#ifndef TUNNEL_CORE_H
#define TUNNEL_CORE_H

#include <stdint.h>
#include "TunnelCoreTypes.h"

char *_Nonnull tc_version(void);
void tc_free(void *_Nullable pointer);

TCStatus tc_fd_tunnel_start(int32_t tunnelFileDescriptor, const char *_Nonnull configuration, int32_t *_Nonnull handle);
TCStatus tc_tunnel_update_config(int32_t handle, const char *_Nonnull configuration);
TCStatus tc_tunnel_get_config(int32_t handle, char *_Nullable *_Nonnull configuration);
TCStatus tc_tunnel_bump_sockets(int32_t handle);
TCStatus tc_tunnel_stop(int32_t handle);
void tc_set_log_callback(TCLogCallback _Nullable callback, void *_Nullable context);

#endif
