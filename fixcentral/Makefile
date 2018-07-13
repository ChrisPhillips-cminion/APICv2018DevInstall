apicupLoc = `which apicup`
apicLoc = `which apic`

all: install upload

clean:
	list=$(sudo docker images | grep pic | sed  s/\ \ */\ /g | cut -d ' ' -f 3)
	sudo kubeadm reset
	echo $(list);
	sudo docker rmi -f $(list) || true 


install:
	sudo cp $(ver)/apicup-* $(apicupLoc)
	sudo cp $(ver)/apic-* $(apicLoc)

	rm -rf versionToInstall || true
	ln -sf $(ver) versionToInstall

	sudo chmod 755 $(apicLoc) $(apiuUpLoc)


upload: 
	sudo apicup registry-upload management $(ver)/management-images* localhost:5000 --debug
	sudo apicup registry-upload analytics $(ver)/analytics-images* localhost:5000 --debug
	sudo apicup registry-upload portal $(ver)/portal-images* localhost:5000 --debug
# done
