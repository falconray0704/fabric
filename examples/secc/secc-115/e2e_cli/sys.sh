#!/bin/bash

set -o nounset
set -o errexit
# trace each command execute, same as `bash -v myscripts.sh`
#set -o verbose
# trace each command execute with attachment infomations, same as `bash -x myscripts.sh`
#set -o xtrace


case $1 in
    up) echo "SECC 113 starting..."
        docker-compose -f docker-zk.yaml up --force-recreate -d
        docker-compose -f docker-kafka.yaml up --force-recreate -d
        docker-compose -f docker-compose-peer.yaml up --force-recreate -d

        docker ps -a
        ;;
    down) echo "SECC 113 stopping..."
        docker-compose -f docker-compose-peer.yaml down --remove-orphans
        docker-compose -f docker-kafka.yaml down --remove-orphans
        docker-compose -f docker-zk.yaml down --remove-orphans

        docker ps -a
        ;;
    *) echo "Unknow command"
        ;;
esac



