---
layout: default
title: Security
description: IBGA common security issues and solutions
parent: References
nav_order: 2
---

# Security
{: .no_toc }

<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

---

## Running IBGA in an Internet Server

**Not recommended.**{: .text-red-200 } IBGA is not designed to run on a public server. The default security is not hardened enough to get you full protection against malicious clients and hacking attempt. Although if you have to host it on the Internet, there are still measures to follow for stronger security on the host server.

### Configure Key-based Authentication for SSH

Chances are your host server is Linux-based if you buy one. For Linux, the first security measure you should take, is to <a href="https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server" target="_blank">configure key-based authentication for SSH</a> (instead of password-based).

### Configure Firewall with UFW (for Static Client IP)

<a href="https://en.wikipedia.org/wiki/Uncomplicated_Firewall" target="_blank">UFW (or Uncomplicated Firewall)</a> is the simplest way to get your host server protected with a firewall. It lets you create rules so that the IBGA ports are exposed only to your IP. <a href="https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-18-04" target="_blank">Here is a tutorial</a> to get you started on UFW.

An example setup is below (your IP address is `203.0.113.4` for example):

    $ sudo ufw allow 22
    $ sudo ufw allow from 203.0.113.4
    $ sudo ufw enable

As soon as you finish type in these commands, the firewall will be working. It lets anyone access port `22`, preventing locking yourself out of SSH in case you changed your own IP. It will only let `203.0.113.4` access the rest of the ports.

### Run a VPN (for Dynamic Client IP)

If your IP address changes often, configuring a firewall can be cumbersome. A good solution in this case is to run a VPN server on the host, which allows your client computer to share the same "local network" as the server.

Configuring a VPN is out of the scope of this document, and sometimes can be technically challenging.

<a href="https://www.wireguard.com/" target="_blank">WireGuard</a> is a good VPN yet simple to configure. You can try the <a href="https://wireguard.how/server/debian/" target="_blank">server tutorial</a> and for example the <a href="https://wireguard.how/client/macos/" target="_blank">macOS client tutorial</a> to get started.

### Change IB Account Trading Password Often

For automation to work, you must insert your account and password in the configuration file [`docker-compose.yml`](../getting-started/configuring.md). One security risk is that **if you rented a virtual server, the host/master server can access your files.**{: .text-red-200 }

Some would argue that Jeff Bezos is not interested in your $1000 account password. In reality, however, you would be surprised in a dev division, how many people technically have the privilege to inspect your files. In fact, inspecting files is also a security measure to detect hacking activities. Bots can collect your files and send elsewhere for performance analysis.

**The risk is real. And probably the only way to mitigate it is to change your password often.**{: .text-red-200 }

---

## VNC Password and a False Sense of Security

Setting a VNC password is [supported](config-args.md#IBGA_VNC_PASSWORD), but it gives you a false sense of security:

1. It protects the VNC server access but not the IB Gateway API socket port, which is open for public access. Any client who guessed the port can have unrestricted access to your account from IB API.
2. IBGA did not set up an SSL http server by default, which means when you enter the VNC password, a <a href="https://en.wikipedia.org/wiki/Packet_analyzer" target="_blank">network sniffing tool</a> could capture it.

Make sure you read [Running IBGA in an Internet Server](#running-ibga-in-an-internet-server) if you are trying to do so.
