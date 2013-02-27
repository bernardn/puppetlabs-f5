require 'puppet/provider/f5'

Puppet::Type.type(:f5_partition).provide(:f5_partition, :parent => Puppet::Provider::F5) do
  @doc = "Manages f5 partitions."

  confine :feature => :posix
  defaultfor :feature => :posix

  def self.wsdl
    'Management.Partition'
  end

  def wsdl
    self.class.wsdl
  end

  def self.instances
    transport[wsdl].get_partition_list.collect do |partition|
      new(:name => partition.partition_name, :description => partition.description)
    end
  end

  def description
    Puppet.debug("Puppet::Provider::F5_partition: retrieving description for #{resource[:name]}")
    transport[wsdl].get_partition_list.collect do |partition|
      if partition.partition_name == resource[:name]
        return partition.description
      end
    end
  end

  def description=(value)
    ### No mean provided by iControl for changing partition description (as in 11.0)
    value
  end
  
  def create
    Puppet.debug("Puppet::Provider::F5_partition: creating F5 partition #{resource[:name]}")
    transport[wsdl].create_partition([{:partition_name => resource[:name], :description => resource[:description]}])
  end

  def destroy
    Puppet.debug("Puppet::Provider::F5_Pool: destroying F5 partition #{resource[:name]}")
    transport[wsdl].delete_partition([resource[:name]])
  end

  def exists?
    partitions=transport[wsdl].get_partition_list.collect { |p| p.partition_name }
    r=partitions.include?(resource[:name])
    Puppet.debug("Puppet::Provider::F5_Pool: Does F5 partition #{resource[:name]} exist ? #{r}")
    r
    end
end
