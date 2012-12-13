require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_pool_set_action_on_service_down.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.action = "SERVICE_DOWN_ACTION_NONE"
      options.quorum = 1
           
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on("-n", "--pool_name POOL_NAME", "Name of Pool") do |name|
        options.pool_name = name
      end
      
	    opts.on("--action ACTION", "Action on Service Down") do |action|
        options.action = action
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

def pool_set_action_on_service_down(lb,pool_names, actions)
  lb.icontrol.locallb.pool.set_action_on_service_down(pool_names, actions)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :pool_name, :action, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

pool_set_action_on_service_down(lb, [options.pool_name], [options.action])
