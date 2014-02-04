require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

# requires v11 and up
# replaces old poolmember_set_priority method

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_pool_set_member_priority.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.member_priority = "0"
      
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
        options.member = pmem
      end
	  opts.on("--member_priority [PRIORITY]", "Pool Member Priority") do |pmem_pri|
        options.member_priority = pmem_pri
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

MemberPriority = Struct.new(:member,:priority) do
  def to_hash
    { 'member' => self.member, 'priority' => self.priority}
  end
end

def member_split(member)
  address, port = member.split(/:/, 2)
  {'address' => address, 'port' => port}
end

def poolmember_set_priority(lb, pool_names, members, priorities)
  lb.icontrol.locallb.pool.set_member_priority(pool_names, members, priorities)
end
# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :name, :member, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

if (options.member.nil? or options.member.to_s.eql?("nil") or options.member.to_s.empty?)
   Kernel.abort "member can not be nil. Skipping setting priority value for member of pool #{options.name}" 
end

lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_pool_names = [options.name]
my_member = member_split(options.member)
my_member_list_of_lists =[[my_member]]

my_poolmem_pri_list_of_lists = [[options.member_priority]]

pp "pool names #{my_pool_names}"
pp "poolmem pri #{my_poolmem_pri_list_of_lists}"

poolmember_set_priority(lb, my_pool_names, my_member_list_of_lists, my_poolmem_pri_list_of_lists)

# ruby -W0 f5_pool_set_member_priority.rb ruby -W0 phl3_ltm_pool_filler.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" -b 192.168.106.x --member 192.168.48.55:1234 --name bob.example.com_1234 --member_priority 3
