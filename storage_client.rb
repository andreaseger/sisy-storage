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

  options[:mount_point] = nil
  opts.on( "-mp", "--mountpoint", "Mount Point.") do |opt|
    options[:mount_point] = opt
  end

  options[:unmount] = false
  opts.on( "-u", "--unmount", "Unmount a container") do |opt|
    options[:unmount] = true
  end

  options[:create] = false
  opts.on( "-c", "--create PATH", "create Volume") do |opt|
    options[:create] = opt
  end

  options[:size] = nil
  opts.on( "-s", "--size SIZE", "Size of the volume to create in MB") do |opt|
    options[:size] = opt
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

  options[:automount] = false
  opts.on( "-a", "--automount", "Enable automount.") do |opt|
    options[:automount] = true
  end
  options[:dry] = true
  opts.on( "-y", "--dry", "Dry-Run. dont really mount/unmount the container") do |opt|
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
require 'digest/sha1'

CONFIG = YAML.load_file("container.yml")
out = if options[:automount] then File.new('storage_client.log','a') else STDOUT end


def get_container_info
  if options[:automount] && options[:device] && !options[:label].empty?
    mountpoint = `mount | grep #{options[:device]}`.match(/.*on\s(\S*)\s.*/)[1]
    uuid = `blkid | grep #{options[:device]}`.match(/UUID=\"(.+)\" \S/)[1]
    container_options = CONFIG[:usb_drive][uuid]
    OpenStruct.new({ path: "#{mountpoint}/#{container_options.rel_path}", mount_point: container_options[:mount_point] }) if container_options
  elsif options[:dropbox] && options[:mount_point]
    OpenStruct.new({ path: File.expand_path(options[:dropbox]), mount_point: options[:mount_point] })
  else
    nil
  end
end


container = get_container_info
if options[:create] && options[:size]
  path = File.expand_path options[:create]
  if File.file? path
    out.puts "A file named #{path} already exits"
    out.close
    exit!
  end
  responds = KeyClient.get(CONFIG.key_server[:ip], CONFIG.key_server[:post], {opcode: 2, keyid: Digest::SHA1.hexdigest(File.basename(path)) } )
  if responds['success']
    out.puts Truecrypt.create(path, response['payload'], options[:size], options[:dry])
  else
    out.puts "Something when wrong: #{response['payload']}"
  end
elsif options[:mount] && !options[:unmount]
  responds = KeyClient.get(CONFIG[:key_server][:ip],CONFIG[:key_server][:post], {opcode: 1, keyid: Digest::SHA1.hexdigest(File.basename(container.path)) } )
  if responds['success']
    out.puts Truecrypt.mount(container.path, responds['payload'], container.mount_point, options[:dry])
  else
    out.puts "Something when wrong: #{response['payload']}"
  end
elsif options[:unmount] && !options[:mount]
  out.puts Truecrypt.unmount(container.path, options[:dry])
end


out.close
exit!
#out.puts "container: #{container.inspect}"
#out.puts "label: #{options[:label].inspect}"
#out.puts "device: #{options[:device]}"
#out.puts "UUID: #{uuid}" if uuid
#out.puts "Mount Point: #{mountpoint}" if mountpoint
#if container.nil?
#  out.puts "cant find container"
#  out.close
#  exit!
#end
