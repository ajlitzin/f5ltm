require './f5'
require 'optparse'
require 'pp'
require 'ruby-debug'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_pool_set_min_active_member.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.min_active_members = "2"
           
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on("-n", "--pool_name POOL_NAME", "Name of Pool") do |name|
        options.pool_name = name
      end
      
	  opts.on("--min_active_members MIN_ACTIVE_MEMBERS", "Minimum active members") do |min_mem|
        options.min_active_members = min_mem
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

def pool_set_min_active_member(lb,pool_names,values)
  lb.icontrol.locallb.pool.set_minimum_active_member(pool_names,values)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :pool_name]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file =>'../fixtures/config-andy.yaml', :connect_timeout => 10)

pool_set_min_active_member(lb,[options.pool_name],[options.min_active_members])
