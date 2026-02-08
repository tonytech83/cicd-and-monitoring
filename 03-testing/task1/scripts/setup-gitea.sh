#!/bin/bash

echo "* Check if Gitea is running and ready ..."
while true; do 
  echo 'Trying to connect to gitea at http://192.168.99.101:3000 ...'; 
  if [ $(curl -s -o /dev/null -w "%{http_code}" http://192.168.99.101:3000) == "200" ]; then 
    echo '... connected.'; 
    break; 
  else 
    echo '... no success. Sleep for 5s and retry ...'; 
    sleep 5; 
  fi 
done

echo "* Create vagrant (with admin role) user in Gitea ..."
docker container exec -u git gitea gitea admin user create --username vagrant --password vagrant --email vagrant@do2.lab --admin

echo "* Configure git ..."
git config --global user.name "Vagrant User"
git config --global user.email vagrant@homework.lab

echo "* Prepare a repository ..."
cp -Rv /vagrant/apps/task-manager /tmp/task-manager
cd /tmp/task-manager && \
git init && \
git checkout -b main && \
git add . && \
git commit -m "first commit" && \
git push -o repo.private=false --set-upstream http://vagrant:vagrant@192.168.99.101:3000/vagrant/task-manager main

# echo "* Add Jenkins webhook to Gitea ..."
# curl -X 'POST' 'http://192.168.56.12:3000/api/v1/repos/vagrant/task-manager/hooks' \
#   -H 'accept: application/json' \
#   -H 'authorization: Basic '$(echo -n 'vagrant:vagrant' | base64) \
#   -H 'Content-Type: application/json' \
#   -d '{
#   "active": true,
#   "branch_filter": "*",
#   "config": {
#     "content_type": "json",
#     "url": "http://192.168.56.11:8080/gitea-webhook/post",
#     "http_method": "post"
#   },
#   "events": [
#     "push"
#   ],
#   "type": "gitea"
# }'

echo "* Generate Runner registration token ..."
docker container exec -u git gitea gitea actions generate-runner-token | tee /tmp/gitea/runner-token.txt

echo "* Start Gitea Runner ..."
sed -i "s/<GITEA-TOKEN>/$(cat /tmp/gitea/runner-token.txt)/" /tmp/gitea/runner-compose.yaml
docker compose -f /tmp/gitea/runner-compose.yaml up -d 
