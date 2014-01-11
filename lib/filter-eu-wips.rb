require './f5'
require 'pp'
require 'optparse'
require 'ostruct'


class Optparser
  def self.parse(args)
    options = OpenStruct.new
    
    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_wideip_get_list.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.file_name = "theplatform.eu-fqdns.txt"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on( "-w", "--file_name FILE_NAME", "write to FILE_NAME") do |file_name|
        options.file_name = file_name
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

def gtm_wideip_get_list(lb)
  lb.icontrol.globallb.gtm_wideip.get_list()
end

#pp "options.bigip: #{options.bigip}"
lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_wip_list = gtm_wideip_get_list(lb)

#my_wip_list is now an array with wip names in format of [/Common/service.fake.com,/Common/example.com]
# need to grab theplatfor.eu entries, and strip the /Common prefix

# first find theplatform.eu guys
eu_wips = my_wip_list.select { |s| s.include?"theplatform.eu"}
File.open("../private-fixtures/#{options.file_name}",'w') do |file|
  # now stip off the /Common BS"
  eu_wips.each do |s|
   s.sub!(/^\/Common\//,"")
   file.puts "#{s}"
  end
end

#pp eu_wips