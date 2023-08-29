require 'net/http'

module SteamHydra
  # Handles network requests
  module Request
    # Makes network requests
    def self.make(args)
      raise('Hostname required.') unless args[:host]

      # Defaults
      timeout = args[:timeout].nil? ? 60 : args[:timeout]
      max_retries = args[:retries].nil? ? 2 : args[:retries]
      args[:path] = args[:path].nil? ? '/' : args[:path]
      tries = 1
      LOG.debug("Netrequest values; host-#{args[:host]} path-#{args[:path]}")
      begin
        loop do
          uri = URI("#{args[:host]}#{args[:path]}")
          use_ssl = (uri.scheme == 'https')
          response = String.new('') # specifically provide an empty string to zero out retries if we failed the previous call, but already had something
          LOG.debug("Building request #{uri} with headers: #{args[:headers]}")
          Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl, read_timeout: timeout) do |http|
            request = case args[:method]
                      when :get then Net::HTTP::Get.new(uri)
                      when :post then Net::HTTP::Post.new(uri)
                      when :put then Net::HTTP::Put.new(uri)
                      when :patch then Net::HTTP::Patch.new(uri)
                      when :delete then Net::HTTP::Delete.new(uri)
                      else
                        raise('No method provided for network request.')
                      end
            request.body = args[:body] if args[:body]
            args[:headers]&.each do |h, v|
              request[h.to_s] = v.to_s
            end
            response = http.request(request)
          end
          if response.code.to_i >= 400
            if tries > max_retries
              LOG.debug("Failed network request to #{args[:host]} retrying.")
              tries += 1
              # add backloff logic, consider header feedback for throttles
              next
            end

            raise('exceeded retrires')
          end
          headers = {}
          response.each_header do |header, value|
            headers[header.to_sym] = value
          end
          return { body: response.body, status: response.code.to_i, headers: headers}
        end
      rescue => e
        LOG.warn("Failed network call #{args[:host]}/#{args[:location]}")
        LOG.warn("Error: #{e}")
        tries += 1
        retry if tries <= max_retries
        LOG.error('Unable to complete a network call. Retries exceeded.')
      end
    end
  end
end