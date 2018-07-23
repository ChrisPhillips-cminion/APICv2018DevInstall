cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true
Restart=always
EOF

systemctl daemon-reload
systemctl restart kubelet

# Update HOST0, HOST1, and HOST2 with the IPs or resolvable names of your hosts
export HOST0=10.218.200.11
export HOST1=10.218.200.12
export HOST2=10.218.200.13

# Create temp directories to store files that will end up on other hosts.
mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/

ETCDHOSTS=(${HOST0} ${HOST1} ${HOST2})
NAMES=("infra0" "infra1" "infra2")

for i in "${!ETCDHOSTS[@]}"; do
HOST=${ETCDHOSTS[$i]}
NAME=${NAMES[$i]}
cat << EOF > /tmp/${HOST}/kubeadmcfg.yaml
apiVersion: "kubeadm.k8s.io/v1alpha2"
kind: MasterConfiguration
etcd:
    localEtcd:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
            initial-cluster: infra0=https://${ETCDHOSTS[0]}:2380,infra1=https://${ETCDHOSTS[1]}:2380,infra2=https://${ETCDHOSTS[2]}:2380
            initial-cluster-state: new
            name: ${NAME}
            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380
EOF
done




kubeadm alpha phase certs etcd-ca

kubeadm alpha phase certs etcd-server --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-peer --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm alpha phase certs apiserver-etcd-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST2}/
# cleanup non-reusable certificates
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm alpha phase certs etcd-server --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-peer --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm alpha phase certs apiserver-etcd-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST1}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm alpha phase certs etcd-server --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-peer --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm alpha phase certs apiserver-etcd-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
# No need to move the certs because they are for HOST0

# clean up certs that should not be copied off this host
sudo find /tmp/${HOST2} -name ca.key -type f -delete
sudo find /tmp/${HOST1} -name ca.key -type f -delete

user=chrisp
ssh $user@${HOST1} sudo rm -rf ha && scp -r /tmp/${HOST1}/ $user@${HOST1}:ha && ssh $user@${HOST1} sudo chown -R root:root ha/pki && ssh $user@${HOST1} sudo cp -rf  ha/pki/* /etc/kubernetes/pki/
ssh $user@${HOST2} sudo rm -rf ha  &&  scp -r /tmp/${HOST2}/ $user@${HOST2}:ha && ssh $user@${HOST2} sudo chown -R root:root ha/pki && ssh $user@${HOST2} sudo cp -rf  ha/pki/* /etc/kubernetes/pki/


kubeadm alpha phase etcd local --config=/tmp/${HOST0}/kubeadmcfg.yaml
ssh $user@${HOST1} sudo kubeadm alpha phase etcd local --config=/home/chrisp/ha/kubeadmcfg.yaml
ssh $user@${HOST2} sudo kubeadm alpha phase etcd local --config=/home/chrisp/ha/kubeadmcfg.yaml
