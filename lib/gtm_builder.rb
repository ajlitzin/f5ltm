#  want to create gtm objects if they don't exist, if any object exists, skip it and warn
#  allow user to decide whether or not to create wideip
# create virtual servers
# create pools (no members)
# set alt lb method
# set fallback lb method
# create rule
# create wideip
# set ipv6 no error response
# add pool members
# set member enabled state (disable opposite member (member with order > 0)

require 'yaml'
require 'optparse'
require 'ostruct'
require 'pp'

#global vars
$debug = false

#dotcom_gtms_list = ["192.168.106.2"]
#doteu_gtms_list = ["192.168.106.2"]
dotcom_gtms_list = ["10.1.96.15", "10.20.96.15"]
doteu_gtms_list = ["10.20.96.16", "10.30.96.15"]
PRIMARY_DOTEU_PARENT = "lon3bigip01"
SECONDARY_DOTEU_PARENT = "phl1tpbigip03"
PRIMARY_DOTCOM_PARENT = "SEA1TPBIGIP03"
SECONDARY_DOTCOM_PARENT = "PHL1TPBIGIP03"

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_phl3_gtm_builder.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on( "-b", "--bigip IP", "BigIP GTM IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf BigIP Connection Config File", "BigIP Connection Config File") do |bipcfile|
        options.bigip_conn_conf = bipcfile || "../private-fixtures/bigipconconf.yml"
      end
      opts.on( "--fqdn FQDN", "The Fully Qualified Domain Name") do |fqdn|
        options.fqdn = fqdn
      end
      opts.on( "--vs_port VS_PORT", "The listening port of the virtual server") do |port|
        options.vs_port = port 
      end
      opts.on( "--pri_vs_ip PRIMARY_VS_IP", "The IP address of the virtual server in the primary datacenter") do |pri_ip|
        options.pri_vs_ip = pri_ip
      end
      opts.on( "--sec_vs_ip SECONDARY_VS_IP", "The IP address of the virtual server in the secondary datacenter") do |sec_ip|
        options.sec_vs_ip = sec_ip
      end
      opts.on("--failover_type [TYPE]", [:dr,:geo], "Select failover type (dr, geo)") do |t|
        options.failover_type = t
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

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [ :bigip, :bigip_conn_conf, :fqdn, :pri_vs_ip, :sec_vs_ip, :failover_type]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

# normalize all the vip fqdns to lowercase and get down to single vip port per vip
options.fqdn.downcase!

if options.fqdn.end_with?("theplatform.eu")
  unless doteu_gtms_list.include?(options.bigip)
    Kernel.abort "Unexpected GTM IP #{options.bigip} for theplatform.eu"
  end
elsif options.fqdn.end_with?("theplatform.com")
  unless dotcom_gtms_list.include?(options.bigip)
    Kernel.abort "Unexpected GTM IP #{options.bigip} for theplatform.com"
  end
end

if options.fqdn.end_with?("theplatform.eu")
  pri_vs_parent = PRIMARY_DOTEU_PARENT 
  sec_vs_parent = SECONDARY_DOTEU_PARENT 
  pri_dc = "lon3"
  sec_dc = "phl3"
  pool_prefix_list = ["lon3","phl3","enduser"]
elsif options.fqdn.end_with?("theplatform.com")
  pri_vs_parent = PRIMARY_DOTCOM_PARENT 
  sec_vs_parent = SECONDARY_DOTCOM_PARENT 
  pri_dc = "sea1"
  sec_dc = "phl1"
  pool_prefix_list = ["sea1","phl1","enduser"]
end

### creating gtm virtual server object for primary LTM
pp "creating #{pri_dc} vs object #{pri_dc}.#{options.fqdn}_#{options.vs_port} for ltm object #{pri_vs_parent}..."

output = %x{ruby -W0 f5_gtm_vs_create.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --name "#{pri_dc}.#{options.fqdn}_#{options.vs_port}" --parent #{pri_vs_parent} --address #{options.pri_vs_ip} --port #{options.vs_port}}

pp "creating #{sec_dc} vs object #{sec_dc}.#{options.fqdn}_#{options.vs_port} for ltm object #{sec_vs_parent}..."

output = %x{ruby -W0 f5_gtm_vs_create.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --name "#{sec_dc}.#{options.fqdn}_#{options.vs_port}" --parent #{sec_vs_parent} --address #{options.sec_vs_ip} --port #{options.vs_port}}

if options.failover_type.to_s == "dr"
  pri_pool_name = "dr.#{pri_dc}.#{options.fqdn}_#{options.vs_port}"
  sec_pool_name = "dr.#{sec_dc}.#{options.fqdn}_#{options.vs_port}"
  enduser_pool_name = "dr.enduser.#{options.fqdn}_#{options.vs_port}"
  pool_name_list = [pri_pool_name,sec_pool_name,enduser_pool_name]
elsif options.failover_type.to_s == "geo"
#  pri_pool_name = "dr.#{pri_dc}.#{options.fqdn}_#{options.vs_port}"
#  sec_pool_name = "dr.#{sec_dc}.#{options.fqdn}_#{options.vs_port}"
  pri_pool_name = nil
  sec_pool_name = nil
  enduser_pool_name = "geo.enduser.#{options.fqdn}_#{options.vs_port}"
#  pool_name_list = [pri_pool_name,sec_pool_name,enduser_pool_name]
  pool_name_list = [enduser_pool_name]
end

### create the pools
pool_name_list.each do |cur_pool_name|
  pp "creating gtm pool #{cur_pool_name}..."

  if cur_pool_name.start_with?("geo.enduser")
    output = %x{ruby -W0 f5_gtm_pool_create.rb  --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{cur_pool_name} --lb_method topology}
  else 
    output = %x{ruby -W0 f5_gtm_pool_create.rb  --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{cur_pool_name} --lb_method ga}
  end
  # set alt lb method
  output = %x{ruby -W0 f5_gtm_set_alternate_lb_method.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{cur_pool_name} --lb_method ga}
  # set fallback lb method
  output = %x{ruby -W0 f5_gtm_set_fallback_lb_method.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{cur_pool_name} --lb_method ga}
    
end  # pool name loop
      
# add members to the pri and sec pools, if they exist (they won't exist in the geo balanced case)
unless pri_pool_name.nil?
  pp "adding #{pri_dc}.#{options.fqdn}_#{options.vs_port} vs to pool #{pri_pool_name}"
  # add pri member to pri pool

  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{pri_pool_name} --address #{options.pri_vs_ip} --port #{options.vs_port} --order 0 }

  # add sec member to pri pool

  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{pri_pool_name} --address #{options.sec_vs_ip} --port #{options.vs_port} --order 1 }

  # disable sec member in pri pool
  output = %x{ruby -W0 f5_gtm_set_pool_member_enabled_state.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --vs_name "#{sec_dc}.#{options.fqdn}_#{options.vs_port}" --parent_name #{sec_vs_parent} -s disabled --pool_name #{pri_pool_name} }

  # add sec member to sec pool
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{sec_pool_name} --address #{options.sec_vs_ip} --port #{options.vs_port} --order 0 }

  # add pri member to sec pool
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{sec_pool_name} --address #{options.pri_vs_ip} --port #{options.vs_port} --order 1 }

  # disable pri member in sec pool
  output = %x{ruby -W0 f5_gtm_set_pool_member_enabled_state.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --vs_name "#{pri_dc}.#{options.fqdn}_#{options.vs_port}" --parent_name #{pri_vs_parent} -s disabled --pool_name #{sec_pool_name} }
end

  # add pri member to enduser pool
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{enduser_pool_name} --address #{options.pri_vs_ip} --port #{options.vs_port} --order 0 }
  # add sec member to enduser pool
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{enduser_pool_name} --address #{options.sec_vs_ip} --port #{options.vs_port} --order 1 }
  
# if the enduser pool is DR then disable the sec member in the enduser pool
if enduser_pool_name.start_with?("dr")
  output = %x{ruby -W0 f5_gtm_set_pool_member_enabled_state.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --vs_name "#{sec_dc}.#{options.fqdn}_#{options.vs_port}" --parent_name #{sec_vs_parent} -s disabled --pool_name #{enduser_pool_name} }
end

# create the irules for dr services
# no iRule needed for geo balanced services
if enduser_pool_name.start_with?("dr") 

doteu_irule_def = <<END_OF_DOTEU_IRULE
when DNS_REQUEST {
# log local0. "Client request IP: [IP::remote_addr]"
# outbound SNAT IP for standard PHL1/PHL3 LDNS
  if { [IP::addr [IP::remote_addr]/32 equals 207.223.2.40/32] } {
    pool #{sec_pool_name}
# LON3 IP range (includes NAT for standard LON3 LDNS)
  } elseif { [IP::addr [IP::remote_addr]/23 equals 185.28.93.0/24] } {
    pool #{pri_pool_name}
# Internet client LDNS - generally go to LON3 first (pool can fail to PHL3)
  } else {
    pool #{enduser_pool_name}
  }
}
END_OF_DOTEU_IRULE

dotcom_irule_def = <<END_OF_DOTCOM_IRULE
when DNS_REQUEST {
# log local0. "Client request IP: [IP::remote_addr]"
# outbound SNAT IP for standard PHL1/PHL3 LDNS
  if { [IP::addr [IP::remote_addr]/32 equals 207.223.2.40/32] } {
    pool #{sec_pool_name}
# SEA1 IP range (includes NAT for standard SEA1 LDNS)
  } elseif { [IP::addr [IP::remote_addr]/23 equals 206.79.64.0/23] } {
    pool #{pri_pool_name}
# Internet client LDNS - generally go to SEA1 first (pool can fail to PHL1)
  } else {
    pool #{enduser_pool_name}
  }
}
END_OF_DOTCOM_IRULE


  pp "creating iRule #{options.fqdn}_rule..."
  #pp " irule def: '#{irule_def}'"
  if options.fqdn.end_with?("theplatform.eu")
    output = %x{ruby -W0 f5_gtm_rule_create.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --rule_name #{options.fqdn}_rule --rule_def '#{doteu_irule_def}' }
  elsif options.fqdn.end_with?("theplatform.com")
    output = %x{ruby -W0 f5_gtm_rule_create.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --rule_name #{options.fqdn}_rule --rule_def '#{dotcom_irule_def}' }
  end

  # create wideip and bind the iRule
  pp "creating wideip #{options.fqdn}..."
  output = %x{ruby -W0 f5_gtm_wideip_create.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --name #{options.fqdn} --rule_name #{options.fqdn}_rule }
  
# create the geo based wideip (single pool, no irule)
elsif enduser_pool_name.start_with?("geo.enduser") 
  pp "creating wideip #{options.fqdn}..."
  # may need to adjust code in f5_gtm_wideip_create. to accept pools...
  output = %x{ruby -W0 f5_gtm_wideip_create.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --name #{options.fqdn} --pool_name #{enduser_pool_name} --order 0 --ratio 0 }
end
# enable ipv6 NoError Response
pp "enabling ipv6 NoError Response"
output = %x{ruby -W0 f5_gtm_set_ipv6_no_error_response_state.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --wip_name #{options.fqdn} -s enabled}
  
   
# ruby -W0 gtm_builder.rb --bigip_conn_conf "../private-fixtures/config-andy-qa-gtm-ve.yml" --fqdn "andytest.theplatform.eu"  --vs_port "80" --pri_vs_ip "5.5.5.5" --sec_vs_ip "6.6.6.6" --failover_type "dr" -b 192.168.106.x 
