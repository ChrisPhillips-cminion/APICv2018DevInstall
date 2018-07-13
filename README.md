# APICv2018DevInstall

This is supplied with zero support and warrenty. If issues are raised I will endever to keep this up todate.

It will install on a single worker node.

You must have the following install with their dependencies

kubectl
kubeadm
helm


Download all the 2018.3.1 binaries to `fixcentral/3.1/`
configure the endpoints in the `./envfile`. Ifyou are unable to set entries in your DNS Server please look at the following blog post. https://medium.com/@cminion/deploying-api-connect-2018-for-a-pot-without-a-dns-server-18eaacb1d88e 
run `make all`

