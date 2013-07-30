require 'yaml'
require 'csv'
require 'pp'

csv_data = CSV.read("../private-fixtures/lon3.csv")
headers = csv_data.shift.map {|i| i.to_s }
# we expect 6 columns: priority, vlan, fqdn, jetty port, vip port, member ip
Kernel.abort "Warning!  Header count is not expected.  Expected 6, got #{headers.length}" unless headers.length == 6

# just overwrite the header names to what i like
headers = [ "priority", "vlan_name", "fqdn", "jetty_port", "vip_port", "pool_mem_ip"]
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
# the csv is pool member focused so vip names are repeated
# we need a list of unique fqdns
fqdns_array =[]
csv_array_of_hashes.each do |member|
  fqdns_array.push([member["fqdn"],member["vip_port"]])
end
#uniq the array
fqdns_array.uniq!
#pp "list of fqdns #{fqdns_array}"
pool_hash = {}
vs_hash = {}
fqdns_array.each do |cur_fqdn, cur_port|
pp "cur fqdn and vip port are #{cur_fqdn}, #{cur_port}\n"
member_list = []

  main_hash = { "fqdn"=> "#{cur_fqdn}", "vip_type" =>'web'}

  monitor_hash = { "name" => "", "type" => "http", "send"=> " GET /management/alive", "recv" => "Web Service is Ok"}
  csv_array_of_hashes.each do |member|
    if member["fqdn"].eql?(cur_fqdn) and member["vip_port"].eql?(cur_port)
      #pp "cur member, #{member["fqdn"]} matches cur fqdn, #{cur_fqdn}"
      #pp "member #{member["pool_mem_ip"]}, priority=  #{member["priority"]}"
      member_list.push({"memberdef"=> "#{member["pool_mem_ip"]}", "priority"=> "#{member["priority"]}"})
      #pp "member list #{member_list}"
    end
    #pp "member list #{member_list}"
    pool_hash = { "name" => "", "port"=> "#{member["jetty_port"]}", "lb_method" => "round_robin", "monitor_name" => "", "min_active_members" => 1, "action_on_service_down"=> "SERVICE_DOWN_ACTION_NONE", "pool_members" => member_list}
    #p pool_hash

    vs_hash = { "name"=> "", "address"=>"1.2.3.4", "port" => member["vip_port"], "protocol"=> "", "netmask" => "", "resource_type"=> "", "default_pool_name"=> "", "profile_context"=>"", "profile_name"=>"http", "snat"=> "", "mirrored_state"=> "", "vlan_name"=>"", "ssl_client_profile"=>""}  
    
  end # csv array loop  
  service_hash = {"service1" => { "main"=> main_hash, "monitor"=>monitor_hash, "pool"=> pool_hash, "virtual_server"=> vs_hash }}
  # use a regex to verify the fqdn is a valid format
  if cur_fqdn.match(/(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)/)
    puts "\n"
    puts "cur fqdn #{cur_fqdn}\n"
    File.open("../private-fixtures/lon3/#{cur_fqdn}_#{vs_hash["port"]}.yml", 'w') do |file|
    #  top_array.each do |cur_hash|
    #    file.write(cur_hash.to_yaml)
    #  end
          file.write(service_hash.to_yaml)
    end
  else
    puts "Warning -skipping file for \"#{cur_fqdn}\" - non alpha chars in fqdn"  
  end  
  
end # fqdns array loop