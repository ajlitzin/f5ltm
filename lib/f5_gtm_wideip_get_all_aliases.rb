require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_wideip_get_all_aliases.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      options.out_file = ""
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
      end
      opts.on( "--wide_ips_file FILE_LIST_OF_WIDE_IPS", "Name of File with list of WideIPs") do |wip_file|
        options.wide_ips_file = wip_file
      end
      opts.on( "--out_file FILE_LIST_OF_ALIASES", "Name of File to output list of aliases") do |out_file|
        options.out_file = out_file
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

def gtm_wideip_get_alias_list(lb,wide_ip)
  lb.icontrol.globallb.gtm_wideip.get_alias(wide_ip)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :bigip_conn_conf,:wide_ips_file]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end
#pp "options.bigip: #{options.bigip}"
lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

#read in the file

wide_ip_list = IO.readlines(options.wide_ips_file)
wide_ip_list.each do | cur |
  cur.chomp!
end
pp wide_ip_list
# returns a list of aliases per wideip
my_alias_list_of_lists = gtm_wideip_get_alias_list(lb,wide_ip_list)
my_alias_list_of_lists.flatten!
#pp my_alias_list_of_lists
if options.out_file == "" then 
  pp my_alias_list_of_lists
else
  File.open(options.out_file, "w") do |f|
    f.puts(my_alias_list_of_lists)
  end
end

# ruby -W0 f5_gtm_wideip_get_all_aliases.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" -b 192.168.106.x -wide_ips_file "../private-fixtures/my-list-of-wideips.txt"
