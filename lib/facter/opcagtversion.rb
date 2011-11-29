Facter.add(:opcagtversion) do
  setcode do
    Facter::Util::Resolution.exec('/opt/OV/bin/opcagt -version')
  end
end
