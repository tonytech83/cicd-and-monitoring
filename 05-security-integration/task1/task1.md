### Create Trivy master workflow

```yaml
name: Trivy Scan

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
on:
  push:
    branches: [main]
  workflow_dispatch:
  schedule:
    - cron: "0 22 * * *"

jobs:
  check-api:
    uses: ./.gitea/workflows/trivy/trivy-check-api.yaml

  check-archiver:
    uses: ./.gitea/workflows/trivy/trivy-check-archiver.yaml

  check-frontend:
    uses: ./.gitea/workflows/trivy/trivy-check-frontend.yaml

  check-monitor:
    uses: ./.gitea/workflows/trivy/trivy-check-monitor.yaml
```

### Create a separate workflow to scan each image

### API

- Create `.trivyignore` file in the root of the project to tell Trivy to ignore `CVE-2026-0861`

```plain
# Waiting for Debian 13 patch - review by 2026-03-15
CVE-2026-0861 exp:2026-03-15
```

### Archiver

We executing

```sh
 trivy image \
 --severity HIGH,CRITICAL \
 --exit-code 1             \
 --ignorefile .trivyignore \
 192.168.56.12:5000/task-manager-archiver:latest
```

and got three HIGH variabilities

```plain
Report Summary

┌────────────────────────────────────────────────────────────────┬────────┬─────────────────┬─────────┐
│                             Target                             │  Type  │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────────────────────┼────────┼─────────────────┼─────────┤
│ 192.168.56.12:5000/task-manager-archiver:latest (ubuntu 22.04) │ ubuntu │        0        │    -    │
├────────────────────────────────────────────────────────────────┼────────┼─────────────────┼─────────┤
│ app/app.jar                                                    │  jar   │        3        │    -    │
└────────────────────────────────────────────────────────────────┴────────┴─────────────────┴─────────┘
```

- Upgrade version of Spring Boot to 3.4.5 in`pom.xml`

```xml

<!-- from -->
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.2</version>
    <relativePath/>
</parent>

<!-- to -->
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.4.5</version>
    <relativePath/>
</parent>
```

- Explicitly add spring-core in `pom.xml` with version 6.2.11

```xml
<properties>
    <java.version>21</java.version>
    <maven.compiler.source>21</maven.compiler.source>
    <maven.compiler.target>21</maven.compiler.target>
    <spring-framework.version>6.2.11</spring-framework.version>  <!-- add this line -->
</properties>
```

Push the changes to rebuild the image. After changes

```plain
Report Summary

┌────────────────────────────────────────────────────────────────┬────────┬─────────────────┬─────────┐
│                             Target                             │  Type  │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────────────────────┼────────┼─────────────────┼─────────┤
│ 192.168.56.12:5000/task-manager-archiver:latest (ubuntu 22.04) │ ubuntu │        0        │    -    │
├────────────────────────────────────────────────────────────────┼────────┼─────────────────┼─────────┤
│ app/app.jar                                                    │  jar   │        0        │    -    │
└────────────────────────────────────────────────────────────────┴────────┴─────────────────┴─────────┘
```

### Monitor

We executing

```sh
 trivy image \
 --severity HIGH,CRITICAL \
 --exit-code 1             \
 --ignorefile .trivyignore \
 192.168.56.12:5000/task-manager-monitor:latest
```

and got 12 variabilities

```plain
Report Summary

┌────────────────────────────────────────────────────────────────┬──────────┬─────────────────┬─────────┐
│                             Target                             │   Type   │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────────────────────┼──────────┼─────────────────┼─────────┤
│ 192.168.56.12:5000/task-manager-monitor:latest (alpine 3.23.3) │  alpine  │        0        │    -    │
├────────────────────────────────────────────────────────────────┼──────────┼─────────────────┼─────────┤
│ root/monitor                                                   │ gobinary │       12        │    -    │
└────────────────────────────────────────────────────────────────┴──────────┴─────────────────┴─────────┘
```

- Change version of base image for build stage in Dockerfile from `golang:1.21-alpine` to `golang:1.21-alpine`

- In `go.mod` file change Go version from 1.21 to 1.24 and fiber from v2.52.0 to v2.52.11

- change the version of Go in setup step from 1.21 to 1.24 inside `ci-monitor-lint.yaml` file.

after fixes

```plain
Report Summary

┌────────────────────────────────────────────────────────────────┬──────────┬─────────────────┬─────────┐
│                             Target                             │   Type   │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────────────────────┼──────────┼─────────────────┼─────────┤
│ 192.168.56.12:5000/task-manager-monitor:latest (alpine 3.23.3) │  alpine  │        0        │    -    │
├────────────────────────────────────────────────────────────────┼──────────┼─────────────────┼─────────┤
│ root/monitor                                                   │ gobinary │        0        │    -    │
└────────────────────────────────────────────────────────────────┴──────────┴─────────────────┴─────────┘
```
