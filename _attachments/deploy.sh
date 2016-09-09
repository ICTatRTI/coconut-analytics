#!/bin/bash
TARGET=$1
PUSHTARGET=$2
if [ $# -lt 2 ]
  then
    printf "Must specify the URL as well as a URL with username/password, e.g.\\n  ./deploy.sh http://cococloud.co/zanzibar http://admin:password@cococloud.co/zanzibar\\n"
    exit
fi
echo "Replacing http://localhost:5984/zanzibar in app/start/coffee to use $TARGET"
sed "s#http://localhost:5984/zanzibar#$TARGET#" app/start.coffee > /tmp/start.coffee; cp /tmp/start.coffee app/start.coffee
echo 'Browserifying and uglifying'
./node_modules/browserify/bin/cmd.js -v -t coffeeify --extension='.coffee' app/start.coffee | ./node_modules/uglifyjs/bin/uglifyjs > bundle.js
echo 'Couchapp pushing'
couchapp push $PUSHTARGET
