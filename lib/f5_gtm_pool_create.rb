require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_pool_create.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
	  
      options.lb_method = "LB_METHOD_GLOBAL_AVAILABILITY"
      options.order = ""
      options.address = ""
      options.port = ""
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
	    opts.on( "-a", "--address IP_ADDRESS", "Virtual Server IP address") do |ip|
        options.address = ip
      end
	  opts.on( "--pool_name Pool_NAME", "Name of GTM pool to create") do |pool_name|
        options.pool_name = pool_name
      end
      opts.on("-p", "--port PORT", "Port of parent LTM Virtual Server") do |port|
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


IPPortDev = Struct.new(:address, :port) do
  def to_hash
    { 'address' => self.address, 'port' => self.port}
  end
end

def gtm_create_pool(lb, pool_names, lb_methods, pool_mem_def)
  lb.icontrol.globallb.gtm_pool.create( pool_names, lb_methods, pool_mem_def)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :address, :pool_name, :port, :order, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end
#pp "options.bigip: #{options.bigip}"
lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

if options.address == "" || options.port == "" then
  my_pool_member_list = []
else
  my_member = IPPortDev.new(options.address, options.port)
  my_pool_member_list = [ 'member'=>my_member.to_hash, 'order'=>options.order]
end
pool_names = [options.pool_name]
lb_methods = [options.lb_method]

pp "my_pool_member_list: #{my_pool_member_list} \n"
pp "pool_names: #{pool_names} \n"
gtm_create_pool(lb, pool_names, lb_methods, [my_pool_member_list])

# ruby -W0 f5_gtm_pool_create.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" --address 6.6.6.6 --pool_name dr.enduser.myfake.vip.tpgtm.info --order 0 --port 80 -b 192.168.106.x
