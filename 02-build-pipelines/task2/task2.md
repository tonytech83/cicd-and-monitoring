## Task
Create a **CI pipeline** using **Gitea** for a **Java** application (in the supporting files) that checks out the code from **Gitea** repository, **builds** a container image (two tags – **latest** and **commit SHA**), and **pushes** it to a local **Docker Registry** (insecure and without authentication)

## Solution


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

