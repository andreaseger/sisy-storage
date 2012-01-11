#!/usr/bin/env ruby

require_relative 'spec_helper'
require_relative "../lib/key_client"
require 'fileutils'
require 'pry'

describe "CLI" do
  let(:host) { '192.168.178.21' }
  let(:port) { 1337 }
  let(:keyid) { 'nomnomnomnom' }
  let(:cmd) { 'ruby storage_client.rb' }
  let(:mountpoint) { File.expand_path('./tmp/mountpoint') }

  before(:each) do
    FileUtils.rm_f Dir.glob('./tmp/*.tc')
  end
  context 'loose volumes' do
    let(:test_file) { './tmp/reg_test_create.tc' }
    before do
      KeyClient.delete host, port, Digest::SHA1.hexdigest(File.basename(test_file))
    end
    context 'create' do
      it 'should create a new truecrypt container named accordingly' do
        `#{cmd} --create '#{test_file}' --size 5`
        File.file?(test_file).should be_true
      end
    end
    context 'mount' do
      let(:test_file) { './tmp/reg_test_mount.tc' }
      before do
        KeyClient.delete host, port, Digest::SHA1.hexdigest(File.basename(test_file))
        `#{cmd} --create '#{test_file}' --size 5`
      end
      it 'should be able to mount the given volume' do
        `#{cmd} --mount --volume '#{test_file}' --mountpoint '#{mountpoint}'`
        `truecrypt -t -l`.should_not match(/No volumes mounted/)
      end
      after do
        `truecrypt -t -d #{test_file}`
      end
    end
    context 'unmount' do
      let(:test_file) { './tmp/reg_test_unmount.tc' }
      before do
        KeyClient.delete host, port, Digest::SHA1.hexdigest(File.basename(test_file))
        `#{cmd} --create '#{test_file}' --size 5`
        `#{cmd} --mount --volume '#{test_file}' --mountpoint '#{mountpoint}'`
      end
      it 'should be able to unmount the given volume' do
        `#{cmd} --unmount --volume '#{test_file}'`
        `truecrypt -t -l`.should match(/No volumes mounted/)
      end
    end
    context 'change' do
      let(:test_file) { './tmp/reg_test_change.tc' }
      before do
        KeyClient.delete host, port, Digest::SHA1.hexdigest(File.basename(test_file))
        `#{cmd} --create '#{test_file}' --size 5`
      end
      it 'should be able to change the password of the given volume' do
        `#{cmd} --change '#{test_file}'`
      end
      after do
        `truecrypt -t -d #{test_file}`
      end
    end
  end
end
