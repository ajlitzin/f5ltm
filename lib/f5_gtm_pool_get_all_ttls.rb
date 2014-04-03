require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_pool_get_all_ttls.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
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

def gtm_pool_get_list(lb)
  lb.icontrol.globallb.gtm_pool.get_list()
end

def gtm_pool_get_ttl(lb, pool_list)
  lb.icontrol.globallb.gtm_pool.get_ttl(pool_list)
end
# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

#pp options.ttl
lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_pool_list = gtm_pool_get_list(lb)

my_pools_and_ttl_list = my_pool_list.zip(gtm_pool_get_ttl(lb,my_pool_list))
pp my_pools_and_ttl_list


# ruby -W0 f5_gtm_pool_get_all_ttls.rb --bigip_conn_conf "../private-fixtures/config-andy-qa-gtm-ve.yml" -b 192.168.106.x 
