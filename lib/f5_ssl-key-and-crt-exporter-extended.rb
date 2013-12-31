#!/usr/bin/ruby

# from https://devcentral.f5.com/wiki/iControl.SSLKeyAndCSRCreator.ashx

require "rubygems"
require "f5-icontrol"
require "getoptlong"

options = GetoptLong.new(
  [ "--bigip-address",    "-b",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--bigip-user",       "-u",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--bigip-pass",       "-p",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--key-id",           "-i",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--output-dir",       "-o",   GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--key-output",       "-k",   GetoptLong::NO_ARGUMENT ],
  [ "--crt-output",       "-c",   GetoptLong::NO_ARGUMENT ],
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
  puts "Output options"
  puts "-" * 20
  puts "  -o  (--output-dir)      CSR/key output directory: location to output private key and CSR files (defaults to current working directory)"
  puts "  -k  (--key-output)      key output: save private key to a local file (saved as key_id.key)"
  puts "  -c  (--crt-output)      CSR output: save certificate signing request to a local file (saved as key_id.csr)"
  puts
  puts "Misc options"
  puts "-" * 20
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

# key/CSR default output file values
key_output = false
crt_output = false
output_dir = Dir.pwd

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
    when "--output-dir"
      if File.directory? arg
        output_dir = arg
      else
        puts "Error: Invalid directory for output. Exiting."
      end
    when "--key-output"
      key_output = true
    when "--crt-output"
      crt_output = true
    when "--overwrite"
      overwrite_key = true
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

# grab a list of existing keys

existing_keys = bigip["Management.KeyCertificate"].get_key_list('MANAGEMENT_MODE_DEFAULT').collect { |key| key["key_info"]["id"] }

puts "existing_keys: #{existing_keys}"
  
existing_keys.each do |cur_fqdn|
  puts " cur fqdn is #{cur_fqdn}"
  
  key_data['id'] = cur_fqdn.chomp
   
  puts "key_data id is #{key_data['id']}"
  
 # write private key to local file if specified by user

  if key_output
    # v11+ puts "/Common/" in the names of the keys/certs, strip it out so we can write it to a dir
    if cur_fqdn.match(/^\/Common\//) then
      path_fqdn = cur_fqdn.chomp.sub(/^\/Common\//,'')
      puts "path fqdn is #{path_fqdn}"
    end
    key_output_file = output_dir + "/" + path_fqdn + ".key"
    key = bigip["Management.KeyCertificate"].key_export_to_pem('MANAGEMENT_MODE_DEFAULT', [key_data['id']])[0]
    File.open(key_output_file, 'w') { |file| file.write(key) }
  end

  # grab cert
  crt = bigip["Management.KeyCertificate"].certificate_export_to_pem('MANAGEMENT_MODE_DEFAULT', [key_data['id']])

  # dump cert to local file if specified by user
  if crt_output
  # v11+ puts "/Common/" in the names of the keys/certs, strip it out so we can write it to a dir
    if cur_fqdn.match(/^\/Common\//) then
      path_fqdn = cur_fqdn.chomp.sub(/^\/Common\//,'')
      puts "path fqdn is #{path_fqdn}"
    end
    crt_output_file = output_dir + "/" + path_fqdn + ".crt"
    File.open(crt_output_file, 'w') { |file| file.write(crt[0]) }
  end

  # print out cert to stdout
  puts
  puts crt
 end # fqdn loop
 
 ### examples
 ## dump all keys and certs
 # ruby ssl-key-and-crt-exporter-extended.rb -b 192.168.106.16 --output-dir ../private-fixtures/exported-ssl/ -c -k -u andy.litzinger
 