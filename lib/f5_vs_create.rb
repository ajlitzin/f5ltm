require './f5'
require 'optparse'
require 'pp'
require 'ruby-debug'


VirtualServer = Struct.new(:name, :address, :port, :protocol) do
  def to_hash
    { 'name' => self.name, 'address' => self.address, 'port' => self.port, 'protcol' => self.protocol}
  end
end

VirtualServerResource = Struct.new(:type, :default_pool_name)
VirtualServerProfile = Struct.new(:profile_context, :profile_name)

def create_virt_s(lb, vs_def, vs_wildmask, vs_resource, vs_profiles)
pp "our profile #{vs_profiles}"
  #debugger
  lb.icontrol.locallb.virtual_server.create([vs_def],[vs_wildmask],[vs_resource],vs_profiles)
end

def set_virt_default_pool(lb, vs_name, pool_name)
  lb.icontrol.locallb.virtual_server.set_default_pool_name([vs_name],[pool_name])
end
Kernel.abort "Usage: #{$0} <hostname>" if ARGV.empty?

hostname = ARGV[0]

lb = F5::LoadBalancer.new(hostname, :config_file => '../fixtures/config-andy.yaml', :connect_timeout => 10)

myvs = VirtualServer.new("andyruby_testvs", "192.168.94.55", 5556, "PROTOCOL_TCP")
my_vs_resource = VirtualServerResource.new("RESOURCE_TYPE_POOL","")
#my_vs_profile = VirtualServerProfile.new("PROFILE_CONTEXT_TYPE_ALL","")
my_vs_profile = [[{profile_context: "PROFILE_CONTEXT_TYPE_ALL", profile_name: "http"}]]

create_virt_s(lb, myvs, "255.255.255.255", my_vs_resource, my_vs_profile)
#set_virt_default_pool(lb, "andyruby_testvs", "andy-vip-in-pool-test")