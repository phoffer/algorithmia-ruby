require 'httparty'

module Algorithmia
  class Requester
    include HTTParty

    def initialize(client)
      self.class.base_uri client.api_address
      @client = client
      @default_headers = {
        'Content-Type' => 'application/json',
        'User-Agent' => 'Algorithmia Ruby Client'
      }
      unless @client.api_key.nil?
        @default_headers['Authorization'] = @client.api_key
      end
    end

    def get(endpoint, query: {}, headers: {})
      headers = merge_headers(headers)
      headers.delete('Content-Type')   # No content, can break request parsing
      response = self.class.get(endpoint, query: query, headers: headers)
      check_for_errors(response)
      response
    end

    def post(endpoint, body, query: {}, headers: {})
      headers = merge_headers(headers)

      if headers['Content-Type'] == 'application/json'
        body = body.to_json
      end

      response = self.class.post(endpoint, body: body, query: query, headers: headers)
      check_for_errors(response)
      response
    end

    def put(endpoint, body, query: {}, headers: {})
      headers = merge_headers(headers)

      if headers['Content-Type'] == 'application/json'
        body = body.to_json
      end

      response = self.class.put(endpoint, body: body, query: query, headers: headers)
      check_for_errors(response)
      response
    end

    def head(endpoint)
      headers = merge_headers({})
      headers.delete('Content-Type')   # No content, can break request parsing
      response = self.class.head(endpoint, headers: headers)
      check_for_errors(response)
      response
    end

    def delete(endpoint, query: {})
      response = self.class.delete(endpoint, query: query, headers: @default_headers)
      check_for_errors(response)
      response
    end

    private

    def check_for_errors(response)
      if response.code >= 200 && response.code < 300
        if response.is_a?(Hash) and response['error']
          parse_error_message(response) if response['error']
        end
        return
      end


      case response.code
      when 401
        if response.nil?
          raise Errors::UnauthorizedError.new("The request you are making requires authorization. Please check that you have permissions & that you've set your API key.", nil)
        end
        raise Errors::UnauthorizedError.new(response["error"]["message"], response)
      when 400
        if response.nil?
          raise Errors::NotFoundError.new("The request was invalid", nil)
        end
        parse_error_message(response)
      when 404
        if response.nil?
          raise Errors::NotFoundError.new("The URI requested is invalid or the resource requested does not exist.", nil)
        end
        raise Errors::NotFoundError.new(response["error"]["message"], response)
      when 500
        if response.nil?
          raise Errors::InternalServerError.new("Whoops! Something is broken.", nil)
        end
        raise Errors::InternalServerError.new(response["error"]["message"], response)
      else
        if response.nil?
          raise Errors::UnknownError.new("An unknown error occurred", nil)
        end
        raise Errors::UnknownError.new("message: #{response["error"]["message"]} stacktrace: #{error["stacktrace"]}", response)
      end
    end

    def parse_error_message(response)
      error = response['error']

      case error["message"]
      when 'authorization required'
        raise Errors::ApiKeyInvalidError.new("The API key you sent is invalid! Please set `Algorithmia::Client.api_key` with the key provided with your account.", response)
      when 'Failed to parse input, input did not parse as valid json'
        raise Errors::JsonParseError.new("Unable to parse the input. Please make sure it matches the expected input of the algorithm and can be parsed into JSON.", response)
      else
        if error["stacktrace"].nil?
          raise Errors::UnknownError.new(error["message"], response)
        else
          raise Errors::UnknownError.new("message: #{error["message"]} stacktrace: #{error["stacktrace"]}", response)
        end
      end
    end

    def merge_headers(headers = {})
      @default_headers.merge(headers)
    end
  end
end
