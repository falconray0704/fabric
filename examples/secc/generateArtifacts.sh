#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -o errexit

#set -x
#set -e

CHANNEL_NAME=$1
: ${CHANNEL_NAME:="secc"}
echo $CHANNEL_NAME

export FABRIC_ROOT=$PWD/../..
export FABRIC_CFG_PATH=$PWD
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

## Using docker-compose template replace private key file names with constants
function replacePrivateKey () {
	echo
	echo "####################################################################"
	echo "##### Replace private key in docker-compose-e2e.yaml ###############"
	echo "####################################################################"

    #set -x
	ARCH=`uname -s | grep Linux`
	if [ "$ARCH" == "Linux" ]; then
		OPTS="-i"
	else
        exit 1
	fi

	cp docker-compose-e2e-template.yaml docker-compose-e2e.yaml

    CURRENT_DIR=$PWD
    cd crypto-config/peerOrganizations/org1.secc-sfo.com/ca/
    PRIV_KEY=$(ls *_sk)
    cd $CURRENT_DIR
    sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
    cd crypto-config/peerOrganizations/org2.secc-sfo.com/ca/
    PRIV_KEY=$(ls *_sk)
    cd $CURRENT_DIR
    sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
    #set +x
}

## Generates Org certs using cryptogen tool
function generateCerts (){
	CRYPTOGEN=$FABRIC_ROOT/release/$OS_ARCH/bin/cryptogen

	if [ -f "$CRYPTOGEN" ]; then
            echo "Using cryptogen -> $CRYPTOGEN"
	else
	    echo "Building cryptogen"
	    make -C $FABRIC_ROOT release
	fi

    rm -rf channel-artifacts/* crypto-config/*
	echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"
	$CRYPTOGEN generate --config=./crypto-config.yaml
	echo
}

function generateIdemixMaterial (){
	IDEMIXGEN=$FABRIC_ROOT/release/$OS_ARCH/bin/idemixgen
	CURDIR=`pwd`
	IDEMIXMATDIR=$CURDIR/crypto-config/idemix

	if [ -f "$IDEMIXGEN" ]; then
            echo "Using idemixgen -> $IDEMIXGEN"
	else
	    echo "Building idemixgen"
	    make -C $FABRIC_ROOT release
	fi

	echo
	echo "####################################################################"
	echo "##### Generate idemix crypto material using idemixgen tool #########"
	echo "####################################################################"

	mkdir -p $IDEMIXMATDIR
	cd $IDEMIXMATDIR

	# Generate the idemix issuer keys
	$IDEMIXGEN ca-keygen

	# Generate the idemix signer keys
	$IDEMIXGEN signerconfig -u OU1 -e OU1 -r 1

	cd $CURDIR
}

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {

	CONFIGTXGEN=$FABRIC_ROOT/release/$OS_ARCH/bin/configtxgen
	if [ -f "$CONFIGTXGEN" ]; then
            echo "Using configtxgen -> $CONFIGTXGEN"
	else
	    echo "Building configtxgen"
	    make -C $FABRIC_ROOT release
	fi

	echo "##########################################################"
	echo "#########  Generating Orderer Genesis block ##############"
	echo "##########################################################"
	# Note: For some unknown reason (at least for now) the block file can't be
	# named orderer.genesis.block or the orderer will fail to launch!
	#$CONFIGTXGEN -profile TwoOrgsOrdererGenesis -channelID e2e-orderer-syschan -outputBlock ./channel-artifacts/genesis.block
	$CONFIGTXGEN -profile TwoOrgsOrdererGenesis -channelID secc-orderer-syschan -outputBlock ./channel-artifacts/genesis.block

	echo
	echo "#################################################################"
	echo "### Generating channel configuration transaction 'channel.tx' ###"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

	echo
	echo "#################################################################"
	echo "#######    Generating anchor peer update for Org1MSP   ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

	echo
	echo "#################################################################"
	echo "#######    Generating anchor peer update for Org2MSP   ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
	echo
}

update_deployment_configuration_files()
{

	echo
	echo "#################################################################"
	echo "#######    Updating SECC deployment generation files ############"
	echo "#################################################################"
    rm -rf secc-111/e2e_cli/channel-artifacts  secc-111/e2e_cli/crypto-config
    rm -rf secc-113/e2e_cli/channel-artifacts  secc-113/e2e_cli/crypto-config
    rm -rf secc-114/e2e_cli/channel-artifacts  secc-114/e2e_cli/crypto-config
    rm -rf secc-115/e2e_cli/channel-artifacts  secc-115/e2e_cli/crypto-config
    rm -rf secc-116/e2e_cli/channel-artifacts  secc-116/e2e_cli/crypto-config

    cp -a channel-artifacts crypto-config secc-111/e2e_cli/
    cp -a channel-artifacts crypto-config secc-113/e2e_cli/
    cp -a channel-artifacts crypto-config secc-114/e2e_cli/
    cp -a channel-artifacts crypto-config secc-115/e2e_cli/
    cp -a channel-artifacts crypto-config secc-116/e2e_cli/

    #######################################################################
	ARCH=`uname -s | grep Linux`
	if [ "$ARCH" == "Linux" ]; then
		OPTS="-i"
	else
        exit 1
	fi

	#echo "#################################################################"
	echo "#######    Updating SECC secc-111/e2e_cli/docker-compose-ca.yaml ############"
    set -x
    pushd crypto-config/peerOrganizations/org1.secc-sfo.com/ca
    PRIV_KEY=$(ls *_sk)
    popd
    pushd secc-111/e2e_cli
    cp docker-compose-ca-template.yaml docker-compose-ca.yaml
    sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-ca.yaml
    popd
    set +x

    echo
}

generateCerts
generateIdemixMaterial
replacePrivateKey
generateChannelArtifacts
update_deployment_configuration_files
