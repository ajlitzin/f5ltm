require 'yaml'
require 'csv'
require 'pp'
require 'ipaddress'

csv_data = CSV.read("../private-fixtures/lon3.csv")
headers = csv_data.shift.map {|i| i.to_s }
# we expect 6 columns: priority, vlan, fqdn, jetty port, vip port, member ip
Kernel.abort "Warning!  Header count is not expected.  Expected 7, got #{headers.length}" unless headers.length == 7

# just overwrite the header names to what i like
headers = [ "priority", "vlan_name", "fqdn", "jetty_port", "vip_port", "pool_mem_ip", "alive_url"]
#pp "#{headers}\n"

string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
csv_array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten]}
new_csv_array_of_hashes =[]

#pp "read in csv of hashes \n"
#csv_array_of_hashes.each do | cur_mem |
#  pp "#{cur_mem}\n"
#end
#pp "#{csv_array_of_hashes}\n"
#pp "#{csv_array_of_hashes[0]}\n"

# normalize all the vip fqdns to lowercase and prepend with lon3
# convert host code into a priority (pga) value
csv_array_of_hashes.each do |member|
  member["fqdn"].downcase!
  member["fqdn"].insert(0,"lon3.")
  case member["priority"]
    when "9"
      member["priority"] = 1
    when "5"
      member["priority"] = 2
    else
      member["priority"] = 3
  end
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
    #new_csv_array_of_hashes.each do | andy |  
    #  pp "#{andy}\n"
    #end  
  end
end
#pp "new csv of hashes \n"
#new_csv_array_of_hashes.each do | cur_mem |
#  pp "#{cur_mem}\n"
#end


csv_array_of_hashes = new_csv_array_of_hashes
#pp "row 2 of csv of hashes \n"
#pp "#{csv_array_of_hashes[2]["fqdn"]}"


new_csv_array_of_hashes = []
csv_array_of_hashes.each do |outer_member| 
  temp_hash = {}
  member_list = []
  cur_fqdn = outer_member["fqdn"]
  cur_port = outer_member["vip_port"]
  #pp "current fqdn #{cur_fqdn}"
  #pp "current port #{cur_port}"
  #puts
  # inner loop to create the array of pool members
  csv_array_of_hashes.each do |member|
    if (member["fqdn"].eql?(cur_fqdn)) and (member["vip_port"].eql?(cur_port))
      #pp "cur member, #{member["fqdn"]} matches cur fqdn, #{cur_fqdn}"
      #pp "member #{member["pool_mem_ip"]}, priority=  #{member["priority"]}"
      member_list.push({"memberdef"=> "#{member["pool_mem_ip"]}", "priority"=> "#{member["priority"]}"})
      #pp "member list #{member_list}"
    end
  end # inner csv array loop
  #pp "member list #{member_list}"
  
  outer_member.each_pair do |k, v|
    temp_hash[k] = v
  end
  temp_hash.delete("pool_mem_ip")
  temp_hash.delete("priority")
  #pp "temp hash is #{temp_hash}"
  #puts
  temp_hash.merge!("pool_mem_ips"=>member_list)
  #pp "temp hash after adding pool_mem_ips #{temp_hash}"
  #puts
  new_csv_array_of_hashes.push(temp_hash)
  #pp "the in progress array"
  #puts
  #new_csv_array_of_hashes.each do |cmem|
  #  pp cmem
  #end
  #puts "end of in-progress array"
  #puts
  
  new_csv_array_of_hashes.uniq!
  #pp "the deduped in progress array"
  #puts
  #new_csv_array_of_hashes.each do |cmem|
  #  pp cmem
  #end
  #puts "end of deduped in-progress array"
  #puts
  
  
end # outer csv array loop

vip_range_obj = IPAddress "185.28.92.0/24"
# create an array of the ips (only because we need to get rid of
# ones already used
vip_ips=[]
vip_range_obj.each_host do |host|
  vip_ips.push(host.address)
end
# we already assinged 185.28.92.1-.4, so get rid of them
vip_ips.slice!(0..4)
# now get it to the size we need, one ip for each vip
#vip_ips.slice!(new_csv_array_of_hashes.length..-1)

fqdns_array=[]
new_csv_array_of_hashes.each do |cur_mem|
  fqdns_array.push(cur_mem["fqdn"])
end
fqdns_array.uniq!
iterator=0

fqdns_array.each do |cur_fqdn|
  new_csv_array_of_hashes.each do |cur_mem|
    if cur_mem["fqdn"].eql?(cur_fqdn)
      cur_mem.merge!("vip_ip"=>vip_ips[iterator])
    end
  end
  iterator+=1
end
 
 
File.open("../private-fixtures/lon3/vip_summary.txt", 'w') do |hosts_file|
  new_csv_array_of_hashes.each do | cur_mem |
    
    pool_hash = {}
    vs_hash = {}
    main_hash = {}
    monitor_hash = {}
    service_hash = {}
    cur_fqdn = cur_mem["fqdn"]
    
  # write to the hosts file
    hosts_file.write("#{cur_mem["vip_ip"]} #{cur_fqdn}\n")  
    
    
    
    main_hash = { "fqdn"=> cur_mem["fqdn"], "vip_type" =>'web'}
    
    monitor_hash = { "name" => "", "type" => "http", "send"=> "GET #{cur_mem["alive_url"]}", "recv" => "Web Service is Ok"}

    pool_hash = { "name" => "", "port"=> "#{cur_mem["jetty_port"]}", "lb_method" => "round_robin", "monitor_name" => "", "min_active_members" => 1, "action_on_service_down"=> "SERVICE_DOWN_ACTION_NONE", "pool_members" => cur_mem["pool_mem_ips"]}
    #pp "#{pool_hash}\n"
    #puts
    
    if cur_mem["vip_port"].to_s.eql?("443")
      ssl_client_profile_name = "#{cur_mem["fqdn"].sub(/^lon3\./,'')}_ssl"
    else
      ssl_client_profile_name = ""
    end
    
    vs_hash = { "name"=> "", "address"=>cur_mem["vip_ip"], "port" => cur_mem["vip_port"], "protocol"=> "", "netmask" => "", "resource_type"=> "", "default_pool_name"=> "", "profile_context"=>"", "profile_name"=>"http", "snat"=> "webs_ltm_int_transit_snat_pool", "mirrored_state"=> "", "vlan_name"=>"", "ssl_client_profile"=>"#{ssl_client_profile_name}"}  
   
    service_hash = {"service1" => { "main"=> main_hash, "monitor"=>monitor_hash, "pool"=> pool_hash, "virtual_server"=> vs_hash }}

    # use a regex to verify the fqdn is a valid format
    if cur_fqdn.match(/(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)/)
      puts "\n"
      puts "about to write file #{cur_fqdn}_#{vs_hash["port"]}\n"
      File.open("../private-fixtures/lon3/#{cur_fqdn}_#{vs_hash["port"]}.yml", 'w') do |file|
      #  top_array.each do |cur_hash|
      #    file.write(cur_hash.to_yaml)
      #  end
            file.write(service_hash.to_yaml)
      end
    else
      puts "Warning -skipping file for \"#{cur_fqdn}\" - non alpha chars in fqdn"  
    end  
  end # new csv array loop
end # vip summary file write