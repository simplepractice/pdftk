require "active_support"
require "active_support/core_ext/enumerable"
require "erb"
require "subprocess"
require "tempfile"

require "pdftk/pdf"
require "pdftk/field"

module Pdftk
  class Error < StandardError
  end
end
