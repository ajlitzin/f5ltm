require './f5'
require 'optparse'
require 'pp'
require 'ruby-debug'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_vs_set_snat_pool.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.snat_pool_name = "automap"
           
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on("-n", "--vs_name VIRTUAL_SERVER_NAME", "Name of Virtual Server") do |name|
        options.vs_name = name
      end
      
	  opts.on("--snat_pool_name SNAT_POOL_NAME", "Name of Snat Pool") do |snat_pname|
        options.snat_pool_name = snat_pname
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

def vs_set_snat_pool(lb,virtual_servers,snatpools)
  lb.icontrol.locallb.virtual_server.set_snat_pool(virtual_servers,snatpools)
end

def vs_set_snat_automap(lb,virtual_servers)
  lb.icontrol.locallb.virtual_server.set_snat_automap(virtual_servers)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :vs_name]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file =>'../fixtures/config-andy.yaml', :connect_timeout => 10)

if options.snat_pool_name.downcase.eql?("automap")
  vs_set_snat_automap(lb,[options.vs_name])
else
  vs_set_snat_pool(lb,[options.vs_name],[options.snat_pool_name])
end
