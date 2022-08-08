---
layout: post
title:  "Setup Matrix Synapse on Ubuntu 20.4"
date:   2022-08-08 18:11:15 +0200
categories: servers
---

#1. Install Docker

{% highlight ruby %}
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -y

## now set user as part of docker group
sudo usermod -aG docker ${USER}

## install docker-compose
sudo apt install docker-compose -y

{% endhighlight %}

#2 Install NGinX Proxy Manager

Start in a home folder eg. /home/user1/ 

{% highlight ruby %}
mkdir npm
cd npm
nano docker-compose.yml
{% endhighlight %}

{% highlight ruby %}
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "<a user name you want>"
      DB_MYSQL_PASSWORD: "<a password you want>"
      DB_MYSQL_NAME: "npm"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
  db:
    image: 'jc21/mariadb-aria:10.4'
    environment:
      MYSQL_ROOT_PASSWORD: '<a long, strong password you want>'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: '<the same username as above>'
      MYSQL_PASSWORD: '<the same password as in the section above>'
    volumes:
      - ./data/mysql:/var/lib/mysql

{% endhighlight %}
SAVE and exit (contr-X)
Start the Proxy Manager:

docker-compose  up -d

Attention: if you use UFW Docker will ignore the rules you set and open port 443, 80 and <b>81</b> 

I found a fix for that. More later....

Now Browse to port 81. It's the npm admin web interface

{% highlight ruby %}
default user: admin@example.com
default password: changeme
{% endhighlight %}


# WORK in progress