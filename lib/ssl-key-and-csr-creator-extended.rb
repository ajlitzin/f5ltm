#!/usr/bin/ruby

# from https://devcentral.f5.com/wiki/iControl.SSLKeyAndCSRCreator.ashx

require "rubygems"
require "f5-icontrol"
require "getoptlong"

options = GetoptLong.new(
  [ "--bigip-address",    "-b",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--bigip-user",       "-u",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--bigip-pass",       "-p",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--key-type",         "-t",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--key-id",           "-i",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--key-bit-length",   "-l",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--key-security",     "-s",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--common-name",              GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--country",                  GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--state",                    GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--locality",                 GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--organization",             GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--division",                 GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--output-dir",       "-o",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--fqdns-list",       "-q",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--no-overwrite",     "-n",   GetoptLong::NO_ARGUMENT ],
  [ "--key-output",       "-k",   GetoptLong::NO_ARGUMENT ],
  [ "--csr-output",       "-c",   GetoptLong::NO_ARGUMENT ],
  [ "--help",             "-h",   GetoptLong::NO_ARGUMENT ]
)

def usage 
  puts $0 + " -b <BIG-IP address> -u <BIG-IP user> -i <key ID>"
  puts
  puts "BIG-IP connection parameters"
  puts "-" * 20
  puts "  -b  (--bigip-address)   BIG-IP management-accessible address"
  puts "  -u  (--bigip-user)      BIG-IP username"
  puts "  -p  (--bigip-pass)      BIG-IP password (will prompt if left blank"
  puts
  puts "Private key parameters"
  puts "-" * 20
  puts "  -i  (--key-id)          key ID: must be unique and should be indicative of the purpose (defaults to common name if left blank)"
  puts "  -t  (--key-type)        key type: [RSA|DSA] (default is 'RSA')"
  puts "  -l  (--key-bit-length)  key bit length: should be a minimum of 1024-bit (default is 2048; most CAs won't sign weaker keys)"
  puts "  -s  (--key-security)    key security: [normal|fips|password] (default is 'normal' with no passphrase)"
  puts
  puts "X.509 data parameters (if blank, you'll be prompted for the answers)"
  puts "-" * 20
  puts "      (--common-name)     common name: FQDN for virtual server (www.example.com)"
  puts "      (--country)         country: two letter country abbreviation (US, CN, etc.)"
  puts "      (--state)           state: two letter state abbreviation (WA, OR, CA, etc.)"
  puts "      (--locality)        locality: locality or city name (Seattle, Portland, etc.)"
  puts "      (--organization)    organization: organization or company name (F5 Networks, Company XYZ, etc.)"
  puts "      (--division)        division: department or division name (IT, HR, Finance, etc.)"
  puts
  puts "Output options"
  puts "-" * 20
  puts "  -o  (--output-dir)      CSR/key output directory: location to output private key and CSR files (defaults to current working directory)"
  puts "  -k  (--key-output)      key output: save private key to a local file (saved as key_id.key)"
  puts "  -c  (--csr-output)      CSR output: save certificate signing request to a local file (saved as key_id.csr)"
  puts
  puts "Misc options"
  puts "-" * 20
  puts "  -q  (--fqdns-list)      a file containing line separated Fully Qualified Domain Names for CNs"
  puts "  -y  (--overwrite)    overwrite existing conflicting IDs"
  puts
  puts
  puts "Help and usage"
  puts "-" * 20
  puts "  -h  (--help)            shows this help/usage dialog"
  puts

  exit
end

# set STDOUT buffer to synchronous
STDOUT.sync = true

# global variables
KEY_TYPES = { "RSA" => "KTYPE_RSA_PRIVATE", "DSA" => "KTYPE_DSA_PRIVATE" }
KEY_SECURITIES = { "normal" => "STYPE_NORMAL", "fips" => "STYPE_FIPS", "password" => "STYPE_PASSWORD" }

# initial parameter values
overwrite_key = false
fqdns_list = ''

# key/CSR default output file values
key_output = false
csr_output = false
output_dir = Dir.pwd

# BIG-IP connection parameters
bigip = {}
bigip['address'] = ''
bigip['user'] = ''
bigip['pass'] = ''

# private key parameters
key_data = {}
key_data['id'] = ''
key_data['key_type'] = KEY_TYPES["RSA"]
key_data['bit_length'] = 2048
key_data['security'] = KEY_SECURITIES["normal"]

# X.509 data parameters
x509_data = {}
x509_data['common_name'] = ''
x509_data['country_name'] = ''
x509_data['state_name'] = ''
x509_data['locality_name'] = ''
x509_data['organization_name'] = ''
x509_data['division_name'] = ''

# loop through command line options
options.each do |option, arg|
  case option
    when "--bigip-address"
      bigip['address'] = arg
    when "--bigip-user"
      bigip['user'] = arg
    when "--bigip-pass"
      bigip['pass'] = arg
    when "--key-id"
      key_data['id'] = arg
    when "--key-type"
      if KEY_TYPES.keys.include? arg.upcase
        key_data['key_type'] = KEY_TYPES[arg.upcase]
      else
        puts "Error: Invalid key type. Exiting."
        exit 1
      end
    when "--key-bit-length"
      key_data['bit_length'] = arg.to_i
    when "--key-security"
      if KEY_SECURITIES.keys.include? arg.downcase
        key_data['security'] = KEY_SECURITIES[arg.downcase]
      else
        puts "Error: Invalid key security type. Exiting."
        exit 1
      end
    when "--common-name"
      x509_data['common_name'] = arg
    when "--country"
      if arg =~ /[a-z]{2}/i
        x509_data['country_name'] = arg.upcase
      else
        puts "Error: Use exactly two letters for the country code. Exiting."
        exit 1
      end
    when "--state"
      x509_data['state_name'] = arg
    when "--locality"
      x509_data['locality_name'] = arg
    when "--organization"
      x509_data['organization_name'] = arg
    when "--division"
      x509_data['division_name'] = arg
    when "--output-dir"
      if File.directory? arg
        output_dir = arg
      else
        puts "Error: Invalid directory for output. Exiting."
      end
    when "--key-output"
      key_output = true
    when "--csr-output"
      csr_output = true
    when "--overwrite"
      overwrite_key = true
    when "--fqdns-list"
        fqdns_list = arg
    when "--help"
      usage
  end
end

# we need at least the BIG-IP's address, user, and a key ID to proceed

usage if bigip['address'].empty? or bigip['user'].empty?

if bigip['pass'].empty?
  puts "Please enter the BIG-IPs password..."
  print "Password: "
  system("stty", "-echo")
  bigip['pass'] = gets.chomp
  system("stty", "echo")
  puts
end

# set up connection to BIG-IP and Management.KeyCertificate interface

bigip = F5::IControl.new(bigip['address'], bigip['user'], bigip['pass'], ["Management.KeyCertificate"]).get_interfaces

unless fqdns_list.empty?  
  fqdns_file = File.open(fqdns_list, "r")
  # set common name to a temp value so you don't get prompted for it
  # gets overwritten later when using an fqdns_file
  x509_data['common_name'] = 'temp.value'
end

# time to play 20 questions with the X.509 data

if x509_data.values.delete_if { |value| !value.empty? }.size > 0
  puts "Please fill in the following X.509 data parameters..."
end

x509_data.sort.each do |key, value| 
  if value.empty?
    print key.capitalize.gsub('_', ' ') + "? "
    x509_data[key] = gets.chomp
  end
end

#grab a list of existing keys and confirm overwrite if a conflict exists

existing_keys = bigip["Management.KeyCertificate"].get_key_list('MANAGEMENT_MODE_DEFAULT').collect { |key| key["key_info"]["id"] }

if fqdns_list.empty?
  fqdns_file = [x509_data['common_name']]
end
  
fqdns_file.each do |cur_fqdn|
  puts " cur fqdn is #{cur_fqdn}"
  x509_data['common_name'] = cur_fqdn.chomp
  # basically ignoring user input key id here- should write better logic around this
  key_data['id'] = cur_fqdn.chomp
  puts "key_data id is #{key_data['id']}"
  
  # print a warning that there is a key id overlap.  later logic decides whether or not to overwrite
  if existing_keys.include? key_data['id']
    print "A key with an ID of '#{key_data['id']}' already exists."
  end

  bigip["Management.KeyCertificate"].key_generate('MANAGEMENT_MODE_DEFAULT', [key_data], [x509_data], true, overwrite_key)

  # write private key to local file if specified by user

  if key_output
    key_output_file = output_dir + "/" + key_data['id'] + ".key"
    key = bigip["Management.KeyCertificate"].key_export_to_pem('MANAGEMENT_MODE_DEFAULT', [key_data['id']])[0]
    File.open(key_output_file, 'w') { |file| file.write(key) }
  end

  # display subject information for CSR as well as the CSR

  puts "Certificate Request"
  puts "-" * 20
  puts "Subject: C=#{x509_data['country_name']}, ST=#{x509_data['state_name']}, L=#{x509_data['locality_name']}, O=#{x509_data['organization_name']}, OU=#{x509_data['division_name']}, CN=#{x509_data['common_name']}"

  csr = bigip["Management.KeyCertificate"].certificate_request_export_to_pem('MANAGEMENT_MODE_DEFAULT', [key_data['id']])

  # write csr key to local file if specified by user

  if csr_output
    csr_output_file = output_dir + "/" + key_data['id'] + ".csr"
    File.open(csr_output_file, 'w') { |file| file.write(csr) }
  end

  puts
  puts csr
 end # fqdn loop
 
 ### examples
 ## using a list of fqdns
 # ruby ssl-key-and-csr-creator-extended.rb -b 192.168.106.16 --country US --state Washington --locality Seattle --organization 'thePlatform for Media, Inc' --division 'Network Operations' --output-dir ../csrs/ -c -q ../private-fixtures/fqdns-for-csrs.yml -u andy.litzinger
 # a single fqdn
 # ruby ssl-key-and-csr-creator-extended.rb -b 192.168.106.16 --country US --state Washington --locality Seattle --organization 'thePlatform for Media, Inc' --division 'Network Operations' --common-name andy.test.com --output-dir ../csrs/ -c -u andy.litzinger