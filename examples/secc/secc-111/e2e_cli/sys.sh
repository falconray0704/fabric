#!/bin/bash

set -o nounset
set -o errexit
# trace each command execute, same as `bash -v myscripts.sh`
#set -o verbose
# trace each command execute with attachment infomations, same as `bash -x myscripts.sh`
#set -o xtrace


case $1 in
    up) echo "SECC 111 starting..."
        docker-compose -f docker-compose-ca.yaml up --force-recreate -d
        docker-compose -f docker-compose-orderer.yaml up --force-recreate -d
        docker ps -a
        ;;
    down) echo "SECC 111 stopping..."
        docker-compose -f docker-compose-ca.yaml down --remove-orphans
        docker-compose -f docker-compose-orderer.yaml down --remove-orphans
        docker ps -a
        ;;
    *) echo "Unknow command"
        ;;
esac



