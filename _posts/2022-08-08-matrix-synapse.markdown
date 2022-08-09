---
layout: post
title:  "Setup Matrix Synapse on Ubuntu 20.4"
date:   2022-08-08
categories: servers
---

# 1. Install Docker

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

# 2. Install NGinX Proxy Manager

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

# 3. Installing Matrix Synapse 

## Generating config files

{% highlight ruby %}
docker run -it --rm --mount type=volume,src=synapse-data,dst=/data -e SYNAPSE_SERVER_NAME=<your-intended-url> -e SYNAPSE_REPORT_STATS=no matrixdotorg/synapse:latest generate
{% endhighlight %}

Insert your URL <......>

The config file will be here:
'/var/lib/docker/volumes/synapse-data/_data/homeserver.yaml'
Settings to look at: enable_registration and SMTP

set the following for federation 
{% highlight ruby %}
serve_server_wellknown: true
{% endhighlight %}
If this is not set federation doesn't work.

## Start the server

Map port 443 to a different one. (eg. 4443) The reverse proxy will use 443. 

{% highlight ruby %}
docker run -d --name synapse --mount type=volume,src=synapse-data,dst=/data -p 8008:8008 -p 4443:443 --restart=unless-stopped matrixdotorg/synapse:latest
{% endhighlight %}

check:
'docker logs synapse'

Now Browse to port 8008 -> you should see a simple page saying Matrix is running.

# 4. Get encryption (SSL) from let's encrypt and config. reverse proxy

Lookup internal Docker IP eg. 172.x.x.x
'ip addr show docker0'

NGinX Proxy Manager>>> new proxy host>>> use the 172.x.x.x ip.

Enable Cache Assets, Block Common Explits, and Websockets Support. 
SAVE
Now edit the new host and add a Custom Location. 
Enter your URL (host name) in "Definte Location"
"Scheme" = https
IP Adress field = the 172.x.x.x from above.
Port = 4443 from above.
Now requst the SSL Cert and enable "Force SSL"
no errors when saving? cool

# 5 Register an admin account on Synapse

{% highlight ruby %}
docker exec -it synapse register_new_matrix_user http://DNSorIP:8008 -c /data/homeserver.yaml
{% endhighlight %}

## Solving UFW and Docker issues

add the following at the end of:  /etc/ufw/after.rules

{% highlight ruby %}
# BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:ufw-docker-logging-deny - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -p udp -m udp --sport 53 --dport 1024:65535 -j RETURN

-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN

-A ufw-docker-logging-deny -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW DOCKER BLOCK] "
-A ufw-docker-logging-deny -j DROP

COMMIT
# END UFW AND DOCKER
{% endhighlight %}

sudo ufw reload

Now UFW is blocking ports opened by Docker.
Now add UFW rules to open port 80 and 443 to the Proxy Docker


# WORK in progress