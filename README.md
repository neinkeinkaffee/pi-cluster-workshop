# pi-cluster-workshop

## Enable OpenWRT tftp server

add these lines to `/etc/config/dhcp'

```text
config dnsmasq
	option enable_tftp '1'
	option tftp_root '/tmp/tftp'
```