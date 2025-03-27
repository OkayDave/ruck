# frozen_string_literal: true

require_relative "ruck/version"
require_relative "ruck/struct_generator"

module Ruck
  class Error < StandardError; end

  class << self
    def new(data)
      StructGenerator.generate(data)
    end
  end
end
