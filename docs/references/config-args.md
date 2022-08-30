---
layout: default
title: Configuration Arguments
description: IBGA configuration arguments in Docker Compose style
parent: References
nav_order: 1
---

# IBGA Configuration Arguments

This section discusses IBGA-specific `IB_*` arguments (in fact, environment variables). For the basics of a Docker Compose configuration, including mechanisms such as `volumes`, `ports`, `restart`, refer to [Docker Basics](docker-basics.md). 

IBGA uses <a href="https://en.wikipedia.org/wiki/Environment_variable" target="_blank">environment variables</a> to pass configuration arguments to the scripts in the container.

| `IB_USERNAME`* | The username of your IB account |
| `IB_PASSWORD`* | The password of your IB account |
| `IB_REGION` | The "Region" combo box in the login window after clicking "More Options".<br>Available choices: `America`, `Europe`, `Asia`, `China`. |
| `IB_TIMEZONE`* | The "Time Zone" combo box in the login window after clicking "More Options".<br>IBG will shut down or restart daily. "Time Zone" is an important setting that governs not only how to interpret the "Log Off/Restart" time, but also the current time reported by the API. For a list of possible values, please refer to the "TZ database name" column in the <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List">time zone database</a>. |
| `IB_LOGINTAB`* | The "Login Tab", otherwise shown as "API Type". Available choices are either `IB API` or `FIX CTCI`. |
| `IB_LOGINTYPE`* | The "Login Type", otherwise shown as "Trading Mode". Available choices are either `Paper Trading` or `Live Trading`. |
| `IB_LOGOFF`* | The **"Auto Logoff Timer"** in **Configuration/Lock** and Exit in the **Configure/Settings** dialog. IB Gateway will shut down daily, at the clock time in the format of `HH:MM A/PM` specified by this argument. IBGA will open up the corresponding dialog after login to match the settings. It will also stick to "Auto logoff" instead of "Auto restart" because IBGA has automatic restarts built-in, and "Auto logoff" is easier to control. |
| `IB_APILOG` | Whether to check **"Create API message log file"** in **Configuration/API/Settings** in the **Configure/Settings** dialog. Omitting this variable will leave the checkbox unchecked. Setting it to any value (`true` for example) will leave it checked. If set to `data`, it will also check **"Included market data in API log file"**. |
| `IB_LOGLEVEL` | The **"Logging Level"** in **Configuration/API/Settings** in the **Configure/Settings** dialog. Available choices are `System`, `Error`, `Warning`, `Info`, and `Detail`. IB technical support typically needs you to provide a `Detail` log if you were to ask for assistance with your API programming. |
| <a name="IBGA_VNC_PASSWORD">`IBGA_VNC_PASSWORD`</a> | Set a password for VNC. The length of the password is between 1-8 characters. If more than 8 are provided, it will get truncated. **Setting a VNC password is not an adequate measure to prevent unwanted access. For more information, please refer to [Security](security.md#vnc-password-and-a-false-sense-of-security).** |
| <a name="IBGA_EXPORT_LOGS">`IBGA_EXPORT_LOGS`</a> | When set to `true`, IBGA will export today's and yesterday's Gateway and API logs to the location specified by `IBGA_LOG_EXPORT_DIR`. |
| <a name="IBGA_LOG_EXPORT_DIR">`IBGA_LOG_EXPORT_DIR`</a> | Specify the container-aspect directory to export logs into. When this variable is not set, IBGA will use a subdirectory of the settings dir `/home/ibg_settings/exported_logs`. |

Arguments marked with an asterisk symbol (*) are required.

Note that you must write the exact value for text arguments. For instance, `IB_LOGINTAB=IB API` will work. But `IB_LOGINTAB=IBAPI` or `IB_LOGINTAB=ib api` will not. Moreover, IB Gateway starts in the English language setting by default, which you should retain. Internal IBGA scripts read UI component and distinguish one button from another based on the text. The scripts only recognize English.

Some environment variables (namely `IBG_DIR`, `IBG_SETTINGS_DIR`, `IBG_PORT_INTERNAL`, `IBG_PORT`, and `IBG_DOWNLOAD_URL`, not listed in the table above) determine how IBGA works internally. They support overriding via Docker Compose configurations. That is, they come with a default value suitable for common usage. But you get to customize how the container works if you need to control how a particular aspect works. Please refer to the source code of [_env.sh](https://github.com/heshiming/ibga/blob/master/scripts/_env.sh) for details.
