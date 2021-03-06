module Algorithmia
  class DataObject
    attr_reader :data_uri

    def initialize(client, data_uri)
      @client = client
      @data_uri = data_uri
      sanitize_data_uri
    end

    def basename
      File.basename(@url)
    end

    def parent
      @client.dir(File.split(@data_uri).first)
    end

    private

    def sanitize_data_uri
      file_path = @data_uri.gsub('data://', '')
      @url = File.join('/v1/data/', file_path)
    end
  end
end
