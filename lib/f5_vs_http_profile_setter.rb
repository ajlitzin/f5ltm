require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_vs_http_profile_setter.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
          
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
	    opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
	    opts.on( "-f", "--vip_file VIP_FILE", "File with list of vips") do |filename|
        options.vs_list_file = filename
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

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

# list has to be formatted one vs name per line
vs_list = File.readlines(options.vs_list_file)
# get rid of any CR LF
vs_list.each do |cur_vs|
  cur_vs.chop!
end
#vs_list = ["andy_ruby_fqdn2_5557", "andy_ruby_fqdn_5556"]

pp vs_list
 vs_list.each do |cur_vs|
  output = %x{ruby -W0 f5_vs_add_profile.rb --name #{cur_vs.to_s} --bigip #{options.bigip} --bigip_conn_conf #{options.bigip_conn_conf} --profile "http"}
 end
