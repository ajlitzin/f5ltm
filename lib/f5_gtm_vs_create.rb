require './f5'
require 'optparse'
require 'pp'
require 'ostruct'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: f5_gtm_vs_create.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      options.port = "80"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf F5 Connection Config", "BigIP IP connection config") do |bipconf|
        options.bigip_conn_conf = bipconf
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
      opts.on("-P", "--parent PARENT", "GTM object name of LTM that owns the Virtual Server") do |parent|
        options.parent = parent
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


VirtualServerID = Struct.new(:name, :parent) do
  def to_hash
    { 'name' => self.name, 'server' => self.parent}
  end
end


IPPortDef = Struct.new(:address, :port) do
  def to_hash
    { 'address' => self.address, 'port' => self.port}
  end
end

def create_virt_s(lb, vs_def, vs_ip_ports)
  lb.icontrol.globallb.gtm_virtual_server_v2.create(vs_def,vs_ip_ports)
end

# get command line options
options = Optparser.parse(ARGV)

# exit if required parameters are missing
# this may need some work
# maybe swap optparse for trollop?
REQ_PARAMS = [:bigip, :name, :address, :port, :parent,:bigip_conn_conf]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end
#pp "options.bigip: #{options.bigip}"
lb = F5::LoadBalancer.new(options.bigip, :config_file => options.bigip_conn_conf, :connect_timeout => 10)

my_vs_id = VirtualServerID.new(options.name, options.parent)
my_vs_id_list = [my_vs_id.to_hash]

my_ip_port = IPPortDef.new(options.address, options.port)
my_ip_port_list = [my_ip_port.to_hash]


pp "myvsid_list: #{my_vs_id_list} \n"
pp "my_ip_port_list: #{my_ip_port_list} \n"
create_virt_s(lb, my_vs_id_list, my_ip_port_list)

# ruby -W0 f5_gtm_vs_create.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" --address 5.5.5.5 --name west.myfake.vip.tpgtm.info --parent westbigip01 --port 80 -b 192.168.106.x
