#!/usr/bin/env ruby

require 'optparse'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: do_stuff.rb [options] "

  options[:volume] = nil
  opts.on( "-v", "--volume NAME", "Mount a truecrypt volume. select by path") do |opt|
    options[:volume] = opt
  end

  options[:mount] = false
  opts.on( "-m", "--mount", "Mount a container") do |opt|
    options[:mount] = true
  end

  options[:mount_point] = nil
  opts.on( "-M", "--mountpoint MOUNTPOINT", "Mount Point") do |opt|
    options[:mount_point] = opt
  end

  options[:unmount] = false
  opts.on( "-u", "--unmount", "Unmount a container") do |opt|
    options[:unmount] = true
  end

  options[:create] = false
  opts.on( "-c", "--create PATH", "Create Volume") do |opt|
    options[:create] = opt
  end
  options[:change] = false
  opts.on( "-C", "--change PATH", "Change the password to a new one.") do |opt|
    options[:change] = opt
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

  options[:init_usb] = false
  opts.on( "-i", "--init-usb","Initialize a automount usb stick.(creates a new volume)") do |opt|
    options[:init_usb] = true
  end
  options[:automount] = false
  opts.on( "-a", "--automount", "Enable automount.") do |opt|
    options[:automount] = true
  end
  options[:dry] = false
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
require 'yaml'
require 'digest/sha1'

CONFIG = YAML.load_file("container.yml")
@out = if options[:automount] then File.new('storage_client.log','a') else STDOUT end

def get_mountpoint(device)
  `mount | grep #{device}`.match(/.*on\s(\S*)\s.*/)[1]
end
def get_uuid(device)
  `sudo blkid | grep #{device}`.match(/UUID="(\S+)" \S/)[1]
end

def get_container_info(options)
  if options[:automount] && options[:device] && !options[:label].empty?
    mountpoint = get_mountpoint options[:device]
    uuid = get_uuid options[:device]
    container_options = CONFIG['usb_drive'][uuid]
    OpenStruct.new({ path: "#{mountpoint}/#{container_options['rel_path']}", mount_point: container_options['mount_point'] }) if container_options
  elsif options[:volume]
    OpenStruct.new({ path: File.expand_path(options[:volume]), mount_point: options[:mount_point] })
  else
    nil
  end
end

if options[:init_usb]
  if options[:device] && options[:volume] && options[:mount_point] && options[:size]
    mountpoint = get_mountpoint options[:device]
    uuid = get_uuid options[:device]

    path = "#{mountpoint}/#{options[:volume]}"
    responds = KeyClient.create(CONFIG['key_server']['ip'], CONFIG['key_server']['port'], Digest::SHA1.hexdigest(File.basename(path)) )
    if responds['success']
      @out.puts Truecrypt.create(path, responds['payload'], options[:size], options[:dry])
      File.open("container.yml", "a") do |io|
        io.puts "  \"#{uuid}\":"
        io.puts "    rel_path: #{options[:volume]}"
        io.puts "    mount_point: #{options[:mount_point]}"
      end
    else
      @out.puts "Something when wrong: #{responds['payload']}"
    end
  else
    @out.puts optparse
  end
  @out.close
  exit!
end

container = get_container_info(options)
if options[:create] && options[:size]
  path = File.expand_path options[:create]
  if File.file? path
    @out.puts "A file named #{path} already exits."
    @out.puts optparse
    @out.close
    exit!
  end
  responds = KeyClient.create(CONFIG['key_server']['ip'], CONFIG['key_server']['port'], Digest::SHA1.hexdigest(File.basename(path)) )
  if responds['success']
    @out.puts Truecrypt.create(path, responds['payload'], options[:size], options[:dry])
  else
    @out.puts "Something when wrong: #{responds['payload']}"
  end
elsif options[:change]
  path = File.expand_path options[:change]
  unless File.file? path
    @out.puts "A file named #{path} does not exist. Try to create one with --create."
    @out.puts optparse
    @out.close
    exit!
  end
  responds = KeyClient.read(CONFIG['key_server']['ip'],CONFIG['key_server']['port'], Digest::SHA1.hexdigest(File.basename(path)) )
  if responds['success']
    old_passphrase = responds['payload']
    responds = KeyClient.delete(CONFIG['key_server']['ip'],CONFIG['key_server']['port'], Digest::SHA1.hexdigest(File.basename(path)) )
    if responds['success']
      responds = KeyClient.create(CONFIG['key_server']['ip'], CONFIG['key_server']['port'], Digest::SHA1.hexdigest(File.basename(path)) )
      if responds['success']
        @out.puts Truecrypt.change(path, old_passphrase, responds['payload'], options[:dry])
      else
        @out.puts "Something when wrong: #{responds['payload']}"
      end
    end
  end
elsif options[:mount] && !options[:unmount]
  if container.nil? || container.mount_point.nil?
    @out.close
    exit!
  end
  responds = KeyClient.read(CONFIG['key_server']['ip'],CONFIG['key_server']['port'], Digest::SHA1.hexdigest(File.basename(container.path)) )
  if responds['success']
    @out.puts Truecrypt.mount(container.path, responds['payload'], container.mount_point, options[:dry])
  else
    @out.puts "Something when wrong: #{responds['payload']}"
  end
elsif options[:unmount] && !options[:mount]
  @out.puts Truecrypt.unmount(container.path, options[:dry])
else
  @out.puts optparse
end


@out.close
exit!
