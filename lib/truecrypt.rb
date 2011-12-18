class Truecrypt

  def self.mount(container, password, mountpoint, test_drive=false )
    cmd = "echo #{password} | sudo truecrypt -t --mount #{container} #{mountpoint}"
    if test_drive
      p "sudo truecrypt -t --mount #{container} #{mountpoint}"
    else
      system cmd
    end
    #TODO return values about success
  end

  def self.unmount(container, test_drive=false )
    cmd = "sudo truecrypt --dismount #{container}"
    if test_drive
      p cmd
    else
      system cmd
    end
    #TODO return values about success
  end

  def self.create(location, key, size, test_drive=false)
    random_source
    cmd = "truecrypt -t --create '#{location}' --encryption=AES --filesystem=FAT --size=#{size*1024} --random-source=/tmp/random_source --volume-type=normal --hash=sha-512 --non-interactive -p '#{key}'"
    if test_drive
      p cmd
    else
      system cmd
    end
    #TODO return values about success
  end

private
  def self.random_source
    cmd = "cat /dev/urandom | tr -dc \"a-zA-Z0-9-_%^&*()_+{}|:<>?=\" | fold -w 4096 | head -n1 | echo > /tmp/random_source"
  end
end
