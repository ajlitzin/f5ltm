require "rubygems"
require 'f5-icontrol', '=11.0.0.1'
require "getoptlong"
#require "rdoc/usage"

options = GetoptLong.new(
  [ "--bigip-address",  "-b", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--bigip-user",     "-u", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--bigip-pass",     "-p", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--vs-name",        "-n", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--help",           "-h", GetoptLong::NO_ARGUMENT ]
)

bigip_address = ''
bigip_user = ''
bigip_pass = ''
vs_name = ''

options.each do |option, arg|
  case option
    when "--bigip-address"
      bigip_address = arg
    when "--bigip-user"
      bigip_user = arg
    when "--bigip-pass"
      bigip_pass = arg
    when "--vs-name"
      vs_name = arg
  end
end

#RDoc::usage if bigip_address.empty? or bigip_user.empty? or bigip_pass.empty? or vs_name.empty?

# Initiate SOAP RPC connection to BIG-IP
bigip = F5::IControl.new(bigip_address, bigip_user, bigip_pass, ["LocalLB.VirtualServer", "LocalLB.Pool"]).get_interfaces
puts 'Connected to BIG-IP at "' + bigip_address + '" with username "' + bigip_user + '" and password "' + bigip_pass + '"...'


bigip["LocalLB.VirtualServer"].set_connection_mirror_state([vs_name],["STATE_DISABLED"])
