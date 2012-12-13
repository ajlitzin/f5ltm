require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_vs_set_vlan.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
          
      options.vlan_state = "STATE_ENABLED"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on("-n", "--vs_name VS_NAME", "Name of virtual server") do |name|
        options.name = name
      end
      
	  opts.on("-s", "--vlan_name VLAN NAME", "Name of vlan") do |vlan|
        options.vlan_name = vlan
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


def set_vlan(lb, vs_list, vlan_filter_list)
  lb.icontrol.locallb.virtual_server.set_vlan(vs_list, vlan_filter_list)
end

VLANFilterList = Struct.new(:vlan_names,:enabled_state) do
  def to_hash
    {'vlans'=>self.vlan_names, 'state' => self.enabled_state}
  end
end

# get command line options
options = Optparser.parse(ARGV)


REQ_PARAMS = [:bigip, :name, :vlan_name, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file =>  options.bigip_conn_conf, :connect_timeout => 10)

vs_list = [options.name]
vlan_list = [options.vlan_name]
my_vlan_filter = VLANFilterList.new(vlan_list, "STATE_ENABLED")
my_vlan_filter_list = [my_vlan_filter.to_hash]

set_vlan(lb, vs_list, my_vlan_filter_list)

