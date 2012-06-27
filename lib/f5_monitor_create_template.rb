require './f5'
require 'optparse'
require 'pp'
require 'ruby-debug'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_monitor_create_template.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      options.type = "TTYPE_HTTP"
      
           
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on("-n", "--name TEMPLATE_NAME", "Name of Monitor Template") do |name|
        options.name = name
      end
      opts.on("--type [TEMPLATE TYPE]", "Template Type") do |type|
        options.template_type = type || "TTYPE_HTTP"
      end
      opts.on("--parent_template [PARENT TEMPLATE]", "Parent Template to inherit from") do |parent|
	    options.parent_template = parent
      end
	    opts.on("--interval [INTERVAL]", "How frequently the monitor instance of this template will run") do |int|
	      options.interval = int
      end
	    opts.on("--timeout [TIMEOUT]", "The Number of seconds in which the node or service must respond to the monitor request") do |timeout|
	      options.timeout = timeout
      end
	    ## FIX THIS- SPLIT IT UP
	    opts.on("--monitor_ip [MonitorIP]", "The destination IP of this monitor template") do |ip|
	      options.monitor_ip = ip || "*"
      end
      opts.on("--monitor_port [MonitorPort]", "The destination Port of this monitor template") do |port|
	      options.monitor_port = port || "*"
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

MonitorTemplate = Struct.new(:template_name, :template_type) do
  def to_hash
    {'template_name'=>  self.template_name,'template_type'=>self.template_type}
  end
end
MonitorCommonAttributes = Struct.new(:parent_template, :interval, :timeout, :dest_ipport,:is_read_only,:is_directly_usable) do
  def to_hash
    {'parent_template' => self.parent_template, 'interval'=> self.interval, 'timeout' => self.timeout, 'dest_ipport' => self.dest_ipport, 'is_read_only' => self.is_read_only, 'is_directly_usable' => self.is_directly_usable}
  end
end


def create_monitor_template(lb,my_mon_template_list, my_mon_attr_list)
pp "mon_template_list #{my_mon_template_list}"
pp " mon attr list: #{my_mon_attr_list}"
#debugger
  lb.icontrol.locallb.monitor.create_template(my_mon_template_list, my_mon_attr_list)
end
# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :name]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file =>'../fixtures/config-andy.yaml', :connect_timeout => 10)


my_mon_template = MonitorTemplate.new(options.name, options.type)
my_mon_template_list = [my_mon_template.to_hash]
my_dest_ipport = { 'address_type' => "ATYPE_STAR_ADDRESS_STAR_PORT", 'ipport' => {'address' => "0.0.0.0", 'port' => 0}}
my_mon_common_attr = MonitorCommonAttributes.new("http", 5, 16, my_dest_ipport, "false", "true")
my_mon_common_attr_list = [my_mon_common_attr.to_hash]
pp "mon template: #{my_mon_template_list}"
pp "mon attrs: #{my_mon_common_attr_list}"

create_monitor_template(lb,my_mon_template_list,my_mon_common_attr_list)