require 'rubygems'
require 'couchrest'
require 'pp'

RestClient.log = 'stdout'



@db = CouchRest.database("http://cococloud.co/zanzibar")

def randomizeLocation(result)
  # Should shift within about 2km
  result["HouseholdLocation-latitude"] = (result["HouseholdLocation-latitude"].to_f + Random.rand(-0.01..0.01)).to_s
  result["HouseholdLocation-longitude"] = (result["HouseholdLocation-longitude"].to_f + Random.rand(-0.01..0.01)).to_s
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

def fixIdentifyingAttributes(result)
  changed = false

  $identifying_attributes.each do |identifying_attribute|
    if result[identifying_attribute]
      changed = true
      if identifying_attribute == "ContactMobilepatientrelative"
        result[identifying_attribute] = "07" + rand(5 ** 5).to_s.rjust(5,'0')
      else
        result[identifying_attribute] = result[identifying_attribute] = $names.sample
      end
    end
  end
  if result["HouseholdLocation-latitude"]
    changed = true
    result = randomizeLocation(result)
  end

  if changed
    print "."
    pp result
    @db.bulk_save_doc(result)
  end

end

@db.view('results/results?include_docs=true')['rows'].map{|row|row["doc"]}.each do |doc|
  fixIdentifyingAttributes(doc)
end

# Fix identifying attributes including lat/long
@db.view('zanzibar/notifications?include_docs=true')['rows'].map{|row|row["doc"]}.each do |doc|
  fixIdentifyingAttributes(doc)
end

# Change all user passwords to password
@db.all_docs({:startkey => "user",:endkey => "userz",:include_docs => true})['rows'].map{|row|row["doc"]}.each do |doc|
  doc["password"] = "password"
  @db.bulk_save_doc(doc)
end

@db.bulk_save() 
