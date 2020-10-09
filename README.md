# pi-cluster-workshop

## Enable OpenWRT tftp server

add these lines to `/etc/config/dhcp'

```text
config dnsmasq
	option enable_tftp '1'
	option tftp_root '/tmp/tftp'
```

## Overlay network notes

`cni0` is the interface on the Pi connected to the flannel overlay network

Wireshark can decode the vxlan that makes up flannel with [this lua plugin](https://github.com/C-h4ck-0/Flannel-VXLAN-Wireshark-parser). 

Overlay network for k3s is [Flannel](https://github.com/coreos/flannel)

## Networking Extension Thoughts

Look at Keepalived for HA ingress between all the worker nodes

## Start up notes

This [blog](https://kauri.io/build-your-very-own-self-hosting-platform-with-raspberry-pi-and-kubernetes/5e1c3fdc1add0d0001dff534/c) 
has some interesting ideas about using metallb for the LB and nginx ingress