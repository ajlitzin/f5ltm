require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_vs_get_profile.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
          
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on("-n", "--name VS_NAME", "Name of virtual server") do |name|
        options.name = name
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


def get_vs_profile(lb, vs_list)
  lb.icontrol.locallb.virtual_server.get_profile(vs_list)
end

# get command line options
options = Optparser.parse(ARGV)


REQ_PARAMS = [:bigip, :name, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

vs_list = [options.name]
# i did use a temp hard coded list here- may need to
# come back and fix the file reader
# vs_list = [ list of vs names, vs2, etc]

# set up to loop through an array of vs names
# but currentl only accepts single vs name via cmd line

## extra code in here from when i used this to figure out which
## existing lab vips didn't have an http profile attached to them
## so i could then apply one to get X-Forwarded-For working
my_profiles =[]
non_http_vs_list =[]
has_http = false
vs_list.each do |cur_vs|
  #pp cur_vs
  my_profiles = get_vs_profile(lb, [cur_vs])
  #pp my_profiles
  
  my_profiles.first.each do |prof|
    if prof.profile_type.eql?("PROFILE_TYPE_HTTP")
      has_http = true
    
    end
  end
  unless has_http
    non_http_vs_list << cur_vs
  end
  has_http = false
end
pp my_profiles
#pp non_http_vs_list
# 5.times {pp "---------------"}
# pp "count of all vs #{vs_list.count}"
# pp "count of dupe vs w/o http #{non_http_vs_list.count}"
