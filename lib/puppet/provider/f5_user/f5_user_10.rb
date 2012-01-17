require 'puppet/provider/f5'

Puppet::Type.type(:f5_user).provide(:f5_user_10, :parent => Puppet::Provider::F5) do
  @doc = "Manages F5 user"

  confine    :feature => :posix
  defaultfor :feature => :posix

  def self.wsdl
    'Management.UserManagement'
  end

  def wsdl
    self.class.wsdl
  end

  def self.instances
    Puppet.debug("Puppet::Provider::F5_User: instances")
    transport[wsdl].get_list.collect do |name|
      new(:name => name)
    end
  end

  def user_permission
    result = {}
    user_permission= transport[wsdl].get_user_permission(resource[:name]).first
    user_permission.each { |role|
      result["#{role.partition}"] = role.role
    }
    result
  end
  def user_permission=(value)
    # Updating user permissions doesn't work as expected. get_user_permission returns correctly the new values but there aren't effective (10.1.0 & 10.2.0). A ticket has been opened with F5.
    permission = []
    resource[:user_permission].keys.each do |part|
      permission.push({:role =>  resource[:user_permission][part], :partition => part})
    end
    value = transport[wsdl].send("set_user_permission", [resource[:name]], [permission]) unless permission.empty?
  end

  def password
    # Passing from a password (encrypted) to the same password (unencrypted) won't trigger changes as passwords are always stored in an encrypted form on the bigip. The only consequence is that the crypt salt will remain the same.
    Puppet.debug("Puppet::Provider::F5_User: retrieving encrypted_password for #{resource[:name]}")
    result = {}
    old_encrypted_password=transport[wsdl].get_encrypted_password(resource[:name]).first
    if resource[:password]['is_encrypted'] != true
      salt = old_encrypted_password.sub(/^(\$1\$\w+?\$).*$/, '\1')
      new_encrypted_password = resource[:password]['password'].crypt(salt)
    else
      new_encrypted_password = resource[:password]['password']
    end
    if new_encrypted_password == old_encrypted_password
      result['password']     = resource[:password]['password']
      result['is_encrypted'] = resource[:password]['is_encrypted']
    else
      result['password'] = old_encrypted_password
      result['is_encrypted'] = true
    end
    result
  end

  def password=(value)
    Puppet.debug("Puppet::Provider::F5_User: setting password for #{resource[:name]}")
    transport[wsdl].change_password_2([resource[:name]],[{ :password => resource[:password]['password'], :is_encrypted => resource[:password]['is_encrypted'] }])
  end
  
  
  methods = [
    'description',
    'fullname',
    'login_shell',
  ]

  methods.each do |method|
    define_method(method.to_sym) do
      if transport[wsdl].respond_to?("get_#{method}".to_sym)
        Puppet.debug("Puppet::Provider::F5_User: retrieving #{method} for #{resource[:name]}")
        transport[wsdl].send("get_#{method}", resource[:name]).first.to_s
      end
    end
  end

  methods.each do |method|
    define_method("#{method}=") do |value|
      if transport[wsdl].respond_to?("set_#{method}".to_sym)
        transport[wsdl].send("set_#{method}", resource[:name], resource[method.to_sym])
      end
    end
  end
  
  def create
    Puppet.debug("Puppet::Provider::F5_User: creating F5 user #{resource[:name]}")
    
    permission = []
    resource[:user_permission].keys.each do |part|
      permission.push({:role =>  resource[:user_permission][part], :partition => part})
    end
    
    user_info_3 = {
      :user           => { :name => resource[:name], :full_name => resource[:fullname]},
      :password       => { :password => resource[:password]['password'], :is_encrypted => resource[:password]['is_encrypted'] },
      :permissions    => permission,
      :login_shell    => resource[:login_shell],
    }
    
    transport[wsdl].create_user_3([user_info_3])
  end

  def destroy
    Puppet.debug("Puppet::Provider::F5_User: destroying F5 user #{resource[:name]}")
    transport[wsdl].delete_user(resource[:name])
  end

  def exists?
    r = false
    transport[wsdl].get_list.each do |u|
      if u.name == resource[:name]
        r = true
        break
      end
    end
    Puppet.debug("Puppet::Provider::F5_User: does F5 user #{resource[:name]} exist ? #{r}")
    r
  end
end