Puppet::Type.newtype(:f5_partition) do
  @doc = "Manage F5 partitions."

  apply_to_device

  ensurable do
    desc "F5 partition resource state. Valid values are present, absent."

    defaultto(:present)

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end
  end

  newparam(:name, :namevar=>true) do
    desc "The partition name. v9.0 API uses IP addresses, v11.0 API uses names."
    newvalues(/^[[:alpha:][:digit:]\._\-]+$/)
  end

  newproperty(:description) do
    desc "The partition description"
  end
end
