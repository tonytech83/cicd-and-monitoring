
## Task

Try to move from **monorepo** to **polyrepo** model and implement **Jenkins** pipeline
- create a **repository per service**; 
- each repository should have a pipeline that tests the code and then builds the container image;
- there is **no need** to have any triggering or connection between the individual repositories


## Solution

- **[Diagram](#diagram)**
- **[Update `scripts/setup-gitea.sh`](#update-scriptssetup-giteash)**
- **[API](#api)**
- **[Archiver](#archiver)**
- **[Frontend](#frontend-htmljavascript)**
- **[Monitor](#monitor)**
- **[All jenkins pipeline](#all-jenkins-pipelines)**

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
---

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
![pic-10](../media/pic-10.png)

### Add plugin to `vagrant/jenkins/plugins.txt`

***This plugin is required because it enables the Jenkins Pipeline to use the docker agent syntax and the docker.image().inside method for running build steps within isolated containers.***

```plain
docker-workflow:572.v950f58993843
```
---

### API

- Create API pipiline job in Jenkins - `vagrant/jenkins/api-job.xml` ( this automatically creates the Jenkins pipeline via the CLI )
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
            agent { label 'docker' }
            steps {
                script {
                    docker.image('python:3.12-slim').inside('-u root') {
                        sh '''
                        pip install flask redis pytest
                        python3 -m pytest tests/
                        '''
                    }
                }
            }
        }

        stage('Build the API') {
            agent { label 'docker' }
            steps {
                sh '''
                # build image with current image tag
                docker build -t ${REGISTRY_URL}/task-manager-api:${IMAGE_TAG} .
                
                # build image wuth 'latest' tag for current image
                docker tag ${REGISTRY_URL}/task-manager-api:${IMAGE_TAG} ${REGISTRY_URL}/task-manager-api:latest
                
                docker push ${REGISTRY_URL}/task-manager-api:${IMAGE_TAG}
                docker push ${REGISTRY_URL}/task-manager-api:latest
                '''
            }
        }

        stage('Clean') {
            agent { label 'docker' }
            steps {
                cleanWs()
            }
        }
    }
}
```
- Result
```sh
$ curl http://localhost:5000/v2/task-manager-api/tags/list
{"name":"task-manager-api","tags":["3","4","latest"]}
```

![pic-6](../media/pic-5.png)

---

### Archiver

- Create Archiver pipiline job in Jenkins - vagrant/jenkins/archiver-job.xml ( this automatically creates the Jenkins pipeline via the CLI )

```xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Pipeline for Gitea Task Manager Archiver</description>
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
          <url>http://192.168.99.101:3000/vagrant/archiver.git</url>
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

- Update Jenkinsfile for Archiver
```groovy
pipeline {
    agent none

    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        REGISTRY_URL = "192.168.99.101:5000"
    }
    stages {
        stage('Test the Archiver') {
            agent { label 'docker' } 
            steps {
                script {
                    docker.image('eclipse-temurin:21-jdk').inside('-v maven-cache:/root/.m2') {
                        sh './mvnw test'
                    }
                }
            }
        }
        stage('Build the Archiver') {
            agent { label 'docker' }
            steps {
                sh '''
                # build image with current image tag
                docker build -t ${REGISTRY_URL}/task-manager-archiver:${IMAGE_TAG} .
                
                # build image wuth 'latest' tag for current image
                docker tag ${REGISTRY_URL}/task-manager-archiver:${IMAGE_TAG} ${REGISTRY_URL}/task-manager-archiver:latest
                
                docker push ${REGISTRY_URL}/task-manager-archiver:${IMAGE_TAG}
                docker push ${REGISTRY_URL}/task-manager-archiver:latest
                '''
            }
        }
        stage('Clean') {
            agent { label 'docker' }
            steps {
                cleanWs()
            }
        }
    }
}
```

- Result
```sh
$ curl http://localhost:5000/v2/task-manager-archiver/tags/list
{"name":"task-manager-archiver","tags":["5","4","latest"]}
```

---

### Frontend (HTML+JavaScript)
- Create Frontend pipiline job in Jenkins - vagrant/jenkins/frontend-job.xml ( this automatically creates the Jenkins pipeline via the CLI )
```xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Pipeline for Gitea Task Manager Frontend</description>
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
          <url>http://192.168.99.101:3000/vagrant/frontend.git</url>
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

- Update Jenkinsfile for Frontend

***Before running the full Jenkins pipeline for the Frontend (including E2E and Playwright tests), all microservice containers must be up and running. To achieve this, the pipeline should be run without test stages to build and push the initial task-manager-frontend image to the registry.***

```groovy
pipeline {
    agent none

    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        REGISTRY_URL = "192.168.99.101:5000"
    }

    stages {
        stage('Test the Frontend Smoke Tests') {
            agent { label 'docker' }
            steps {
                script {
                    docker.image('node:20-slim').inside('-u root') {
                        sh '''
                        apt-get update && apt-get install -y curl
                        cd test/
                        chmod +x smoke_test.sh
                        ./smoke_test.sh
                        '''
                    }
                }
            }
        }

        stage('Test the Frontend Playwright') {
            agent { label 'docker' }
            steps {
                script {
                    docker.image('mcr.microsoft.com/playwright:v1.50.1-noble').inside('-u root --ipc=host') {
                        sh '''
                        cd test/
                        npm ci
                        npx playwright install --with-deps chromium
                        npx playwright test test_ui.spec.js
                        '''
                    }
                }
            }
        }

        stage('Build the Frontend') {
            agent { label 'docker' }
            steps {
                sh '''
                # build image with current image tag
                docker build -t ${REGISTRY_URL}/task-manager-frontend:${IMAGE_TAG} .

                # tag image with 'latest' tag
                docker tag ${REGISTRY_URL}/task-manager-frontend:${IMAGE_TAG} ${REGISTRY_URL}/task-manager-frontend:latest

                # push both tags
                docker push ${REGISTRY_URL}/task-manager-frontend:${IMAGE_TAG}
                docker push ${REGISTRY_URL}/task-manager-frontend:latest
                '''
            }
        }

        stage('Clean') {
            agent { label 'docker' }
            steps {
                cleanWs()
            }
        }
    }
}
```
- Result
```sh
$ curl http://localhost:5000/v2/task-manager-frontend/tags/list
{"name":"task-manager-frontend","tags":["7","10","6","latest"]}
```

![pic-7](../media/pic-7.png)

---

### Monitor

- Create Monitor pipiline job in Jenkins - `vagrant/jenkins/monitor-job.xml` ( this automatically creates the Jenkins pipeline via the CLI )
```xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Pipeline for Gitea Task Manager Monitor</description>
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
          <url>http://192.168.99.101:3000/vagrant/monitor.git</url>
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
- Update Jenkinsfile for Monitor
```groovy
pipeline {
    agent none

    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        REGISTRY_URL = "192.168.99.101:5000"
    }
    stages {
        stage('Test the Monitor') {
            agent { label 'docker' }
            steps {
                script {
                    docker.image('golang:1.21-alpine').inside('-u root -v go-cache:/go/pkg/mod') {
                        sh '''
                        go mod tidy
                        go test -v ./...
                            '''
                    }
                }
            }
        }
        stage('Build the Monitor') {
            agent { label 'docker'}
            steps {
                sh '''
                # build image with current image tag
                docker build -t ${REGISTRY_URL}/task-manager-monitor:${IMAGE_TAG} .
                
                # build image wuth 'latest' tag for current image
                docker tag ${REGISTRY_URL}/task-manager-monitor:${IMAGE_TAG} ${REGISTRY_URL}/task-manager-monitor:latest
                
                docker push ${REGISTRY_URL}/task-manager-monitor:${IMAGE_TAG}
                docker push ${REGISTRY_URL}/task-manager-monitor:latest
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
$ curl http://localhost:5000/v2/task-manager-monitor/tags/list
{"name":"task-manager-monitor","tags":["3","latest","2"]}
```
![pic-8](../media/pic-8.png)

---

### All jenkins pipelines

![pic-9](../media/pic-9.png)