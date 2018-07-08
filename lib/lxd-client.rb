require "lxd-client/version"

require "lxd-client/response"
require "lxd-client/error"
require "lxd-client/service"

module LxdClient
  # Your code goes here...
  def self.root
    File.dirname(__dir__)
  end
end
