# this is our main file
#things to do

# make call to parse yaml file
# create monitor
# create pool (f5_pool_create)
# update pool members
## PGA
# update pool
## enable PGA?
## bind monitor
# create SSL profile?
# create vs (f5_vs_create)
# update vs
## snat?
## ssl_profile?
## vlans
## connection mirroring?
## bind irule?

require 'yaml'
require 'ostruct'
require 'optparse'
require 'pp'
require 'ruby-debug'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_pool_create.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.vsconf = "../fixtures/virtual_servers.yaml"
      
           
      opts.on( "-f", "--config Config File", "YAML config file") do |file|
        options.vsconf = file || "../fixtures/virtual_servers.yaml"
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

def create_member_list(member_list)
    member_flags = ""
    member_list.each do |member|
      member_flags << "--member #{member["memberdef"]} "
    end
    member_flags
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:vsconf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

# read into an open struct
vs_yaml_conf = OpenStruct.new(YAML.load_file(options.vsconf))

# presume that services are split by "servicen" in yaml conf
service_list = vs_yaml_conf.methods.grep(/service\d+$/)
pp vs_yaml_conf.pool["name"]
if service_list.empty?
  # create vs/pool/monitor/etc for the single service defined
  # how to DRY this up?
  puts "service list is empty"
  ### creating pool
  #debugger
  member_list = create_member_list(vs_yaml_conf.pool["pool_members"])
  output = %x{ruby f5_pool_create.rb --name #{vs_yaml_conf.pool["name"]} #{member_list} --bigip 192.168.106.13}
  
  ### creating virtual server
  pp "--bigip 192.168.106.13 --address #{vs_yaml_conf.virtual_server["address"].to_s}  --mask #{vs_yaml_conf.virtual_server["netmask"]} --name #{vs_yaml_conf.virtual_server["name"]} --port #{vs_yaml_conf.virtual_server["port"]} --protocol #{vs_yaml_conf.virtual_server["protocol"]} --resource_type #{vs_yaml_conf.virtual_server["resource_type"]} --pool_name #{vs_yaml_conf.virtual_server["default_pool_name"]} --profile_context #{vs_yaml_conf.virtual_server["profile_context"]}"
  
  #moreoutput = %x{ruby f5_vs_create.rb --bigip "192.168.106.13" --address #{vs_yaml_conf.virtual_server["address"].to_s}  --mask #{vs_yaml_conf.virtual_server["netmask"]} --name #{vs_yaml_conf.virtual_server["name"]} --port #{vs_yaml_conf.virtual_server["port"]}}
  
  output = %x{ruby f5_vs_create.rb --bigip 192.168.106.13 --address #{vs_yaml_conf.virtual_server["address"].to_s}  --mask #{vs_yaml_conf.virtual_server["netmask"]} --name #{vs_yaml_conf.virtual_server["name"]} --port #{vs_yaml_conf.virtual_server["port"]} --protocol #{vs_yaml_conf.virtual_server["protocol"]} --resource_type #{vs_yaml_conf.virtual_server["resource_type"]} --pool_name #{vs_yaml_conf.virtual_server["default_pool_name"]} --profile_context #{vs_yaml_conf.virtual_server["profile_context"]}}
else
  puts "service list is NOT empty, #{service_list}"
  service_list.each do
    # loop through each service and create vs/pool/monitor/etc
  end
end

#pp vs_yaml_conf.service1