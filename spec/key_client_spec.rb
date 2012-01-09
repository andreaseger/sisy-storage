#!/usr/bin/env ruby

require_relative 'spec_helper'
require_relative "../lib/key_client"

describe KeyClient do
  let(:host) { '192.168.178.21' }
  let(:port) { 1337 }
  let(:keyid) { 'foobar' }

  it 'should be able to access the key_server' do
    KeyClient.get(host, port, { opcode: 1, keyid: keyid }).should_not be_nil
  end

  context '#create' do
    after do
      KeyClient.get(host, port, { opcode: 3, keyid: keyid})
    end
    #create
    it 'should be able to create a new key' do
      KeyClient.get(host, port, { opcode: 2, keyid: keyid})['success'].should be_true
    end
    it 'should return a 64 character long passphrase on create' do
      KeyClient.get(host, port, { opcode: 2, keyid: keyid})['payload'].should have(64).characters
    end
    it 'should not be able to create a passphrase for an existing key' do
      KeyClient.get(host, port, { opcode: 2, keyid: keyid})['success']
      KeyClient.get(host, port, { opcode: 2, keyid: keyid})['success'].should be_false
    end

    #read
    it 'should receive the passphrase from an existing key' do
      KeyClient.get(host, port, { opcode: 2, keyid: keyid})
      KeyClient.get(host, port, { opcode: 1, keyid: keyid})['success'].should be_true
    end
    it 'should not receive a passphrase from a non existing key' do
      KeyClient.get(host, port, { opcode: 1, keyid: keyid})['success'].should be_false
    end
    it 'should receive the same passphrase as on the earlier creation for a key' do
      pass = KeyClient.get(host, port, { opcode: 2, keyid: keyid})['payload']
      KeyClient.get(host, port, { opcode: 1, keyid: keyid})['payload'].should eq(pass)
    end

    #delete
    it 'should be able to delete a existing key' do
      KeyClient.get(host, port, { opcode: 2, keyid: keyid})
      KeyClient.get(host, port, { opcode: 3, keyid: keyid})['success'].should be_true
    end
    it 'should fail reading a deleted key' do
      KeyClient.get(host, port, { opcode: 2, keyid: keyid})
      KeyClient.get(host, port, { opcode: 3, keyid: keyid})
      KeyClient.get(host, port, { opcode: 1, keyid: keyid})['success'].should be_false
    end
  end

  #wrapper methods
  it 'should be able to create a key (via wrapper)' do
    KeyClient.expects(:get).with(host, port, { opcode: 2, keyid: keyid})
    KeyClient.create(host, port, keyid)
  end
  it 'should be able to read a key (via wrapper)' do
    KeyClient.expects(:get).with(host, port, { opcode: 1, keyid: keyid})
    KeyClient.read(host, port, keyid)
  end
  it 'should be able to delete a key (via wrapper)' do
    KeyClient.expects(:get).with(host, port, { opcode: 3, keyid: keyid})
    KeyClient.delete(host, port, keyid)
  end
end
