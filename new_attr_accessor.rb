class Object

  def self.new_attr_accessor(*args)
    args.each do |arg|
      define_method(arg) do
        instance_variable_get("@#{arg}")
      end

      define_method("#{arg}=".to_sym) do |value|
        instance_variable_set("@#{arg}", value)
      end
    end

  end

end

class Animal

  new_attr_accessor(:name, :type)

  def initialize

  end

end