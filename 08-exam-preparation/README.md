Create two repos in Gitea and push local ones 'exam-app' and 'exam-infra'

1. Login VSCode
http://IP:18000 

2. Execute commands from README.md
- Check Dockerfiles (may not be completed or may have errors)!
- Check the app http://IP:10002
- Check the status on http://IP:10001/status
- Check the metrics on http://IP:10001/metrics

3. Create metrics

- Build the Backend image again after changes!
```sh
docker build -t notes-be .
docker container rm --force notes-be
docker container run -d --name notes-be -p 10001:5000 -e REDIS_HOST=notes-db --net notes-app notes-be
```
- Test the metrics endpoint for newly created metrics
http://IP:10001/metrics

- Delete the tested app
```sh
docker container rm --force notes-fe notes-be notes-db
docker network rm notes-app
```

4. Separate the repositories
- Copy the local repo to the new local app repo
```sh
cp -Rv exam-notes/{services,images,README.md} exam-app/
```
- Create app repo in Gitea http://IP:3000 
[!note] Use local gitea IP address instead of public

5. Create Helm chart
exam-infra
 - charts
	- exam-app
		- templates
		
- Create `exam-infra/charts/exam-app/Chart.yaml`
- Create `exam-infra/charts/exam-app/values.yaml`

- Create manifests `exam-infra/charts/exam-app/templates/backend.yaml`
- Create manifests `exam-infra/charts/exam-app/templates/database.yaml`
- Create manifests for ConfigMap `exam-infra/charts/exam-app/templates/frontend-cm.yaml`
- Create manifests `exam-infra/charts/exam-app/templates/frontend.yaml`

- Registry commands
```sh
curl http://IP:5000/v2/_catalog
```

- Tag and push the be and fe images to local Docker registry
```sh
docker tag notes-be:latest 192.168.56.12:5000/notes-be:latest
docker tag notes-fe:latest 192.168.56.12:5000/notes-fe:lates
```

[!note] - We have a problem, there no images for be and fe in our local Docker registry!
```sh
sudo vi /etc/docker/daemon.json 
# replace with local Docker registry IP address! Restart docker service!
```

- Push the images
```sh
docker push 192.168.56.12:5000/notes-be:latest
docker push 192.168.56.12:5000/notes-fe:latest
```

- Test the heml chart
```sh
cd /home/vagrant/exam-infra
helm upgrade --install test ./charts/exam-app/
helm list

kubectl get all 
```
- Prepare passwords
```sh
echo "Parolka-12345" | base64
echo "requirepass Parolka-12345" | base64
```
- Create in `exam-notes` secret manifest
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
data:
  cli-password: UGFyb2xrYS0xMjM0NQo=
  srv-password: cmVxdWlyZXBhc3MgUGFyb2xrYS0xMjM0NQo=
```
- Convert the Secret manifest to Sealed Secret manifest
```sh
kubeseal --format yaml --scope cluster-wide < ~/exam-notes/db-secret.yaml > ~/exam-infra/charts/exam-app/templates/secret.yaml
```
- Move passwords to values.yaml file. Change the key form dash to underscore!
- Make parameterization
```yaml
---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  annotations:
    sealedsecrets.bitnami.com/cluster-wide: "true"
  name: {{ .Release.Name }}-db-secret
spec:
  encryptedData:
    CLI_PASSWORD: {{ .Values.secrets.cli_password }}
    SRV_PASSWORD: {{ .Values.secrets.srv_password }}
  template:
    metadata:
      annotations:
        sealedsecrets.bitnami.com/cluster-wide: "true"
      name: {{ .Release.Name }}-db-secret
    type: Opaque
```
- Add password requirement in `database.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ .Release.Name }}-db
  labels:
    app: {{ .Release.Name }}-notes
    service: db
spec:
  containers:
  - name: db
    image: redis:8.4.0-alpine
    command:
      - redis-server
      - "/redis-config/redis.conf"
    ports:
    - containerPort: 6379
    volumeMounts:
    - mountPath: /redis-config
      name: config
  volumes:
    - name: config
      secret:
        secretName: "{{ .Release.Name }}-db-secret"
        items:
        - key: SRV_PASSWORD
          path: redis.conf
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-db
spec:
  selector:
    app: {{ .Release.Name }}-notes
    service: db
  ports:
    - protocol: TCP
      port: 6379
      targetPort: 6379
  type: ClusterIP

```
- Add password in be to access the db
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ .Release.Name }}-be
  labels:
    app: {{ .Release.Name }}-notes
    service: be
spec:
  containers:
  - name: be
    image: {{ .Values.global.registry }}/notes-be:{{ .Values.backend.tag }}
    ports:
    - containerPort: 5000
    env:
    - name: REDIS_HOST
      value: "{{ .Release.Name }}-db"
    - name: REDIS_PASSWORD
      valueFrom:
        secretKeyRef:
          name: "{{ .Release.Name }}-db-secret"
          key: CLI_PASSWORD
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-be
spec:
  selector:
    app: {{ .Release.Name }}-notes
    service: be
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
  type: ClusterIP

```
- Test
```sh
cd ~/exam-infra
helm uninstall test
kubectl get pod,svc
helm upgrade --install test ./charts/exam-app/
kubectl get pod,svc,secret,sealedsecret
# do tests
helm uninstall test
```
- Create repository for infrastructure

6. Create ServiceMonitor
- `backend-monitor.yaml`
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ .Release.Name }}-be-monitor
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      service: be
  endpoints:
  - targetPort: 5000
    path: /metrics
```
- push the new manifest to Gitea

7. Create Argo CD app
- take NodePort
```sh
kubectl get svc -n argocd
````
- take initial password
```sh
argocd admin initial-password -n argocd
```
- login and change the password
```sh
argocd login IP:NodePort
# change password
argocd account update-password
```
- Chreate the application
```sh
argocd app create exam-app \
	--repo http://192.168.56.12:3000/vagrant/exam-infra \
	--path charts/exam-app \
	--dest-server https://kubernetes.default.svc \
	--dest-namespace ea \
	--sync-policy automated \
	--self-heal \
	--sync-option CreateNamespace=true \
	--label purpose=exam-prep \
	--label apptype=helm
```
- Path Prometheus to NodePort
```sh
kubectl patch svc monitoring-kube-prometheus-prometheus -n monitoring -p '{"spec": {"type": "NodePort"}}'
```
- check Prometheus, no data from our backend. The problem is missing label from ServiceMonitor in BE service! Make correction and push changes to infra  repo.

8. Create ServiceMonitor for Argo CD components. The manifest is outside exam-infra repo!
[!note] - Be sure that namespace and release are these!
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: argocd
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
    - port: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-server-metrics
  namespace: argocd
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-server-metrics
  endpoints:
    - port: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-repo-server-metrics
  namespace: argocd
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-repo-server
  endpoints:
    - port: metrics
```` 
- Create new ServiceMonitor objects
```sh
kubectl apply -f argocd-monitoring.yaml
```
- check Prometheus for new metrics, it can take time to shown!

- Patch Prometheus service back to ClusterIP
```sh
kubectl patch svc monitoring-kube-prometheus-prometheus -n monitoring -p '{"spec": {"type": "ClusterIP"}}'
```

9. Create workflows
- Create secrests in exam-app repo for authentication to exam-infra repo
REPO_USER
REPO_PASS
- Create workflow for Backend
```yaml
name: Exam App Backend Workflow

on:
  workflow_call:
    push:
      branches: [main]
      paths:
        - 'services/backend/**/'
  workflow_dispatch:

env:
  DOCKER: 192.168.56.12
  GITEA_URL: ${{env.DOCKER }}:3000
  REGISTRY_URL: ${{env.DOCKER }}:5000
  DOCKER_IMAGE_NAME: notes-be

jobs:
  setup:
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.calc.outputs.short_sha }}
    steps:
      - id: calc
        run: echo "short_sha=${GITHUB_SHA:0:10}" >> $GITHUB_OUTPUT

  build:
    needs: setup
    runs-on: ubuntu-latest
    env:
      IMAGE_TAG: ${{ needs.setup.outputs.image_tag }}
    steps:
      - name: Chack out the code
        uses:  actions/checkout@v6 # Check the action!

      - name: Build the image
        run: |
          cd services/backend
          docker build -t ${{ env.REGISTRY_URL }}/${{ env.DOCKER_IMAGE_NAME }}:$IMAGE_TAG -t ${{ env.REGISTRY_URL }}/${{ env.DOCKER_IMAGE_NAME }}:latest .
        
  push:
    needs: [setup, build]
    runs-on: ubuntu-latest
    env:
      IMAGE_TAG: ${{ needs.setup.outputs.image_tag }}

    steps:
      - name: Push Docker image
        run: |
          docker push ${{ env.REGISTRY_URL }}/${{ env.DOCKER_IMAGE_NAME }}:$IMAGE_TAG
          docker push ${{ env.REGISTRY_URL }}/${{ env.DOCKER_IMAGE_NAME }}:latest

  change:
    needs: [setup, push]
    runs-on: ubuntu-latest
    env:
      IMAGE_TAG: ${{ needs.setup.outputs.image_tag }}

    steps:
      - name: Update the image tag
        run: |
          # 1. Setup Auth and Clone Infra Repo
          git config --global user.name "Gitea CI"
          git config --global user.email "ci@gitea.local"

          git clone http://${{ secrets.REPO_USER }}:${{ secrets.REPO_PASS }}@${{ env.GITEA_URL }}/${{ secrets.REPO_USER }}/exam-infra.git
          cd exam-infra

          # 2. Update Version using yq
          yq -i ".backend.tag = \"$IMAGE_TAG\"" charts/exam-app/values.yaml

          # 3. Commit and Push back to Infra Repo
          git diff --quiet && echo "No changes, skipping push" && exit 0
          git add .
          git commit -m "gitea: update chart backend tag to ${IMAGE_TAG}"
          git push origin main
```
- Create workflow for frontend
```yaml
name: Exam App Frontend Workflow

on:
  workflow_call:
    push:
      branches: [main]
      paths:
        - 'services/frontend/**/'
  workflow_dispatch:

env:
  DOCKER: 192.168.56.12
  GITEA_URL: ${{env.DOCKER }}:3000
  REGISTRY_URL: ${{env.DOCKER }}:5000
  DOCKER_IMAGE_NAME: notes-fe

jobs:
  setup:
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.calc.outputs.short_sha }}
    steps:
      - id: calc
        run: echo "short_sha=${GITHUB_SHA:0:10}" >> $GITHUB_OUTPUT

  build:
    needs: setup
    runs-on: ubuntu-latest
    env:
      IMAGE_TAG: ${{ needs.setup.outputs.image_tag }}
    steps:
      - name: Chack out the code
        uses:  actions/checkout@v6 # Check the action!

      - name: Build the image
        run: |
          cd services/frontend
          docker build -t ${{ env.REGISTRY_URL }}/${{ env.DOCKER_IMAGE_NAME }}:$IMAGE_TAG -t ${{ env.REGISTRY_URL }}/${{ env.DOCKER_IMAGE_NAME }}:latest .
        
  push:
    needs: [setup, build]
    runs-on: ubuntu-latest
    env:
      IMAGE_TAG: ${{ needs.setup.outputs.image_tag }}

    steps:
      - name: Push Docker image
        run: |
          docker push ${{ env.REGISTRY_URL }}/${{ env.DOCKER_IMAGE_NAME }}:$IMAGE_TAG
          docker push ${{ env.REGISTRY_URL }}/${{ env.DOCKER_IMAGE_NAME }}:latest

  change:
    needs: [setup, push]
    runs-on: ubuntu-latest
    env:
      IMAGE_TAG: ${{ needs.setup.outputs.image_tag }}

    steps:
      - name: Update the image tag
        run: |
          # 1. Setup Auth and Clone Infra Repo
          git config --global user.name "Gitea CI"
          git config --global user.email "ci@gitea.local"

          git clone http://${{ secrets.REPO_USER }}:${{ secrets.REPO_PASS }}@${{ env.GITEA_URL }}/${{ secrets.REPO_USER }}/exam-infra.git
          cd exam-infra

          # 2. Update Version using yq
          yq -i ".frontend.tag = \"$IMAGE_TAG\"" charts/exam-app/values.yaml

          # 3. Commit and Push back to Infra Repo
          git diff --quiet && echo "No changes, skipping push" && exit 0
          git add .
          git commit -m "gitea: update chart frontend tag to ${IMAGE_TAG}"
          git push origin main
```
- run manually backend workflow