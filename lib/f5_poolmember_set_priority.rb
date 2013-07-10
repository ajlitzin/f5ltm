require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_poolmember_set_priority.rb [options]"
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

def poolmember_set_priority(lb, pool_names, priorities)
  lb.icontrol.locallb.pool_member.set_priority(pool_names, priorities)
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

my_poolmem_priority = MemberPriority.new(my_member,options.member_priority)
my_poolmem_pri_list_of_lists = [[my_poolmem_priority.to_hash]]

pp "pool names #{my_pool_names}"
pp "poolmem pri #{my_poolmem_pri_list_of_lists}"

poolmember_set_priority(lb, my_pool_names, my_poolmem_pri_list_of_lists)
