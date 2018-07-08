module LxdClient
  class Error < RuntimeError
    attr_reader :response

    def initialize(response)
      super("Received response with error_code #{response.body["error_code"]} : '#{response.body["error"]}'")
      @response = response
    end
  end
end