require './f5'
require 'optparse'
require 'pp'
require 'ruby-debug'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_monitor_set_template_string_property.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.monitor_rule_type = "MONITOR_RULE_TYPE_SINGLE"
           
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on("-s", "--string_value STRING", "String Value to set") do |s|
        options.string_value = s
      end
      opts.on("-t", "--string_property_type STRING_PROPERTY_TYPE", "String Property Type to set") do |spt|
        options.string_property_type = spt
      end
	  opts.on("--monitor_name MONITOR_NAME", "Name of Monitor Template") do |mname|
        options.monitor_name = mname
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

def monitor_set_template_string_property(lb,my_mon_name_list,my_values_list)
  lb.icontrol.locallb.monitor.set_template_string_property(my_mon_name_list,my_values_list)
end

StringValue = Struct.new(:type,:value) do
  def to_hash
    {'type'=>self.type, 'value' => self.value}
  end
end


# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :monitor_name,  :string_property_type, :string_value ]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file =>'../fixtures/config-andy.yaml', :connect_timeout => 10)

my_values = StringValue.new(options.string_property_type,options.string_value)
my_values_list = [my_values.to_hash]

monitor_set_template_string_property(lb,[options.monitor_name], my_values_list)