# Espocrm Workflow

This project is a fork of the [EspoCRM Github repository](https://github.com/espocrm/espocrm). It adds additional functionality to set up a continuous integration, delivery, and deployment (CI/ CD) process, using Docker and [Github actions](https://docs.github.com/en/actions). 

## About

### Workflow

The project uses [Github actions](https://docs.github.com/en/actions) to define and run the workflow. The workflow is specified in the ```.github/workflows/main.yml``` file. It runs tests, builds images, and deploys the images to the server:

1. Run unit tests.
2. Run integration tests.
3. Build Docker images using ```docker-compose.ci.yml```, and save them as [Github packages](https://github.com/features/packages).
4. Pull the built images from [Github packages](https://github.com/features/packages) into the server.
5. Build and run containers based on the pulled images using ```docker-compose.prod.yml```. This runs the containers: ```espocrm```, ```mysql```, and ```espocrm-daemon```.

### Docker

The following files have been added which are used for building Docker images and running Docker containers:

```bash
docker-compose.dev.yml    # Used locally for development
docker-compose.ci.yml    # Used in Github actions workflow on the Github server
docker-compose.prod.yml    # Used in Github actions workflow to run containers on the server
docker-daemon.sh    # Used for running the espocrm-daemon container
docker-entrypoint.sh    # Used for running the mysql and espocrm containers
docker-websocket.sh
Dockerfile    # Used for building images
```

These files are largely based on the files in the [espocrm-docker Github repository](https://github.com/espocrm/espocrm-docker).

## Setup

### Server setup

Here is an example of how to set up a server for the project:

1. Set up a remote server with SSH access, e.g. with [DigitalOcean](https://www.digitalocean.com/) or another provider.

2. Install Docker if not already installed.

3. Create a user and add them to the ```sudo``` and ```docker``` groups:
    ```bash
    adduser myuser
    usermod -aG sudo myuser
    usermod -aG docker myuser
    ```
4. Enable SSH access by copying the key from ```root```:
    ```bash
    rsync --archive --chown=myuser:myuser ~/.ssh /home/myuser
    ```
5. After verifying that you can SSH in as the new user, disable root access:
    ```bash
    sudo vim /etc/ssh/sshd_config   # Set PermitRootLogin to no
    sudo systemctl restart sshd    # Restart the daemon
    ```
6. Set up a firewall:
    ```bash
    ufw allow OpenSSH
    ufw enable
    ```
7. Create a user for Github actions continuous integration, and add them to the ```sudo``` and ```docker``` groups:
    ```bash
    adduser githubciuser
    usermod -aG sudo githubciuser
    usermod -aG docker githubciuser
    ```
8. Generate SSH keys for the new user (leave the password blank):
    ```bash
    ssh-keygen -t ed25519
    cat <path/to/public/key> >> ~/.ssh/authorized_keys
    ```
    Save the username and private key as the [Github secrets](https://docs.github.com/en/rest/actions/secrets): ```SSH_USER``` and ```PRIVATE_KEY```.

### Github secrets

The project uses [Github secrets](https://docs.github.com/en/rest/actions/secrets) to save and retrieve private information. To run the project, the following secrets to be set:

- ```ESPOCRM_ADMIN_USERNAME``` and ```ESPOCRM_ADMIN_PASSWORD``` - the username and password of the admin user in EspoCRM.
- ```ESPOCRM_DATABASE_PASSWORD``` - mySQL database password.
- ```ESPOCRM_SITE_URL``` - the URL of the site, e.g. ```http://123.45.678.90:8080```
- ```IP_ADDRESS``` - the IP address of the server
- ```NAMESPACE``` - the Github organisation or username which the repo is in
- ```PERSONAL_ACCESS_TOKEN``` - a [Github personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens), with permissions to write, read, and delete packages
- ```SSH_USER``` and ```PRIVATE_KEY``` - name and private SSH key pf a user on the server (the user should be part of the ```docker``` group)

## Usage

### Production

To start the workflow, push changes to the ```master``` branch:

```bash
git push
```

This starts the workflow described above - it runs tests, builds the new images, pulls the new images to the server, and starts up ```mysql```, ```espocrm```, and ```espocrm-daemon``` containers.

Note that this creates new images on the server, so occasionally it is good to remove old images to avoid taking up a lot of space. This can be done by accessing the server via SSH and running ```docker image prune```.

### Development

The Docker containers can be built and run locally using the ```docker-compose.dev.yml``` file:

```bash
docker compose -f docker-compose.dev.yml up --force-recreate -d
```
Add the ```--renew-anon-volumes``` tag to recreate anonymous volumes instead of retrieving data from the previous containers.


## EspoCRM

[![PHPStan level 8](https://img.shields.io/badge/PHPStan-level%208-brightgreen)](#espocrm)

[EspoCRM is an Open Source CRM](https://www.espocrm.com) (Customer Relationship Management)
software that allows you to see, enter and evaluate all your company relationships regardless
of the type. People, companies or opportunities – all in an easy and intuitive interface.

It's a web application with a frontend designed as a single page application and REST API
backend written in PHP.

[Download](https://www.espocrm.com/download/) the latest release from our website. Release notes
and release packages are available at [Releases](https://github.com/espocrm/espocrm/releases) on GitHub.

![Screenshot](https://user-images.githubusercontent.com/1006792/226094559-995dfd2a-a18f-4619-a21b-79a4e671990a.png)

### Demo

You can try the CRM on the online [demo](https://www.espocrm.com/demo/).

### Requirements

* PHP 8.0 and later;
* MySQL 5.7 (and later), or MariaDB 10.2 (and later).

For more information about server configuration see [this article](https://docs.espocrm.com/administration/server-configuration/).

### Documentation

See the [documentation](https://docs.espocrm.com) for administrators, users and developers.

### Bug reporting

Create a [GitHub issue](https://github.com/espocrm/espocrm/issues/new/choose) or post on our [forum](https://forum.espocrm.com/forum/bug-reports).

### Installing stable version

See installation instructions:

* [Manual installation](https://docs.espocrm.com/administration/installation/) 
* [Installation by script](https://docs.espocrm.com/administration/installation-by-script/)
* [Installation with Docker](https://docs.espocrm.com/administration/docker/installation/)
* [Installation with Traefik](https://docs.espocrm.com/administration/docker/traefik/)

### Development

See the [developer documentation](https://docs.espocrm.com/development/).

We highly recommend using IDE for development. The backend codebase follows SOLID principles, utilizes interfaces, static typing and generics. We recommend to start learning EspoCRM from the Dependency Injection article in the documentation.

### Contributing

Before we can merge your pull request, you need to accept our CLA [here](https://github.com/espocrm/cla). It's very simple to do.

Branches:

* *fix* – upcoming maintenance release; minor fixes should be pushed to this branch;
* *master* – develop branch; new features should be pushed to this branch;
* *stable* – last stable release.

### Language

If you want to improve existing translation or add a language that is not available yet, you can contribute on our [POEditor](https://poeditor.com/join/project/gLDKZtUF4i) project. See instructions [here](https://www.espocrm.com/blog/how-to-use-poeditor-to-translate-espocrm/).

Changes on POEditor are usually merged to the GitHub repository before minor releases.

### Community & Support

If you have a question regarding some features, need help or customizations, want to get in touch with other EspoCRM users, or add a feature request, please use our [community forum](https://forum.espocrm.com/). We believe that using the forum to ask for help and share experience allows everyone in the community to contribute and use this knowledge later.

### License

EspoCRM is published under the GNU GPLv3 [license](https://raw.githubusercontent.com/espocrm/espocrm/master/LICENSE.txt).
