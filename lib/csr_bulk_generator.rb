# this is our main file

require 'yaml'
require 'ostruct'
require 'optparse'
require 'pp'

class Optparser
  def self.parse(args)
    options = OpenStruct.new

    opts = OptionParser.new do |opts|
      
      opts.banner = "Usage: csr_bulk_generator.rb [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      
      opts.on( "-b", "--bigip IP", "BigIP IP address") do |bip|
        options.bigip = bip
      end
      opts.on( "-f", "--config Config File", "YAML config file") do |file|
        options.csrconf = file || "../private-fixtures/fqdns_for_csrs.yml"
      end
      
      opts.on( "-u", "--bigip-user", "BigIP User name") do |username|
        options.bipuser = username
      end
      opts.on( "-p", "--bigip-pass", "Users Password") do |pass|
        options.bippass = pass
      end
      opts.on( "-o", "--output-dir", "Output Directory") do |odir|
        options.outputdir = odir || "."
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
REQ_PARAMS = [:csrconf, :bigip, :bipuser, :bippass]
REQ_PARAMS.find do |p|
  Kernel.abort "Missing Argument: #{p}" unless options.respond_to?(p)
end

# read list of FQDNs into an open struct (ostruct probably overkill here)
#csr_conf = OpenStruct.new(YAML.load_file(options.csrconf))
fqdns_file = File.open(options.csrconf, "r")



  ### creating csr
fqdns_file.each do |cur_fqdn|
  pp "creating csr #{cur_fqdn.tr("\n","")}..."
  
  output = %x{ruby ssl-key-and-csr-creator.rb --bigip-address #{options.bigip} --bigip-user #{options.bipuser} --bigip-pass #{options.bippass} --key-bit-length 2048 --common-name #{cur_fqdn} --country "US" --state "Washington" --locality "Seattle" --organization "thePlatform for Media, Inc" --division "Network Operations" --csr-output --output-dir #{options.outputdir} }
end