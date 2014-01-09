require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_rule_create.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
	  
      options.order = "10"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
	    opts.on( "-n", "--rule_name RULE_NAME", "iRule name") do |rule_name|
        options.rule_name = rule_name
      end
      opts.on( "--rule_def RULE_DEF", "rule definition text") do |rule_def|
        options.rule_def = rule_def
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

RuleDef = Struct.new(:name, :def) do
  def to_hash
    { 'rule_name' => self.name, 'rule_definition' => self.def}
  end
end

def gtm_rule_create(lb, rules)
  lb.icontrol.globallb.gtm_rule.create(rules)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :bigip_conn_conf, :rule_name, :rule_def,]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_rule_list = [RuleDef.new(options.rule_name,options.rule_def).to_hash]


pp "my_rule_list: #{my_rule_list}"
gtm_rule_create(lb, my_rule_list)

# ruby -W0 f5_gtm_rule_create.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" --rule_name myfake_vip.tpgtm.info_rule --rule_def 'when DNS_REQUEST { pool dr.enduser.myfake.vip.tpgtm.info_80 }' -b 192.168.106.x
