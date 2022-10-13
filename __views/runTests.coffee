# Test
#
#

CoffeeScript = require 'coffeescript'
fs = require('fs')

results = []
emit = (a,b) =>
  results.push [a,b]

#
# performanceByYearTermRegionSchoolClassStreamLearner.coffee
#

# Get the map function and set it equal to mapFunction
#
###
map = fs.readFileSync('./performanceByYearTermRegionSchoolClassStreamLearner.coffee', 'utf8')
eval ("mapFunction = #{CoffeeScript.compile(map, {bare:true})}")

testDoc = require './enrollment1.json'
mapFunction(testDoc)
console.log results
###

map = fs.readFileSync('./attendancePerformanceByYearTermRegionSchoolClassStreamLearner.coffee', 'utf8')
eval ("mapFunction = #{CoffeeScript.compile(map, {bare:true})}")
testDoc = require './person1.json'
mapFunction(testDoc)
console.log results
#
###
map = fs.readFileSync('./followupsByRelevantUsers.coffee', 'utf8')
eval ("mapFunction = #{CoffeeScript.compile(map, {bare:true})}")
testDoc = require './followup1.json'
mapFunction(testDoc)
console.log results
map = fs.readFileSync('./peopleNeedingFollowup.coffee', 'utf8')
eval ("mapFunction = #{CoffeeScript.compile(map, {bare:true})}")
testDoc = require './person1.json'
mapFunction(testDoc)
console.log results
###
