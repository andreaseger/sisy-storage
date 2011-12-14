#!/bin/sh

devmon --no-mount --exec-on-drive "ruby /home/sch1zo/code/sisy_storage/storage_client.rb -m -d %f -l %l" > /home/sch1zo/code/sisy_storage/devmon.log &
