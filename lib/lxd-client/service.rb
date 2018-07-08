require 'net/socket_http'

module LxdClient
  class Service
    def initialize(socket_path='/var/lib/lxd/unix.socket', options={ "wait" => true })
      @socket_path = socket_path
      @options = options
    end

     ############### Containers ###############

    def containers
      request do |http|
        http.get("/1.0/containers", {'Accept' =>'application/json'}) 
      end
    end

    def container(name)
      request do |http|
        http.get("/1.0/containers/#{name}", {'Accept' =>'application/json'}) 
      end
    end

    def container_state(name)
      request do |http|
        http.get("/1.0/containers/#{name}/state", {'Accept' =>'application/json'}) 
      end
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
      request do |http|
        http.get('/1.0/operations', {'Accept' =>'application/json'}) 
      end
    end

    def operation(uuid)
      request do |http|
        http.get("/1.0/operations/#{uuid}", {'Accept' =>'application/json'}) 
      end
    end

    def operation_wait(uuid, timeout=30)
      request do |http|
        http.get("/1.0/operations/#{uuid}/wait?timeout=#{timeout}", {'Accept' =>'application/json'}) 
      end
    end

    ############### Profiles ###############
    def profiles
      request do |http|
        http.get("/1.0/profiles", {'Accept' =>'application/json'}) 
      end
    end

    def profile(name)
      request do |http|
        http.get("/1.0/profiles/#{name}", {'Accept' =>'application/json'}) 
      end
    end

    def profile_create(values_hash)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = values_hash
        post = Net::HTTP::Post.new("/1.0/profiles", headers)

        post.body = body.to_json
        http.request(post)
      end
    end

    def profile_replace(name, values_hash)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = values_hash
        put = Net::HTTP::Put.new("/1.0/profiles/#{name}", headers)

        put.body = body.to_json
        http.request(put)
      end
    end

    def profile_update(name, values_hash)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = values_hash
        patch = Net::HTTP::Patch.new("/1.0/profiles/#{name}", headers)

        patch.body = body.to_json
        http.request(patch)
      end
    end

    def profile_rename(name, new_name)
      request do |http|
        headers = {'Accept' =>'application/json', 'Content-Type' => 'application/json'}
        body = { name: new_name }
        post = Net::HTTP::Post.new("/1.0/profiles/#{name}", headers)

        post.body = body.to_json
        http.request(post)
      end
    end

    def profile_delete(name)
      request do |http|
        http.delete("/1.0/profiles/#{name}", {'Accept' =>'application/json'}) 
      end
    end

    private 
    def request
      http = Net::SocketHttp.new('', @socket_path)
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
          
          response
        else
          raise("Unknown response type #{response.body["type"]}")
        end
      else
        raise(LxdClient::Error.new(response))
      end
    end
  end
end
