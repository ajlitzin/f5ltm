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
require 'csv'
require 'pp'

#global vars
$debug = false

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_phl3_gtm_builder.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf BigIP Connection Config File", "BigIP Connection Config File") do |bipcfile|
        options.bigip_conn_conf = bipcfile || "../private-fixtures/bigipconconf.yml"
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
REQ_PARAMS = [ :bigip, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

csv_data = CSV.read("../private-fixtures/phl3.csv")
headers = csv_data.shift.map {|i| i.to_s }
# we expect 4 columns: fqdn, jetty port, vip port, alive_url
Kernel.abort "Warning!  Header count is not expected.  Expected 4, got #{headers.length}" unless headers.length == 4

# just overwrite the header names to what i like
headers = [ "fqdn", "jetty_port", "vip_port", "alive_url"]
#pp "#{headers}\n"

string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
csv_array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten]}
new_csv_array_of_hashes =[]

pp "read in csv of hashes"
# csv_array_of_hashes.each do | cur_mem |
 # pp "#{cur_mem}\n"
# end
# pp "#{csv_array_of_hashes}\n"
# pp "#{csv_array_of_hashes[0]}\n"

# normalize all the vip fqdns to lowercase and get down to single vip port per vip
csv_array_of_hashes.each do |member|
  member["fqdn"].downcase!
  #for vips with multiple listeningports, split them into unique rows, but only keep the first port.  for gtm virtual servers we only create one vs object even if the actual ltm vip has multiple listening ports
  vip_ports = member["vip_port"].split(";")
  # assuming that the first port will always be port 80 when there are 2 or more ports
   new_hash ={}
   member.each_pair do |k, v|
     new_hash[k] = v
   end
   new_hash["vip_port"] = vip_ports.first
   new_csv_array_of_hashes.push(new_hash)
end
# pp "new csv of hashes \n"
# pp "#{new_csv_array_of_hashes}\n"
# new_csv_array_of_hashes.each do | cur_mem |
 # pp "#{cur_mem}\n"
# end
 
# read in a csv that is fqdn,vip_ip
phl3_fqdns_vips_csv = CSV.read("../private-fixtures/phl3/phl3-fqdns-ips.csv")
# change it to a hash with the fqdn as the key, i.e {"bob.theplatform.com"=>5.5.5.5}
phl3_fqdns_vips_hash = Hash[phl3_fqdns_vips_csv]
lon3_fqdns_vips_csv = CSV.read("../private-fixtures/lon3/lon3-fqdns-ips.csv")
lon3_fqdns_vips_hash = Hash[lon3_fqdns_vips_csv]

# create virtual servers for lon3bigip01 and phl3bigip01
#gtm_server_objects = ["lon3bigip01","phl3bigip01"]
environs = [{:server=>"lon3bigip01",:dc=>"lon3"},{:server => "phl1tpbigip03",:dc=>"phl3"}]
phl3_parent = "phl1tpbigip03"
lon3_parent = "lon3bigip01"

new_csv_array_of_hashes.each do |cur_mem|
  environs.each do | cur_dc |
  
    ### creating gtm virtual server object
    pp "creating vs object #{cur_mem["fqdn"]}_#{cur_mem["vip_port"]} for ltm object #{cur_dc[:server]}..."
    if cur_dc[:dc] == "lon3"
      cur_addr = lon3_fqdns_vips_hash[cur_mem["fqdn"]]
      lon3_order = 0
      phl3_order = 1
    elsif cur_dc[:dc] == "phl3"
      cur_addr = phl3_fqdns_vips_hash[cur_mem["fqdn"]]
      lon3_order = 1
      phl3_order = 0
    end
    output = %x{ruby -W0 f5_gtm_vs_create.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --name "#{cur_dc[:dc]}.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}" --parent #{cur_dc[:server]} --address #{cur_addr} --port #{cur_mem["vip_port"]}}

      pool_name = "dr.#{cur_dc[:dc]}.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}"

    #create the pools - the environs loop will create the phl1 and phl3 pools, but we'll need to create the enduser pool outside this loop
    pp "creating gtm pool #{pool_name}..."
    output = %x{ruby -W0 f5_gtm_pool_create.rb  --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{pool_name}}
    
    # set the alternate and fallback lb methods of the pool
    # scripts currently hardcode/default to Global Availability for both
    pp "setting alt and fallback lb methods to pool #{pool_name}"
    output = %x{ruby -W0 f5_gtm_set_alternate_lb_method.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{pool_name}}
    output = %x{ruby -W0 f5_gtm_set_fallback_lb_method.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{pool_name}}
    
  end  # gtm_server_objects loop
      
  # create enduser pool
  pool_name = "dr.enduser.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}"
  pp "creating gtm pool #{pool_name}..."
  output = %x{ruby -W0 f5_gtm_pool_create.rb  --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name "#{pool_name}}
  
  # set the alternate and fallback lb methods of the pool
  pp "setting alt and fallback lb methods to pool #{pool_name}"
  output = %x{ruby -W0 f5_gtm_set_alternate_lb_method.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{pool_name}}
  output = %x{ruby -W0 f5_gtm_set_fallback_lb_method.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{pool_name}}
  
  # add both vs as pool members to enduser pool
  # add lon3 vs.  lon3 gets order 0 because it's the primary R/W DC 
  pp "adding lon3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]} vs to pool #{pool_name}"
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{pool_name} --address #{lon3_fqdns_vips_hash[cur_mem["fqdn"]]} --port #{cur_mem["vip_port"]} --order 0 }
  # now repeat and add phl3 pool to same pool
  pp "adding phl3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]} vs to pool #{pool_name}"
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{pool_name} --address #{phl3_fqdns_vips_hash[cur_mem["fqdn"]]} --port #{cur_mem["vip_port"]} --order 1 }  
  
  # create the irules
  
  lon3_pool_name = "dr.lon3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}"
  phl3_pool_name = "dr.phl3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}"
  
 irule_def = <<END_OF_IRULE
when DNS_REQUEST {
# log local0. "Client request IP: [IP::remote_addr]"
# outbound SNAT IP for standard PHL1/PHL3 LDNS
  if { [IP::addr [IP::remote_addr]/32 equals 207.223.2.40/32] } {
    pool #{phl3_pool_name}
# LON3 IP range (includes NAT for standard LON3 LDNS)
  } elseif { [IP::addr [IP::remote_addr]/23 equals 185.28.93.0/24] } {
    pool #{lon3_pool_name}
# Internet client LDNS - generally go to LON3 first (pool can fail to PHL3)
  } else {
    pool #{pool_name}
  }
}
END_OF_IRULE

  pp "creating iRule #{cur_mem["fqdn"]}_rule..."
  #pp " irule def: '#{irule_def}'"
  output = %x{ruby -W0 f5_gtm_rule_create.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --rule_name #{cur_mem["fqdn"]}_rule --rule_def '#{irule_def}' }

  # create wideip and bind the iRule
  pp "creating wideip #{cur_mem["fqdn"]}..."
  output = %x{ruby -W0 f5_gtm_wideip_create.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --name #{cur_mem["fqdn"]} --rule_name #{cur_mem["fqdn"]}_rule }
  
  # enable ipv6 NoError Response
  pp "enabling ipv6 NoError Response"
  output = %x{ruby -W0 f5_gtm_set_ipv6_no_error_response_state.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --wip_name #{cur_mem["fqdn"]} -s enabled}
  
end # new_csv_array_of_hashes loop

#now virtual servers, pools, iRules, and wideips are created
# but pools are empty
# used a 2nd loop because i couldn't add pool member to each
# pool until all pools and virtual servers (members) were created
new_csv_array_of_hashes.each do |cur_mem|
  lon3_pool_name = "dr.lon3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}"
  phl3_pool_name = "dr.phl3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}"
# add both vs as pool members to each pool
  # add to lon3 vs to lon3 pool
  pp "adding lon3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]} pool member to pool #{lon3_pool_name}"
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{lon3_pool_name} --address #{lon3_fqdns_vips_hash[cur_mem["fqdn"]]} --port #{cur_mem["vip_port"]} --order 0 }
  # now repeat and add phl3 pool to same pool
  pp "adding phl3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]} pool member to pool #{lon3_pool_name}"
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{lon3_pool_name} --address #{phl3_fqdns_vips_hash[cur_mem["fqdn"]]} --port #{cur_mem["vip_port"]} --order 1 }
  # add lon3 vs to phl3 pool
  pp "adding lon3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]} pool member to pool #{phl3_pool_name}"
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{phl3_pool_name} --address #{lon3_fqdns_vips_hash[cur_mem["fqdn"]]} --port #{cur_mem["vip_port"]} --order 1 }
  # now repeat and add phl3 pool to same pool
  pp "adding phl3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]} pool member to pool #{phl3_pool_name}"
  output = %x{ruby -W0 f5_gtm_pool_add_member.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --pool_name #{phl3_pool_name} --address #{phl3_fqdns_vips_hash[cur_mem["fqdn"]]} --port #{cur_mem["vip_port"]} --order 0 }
    
  # #disable the non-local member
  # lon3 pool, disable phl3 member
  pp "disable dr.lon3 phl3 pool member..."
  output = %x{ruby -W0 f5_gtm_set_pool_member_enabled_state.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --vs_name "phl3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}" --parent_name #{phl3_parent} -s disabled --pool_name dr.lon3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]} }
  # phl3 pool, disable lon3 member
  pp "disable dr.phl3 lon3 pool member..."
  output = %x{ruby -W0 f5_gtm_set_pool_member_enabled_state.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --vs_name "lon3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}" --parent_name #{lon3_parent} -s disabled --pool_name dr.phl3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]} }

  # disable phl3 member in enduser pool - only lon active by default
  pp "disable dr.endusers phl3 pool member..."
  output = %x{ruby -W0 f5_gtm_set_pool_member_enabled_state.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --vs_name "phl3.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}" --parent_name #{phl3_parent} -s disabled --pool_name "dr.enduser.#{cur_mem["fqdn"]}_#{cur_mem["vip_port"]}" }
end #cur_array_of_hashes loop #2

# ruby -W0 f5_phl3_gtm_builder.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" -b 192.168.106.x
