require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_pool_set_member_enabled_state.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
	  
      options.order = "10"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
	    opts.on( "-vs_name", "--vs_name VS_NAME", "Virtual Server name") do |vs_name|
        options.vs_name = vs_name
      end
      opts.on( "-parent_name", "--parent_name PARENT_NAME", "Virtual Server parent LTM object name") do |parent_name|
        options.parent_name = parent_name
      end
	    opts.on( "--pool_name Pool_NAME", "Name of GTM pool to create") do |pool_name|
        options.pool_name = pool_name
      end
      opts.on("-s", "--state STATE", "pool member state (enabled|disabled") do |state|
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


VirtualServerID = Struct.new(:name, :parent) do
  def to_hash
    { 'name' => self.name, 'server' => self.parent}
  end
end

def gtm_set_pool_member_enabled_state(lb, pool_names, members, states)
  lb.icontrol.globallb.gtm_pool.set_member_enabled_state( pool_names, members, states)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :vs_name, :parent_name, :pool_name, :state, :bigip_conn_conf]
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

my_vs_id_list = [VirtualServerID.new(options.vs_name,options.parent_name).to_hash]
pool_names = [options.pool_name]
states = [options.state]

pp "my_vs_id_list: #{my_vs_id_list} \n"
pp "pool_names: #{pool_names} \n"
gtm_set_pool_member_enabled_state(lb, pool_names, [my_vs_id_list],[states])

# ruby -W0 f5_gtm_set_pool_member_enabled_state.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" --vs_name west.myfake_vip.tpgtm.info_80 --parent_name westbigip01 --pool_name dr.enduser.myfake.vip.tpgtm.info_80 -s disabled -b 192.168.106.x
