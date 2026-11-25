package fdtunnel

import (
	"errors"
	"fmt"
	"os"

	"golang.org/x/sys/unix"
	"golang.zx2c4.com/wireguard/device"
	"golang.zx2c4.com/wireguard/tun"
	"splitway/tunnelcore/servicerouting"
	"splitway/tunnelcore/udpbind"
)

var (
	ErrTunnelInterfaceUnavailable = errors.New("tunnel interface unavailable")
	ErrConfigurationRejected      = errors.New("configuration rejected")
	ErrDeviceUnavailable          = errors.New("device unavailable")
	ErrServiceRoutingUnavailable  = errors.New("service routing unavailable")
)

const (
	tunnelInterfaceFileName = "utun"
	keepInterfaceMTU        = 0
)

type Tunnel struct {
	device      *device.Device
	translation *servicerouting.TranslatingDevice
}

func StartOnFileDescriptor(fileDescriptor int, configuration string, logger *device.Logger) (*Tunnel, error) {
	tunnelInterface, err := openTunnelInterface(fileDescriptor)
	if err != nil {
		return nil, err
	}
	return Start(tunnelInterface, configuration, logger)
}

func Start(tunnelInterface tun.Device, configuration string, logger *device.Logger) (*Tunnel, error) {
	if routesServicesOnThisPlatform {
		return StartRoutingServices(tunnelInterface, configuration, logger)
	}
	return start(tunnelInterface, nil, configuration, logger)
}

func StartRoutingServices(tunnelInterface tun.Device, configuration string, logger *device.Logger) (*Tunnel, error) {
	translation := servicerouting.NewTranslatingDevice(tunnelInterface)
	return start(translation, translation, configuration, logger)
}

func start(
	wireGuardInterface tun.Device,
	translation *servicerouting.TranslatingDevice,
	configuration string,
	logger *device.Logger,
) (*Tunnel, error) {
	wireGuardDevice := device.NewDevice(wireGuardInterface, udpbind.New(), logger)
	if err := wireGuardDevice.IpcSet(configuration); err != nil {
		wireGuardDevice.Close()
		return nil, fmt.Errorf("%w: %w", ErrConfigurationRejected, err)
	}
	if err := wireGuardDevice.Up(); err != nil {
		wireGuardDevice.Close()
		return nil, fmt.Errorf("%w: %w", ErrDeviceUnavailable, err)
	}
	return &Tunnel{device: wireGuardDevice, translation: translation}, nil
}

func (tunnel *Tunnel) Apply(configuration string) error {
	if err := tunnel.device.IpcSet(configuration); err != nil {
		return fmt.Errorf("%w: %w", ErrConfigurationRejected, err)
	}
	return nil
}

func (tunnel *Tunnel) RoutesServices() bool {
	return tunnel.translation != nil
}

func (tunnel *Tunnel) RouteServices(plan servicerouting.Plan) error {
	if tunnel.translation == nil {
		return ErrServiceRoutingUnavailable
	}
	if err := tunnel.translation.Apply(plan); err != nil {
		return fmt.Errorf("%w: %w", ErrConfigurationRejected, err)
	}
	return nil
}

func (tunnel *Tunnel) Configuration() (string, error) {
	return tunnel.device.IpcGet()
}

func (tunnel *Tunnel) BumpSockets() error {
	return tunnel.device.BindUpdate()
}

func (tunnel *Tunnel) Stop() {
	tunnel.device.Close()
}

func openTunnelInterface(fileDescriptor int) (tun.Device, error) {
	duplicate, err := unix.Dup(fileDescriptor)
	if err != nil {
		return nil, fmt.Errorf("%w: %w", ErrTunnelInterfaceUnavailable, err)
	}
	if err := unix.SetNonblock(duplicate, true); err != nil {
		unix.Close(duplicate)
		return nil, fmt.Errorf("%w: %w", ErrTunnelInterfaceUnavailable, err)
	}
	tunnelInterface, err := tun.CreateTUNFromFile(os.NewFile(uintptr(duplicate), tunnelInterfaceFileName), keepInterfaceMTU)
	if err != nil {
		return nil, fmt.Errorf("%w: %w", ErrTunnelInterfaceUnavailable, err)
	}
	return tunnelInterface, nil
}
