require 'net/socket_http'
require 'openssl'
require 'socket'
require 'base64'

module LxdClient
  class Service
    module ContainerActions
      START = 'start'
      STOP = 'stop'
      RESTART = 'restart'
      FREEZE = 'freeze'
      UNFREEZE = 'unfreeze'
    end

    def initialize(url='unix:///var/lib/lxd/unix.socket', async: false, read_timeout: 30, wait_timeout: nil, client_key: nil, client_cert: nil)
      @url = url
      @async = async
      @read_timeout = read_timeout
      @wait_timeout = wait_timeout
      @client_key = client_key
      @client_cert = client_cert
    end

    ############### API ###############

    def api
      response = get("/")
      response.body["metadata"]
    end

    ############### Configuration ###############
    
    def config
      response = get("/1.0")
      response.body["metadata"]
    end
    
    def config_replace(values_hash)
      replace("/1.0", values_hash)
    end
    
    def config_update(values_hash)
      update("/1.0", values_hash)
    end

    ############### Certificates ###############

    def certificates
      response = get("/1.0/certificates")
      response.body["metadata"]
    end

    def certificate_create(cert_path, password, name: Socket.gethostname)
      if !File.file?(cert_path) 
        raise ArgumentError.new("File #{cert_path} not found")
      end

      cert_raw = File.read(cert_path)
      values_hash = {
        name: name,
        type: 'client',
        certificate: Base64.strict_encode64(OpenSSL::X509::Certificate.new(cert_raw).to_der),
        password: password
      }

      create("/1.0/certificates", values_hash)
    end

    def certificate(fingerprint)
      response = get("/1.0/certificates/#{fingerprint}")
      response.body["metadata"]
    end

    ############### Containers ###############

    def containers
      response = get("/1.0/containers")
      container_urls = response.body["metadata"]
      container_urls.map { |url| File.basename(url) }
    end

    def container_create(values_hash)
      response = create("/1.0/containers", values_hash)
      response.body["metadata"]
    end

    def container(name)
      response = get("/1.0/containers/#{name}")
      response.body["metadata"]
    end

    def container_delete(name)
      delete("/1.0/containers/#{name}")
    end

    def container_state(name)
      response = get("/1.0/containers/#{name}/state")
      response.body["metadata"]
    end

    def container_start(container, stateful: false, timeout: nil)
      container_action(container, ContainerActions::START, stateful: stateful, timeout: timeout)
    end

    def container_restart(container, force: false, timeout: nil)
      container_action(container, ContainerActions::RESTART, force: force, timeout: timeout)
    end

    def container_stop(container, stateful: false, force: false, timeout: nil)
      container_action(container, ContainerActions::STOP, stateful: stateful, force: force, timeout: timeout)
    end

    def container_freeze(container, timeout: nil)
      container_action(container, ContainerActions::FREEZE, timeout: timeout)
    end

    def container_unfreeze(container, timeout: nil)
      container_action(container, ContainerActions::UNFREEZE, timeout: timeout)
    end

    ############### Snapshots ###############

    def snapshots(container)
      response = get("/1.0/containers/#{container}/snapshots")
      snapshot_urls = response.body["metadata"]
      snapshot_urls.map { |url| File.basename(url) }
    end

    def snapshot(container, snapshot)
      get("/1.0/containers/#{container}/snapshots/#{snapshot}")
    end
    
    #stateful is broken
    def snapshot_create(container, snapshot_name, stateful: false)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = { name: snapshot_name, stateful: stateful }
        post = Net::HTTP::Post.new("/1.0/containers/#{container}/snapshots", headers)

        post.body = body.to_json
        http.request(post)
      end
    end

    def snapshot_delete(container, snapshot)
      delete("/1.0/containers/#{container}/snapshots/#{snapshot}")
    end

    ############### Images ###############

    def images
      response = get('/1.0/images')
      image_urls = response.body["metadata"]
      image_urls.map { |url| File.basename(url) }
    end

    def image(fingerprint)
      response = get("/1.0/images/#{fingerprint}")
      response.body["metadata"]
    end

    def image_upload(path, sha256: nil, filename: nil, is_public: false, properties: {})
      response = request do |http|
        if !File.file?(path) 
          raise ArgumentError.new("File #{path} not found")
        end

        headers = { }

        #for streamed uploads, must send Content-Length and Transfer-Encoding as 'chunked'
        headers["Content-Type"] = "application/octet-stream"
        headers["Content-Length"] = File.stat(path).size.to_s
        headers["Transfer-Encoding"] = 'chunked'

        headers["X-LXD-fingerprint"] = sha256
        headers["X-LXD-filename"] = filename if !filename.nil?
        headers["X-LXD-public"] = (is_public == true).to_s
        headers["X-LXD-properties"] = URI.encode_www_form(properties) if !properties.empty?
            
        #must stream file upload: 
        post = Net::HTTP::Post.new("/1.0/images", headers)
        post.body_stream = File.open(path, 'r')

        http.request(post)
      end 
    end

    def image_delete(fingerprint)
      delete("/1.0/images/#{fingerprint}")
    end

    ############### Image Aliases ###############

    def image_aliases
      response = get('/1.0/images/aliases')
      image_alias_urls = response.body["metadata"]
      image_alias_urls.map { |url| File.basename(url) }
    end

    def image_alias(name)
      response = get("/1.0/images/aliases/#{name}")
      response.body["metadata"]
    end

    def image_alias_create(values_hash)
      create("/1.0/images/aliases", values_hash)
    end

    def image_alias_replace(name, values_hash)
      replace("/1.0/images/aliases/#{name}", values_hash)
    end

    def image_alias_update(name, values_hash)
      update("/1.0/images/aliases/#{name}", values_hash)
    end

    def image_alias_rename(name, new_name)
      rename("/1.0/images/aliases/#{name}", new_name)
    end

    def image_alias_delete(name)
      delete("/1.0/images/aliases/#{name}")
    end
    
    ############### Networks ###############

    def networks
      response = get('/1.0/networks')
      network_urls = response.body["metadata"]
      network_urls.map { |url| File.basename(url) }
    end

    #   {
    #     "name": "lxdbr1",
    #     "description": "My network",
    #     "config": {
    #         "ipv4.address": "10.207.129.1/24",
    #         "ipv4.nat": "true",
    #         "ipv6.address": "2001:470:b368:4242::1/64",
    #         "ipv6.nat": "true"
    #     }
    # }
    def network_create(values_hash)
      create("/1.0/networks", values_hash)
    end

    def network(name)
      response = get("/1.0/networks/#{name}")
      response.body["metadata"]
    end

    def network_replace(name, values_hash)
      replace("/1.0/networks/#{name}", values_hash)
    end

    #doesn't work v3.0.1
    def network_update(name, values_hash)
      update("/1.0/networks/#{name}", values_hash)
    end

    def network_rename(name, new_name)
      rename("/1.0/networks/#{name}", new_name)
    end

    def network_delete(name)
      delete("/1.0/networks/#{name}")
    end

    ############### Operations ###############

    def operations
      response = get('/1.0/operations')
      operation_urls = response.body["metadata"]
      operation_urls.map { |url| File.basename(url) }
    end

    def operation(uuid)
      response = get("/1.0/operations/#{uuid}")
      response.body["metadata"]
    end

    def operation_wait(uuid, timeout: nil)
      endpoint = "/1.0/operations/#{uuid}/wait"
        
      if !timeout.nil? 
        endpoint += "?timeout=#{timeout}"
      end

      get(endpoint)  
    end

    ############### Profiles ###############
    def profiles
      response = get("/1.0/profiles")
      profile_urls = response.body["metadata"]
      profile_urls.map { |url| File.basename(url) }
    end

    def profile_create(values_hash)
      create("/1.0/profiles", values_hash)
    end

    def profile(name)
      response = get("/1.0/profiles/#{name}")
      response.body["metadata"]
    end

    def profile_replace(name, values_hash)
      replace("/1.0/profiles/#{name}", values_hash)
    end

    def profile_update(name, values_hash)
      update("/1.0/profiles/#{name}", values_hash)
    end

    def profile_rename(name, new_name)
      rename("/1.0/profiles/#{name}", new_name)
    end

    def profile_delete(name)
      delete("/1.0/profiles/#{name}")
    end

    ############### Storage-Pools ###############

    def storage_pools
      response = get("/1.0/storage-pools")
      storage_pools_urls = response.body["metadata"]
      storage_pools_urls.map { |url| File.basename(url) }
    end

    def storage_pool_create(values_hash)
      create("/1.0/storage-pools", values_hash)
    end

    def storage_pool(name)
      response = get("/1.0/storage-pools/#{name}")
      response.body["metadata"]
    end

    def storage_pool_replace(name, values_hash)
      replace("/1.0/storage-pools/#{name}", values_hash)
    end

    def storage_pool_update(name, values_hash)
      update("/1.0/storage-pools/#{name}", values_hash)
    end

    def storage_pool_delete(name)
      delete("/1.0/storage-pools/#{name}")
    end

    def storage_pool_resources(name)
      response = get("/1.0/storage-pools/#{name}/resources")
      response.body["metadata"]
    end

    def storage_pool_volumes(name)
      response = get("/1.0/storage-pools/#{name}/volumes")
      response.body["metadata"]
    end

    def storage_pool_volume_create(name, values_hash)
      create("/1.0/storage-pools/#{name}/volumes", values_hash)
    end

    ############### Resources ############### 

    def resources
      response = get("/1.0/resources")
      response.body["metadata"]
    end

    ############### Convenience Extension ###############

    def image_for_alias(alias_name)
      _image_alias = image_alias(alias_name)
      fingerprint = _image_alias["target"]
      image(fingerprint)
    end

    def logical_core_count
      _resources = resources
      _resources['cpu']['total'].to_i  
    end

    def available_ram_mb
      _resources = resources
      total = _resources['memory']['total'].to_i  
      used = _resources['memory']['used'].to_i

      one_mb = 1024.0 * 1024.0
      (total - used) / one_mb
    end

    protected
    def container_action(container, action, stateful: false, force: false, timeout: nil)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = { action: action, stateful: stateful, force: force, timeout: timeout }
        put = Net::HTTP::Put.new("/1.0/containers/#{container}/state", headers)

        put.body = body.to_json
        http.request(put)
      end
    end

    private 
    def get(endpoint)
      request do |http|
        http.get(endpoint, {'Accept' =>'application/json'}) 
      end
    end

    def create(endpoint, values_hash)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = values_hash
        post = Net::HTTP::Post.new(endpoint, headers)

        post.body = body.to_json
        http.request(post)
      end
    end

    def replace(endpoint, values_hash)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = values_hash
        put = Net::HTTP::Put.new(endpoint, headers)

        put.body = body.to_json
        http.request(put)
      end
    end

    def update(endpoint, values_hash)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = values_hash
        patch = Net::HTTP::Patch.new(endpoint, headers)

        patch.body = body.to_json
        http.request(patch)
      end
    end

    def rename(endpoint, new_name)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = { name: new_name }
        post = Net::HTTP::Post.new(endpoint, headers)

        post.body = body.to_json
        http.request(post)
      end
    end

    def delete(endpoint)
      response = request do |http|
        http.delete(endpoint, {'Accept' =>'application/json'}) 
      end
    end

    def request
      http = get_http(@url)
      raw_response = yield(http)
      response = LxdClient::Response.new(raw_response.code, raw_response.body)

      if response.success?
        if response.sync?
          response
        elsif response.async?
          unless @async == true
            response_id = response.body["metadata"]["id"]
            operation_response = operation_wait(response_id, timeout: @wait_timeout)
            operation_status_code = operation_response.body["metadata"]["status_code"]
            
            if LxdClient::Response::ERROR_HTTP_RESPONSE_CODES.include?(operation_status_code.to_s)
              raise(LxdClient::Error.new(operation_response))
            end
          end
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
          http.cert = OpenSSL::X509::Certificate.new(File.read(@client_cert))
          http.key = OpenSSL::PKey::RSA.new(File.read(@client_key))
        else
         http.use_ssl = false
        end  
      else
        socket_path = url.split(unix_scheme_regex).last.strip
        http = Net::SocketHttp.new('', socket_path)
      end

      http.read_timeout = @read_timeout
      http
    end
  end
end
