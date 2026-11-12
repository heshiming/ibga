---
layout: single
title: "IBGA Reference"
excerpt: "IBGA reference: configuration arguments and security guide."
sidebar:
  title: "Documentation"
  nav: docs
redirect_from:
  - /references/
  - /references/config-args.html
  - /references/security.html
---

## IBGA Configuration Arguments

This section discusses IBGA-specific `IB_*` arguments (in fact, environment variables). For the basics of a Docker Compose configuration, including mechanisms such as `volumes`, `ports`, `restart`, refer to [Docker Compose Basics](../guide/#docker-compose-basics). 

IBGA uses <a href="https://en.wikipedia.org/wiki/Environment_variable" target="_blank">environment variables</a> to pass configuration arguments to the scripts in the container.

| `IB_USERNAME`* | The username of your IB account |
| `IB_PASSWORD`* | The password of your IB account |
| `IB_REGION` | The "Region" combo box in the login window after clicking "More Options".<br>Available choices: `America`, `Europe`, `Asia`, `China`. |
| `IB_TIMEZONE`* | The "Time Zone" combo box in the login window after clicking "More Options".<br>IBG will shut down or restart daily. "Time Zone" is an important setting that governs not only how to interpret the "Log Off/Restart" time, but also the current time reported by the API. For a list of possible values, please refer to the "TZ database name" column in the <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List">time zone database</a>. |
| `IB_LOGINTAB`* | The "Login Tab", otherwise shown as "API Type". Available choices are either `IB API` or `FIX CTCI`. |
| `IB_LOGINTYPE`* | The "Login Type", otherwise shown as "Trading Mode". Available choices are either `Paper Trading` or `Live Trading`. |
| `IB_LOGOFF`* | The **"Auto Logoff Timer"** in **Configuration/Lock** and Exit in the **Configure/Settings** dialog. IB Gateway will shut down daily, at the clock time in the format of `HH:MM A/PM` specified by this argument. IBGA will open up the corresponding dialog after login to match the settings. It will also stick to "Auto logoff" instead of "Auto restart" because IBGA has automatic restarts built-in, and "Auto logoff" is easier to control. |
| `IB_READONLY` | Whether to check **"Read-Only API"** in **Configuration/API/Settings** in the **Configure/Settings** dialog. Omitting this variable (or setting it to `false`, `no`, or `n`) will leave the checkbox unchecked, which is required for placing orders. Setting it to `true`, `yes`, or `y` will leave it checked. |
| `IB_APILOG` | Whether to check **"Create API message log file"** in **Configuration/API/Settings** in the **Configure/Settings** dialog. Omitting this variable will leave the checkbox unchecked. Setting it to any value (`true` for example) will leave it checked. If set to `data`, it will also check **"Included market data in API log file"**. |
| `IB_LOGLEVEL` | The **"Logging Level"** in **Configuration/API/Settings** in the **Configure/Settings** dialog. Available choices are `System`, `Error`, `Warning`, `Info`, and `Detail`. IB technical support typically needs you to provide a `Detail` log if you were to ask for assistance with your API programming. |
| <a name="IBGA_VNC_PASSWORD">`IBGA_VNC_PASSWORD`</a> | Set a password for VNC. The length of the password is between 1-8 characters. If more than 8 are provided, it will get truncated. **Setting a VNC password is not an adequate measure to prevent unwanted access. For more information, please refer to [Security](#vnc-password-and-a-false-sense-of-security).** |
| <a name="IBGA_EXPORT_LOGS">`IBGA_EXPORT_LOGS`</a> | When set to `true`, IBGA will export today's and yesterday's Gateway and API logs to the location specified by `IBGA_LOG_EXPORT_DIR`. |
| <a name="IBGA_LOG_EXPORT_DIR">`IBGA_LOG_EXPORT_DIR`</a> | Specify the container-aspect directory to export logs into. When this variable is not set, IBGA will use a subdirectory of the settings dir `/home/ibg_settings/exported_logs`. |
| <a name="IB_PREFER_IBKEY">`IB_PREFER_IBKEY`</a> | Set to "true" to allow automatic selection of "IB Key" when there are multiple choices of two-factor authentication devices. |
| <a name="TOTP_KEY">`TOTP_KEY`</a> | [Automate TOTP (Mobile Authenticator App) login.](../guide/#how-to-setup-totp-mobile-authenticator-app-automated-login) |
| <a name="IBGA_RECONNECT_INTERVAL">`IBGA_RECONNECT_INTERVAL`</a> | How often (in seconds) IBGA checks whether the gateway is stuck on the **"EXISTING SESSION DETECTED"** dialog and automatically clicks **"Reconnect This Session"** to recover. Defaults to `0` (disabled). Set to a positive number of seconds (e.g. `600` for 10 minutes) to enable the check. |

Arguments marked with an asterisk symbol (\*) are required.

Note that you must write the exact value for text arguments. For instance, `IB_LOGINTAB=IB API` will work. But `IB_LOGINTAB=IBAPI` or `IB_LOGINTAB=ib api` will not. Moreover, IB Gateway starts in the English language setting by default, which you should retain. Internal IBGA scripts read UI component and distinguish one button from another based on the text. The scripts only recognize English.

Some environment variables (namely `IBG_DIR`, `IBG_SETTINGS_DIR`, `IBG_PORT_INTERNAL`, `IBG_PORT`, and `IBG_DOWNLOAD_URL`, not listed in the table above) determine how IBGA works internally. They support overriding via Docker Compose configurations. That is, they come with a default value suitable for common usage. But you get to customize how the container works if you need to control how a particular aspect works. Please refer to the source code of [_env.sh](https://github.com/heshiming/ibga/blob/master/scripts/_env.sh) for details.

## Security

#### Running IBGA in an Internet Server

**Not recommended.** IBGA is not designed to run on a public server. The default security is not hardened enough to get you full protection against malicious clients and hacking attempt. Although if you have to host it on the Internet, there are still measures to follow for stronger security on the host server.

##### Configure Key-based Authentication for SSH

Chances are your host server is Linux-based if you buy one. For Linux, the first security measure you should take, is to <a href="https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server" target="_blank">configure key-based authentication for SSH</a> (instead of password-based).

##### Configure Firewall with UFW (for Static Client IP)

<a href="https://en.wikipedia.org/wiki/Uncomplicated_Firewall" target="_blank">UFW (or Uncomplicated Firewall)</a> is the simplest way to get your host server protected with a firewall. It lets you create rules so that the IBGA ports are exposed only to your IP. <a href="https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-18-04" target="_blank">Here is a tutorial</a> to get you started on UFW.

An example setup is below (your IP address is `203.0.113.4` for example):

    $ sudo ufw allow 22
    $ sudo ufw allow from 203.0.113.4
    $ sudo ufw enable

As soon as you finish type in these commands, the firewall will be working. It lets anyone access port `22`, preventing locking yourself out of SSH in case you changed your own IP. It will only let `203.0.113.4` access the rest of the ports.

##### Run a VPN (for Dynamic Client IP)

If your IP address changes often, configuring a firewall can be cumbersome. A good solution in this case is to run a VPN server on the host, which allows your client computer to share the same "local network" as the server.

Configuring a VPN is out of the scope of this document, and sometimes can be technically challenging.

<a href="https://www.wireguard.com/" target="_blank">WireGuard</a> is a good VPN yet simple to configure. You can try the <a href="https://wireguard.how/server/debian/" target="_blank">server tutorial</a> and for example the <a href="https://wireguard.how/client/macos/" target="_blank">macOS client tutorial</a> to get started.

##### Change IB Account Trading Password Often

For automation to work, you must insert your account and password in the configuration file [`docker-compose.yml`](../guide/#an-example-docker-compose-configuration-file). One security risk is that **if you rented a virtual server, the host/master server can access your files.**

Some would argue that Jeff Bezos is not interested in your $1000 account password. In reality, however, you would be surprised in a dev division, how many people technically have the privilege to inspect your files. In fact, inspecting files is also a security measure to detect hacking activities. Bots can collect your files and send elsewhere for performance analysis.

**The risk is real. And probably the only way to mitigate it is to change your password often.**

#### VNC Password and a False Sense of Security

Setting a VNC password is [supported](#IBGA_VNC_PASSWORD), but it gives you a false sense of security:

1. It protects the VNC server access but not the IB Gateway API socket port, which is open for public access. Any client who guessed the port can have unrestricted access to your account from IB API.
2. IBGA did not set up an SSL http server by default, which means when you enter the VNC password, a <a href="https://en.wikipedia.org/wiki/Packet_analyzer" target="_blank">network sniffing tool</a> could capture it.

Make sure you read [Running IBGA in an Internet Server](#running-ibga-in-an-internet-server) if you are trying to do so.
