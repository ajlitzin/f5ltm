require 'yaml'

# fqdn, pool port, vip port 1, vip port 2
inputarray = [ "andy.test.theplatform.com", 14042, 80, 443 ]

CSV.foreach("../private-fixtures/lon3.csv") do |row|


  main_hash1 = { "fqdn"=> "andy.test.corp.theplatform.com", "vip_type" =>'web'}

  main_hash2 = { "fqdn"=> "andy.test.corp.theplatform.com2", "vip_type" =>'web'}

  monitor_hash1 = { "name" => "", "type" => "http", "send"=> " GET /management/alive", "recv" => "Web Service is Ok"}

  pool_hash1 = { "name" => "", "port"=> 4567, "lb_method" => "least_connections", "monitor_name" => "", "min_active_members" => 0, "action_on_service_down"=> "SERVICE_DOWN_ACTION_NONE", "pool_members" => [{ "memberdef" => "192.168.244.250:8080", "priority"=> 2}, { "memberdef" => "192.168.244.251:8080", "priority"=>2 }]}

  vs_hash1 = { "name"=> "", "address"=>"1.2.3.4", "port" => 80, "protocol"=> "", "netmask" => "", "resource_type"=> "", "default_pool_name"=> "", "profile_context"=>"", "profile_name"=>"http", "snat"=> "", "mirrored_state"=> "", "vlan_name"=>"", "ssl_client_profile"=>""}

  service1hash = {"service1" => { "main"=> main_hash1, "monitor"=>monitor_hash1, "pool"=> pool_hash1, "virtual_server"=> vs_hash1 }}
  service2hash = {"service2" => { "main"=> main_hash1, "monitor"=>monitor_hash1, "pool"=> pool_hash1, "virtual_server"=> vs_hash1 }}
  top_array = [service1hash,service2hash]

  top_array.each do |cur_hash|
    puts cur_hash.to_yaml
  end

  File.open("../private-fixtures/andy-csv-out2.yml", 'w') do |file|
    top_array.each do |cur_hash|
      file.write(cur_hash.to_yaml)
    end
  end
end # csv loop