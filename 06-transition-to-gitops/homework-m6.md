# Homework M6: Transition to GitOps

Main goal is to build further on what was demonstrated during the practice

Prerequisites may vary between different tasks. You should adjust your infrastructure according to the task you chose to implement

## Task

Explore further the **GitOps** principles by executing the following

- Take the **simple counter application** (without DB dependencies) from the earlier modules (no matter the language) and create a repository for it (**counter-app**)

- Prepare a **Helm chart** for the application and store it in another repository (**counter-infra**)

- Create an end-to-end **Gitea Actions** workflow or **Jenkins** pipeline that has a **lint** (simple Dockerfile linter), **test** (simple curl-based test), **build and push**, and **change** stages

- Define **Argo CD** application that interacts with the infrastructure repository

**_\* The focus should be on achieving the required and not on doing it in the most automated way possible_**

## Proof

Prepare a document that shows what you accomplished and how you did it. It can include (**not limited to**):

- The commands you used to achieve the above tasks

- A few pictures showing intermediary steps or results

## Solution

1. [Task 1](./task1/task1.md)
