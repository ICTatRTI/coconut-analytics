#! /usr/bin/env ruby
#
#


STDERR.puts "DEPRECATED - use coffee version instead"
return

require 'rubygems'
require 'couchrest'
require 'json'

#@db = CouchRest.new(ARGV[0]).database!(ARGV[1])

#Get all .coffee files
Dir.glob("*.coffee").each do |view|
  next unless view.match(/__reduce/).nil?
  next if view == "executeViews.coffee"
  next if view == 'runTests.coffee'
  puts view

  view_name = view.sub(/\.coffee/,"")
  document_id = "_design/#{view_name}"
  map = File.read(view)

  local_view_doc = {
    "_id" => document_id, 
    "language" => "coffeescript",
    :views => {
      "#{view_name}" => {
        :map => map
        }
      }
  }

  reduce_file = view.sub(/\.coffee/,"__reduce.coffee")
  if File.exist? reduce_file
    reduce = File.read(view.sub(/\.coffee/,"__reduce.coffee"))
    local_view_doc[:views][view_name][:reduce] = reduce
  end

  puts local_view_doc

  # Look for something like this to specify the database
  # db:wusc-people
  match = map.match(/^.*db:(.*)/)
  database_name = $1 if match
  db = CouchRest.new(ARGV[0]).database!(database_name)
  begin
    db_view_doc = db.get(document_id)
    local_view_doc["_rev"] = db_view_doc["_rev"] if db_view_doc
  rescue
  end
    
  #puts local_view_doc.to_json
  puts "Saving view #{view} in #{database_name}"

  db.save_doc(local_view_doc)

end

