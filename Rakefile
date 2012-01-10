#!/usr/bin/env rake

require 'fileutils'

desc "Install this tool to /usr/local/bin"
task :install do
  p FileUtils.ln_sf(File.expand_path("./storage_client.rb"), "/usr/local/bin/storage-client", :verbose => true)
end
