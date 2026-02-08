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

# Function to add local repository to Gitea by repository name
add_repo() {
  local repo_name=$1

  echo "* Prepare a $repo_name repository ..."
  cp -Rv /vagrant/apps/$repo_name /tmp/$repo_name
  cd /tmp/$repo_name && \
  git init && \
  git checkout -b main && \
  git add . && \
  git commit -m "first commit" && \
  git push -o repo.private=false --set-upstream "http://vagrant:vagrant@192.168.99.101:3000/vagrant/$repo_name" main
}

# Function to add Jenkins webhook by repository name
add_webhook() {
  local repo_name=$1

  echo "* Add Jenkins webhook to Gitea $repo_name repository ..."
  curl -X "POST" "http://192.168.99.101:3000/api/v1/repos/vagrant/${repo_name}/hooks" \
    -H 'accept: application/json' \
    -H 'authorization: Basic '$(echo -n 'vagrant:vagrant' | base64) \
    -H 'Content-Type: application/json' \
    -d '{
    "active": true,
    "branch_filter": "*",
    "config": {
      "content_type": "json",
      "url": "http://192.168.99.102:8080/gitea-webhook/post",
      "http_method": "post"
    },
    "events": [
      "push"
    ],
    "type": "gitea"
  }'
}

# Function to setup repository
# - add repo in Gitea
# - create Jenkins webhook
setup_repo() {
  repos=("api" "archiver" "frontend" "monitor")

  for repo in "${repos[@]}"; do
    if add_repo "$repo"; then
      add_webhook "$repo"
    else
      echo "Failed to set up repository: $repo" >&2
    fi
  done
}

setup_repo

echo "* Generate Runner registration token ..."
docker container exec -u git gitea gitea actions generate-runner-token | tee /tmp/gitea/runner-token.txt

echo "* Start Gitea Runner ..."
sed -i "s/<GITEA-TOKEN>/$(cat /tmp/gitea/runner-token.txt)/" /tmp/gitea/runner-compose.yaml
docker compose -f /tmp/gitea/runner-compose.yaml up -d 
