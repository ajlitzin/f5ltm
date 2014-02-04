require 'yaml'
require 'csv'
require 'pp'

#global vars
$debug = false

#we're using a csv that doesn't have pool members- that will be handled with a different script
csv_data = CSV.read("../private-fixtures/phl3-minus-built-vips.csv")
headers = csv_data.shift.map {|i| i.to_s }
# we expect 4 columns: fqdn, jetty port, vip port, alive_url
Kernel.abort "Warning!  Header count is not expected.  Expected 4, got #{headers.length}" unless headers.length == 4

# just overwrite the header names to what i like
headers = [ "fqdn", "jetty_port", "vip_port", "alive_url"]
#pp "#{headers}\n"

string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
csv_array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten]}
new_csv_array_of_hashes =[]

pp "read in csv of hashes \n"
# csv_array_of_hashes.each do | cur_mem |
 # pp "#{cur_mem}\n"
# end
# pp "#{csv_array_of_hashes}\n"
# pp "#{csv_array_of_hashes[0]}\n"

# normalize all the vip fqdns to lowercase and prepend with phl3
csv_array_of_hashes.each do |member|
  member["fqdn"].downcase!
  member["fqdn"].insert(0,"phl3.")
  #for vips with multiple listeningports, split them into unique rows
  jetty_ports = member["vip_port"].split(";")
  #pp jetty_ports
  jetty_ports.each do | cur_port |
    #pp "cur_port is #{cur_port}"
    new_hash ={}
    member.each_pair do |k, v|
      new_hash[k] = v
    end
    new_hash["vip_port"] = cur_port
    new_csv_array_of_hashes.push(new_hash)
    # new_csv_array_of_hashes.each do | andy |  
     # pp "#{andy}\n"
    # end  
  end
end
# pp "new csv of hashes \n"
# pp "#{new_csv_array_of_hashes}\n"
# new_csv_array_of_hashes.each do | cur_mem |
 # pp "#{cur_mem}\n"
# end
 
# read in a csv that is fqdn,vip_ip
fqdns_vips_csv = CSV.read("../private-fixtures/phl3/phl3-fqdns-ips.csv")
# change it to a hash with the fqdn as the key
fqdns_vips_hash = Hash[fqdns_vips_csv]
 
File.open("../private-fixtures/phl3/vip_summary.txt", 'w') do |hosts_file|
  new_csv_array_of_hashes.each do | cur_mem |
    pool_hash = {}
    vs_hash = {}
    main_hash = {}
    monitor_hash = {}
    service_hash = {}
    cur_fqdn = cur_mem["fqdn"]
    # hardcode a blank member definition- we're adding pool member in another script later
    pool_mem_array_of_hashes = ["memberdef"=> "", "priority"=> ""]
    
  # write to the hosts file
    hosts_file.write("#{cur_mem["vip_ip"]} #{cur_fqdn}\n")  
    
    main_hash = { "fqdn"=> cur_mem["fqdn"], "vip_type" =>'web'}
    
    monitor_hash = { "name" => "", "type" => "http", "send"=> "GET #{cur_mem["alive_url"]}", "recv" => "Web Service is Ok"}

    pool_hash = { "name" => "", "port"=> "#{cur_mem["jetty_port"]}", "lb_method" => "round_robin", "monitor_name" => "", "min_active_members" => 1, "action_on_service_down"=> "SERVICE_DOWN_ACTION_NONE", "pool_members" => pool_mem_array_of_hashes}
    # #pp "#{pool_hash}\n"
    # #puts
    
    if cur_mem["vip_port"].to_s.eql?("443")
      ssl_client_profile_name = "#{cur_mem["fqdn"].sub(/^phl3\./,'')}_ssl"
    else
      ssl_client_profile_name = ""
    end
    
     vs_hash = { "name"=> "", "address"=>fqdns_vips_hash["#{cur_mem["fqdn"].sub(/^phl3\./,"")}"], "port" => cur_mem["vip_port"], "protocol"=> "", "netmask" => "", "resource_type"=> "", "default_pool_name"=> "", "profile_context"=>"", "profile_name"=>"http", "snat"=> "ltm_int_transit_snat_pool", "mirrored_state"=> "", "vlan_name"=>"", "ssl_client_profile"=>"#{ssl_client_profile_name}"}  

     service_hash = {"service1" => { "main"=> main_hash, "monitor"=>monitor_hash, "pool"=> pool_hash, "virtual_server"=> vs_hash }}

    # use a regex to verify the fqdn is a valid format
    if cur_fqdn.match(/(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)/)
      puts "\n"
      puts "about to write file #{cur_fqdn}_#{vs_hash["port"]}\n"
      File.open("../private-fixtures/phl3/#{cur_fqdn}_#{vs_hash["port"]}.yml", 'w') do |file|
        file.write(service_hash.to_yaml)
      end
    else
      puts "Warning -skipping file for \"#{cur_fqdn}\" - non alpha chars in fqdn"  
    end  
  end # new csv array loop
end # vip summary file write
