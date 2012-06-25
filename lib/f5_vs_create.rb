require './f5'
require 'optparse'
require 'pp'
require 'ruby-debug'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_vs_create.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.default_pool_name = ""
      options.protocol = "PROTOCOL_TCP"
      options.netmask = ["255.255.255.255"]
      options.resource_type = "RESOURCE_TYPE_POOL"
      options.profile_context = "PROFILE_CONTEXT_TYPE_ALL"
      options.profile_name = "http"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "-a", "--address IP_ADDRESS", "Virtual Server IP address") do |ip|
        options.address = ip
      end
      opts.on("-n", "--name VS_NAME", "Name of virtual server") do |name|
        options.name = name
      end
      opts.on("-p", "--port PORT", "Virtual Server Port") do |port|
        options.port = port
      end
      opts.on("-P", "--protocol PROTOCOL", "Protocol Type") do |protocol|
        options.protocol = protocol || "PROTOCOL_TCP"
      end
      opts.on("-m", "--mask NETMASK", "Subnet Mask, 255.255.255.255 for hosts") do |mask|
        options.netmask = [mask] || ["255.255.255.255"]
      end
      opts.on("-t", "--resource_type TYPE", "Virtual Server Resource Type") do |type|
        options.resource_type = type || "RESOURCE_TYPE_POOL"
      end
      opts.on("-l", "--pool_name POOL NAME", "Default Pool Name") do |poolname|
        options.default_pool_name = poolname || ""
      end
      opts.on("--profile_context PROFILE_CONTEXT_TYPE", [:PROFILE_CONTEXT_TYPE_ALL, :PROFILE_CONTEXT_TYPE_CLIENT, :PROFILE_CONTEXT_TYPE_SERVER],   "Select Profile Context Type (Profile_context_type_all,MOREDUDE)") do |pc|
        options.profile_context = pc || "PROFILE_CONTEXT_TYPE_ALL"
      end
      opts.on("--profile_name NAME", [:http], "Select Profile Name (http)") do |pn|
        options.profile_name = pn
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


VirtualServer = Struct.new(:name, :address, :port, :protocol) do
  def to_hash
    { 'name' => self.name, 'address' => self.address, 'port' => self.port, 'protocol' => self.protocol}
  end
end

VirtualServerResource = Struct.new(:type, :default_pool_name) do
  def to_hash
    { 'type' => self.type, 'default_pool_name' => self.default_pool_name}
  end
end

VirtualServerProfile = Struct.new(:profile_context, :profile_name) do
  def to_hash
    { 'profile_context' => self.profile_context, 'profile_name' => self.profile_name}
  end
end

def create_virt_s(lb, vs_def, vs_wildmask, vs_resource, vs_profiles)
pp "our profile #{vs_profiles}"
  #debugger
  lb.icontrol.locallb.virtual_server.create(vs_def,vs_wildmask,vs_resource,vs_profiles)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :name, :address, :port]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file => '../fixtures/config-andy.yaml', :connect_timeout => 10)

#myvs = VirtualServer.new("andyruby_testvs", "192.168.94.55", 5556, "PROTOCOL_TCP")
myvs = VirtualServer.new(options.name, options.address, options.port.to_i, options.protocol)
myvs_list = [myvs.to_hash]

#my_vs_resource = VirtualServerResource.new("RESOURCE_TYPE_POOL","name_of_default_pool")
my_vs_resource = VirtualServerResource.new(options.resource_type,options.default_pool_name)
my_vs_resource_list = [my_vs_resource.to_hash]

#my_vs_profile = {profile_context: options.profile_context, profile_name: options.profile_name}
my_vs_profile = VirtualServerProfile.new(options.profile_context, options.profile_name)
my_vs_profile_list = [my_vs_profile.to_hash]
my_vs_profile_lists = [my_vs_profile_list]

create_virt_s(lb, myvs_list, options.netmask, my_vs_resource_list, my_vs_profile_lists)