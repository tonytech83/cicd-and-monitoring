
## Task

Try to move from **monorepo** to **polyrepo** model and implement **Jenkins** pipeline
- create a **repository per service**; 
- each repository should have a pipeline that tests the code and then builds the container image;
- there is **no need** to have any triggering or connection between the individual repositories


## Solution

- **[Diagram](#diagram)**



### Diagram

```plain
------------+---------------------------+------------
            |                           |
      192.168.99.101              192.168.99.102
            |                           |
+-----------+-----------+   +-----------+-----------+
|       [ docker ]      |   |      [ jenkins ]      |
|                       |   |                       |
|  docker               |   |  jenkins              |
|  gitea                |   |                       |
|  docker registry      |   |                       |
|  git                  |   |                       |
|                       |   |                       |
|                       |   |                       |
+-----------------------+   +-----------------------+
```

### Update `scripts/setup-gitea.sh`
Create three function to setup all local repositories
```bash
...

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

...
```

### Add plugin to `vagrant/jenkins/plugins.txt`
```plain
docker-workflow:572.v950f58993843
```

### API

- Create API pipiline job in Jenkins - `vagrant/jenkins/api-job.xml`
```xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Pipeline for Gitea Task Manager API</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.plugins.gitea.GiteaPushTrigger plugin="gitea"/>
        
        <com.cloudbees.jenkins.sidecar.gitscremote.GitHubPushTrigger plugin="github"/>
        
        <hudson.triggers.SCMTrigger>
          <spec></spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>http://192.168.99.101:3000/vagrant/api.git</url>
          <credentialsId>vagrant</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
```
- Update Jenkinsfile
```groovy
pipeline {
    agent none

    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        REGISTRY_URL = "192.168.99.101:5000"
    }
    stages {
        stage('Test the API') {
            agent {
                docker {
                    image 'python:3.12-slim'
                    label 'docker'
                    args '-u root' 
                }
            }
            steps {
                sh '''
                pip install flask redis pytest
                python3 -m pytest tests/
                '''
            }
        }
        stage('Build the API') {
            agent { label 'docker' }
            steps {
                sh '''
				docker build -t ${REGISTRY_URL}/task-manager-api:${IMAGE_TAG} .
				docker push ${REGISTRY_URL}/task-manager-api:${IMAGE_TAG}
				'''
            }
        }
        stage('Clean') {
            agent { label 'docker' }
            steps
            {
                cleanWs()
            }
        }
    }
}
```
- Result
```sh
vagrant@docker:/tmp/api$ curl http://localhost:5000/v2/task-manager-api/tags/list
{"name":"task-manager-api","tags":["3"]}
```