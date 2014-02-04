require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_pool_add_member_v2.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.members = []
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on("-n", "--name POOL_NAME", "Name of Pool") do |name|
        options.name = name
      end
      opts.on("--member IP:PORT", "Pool Member(s), IP:Port") do |pmem|
        options.members << pmem
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

Member = Struct.new(:address, :port) do
  def to_hash
    { 'address' => self.address, 'port' => self.port }
  end
end

def member_split(members)
  member_list = []
  members.each do |mem|
    address, port = mem.split(/:/, 2)
    member_list << {'address' => address, 'port' => port}
  end
  member_list
end
def add_member(lb, pool_names, members)
  lb.icontrol.locallb.pool.add_member_v2(pool_names, members)
end
# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :name, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

mypool_names = [options.name]
mymember_lists = [member_split(options.members)]
pp mymember_lists  
add_member(lb, mypool_names, mymember_lists)
#
#ruby -W0 f5_pool_add_member_v2.rb --bigip_conn_conf ..\private-fixtures\config-andy.yaml --bigip 192.168.106.x --name my.pool.name_1234 --member 192.168.48.55:1234 --member 192.168.48.56:1234
