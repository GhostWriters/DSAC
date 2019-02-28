# Welcome to DSAC!

[![Discord chat](https://img.shields.io/discord/477959324183035936.svg?logo=discord)](https://discord.gg/YFyJpmH) [![GitHub last commit](https://img.shields.io/github/last-commit/GhostWriters/DockSTARTer/master.svg)](https://github.com/GhostWriters/DSAC/commits/master) [![GitHub license](https://img.shields.io/github/license/GhostWriters/DockSTARTer.svg)](https://github.com/GhostWriters/DSAC/blob/master/LICENSE.md) [![Travis (.com) branch](https://img.shields.io/travis/com/GhostWriters/DSAC/master.svg?logo=travis)](https://travis-ci.com/GhostWriters/DSAC)

DSAC is your friend! DSAC is your buddy!  DSAC's ultimate goal is to give you all the proper configuration information for every selected application at install!

### What is DSAC?

DSAC is shorthand for DockSTARTer Application Configurator

### What DSAC is NOT?

DSAC will not replace DockSTARTer's configuration nor is it meant to. DSAC is an optional set of very specific configurations and tasks to make sure you have a turnkey and completely setup server!

### Why DSAC?

DSAC will help you through the tough and complex task of having a turnkey setup for your DockSTARTer.


It will assist with:
* Presenting you with a checklist of activities necessary.
* Error check you at critical steps and collect the information needed to continue.
* The ability to fill-in the configuration information necessary.
* Pushing that info into your DockSTARTer install.

### What to know about DSAC?

DSAC is still under heavy development and early users; expect there to be many bugs.

## Getting Started

### One Time Setup (required)

Do the following, and then see [DockSTARTer](https://github.com/GhostWriters/DSAC) for further usage details.

- APT Systems (Debian/Ubuntu/Raspbian/etc)

```bash
# NOTE: Ubuntu 18.10 is known to have issues with the installation process, 18.04 is recommended
sudo apt-get install curl git
bash -c "$(curl -fsSL https://ghostwriters.github.io/DSAC/main.sh)"
sudo reboot
```

- DNF Systems (Fedora)

```bash
sudo dnf install curl git
bash -c "$(curl -fsSL https://ghostwriters.github.io/DSAC/main.sh)"
sudo reboot
```

- YUM Systems (CentOS)

```bash
sudo yum install curl git
bash -c "$(curl -fsSL https://ghostwriters.github.io/DSAC/main.sh)"
sudo reboot
```

## Support

[![Discord chat](https://img.shields.io/discord/477959324183035936.svg?logo=discord)](https://discord.gg/YFyJpmH)

Click the chat badge to join us on Discord for support!

[[Feature Request](https://github.com/GhostWriters/DSAC/issues/new?template=feature_request.md)] [[Bug Report](https://github.com/GhostWriters/DSAC/issues/new?template=bug_report.md)]

## Contributors

[![GitHub contributors](https://img.shields.io/github/contributors/GhostWriters/DockSTARTer.svg)](https://github.com/GhostWriters/DSAC/graphs/contributors)

This project exists thanks to all the people who contribute.

## Help out!
Want to contribute? We created the develop.sh script to assist! Run the following and get started!
NOTE: This assumes that you have run one of the above from "One Time Setup"

```bash
curl -fsSL -o develop.sh https://ghostwriters.github.io/DSAC/.scripts/develop.sh
bash develop.sh -h
```

## Special Thanks

In addition to the special thanks found in https://github.com/GhostWriters/DockSTARTer we would also like to thank https://github.com/GhostWriters and all those involved in the DockSTARTer project!
