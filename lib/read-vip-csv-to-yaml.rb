require 'yaml'
require 'csv'
require 'pp'

csv_data = CSV.read("../private-fixtures/lon3.csv")
headers = csv_data.shift.map {|i| i.to_s }
Kernel.abort "Warning!  Header count is not expected.  Expected 6, got #{headers.length}" unless headers.length == 6

# just overwrite the header names to what i like
headers = [ "priority", "vlan_name", "fqdn", "jetty_port", "vip_port", "pool_mem_ip"]
pp "#{headers}\n"

string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
csv_array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten]}

pp "#{csv_array_of_hashes[0]}\n"

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
end
pp "#{csv_array_of_hashes[50]["fqdn"]}"

# the csv is pool member focused so vip names are repeated
# we need a list of unique fqdns
fqdns_array =[]
csv_array_of_hashes.each do |member|
  fqdns_array.push(member["fqdn"])
end
#uniq the array
fqdns_array.uniq!
#pp "list of fqdns #{fqdns_array}"
pool_hash1 ={}

fqdns_array.each do |cur_fqdn|
service_num = 1
member_list = []
pool_hash = {}
  main_hash = { "fqdn"=> "#{cur_fqdn}", "vip_type" =>'web'}

  monitor_hash = { "name" => "", "type" => "http", "send"=> " GET /management/alive", "recv" => "Web Service is Ok"}
  csv_array_of_hashes.each do |member|
    if member["fqdn"].eql?(cur_fqdn)
      #pp "cur member, #{member["fqdn"]} matches cur fqdn, #{cur_fqdn}"
      #pp "member #{member["pool_mem_ip"]}, priority=  #{member["priority"]}"
      member_list.push({"memberdef"=> "#{member["pool_mem_ip"]}", "priority"=> "#{member["priority"]}"})
      pp "member list #{member_list}"
    end
    pool_hash = { "name" => "", "port"=> "#{member["jetty_port"]}", "lb_method" => "least_connections", "monitor_name" => "", "min_active_members" => 1, "action_on_service_down"=> "SERVICE_DOWN_ACTION_NONE", "pool_members" => member_list}
  end
  vs_hash = { "name"=> "", "address"=>"1.2.3.4", "port" => 80, "protocol"=> "", "netmask" => "", "resource_type"=> "", "default_pool_name"=> "", "profile_context"=>"", "profile_name"=>"http", "snat"=> "", "mirrored_state"=> "", "vlan_name"=>"", "ssl_client_profile"=>""}
  #service_num.next
  
  service_hash = {"service#{service_num}" => { "main"=> main_hash, "monitor"=>monitor_hash, "pool"=> pool_hash, "virtual_server"=> vs_hash }}
  
  # use a regex to verify the fqdn is a valid format
  if cur_fqdn.match(/(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)/)
    puts "cur fqdn #{cur_fqdn}"
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