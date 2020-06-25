TO GET A DEV ENV WORKING:


Run ./bundleCss.sh to generate the css bundle

To create vendor.min.js (this makes incremental builds much faster) do this:

npx browserify  -r moment -r jquery -r backbone -r pouchdb-core -r pouchdb-adapter-http -r pouchdb-mapreduce -r pouchdb-upsert -r underscore -r tabulator-tables | npx terser > vendor.min.js


The run:

npm run start

