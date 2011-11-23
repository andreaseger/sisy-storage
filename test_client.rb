require './lib/key_client'
require './lib/truecrypt'


host = ARGV[0] || "127.0.0.1"
port = 1337

p "  # connecting to #{host}:#{port}"
server = KeyClient.new(host,port)

p '  # create key'
p key = server.ask({opcode: 2, keyid: "Omnonnom"})

if key['success']
  p '  # new key'
  p key['payload']
end

p '### get a key'
p key = server.ask({opcode: 1, keyid: "Omnonnom"})

if key['success']
  p '### mount truecrypt - test_drive'
  Truecrypt.mount('/media/stick/container.tc', key["payload"],'$HOME/secure/stick',true)
  p '### unmount'
  Truecrypt.unmount('/media/stick/container.tc',true)
end

p '### get a not existing key'
p server.ask({opcode: 1, keyid: "wohooo"})

p '### delete key'
p server.ask({opcode: 3, keyid: "Omnonnom"})

p '### get a not existing key'
p server.ask({opcode: 1, keyid: "Omnonnom"})

# answers
# { success: true, payload: key|error_message }
