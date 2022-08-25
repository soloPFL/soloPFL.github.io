---
layout: post
title:  "Setup Pi-Hole with unbound as hyperlocal recusive DNS Server"
date:   2022-08-25
categories: servers
---

# Fast way to do this:

## Install Pi-Hole first

{% highlight ruby %}
curl -sSL https://install.pi-hole.net | bash
{% endhighlight %}

## Then install and configure unbound

{% highlight ruby %}
wget https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/install-unbound-hyperlocal-pihole.sh
chmod +x install-unbound-hyperlocal-pihole.sh
sudo ./install-unbound-hyperlocal-pihole.sh
{% endhighlight %}


# Step by step
# Install Pi-Hole

{% highlight ruby %}
curl -sSL https://install.pi-hole.net | bash
{% endhighlight %}

# Install unbound

{% highlight ruby %}
sudo apt install unbound
{% endhighlight %}

# Download the unbound config and creat other configs

{% highlight ruby %}
wget -O pi-hole.conf https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/pi-hole.conf-unbound
mv pi-hole.conf /etc/unbound/unbound.conf.d/pi-hole.conf
{% endhighlight %}

{% highlight ruby %}
touch /etc/dnsmasq.d/99-edns.conf
echo 'edns-packet-max=1232' >> /etc/dnsmasq.d/99-edns.conf
{% endhighlight %}
{% highlight ruby %}
sudo service unbound restart
{% endhighlight %}

# Configure Pi-Hole to use unbound 

{% highlight ruby %}
127.0.0.1#5335 
{% endhighlight %}

Use this as Custom DNS (IPv4)

# Work in Progress 