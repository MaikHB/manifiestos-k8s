#!/bin/bash

set -e  # Salir ante cualquier error

# 1. Verificar herramientas necesarias
for cmd in git minikube kubectl; do
  if ! command -v $cmd &> /dev/null; then
    echo "❌ '$cmd' no está instalado. Instálalo para continuar."
    exit 1
  fi
done

# 2. Definir rutas y repositorios
WIN_BASE_DIR="$HOME/Desktop/proyecto-k8s"
WEB_REPO="https://github.com/ewojjowe/static-website"
WEB_FOLDER="sitio-web"
K8S_FOLDER="k8s-manifests"
LINUX_MOUNT_PATH="/mnt/sitio-web"

# 3. Convertir rutas a formato Linux válido si es Git Bash
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  BASE_DIR=$(cygpath -u "$WIN_BASE_DIR")
  MOUNT_SRC=$(cygpath -w "$WIN_BASE_DIR/$WEB_FOLDER" | sed 's/\\\\/\\/')
  MOUNT_STRING="$MOUNT_SRC:$LINUX_MOUNT_PATH"
else
  BASE_DIR="$WIN_BASE_DIR"
  MOUNT_STRING="$BASE_DIR/$WEB_FOLDER:$LINUX_MOUNT_PATH"
fi

# 4. Crear estructura del proyecto
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# 5. Clonar repositorio del sitio web si no existe
if [ ! -d "$WEB_FOLDER" ]; then
  git clone "$WEB_REPO" "$WEB_FOLDER"
else
  echo "📂 El repositorio web ya existe, omitiendo clonación..."
fi

# 6. Crear estructura para manifiestos
mkdir -p "$K8S_FOLDER"/{deployment,service,pvc}

# 7. Crear manifiestos YAML
cat <<EOF > "$K8S_FOLDER/pvc/pvc.yaml"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

cat <<EOF > "$K8S_FOLDER/deployment/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx
          ports:
            - containerPort: 80
          volumeMounts:
            - name: content
              mountPath: /usr/share/nginx/html
      volumes:
        - name: content
          hostPath:
            path: $LINUX_MOUNT_PATH
            type: Directory
EOF

cat <<EOF > "$K8S_FOLDER/service/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF

# 8. Borrar cluster previo y levantar Minikube con montaje
minikube delete
minikube start --driver=docker --mount --mount-string="$MOUNT_STRING"

# 9. Aplicar manifiestos
kubectl apply -f "$K8S_FOLDER/pvc"
kubectl apply -f "$K8S_FOLDER/deployment"
kubectl apply -f "$K8S_FOLDER/service"

# 10. Esperar pod
kubectl wait --for=condition=ready pod -l app=web --timeout=60s

# 11. Verificaciones
kubectl get pods
kubectl get pv,pvc
kubectl exec -it "$(kubectl get pod -l app=web -o jsonpath='{.items[0].metadata.name}')" -- sh -c "ls /usr/share/nginx/html"

# 12. Mostrar URL del sitio
minikube service web-service
