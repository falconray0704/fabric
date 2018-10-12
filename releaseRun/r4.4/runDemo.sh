#!/bin/bash


set -x

set -o nounset
set -o errexit

ROOT_HL="/hyperledger"

PATH_EXE="/hyperledger/fabric/releaseRun"

ROOT_RUN="/hyperledger/runEnv"
NAME_RUN="r4.4"
HOME_RUN=${ROOT_RUN}/${NAME_RUN}
ROOT_CFG=${HOME_RUN}/fabricconfig

ROOT_ORDER_CFG=${HOME_RUN}/order

generate_fabric_configs()
{
    mkdir -p ${HOME_RUN}
    cp -a ${ROOT_HL}/release/linux-amd64/bin ${HOME_RUN}/

    pushd ${HOME_RUN}

    rm -rf ${ROOT_CFG}
    mkdir -p ${ROOT_CFG}
    pushd ${ROOT_CFG}

    export PATH=$PATH:${HOME_RUN}/bin
    #rm -rf ./crypto-config
    #mkdir -p ${NAME_RUN}
    #cryptogen showtemplate > ${NAME_RUN}/crypto-config.yaml
    cp ${PATH_EXE}/${NAME_RUN}/crypto-config.yaml ./
    cryptogen generate --config=crypto-config.yaml --output ./crypto-config
    tree ./crypto-config
    #tree -L 5

    popd

    popd
}

generate_init_configs()
{
    rm -rf ${ROOT_ORDER_CFG}
    mkdir -p ${ROOT_ORDER_CFG}
    # cp -r ${ROOT_HL}/fabric/sampleconfig/configtx.yaml ${ROOT_ORDER_CFG}

    pushd ${ROOT_ORDER_CFG}

    # generate system init block
    cp ${PATH_EXE}/${NAME_RUN}/configtx.yaml ./
    export PATH=$PATH:${HOME_RUN}/bin
    configtxgen --configPath ${ROOT_ORDER_CFG} -profile TestTwoOrgsOrdererGenesis -outputBlock ./orderer.genesis.block
    ls -al ./orderer.genesis.block

    # generate ledger(channel) file
    #configtxgen --configPath ${ROOT_ORDER_CFG} -profile TestTwoOrgsChannel -outputCreateChannelTx ./roberttestchannel.tx -channelID robertestchannel
    #ls -al ./robertestchannel.tx

    # generate anchor file
    configtxgen --configPath ${ROOT_ORDER_CFG} -profile TestTwoOrgsChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID robertestchannel -asOrg Org1MSP
    #configtxgen --configPath ${ROOT_ORDER_CFG} -profile TestTwoOrgsChannel -outputAnchorPeersUpdate ./Org2MSPanchors.tx -channelID robertestchannel -asOrg Org2MSP
    ls -al ./*anchors.tx

    popd
}

case $1 in
    genCfgs) echo "Generating fabric configs..."
        generate_fabric_configs
        ;;
    genInitCfgs) echo "Generating fabric init configs..."
        generate_init_configs
        ;;
    -h|*) echo "Unknow commands!"
        echo "Supported commands:"
        echo "genCfgs"
        echo "genInitCfgs"
esac



