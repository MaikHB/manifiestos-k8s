
# **Tabla de contenido**

[TOC]

# Despliegue de sitio web estático en Minikube con Kubernetes

### Estructura del proyecto 🧱 

```sql
📁 web-static/              ← Repositorio del sitio web
   ├── 📄 index.html 
   ├── 📄 styles.css 
   ├── 📄 script.js 
   ├── 📁 assets/ 
   ├── 📄 README.md 
   └── 📄 .git                 ← Repositorio Git local
```
```sql
📁 k8s-manifests/          ← Repositorio con manifiestos de Kubernetes 
   ├── 📁 deployments/
              └── deployment.yaml 
   ├── 📁 services/
              └── service.yaml 
   ├── 📁 volumes/
              ├── pv.yaml 
              └── pvc.yaml 
   ├── 📄 README.md 
   └── 📄 .git                 ← Repositorio Git local
```

## Requisitos 🧰

- Docker Desktop
- Minikube
- kubectl
- Git

## Pasos🚀

##### 1. Crear los repositorio "sitio web"

   ```bash
mkdir sitio-web
cd sitio-web
```

##### 2. Clonar los repositorios

```bash
git clone https://github.com/ewojjowe/static-website .
```

##### 3. Crear los repositorio "manifiestos-k8s"

```bash
mkdir k8s-manifiestos
cd k8s-manifiestos
```

##### 4. Crear estructura organizada📥
```bash
mkdir deployment
mkdir service
mkdir pvc
```

##### 5. Crear manifiestos Kubernetes📦

###### 5.1 Crear un volumen persistente

pvc/pvc.yaml
```yaml
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
```

###### 5.2 Crear un deployment con nginx

deployment/nginx-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
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
          image: nginx:latest
          ports:
            - containerPort: 80
          volumeMounts:
            - name: web-content
              mountPath: /usr/share/nginx/html
      volumes:
        - name: web-content
          hostPath:
              path: /mnt/sitio-web/static-website  # Ruta exacta donde están tus archivos
              type: Directory
```

###### 5.2 Crear el service

service/web-service.yaml
```yaml
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
```

##### 6. Iniciar Minikube con Docker montar el contenido🛠️

```bash
minikube start --driver=docker --mount --mount-string="PATH_A_TU_PROYECTO\sitio-web:/mnt/sitio-web"
```
>💡Reemplaza **PATH_A_TU_PROYECTO** por la ruta completa a tu carpeta sitio-web

##### 7. Aplicar los manifiestos🧪

###### 7.1 Navega al directorio correcto

```bash
cd PATH_A_TU_PROYECTO\manifiestos-k8s
```
>💡Reemplaza **PATH_A_TU_PROYECTO** por la ruta completa a tu carpeta manifiestos-k8s

###### 7.2  Verifica el contenido de los directorios

```bash
ls pvc
ls deployment
ls service
```
###### 7.3 Aplicar todos los manifiestos para cada directorio

```bash
kubectl apply -f pvc/
kubectl apply -f deployment/
kubectl apply -f service/
```

##### 8. Verificar estado de pods y volúmenes 🔍

###### 8.1 Verificamos si aparecen los archivos (HTML,CSS,etc) de la carpeta donde se encuentra alojado el FRONT

```bash
minikube ssh -- ls /mnt/sitio-web/static-website
```
Si ves el index.html entonces puedes salir
```bash
exit
```

###### 8.2 Verificar que el estado del pod sea Running

```bash
kubectl get pods
kubectl exec -it <pod-name> -- ls /usr/share/nginx/html
```

>💡Reemplaza** POD-NAME** por el nombre del pod creado

###### 8.3 Verificar que el estado del pv y pvc sea Bound

```bash
kubectl get pv,pvc
```

##### 9. Obtener URL🌐

###### 9.1 Url Local

```bash
minikube service web-service --url
```

###### 9.2 Url web

```bash
minikube service web-service
```

# Michael.md
