include envfile
pre:
	sudo sysctl -w vm.max_map_count=262144
	sudo swapoff -a # Kubernetes won't 	with swap enabled.	This is the Ubuntu method of disabling

clean: pre
	rm -rf tmpo
	sudo kubeadm reset --force
	ssh $(workerNode) sudo kubeadm reset --force 
	ssh $(workerNode) sudo rm -rf /var/lib/rook/
	ssh $(workerNode) sudo rm -rf /var/kubernetes
	ssh $(workerNode2) sudo kubeadm reset --force 
	ssh $(workerNode2) sudo rm -rf /var/lib/rook/
	ssh $(workerNode2) sudo rm -rf /var/kubernetes
	sudo rm -rf ~/.kube
	sudo rm -rf ~/.helm
	sudo rm -rf /var/kubernetes
	sudo rm -rf /var/lib/rook/
	rm -rf myinstall || true

rookInstall:
	kubectl delete namespace rook || true
	kubectl create namespace rook 
	ssh $(workerNode) sudo rm -rf /var/lib/rook
	ssh $(workerNode2) sudo rm -rf /var/lib/rook
	sudo rm -rf /var/lib/rook/
	helm repo add rook-alpha https://charts.rook.io/alpha
	helm install rook-alpha/rook --name rook --namespace rook
	kubectl apply -f yaml/rook-storageclass.yml
	kubectl apply -f yaml/rook-toolbox.yaml
	echo Waiting for rook to start
	sleep 60s && kubectl apply -f yaml/pvcTest.yaml 

addNodes:
	sh bin/createWorker.sh $(workerNode)
	sh bin/createWorker.sh $(workerNode2)
	cd bin/ && sudo bash haK8s.sh


buildK8s: clean pre
	#--kubernetes-version=1.10.2
	sudo kubeadm init --pod-network-cidr 192.168.0.0/16 | tee kubeinit.log #--kubernetes-version=1.10.2   | tee kubeinit.log
	mkdir -p ~/.kube
	sudo cp -f /etc/kubernetes/admin.conf ~/.kube/config
	sudo chmod 755 -R  ~/.kube/
	kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
	kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
	kubectl taint nodes --all node-role.kubernetes.io/master-

helm:
	kubectl apply -f yaml/tiller-rbac.yml
	helm init
	echo "Waiting for tiller to start in cluster"
	sleep 60
	kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

ingress: 
	helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
	helm install --name ingress -f yaml/nginx-ingress-values.yml stable/nginx-ingress
registry:
	helm install --name registry stable/docker-registry  -f yaml/registry-values.yaml 
	kubectl apply -f yaml/docker-registry-service.yaml
	sleep 10s
	sh bin/setupPfRegistry.sh

installDep: pre
	sudo dpkg --install kubeadm*/*deb
	sudo apt-get install -y ceph-fs-common ceph-common

loadDep: 
	sudo docker pull ibmcom/datapower
	sudo docker tag ibmcom/datapower:latest px-chrisp1:5000/ibmcom/datapower:latest
	sudo docker push px-chrisp1:5000/ibmcom/datapower:latest
	$(MAKE) -C fixcentral/ install upload ver=$(ver)


loadDepClean: clean
	cd fixcentral
	$(MAKE) -C fixcentral/ clean ver=$(ver)


prep: pre clean buildK8s addNodes helm ingress rookInstall registry 


buildYaml:
	rm -rf myinstall || true
	apicup init myinstall
	cd ./myinstall ; apicup subsys create mgmt management --k8s ;
	cd ./myinstall ; apicup endpoints set mgmt platform-api   $(ep_api) ;
	cd ./myinstall ; apicup endpoints set mgmt api-manager-ui $(ep_apim)  ;
	cd ./myinstall ; apicup endpoints set mgmt cloud-admin-ui $(ep_cm)  ;
	cd ./myinstall ; apicup endpoints set mgmt consumer-api $(ep_consumer) ;
	cd ./myinstall ; apicup subsys set mgmt registry-secret apiconnect-image-pull-secret ;
	cd ./myinstall ; apicup subsys set mgmt storage-class rook-block ;
	cd ./myinstall ; apicup subsys set mgmt namespace $(NAMESPACE) ;
	cd ./myinstall ; apicup subsys set mgmt cassandra-cluster-size 1 ;
	cd ./myinstall ; apicup subsys set mgmt cassandra-max-memory-gb 2 ;
	cd ./myinstall ; apicup subsys set mgmt cassandra-volume-size-gb 50 ;
	cd ./myinstall ; apicup subsys set mgmt create-crd "true" ;
	cd ./myinstall ; apicup subsys set mgmt enable-persistence "true" ;
	cd ./myinstall ; apicup subsys create gw gateway --k8s ;
	cd ./myinstall ; apicup endpoints set gw api-gateway $(ep_gw)
	cd ./myinstall ; apicup endpoints set gw apic-gw-service $(ep_gwd) 
	cd ./myinstall ; apicup subsys set gw namespace $(NAMESPACE) ;
	cd ./myinstall ; apicup subsys set gw max-cpu 2 ;
	cd ./myinstall ; apicup subsys set gw max-memory-gb 4 ;
	cd ./myinstall ; apicup subsys set gw replica-count 3 ;
	cd ./myinstall ; apicup subsys create analytics analytics --k8s ;
	cd ./myinstall ; apicup subsys set analytics namespace $(NAMESPACE) ;
	cd ./myinstall ; apicup subsys set analytics coordinating-max-memory-gb 6 ;
	cd ./myinstall ; apicup subsys set analytics data-max-memory-gb 2 ;
	cd ./myinstall ; apicup subsys set analytics data-storage-size-gb 10 ;
	cd ./myinstall ; apicup subsys set analytics master-max-memory-gb 2 ;
	cd ./myinstall ; apicup subsys set analytics master-storage-size-gb 1 ;
	cd ./myinstall ; apicup subsys set analytics storage-class rook-block  ;
	cd ./myinstall ; apicup endpoints set analytics analytics-ingestion $(ep_ai) ;
	cd ./myinstall ; apicup endpoints set analytics analytics-client $(ep_ac) ;
	cd ./myinstall ; apicup subsys create portal portal --k8s ;
	cd ./myinstall ; apicup endpoints set portal portal-admin $(ep_padmin) ;
	cd ./myinstall ; apicup endpoints set portal portal-www $(ep_portal) ;
	cd ./myinstall ; apicup subsys set portal namespace $(NAMESPACE) ;
	cd ./myinstall ; apicup subsys set portal registry px-chrisp1:5000
	cd ./myinstall ; apicup subsys set portal registry-secret apiconnect-image-pull-secret ;
	cd ./myinstall ; apicup subsys set mgmt registry px-chrisp1:5000
	cd ./myinstall ; apicup subsys set mgmt registry-secret apiconnect-image-pull-secret ;
	cd ./myinstall ; apicup subsys set analytics registry px-chrisp1:5000
	cd ./myinstall ; apicup subsys set gw image-repository px-chrisp1:5000/ibmcom/datapower
	cd ./myinstall ; apicup subsys set gw image-tag "latest"
#	cd ./myinstall ; apicup subsys set gw registry px-chrisp1:5000
#	cd ./myinstall ; apicup subsys set gw registry-secret apiconnect-image-pull-secret ;
#	cd ./myinstall ; apicup subsys set gw mode demo
	cd ./myinstall ; apicup subsys set analytics registry-secret apiconnect-image-pull-secret ;
#	cd ./myinstall ; apicup subsys set mgmt mode demo
#	cd ./myinstall ; apicup subsys set portal mode demo
#	cd ./myinstall ; apicup subsys set analytics mode demo
	cd myinstall  ; apicup subsys install mgmt
	cd myinstall ; apicup subsys install gw
	cd myinstall ; apicup subsys install analytics
	cd myinstall ; apicup subsys install portal
configureAPIC:
	sh bin/changepassword.sh $(ep_cm) $(admin_email) $(admin_pass)
	sh envfile && sh bin/createDpService.sh 

all: prep loadDep  buildYaml configureAPIingress C
