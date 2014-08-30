# Remove this and replace with `JSON` after upgrading to Rails 4.2

class ActiveSupportJsonProxy

  def self.dump(object)
    ActiveSupport::JSON.encode(object) unless object.nil?
  end

  def self.load(string)
    ActiveSupport::JSON.decode(string) if string.present?
  end

end
