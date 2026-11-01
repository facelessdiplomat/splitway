#ifndef TUNNEL_CORE_H
#define TUNNEL_CORE_H

#include <stdint.h>
#include "TunnelCoreTypes.h"

char *_Nonnull tc_version(void);
void tc_free(void *_Nullable pointer);

TCStatus tc_fd_tunnel_start(int32_t tunnelFileDescriptor, const char *_Nonnull configuration, int32_t *_Nonnull handle);
TCStatus tc_fd_tunnel_set_service_routing(int32_t handle, const char *_Nonnull plan);
TCStatus tc_tunnel_update_config(int32_t handle, const char *_Nonnull configuration);
TCStatus tc_tunnel_get_config(int32_t handle, char *_Nullable *_Nonnull configuration);
TCStatus tc_tunnel_bump_sockets(int32_t handle);
TCStatus tc_tunnel_stop(int32_t handle);
void tc_set_log_callback(TCLogCallback _Nullable callback, void *_Nullable context);

TCStatus tc_usernet_start(const char *_Nonnull configuration, const char *_Nonnull addresses, const char *_Nonnull dnsServers, int32_t mtu, int32_t *_Nonnull handle);
TCStatus tc_usernet_dial_tcp(int32_t network, const char *_Nonnull address, uint16_t port, int32_t timeoutMilliseconds, int32_t *_Nonnull connection);
TCStatus tc_usernet_dial_udp(int32_t network, const char *_Nonnull address, uint16_t port, int32_t *_Nonnull connection);
TCStatus tc_usernet_lookup_host(int32_t network, const char *_Nonnull name, int32_t timeoutMilliseconds, char *_Nullable *_Nonnull addresses);

TCStatus tc_connection_start_receiving(int32_t connection, TCConnectionCallbacks callbacks, int32_t readByteCount, int32_t initialCredit);
TCStatus tc_connection_write(int32_t connection, const uint8_t *_Nonnull bytes, int32_t length, int32_t *_Nonnull writtenLength);
TCStatus tc_connection_grant(int32_t connection, int32_t byteCount);
TCStatus tc_connection_close(int32_t connection, TCConnectionClosing closing);

#endif
