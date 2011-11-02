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

  options[:testing] = nil
  opts.on( "-t", "--testing DATA", "only used for testing") do |data|
    options[:testing] = data
  end


  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end


optparse.parse!
out = options[:output].nil? ? $stdout : File.new(options[:output],'a')

class Truecrypt
  def self.mount(container, password, mountpoint )
    `sudo truecrypt -t --mount #{container} --password #{password} #{mountpoint}`
  end

  def self.unmount(container)
    `sudo trucrypt -d #{container}`
  end
end

require 'socket'
require 'openssl'
require 'json'

class KeyServer
  def initialize(host,port)
    @host = host
    @port = port
  end

  def ask(data)
    socket = TCPSocket.open(@host, @port)
    ssl_context = OpenSSL::SSL::SSLContext.new()

    ssl_context.cert = OpenSSL::X509::Certificate.new(File.open("x509/client.crt"))
    ssl_context.key = OpenSSL::PKey::RSA.new(File.open("x509/client.key"))

    ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl_socket.sync_close = true
    ssl_socket.connect

    ssl_socket.puts(data.to_json)

    ssl_socket.gets
  end
end

if options[:testing]
  server = KeyServer.new('127.0.0.1', options[:testing].to_i)
  ans = server.ask({foo: 'bar', baz: 5})
  p JSON.parse(ans)
end


if options[:label]
  options[:mountpoint] = `mount | grep #{options[:device]}`.match(/.*on\s(\S*)\s.*/)[1]
  out.puts options.inspect

  out.puts
end
