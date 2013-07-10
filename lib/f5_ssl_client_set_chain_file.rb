require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

# only works with 11.0 and up
class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_ssl_client_profile_set_chain_file.rb [options]"
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
      
         
      opts.on("-c", "--chain-name CHAIN_NAME", "Name of SSL Chain File") do |chain_name|
        options.chain_name = chain_name
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
pp "made it through options parsing"

REQ_PARAMS = [:bigip, :profile_name, :chain_name, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file =>  options.bigip_conn_conf, :connect_timeout => 10)

SSLClientProfileString = Struct.new(:name, :default_flag) do
  def to_hash
   { 'value' => self.name, 'default_flag' => self.default_flag }
  end
end

def set_ssl_client_chain_file(lb, profile_list, chain_list)
  lb.icontrol.locallb.profile_client_ssl.set_chain_file(profile_list, chain_list)
end

profile_list = [options.profile_name]
my_chain_profile_string = SSLClientProfileString.new(options.chain_name, "false")
my_chain_list = [my_chain_profile_string.to_hash]

set_ssl_client_chain_file(lb, profile_list, my_chain_list)

# example
# ruby f5_ssl_client_profile_create.rb --bigip_conn_conf ..\fixtures\config-andy.yaml --bigip 192.168.106.16 -k andy.iscool.pleasework.com.key -c andy.iscool.pleasework.com.crt -p andy.iscool.pleasework.com_ssl