# Constants.coffee
# Keeping all constants used in App in a single place
module.exports =
  SaltRounds: 10
  Version: "2.0"
  dateFormats: ['DD-MM-YYYY', 'MM-DD-YYYY', 'YYYY-MM-DD']
  graphColorSchemes: ['spectrum14', 'colorwheel', 'cool', 'spectrum2000', 'spectrum2001', 'classic9','munin']
  Countries:
    [
      {"name": "Afghanistan", "code": "AF"}
      {"name": "Åland Islands", "code": "AX"}
      {"name": "Albania", "code": "AL"}
      {"name": "Algeria", "code": "DZ"}
      {"name": "American Samoa", "code": "AS"}
      {"name": "AndorrA", "code": "AD"}
      {"name": "Angola", "code": "AO"}
      {"name": "Anguilla", "code": "AI"}
      {"name": "Antarctica", "code": "AQ"}
      {"name": "Antigua and Barbuda", "code": "AG"}
      {"name": "Argentina", "code": "AR"}
      {"name": "Armenia", "code": "AM"}
      {"name": "Aruba", "code": "AW"}
      {"name": "Australia", "code": "AU"}
      {"name": "Austria", "code": "AT"}
      {"name": "Azerbaijan", "code": "AZ"}
      {"name": "Bahamas", "code": "BS"}
      {"name": "Bahrain", "code": "BH"}
      {"name": "Bangladesh", "code": "BD"}
      {"name": "Barbados", "code": "BB"}
      {"name": "Belarus", "code": "BY"}
      {"name": "Belgium", "code": "BE"}
      {"name": "Belize", "code": "BZ"}
      {"name": "Benin", "code": "BJ"}
      {"name": "Bermuda", "code": "BM"}
      {"name": "Bhutan", "code": "BT"}
      {"name": "Bolivia", "code": "BO"}
      {"name": "Bosnia and Herzegovina", "code": "BA"}
      {"name": "Botswana", "code": "BW"}
      {"name": "Bouvet Island", "code": "BV"}
      {"name": "Brazil", "code": "BR"}
      {"name": "British Indian Ocean Territory", "code": "IO"}
      {"name": "Brunei Darussalam", "code": "BN"}
      {"name": "Bulgaria", "code": "BG"}
      {"name": "Burkina Faso", "code": "BF"}
      {"name": "Burundi", "code": "BI"}
      {"name": "Cambodia", "code": "KH"}
      {"name": "Cameroon", "code": "CM"}
      {"name": "Canada", "code": "CA"}
      {"name": "Cape Verde", "code": "CV"}
      {"name": "Cayman Islands", "code": "KY"}
      {"name": "Central African Republic", "code": "CF"}
      {"name": "Chad", "code": "TD"}
      {"name": "Chile", "code": "CL"}
      {"name": "China", "code": "CN"}
      {"name": "Christmas Island", "code": "CX"}
      {"name": "Cocos (Keeling) Islands", "code": "CC"}
      {"name": "Colombia", "code": "CO"}
      {"name": "Comoros", "code": "KM"}
      {"name": "Congo", "code": "CG"}
      {"name": "Congo, The Democratic Republic of the", "code": "CD"}
      {"name": "Cook Islands", "code": "CK"}
      {"name": "Costa Rica", "code": "CR"}
      {"name": "Cote D\"Ivoire", "code": "CI"}
      {"name": "Croatia", "code": "HR"}
      {"name": "Cuba", "code": "CU"}
      {"name": "Cyprus", "code": "CY"}
      {"name": "Czech Republic", "code": "CZ"}
      {"name": "Denmark", "code": "DK"}
      {"name": "Djibouti", "code": "DJ"}
      {"name": "Dominica", "code": "DM"}
      {"name": "Dominican Republic", "code": "DO"}
      {"name": "Ecuador", "code": "EC"}
      {"name": "Egypt", "code": "EG"}
      {"name": "El Salvador", "code": "SV"}
      {"name": "Equatorial Guinea", "code": "GQ"}
      {"name": "Eritrea", "code": "ER"}
      {"name": "Estonia", "code": "EE"}
      {"name": "Ethiopia", "code": "ET"}
      {"name": "Falkland Islands (Malvinas)", "code": "FK"}
      {"name": "Faroe Islands", "code": "FO"}
      {"name": "Fiji", "code": "FJ"}
      {"name": "Finland", "code": "FI"}
      {"name": "France", "code": "FR"}
      {"name": "French Guiana", "code": "GF"}
      {"name": "French Polynesia", "code": "PF"}
      {"name": "French Southern Territories", "code": "TF"}
      {"name": "Gabon", "code": "GA"}
      {"name": "Gambia", "code": "GM"}
      {"name": "Georgia", "code": "GE"}
      {"name": "Germany", "code": "DE"}
      {"name": "Ghana", "code": "GH"}
      {"name": "Gibraltar", "code": "GI"}
      {"name": "Greece", "code": "GR"}
      {"name": "Greenland", "code": "GL"}
      {"name": "Grenada", "code": "GD"}
      {"name": "Guadeloupe", "code": "GP"}
      {"name": "Guam", "code": "GU"}
      {"name": "Guatemala", "code": "GT"}
      {"name": "Guernsey", "code": "GG"}
      {"name": "Guinea", "code": "GN"}
      {"name": "Guinea-Bissau", "code": "GW"}
      {"name": "Guyana", "code": "GY"}
      {"name": "Haiti", "code": "HT"}
      {"name": "Heard Island and Mcdonald Islands", "code": "HM"}
      {"name": "Holy See (Vatican City State)", "code": "VA"}
      {"name": "Honduras", "code": "HN"}
      {"name": "Hong Kong", "code": "HK"}
      {"name": "Hungary", "code": "HU"}
      {"name": "Iceland", "code": "IS"}
      {"name": "India", "code": "IN"}
      {"name": "Indonesia", "code": "ID"}
      {"name": "Iran, Islamic Republic Of", "code": "IR"}
      {"name": "Iraq", "code": "IQ"}
      {"name": "Ireland", "code": "IE"}
      {"name": "Isle of Man", "code": "IM"}
      {"name": "Israel", "code": "IL"}
      {"name": "Italy", "code": "IT"}
      {"name": "Jamaica", "code": "JM"}
      {"name": "Japan", "code": "JP"}
      {"name": "Jersey", "code": "JE"}
      {"name": "Jordan", "code": "JO"}
      {"name": "Kazakhstan", "code": "KZ"}
      {"name": "Kenya", "code": "KE"}
      {"name": "Kiribati", "code": "KI"}
      {"name": "Korea, Democratic People\"S Republic of", "code": "KP"}
      {"name": "Korea, Republic of", "code": "KR"}
      {"name": "Kuwait", "code": "KW"}
      {"name": "Kyrgyzstan", "code": "KG"}
      {"name": "Lao People\"S Democratic Republic", "code": "LA"}
      {"name": "Latvia", "code": "LV"}
      {"name": "Lebanon", "code": "LB"}
      {"name": "Lesotho", "code": "LS"}
      {"name": "Liberia", "code": "LR"}
      {"name": "Libyan Arab Jamahiriya", "code": "LY"}
      {"name": "Liechtenstein", "code": "LI"}
      {"name": "Lithuania", "code": "LT"}
      {"name": "Luxembourg", "code": "LU"}
      {"name": "Macao", "code": "MO"}
      {"name": "Macedonia, The Former Yugoslav Republic of", "code": "MK"}
      {"name": "Madagascar", "code": "MG"}
      {"name": "Malawi", "code": "MW"}
      {"name": "Malaysia", "code": "MY"}
      {"name": "Maldives", "code": "MV"}
      {"name": "Mali", "code": "ML"}
      {"name": "Malta", "code": "MT"}
      {"name": "Marshall Islands", "code": "MH"}
      {"name": "Martinique", "code": "MQ"}
      {"name": "Mauritania", "code": "MR"}
      {"name": "Mauritius", "code": "MU"}
      {"name": "Mayotte", "code": "YT"}
      {"name": "Mexico", "code": "MX"}
      {"name": "Micronesia, Federated States of", "code": "FM"}
      {"name": "Moldova, Republic of", "code": "MD"}
      {"name": "Monaco", "code": "MC"}
      {"name": "Mongolia", "code": "MN"}
      {"name": "Montserrat", "code": "MS"}
      {"name": "Morocco", "code": "MA"}
      {"name": "Mozambique", "code": "MZ"}
      {"name": "Myanmar", "code": "MM"}
      {"name": "Namibia", "code": "NA"}
      {"name": "Nauru", "code": "NR"}
      {"name": "Nepal", "code": "NP"}
      {"name": "Netherlands", "code": "NL"}
      {"name": "Netherlands Antilles", "code": "AN"}
      {"name": "New Caledonia", "code": "NC"}
      {"name": "New Zealand", "code": "NZ"}
      {"name": "Nicaragua", "code": "NI"}
      {"name": "Niger", "code": "NE"}
      {"name": "Nigeria", "code": "NG"}
      {"name": "Niue", "code": "NU"}
      {"name": "Norfolk Island", "code": "NF"}
      {"name": "Northern Mariana Islands", "code": "MP"}
      {"name": "Norway", "code": "NO"}
      {"name": "Oman", "code": "OM"}
      {"name": "Pakistan", "code": "PK"}
      {"name": "Palau", "code": "PW"}
      {"name": "Palestinian Territory, Occupied", "code": "PS"}
      {"name": "Panama", "code": "PA"}
      {"name": "Papua New Guinea", "code": "PG"}
      {"name": "Paraguay", "code": "PY"}
      {"name": "Peru", "code": "PE"}
      {"name": "Philippines", "code": "PH"}
      {"name": "Pitcairn", "code": "PN"}
      {"name": "Poland", "code": "PL"}
      {"name": "Portugal", "code": "PT"}
      {"name": "Puerto Rico", "code": "PR"}
      {"name": "Qatar", "code": "QA"}
      {"name": "Reunion", "code": "RE"}
      {"name": "Romania", "code": "RO"}
      {"name": "Russian Federation", "code": "RU"}
      {"name": "RWANDA", "code": "RW"}
      {"name": "Saint Helena", "code": "SH"}
      {"name": "Saint Kitts and Nevis", "code": "KN"}
      {"name": "Saint Lucia", "code": "LC"}
      {"name": "Saint Pierre and Miquelon", "code": "PM"}
      {"name": "Saint Vincent and the Grenadines", "code": "VC"}
      {"name": "Samoa", "code": "WS"}
      {"name": "San Marino", "code": "SM"}
      {"name": "Sao Tome and Principe", "code": "ST"}
      {"name": "Saudi Arabia", "code": "SA"}
      {"name": "Senegal", "code": "SN"}
      {"name": "Serbia and Montenegro", "code": "CS"}
      {"name": "Seychelles", "code": "SC"}
      {"name": "Sierra Leone", "code": "SL"}
      {"name": "Singapore", "code": "SG"}
      {"name": "Slovakia", "code": "SK"}
      {"name": "Slovenia", "code": "SI"}
      {"name": "Solomon Islands", "code": "SB"}
      {"name": "Somalia", "code": "SO"}
      {"name": "South Africa", "code": "ZA"}
      {"name": "South Georgia and the South Sandwich Islands", "code": "GS"}
      {"name": "Spain", "code": "ES"}
      {"name": "Sri Lanka", "code": "LK"}
      {"name": "Sudan", "code": "SD"}
      {"name": "Suriname", "code": "SR"}
      {"name": "Svalbard and Jan Mayen", "code": "SJ"}
      {"name": "Swaziland", "code": "SZ"}
      {"name": "Sweden", "code": "SE"}
      {"name": "Switzerland", "code": "CH"}
      {"name": "Syrian Arab Republic", "code": "SY"}
      {"name": "Taiwan, Province of China", "code": "TW"}
      {"name": "Tajikistan", "code": "TJ"}
      {"name": "Tanzania, United Republic of", "code": "TZ"}
      {"name": "Thailand", "code": "TH"}
      {"name": "Timor-Leste", "code": "TL"}
      {"name": "Togo", "code": "TG"}
      {"name": "Tokelau", "code": "TK"}
      {"name": "Tonga", "code": "TO"}
      {"name": "Trinidad and Tobago", "code": "TT"}
      {"name": "Tunisia", "code": "TN"}
      {"name": "Turkey", "code": "TR"}
      {"name": "Turkmenistan", "code": "TM"}
      {"name": "Turks and Caicos Islands", "code": "TC"}
      {"name": "Tuvalu", "code": "TV"}
      {"name": "Uganda", "code": "UG"}
      {"name": "Ukraine", "code": "UA"}
      {"name": "United Arab Emirates", "code": "AE"}
      {"name": "United Kingdom", "code": "GB"}
      {"name": "United States", "code": "US"}
      {"name": "United States Minor Outlying Islands", "code": "UM"}
      {"name": "Uruguay", "code": "UY"}
      {"name": "Uzbekistan", "code": "UZ"}
      {"name": "Vanuatu", "code": "VU"}
      {"name": "Venezuela", "code": "VE"}
      {"name": "Viet Nam", "code": "VN"}
      {"name": "Virgin Islands, British", "code": "VG"}
      {"name": "Virgin Islands, U.S.", "code": "VI"}
      {"name": "Wallis and Futuna", "code": "WF"}
      {"name": "Western Sahara", "code": "EH"}
      {"name": "Yemen", "code": "YE"}
      {"name": "Zambia", "code": "ZM"}
      {"name": "Zimbabwe", "code": "ZW"}
      {"name": "Zanzibar", "code":""}
    ]
  Timezones:
    [
      { "Abbreviation" :"A", "Name": "Alpha Time Zone", "DisplayName": "Alpha Time Zone(UTC + 1)", "Offset": "1 hours"}
      { "Abbreviation" :"ACDT", "Name": "Australian Central Daylight Time", "DisplayName": "Australian Central Daylight Time(UTC + 10:30)", "Offset": "10:30 hours"}
      { "Abbreviation" :"ACST", "Name": "Australian Central Standard Time", "DisplayName": "Australian Central Standard Time(UTC + 9:30)", "Offset": "9:30 hours"}
      { "Abbreviation" :"ADT", "Name": "Atlantic Daylight Time", "DisplayName": "Atlantic Daylight Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"ADT", "Name": "Atlantic Daylight Time", "DisplayName": "Atlantic Daylight Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"AEDT", "Name": "Australian Eastern Daylight Time", "DisplayName": "Australian Eastern Daylight Time(UTC + 11)", "Offset": "11 hours"}
      { "Abbreviation" :"AEST", "Name": "Australian Eastern Standard Time", "DisplayName": "Australian Eastern Standard Time(UTC + 10)", "Offset": "10 hours"}
      { "Abbreviation" :"AFT", "Name": "Afghanistan Time", "DisplayName": "Afghanistan Time(UTC + 4:30)", "Offset": "4:30 hours"}
      { "Abbreviation" :"AKDT", "Name": "Alaska Daylight Time", "DisplayName": "Alaska Daylight Time(UTC - 8)", "Offset": "-8 hours"}
      { "Abbreviation" :"AKST", "Name": "Alaska Standard Time", "DisplayName": "Alaska Standard Time(UTC - 9)", "Offset": "-9 hours"}
      { "Abbreviation" :"ALMT", "Name": "Alma-Ata Time", "DisplayName": "Alma-Ata Time(UTC + 6)", "Offset": "6 hours"}
      { "Abbreviation" :"AMST", "Name": "Armenia Summer Time", "DisplayName": "Armenia Summer Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"AMST", "Name": "Amazon Summer Time", "DisplayName": "Amazon Summer Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"AMT", "Name": "Armenia Time", "DisplayName": "Armenia Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"AMT", "Name": "Amazon Time", "DisplayName": "Amazon Time(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"ANAST", "Name": "Anadyr Summer Time", "DisplayName": "Anadyr Summer Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"ANAT", "Name": "Anadyr Time", "DisplayName": "Anadyr Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"AQTT", "Name": "Aqtobe Time", "DisplayName": "Aqtobe Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"ART", "Name": "Argentina Time", "DisplayName": "Argentina Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"AST", "Name": "Arabia Standard Time", "DisplayName": "Arabia Standard Time(UTC + 3)", "Offset": "3 hours"}
      { "Abbreviation" :"AST", "Name": "Atlantic Standard Time", "DisplayName": "Atlantic Standard Time(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"AWDT", "Name": "Australian Western Daylight Time", "DisplayName": "Australian Western Daylight Time(UTC + 9)", "Offset": "9 hours"}
      { "Abbreviation" :"AWST", "Name": "Australian Western Standard Time", "DisplayName": "Australian Western Standard Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"AZOST", "Name": "Azores Summer Time", "DisplayName": "Azores Summer Time(UTC)", "Offset": "0 hours"}
      { "Abbreviation" :"AZOT", "Name": "Azores Time", "DisplayName": "Azores Time(UTC - 1)", "Offset": "-1 hours"}
      { "Abbreviation" :"AZST", "Name": "Azerbaijan Summer Time", "DisplayName": "Azerbaijan Summer Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"AZT", "Name": "Azerbaijan Time", "DisplayName": "Azerbaijan Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"B", "Name": "Bravo Time Zone", "DisplayName": "Bravo Time Zone(UTC + 2)", "Offset": "2 hours"}
      { "Abbreviation" :"BNT", "Name": "Brunei Darussalam Time", "DisplayName": "Brunei Darussalam Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"BOT", "Name": "Bolivia Time", "DisplayName": "Bolivia Time(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"BRST", "Name": "Brasilia Summer Time", "DisplayName": "Brasilia Summer Time(UTC - 2)", "Offset": "-2 hours"}
      { "Abbreviation" :"BRT", "Name": "Brasília time", "DisplayName": "Brasília time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"BST", "Name": "Bangladesh Standard Time", "DisplayName": "Bangladesh Standard Time(UTC + 6)", "Offset": "6 hours"}
      { "Abbreviation" :"BST", "Name": "British Summer Time", "DisplayName": "British Summer Time(UTC + 1)", "Offset": "1 hours"}
      { "Abbreviation" :"BTT", "Name": "Bhutan Time", "DisplayName": "Bhutan Time(UTC + 6)", "Offset": "6 hours"}
      { "Abbreviation" :"C", "Name": "Charlie Time Zone", "DisplayName": "Charlie Time Zone(UTC + 3)", "Offset": "3 hours"}
      { "Abbreviation" :"CAST", "Name": "Casey Time", "DisplayName": "Casey Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"CAT", "Name": "Central Africa Time", "DisplayName": "Central Africa Time(UTC + 2)", "Offset": "2 hours"}
      { "Abbreviation" :"CCT", "Name": "Cocos Islands Time", "DisplayName": "Cocos Islands Time(UTC + 6:30)", "Offset": "6:30 hours"}
      { "Abbreviation" :"CDT", "Name": "Cuba Daylight Time", "DisplayName": "Cuba Daylight Time(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"CDT", "Name": "Central Daylight Time", "DisplayName": "Central Daylight Time(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"CEST", "Name": "Central European Summer Time", "DisplayName": "Central European Summer Time(UTC + 2)", "Offset": "2 hours"}
      { "Abbreviation" :"CET", "Name": "Central European Time", "DisplayName": "Central European Time(UTC + 1)", "Offset": "1 hours"}
      { "Abbreviation" :"CHADT", "Name": "Chatham Island Daylight Time", "DisplayName": "Chatham Island Daylight Time(UTC + 13:45)", "Offset": "13:45 hours"}
      { "Abbreviation" :"CHAST", "Name": "Chatham Island Standard Time", "DisplayName": "Chatham Island Standard Time(UTC + 12:45)", "Offset": "12:45 hours"}
      { "Abbreviation" :"CKT", "Name": "Cook Island Time", "DisplayName": "Cook Island Time(UTC - 10)", "Offset": "-10 hours"}
      { "Abbreviation" :"CLST", "Name": "Chile Summer Time", "DisplayName": "Chile Summer Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"CLT", "Name": "Chile Standard Time", "DisplayName": "Chile Standard Time(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"COT", "Name": "Colombia Time", "DisplayName": "Colombia Time(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"CST", "Name": "China Standard Time", "DisplayName": "China Standard Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"CST", "Name": "Central Standard Time", "DisplayName": "Central Standard Time(UTC - 6)", "Offset": "-6 hours"}
      { "Abbreviation" :"CST", "Name": "Cuba Standard Time", "DisplayName": "Cuba Standard Time(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"CVT", "Name": "Cape Verde Time", "DisplayName": "Cape Verde Time(UTC - 1)", "Offset": "-1 hours"}
      { "Abbreviation" :"CXT", "Name": "Christmas Island Time", "DisplayName": "Christmas Island Time(UTC + 7)", "Offset": "7 hours"}
      { "Abbreviation" :"ChST", "Name": "Chamorro Standard Time", "DisplayName": "Chamorro Standard Time(UTC + 10)", "Offset": "10 hours"}
      { "Abbreviation" :"D", "Name": "Delta Time Zone", "DisplayName": "Delta Time Zone(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"DAVT", "Name": "Davis Time", "DisplayName": "Davis Time(UTC + 7)", "Offset": "7 hours"}
      { "Abbreviation" :"E", "Name": "Echo Time Zone", "DisplayName": "Echo Time Zone(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"EASST", "Name": "Easter Island Summer Time", "DisplayName": "Easter Island Summer Time(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"EAST", "Name": "Easter Island Standard Time", "DisplayName": "Easter Island Standard Time(UTC - 6)", "Offset": "-6 hours"}
      { "Abbreviation" :"EAT", "Name": "Eastern Africa Time", "DisplayName": "Eastern Africa Time(UTC + 3)", "Offset": "3 hours"}
      { "Abbreviation" :"EAT", "Name": "East Africa Time", "DisplayName": "East Africa Time(UTC + 3)", "Offset": "3 hours"}
      { "Abbreviation" :"ECT", "Name": "Ecuador Time", "DisplayName": "Ecuador Time(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"EDT", "Name": "Eastern Daylight Time", "DisplayName": "Eastern Daylight Time(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"EEST", "Name": "Eastern European Summer Time", "DisplayName": "Eastern European Summer Time(UTC + 3)", "Offset": "3 hours"}
      { "Abbreviation" :"EET", "Name": "Eastern European Time", "DisplayName": "Eastern European Time(UTC + 2)", "Offset": "2 hours"}
      { "Abbreviation" :"EGST", "Name": "Eastern Greenland Summer Time", "DisplayName": "Eastern Greenland Summer Time(UTC)", "Offset": "0 hours"}
      { "Abbreviation" :"EGT", "Name": "East Greenland Time", "DisplayName": "East Greenland Time(UTC - 1)", "Offset": "-1 hours"}
      { "Abbreviation" :"EST", "Name": "Eastern Standard Time", "DisplayName": "Eastern Standard Time(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"ET", "Name": "Tiempo del Este", "DisplayName": "Tiempo del Este(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"F", "Name": "Foxtrot Time Zone", "DisplayName": "Foxtrot Time Zone(UTC + 6)", "Offset": "6 hours"}
      { "Abbreviation" :"FJST", "Name": "Fiji Summer Time", "DisplayName": "Fiji Summer Time(UTC + 13)", "Offset": "13 hours"}
      { "Abbreviation" :"FJT", "Name": "Fiji Time", "DisplayName": "Fiji Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"FKST", "Name": "Falkland Islands Summer Time", "DisplayName": "Falkland Islands Summer Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"FKT", "Name": "Falkland Island Time", "DisplayName": "Falkland Island Time(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"FNT", "Name": "Fernando de Noronha Time", "DisplayName": "Fernando de Noronha Time(UTC - 2)", "Offset": "-2 hours"}
      { "Abbreviation" :"G", "Name": "Golf Time Zone", "DisplayName": "Golf Time Zone(UTC + 7)", "Offset": "7 hours"}
      { "Abbreviation" :"GALT", "Name": "Galapagos Time", "DisplayName": "Galapagos Time(UTC - 6)", "Offset": "-6 hours"}
      { "Abbreviation" :"GAMT", "Name": "Gambier Time", "DisplayName": "Gambier Time(UTC - 9)", "Offset": "-9 hours"}
      { "Abbreviation" :"GET", "Name": "Georgia Standard Time", "DisplayName": "Georgia Standard Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"GFT", "Name": "French Guiana Time", "DisplayName": "French Guiana Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"GILT", "Name": "Gilbert Island Time", "DisplayName": "Gilbert Island Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"GMT", "Name": "Greenwich Mean Time", "DisplayName": "Greenwich Mean Time(UTC)", "Offset": "0 hours"}
      { "Abbreviation" :"GST", "Name": "Gulf Standard Time", "DisplayName": "Gulf Standard Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"GYT", "Name": "Guyana Time", "DisplayName": "Guyana Time(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"H", "Name": "Hotel Time Zone", "DisplayName": "Hotel Time Zone(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"HAA", "Name": "Heure Avancée de l'Atlantique", "DisplayName": "Heure Avancée de l'Atlantique(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"HAC", "Name": "Heure Avancée du Centre", "DisplayName": "Heure Avancée du Centre(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"HADT", "Name": "Hawaii-Aleutian Daylight Time", "DisplayName": "Hawaii-Aleutian Daylight Time(UTC - 9)", "Offset": "-9 hours"}
      { "Abbreviation" :"HAE", "Name": "Heure Avancée de l'Est", "DisplayName": "Heure Avancée de l'Est(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"HAP", "Name": "Heure Avancée du Pacifique", "DisplayName": "Heure Avancée du Pacifique(UTC - 7)", "Offset": "-7 hours"}
      { "Abbreviation" :"HAR", "Name": "Heure Avancée des Rocheuses", "DisplayName": "Heure Avancée des Rocheuses(UTC - 6)", "Offset": "-6 hours"}
      { "Abbreviation" :"HAST", "Name": "Hawaii-Aleutian Standard Time", "DisplayName": "Hawaii-Aleutian Standard Time(UTC - 10)", "Offset": "-10 hours"}
      { "Abbreviation" :"HAT", "Name": "Heure Avancée de Terre-Neuve", "DisplayName": "Heure Avancée de Terre-Neuve(UTC - 2:30)", "Offset": "-2:30 hours"}
      { "Abbreviation" :"HAY", "Name": "Heure Avancée du Yukon", "DisplayName": "Heure Avancée du Yukon(UTC - 8)", "Offset": "-8 hours"}
      { "Abbreviation" :"HKT", "Name": "Hong Kong Time", "DisplayName": "Hong Kong Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"HLV", "Name": "Hora Legal de Venezuela", "DisplayName": "Hora Legal de Venezuela(UTC - 4:30)", "Offset": "-4:30 hours"}
      { "Abbreviation" :"HNA", "Name": "Heure Normale de l'Atlantique", "DisplayName": "Heure Normale de l'Atlantique(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"HNC", "Name": "Heure Normale du Centre", "DisplayName": "Heure Normale du Centre(UTC - 6)", "Offset": "-6 hours"}
      { "Abbreviation" :"HNE", "Name": "Heure Normale de l'Est", "DisplayName": "Heure Normale de l'Est(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"HNP", "Name": "Heure Normale du Pacifique", "DisplayName": "Heure Normale du Pacifique(UTC - 8)", "Offset": "-8 hours"}
      { "Abbreviation" :"HNR", "Name": "Heure Normale des Rocheuses", "DisplayName": "Heure Normale des Rocheuses(UTC - 7)", "Offset": "-7 hours"}
      { "Abbreviation" :"HNT", "Name": "Heure Normale de Terre-Neuve", "DisplayName": "Heure Normale de Terre-Neuve(UTC - 3:30)", "Offset": "-3:30 hours"}
      { "Abbreviation" :"HNY", "Name": "Heure Normale du Yukon", "DisplayName": "Heure Normale du Yukon(UTC - 9)", "Offset": "-9 hours"}
      { "Abbreviation" :"HOVT", "Name": "Hovd Time", "DisplayName": "Hovd Time(UTC + 7)", "Offset": "7 hours"}
      { "Abbreviation" :"I", "Name": "India Time Zone", "DisplayName": "India Time Zone(UTC + 9)", "Offset": "9 hours"}
      { "Abbreviation" :"ICT", "Name": "Indochina Time", "DisplayName": "Indochina Time(UTC + 7)", "Offset": "7 hours"}
      { "Abbreviation" :"IDT", "Name": "Israel Daylight Time", "DisplayName": "Israel Daylight Time(UTC + 3)", "Offset": "3 hours"}
      { "Abbreviation" :"IOT", "Name": "Indian Chagos Time", "DisplayName": "Indian Chagos Time(UTC + 6)", "Offset": "6 hours"}
      { "Abbreviation" :"IRDT", "Name": "Iran Daylight Time", "DisplayName": "Iran Daylight Time(UTC + 4:30)", "Offset": "4:30 hours"}
      { "Abbreviation" :"IRKST", "Name": "Irkutsk Summer Time", "DisplayName": "Irkutsk Summer Time(UTC + 9)", "Offset": "9 hours"}
      { "Abbreviation" :"IRKT", "Name": "Irkutsk Time", "DisplayName": "Irkutsk Time(UTC + 9)", "Offset": "9 hours"}
      { "Abbreviation" :"IRST", "Name": "Iran Standard Time", "DisplayName": "Iran Standard Time(UTC + 3:30)", "Offset": "3:30 hours"}
      { "Abbreviation" :"IST", "Name": "Israel Standard Time", "DisplayName": "Israel Standard Time(UTC + 2)", "Offset": "2 hours"}
      { "Abbreviation" :"IST", "Name": "India Standard Time", "DisplayName": "India Standard Time(UTC + 5:30)", "Offset": "5:30 hours"}
      { "Abbreviation" :"IST", "Name": "Irish Standard Time", "DisplayName": "Irish Standard Time(UTC + 1)", "Offset": "1 hours"}
      { "Abbreviation" :"JST", "Name": "Japan Standard Time", "DisplayName": "Japan Standard Time(UTC + 9)", "Offset": "9 hours"}
      { "Abbreviation" :"K", "Name": "Kilo Time Zone", "DisplayName": "Kilo Time Zone(UTC + 10)", "Offset": "10 hours"}
      { "Abbreviation" :"KGT", "Name": "Kyrgyzstan Time", "DisplayName": "Kyrgyzstan Time(UTC + 6)", "Offset": "6 hours"}
      { "Abbreviation" :"KRAST", "Name": "Krasnoyarsk Summer Time", "DisplayName": "Krasnoyarsk Summer Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"KRAT", "Name": "Krasnoyarsk Time", "DisplayName": "Krasnoyarsk Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"KST", "Name": "Korea Standard Time", "DisplayName": "Korea Standard Time(UTC + 9)", "Offset": "9 hours"}
      { "Abbreviation" :"KUYT", "Name": "Kuybyshev Time", "DisplayName": "Kuybyshev Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"L", "Name": "Lima Time Zone", "DisplayName": "Lima Time Zone(UTC + 11)", "Offset": "11 hours"}
      { "Abbreviation" :"LHDT", "Name": "Lord Howe Daylight Time", "DisplayName": "Lord Howe Daylight Time(UTC + 11)", "Offset": "11 hours"}
      { "Abbreviation" :"LHST", "Name": "Lord Howe Standard Time", "DisplayName": "Lord Howe Standard Time(UTC + 10:30)", "Offset": "10:30 hours"}
      { "Abbreviation" :"LINT", "Name": "Line Islands Time", "DisplayName": "Line Islands Time(UTC + 14)", "Offset": "14 hours"}
      { "Abbreviation" :"M", "Name": "Mike Time Zone", "DisplayName": "Mike Time Zone(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"MAGST", "Name": "Magadan Summer Time", "DisplayName": "Magadan Summer Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"MAGT", "Name": "Magadan Time", "DisplayName": "Magadan Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"MART", "Name": "Marquesas Time", "DisplayName": "Marquesas Time(UTC - 9:30)", "Offset": "-9:30 hours"}
      { "Abbreviation" :"MAWT", "Name": "Mawson Time", "DisplayName": "Mawson Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"MDT", "Name": "Mountain Daylight Time", "DisplayName": "Mountain Daylight Time(UTC - 6)", "Offset": "-6 hours"}
      { "Abbreviation" :"MESZ", "Name": "Mitteleuropäische Sommerzeit", "DisplayName": "Mitteleuropäische Sommerzeit(UTC + 2)", "Offset": "2 hours"}
      { "Abbreviation" :"MEZ", "Name": "Mitteleuropäische Zeit", "DisplayName": "Mitteleuropäische Zeit(UTC + 1)", "Offset": "1 hours"}
      { "Abbreviation" :"MHT", "Name": "Marshall Islands Time", "DisplayName": "Marshall Islands Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"MMT", "Name": "Myanmar Time", "DisplayName": "Myanmar Time(UTC + 6:30)", "Offset": "6:30 hours"}
      { "Abbreviation" :"MSD", "Name": "Moscow Daylight Time", "DisplayName": "Moscow Daylight Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"MSK", "Name": "Moscow Standard Time", "DisplayName": "Moscow Standard Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"MST", "Name": "Mountain Standard Time", "DisplayName": "Mountain Standard Time(UTC - 7)", "Offset": "-7 hours"}
      { "Abbreviation" :"MUT", "Name": "Mauritius Time", "DisplayName": "Mauritius Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"MVT", "Name": "Maldives Time", "DisplayName": "Maldives Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"MYT", "Name": "Malaysia Time", "DisplayName": "Malaysia Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"N", "Name": "November Time Zone", "DisplayName": "November Time Zone(UTC - 1)", "Offset": "-1 hours"}
      { "Abbreviation" :"NCT", "Name": "New Caledonia Time", "DisplayName": "New Caledonia Time(UTC + 11)", "Offset": "11 hours"}
      { "Abbreviation" :"NDT", "Name": "Newfoundland Daylight Time", "DisplayName": "Newfoundland Daylight Time(UTC - 2:30)", "Offset": "-2:30 hours"}
      { "Abbreviation" :"NFT", "Name": "Norfolk Time", "DisplayName": "Norfolk Time(UTC + 11:30)", "Offset": "11:30 hours"}
      { "Abbreviation" :"NOVST", "Name": "Novosibirsk Summer Time", "DisplayName": "Novosibirsk Summer Time(UTC + 7)", "Offset": "7 hours"}
      { "Abbreviation" :"NOVT", "Name": "Novosibirsk Time", "DisplayName": "Novosibirsk Time(UTC + 6)", "Offset": "6 hours"}
      { "Abbreviation" :"NPT", "Name": "Nepal Time", "DisplayName": "Nepal Time(UTC + 5:45)", "Offset": "5:45 hours"}
      { "Abbreviation" :"NST", "Name": "Newfoundland Standard Time", "DisplayName": "Newfoundland Standard Time(UTC - 3:30)", "Offset": "-3:30 hours"}
      { "Abbreviation" :"NUT", "Name": "Niue Time", "DisplayName": "Niue Time(UTC - 11)", "Offset": "-11 hours"}
      { "Abbreviation" :"NZDT", "Name": "New Zealand Daylight Time", "DisplayName": "New Zealand Daylight Time(UTC + 13)", "Offset": "13 hours"}
      { "Abbreviation" :"NZST", "Name": "New Zealand Standard Time", "DisplayName": "New Zealand Standard Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"O", "Name": "Oscar Time Zone", "DisplayName": "Oscar Time Zone(UTC - 2)", "Offset": "-2 hours"}
      { "Abbreviation" :"OMSST", "Name": "Omsk Summer Time", "DisplayName": "Omsk Summer Time(UTC + 7)", "Offset": "7 hours"}
      { "Abbreviation" :"OMST", "Name": "Omsk Standard Time", "DisplayName": "Omsk Standard Time(UTC + 7)", "Offset": "7 hours"}
      { "Abbreviation" :"P", "Name": "Papa Time Zone", "DisplayName": "Papa Time Zone(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"PDT", "Name": "Pacific Daylight Time", "DisplayName": "Pacific Daylight Time(UTC - 7)", "Offset": "-7 hours"}
      { "Abbreviation" :"PET", "Name": "Peru Time", "DisplayName": "Peru Time(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"PETST", "Name": "Kamchatka Summer Time", "DisplayName": "Kamchatka Summer Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"PETT", "Name": "Kamchatka Time", "DisplayName": "Kamchatka Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"PGT", "Name": "Papua New Guinea Time", "DisplayName": "Papua New Guinea Time(UTC + 10)", "Offset": "10 hours"}
      { "Abbreviation" :"PHOT", "Name": "Phoenix Island Time", "DisplayName": "Phoenix Island Time(UTC + 13)", "Offset": "13 hours"}
      { "Abbreviation" :"PHT", "Name": "Philippine Time", "DisplayName": "Philippine Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"PKT", "Name": "Pakistan Standard Time", "DisplayName": "Pakistan Standard Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"PMDT", "Name": "Pierre & Miquelon Daylight Time", "DisplayName": "Pierre & Miquelon Daylight Time(UTC - 2)", "Offset": "-2 hours"}
      { "Abbreviation" :"PMST", "Name": "Pierre & Miquelon Standard Time", "DisplayName": "Pierre & Miquelon Standard Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"PONT", "Name": "Pohnpei Standard Time", "DisplayName": "Pohnpei Standard Time(UTC + 11)", "Offset": "11 hours"}
      { "Abbreviation" :"PST", "Name": "Pacific Standard Time", "DisplayName": "Pacific Standard Time(UTC - 8)", "Offset": "-8 hours"}
      { "Abbreviation" :"PST", "Name": "Pitcairn Standard Time", "DisplayName": "Pitcairn Standard Time(UTC - 8)", "Offset": "-8 hours"}
      { "Abbreviation" :"PT", "Name": "Tiempo del Pacífico", "DisplayName": "Tiempo del Pacífico(UTC - 8)", "Offset": "-8 hours"}
      { "Abbreviation" :"PWT", "Name": "Palau Time", "DisplayName": "Palau Time(UTC + 9)", "Offset": "9 hours"}
      { "Abbreviation" :"PYST", "Name": "Paraguay Summer Time", "DisplayName": "Paraguay Summer Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"PYT", "Name": "Paraguay Time", "DisplayName": "Paraguay Time(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"Q", "Name": "Quebec Time Zone", "DisplayName": "Quebec Time Zone(UTC - 4)", "Offset": "-4 hours"}
      { "Abbreviation" :"R", "Name": "Romeo Time Zone", "DisplayName": "Romeo Time Zone(UTC - 5)", "Offset": "-5 hours"}
      { "Abbreviation" :"RET", "Name": "Reunion Time", "DisplayName": "Reunion Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"S", "Name": "Sierra Time Zone", "DisplayName": "Sierra Time Zone(UTC - 6)", "Offset": "-6 hours"}
      { "Abbreviation" :"SAMT", "Name": "Samara Time", "DisplayName": "Samara Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"SAST", "Name": "South Africa Standard Time", "DisplayName": "South Africa Standard Time(UTC + 2)", "Offset": "2 hours"}
      { "Abbreviation" :"SBT", "Name": "Solomon IslandsTime", "DisplayName": "Solomon IslandsTime(UTC + 11)", "Offset": "11 hours"}
      { "Abbreviation" :"SCT", "Name": "Seychelles Time", "DisplayName": "Seychelles Time(UTC + 4)", "Offset": "4 hours"}
      { "Abbreviation" :"SGT", "Name": "Singapore Time", "DisplayName": "Singapore Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"SRT", "Name": "Suriname Time", "DisplayName": "Suriname Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"SST", "Name": "Samoa Standard Time", "DisplayName": "Samoa Standard Time(UTC - 11)", "Offset": "-11 hours"}
      { "Abbreviation" :"T", "Name": "Tango Time Zone", "DisplayName": "Tango Time Zone(UTC - 7)", "Offset": "-7 hours"}
      { "Abbreviation" :"TAHT", "Name": "Tahiti Time", "DisplayName": "Tahiti Time(UTC - 10)", "Offset": "-10 hours"}
      { "Abbreviation" :"TFT", "Name": "French Southern and Antarctic Time", "DisplayName": "French Southern and Antarctic Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"TJT", "Name": "Tajikistan Time", "DisplayName": "Tajikistan Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"TKT", "Name": "Tokelau Time", "DisplayName": "Tokelau Time(UTC + 13)", "Offset": "13 hours"}
      { "Abbreviation" :"TLT", "Name": "East Timor Time", "DisplayName": "East Timor Time(UTC + 9)", "Offset": "9 hours"}
      { "Abbreviation" :"TMT", "Name": "Turkmenistan Time", "DisplayName": "Turkmenistan Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"TVT", "Name": "Tuvalu Time", "DisplayName": "Tuvalu Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"U", "Name": "Uniform Time Zone", "DisplayName": "Uniform Time Zone(UTC - 8)", "Offset": "-8 hours"}
      { "Abbreviation" :"ULAT", "Name": "Ulaanbaatar Time", "DisplayName": "Ulaanbaatar Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"UTC", "Name": "Coordinated Universal Time", "DisplayName": "Coordinated Universal Time(UTC)", "Offset": "0 hours"}
      { "Abbreviation" :"UYST", "Name": "Uruguay Summer Time", "DisplayName": "Uruguay Summer Time(UTC - 2)", "Offset": "-2 hours"}
      { "Abbreviation" :"UYT", "Name": "Uruguay Time", "DisplayName": "Uruguay Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"UZT", "Name": "Uzbekistan Time", "DisplayName": "Uzbekistan Time(UTC + 5)", "Offset": "5 hours"}
      { "Abbreviation" :"V", "Name": "Victor Time Zone", "DisplayName": "Victor Time Zone(UTC - 9)", "Offset": "-9 hours"}
      { "Abbreviation" :"VET", "Name": "Venezuelan Standard Time", "DisplayName": "Venezuelan Standard Time(UTC - 4:30)", "Offset": "-4:30 hours"}
      { "Abbreviation" :"VLAST", "Name": "Vladivostok Summer Time", "DisplayName": "Vladivostok Summer Time(UTC + 11)", "Offset": "11 hours"}
      { "Abbreviation" :"VLAT", "Name": "Vladivostok Time", "DisplayName": "Vladivostok Time(UTC + 11)", "Offset": "11 hours"}
      { "Abbreviation" :"VUT", "Name": "Vanuatu Time", "DisplayName": "Vanuatu Time(UTC + 11)", "Offset": "11 hours"}
      { "Abbreviation" :"W", "Name": "Whiskey Time Zone", "DisplayName": "Whiskey Time Zone(UTC - 10)", "Offset": "-10 hours"}
      { "Abbreviation" :"WAST", "Name": "West Africa Summer Time", "DisplayName": "West Africa Summer Time(UTC + 2)", "Offset": "2 hours"}
      { "Abbreviation" :"WAT", "Name": "West Africa Time", "DisplayName": "West Africa Time(UTC + 1)", "Offset": "1 hours"}
      { "Abbreviation" :"WEST", "Name": "Western European Summer Time", "DisplayName": "Western European Summer Time(UTC + 1)", "Offset": "1 hours"}
      { "Abbreviation" :"WESZ", "Name": "Westeuropäische Sommerzeit", "DisplayName": "Westeuropäische Sommerzeit(UTC + 1)", "Offset": "1 hours"}
      { "Abbreviation" :"WET", "Name": "Western European Time", "DisplayName": "Western European Time(UTC)", "Offset": "0 hours"}
      { "Abbreviation" :"WEZ", "Name": "Westeuropäische Zeit", "DisplayName": "Westeuropäische Zeit(UTC)", "Offset": "0 hours"}
      { "Abbreviation" :"WFT", "Name": "Wallis and Futuna Time", "DisplayName": "Wallis and Futuna Time(UTC + 12)", "Offset": "12 hours"}
      { "Abbreviation" :"WGST", "Name": "Western Greenland Summer Time", "DisplayName": "Western Greenland Summer Time(UTC - 2)", "Offset": "-2 hours"}
      { "Abbreviation" :"WGT", "Name": "West Greenland Time", "DisplayName": "West Greenland Time(UTC - 3)", "Offset": "-3 hours"}
      { "Abbreviation" :"WIB", "Name": "Western Indonesian Time", "DisplayName": "Western Indonesian Time(UTC + 7)", "Offset": "7 hours"}
      { "Abbreviation" :"WIT", "Name": "Eastern Indonesian Time", "DisplayName": "Eastern Indonesian Time(UTC + 9)", "Offset": "9 hours"}
      { "Abbreviation" :"WITA", "Name": "Central Indonesian Time", "DisplayName": "Central Indonesian Time(UTC + 8)", "Offset": "8 hours"}
      { "Abbreviation" :"WST", "Name": "Western Sahara Summer Time", "DisplayName": "Western Sahara Summer Time(UTC + 1)", "Offset": "1 hours"}
      { "Abbreviation" :"WST", "Name": "West Samoa Time", "DisplayName": "West Samoa Time(UTC + 13)", "Offset": "13 hours"}
      { "Abbreviation" :"WT", "Name": "Western Sahara Standard Time", "DisplayName": "Western Sahara Standard Time(UTC)", "Offset": "0 hours"}
      { "Abbreviation" :"X", "Name": "X-ray Time Zone", "DisplayName": "X-ray Time Zone(UTC - 11)", "Offset": "-11 hours"}
      { "Abbreviation" :"Y", "Name": "Yankee Time Zone", "DisplayName": "Yankee Time Zone(UTC - 12)", "Offset": "-12 hours"}
      { "Abbreviation" :"YAKST", "Name": "Yakutsk Summer Time", "DisplayName": "Yakutsk Summer Time(UTC + 10)", "Offset": "10 hours"}
      { "Abbreviation" :"YAKT", "Name": "Yakutsk Time", "DisplayName": "Yakutsk Time(UTC + 10)", "Offset": "10 hours"}
      { "Abbreviation" :"YAPT", "Name": "Yap Time", "DisplayName": "Yap Time(UTC + 10)", "Offset": "10 hours"}
      { "Abbreviation" :"YEKST", "Name": "Yekaterinburg Summer Time", "DisplayName": "Yekaterinburg Summer Time(UTC + 6)", "Offset": "6 hours"}
      { "Abbreviation" :"YEKT", "Name": " Yekaterinburg Time", "DisplayName": " Yekaterinburg Time(UTC + 6)", "Offset": "6 hours"}
      { "Abbreviation" :"Z", "Name": "Zulu Time Zone", "DisplayName": "Zulu Time Zone(UTC)", "Offset": "0 hours"}
    ]

  Labels:
    {
      "type": "Type"
      "source": "Source"
      "source_phone": "Source Phone"
      "caseid": "Case ID"
      "date": "Date"
      "hf": "HF"
      "Name": "Name"
      "Age": "Age"
      "Shehia": "Shehia"
      "IsShehiaValid": "Is Shehia Valid?"
      "HighRiskShehia": "High Risk Shehia"
      "Village": "Village"
      "Sex": "Sex"
      "positive_test_date": "Positive Test Date"
      "facility": "Facility"
      "FacilityType": "Facility Type"
      "facility_district": "District of Facility"
      "district": "District (if no household district uses facility)"
      "SMSSent": "SMS Sent"
      "numbersSentTo": "Numbers Sent To"
      "HasCaseNotification": "Has Case Notification"
      "CaseNotification": "Case Notification"
      "MalariaCaseID": "Malaria Case ID"
      "FacilityName": "Facility Name"
      "DateOfPositiveResults": "Date of Positive Results"
      "ReferenceInOpdRegister": "Reference in OPD Register"
      "FirstName": "First Name"
      "MiddleName": "Middle Name"
      "LastName": "Last Name"
      "ShehaMjumbe": "Sheha Mjumbe"
      "HeadOfHouseholdName": "Head of Household Name"
      "ContactMobilePatientRelative": "Contact Mobile Patient Relative"
      "TreatmentGiven": "Treatment Given"
      "TreatmentProvided": "Treatment Provided"
      "IfYesListAllPlacesTravelled": "All Places Traveled to in Past Month"
      "CaseIdForOtherHouseholdMemberThatTestedPositiveAtAHealthFacility": "CaseID For Other Household Member That Tested Positive at a Health Facility"
      "CommentRemarks": "Comment Remarks"
      "ParasiteSpecies": "Parasite Species"
      "AgeInMonthsOrYears": "Age in Months or Years"
      "isUnder5": "Is Under 5"
      "TravelledOvernightInPastMonth": "Travelled Overnight in Past Month"
      "HasSomeoneFromTheSameHouseholdRecentlyTestedPositiveAtAHealthFacility": "Has Someone From The Same Household Recently Tested Positive at a Health Facility"
      "ReasonForVisitingHousehold": "Reason For Visiting Household"
      "CurrentBodyTemperatureC": "Current Body Temperature (C)"
      "IfYesListAllPlacesTravelled": "If Yes List All Places Travelled"
      "AgeInYearsOrMonths": "Age in Years or Months"
      "ageInYears": "Age In Years"
      "FeverCurrentlyOrInTheLastTwoWeeks": "Fever Currently Or In The Last Two Weeks?"
      "MalariaTestResult": "Malaria Test Result"
      "SleptUnderLlinLastNight": "Slept Under LLIN Last Night?"
      "OvernightTravelInPastMonth": "Overnight Travel in Past Month"
      "ResidentOfShehia": "Resident of Shehia"
      "FollowupNeighbors": "Follow up Neighbors?"
      "Numberofotherhouseholdswithin50stepsofindexcasehousehold": "Number of Other Households Within 50 Steps of Index Case Household"
      "NumberOfOtherHouseholdsWithin50StepsOfIndexCaseHousehold": "Number of Other Households Within 50 Steps of Index Case Household"
      "TotalNumberOfResidentsInTheHousehold": "Total Number of Residents in the Household"
      "NumberOfLlin": "Number of LLIN"
      "NumberOfSleepingPlacesBedsMattresses": "Number of Sleeping Places (Beds/Mattresses)"
      "CouponNumbers": "Coupon Numbers"
      "NumberOfHouseholdMembersWithFeverOrHistoryOfFeverWithinPastWeek": "Number of Household Members With Fever or History of Fever Within Past Week"
      "NumberOfHouseholdMembersTreatedForMalariaWithinPastWeek": "Number of Household Members Treated for Malaria Within Past Week"
      "LastDateOfIrs": "Last Date of IRS"
      "HaveYouGivenCouponsForNets": "Have you given coupon(s) for nets?"
      "IndexCaseIfPatientIsFemale1545YearsOfAgeIsSheIsPregant": "Index Case: If Patient is Female 15-45 Years of Age, Is She Pregnant?"
      "IndexCasePatientSCurrentStatus": "Index case: Patient's current status"
      "IndexCasePatientSTreatmentStatus": "Index case: Patient's treatment status"
      "IndexCasePatientName": "Patient Name"
      "IndexCaseOvernightTravelOutsideOfZanzibarInThePastYearasePatient": "Index Case Patient"
      "IndexCaseSleptUnderLlinLastNight": "Index case: Slept under LLIN last night?"
      "IndexCaseOvernightTravelOutsideOfZanzibarInThePastYear": "Index Case Overnight Travel Outside of Zanzibar in the Past Year"
      "IndexCaseOvernightTravelWithinZanzibar1024DaysBeforePositiveTestResult": "Index Case Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
      "AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar07DaysBeforePositiveTestResult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 0-7 Days Before Positive Test Result"
      "AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar814DaysBeforePositiveTestResult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 8-14 Days Before Positive Test Result"
      "AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar1521DaysBeforePositiveTestResult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 15-21 Days Before Positive Test Result"
      "AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar2242DaysBeforePositiveTestResult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 22-42 Days Before Positive Test Result"
      "AllLocationsAndEntryPointsFromOvernightTravelOutsideZanzibar43365DaysBeforePositiveTestResult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 43-365 Days Before Positive Test Result"
      "ListAllLocationsOfOvernightTravelWithinZanzibar1024DaysBeforePositiveTestResult": "All Locations Of Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
      "DaysBetweenPositiveResultAndNotificationFromFacility": "Days Between Positive Result at Facility and Case Notification"
      "LessThanOneDayBetweenPositiveResultAndNotificationFromFacility": "Less Than One Day Between Positive Result And Notification From Facility"
      "OneToTwoDaysBetweenPositiveResultAndNotificationFromFacility": "One To Two Days Between Positive Result And Notification From Facility"
      "TwoToThreeDaysBetweenPositiveResultAndNotificationFromFacility": "Two To Three Days Between Positive Result And Notification From Facility"
      "DaysFromCaseNotificationToCompleteFacility": "Days From Case Notification To Complete Facility"
      "DaysFromSmsToCompleteHousehold": "Days between SMS Senxt to DMSO to Having Complete Household"
      "Comments": "Comments"
      "CommentsOrRemarks": "Comments or Remarks"
      "HouseholdLocationDescription": "Household Location - Description"
      "HouseholdLocationLatitude": "Household Location - Latitude"
      "HouseholdLocationLongitude": "Household Location - Longitude"
      "HouseholdLocationAccuracy": "Household Location - Accuracy"
      "HouseholdLocationAltitude": " Household Location - Altitude"
      "HouseholdLocationAltitudeAccuracy": "Household Location - Altitude Accuracy"
      "HouseholdLocationHeading": "Household Location - Heading"
      "HouseholdLocationTimestamp": "Household Location - Timestamp"
      "Comments": "Comments"
      "TravelLocationName": "Travel Location Name"
      "IndexCaseOvernightTravelOutsideOfZanzibarInThePastYear": "Has Index Case had Overnight Travel Outside of Zanzibar in the Past Year"
      "OvernightTravelWithinZanzibar1024DaysBeforePositiveTestResult": "Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
      "OvernightTravelOutsideOfZanzibarInThePastYear": "Overnight Travel Outside of Zanzibar In The Past Year"
      "ReferredToHealthFacility": "Referred to Health Facility"
      "IndexCaseDiagnosisDate": "Index Case Diagnosis Date"
      "IndexCaseDiagnosisDateIsoWeek": "Index Case Diagnosis Date ISO Week"
      "HasCompleteFacility": "Has Complete Facility"
      "NotCompleteFacilityAfter24Hours": "Not Complete Facility After 24 Hours"
      "NotFollowedUpAfter48Hours": "Not Followed Up After 48 Hours"
      "FollowedUpWithin48Hours": "Followed Up Within 48Hours"
      "IndexCaseHasTravelHistory": "Index Case Has Travel History"
      "IndexCaseHasNoTravelHistory": "Index Case Has No Travel History"
      "CompleteHouseholdVisit": "Complete Household Visit"
      "NumberPositiveCasesAtIndexHousehold": "Number Positive Cases At Index Household"
      "NumberPositiveCasesAtIndexHouseholdAndNeighborHouseholds": "Number Positive Cases At Index Household And Neighbor Households"
      "NumberHouseholdOrNeighborMembersTested": "Number Household Or Neighbor Members Tested"
      "NumberPositiveCasesIncludingIndex": "Number Positive Cases Including Index"
      "NumberPositiveCasesAtIndexHouseholdAndNeighborHouseholdsUnder5": "Number Positive Cases At Index Household And Neighbor Households Under 5"
      "NumberSuspectedImportedCasesIncludingHouseholdMembers": "Number Suspected Imported Cases Including Household Members"
      "transferred": "Transfered"
      "deidentified": "Deidentified"
      "location_shifted": "Location Shifted"
      "date_shifted": "Date Shifted"
      "shift_amount": "Shift Amount"

#Old labels on old records needed until data camel cases have been cleaned up.
      "name": "Name"
      "shehia": "Shehia"
      "isShehiaValid": "Is Shehia Valid?"
      "highRiskShehia": "High Risk Shehia"
      "village": "Village"
      "facilityType": "Facility Type"
      "hasCaseNotification": "Has Case Notification"
      "caseNotification": "Case Notification"
      "DateofPositiveResults": "Date of Positive Results"
      "ReferenceinOPDRegister": "Reference in OPD Register"
      "HeadofHouseholdName": "Head of Household Name"
      "ContactMobilepatientrelative": "Contact Mobile Patient Relative"
      "IfYESlistALLplacestravelled": "All Places Traveled to in Past Month"
      "CaseIDforotherhouseholdmemberthattestedpositiveatahealthfacility": "CaseID For Other Household Member That Tested Positive at a Health Facility"
      "AgeinMonthsorYears": "Age in Months or Years"
      "TravelledOvernightinpastmonth": "Travelled Overnight in Past Month"
      "Hassomeonefromthesamehouseholdrecentlytestedpositiveatahealthfacility": "Has Someone From The Same Household Recently Tested Positive at a Health Facility"
      "Reasonforvisitinghousehold": "Reason For Visiting Household"
      "Ifyeslistallplacestravelled": "If Yes List All Places Travelled"
      "AgeinYearsorMonths": "Age in Years or Months"
      "Fevercurrentlyorinthelasttwoweeks": "Fever Currently Or In The Last Two Weeks?"
      "SleptunderLLINlastnight": "Slept Under LLIN Last Night?"
      "OvernightTravelinpastmonth": "Overnight Travel in Past Month"
      "ResidentofShehia": "Resident of Shehia"
      "TotalNumberofResidentsintheHousehold": "Total Number of Residents in the Household"
      "NumberofLLIN": "Number of LLIN"
      "NumberofSleepingPlacesbedsmattresses": "Number of Sleeping Places (Beds/Mattresses)"
      "NumberofHouseholdMemberswithFeverorHistoryofFeverWithinPastWeek": "Number of Household Members With Fever or History of Fever Within Past Week"
      "NumberofHouseholdMembersTreatedforMalariaWithinPastWeek": "Number of Household Members Treated for Malaria Within Past Week"
      "LastdateofIRS": "Last Date of IRS"
      "Haveyougivencouponsfornets": "Have you given coupon(s) for nets?"
      "IndexcaseIfpatientisfemale1545yearsofageissheispregant": "Index Case: If Patient is Female 15-45 Years of Age, Is She Pregnant?"
      "IndexcasePatientscurrentstatus": "Index case: Patient's current status"
      "IndexcasePatientstreatmentstatus": "Index case: Patient's treatment status"
      "indexCasePatientName": "Patient Name"
      "IndexcasePatient": "Index Case Patient"
      "IndexcaseSleptunderLLINlastnight": "Index case: Slept under LLIN last night?"
      "IndexcaseOvernightTraveloutsideofZanzibarinthepastyear": "Index Case Overnight Travel Outside of Zanzibar in the Past Year"
      "IndexcaseOvernightTravelwithinZanzibar1024daysbeforepositivetestresult": "Index Case Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
      "AlllocationsandentrypointsfromovernighttraveloutsideZanzibar07daysbeforepositivetestresult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 0-7 Days Before Positive Test Result"
      "AlllocationsandentrypointsfromovernighttraveloutsideZanzibar814daysbeforepositivetestresult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 8-14 Days Before Positive Test Result"
      "AlllocationsandentrypointsfromovernighttraveloutsideZanzibar1521daysbeforepositivetestresult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 15-21 Days Before Positive Test Result"
      "AlllocationsandentrypointsfromovernighttraveloutsideZanzibar2242daysbeforepositivetestresult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 22-42 Days Before Positive Test Result"
      "AlllocationsandentrypointsfromovernighttraveloutsideZanzibar43365daysbeforepositivetestresult": "All Locations and Entry Points From Overnight Travel Outside Zanzibar 43-365 Days Before Positive Test Result"
      "ListalllocationsofovernighttravelwithinZanzibar1024daysbeforepositivetestresult": "All Locations Of Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
      "daysBetweenPositiveResultAndNotificationFromFacility": "Days Between Positive Result at Facility and Case Notification"
      "lessThanOneDayBetweenPositiveResultAndNotificationFromFacility": "Less Than One Day Between Positive Result And Notification From Facility"
      "oneToTwoDaysBetweenPositiveResultAndNotificationFromFacility": "One To Two Days Between Positive Result And Notification From Facility"
      "twoToThreeDaysBetweenPositiveResultAndNotificationFromFacility": "Two To Three Days Between Positive Result And Notification From Facility"
      "moreThanThreeDaysBetweenPositiveResultAndNotificationFromFacility": "More Than Three Days Between Positive Result And Notification From Facility"
      "daysBetweenPositiveResultAndCompleteHousehold": "Days Between Positive Result And Complete Household"
      "lessThanOneDayBetweenPositiveResultAndCompleteHousehold": "Less Than One Day Between Positive Result And Complete Household"
      "oneToTwoDaysBetweenPositiveResultAndCompleteHousehold": "One To Two Days Between Positive Result And Complete Household"
      "twoToThreeDaysBetweenPositiveResultAndCompleteHousehold": "Two To Three Days Between Positive Result And Complete Household"
      "moreThanThreeDaysBetweenPositiveResultAndCompleteHousehold": "More Than Three Days Between Positive Result And Complete Household"
      "daysFromCaseNotificationToCompleteFacility": "Days From Case Notification To Complete Facility"
      "daysFromSMSToCompleteHousehold": "Days between SMS Sent to DMSO to Having Complete Household"
      "HouseholdLocation-description": "Household Location - Description"
      "HouseholdLocation-latitude": "Household Location - Latitude"
      "HouseholdLocation-longitude": "Household Location - Longitude"
      "HouseholdLocation-accuracy": "Household Location - Accuracy"
      "HouseholdLocation-altitude": "Household Location - Altitude"
      "HouseholdLocation-altitudeAccuracy": "Household Location - Altitude Accuracy"
      "HouseholdLocation-heading": "Household Location - Heading"
      "HouseholdLocation-timestamp": "Household Location - Timestamp"
      "travelLocationName": "Travel Location Name"
      "OvernightTravelwithinZanzibar1024daysbeforepositivetestresult": "Overnight Travel Within Zanzibar 10-24 Days Before Positive Test Result"
      "OvernightTraveloutsideofZanzibarinthepastyear": "Overnight Travel Outside of Zanzibar In The Past Year"
      "ReferredtoHealthFacility": "Referred to Health Facility"
      "indexCaseDiagnosisDate": "Index Case Diagnosis Date"
      "hasCompleteFacility": "Has Complete Facility"
      "notCompleteFacilityAfter24Hours": "Not Complete Facility After 24 Hours"
      "notFollowedUpAfter48Hours": "Not Followed Up After 48 Hours"
      "followedUpWithin48Hours": "Followed Up Within 48Hours"
      "indexCaseHasTravelHistory": "Index Case Has Travel History"
      "indexCaseHasNoTravelHistory": "Index Case Has No Travel History"
      "completeHouseholdVisit": "Complete Household Visit"
      "numberPositiveCasesAtIndexHousehold": "Number Positive Cases At Index Household"
      "numberPositiveCasesAtIndexHouseholdAndNeighborHouseholds": "Number Positive Cases At Index Household And Neighbor Households"
      "numberHouseholdOrNeighborMembersTested": "Number Household Or Neighbor Members Tested"
      "numberPositiveCasesIncludingIndex": "Number Positive Cases Including Index"
      "numberPositiveCasesAtIndexHouseholdAndNeighborHouseholdsUnder5": "Number Positive Cases At Index Household And Neighbor Households Under 5"
      "numberSuspectedImportedCasesIncludingHouseholdMembers": "Number Suspected Imported Cases Including Household Members"
    }
