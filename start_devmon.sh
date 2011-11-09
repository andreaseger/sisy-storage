#!/bin/sh

devmon --no-mount --exec-on-drive "ruby /home/sch1zo/code/sisy_storage/storage_client.rb -m %d -d %f -l %l -o /home/sch1zo/code/sisy_storage/storage_client.log" > /dev/null &
