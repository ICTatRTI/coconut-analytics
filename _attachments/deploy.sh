#!/bin/bash

echo "Did you kill the npm run start process, otherwise you will get a corrupt bundle.js!"

read justareminder


echo 'Browserifying and uglifying'
./node_modules/browserify/bin/cmd.js -v -t coffeeify --extension='.coffee' app/start.coffee | ./node_modules/uglify-js/bin/uglifyjs > bundle.js

rsync --progress --recursive --exclude=node_modules ./ keep.cococloud.co:/var/www/analytics/

TARGETWITHPASSWORD=$1
if [ $# -lt 1 ]
  then
    printf "Must specify the URL with username/password to update views, e.g.\\n  ./deploy.sh https://admin:password@cococloud.co/zanzibar\\n"
    exit
fi

echo "Did you kill the npm run start process, otherwise you will get a corrupt bundle.js!"

CREDENTIALS=$(echo $TARGETWITHPASSWORD | cut -f1 -d@ | cut -f 3 -d/)
TARGETNOCREDENTIALS=$(echo $TARGETWITHPASSWORD | sed "s/$CREDENTIALS@//")
DATABASE=$(echo $TARGETWITHPASSWORD | rev | cut -f1 -d/ | rev)
TARGETNODATABASE=$(echo $TARGETWITHPASSWORD | sed "s/\(.*\)$DATABASE/\1/")

<<<<<<< HEAD
=======
#./setDeploymentTarget.sh $TARGETNOCREDENTIALS
echo 'Browserifying and uglifying'
./node_modules/browserify/bin/cmd.js -v -t coffeeify --extension='.coffee' app/start.coffee | ./node_modules/uglify-js/bin/uglifyjs > bundle.js
#echo "Couchapp pushing to $TARGETWITHPASSWORD"
#couchapp push --verbose $TARGETWITHPASSWORD

rsync --progress --recursive --exclude=node_modules ./ keep.cococloud.co:/var/www/analytics/

>>>>>>> d251b87cb1610fda6338ea35223f49ed8a4ca49d
echo "Pushing all required views to $TARGETNODATABASE $DATABASE"
cd ../__views
ruby ./pushViews.rb $TARGETNODATABASE $DATABASE
echo 'Executing (caching) all required views'
coffee executeViews.coffee $TARGETNOCREDENTIALS
