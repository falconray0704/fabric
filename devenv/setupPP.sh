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

# Pull docker image for integration test
docker pull hyperledger/fabric-javaenv:latest

