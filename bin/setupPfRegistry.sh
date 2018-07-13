export POD_NAME=$(kubectl get pods --namespace default -l "app=docker-registry,release=registry" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 5000:5000 & 
