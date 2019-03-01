---
title: Setting up your own private VPN on Google Cloud
date: "2016-11-05T21:54:03-07:00"
layout: post
draft: false
path: "/posts/openvpn"
category: "vpn"
tags:
  - "openvpn"
description: "Setting up your own private VPN on Google Cloud"
---

Why would I want to roll my own VPN, you ask? A couple reasons:

* If you frequent coffee shops, or airports, and want a little extra security when using open, un-protected wifi networks
* If you want to mask your IP address for whatever reason
* Rolling your own could be cheaper than going with a commerical solution. All you need is a small Linux VM with a cloud provider, and the big players usually have free trials. AWS's free tier lasts for 30 days; Google Cloud (GCE) runs for 60 days or $300, which ever comes first; and Digital Ocean droplets could be had for ~$5/month, much less if you don't keep them running all the time.
* For funsies!

We'll be using Ubuntu 16.04 and OpenVPN as per [this](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-16-04) Digital Ocean tutorial, which has pretty much has everything we need. The only difference is we're running the steps on a Google Cloud compute, rather than a Digital Ocean droplet.

Step 1: create the compute instance. We can do this via the UI or CLI:

``` bash
gcloud compute instances create vpn-server --can-ip-forward --machine-type g1-small --image ubuntu-1604-lts
```

Step 2: follow the Digital Ocean tutorial to install OpenVPN and create the private/public keys for server and client(s):

```bash
# Install OpenVPN and EasyRSA
sudo apt-get install openvpn easy-rsa
sudo make-cadir /etc/openvpn/easy-rsa

# Configure env vars for generating certs
sudo su
cd /etc/openvpn/easy-rsa
vi vars
source vars

# Clean, create CA cert, server and dh keys
./clean-all
./build-ca
./build-key-server server
./build-dh
openvpn --genkey --secret keys/ta.key

# Create client key pair
./build-key client1
cd keys
cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn

# Configure server.conf, sysctl.conf, and firewall/NAT rules
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
gunzip /etc/openvpn/server.conf.gz
vi /etc/opevpn/server.conf
vi /etc/sysctl.conf
vi /etc/ufw/before.rules
vi /etc/default/ufw
ufw allow 3141/tcp
ufw allow OpenSSH

# Restart ufw
ufw disable
ufw enable

# Start OpenVPN and enable daemon (auto-start on server reboot)
systemctl start openvpn@server
systemctl status openvpn@server
systemctl enable openvpn@server
```

Copy the client keys and CA cert (ca.crt, client1.crt, client1.key) to local machine and configure OpenVPN on the client.

Step 3: PROFIT!

