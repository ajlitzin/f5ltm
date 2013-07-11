require 'yaml'

inputarray = [ "andy.test.theplatform.com", 14042, 80, 443 ]

main_hash = { :main => {:fqdn=> "andy.test.corp.theplatform.com", :vip_type =>'web'}}
monitor_hash = { :monitor => { :name => "", :type => "http", :send=> " GET /management/alive", :recv => "Web Service is Ok"}}

pool_hash = { :pool => { :name => "", :port=> 4567, :lb_method => "least_connections", :monitor_name => "", :min_active_members => 0, :action_on_service_down=> "SERVICE_DOWN_ACTION_NONE", :pool_members => { :memberdef => "", :priority=> 2}}}

vs_hash = { :virtual_server => { :name=> "", :address=>"1.2.3.4", :port => 80, :protocol=> "", :netmask => "", :resource_type=> "", :default_pool_name=> "", :profile_context=>"", :profile_name=>"http", :snat=> "", :mirrored_state=> "", :vlan_name=>"", :ssl_client_profile=>""} }

top_hash = {:service1 => [main_hash, monitor_hash, pool_hash, vs_hash]}

puts top_hash.to_yaml

File.open("../private-fixtures/andy-csv-out.yml", 'w') {|f| f.write(top_hash.to_yaml)}