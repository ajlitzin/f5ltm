require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_pool_create_v2.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
	  
      options.lb_method = "LB_METHOD_GLOBAL_AVAILABILITY"
      options.order = ""
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on( "--vs_name VS_NAME", "Name of virtual server") do |vs_name|
        options.vs_name = vs_name
      end
	  opts.on( "--parent_name PARENT_NAME", "Name of parent LTM object of virtual server") do |parent_name|
        options.parent_name = parent_name
      end
	  opts.on( "--pool_name Pool_NAME", "Name of GTM pool to create") do |pool_name|
        options.pool_name = pool_name
      end
      opts.on("-p", "--port PORT", "Virtual Server Port") do |port|
        options.port = port
      end
      opts.on("-o", "--order ORDER", "pool member order number") do |order|
        options.order = order
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


VirtualServerID = Struct.new(:name, :parent) do
  def to_hash
    { 'name' => self.name, 'server' => self.parent}
  end
end

def gtm_create_pool(lb, pool_names, lb_methods, vs_def, orders)
  lb.icontrol.globallb.gtm_pool.create_v2( pool_names, lb_methods, vs_def, orders)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :vs_name, :pool_name, :port, :parent_name, :order, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end
#pp "options.bigip: #{options.bigip}"
lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_vs_id = VirtualServerID.new(options.vs_name, options.parent_name)
my_vs_id_list = [my_vs_id.to_hash]
pool_names = ["#{options.pool_name}_#{options.port}"]
lb_methods = [options.lb_method]
orders = [[options.order]]

pp "myvsid_list: #{my_vs_id_list} \n"
pp "pool_names: #{pool_names} \n"
gtm_create_pool(lb, pool_names, lb_methods, my_vs_id_list, orders)

# ruby -W0 f5_gtm_pool_create_v2.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" --vs_name east.myfake.vip.tpgtm.info --parent_name eastbigip01 --pool_name dr.enduser.myfake.vip.tpgtm.info --order 0 -port 80 -b 192.168.106.x
