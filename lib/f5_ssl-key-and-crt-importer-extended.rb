#!/usr/bin/ruby

# some code taken from https://devcentral.f5.com/wiki/iControl.SSLKeyAndCSRCreator.ashx

require "rubygems"
require "f5-icontrol"
require "getoptlong"

options = GetoptLong.new(
  [ "--bigip-address",    "-b",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--bigip-user",       "-u",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--bigip-pass",       "-p",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--key-id",           "-i",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--input-dir",       "-o",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--overwrite-key",   "-k",   GetoptLong::NO_ARGUMENT ],
  [ "--overwrite-cert",   "-c",   GetoptLong::NO_ARGUMENT ],
  [ "--verbose",   "-v",   GetoptLong::NO_ARGUMENT ],
  [ "--quiet",   "-q",   GetoptLong::NO_ARGUMENT ],
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
  puts
  puts "input options"
  puts "-" * 20
  puts "  -o  (--input-dir)      CSR/key input directory: location to input private key and CSR files (defaults to current working directory)"
  puts
  puts "Misc options"
  puts "-" * 20
  puts "  -k  (--overwrite-key)    overwrite existing conflicting keys"
  puts
  puts "  -c  (--overwrite-cert)    overwrite existing conflicting certs"
  puts
  puts "  -v  (--verbose)    print debug output"
  puts
  puts "  -q  (--quiet)    don't print output"
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

# initial parameter values
overwrite_key = false
overwrite_cert = false
quiet = false
verbose = false

# default input file values
input_dir = Dir.pwd

# BIG-IP connection parameters
bigip = {}
bigip['address'] = ''
bigip['user'] = ''
bigip['pass'] = ''

# private key parameters
key_data = {}
key_data['id'] = ''

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
    when "--input-dir"
      if File.directory? arg
        input_dir = arg
      else
        puts "Error: Invalid directory for input. Exiting."
      end
    when "--overwrite-key"
      overwrite_key = true
    when "--overwrite-cert"
      overwrite_cert = true
    when "--verbose"
      verbose = true
    when "--quiet"
      quiet = true
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

# grab a list of keys
# expect keys and certs in same dir, with same name differing in suffix (.key, .crt)
keys = []
keys = Dir.entries(input_dir)
keys.select! { |key_files| key_files =~ /.*\.key/}
if verbose
  puts "list of keys: #{keys}"
end

keys.each do |cur_fqdn|
     
  # strip the .key suffix
  key_data['id'] = cur_fqdn.gsub(/\.key$/, '').chomp
  unless quiet
    puts "Uploading key for #{key_data['id']}"
  end
  
  key_input_file = input_dir + "/" + cur_fqdn
  cur_key_pem = File.read(key_input_file)
  
  if verbose
    puts "#{cur_key_pem}"
  end
  # import the key file
  begin
    bigip["Management.KeyCertificate"].key_import_from_pem('MANAGEMENT_MODE_DEFAULT', [key_data['id']], [cur_key_pem], overwrite_key)
  rescue Exception => msg
    puts msg  
  end  
  
  unless quiet
    puts "Uploading cert for #{key_data['id']}"
  end
  cert_input_file = input_dir + "/" + cur_fqdn.gsub(/\.key$/, '.crt')
  cur_cert_pem = File.read(cert_input_file)
  if verbose
    puts "#{cur_cert_pem}"
  end
  begin
    bigip["Management.KeyCertificate"].certificate_import_from_pem('MANAGEMENT_MODE_DEFAULT', [key_data['id']], [cur_cert_pem], overwrite_cert)
  rescue Exception => msg
    puts msg
  end
  
  # puts crt
end # fqdn loop
 
 ### examples
 ## dump all keys and certs
 # ruby f5_ssl-key-and-crt-importer-extended.rb -b 192.168.106.16 --input-dir ../private-fixtures/exported-ssl/ -u andy.litzinger
 