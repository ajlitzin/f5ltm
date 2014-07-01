require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_vs_get_list.rb [options]"
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
      opts.on( "-n", "--name VS NAME", "Name of VS to look for") do |vs_name|
        options.vs_name = vs_name
      end
    end
    opts.parse!(args)
    options
  end # self.parse
end #class Optparser


def get_vs_list(lb)
  lb.icontrol.locallb.virtual_server.get_list
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

lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

vs_list = get_vs_list(lb)
#normalize case
vs_list.each { |x| x.downcase!}
# remove /common/
vs_list.each { |x| x.gsub!(/\/common\//,"")}

if options.vs_name
  unless vs_list.include?(options.vs_name)
    pp "we found it"
  else
    pp "did NOT find it"
  end
else
  pp vs_list
end
