#!/bin/bash
TARGET=$1
if [ $# -lt 1 ]
  then
    printf "Must specify the target URL, e.g.\\n  ./setDeploymentTarget.sh https://admin:password@cococloud.co/zanzibar\\n"
    exit
fi
echo "Setting global.pouchdb in app/start/coffee to use $TARGET"
sed "s#global.pouchdb = .*#global.pouchdb = new PouchDB('$TARGET')#" app/start.coffee > /tmp/start.coffee; cp /tmp/start.coffee app/start.coffee
