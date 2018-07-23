# APICv2018DevInstall

This is supplied with zero support and warrenty. If issues are raised I will endever to keep this up todate.


CephFs request you to have ` --feature-gates=ReadOnlyAPIDataVolumes=false` set in `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf ` if this setting is not set then the image will not deploy even if you dont want cephs

my `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf ` is below

```
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf  --feature-gates=ReadOnlyAPIDataVolumes=false"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/default/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
```

It will install on a single worker node.

You must have the following install with their dependencies

kubectl
kubeadm
helm


Download all the 2018.3.1 binaries to `fixcentral/3.1/`
configure the variables in the `./envfile`.
If you are unable to set entries in your DNS Server please look at the following blog post. https://medium.com/@cminion/deploying-api-connect-2018-for-a-pot-without-a-dns-server-18eaacb1d88e 

run `make all`


