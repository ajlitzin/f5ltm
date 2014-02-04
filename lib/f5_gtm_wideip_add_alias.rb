require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_wideip_add_alias.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on( "-w", "--wide_ip WIDE_IP", "Name of WideIP") do |wip|
        options.wide_ip = wip
      end
      opts.on( "-a", "--alias_name ALIAS", "Alias to add to  WideIP") do |alias_name|
        options.alias_name = alias_name
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

def gtm_wideip_add_alias(lb,wide_ip_list,alias_lists)
  lb.icontrol.globallb.gtm_wideip.add_alias(wide_ip_list,alias_lists)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :bigip_conn_conf,:wide_ip, :alias_name]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end
#pp "options.bigip: #{options.bigip}"
lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_alias_list = [options.alias_name]
my_wip_list = [options.wide_ip]
pp my_alias_list
pp my_wip_list
gtm_wideip_add_alias(lb,my_wip_list,[my_alias_list])

# ruby -W0 f5_gtm_wideip_add_alias.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" -b 192.168.106.x -wide_ip bob.theplatform.com --alias cust.bob.theplatform.com
