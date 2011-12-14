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

  options[:dry] = true
  opts.on( "-y", "--dry", "Dry-Run. dont realy mount/unmount the container") do |opt|
    options[:dry] = true
  end

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
require 'yaml'

CONTAINER_CONFIG = OpenStruct.new(YAML.load_file("container.yml"))
out = File.new('storage_client.log','a')

container = nil

if options[:device]
  if options[:label].empty?
    out.close
    exit!
  end
  mountpoint = `mount | grep #{options[:device]}`.match(/.*on\s(\S*)\s.*/)[1]
  uuid = `blkid | grep #{options[:device]}`.match(/UUID=\"(.+)\" \S/)[1]
  container = CONTAINER_CONFIG.usb_drive.reduce({}){|a,e| a[e[:uuid]] = OpenStruct.new(e); a}[uuid]
  container.path = "#{mountpoint}/#{container.rel_path}" if container
  container.key = container.uuid if container
end

if options[:dropbox]
  container = CONTAINER_CONFIG.dropbox.reduce({}){|a,e| a[e[:uuid]] = OpenStruct.new(e); a}[uuid]
  require 'digest/sha1'
  container.key = Digest::SHA1.hexdigest container.path if container
end

out.puts "container: #{container.inspect}"
out.puts "label: #{options[:label].inspect}"
out.puts "device: #{options[:device]}"
out.puts "UUID: #{uuid}" if uuid
out.puts "Mount Point: #{mountpoint}" if mountpoint
if container.nil?
  out.puts "cant find container"
  out.close
  exit!
end

out.puts "Container: #{container.desc}"

if options[:unmount] && !options[:mount]
  out.puts Truecrypt.unmount(container.path, options[:dry])
elsif !options[:unmount] && options[:mount]
  server = KeyClient.new(CONTAINER_CONFIG.key_server[:ip],CONTAINER_CONFIG.key_server[:post])
  responds = server.ask( {opcode: 1, keyid: container.key } )
  if responds['success']
    out.puts Truecrypt.mount(container.path, key['payload'], container.mount_point, options[:dry])
  end
else
  out.puts "choose mount OR unmount"
end
