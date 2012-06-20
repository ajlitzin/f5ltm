#!/usr/bin/env ruby
# vim:expandtab shiftwidth=2 softtabstop=2
# Andy Litzinger https://github.com/ajlitzin/f5ltm
# with code from Jos Backus http://www.catnook.com/

require 'rubygems'
require 'yaml'
require 'getoptions'

$: << File.join(ENV['HOME'], '/ops/lib') << '/cc/ops/lib'
require 'f5'

PROGNAME = File.basename($0)

def usage(msg=nil)
  Kernel.warn "#{PROGNAME}: #{msg}" if msg
  Kernel.abort "Usage: #{PROGNAME} [--config_file <filename>] <hostname> show|enable|disable <node> [...]"
end

opts = GetOptions.new(%w(config_file=s connect_timeout=i))

hostname, cmd, *nodes = ARGV

usage if nodes.empty?

options = {
  :config_file     => opts.config_file,
  :connect_timeout => opts.connect_timeout,
}

