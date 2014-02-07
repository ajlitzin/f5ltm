require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser


  LB_METHODS = %w[LB_METHOD_GLOBAL_AVAILABILITY LB_METHOD_TOPOLOGY]
  LB_METHOD_ALIASES = { "ga" => "LB_METHOD_GLOBAL_AVAILABILITY", "topology" => "LB_METHOD_TOPOLOGY"}


  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_pool_set_alternate_lb_method.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
	  
      options.lb_method = "LB_METHOD_GLOBAL_AVAILABILITY"
      options.port = "80"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
 	    opts.on( "--pool_name POOL_NAME", "Name of GTM pool") do |pool_name|
        options.pool_name = pool_name
      end
      lb_method_list = (LB_METHOD_ALIASES.keys + LB_METHODS).join(",")
      opts.on("--lb_method LB_METHOD", LB_METHODS, LB_METHOD_ALIASES, "Select LB Method",
             "  (#{lb_method_list})") do |lb_method|
         options.lb_method = lb_method
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

def gtm_set_alternate_lb_method(lb, pool_names, lb_methods)
  lb.icontrol.globallb.gtm_pool.set_alternate_lb_method( pool_names, lb_methods)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :pool_name, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end
#pp "options.bigip: #{options.bigip}"
lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

pool_names = [options.pool_name]
lb_methods = [options.lb_method]

pp "pool_names: #{pool_names} \n"
gtm_set_alternate_lb_method(lb, pool_names, lb_methods)

# ruby -W0 f5_gtm_set_alternate_lb_method.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" --pool_name dr.enduser.myfake.vip.tpgtm.info_80 -b 192.168.106.x
