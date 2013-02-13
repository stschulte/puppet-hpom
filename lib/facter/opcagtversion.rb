Facter.add(:opcagtversion) do
  setcode do
    Facter::Util::Resolution.exec('/opt/OV/bin/ovconfget eaagt OPC_INSTALLED_VERSION')
  end
end
