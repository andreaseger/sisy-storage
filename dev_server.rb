require "socket"
require "openssl"
require "thread"
require 'json'

require 'pry'

listeningPort = Integer(ARGV[0])

store = OpenSSL::X509::Store.new
store.add_cert(OpenSSL::X509::Certificate.new(File.open("x509/cacert.pem")))
store.purpose = OpenSSL::X509::PURPOSE_SSL_CLIENT

sslContext = OpenSSL::SSL::SSLContext.new
sslContext.cert = OpenSSL::X509::Certificate.new(File.open("x509/server.crt"))
sslContext.key = OpenSSL::PKey::RSA.new(File.open("x509/server.key"))
sslContext.verify_mode = OpenSSL::SSL::VERIFY_PEER|OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
sslContext.cert_store = store

server = TCPServer.new(listeningPort)
ssl = OpenSSL::SSL::SSLServer.new(server, sslContext)

puts "Listening on port #{listeningPort}"

loop do
  Thread.new(ssl.accept) do |conn|
    p "Connected to #{conn.peeraddr.last}"
    p "Certificate verified" if conn.peer_cert.verify(OpenSSL::X509::Certificate.new(File.open("x509/cacert.pem")).public_key)

    begin
      while request = conn.gets
        $stdout.puts "=> " + request
        response = JSON.parse(request)
        response[:answer] = "here's your key"
        response[:time] = Time.now
        $stdout.puts "<= " + response.to_json
        conn.puts response.to_json
      end
    rescue
      $stderr.puts $!
    end
  end
end
