require "socket"
require "openssl"
require "thread"

listeningPort = Integer(ARGV[0])

server = TCPServer.new(listeningPort)
sslContext = OpenSSL::SSL::SSLContext.new
sslContext.cert = OpenSSL::X509::Certificate.new(File.open("x509/server.crt"))
sslContext.key = OpenSSL::PKey::RSA.new(File.open("x509/server.key"))
sslServer = OpenSSL::SSL::SSLServer.new(server, sslContext)

puts "Listening on port #{listeningPort}"

loop do
  connection = sslServer.accept
  Thread.new {
    begin
      while (lineIn = connection.gets)
        lineIn = lineIn.chomp
        $stdout.puts "=> " + lineIn
        lineOut = "You said: " + lineIn
        $stdout.puts "<= " + lineOut
        connection.puts lineOut
      end
    rescue
      $stderr.puts $!
    end
  }
end
