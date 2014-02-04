require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_wideip_get_alias.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on(  "--bigip_get IP", "BigIP IP address to get widip alias from") do |bip|
        options.bigip_get = bip
      end
      opts.on(  "--bigip_add IP", "BigIP IP address to add widip alias to") do |bip_add|
        options.bigip_add = bip_add
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on( "-w", "--wide_ip WIDE_IP", "Name of WideIP") do |wip|
        options.wide_ip = wip
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

def gtm_wideip_get_alias_list(lb,wide_ip)
  lb.icontrol.globallb.gtm_wideip.get_alias(wide_ip)
end

def gtm_wideip_add_alias(lb,wide_ip_list,alias_lists)
  lb.icontrol.globallb.gtm_wideip.add_alias(wide_ip_list,alias_lists)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip_get, :bigip_add, :bigip_conn_conf,:wide_ip]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb_get = F5::LoadBalancer.new(options.bigip_get, :config_file => options.bigip_conn_conf, :connect_timeout => 10)
lb_add = F5::LoadBalancer.new(options.bigip_add, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_wide_ip_list = [options.wide_ip]
pp options.wide_ip
my_alias_listoflists = gtm_wideip_get_alias_list(lb_get,my_wide_ip_list)
pp my_alias_listoflists
pp "applying list of aliases..."
gtm_wideip_add_alias(lb_add,my_wide_ip_list,my_alias_listoflists)

# ruby -W0 f5_gtm_wideip_get_and_set_alias.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" --bigip_get 192.168.106.x --bigip_add 192.168.106.y --wide_ip bob.theplatform.com
