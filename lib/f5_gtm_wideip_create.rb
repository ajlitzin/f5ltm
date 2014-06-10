require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_wideip_create.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.pool_name = ""
      options.order = ""
      options.ratio = ""
      options.rule_name = ""
      options.rule_priority = 0
      options.lb_method = "LB_METHOD_ROUND_ROBIN"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on("-n", "--name WIDEIP_NAME", "Name of wideip") do |name|
        options.name = name
      end
	    opts.on( "--pool_name POOL_NAME", "Name of pool") do |pool_name|
        options.pool_name = pool_name
      end
	    opts.on("-o", "--order POOL_ORDER", "Order of Pool") do |order|
        options.order = order
      end
	    opts.on("-r", "--ratio POOL_RATIO", "Ratio of Pool") do |ratio|
        options.ratio = ratio
      end
      opts.on( "--rule_name RULE_NAME", "iRule Name") do |rule_name|
        options.rule_name = rule_name
      end
	    opts.on("--rule_priority RULE_PRIORITY", "Priority of rule") do |rule_pri|
        options.rule_priority = rule_pri
      end
      opts.on("--lb_method LB_METHOD", "WideIP LB Method to balance between multiple pools") do |method|
        options.lb_method = method
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


WideIPPool = Struct.new(:name, :order, :ratio) do
  def to_hash
    { 'pool_name' => self.name, 'order' => self.order, 'ratio' => self.ratio}
  end
end

WideIPRule = Struct.new(:name, :priority) do
  def to_hash
    { 'rule_name' => self.name, 'priority' => self.priority}
  end
end

def gtm_create_wideip(lb, wide_ips, lb_methods, wideip_pools,wideip_rules)
  lb.icontrol.globallb.gtm_wideip.create(wide_ips, lb_methods, wideip_pools,wideip_rules)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :bigip_conn_conf, :name]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end
#pp "options.bigip: #{options.bigip}"
lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

if (options.pool_name == "" || options.order == "" || options.ratio == "") then
  my_wip_pool_list = []
else
  my_wip_pool_list = [WideIPPool.new(options.pool_name, options.order, options.ratio).to_hash]
end

if options.rule_name == ""
  my_wip_rule_list = []
else
  my_wip_rule_list = [WideIPRule.new(options.rule_name, options.rule_priority).to_hash]
end

pp "my_wip_pool_list: #{my_wip_pool_list} \n"
pp "my_wip_rule_list: #{my_wip_rule_list} \n"
gtm_create_wideip(lb, [options.name], [options.lb_method], [my_wip_pool_list], [my_wip_rule_list])

# ruby -W0 f5_gtm_wideip_create.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" --name myfake.vip.tpgtm.info --rule_name myfake_vip.tpgtm.info_rule -b 192.168.106.x
