class Truecrypt
  def self.mount(container, password, mountpoint )
    `sudo truecrypt -t --mount #{container} --password #{password} #{mountpoint}`
  end

  def self.unmount(container)
    `sudo trucrypt -d #{container}`
  end
end

