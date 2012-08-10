require './f5'
require 'optparse'
require 'pp'
require 'ruby-debug'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_pool_set_monitor_associaition.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.monitor_rule_type = "MONITOR_RULE_TYPE_SINGLE"
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
      
	    opts.on("--monitor_name MONITOR_NAME", "Name of Monitor Template") do |mname|
        options.monitor_name = mname
      end
 	    opts.on("--monitor_rule_type MONITOR_RULE_TYPE", "Monitor Rule Type") do |mtname|
        options.monitor_rule_type = mtname || "MONITOR_RULE_TYPE_SINGLE"
      end
      opts.on("--quorum MONITOR_RULE_QUORUM", "When multiple monitors are bound, how many need to succeed for resource to be up") do |q|
        options.quorum = q || 1
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

def pool_set_monitor_association(lb,my_mon_assoc)
  lb.icontrol.locallb.pool.set_monitor_association(my_mon_assoc)
end

PoolMonitorAssociaion = Struct.new(:pool_name,:monitor_rule) do
  def to_hash
    {'pool_name'=>self.pool_name, 'monitor_rule' => self.monitor_rule}
  end
end

MonitorRule = Struct.new(:monitor_rule_type,:quorum,:monitor_templates) do
  def to_hash
    { 'type' => self.monitor_rule_type, 'quorum' => self.quorum, 'monitor_templates'=> self.monitor_templates}
  end
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :pool_name, :monitor_name, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_monitor_rule = MonitorRule.new(options.monitor_rule_type,options.quorum,[options.monitor_name])
my_pool_mon_assoc = PoolMonitorAssociaion.new(options.pool_name,my_monitor_rule.to_hash)

pool_set_monitor_association(lb,[my_pool_mon_assoc])