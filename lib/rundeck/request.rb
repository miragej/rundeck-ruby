require 'httparty'
require 'libxml'

module Rundeck
  # @private
  class Request
    include HTTParty
    format :xml
    headers 'Accept' => 'application/xml'

    attr_accessor :api_token

    def get(path, options = {})
      set_api_token_header(options)
      validate self.class.get(path, options)
    end

    def post(path, options = {})
      set_api_token_header(options, path)
      validate self.class.post(path, options)
    end

    def put(path, options = {})
      set_api_token_header(options)
      validate self.class.put(path, options)
    end

    def delete(path, options = {})
      set_api_token_header(options)
      validate self.class.delete(path, options)
    end

    # Checks the response code for common errors.
    # Returns parsed response for successful requests.
    def validate(response)
      case response.code
      when 400 then fail Error::BadRequest, error_message(response)
      when 401 then fail Error::Unauthorized, error_message(response)
      when 403 then fail Error::Forbidden, error_message(response)
      when 404 then fail Error::NotFound, error_message(response)
      when 405 then fail Error::MethodNotAllowed, error_message(response)
      when 409 then fail Error::Conflict, error_message(response)
      when 500 then fail Error::InternalServerError, error_message(response)
      when 502 then fail Error::BadGateway, error_message(response)
      when 503 then fail Error::ServiceUnavailable, error_message(response)
      end

      response.parsed_response
    end

    # Sets a base_uri and default_params for requests.
    # @raise [Error::MissingCredentials] if endpoint not set.
    def set_request_defaults(endpoint, api_token)
      unless endpoint
        fail Error::MissingCredentials, 'Please set an endpoint to API'
      end
      @api_token = api_token

      self.class.base_uri endpoint
      # self.class.default_params :sudo => sudo
      # self.class.default_params.delete(:sudo) if sudo.nil?
    end

    private

    # Sets a PRIVATE-TOKEN header for requests.
    # @raise [Error::MissingCredentials] if api_token not set.
    def set_api_token_header(options, path = nil)
      return nil if path == '/j_security_check'
      unless @api_token
        fail Error::MissingCredentials, 'Please set a api_token for user'
      end
      options[:headers] = {} if options[:headers].nil?
      options[:headers].merge!( 'X-Rundeck-Auth-Token' => @api_token )
    end

    def error_message(response)
      "Server responded with code #{response.code}, " \
      "message: #{response.parsed_response['result']['error'][1]['message']}. " \
      "Request URI: #{response.request.base_uri}#{response.request.path}"
    end
  end
end
