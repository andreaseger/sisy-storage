class Truecrypt
  def self.mount(container, password, mountpoint, test_drive=false )
    cmd = "echo #{password} | sudo truecrypt -t --mount #{container} #{mountpoint}"
    if test_drive
      p "sudo truecrypt -t --mount #{container} #{mountpoint}"
    else
      system cmd
    end
  end

  def self.unmount(container, test_drive=false )
    cmd = "sudo trucrypt -d #{container}"
    if test_drive
      p cmd
    else
      system cmd
    end
  end
end

