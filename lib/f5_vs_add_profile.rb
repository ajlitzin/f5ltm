require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_vs_add_profile.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      
          
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on("-n", "--vs-name VS_NAME", "Name of virtual server") do |name|
        options.name = name
      end
      
	    opts.on("-p", "--profile PROFILE_NAME", "Name of virtual server profile to apply") do |name|
        options.profile_name = name
      end
      opts.on("-t", "--profile-context-type PROFILE_CONTEXT_TYPE", "Type of virtual server profile to apply") do |context|
        options.profile_context = context || "PROFILE_CONTEXT_TYPE_ALL"
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


def add_vs_profile(lb, vs_list, profile_lists)
  lb.icontrol.locallb.virtual_server.add_profile(vs_list, profile_lists)
end

# get command line options
options = Optparser.parse(ARGV)
case options.profle_context
  when "PROFILE_CONTEXT_TYPE_ALL", "all"
    options.profile_context = "PROFILE_CONTEXT_TYPE_ALL"
  when "server", "PROFILE_CONTEXT_TYPE_SERVER"
    options.profile_context = "PROFILE_CONTEXT_TYPE_SERVER"
  when "client" , "PROFILE_CONTEXT_TYPE_CLIENT"
    options.profile_context = "PROFILE_CONTEXT_TYPE_CLIENT"
  else
    options.profile_context = "PROFILE_CONTEXT_TYPE_ALL"
end

REQ_PARAMS = [:bigip, :name, :profile_name, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file =>  options.bigip_conn_conf, :connect_timeout => 10)


Vs_Profile = Struct.new(:profile_context, :profile_name) do
  def to_hash
    { 'profile_context' => self.profile_context, 'profile_name' => self.profile_name }
  end
end

vs_list = [options.name]
#my_vs_profile = Vs_Profile.new("PROFILE_CONTEXT_TYPE_ALL",options.profile_name)
my_vs_profile = Vs_Profile.new(options.profile_context,options.profile_name)
my_vs_profile_list = [my_vs_profile.to_hash]
my_vs_profile_lists = [my_vs_profile_list]

pp my_vs_profile_lists
add_vs_profile(lb, vs_list, my_vs_profile_lists)
