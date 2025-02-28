---
layout: post
title: "Setup Unbound as Hyperlocal Recursive DNS Server with Enhanced Debugging"
date:   2025-02-28
categories: servers
---

# Setting Up Unbound Hyperlocal DNS with Enhanced Debugging Capabilities

## Introduction
This guide will walk you through setting up an enhanced version of Unbound as a hyperlocal recursive DNS server using Docker. The setup includes detailed logging and debugging capabilities, making it easier to troubleshoot and maintain.

`wget https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/refs/heads/main/files/2025/working-fixed-unbound-script.sh`

## Overview of the Script
The script `[working-fixed-unbound-script.sh](https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/refs/heads/main/files/2025/working-fixed-unbound-script.sh)` automates the creation of necessary files and configurations for running Unbound in Docker. Here’s what each part of the script does:

### 1. **Create Necessary Directories**
   - The script creates a directory named `config` to store configuration files for Unbound.

### 2. **Create `docker-compose.yml`**
   - This file defines the service for running Unbound in Docker, specifying build context, container name, volumes, network mode, and environment variables.

### 3. **Create `Dockerfile`**
   - The Dockerfile specifies the base image (`mvance/unbound:latest`) and installs necessary packages like `curl`.
   - It also sets up scripts for updating root hints and modifies the entrypoint to enhance debugging and configuration validation.

### 4. **Create `update-root-hints.sh` Script**
   - This script downloads the latest root hints from the Internet and reloads Unbound configuration if the server is running.

### 5. **Create `entrypoint.sh` Script**
   - The entrypoint script performs several tasks:
     - Downloads fresh root hints.
     - Generates or updates the root trust anchor.
     - Checks for the existence of the configuration file.
     - Validates the Unbound configuration.
     - Starts Unbound with verbose logging.

### 6. **Create `unbound.conf` Configuration File**
   - This configuration file specifies various settings such as verbosity, interface details, security settings, DNSSEC configurations, and access controls.

### 7. **Download Initial Files**
   - The script downloads initial root hints and creates an empty `root.key` file with the correct permissions.

