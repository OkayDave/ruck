# frozen_string_literal: true

require_relative "ruckt/version"
require_relative "ruckt/struct_generator"

module Ruckt
  class Error < StandardError; end

  class << self
    def new(data)
      StructGenerator.generate(data)
    end
  end
end 