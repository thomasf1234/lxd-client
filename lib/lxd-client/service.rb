require 'net/socket_http'

module LxdClient
  class Service
    def initialize(url='unix:///var/lib/lxd/unix.socket', options={ "wait" => true, "read_timeout" => 30 })
      @url = url
      @options = options
    end

    ############### Containers ###############

    def containers
      response = request do |http|
        http.get("/1.0/containers", {'Accept' =>'application/json'}) 
      end

      container_urls = response.body["metadata"]
      container_urls.map { |url| File.basename(url) }
    end

    def container(name)
      response = request do |http|
        http.get("/1.0/containers/#{name}", {'Accept' =>'application/json'}) 
      end

      response.body["metadata"]
    end

    def container_state(name)
      response = request do |http|
        http.get("/1.0/containers/#{name}/state", {'Accept' =>'application/json'}) 
      end

      response.body["metadata"]
    end

    def container_stop(container, stateful=false, force=false, timeout=30)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = { action: 'stop', stateful: stateful, force: force, timeout: timeout }
        put = Net::HTTP::Put.new("/1.0/containers/#{container}/state", headers)

        put.body = body.to_json
        http.request(put)
      end
    end

    def snapshots(container)
      request do |http|
        http.get("/1.0/containers/#{container}/snapshots", {'Accept' =>'application/json'}) 
      end
    end

    def snapshot(container, snapshot)
      request do |http|
        http.get("/1.0/containers/#{container}/snapshots/#{snapshot}", {'Accept' =>'application/json'}) 
      end
    end
    
    #stateful is broken
    def snapshot_create(container, snapshot_name, stateful=false)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = { name: snapshot_name, stateful: stateful }
        post = Net::HTTP::Post.new("/1.0/containers/#{container}/snapshots", headers)

        post.body = body.to_json
        http.request(post)
      end
    end

    def snapshot_delete(container, snapshot)
      request do |http|
        http.delete("/1.0/containers/#{container}/snapshots/#{snapshot}", {'Accept' =>'application/json'}) 
      end
    end

    ############### Operations ###############

    def operations
      response = request do |http|
        http.get('/1.0/operations', {'Accept' =>'application/json'}) 
      end

      operation_urls = response.body["metadata"]
      operation_urls.map { |url| File.basename(url) }
    end

    def operation(uuid)
      response = request do |http|
        http.get("/1.0/operations/#{uuid}", {'Accept' =>'application/json'}) 
      end

      response.body["metadata"]
    end

    def operation_wait(uuid, timeout=nil)
      request do |http|
        endpoint = "/1.0/operations/#{uuid}/wait"
        
        if !timeout.nil? 
          endpoint += "?timeout=#{timeout}"
        end

        http.get(endpoint, {'Accept' =>'application/json'}) 
      end
    end

    ############### Profiles ###############
    def profiles
      response = request do |http|
        http.get("/1.0/profiles", {'Accept' =>'application/json'}) 
      end

      profile_urls = response.body["metadata"]
      profile_urls.map { |url| File.basename(url) }
    end

    def profile(name)
      response = request do |http|
        http.get("/1.0/profiles/#{name}", {'Accept' =>'application/json'}) 
      end

      response.body["metadata"]
    end

    def profile_create(values_hash)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = values_hash
        post = Net::HTTP::Post.new("/1.0/profiles", headers)

        post.body = body.to_json
        http.request(post)
      end

      nil
    end

    def profile_replace(name, values_hash)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = values_hash
        put = Net::HTTP::Put.new("/1.0/profiles/#{name}", headers)

        put.body = body.to_json
        http.request(put)
      end

      nil
    end

    def profile_update(name, values_hash)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = values_hash
        patch = Net::HTTP::Patch.new("/1.0/profiles/#{name}", headers)

        patch.body = body.to_json
        http.request(patch)
      end

      nil
    end

    def profile_rename(name, new_name)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = { name: new_name }
        post = Net::HTTP::Post.new("/1.0/profiles/#{name}", headers)

        post.body = body.to_json
        http.request(post)
      end

      nil
    end

    def profile_delete(name)
      request do |http|
        http.delete("/1.0/profiles/#{name}", {'Accept' =>'application/json'}) 
      end

      nil
    end

    private 
    def request
      http = get_http(@url)
      raw_response = yield(http)
      response = LxdClient::Response.new(raw_response.code, raw_response.body)

      if response.success?
        if response.sync?
          response
        elsif response.async?
          if @options["wait"] == true
            response_id = response.body["metadata"]["id"]
            operation_wait(response_id)
          end
          require 'pry'; binding.pry
          response
          
        else
          raise("Unknown response type #{response.body["type"]}")
        end
      else
        raise(LxdClient::Error.new(response))
      end
    end

    def get_http(url)
      unix_scheme_regex = /^unix:\/\//
      http = nil

      if url.match(unix_scheme_regex).nil?
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)

        if uri.kind_of?(URI::HTTPS)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        else
         http.use_ssl = false
        end  
      else
        socket_path = url.split(unix_scheme_regex).last.strip
        http = Net::SocketHttp.new('', socket_path)
      end

      http.read_timeout = @options['read_timeout']
      http
    end
  end
end
