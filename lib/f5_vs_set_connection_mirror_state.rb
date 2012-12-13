require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_vs_set_connection_mirror_state.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
          
      options.mirrored_state = "STATE_DISABLED"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on("-n", "--vs_name VS_NAME", "Name of virtual server") do |name|
        options.name = name
      end
      
	  opts.on("-s", "--mirrored_state MIRRORED_STATE", "Mirror Connection State") do |state|
        options.mirrored_state = state
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


def set_connection_mirror_state(lb, vs_list, state_list)
  lb.icontrol.locallb.virtual_server.set_connection_mirror_state(vs_list, state_list)
end

# get command line options
options = Optparser.parse(ARGV)


REQ_PARAMS = [:bigip, :name, :mirrored_state, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file =>  options.bigip_conn_conf, :connect_timeout => 10)

vs_list = [options.name]
mirrored_state_list = [options.mirrored_state]

pp mirrored_state_list
set_connection_mirror_state(lb, vs_list, mirrored_state_list)

