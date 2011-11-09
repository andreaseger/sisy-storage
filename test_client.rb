require './lib/key_client'


host = ARGV[0]
port = ARGV[1].to_i

p "connecting to #{host}:#{port}"
server = KeyClient.new(host,port)

p 'create key'
p server.ask({opcode: 2, keyid: "Omnonnom", key: "oldsanfo3ih342f"})

p 'get a key'
p server.ask({opcode: 1, keyid: "Omnomnom"})

p 'delete key'
p server.ask({opcode: 3, keyid: "Omnonnom"})


# answers
# { success: true, payload: key|error_message }
