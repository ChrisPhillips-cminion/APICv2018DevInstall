include envfile
pre:
	sudo sysctl -w vm.max_map_count=262144
	sudo swapoff -a # Kubernetes won't 	with swap enabled.	This is the Ubuntu method of disabling

clean: pre
	rm -rf tmpo
	sudo kubeadm reset
	sudo rm -rf ~/.kube
	sudo rm -rf ~/.helm
	sudo rm -rf /var/kubernetes
	rm -rf myinstall || true

buildK8s: clean pre
	sudo kubeadm init --apiserver-advertise-address=0.0.0.0 --pod-network-cidr=172.17.0.0/16
	mkdir -p $(HOME)/.kube
	sudo cp -f /etc/kubernetes/admin.conf $(HOME)/.kube/config
	sudo chown  $(USER) $(HOME)/.kube/config
	kubectl apply -f yaml/calico.yaml
	kubectl taint nodes --all node-role.kubernetes.io/master-
	#kubectl apply -f yaml/registry.yml && sleep 100 &
	helm init
	echo "Waiting for tiller to start in cluster"
	sleep 60
	kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
	kubectl create -f yaml/storage-rbac.yaml
	kubectl create -f yaml/hostpath-provisioner.yaml
	kubectl create -f yaml/StorageClass.yaml
	helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
	helm install --name registry stable/docker-registry
	sleep 30s
	sh bin/setupPfRegistry.sh
	helm install --name ingress -f yaml/nginx-ingress-values.yml stable/nginx-ingress
	wait
installDep: pre
	sudo dpkg --install kubeadm*/*deb

loadDep: 
	sudo docker pull ibmcom/datapower
	sudo docker tag ibmcom/datapower:latest localhost:5000/apiconnect/datapower-api-gateway:7.7.1.1-300826-release
	sudo docker push localhost:5000/apiconnect/datapower-api-gateway:7.7.1.1-300826-release
	$(MAKE) -C fixcentral/ install upload ver=$(ver)


loadDepClean: clean
	cd fixcentral
	$(MAKE) -C fixcentral/ clean ver=$(ver)


prep: pre clean buildK8s loadDep 

buildYaml:
	rm -rf myinstall || true
	apicup init myinstall
	cd ./myinstall ; apicup subsys create mgmt management --k8s ;
	cd ./myinstall ; apicup endpoints set mgmt platform-api   $(ep_api) ;
	cd ./myinstall ; apicup endpoints set mgmt api-manager-ui $(ep_apim)  ;
	cd ./myinstall ; apicup endpoints set mgmt cloud-admin-ui $(ep_cm)  ;
	cd ./myinstall ; apicup endpoints set mgmt consumer-api $(ep_consumer) ;
	cd ./myinstall ; apicup subsys set mgmt registry-secret apiconnect-image-pull-secret ;
	cd ./myinstall ; apicup subsys set mgmt storage-class velox-block ;
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
	cd ./myinstall ; apicup subsys set analytics storage-class velox-block  ;
	cd ./myinstall ; apicup endpoints set analytics analytics-ingestion $(ep_ai) ;
	cd ./myinstall ; apicup endpoints set analytics analytics-client $(ep_ac) ;
	cd ./myinstall ; apicup subsys create portal portal --k8s ;
	cd ./myinstall ; apicup endpoints set portal portal-admin $(ep_padmin) ;
	cd ./myinstall ; apicup endpoints set portal portal-www $(ep_portal) ;
	cd ./myinstall ; apicup subsys set portal namespace $(NAMESPACE) ;
	cd ./myinstall ; apicup subsys set portal registry localhost:5000
	cd ./myinstall ; apicup subsys set portal registry-secret apiconnect-image-pull-secret ;
	cd ./myinstall ; apicup subsys set mgmt registry localhost:5000
	cd ./myinstall ; apicup subsys set mgmt registry-secret apiconnect-image-pull-secret ;
	cd ./myinstall ; apicup subsys set analytics registry localhost:5000
#	cd ./myinstall ; apicup subsys set gw image-repository ibmcom/datapower
#	cd ./myinstall ; apicup subsys set gw image-tag "7.7.1.1.300826"
	cd ./myinstall ; apicup subsys set gw registry localhost:5000
	cd ./myinstall ; apicup subsys set gw registry-secret apiconnect-image-pull-secret ;
	cd ./myinstall ; apicup subsys set gw mode demo
	cd ./myinstall ; apicup subsys set analytics registry-secret apiconnect-image-pull-secret ;
	cd ./myinstall ; apicup subsys set mgmt mode demo
	cd ./myinstall ; apicup subsys set portal mode demo
	cd ./myinstall ; apicup subsys set analytics mode demo
	cd myinstall  ; apicup subsys install mgmt
	cd myinstall ; apicup subsys install gw
	cd myinstall ; apicup subsys install analytics
	cd myinstall ; apicup subsys install portal
configureAPIC:
	sh bin/changepassword.sh $(ep_cm) $(admin_email) $(admin_pass)
	sh envfile && sh bin/createDpService.sh 


all: prep buildYaml configureAPIC
