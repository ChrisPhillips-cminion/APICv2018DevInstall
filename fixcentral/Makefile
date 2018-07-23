apicupLoc = `which apicup ||  echo '/usr/bin/apicup'`
apicLoc = `which apic || echo '/usr/bin/apic'`

all: install upload

clean:
	list=$(sudo docker images | grep pic | sed  s/\ \ */\ /g | cut -d ' ' -f 3)
	sudo kubeadm reset
	echo $(list);
	sudo docker rmi -f $(list) || true 


install:
	sudo cp $(ver)/apicup-* $(apicupLoc)
	#sudo cp $(ver)/apic-* $(apicLoc)

	rm -rf versionToInstall || true
	ln -sf $(ver) versionToInstall

	#sudo chmod 755 $(apicLoc) 
	sudo chmod 755 $(apicupLoc)


upload: 
	sudo apicup registry-upload management $(ver)/management-images* px-chrisp1:5000 --debug
	sudo apicup registry-upload analytics $(ver)/analytics-images* px-chrisp1:5000 --debug
	sudo apicup registry-upload portal $(ver)/portal-images* px-chrisp1:5000 --debug
# done
