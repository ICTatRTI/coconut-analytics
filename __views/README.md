This directory holds couchdb map/reduce views. The couchapp utility puts all views in the same design document. This is not a good idea, since any change to any view requires all views to be rebuilt. Better to have each view in it's own design document. See this:

https://pouchdb.com/2014/06/17/12-pro-tips-for-better-code-with-pouchdb.html

That is the strategy employed here.

Create a new view by creating a .coffee file in this directory. Each file be turned into a design doc and view when you run 

    ./pushViews.rb databaseTarget

(Note: the url is in quotes followed by the db name)
For instance if the file

docIDsForUpdating.coffee

is here. Then running:
    ./pushViews.rb "http://localhost:5984" mydb
    
will create a design doc called docIdsForUpdating in the mydb database with a view called docIdsForUpdating. You could then access it by going to:

http://localhost:5984/mydb/_design/docIdsForUpdating/_view/docIdsForUpdating

If you also want to include a reduce function, just create a file with the same name as the associated map, but add __reduce at the end. For example:

results_by_question_set_and_date.coffee
results_by_question_set_and_date__reduce.coffee

Inside of the file you can define the reduce function, for example to use the built in couchdb count function, just put this:

_count
