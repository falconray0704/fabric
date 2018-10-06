#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -o nounset
set -o errexit

set -e
set -x

# Install docker
sudo usermod -a -G docker $USER # Add ubuntu user to the docker group

# Set Go environment variables needed by other scripts
export GOPATH="/opt/gopath"
export GOROOT="/opt/go"
PATH=$GOROOT/bin:$GOPATH/bin:$PATH

sudo chown -R $USER:$USER $GOROOT

# Create directory for the DB
sudo mkdir -p /var/hyperledger
sudo chown -R $USER:$USER /var/hyperledger

# Ensure permissions are set for GOPATH
sudo chown -R $USER:$USER $GOPATH

echo "Reboot VM before continue..."

