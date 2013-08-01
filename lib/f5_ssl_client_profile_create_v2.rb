require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_ssl_client_profile_create.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
          
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      
	    opts.on("-p", "--profile PROFILE_NAME", "Name of SSL Client Profile to create") do |name|
        options.profile_name = name
      end
      
      opts.on("-k", "--key-name KEY_NAME", "Name of SSL key") do |key_name|
        options.key_name = key_name
      end
      
      opts.on("-c", "--cert-name CERT_NAME", "Name of SSL Certificate") do |cert_name|
        options.cert_name = cert_name
      end
	  
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
      exit
      end
    end
    opts.parse!(args)
    options
  end # self.parse
end #class Optparser


# get command line options
options = Optparser.parse(ARGV)

REQ_PARAMS = [:bigip, :profile_name, :key_name, :cert_name, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file =>  options.bigip_conn_conf, :connect_timeout => 10)

SSLClientProfileString = Struct.new(:name, :default_flag) do
  def to_hash
   { 'value' => self.name, 'default_flag' => self.default_flag }
  end
end

def create_ssl_client_profile(lb, profile_list, key_list, cert_list)
  lb.icontrol.locallb.profile_client_ssl.create(profile_list, key_list, cert_list)
end

profile_list = [options.profile_name]
my_key_profile_string = SSLClientProfileString.new(options.key_name, "false")
my_cert_profile_string = SSLClientProfileString.new(options.cert_name, "false")
my_key_list = [my_key_profile_string.to_hash]
my_cert_list = [my_cert_profile_string.to_hash]

create_ssl_client_profile(lb, profile_list, my_key_list, my_cert_list)

# example
# ruby f5_ssl_client_profile_create.rb --bigip_conn_conf ..\fixtures\config-andy.yaml --bigip 192.168.106.16 -k andy.iscool.pleasework.com.key -c andy.iscool.pleasework.com.crt -p andy.iscool.pleasework.com_ssl