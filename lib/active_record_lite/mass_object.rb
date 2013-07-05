class MassObject

  def self.set_attrs(*attributes)
    @attributes = []
    attributes.each do |attribute|
      attr_accessor(attribute)
      @attributes << attribute
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map { |result| self.new(result)}
  end

  def initialize(params = {})
    params.each do |key, value|
      if self.class.attributes.include?(key.to_sym)
        self.send("#{key}=", value)
      else
        raise "mass assignment to unregistered attribute #{key}"
      end
    end
  end

end

