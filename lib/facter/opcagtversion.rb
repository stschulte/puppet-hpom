Facter.add(:opcagtversion) do
  setcode do
    Facter::Util::Resolution.exec('/opt/OV/bin/OpC/opcagt')
  end
end
