# Homework M1: Introduction and Tool Landscape

Main goal is to build further on what was demonstrated during the practice

Prerequisites may vary between different tasks. You should adjust your infrastructure according to the task you chose to implement

## Tasks

Choose and implement one or more of the following:

- Prepare a set of **two virtual machines**. One of the virtual machines should host the application, and the other -- the database. Pick up one of the pairs -- **Python + Redis**, **Python + MariaDB**, **Go + Redis**, or **Go + MariaDB**. You could implement it by following the manual approach or by automating the solution to some extent, including by using **Vagrant**

*Note that the application should be adjusted a bit to be able to communicate with the remote database*

- Prepare a set of **two container images**. One of the images should host the application, and the other -- the database. Pick up one of the pairs -- **Python + Redis**, **Python + MariaDB**, **Go + Redis**, or **Go + MariaDB**. Then spin up **two containers** out of them. You could implement it by following the manual approach or by automating the solution to some extent, including by using **Vagrant**

*Note that the application should be adjusted a bit to be able to communicate with the remote database*

*Note that depending on the selection, one of the images could be a standard one (if using **Redis**)*

*Note that the Docker (or the container runtime/platform of choice) could be in a VM or on your host*

- If **NodeJS** is your thing, try to create a version of the second **NodeJS** application but using **MariaDB** as a database. You are free to use either a pair of VMs, or a pair of containers (and container images)

*Note that the application should be adjusted a bit to be able to communicate with the remote database*

*Note that the Docker (or the container runtime/platform of choice) could be in a VM or on your host*

***\* Please note that even if you choose to implement more than one task, they may be quite independent and different. So, you may need to create a separate infrastructure (environment) for each or at least clean it every time***

## Proof

Prepare a document that shows what you accomplished and how you did it. It can include (**not limited to**):

- The commands you used to achieve the above tasks

- A few pictures showing intermediary steps or results

## Solution
1. [Task 1](./task1/task1.md)
1. [Task 2](./task1/task2.md)
1. [Task 3](./task1/task3.md)