require 'optparse'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: do_stuff.rb [options] "

  options[:output] = nil
  opts.on( '-o', '--output FILE', 'Write log to FILE' ) do |file|
    options[:output] = file
  end

  options[:mountpoint] = nil
  opts.on( "-m", "--mount-point MOUNT", "mount point directory (eg /media/cd)") do |mount|
    options[:mountpoint] = mount unless mount.empty?
  end

  options[:device] = nil
  opts.on( "-d", "--device-name DEVICE", "device name (eg /dev/sdd1)") do |device|
    options[:device] = device unless device.empty?
  end

  options[:label] = nil
  opts.on( "-l", "--label LABEL", "label of mounted volume") do |label|
    options[:label] = label unless label.empty?
  end

  options[:host] = '127.0.0.1'
  opts.on( "-h", "--host", "KeyServer Host. Default: 127.0.0.1") do |host|
    options[:host] = host
  end

  options[:port] = 56789
  opts.on( "-p", "--port", "KeyServer Port. Default: 56789") do |port|
    options[:port] = port.to_i
  end

  opts.on( '-?', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end


optparse.parse!
out = options[:output].nil? ? $stdout : File.new(options[:output],'a')


require './lib/truecrypt'
require './lib/key_client'
require 'pry'


if options[:label]
  options[:mountpoint] = `mount | grep #{options[:device]}`.match(/.*on\s(\S*)\s.*/)[1]
  p uuid = `blkid | grep #{options[:device]}`.match(/UUID="(.+)"/)[1]
  out.puts options.inspect

  server = KeyClient.new(options[:host], options[:port])
  out.puts server.ask( {opcode: 1, keyid: [options[:device], options[:label], options[:mountpoint]].join(':') } )
end
