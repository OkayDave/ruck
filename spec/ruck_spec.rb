# frozen_string_literal: true

# Required for testing Date/Time object handling
require "date"
require "time"

RSpec.describe Ruck do
  # Basic sanity check to ensure the gem has a version number
  it "has a version number" do
    expect(Ruck::VERSION).not_to be nil
  end

  describe ".new" do
    # Test basic functionality with simple data types
    context "with basic data (happy path)" do
      # Test data containing string, integer, and boolean values
      let(:data) { { name: "Dave", age: 40, active: true } }
      # Create a new struct class from the data
      let(:struct_class) { described_class.new(data) }
      # Create an instance of that struct class with the same data
      let(:instance) { struct_class.new(data) }

      # Verify that getter methods are created and return correct values
      it "creates accessor methods" do
        expect(instance.name).to eq("Dave")
        expect(instance.age).to eq(40)
        expect(instance.active).to be true
      end

      # Verify that setter methods work and update values
      it "creates setter methods" do
        instance.name = "John"
        expect(instance.name).to eq("John")
      end

      # Verify that boolean attributes get special '?' methods
      # and that these methods reflect changes to the underlying value
      it "creates query methods for boolean attributes" do
        expect(instance.active?).to be true
        instance.active = false
        expect(instance.active?).to be false
      end

      # Verify that type validation works when assigning wrong types
      it "validates types on assignment" do
        expect { instance.age = "forty" }.to raise_error(TypeError, /Expected age to be Integer, got String/)
      end

      # Verify that assigning values of the same type works
      it "allows assignment of same type" do
        expect { instance.age = 41 }.not_to raise_error
        expect(instance.age).to eq(41)
      end

      # Verify that subclasses of the original type are accepted
      # This is important for duck typing and inheritance
      it "allows assignment of subclasses" do
        special_string = Class.new(String).new("Special")
        expect { instance.name = special_string }.not_to raise_error
      end
    end

    # Test handling of nested data structures
    context "with nested structures (happy path)" do
      # Complex nested data structure with multiple levels
      let(:data) do
        {
          name: "Dave",
          location: { 
            city: "Sheffield",
            postcode: "S2",
            coords: {
              lat: 53.3811,
              lng: -1.4701
            }
          }
        }
      end
      let(:struct_class) { described_class.new(data) }
      let(:instance) { struct_class.new(data) }

      # Verify that first-level nested structures work
      it "creates nested structs" do
        expect(instance.location.city).to eq("Sheffield")
        expect(instance.location.postcode).to eq("S2")
      end

      # Verify that deeply nested structures (multiple levels) work
      it "handles deeply nested structs" do
        expect(instance.location.coords.lat).to eq(53.3811)
        expect(instance.location.coords.lng).to eq(-1.4701)
      end

      # Verify type validation works in nested structures
      it "validates types in nested structs" do
        expect { instance.location.city = 123 }.to raise_error(TypeError, /Expected city to be String, got Integer/)
      end

      # Verify that nested structures can be updated
      it "allows updating nested structs" do
        instance.location.city = "London"
        expect(instance.location.city).to eq("London")
      end
    end

    # Test array handling
    context "with arrays (happy path)" do
      # Data containing arrays of different types
      let(:data) do
        {
          name: "Dave",
          hobbies: ["coding", "reading"],
          scores: [1, 2, 3]
        }
      end
      let(:struct_class) { described_class.new(data) }
      let(:instance) { struct_class.new(data) }

      # Verify arrays are stored and retrieved correctly
      it "handles array attributes" do
        expect(instance.hobbies).to eq(["coding", "reading"])
        expect(instance.scores).to eq([1, 2, 3])
      end

      # Verify type validation for array attributes
      it "validates array type" do
        expect { instance.hobbies = "not an array" }.to raise_error(TypeError, /Expected hobbies to be Array, got String/)
      end

      # Verify that arrays can be modified in place
      it "allows modifying arrays" do
        instance.hobbies << "gaming"
        expect(instance.hobbies).to eq(["coding", "reading", "gaming"])
      end
    end

    # Test edge cases and error conditions
    context "with edge cases and sad paths" do
      # Verify handling of empty input
      it "handles empty hash" do
        struct_class = described_class.new({})
        instance = struct_class.new
        expect(instance).to be_a(struct_class)
      end

      # Verify that nil values are handled correctly and type-checked
      it "handles nil values" do
        struct_class = described_class.new({ name: nil })
        instance = struct_class.new(name: nil)
        expect(instance.name).to be_nil
        expect { instance.name = "Dave" }.to raise_error(TypeError, /Expected name to be NilClass, got String/)
      end

      # Verify that false boolean values work correctly
      it "handles boolean false values" do
        struct_class = described_class.new({ active: false })
        instance = struct_class.new(active: false)
        expect(instance.active).to be false
        expect(instance.active?).to be false
      end

      # Verify that missing initialization values default to nil
      it "handles missing keys on initialization" do
        struct_class = described_class.new({ name: "Dave", age: 40 })
        instance = struct_class.new(name: "Dave")
        expect(instance.age).to be_nil
      end

      # Verify that non-hash inputs are returned as-is
      it "rejects non-hash input" do
        expect(described_class.new("not a hash")).to eq("not a hash")
        expect(described_class.new(42)).to eq(42)
        expect(described_class.new(nil)).to be_nil
      end

      # Verify that empty nested hashes are handled correctly
      it "handles nested empty hashes" do
        struct_class = described_class.new({ config: {} })
        instance = struct_class.new(config: {})
        expect(instance.config).to eq({})
      end

      # Verify that both string and symbol keys work
      it "handles hashes with symbol and string keys" do
        struct_class = described_class.new({ "name" => "Dave", age: 40 })
        instance = struct_class.new("name" => "Dave", age: 40)
        expect(instance.name).to eq("Dave")
        expect(instance.age).to eq(40)
      end

      # Verify that nested data is validated when updating
      it "handles updating with invalid nested data" do
        struct_class = described_class.new({ location: { city: "Sheffield" } })
        instance = struct_class.new(location: { city: "Sheffield" })
        
        expect { 
          instance.location = { city: 123 } 
        }.to raise_error(TypeError, /Expected city to be String, got Integer/)
      end

      # Verify that nested structures can reference each other
      it "handles inheritance in nested structs" do
        parent_data = { name: "Parent" }
        child_data = { name: "Child", parent: parent_data }
        
        struct_class = described_class.new(child_data)
        instance = struct_class.new(child_data)
        
        expect(instance.name).to eq("Child")
        expect(instance.parent.name).to eq("Parent")
      end
    end

    # Test handling of Ruby standard library objects
    context "with special Ruby objects" do
      # Test data containing various Ruby standard library objects
      let(:data) do
        {
          date: Date.new(2024, 3, 26),
          time: Time.new(2024, 3, 26, 12, 0, 0),
          regexp: /test/,
          range: (1..10)
        }
      end
      let(:struct_class) { described_class.new(data) }
      let(:instance) { struct_class.new(data) }

      # Verify Date object handling and type validation
      it "handles Date objects" do
        expect(instance.date).to be_a(Date)
        expect { instance.date = Time.now }.to raise_error(TypeError)
      end

      # Verify Time object handling and type validation
      it "handles Time objects" do
        expect(instance.time).to be_a(Time)
        new_time = Time.new(2024, 3, 26, 13, 0, 0)
        expect { instance.time = new_time }.not_to raise_error
      end

      # Verify Regexp object handling and type validation
      it "handles Regexp objects" do
        expect(instance.regexp).to be_a(Regexp)
        expect { instance.regexp = "not a regexp" }.to raise_error(TypeError)
      end

      # Verify Range object handling and type validation
      it "handles Range objects" do
        expect(instance.range).to be_a(Range)
        expect { instance.range = (1...5) }.not_to raise_error
      end
    end
  end
end
