require './f5'
require 'optparse'
require 'pp'
require 'ruby-debug'

def set_virt_default_pool(lb, vs_name, pool_name)
  lb.icontrol.locallb.virtual_server.set_default_pool_name([vs_name],[pool_name])
end

lb = F5::LoadBalancer.new(hostname, :config_file => '../fixtures/config-andy.yaml', :connect_timeout => 10)


set_virt_default_pool(lb, "andyruby_testvs", "andy-vip-in-pool-test")