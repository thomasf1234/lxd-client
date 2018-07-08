require 'json'

module LxdClient
  class Response
    SUCCESSFUL_HTTP_RESPONSE_CODES = ['200', '201', '202']
    ERROR_HTTP_RESPONSE_CODES = ['400', '401', '403', '404', '409', '412', '500']

    module Types
      SYNC = 'sync'
      ASYNC = 'async'
    end

    attr_reader :code, :body

    def initialize(response_code, response_body)
      @code = response_code
      @body = JSON.parse(response_body)
    end

    def sync?
      body["type"] == Types::SYNC
    end

    def async?
      body["type"] == Types::ASYNC
    end

    def success?
      SUCCESSFUL_HTTP_RESPONSE_CODES.include?(code)
    end

    def error?
      ERROR_HTTP_RESPONSE_CODES.include?(code)
    end
  end
end