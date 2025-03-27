# Ruckt

[![Gem Version](https://badge.fury.io/rb/ruck.svg)](https://badge.fury.io/rb/ruck)
[![RSpec](https://github.com/OkayDave/ruck/actions/workflows/rspec.yml/badge.svg)](https://github.com/OkayDave/ruck/actions/workflows/rspec.yml)
[![Coverage Status](https://coveralls.io/repos/github/dave/ruck/badge.svg?branch=main)](https://coveralls.io/github/dave/ruck?branch=main)

A flexible, type-safe struct generator for Ruby that automatically infers and creates Ruby Struct-like classes from arbitrary data sources with runtime type validation.

## Why Ruckt?

Ruckt combines the flexibility of Ruby's OpenStruct with the explicit structure and performance benefits of native Struct, giving you auto-generated, type-safe data objects directly from your hashes and JSON payloads. Unlike OpenStruct, Ruckt enforces attribute types for safety, and unlike traditional Struct, it dynamically adapts to nested data structures without manual boilerplate. 

## Features

- Dynamic Struct Generation: Classes auto-created from hashes/data samples
- Type Safety: Runtime type validation for all attributes
- Nested Structures: Automatic handling of nested hashes
- Query Methods: Automatic boolean attribute methods (e.g., `active?`)
- Clear Error Messages: Descriptive errors for type mismatches

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruckt'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install ruckt
```

## Usage

### Basic Example

```ruby
require 'ruckt'

# Create a struct from a hash
data = {
  name: "Dave",
  age: 40,
  active: true
}

user = Ruckt.new(data)

# Access attributes
user.name      # => "Dave"
user.age       # => 40
user.active?   # => true

# Set attributes
user.name = "John"  # => works fine
user.age = "forty"  # => raises TypeError
```

### Nested Structures

```ruby
data = {
  name: "Dave",
  location: {
    city: "Sheffield",
    postcode: "S2"
  }
}

person = Ruckt.new(data)

# Access nested attributes
person.location.city      # => "Sheffield"
person.location.postcode  # => "S2"

# Type validation works for nested structures too
person.location.city = 123  # => raises TypeError
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

Please ensure that any additions are fully covered by RSpec.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dave/ruck.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
