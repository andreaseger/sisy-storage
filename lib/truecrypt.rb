class Truecrypt
  def self.mount(container, password, mountpoint, test_drive=false )
    cmd = "sudo truecrypt -t --mount #{container} --password #{password} #{mountpoint}"
    if test_drive
      p cmd
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

