require 'socket'
require 'openssl'
require 'json'

class KeyClient
  def initialize(host,port)
    @host = host
    @port = port
  end

  def ask(data)
    ssl_context = OpenSSL::SSL::SSLContext.new()
    ssl_context.cert = OpenSSL::X509::Certificate.new(File.open("x509/client.crt"))
    ssl_context.key = OpenSSL::PKey::RSA.new(File.open("x509/client.key"))

    socket = TCPSocket.open(@host, @port)
    ssl = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl.sync_close = true
    ssl.connect

    p "Certificate verified" if ssl.peer_cert.verify(OpenSSL::X509::Certificate.new(File.open("x509/cacert.pem")).public_key)

    begin
      ssl.puts(data.to_json)
      JSON.parse(ssl.gets)
    rescue
      $stderr.puts "Error from client: #{$!}"
    end
  end
end


