# read in csv of hostname,fqdn,jetty_port,pga
# lookup IPs for each server name (create hash of serverame=>ipaddress)
# add members to pool
# set pool member pga values

require 'yaml'
require 'optparse'
require 'ostruct'
require 'csv'
require 'pp'
require 'resolv'

#global vars
$debug = false

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: phl3_ltm_pool_filler.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "--bigip_conn_conf BigIP Connection Config File", "BigIP Connection Config File") do |bipcfile|
        options.bigip_conn_conf = bipcfile || "../private-fixtures/bigipconconf.yml"
      end
      opts.on( "-c", "--csv_file CSV_FILE", "The CSV file with LTM pool member hostnames,fqdn,jetty_port,pga ") do |csv_file|
        options.csv_file = csv_file
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
REQ_PARAMS = [ :bigip, :bigip_conn_conf, :csv_file]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

def normalize_priority(pga)
  case pga
  when "0"
    pga = 3
  when "5"
    pga = 2
  when "9"
    pga = 1
  end
end

#csv_data = CSV.read("../private-fixtures/phl3.csv")
csv_data = CSV.read("#{options.csv_file}")
headers = csv_data.shift.map {|i| i.to_s }
# we expect 4 columns: hostname, fqdn, jetty port, pga
Kernel.abort "Warning!  Header count is not expected.  Expected 4, got #{headers.length}" unless headers.length == 4

# just overwrite the header names to what i like
# in this case they are already what i want, but don't want to mess with re-used code below
headers = [ "hostname", "fqdn", "jetty_port", "pga"]
#pp "#{headers}\n"

string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
csv_array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten]}
new_csv_array_of_hashes =[]

pp "read in csv of hashes"
# csv_array_of_hashes.each do | cur_mem |
 # pp "#{cur_mem}\n"
# end
# pp "#{csv_array_of_hashes}\n"

host_hash ={}
# normalize all the vip fqdns to lowercase and get down to single vip port per vip
csv_array_of_hashes.each do |member|
  member["fqdn"].downcase!
  host_hash[member["hostname"]] = Resolv.getaddress(member["hostname"])
end
# pp "new csv of hashes \n"
# pp host_hash
# pp "#{new_csv_array_of_hashes}\n"
# new_csv_array_of_hashes.each do | cur_mem |
 # pp "#{cur_mem}\n"
# end
#
 

csv_array_of_hashes.each do |cur_mem|
  # add members to the pool 
  pp "adding #{cur_mem["hostname"]} to pool phl3.#{cur_mem["fqdn"]}_#{cur_mem["jetty_port"]}"
  cur_mem_ip = host_hash[cur_mem["hostname"]]
  output = %x{ruby -W0 f5_pool_add_member_v2.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --name "phl3.#{cur_mem["fqdn"]}_#{cur_mem["jetty_port"]}" --member "#{cur_mem_ip}:#{cur_mem["jetty_port"]}"}
  # set pga value
  my_pri = normalize_priority(cur_mem["pga"])
  pp "setting pga to #{my_pri}"
  output = %x{ruby -W0 f5_pool_set_member_priority.rb --bigip_conn_conf #{options.bigip_conn_conf} --bigip #{options.bigip} --name "phl3.#{cur_mem["fqdn"]}_#{cur_mem["jetty_port"]}" --member "#{cur_mem_ip}:#{cur_mem["jetty_port"]}" --member_priority #{my_pri}}

end # new_csv_array_of_hashes loop

# ruby -W0 phl3_ltm_pool_filler.rb --bigip_conn_conf "..\private-fixtures\config-andy-qa-gtm-ve.yml" -b 192.168.106.x -c "../private-fixtures/phl3-pools.csv"
