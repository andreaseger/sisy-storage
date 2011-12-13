require 'optparse'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: do_stuff.rb [options] "

  options[:dropbox] = nil
  opts.on( "-d", "--dropbox NAME", "Mount a dropbox container. Select by Name configured in container.yml") do |opt|
    options[:dropbox] = opt
  end

  options[:mount] = false
  opts.on( "-m", "--mount", "mount a container") do |opt|
    options[:mount] = true
  end

  options[:unmount] = false
  opts.on( "-u", "--unmount", "Unmount a container") do |opt|
    options[:unmount] = true
  end

  options[:uuid] = nil
  opts.on( "-r", "--uuid UUID", "Mount Container on Device with the given UUID") do |opt|
    options[:uuid] = opt
  end

  options[:device] = nil
  opts.on( "-d", "--device DEVICE", "Container on DEVICE will be mounted") do |opt|
    options[:device] = opt
  end

  options[:label] = nil
  opts.on( "-l", "--label LABEL", "Device Label") do |opt|
    options[:label] = opt
  end

  options[:dry] = false
  opts.on( "-y", "--dry", "Dry-Run. dont realy mount/unmount the container") do |opt|
    options[:dry] = true
  end

#  options[:output] = nil
#  opts.on( '-o', '--output FILE', 'Write log to FILE' ) do |file|
#    options[:output] = file
#  end
#
#  options[:mountpoint] = nil
#  opts.on( "-m", "--mount-point MOUNT", "mount point directory (eg /media/cd)") do |mount|
#    options[:mountpoint] = mount unless mount.empty?
#  end
#
#  options[:device] = nil
#  opts.on( "-d", "--device-name DEVICE", "device name (eg /dev/sdd1)") do |device|
#    options[:device] = device unless device.empty?
#  end
#
#  options[:label] = nil
#  opts.on( "-l", "--label LABEL", "label of mounted volume") do |label|
#    options[:label] = label unless label.empty?
#  end
#
#  options[:host] = '127.0.0.1'
#  opts.on( "-h", "--host", "KeyServer Host. Default: 127.0.0.1") do |host|
#    options[:host] = host
#  end
#
#  options[:port] = 56789
#  opts.on( "-p", "--port", "KeyServer Port. Default: 56789") do |port|
#    options[:port] = port.to_i
#  end

  opts.on( '-?', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end


optparse.parse!

require './lib/truecrypt'
require './lib/key_client'
require 'ostruct'
require 'pry'

CONTAINER_CONFIG = OpenStruct.new(YAML.load_file("container.yml"))

container = nil


if options[:device]
  return 0 unless options[:label]
  mountpoint = `mount | grep #{options[:device]}`.match(/.*on\s(\S*)\s.*/)[1]
  uuid = `blkid | grep #{options[:device]}`.match(/UUID="(.+)"/)[1]
  container = CONTAINER_CONFIG.usb_drive.reduce({}){|a,e| a[e[:uuid]] = OpenStruct.new(e); a}[uuid]
  container.path = "#{mountpoint}/#{container.rel_path}"
end

if options[:dropbox]
  container = CONTAINER_CONFIG.dropbox.reduce({}){|a,e| a[e[:uuid]] = OpenStruct.new(e); a}[uuid]
end

raise "cant find container" if container = nil

p "Container: #{container.desc}"

if options[:unmount] && !options[:mount]
  p Truecrypt.unmount(container.path, options[:dry])
elsif !options[:unmount] && options[:mount]
  server = KeyClient.new(CONTAINER_CONFIG.key_server[:id],CONTAINER_CONFIG.key_server[:post])
  responds = server.ask( {opcode: 1, keyid: container.key } )
  if responds['success']
    p Truecrypt.mount(container.path, key['payload'], container.mount_point, options[:dry])
  end
else
  raise "choose mount OR unmount"
end
