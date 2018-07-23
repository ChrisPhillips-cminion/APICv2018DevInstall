ssh $1  sudo $(cat kubeinit.log | grep kubeadm | tail -n1 )
#scp -r ~/.kube $1:.

