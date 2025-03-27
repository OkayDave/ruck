# frozen_string_literal: true

module Ruck
  # The StructGenerator class is responsible for dynamically creating struct-like classes
  # from hash data. It provides type safety and validation while maintaining a simple interface.
  class StructGenerator
    class << self
      # Generates a new struct-like class from a hash of data
      # @param data [Hash] The hash containing the data structure to model
      # @return [Class] A new class with typed attributes matching the data structure
      def generate(data)
        # If input isn't a hash, return it as-is (handles non-hash edge cases)
        return data unless data.is_a?(Hash)

        # Create a new anonymous class that will become our struct
        Class.new do
          # Include type validation functionality
          include TypeValidation

          # Store type information for all attributes
          # This will be used for validation when setting values
          @type_info = {}

          class << self
            # Make type information accessible to instances
            attr_reader :type_info

            # Determines the type of a value for validation purposes
            # @param value [Object] The value to infer the type from
            # @return [Class, Array<Class>] The inferred type(s)
            def infer_type(value)
              case value
              when Hash
                # Empty hashes stay as Hash, non-empty become nested structs
                value.empty? ? Hash : StructGenerator.generate(value)
              when TrueClass, FalseClass
                # Booleans can be either true or false, so we accept both types
                [TrueClass, FalseClass]
              else
                # For all other values, use their class as the type
                value.class
              end
            end
          end

          # Iterate through the data hash to define our struct's attributes
          data.each do |key, value|
            # Store the inferred type for this attribute
            @type_info[key] = infer_type(value)

            # Define a getter method that returns the instance variable
            define_method(key) do 
              instance_variable_get("@#{key}")
            end

            # Define a setter method with type validation
            define_method("#{key}=") do |val|
              # Special handling for nested hash updates
              if val.is_a?(Hash) && self.class.type_info[key].is_a?(Class) && 
                 self.class.type_info[key].respond_to?(:type_info)
                # Create a temporary instance to validate the nested data
                # This ensures all nested values have correct types
                temp_instance = self.class.type_info[key].new
                val.each do |k, v|
                  temp_instance.send("#{k}=", v)
                end
                instance_variable_set("@#{key}", temp_instance)
              else
                # For non-nested values, validate and set directly
                validate_type(key, val)
                instance_variable_set("@#{key}", val)
              end
            end
            
            # For boolean attributes, add a convenience query method
            # that ends with '?' (e.g., active?)
            if value.is_a?(TrueClass) || value.is_a?(FalseClass)
              define_method("#{key}?") { instance_variable_get("@#{key}") }
            end

            # For non-empty hashes, create a nested struct class
            if value.is_a?(Hash) && !value.empty?
              nested_class = StructGenerator.generate(value)
              const_set(key.to_s.capitalize, nested_class)
            end
          end

          # Define the initialize method that sets up a new instance
          define_method(:initialize) do |values = {}|
            values.each do |key, value|
              # Special handling for nested structs
              if self.class.type_info[key].is_a?(Class) && value.is_a?(Hash) &&
                 self.class.type_info[key].respond_to?(:type_info)
                instance_variable_set("@#{key}", self.class.type_info[key].new(value))
              else
                # For non-nested values, use the setter for validation
                send("#{key}=", value)
              end
            end
          end
        end
      end
    end

    # Module containing type validation functionality
    # This is mixed into generated struct classes
    module TypeValidation
      # Validates that a value matches the expected type for an attribute
      # @param key [Symbol] The attribute name
      # @param value [Object] The value to validate
      # @raise [TypeError] If the value doesn't match the expected type
      def validate_type(key, value)
        expected_type = self.class.type_info[key]
        
        # Handle cases where multiple types are allowed (e.g., true/false)
        if expected_type.is_a?(Array)
          return if expected_type.any? { |type| value.is_a?(type) }
          raise TypeError, "Expected #{key} to be one of #{expected_type.join(', ')}, got #{value.class}"
        end

        # Handle single type validation
        return if value.is_a?(expected_type)
        raise TypeError, "Expected #{key} to be #{expected_type}, got #{value.class}"
      end
    end
  end
end 