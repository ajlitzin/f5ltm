require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: pool_exists.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
          
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on( "--pool_name Pool Name", "Name of Pool to look for") do |pool_name|
        options.pool_name = pool_name
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


def get_pool_list(lb)
  lb.icontrol.locallb.pool.get_list
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :bigip_conn_conf, :pool_name]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

existing_pools = %x{ruby -W0 f5_pool_get_list.rb --bigip #{options.bigip} --bigip_conn_conf #{options.bigip_conn_conf}  }

if existing_pools.include?("#{options.pool_name.downcase}")
  p "WE found it!!/n"
else
  printf "new pool baby, let's make it"
end
