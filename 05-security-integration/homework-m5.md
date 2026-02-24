# Homework M5: Security Integration

Main goal is to build further on what was demonstrated during the practice

Prerequisites may vary between different tasks. You should adjust your infrastructure according to the task you chose to implement

## Tasks

Explore **Trivy** further and why not **Grype** by choosing to implement one or more of the following

- Create a **Gitea Actions** workflow or **Jenkins** pipeline that executes **periodically**, for example, **every day at 20:00** and using **Trivy**, scans the **latest** tag of the container images of our four microservices. The workflow/pipeline should also allow manual execution

- Create a **Gitea Actions** workflow or **Jenkins** pipeline that executes **periodically**, for example, **every day at 20:00** and using **Grype**, scans the **latest** tag of the container images of our four microservices. The workflow/pipeline should also allow manual execution

**_\* The focus should be on achieving the required and not on doing it in the most automated way possible_**

**_\*\* Please note that even if you choose to implement more than one task, they may be quite independent and different. So, you may need to create a separate infrastructure (environment) for each or at least clean it every time_**

## Proof

Prepare a document that shows what you accomplished and how you did it. It can include (**not limited to**):

- The commands you used to achieve the above tasks

- A few pictures showing intermediary steps or results

## Solution

1. [Task 1](./task1/task1.md)
2. [Task 2](./task2/task2.md)
