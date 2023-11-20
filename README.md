# AutomateAPI
Latest Tested Versions (as of 2023-11-15):
| Automate | Extension | ScreenConnect | Plugin |
| :---: | :---: | :---: | :---: |
| v23.0.9.392  | v4.4.0.2 | v23.6.8.8644 | v7.1.23001.13 |

Note: A Partner "ClientID" token is needed with Automate 20 Patch 11 and above. See https://developer.connectwise.com/ClientID

# Features
1) Get, search and return PowerShell objects for pre-defined searches or custom conditions using Get-AutomateComputer. See https://github.com/gavsto/AutomateAPI/wiki/Get-AutomateComputer

2) Identify agents that are online in Control and offline in Automate. See https://github.com/gavsto/AutomateAPI/wiki/Autofix-Broken-Agents

3) Autofix agents that are broken using Repair-AutomateAgent. See https://github.com/gavsto/AutomateAPI/wiki/Autofix-Broken-Agents

4) New - Invoke-AutomateCommand, used like this Get-AutomateComputer -ComputerId 1 | Invoke-AutomateCommand -PowerShell -Command "Get-Service"

A PowerShell Module created by Gavin Stone (Gavsto) for the ConnectWise Automate API

# How do I get Going
See https://github.com/gavsto/AutomateAPI/wiki/Pre-requisites-and-Install

Then https://github.com/gavsto/AutomateAPI/wiki/Getting-Started-and-Connected

Then https://github.com/gavsto/AutomateAPI/wiki/Get-AutomateComputer

If you're interested in repairing broken agents https://github.com/gavsto/AutomateAPI/wiki/Autofix-Broken-Agents

# I want to help
Great - dig in and submit a pull request! Please make sure your follow the conventions set by the other modules. Write documentation for functions, support pipeline input where required etc.

# Significant Contributions

**Darren White** for his pre-input, ongoing code support with the code and then his extensive support in helping me get the Control portions of this module down from 10 minutes to 25 seconds per 2500 PCs. You are definitely a legend, Darren.

# Special Thanks
Special thanks to a number of people whose help (and in certain cases code) I have used within this project

**Chris Taylor** where I have re-used and modified certain parts of the ConnectWise Control module to send commands to Control and his ConnectWise Automate module so we can reinstall services

**Mendy Green** for helping me test the initial code

**Davíð Snædal** for his assistance before this module even started with guidance on connection to the Automate REST APIs

**ConnectWise** for absolutely smashing the delivery of their API

