require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_set_ipv6_no_error_response_state.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
	    opts.on( "-wip_name", "--wip_name VS_NAME", "WideIP name") do |wip_name|
        options.wip_name = wip_name
      end
      opts.on("-s", "--state STATE", "ipv6 error response state (enabled|disabled") do |state|
        options.state = state
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


def gtm_set_ipv6_no_error_response_state(lb, wide_ips, states)
  lb.icontrol.globallb.gtm_wideip.set_ipv6_no_error_response_state( wide_ips, states)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip,  :bigip_conn_conf, :wip_name, :state]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

case options.state
  when "enabled"
    options.state = "STATE_ENABLED"
  when "disabled"
    options.state = "STATE_DISABLED"
  # else leave it alone so it will error and give the user
  # the typo'd enabled state
end


lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_wip_list =[options.wip_name]
states = [options.state]

gtm_set_ipv6_no_error_response_state(lb, my_wip_list,states)

# ruby -W0 f5_gtm_set_ipv6_no_error_response_state.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" --wip_name myfake.vip.tpgtm.info -s enabled -b 192.168.106.x
