# this is our main file
#things to do

# make call to parse yaml file (vs_builder code)
# create monitor (f5_monitor_create_template)
# update monitor
## add http send/receive (f5_monitor_set_template_string_property)
# create pool (f5_pool_create)
# update pool members
## PGA (f5_poolmember_set_priority.rb)
# update pool
## enable PGA (f5_pool_set_min_active_members)
## bind monitor (pool_set_monitor_association)
# create SSL profile?
# create vs (f5_vs_create)
# update vs
## snat (f5_vs_set_snat_pool)
## ssl_profile?
## vlans
## connection mirroring (only for DB LB)
## bind irule (lowest priority)

## other ideas-
### decouple command line from methods.  could allow easier direct use of methods.
### most obvious in setting pool member priority

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
#pp vs_yaml_conf.pool["name"]
pp vs_yaml_conf

if service_list.empty?
  # create vs/pool/monitor/etc for the single service defined
  # how to DRY this up?
  puts "service list is empty"
  ### creating pool
  #debugger
  member_list = create_member_list(vs_yaml_conf.pool["pool_members"])
  #output = %x{ruby f5_pool_create.rb --name #{vs_yaml_conf.pool["name"]} #{member_list} --bigip 192.168.106.13}
  
  ### update pool member priority
  vs_yaml_conf.pool["pool_members"].each do |pool_mem|
    output = %x{ruby f5_poolmember_set_priority.rb --bigip 192.168.106.13 --name #{vs_yaml_conf.pool["name"]} --member #{pool_mem["memberdef"]} --member_priority #{pool_mem["priority"]} }
  end
  
  ### turn on PGA
  output = %x{ruby f5_pool_set_min_active_members.rb --bigip 192.168.106.13 --pool_name #{vs_yaml_conf.pool["name"]} --min_active_members #{vs_yaml_conf.pool["min_active_members"]} }
  
  ## creating monitor template
  
  #monoutput = %x{ruby f5_monitor_create_template.rb --bigip 192.168.106.13  --name #{vs_yaml_conf.monitor["name"]} --parent_template #{vs_yaml_conf.monitor["type"]} --interval #{vs_yaml_conf.monitor["interval"]} --timeout #{vs_yaml_conf.monitor["timeout"]}}
  
  ## set monitor send/receive strings
  ## assumes http/https monitor type
  
  send_string_suffix = vs_yaml_conf.monitor["send"].to_s.concat(' HTTP/1.1\\r\\nHost: bigipalive.theplatform.com\\r\\n\\r\\n')
  
  #monoutput = %x{ruby f5_monitor_set_template_string_property.rb --bigip 192.168.106.13 --monitor_name #{vs_yaml_conf.monitor["name"]} --string_property_type "STYPE_SEND" --string_value "#{send_string_suffix}"}
 
  #monoutput = %x{ruby f5_monitor_set_template_string_property.rb --bigip 192.168.106.13 --monitor_name #{vs_yaml_conf.monitor["name"]} --string_property_type "STYPE_RECEIVE" --string_value "#{vs_yaml_conf.monitor["recv"]}"}

  ### associate monitor template with pool
  #monassoc_output = %x{ruby f5_pool_set_monitor_association.rb --bigip 192.168.106.13 --pool_name #{vs_yaml_conf.pool["name"]} --monitor_name #{vs_yaml_conf.monitor["name"]} }
  
  ### create the virtual server
  #output = %x{ruby f5_vs_create.rb --bigip 192.168.106.13 --address #{vs_yaml_conf.virtual_server["address"].to_s}  --mask #{vs_yaml_conf.virtual_server["netmask"]} --name #{vs_yaml_conf.virtual_server["name"]} --port #{vs_yaml_conf.virtual_server["port"]} --protocol #{vs_yaml_conf.virtual_server["protocol"]} --resource_type #{vs_yaml_conf.virtual_server["resource_type"]} --pool_name #{vs_yaml_conf.virtual_server["default_pool_name"]} --profile_context #{vs_yaml_conf.virtual_server["profile_context"]}}
  
  ###### update VS settings ######
  ### add snat if necessary
  unless vs_yaml_conf.virtual_server["snat"].nil?
    output = %x{ruby f5_vs_set_snat_pool.rb --bigip 192.168.106.13 --vs_name #{vs_yaml_conf.virtual_server["name"]} --snat_pool_name #{vs_yaml_conf.virtual_server["snat"]} }
  end
else
  puts "service list is NOT empty, #{service_list}"
  service_list.each do
    # loop through each service and create vs/pool/monitor/etc
  end
end

#pp vs_yaml_conf.service1