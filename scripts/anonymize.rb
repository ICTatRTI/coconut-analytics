require 'rubygems'
#require 'restclient'
require 'couchrest'
require 'pp'
require 'date'
require 'yaml'

#RestClient.log = 'stdout'

@db = CouchRest.database("http://admin:password@localhost:5984/coconut-surveillance-zanzibar")
#@db = CouchRest.database("http://cococloud.co/zanzibar")
#
@db.bulk_save_cache_limit = 100

def randomizeLocation(result)
  # Should shift within about 2km (changed to be less than that, not sure how much though)
  result["HouseholdLocation-latitude"] = (result["HouseholdLocation-latitude"].to_f + Random.rand(-0.001..0.001)).to_s
  result["HouseholdLocation-longitude"] = (result["HouseholdLocation-longitude"].to_f + Random.rand(-0.001..0.001)).to_s
  result
end

$identifying_attributes = [
  "Name",
  "name",
  "FirstName",
  "MiddleName",
  "LastName",
  "ContactMobilepatientrelative",
  "HeadofHouseholdName",
  "ShehaMjumbe"
]

$names="Loyd 
Lionel
Quinn
Joye
Suanne
Iliana
Emily
Eneida
Cristy
Cyndi
Cynthia
Nicola
Theresa 
Latashia 
Neil 
Krysten 
Leonard 
Anh
Sari
Trish
Tamar
Glynis
Desirae
Sherman
Kymberly
Margori
Garre
Barabara
Una
Shiela
Shizue
Kristy
Marianne
Malisa
Alba
Sebrina
Gale
Tova
Joelle
Rhett
Lael
Babette
Domonique
Kelsie
Meagan
India
Bao
Asia
Corazon
Sarita
Chere
Luz
Shira
Krystyna
Danita
Jess
Jorge
Kerstin
Alva
Peggie
Dede
Stefani
Rosenda
Vita
Salley
Piper
Florida
Bernardo
Kyle
Nichol
Isaias
Lydia
Sean
Nancee
Ardella
Donita
Columbus
Alfredia
Kacey
Vickey
Dorotha
Lilian
Macie
Eloy
Elene
Hilma
Peg
Mavis
Dorethea
Dollie
Tommy
Valrie
Leroy
Marlo
Andy
Elly
Josie
Alexandra
Shanell
Tiesha".split("\n").map{|name|name.upcase}

def fixIdentifyingAttributes(result, days_to_shift)
  changed = false

  if not result["deidentified"]
    $identifying_attributes.each do |identifying_attribute|
      if result[identifying_attribute]
        if identifying_attribute == "ContactMobilepatientrelative"
          result[identifying_attribute] = "07" + rand(5 ** 5).to_s.rjust(5,'0')
        else
          result[identifying_attribute] = result[identifying_attribute] = $names.sample
        end
        print "i"
        changed = true
        result["deidentified"] = true
      end
    end
  end

  if result["HouseholdLocation-latitude"] and not result["location_shifted"]
    result = randomizeLocation(result)
    print "l"
    changed = true
    result["location_shifted"] = true
  end

  if not result["date_shifted"]
    [
      "date",
      "createdAt",
      "lastModifiedAt",
      "DateofPositiveResults",
      "DateOfPositiveResults"
    ].each do |dateField|
      if result[dateField]
        print "#{dateField} was #{result[dateField]} and is now: "
        result[dateField] = DateTime.parse(result[dateField]) + days_to_shift
        if result[dateField].minute == 0 and result[dateField].hour == 0
          result[dateField] = result[dateField].strftime("%Y-%m-%d")
        else
          result[dateField] = result[dateField].strftime("%Y-%m-%d %H:%M:%S")
        end
        puts result[dateField]
        print "d"
        changed = true
        result["date_shifted"] = true
      end
    end
  end

  if changed
    @db.bulk_save_doc(result)
  end


  # TODO year, week for notifications

end

def filter_for_2013_2016
  if @db.get("filtered_for_2013_2016_data")
    puts "Database already filtered"
  else
    # Remove everything beside 2013-2015
    #puts @db.view('caseIDsByDate/caseIDsByDate?startKey="2010"&endKey="2012-12-31"')['rows'][0]
    puts "Removing case data before 2012-12-31"
    @db.view('zanzibar/caseIDsByDate', {:endkey=>"2013", :include_docs=>true, :inclusive_end=>true})['rows'].each do |row|
      #print "-"
      puts row["key"]
      @db.delete_doc({"_id" => row["id"], "_rev" => row["doc"]["_rev"]}, true)
    end

    puts "Removing case data after 2016-01-01"
    @db.view('zanzibar/caseIDsByDate', {:startkey=>"2016", :include_docs => true})['rows'].each do |row|
      #print "+"
      puts row["key"]
      @db.delete_doc({"_id" => row["id"], "_rev" => row["doc"]["_rev"]}, true)
    end

    puts "Removing weekly data before 2012-12-31"
    @db.view('weeklyDataBySubmitDate/weeklyDataBySubmitDate', {:endkey=>["2013"], :include_docs => true, :inclusive_end=>true, :reduce => false})['rows'].each do |row|
      #print "+"
      puts row["key"]
      @db.delete_doc({"_id" => row["id"], "_rev" => row["doc"]["_rev"]}, true)
    end

    puts "Removing weekly data after 2016-01-01"
    @db.view('weeklyDataBySubmitDate/weeklyDataBySubmitDate', {:startkey=>["2016"], :include_docs => true, :reduce => false})['rows'].each do |row|
      #print "+"
      puts row["key"]
      @db.delete_doc({"_id" => row["id"], "_rev" => row["doc"]["_rev"]}, true)
    end


    puts "Removing all case_summary docs (need to rebuild)"
    @db.all_docs({:startkey => "case_summary_", :endkey => "case_summary_zz"})['rows'].each{ |row|
      print "."
      @db.delete_doc({"_id" => row["id"], "_rev" => row["value"]["rev"]}, true) unless row.nil?
    }

    puts "Saving: " + @db.bulk_save().to_yaml

  end


end

filter_for_2013_2016()
filter_for_2013_2016()
filter_for_2013_2016() # Not sure why I have to do this multiple times but a few get left out
@db.save_doc('_id' => "filtered_for_2013_2016_data") unless @db.get("filtered_for_2013_2016_data")

days_to_shift = (DateTime.now - DateTime.parse(@db.view("zanzibar/caseIDsByDate", {:limit => 1, :descending => true})['rows'][0]["key"])).to_i

puts "Fixing identifying attributes and shifting dates by #{days_to_shift}"
@db.view('zanzibar/caseIDsByDate?include_docs=true')['rows'].map{|row|row["doc"]}.each do |doc|
  fixIdentifyingAttributes(doc, days_to_shift)
end

puts "Shifting dates for weekly reports by #{days_to_shift}"
@db.view('weeklyDataBySubmitDate/weeklyDataBySubmitDate?include_docs=true&reduce=false')['rows'].map{|row|row["doc"]}.each do |doc|
  if not doc["date_shifted"]
    shiftedDateTime = DateTime.strptime("#{doc["Year"]} #{doc["Week"]}", "%G %V") + days_to_shift
    doc["Year"] = shiftedDateTime.strftime("%G")
    doc["Week"] = shiftedDateTime.strftime("%V")
    doc["Submit Date"] = (DateTime.parse(doc["Submit Date"]) + days_to_shift).strftime("%Y-%m-%d %H:%M:%S")
    doc["date_shifted"] = true
    doc["shift_amount"] = days_to_shift
    @db.bulk_save_doc(result)
  end
end

puts "Changing passwords"
# Change all user passwords to bcrypy hash version of 'password'
@db.all_docs({:startkey => "user",:endkey => "userz",:include_docs => true})['rows'].map{|row|row["doc"]}.each do |doc|
  doc["hash"] = "$2a$10$6KmPWcacb3y6Eq7H7ilQCOCAIIqogyXa2Znij3AXyFtzn59W6nKE2"
  @db.bulk_save_doc(doc)
end

@db.bulk_save()
