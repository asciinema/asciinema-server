class Theme < Struct.new(:name, :label)

  AVAILABLE = {
    'seti' => 'Seti',
    'tango' => 'Tango',
    'solarized-dark' => 'Solarized Dark',
    'solarized-light' => 'Solarized Light',
  }

  DEFAULT = 'tango'

  def self.default
    new(DEFAULT, AVAILABLE[DEFAULT])
  end

  def self.for_name(name)
    new(name, AVAILABLE[name])
  end

end
