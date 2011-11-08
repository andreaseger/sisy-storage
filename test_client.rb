require './lib/key_client'

server = KeyClient.new('127.0.0.1', 56789)
p server.ask({question: "test foo"})

