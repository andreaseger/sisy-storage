require 'socket'
require 'openssl'
require 'json'

CA=<<-EOF
-----BEGIN CERTIFICATE-----
MIIC2jCCAkOgAwIBAgIJAMqJDkmDMog8MA0GCSqGSIb3DQEBBQUAMDgxCzAJBgNV
BAYTAlVTMRMwEQYDVQQIDApOZXcgSmVyc2V5MRQwEgYDVQQKDAtsb2NhbGRvbWFp
bjAeFw0xMTExMDkxMTAwNTJaFw0yMTExMDYxMTAwNTJaMDgxCzAJBgNVBAYTAlVT
MRMwEQYDVQQIDApOZXcgSmVyc2V5MRQwEgYDVQQKDAtsb2NhbGRvbWFpbjCBnzAN
BgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAs1sDK1+C7L5uFx+4+/e46gKvzdb3E2XV
5DEEgMuRJV5rIBE7MNsbqLHgNfYBhIcCE5pDfS7rn+cS2UizAj6t5ogbey829RvD
++9eKkDFfUybcxEFfwYShgMD6ClzIbUtZYAFFT77OIYNQBwQF12XFrHKOXvTq9vg
4j80FvmiPpMCAwEAAaOB6zCB6DAdBgNVHQ4EFgQUGF+CRNxUmIHZ1rLz57NUx5Ww
ITowDAYDVR0TBAUwAwEB/zALBgNVHQ8EBAMCAQYwEQYJYIZIAYb4QgEBBAQDAgIE
MC8GCWCGSAGG+EIBDQQiFiBPcGVuU1NMIEdlbmVyYXRlZCBDQSBDZXJ0aWZpY2F0
ZTBoBgNVHSMEYTBfgBQYX4JE3FSYgdnWsvPns1THlbAhOqE8pDowODELMAkGA1UE
BhMCVVMxEzARBgNVBAgMCk5ldyBKZXJzZXkxFDASBgNVBAoMC2xvY2FsZG9tYWlu
ggkAyokOSYMyiDwwDQYJKoZIhvcNAQEFBQADgYEAplsSHRartHnCHU0zWh4zLhT4
crMBMnlutX3DoSPiQJfbvY40psXaOewwd0du6tv+WN8atFyyF+OGmQIb1/rlpG89
NQPsfVgtGwxq80qFx50O1ZTYJ8V3W/66UAAAd4xtb/kL/LKVYEXuTlh03WkAF5CL
hnIFgWCWL20vl9JOaIo=
-----END CERTIFICATE-----
EOF



class KeyClient
  def self.get(host, port, data, cert='x509/client.crt', cert_key='x509/client.key')
    ssl_context = OpenSSL::SSL::SSLContext.new()
    ssl_context.cert = OpenSSL::X509::Certificate.new(File.open(cert))
    ssl_context.key = OpenSSL::PKey::RSA.new(File.open(cert_key))

    socket = TCPSocket.open(host, port)
    ssl = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl.sync_close = true
    ssl.connect

    $stderr.puts "Certificate not_verified" and return nil unless ssl.peer_cert.verify(OpenSSL::X509::Certificate.new(CA).public_key)

    begin
      ssl.puts(data.to_json)
      JSON.parse(ssl.gets)
    rescue
      $stderr.puts "Error from client: #{$!}" and return nil
    end
  end
  def self.read(host,port,keyid)
    get(host,port,{opcode: 1, keyid: keyid})
  end
  def self.delete(host,port,keyid)
    get(host,port,{opcode: 3, keyid: keyid})
  end
  def self.create(host,port,keyid)
    get(host,port,{opcode: 2, keyid: keyid})
  end
end
