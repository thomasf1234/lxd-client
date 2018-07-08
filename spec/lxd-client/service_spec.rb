RSpec.describe LxdClient::Service do
  let(:service) { LxdClient::Service.new('http://localhost.lxd') }

  ############### Containers ###############

  describe "containers" do 
    let(:response_code) { 200 }
    let(:response_body) do
       "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":#{containers.to_json}}" 
    end
    let(:containers) do 
      ["/1.0/containers/cont-ub18", "/1.0/containers/cont-ub16", "/1.0/containers/cont-ub14"]
    end

    before(:each) do
      stub_request(:get, "http://localhost.lxd/1.0/containers").to_return(
        body: response_body, 
        status: response_code
      )
    end
    
    it "returns the containers" do 
      expect(service.containers).to match_array(["cont-ub18", "cont-ub16", "cont-ub14"])
    end
  end

  describe "container" do 
    context "Found" do 
      let(:response_code) { 200 }
      let(:response_body) do
        "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":#{container_info.to_json}}"
      end
      let(:container_info) do 
        {"architecture"=>"x86_64",
          "config"=>
           {"image.architecture"=>"amd64",
            "image.description"=>"ubuntu 18.04 LTS amd64 (release) (20180617)",
            "image.label"=>"release",
            "image.os"=>"ubuntu",
            "image.release"=>"bionic",
            "image.serial"=>"20180617",
            "image.version"=>"18.04",
            "volatile.base_image"=>"b190d5ec0c537468465e7bd122fe127d9f3509e3a09fb699ac33b0c5d4fe050f",
            "volatile.eth0.hwaddr"=>"00:16:3e:96:32:26",
            "volatile.idmap.base"=>"0",
            "volatile.idmap.next"=>
             "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":296608,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":296608,\"Nsid\":0,\"Maprange\":65536}]",
            "volatile.last_state.idmap"=>
             "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":296608,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":296608,\"Nsid\":0,\"Maprange\":65536}]",
            "volatile.last_state.power"=>"RUNNING"},
          "devices"=>{},
          "ephemeral"=>false,
          "profiles"=>["basic"],
          "stateful"=>false,
          "description"=>"",
          "created_at"=>"2018-07-04T16:42:28+01:00",
          "expanded_config"=>
           {"boot.autostart"=>"true",
            "boot.autostart.priority"=>"100",
            "environment.http_proxy"=>"",
            "image.architecture"=>"amd64",
            "image.description"=>"ubuntu 18.04 LTS amd64 (release) (20180617)",
            "image.label"=>"release",
            "image.os"=>"ubuntu",
            "image.release"=>"bionic",
            "image.serial"=>"20180617",
            "image.version"=>"18.04",
            "limits.cpu"=>"1",
            "limits.memory"=>"500MB",
            "limits.memory.swap"=>"false",
            "volatile.base_image"=>"b190d5ec0c537468465e7bd122fe127d9f3509e3a09fb699ac33b0c5d4fe050f",
            "volatile.eth0.hwaddr"=>"00:16:3e:96:32:26",
            "volatile.idmap.base"=>"0",
            "volatile.idmap.next"=>
             "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":296608,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":296608,\"Nsid\":0,\"Maprange\":65536}]",
            "volatile.last_state.idmap"=>
             "[{\"Isuid\":true,\"Isgid\":false,\"Hostid\":296608,\"Nsid\":0,\"Maprange\":65536},{\"Isuid\":false,\"Isgid\":true,\"Hostid\":296608,\"Nsid\":0,\"Maprange\":65536}]",
            "volatile.last_state.power"=>"RUNNING"},
          "expanded_devices"=>{"eth0"=>{"name"=>"eth0", "nictype"=>"bridged", "parent"=>"lxdbr0", "type"=>"nic"}, "root"=>{"path"=>"/", "pool"=>"default", "size"=>"2GB", "type"=>"disk"}},
          "name"=>"cont-ub18",
          "status"=>"Running",
          "status_code"=>103,
          "last_used_at"=>"2018-07-08T14:26:11+01:00",
          "location"=>""}
      end

      before(:each) do
        stub_request(:get, "http://localhost.lxd/1.0/containers/cont-ub18").to_return(
          body: response_body, 
          status: response_code
        )
      end

      it "returns the container info" do 
        expect(service.container("cont-ub18")).to eq(container_info)
      end
    end

    context "Not Found" do 
      let(:response_code) { 404 }
      let(:response_body) do
        "{\"error\":\"not found\",\"error_code\":404,\"type\":\"error\"}" 
      end

      before(:each) do
        stub_request(:get, "http://localhost.lxd/1.0/containers/cont-ub17").to_return(
          body: response_body, 
          status: response_code
        )
      end

      it "raises an error for 404 not found" do 
        begin
          service.container("cont-ub17")
          fail("Should have raised exception")
        rescue LxdClient::Error => e
          expect(e.message).to eq("Received response with error_code 404 : not found")
        end
      end
    end
  end

  describe "container_state" do 
    context "exists" do 
      let(:response_code) { 200 }
      let(:response_body) do
        "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":#{container_state.to_json}}"
      end
      let(:container_state) do 
        {"status"=>"Running",
          "status_code"=>103,
          "disk"=>{"root"=>{"usage"=>107749888}},
          "memory"=>{"usage"=>98791424, "usage_peak"=>122769408, "swap_usage"=>0, "swap_usage_peak"=>0},
          "network"=>
           {"eth0"=>
             {"addresses"=>
               [{"family"=>"inet", "address"=>"10.95.218.237", "netmask"=>"24", "scope"=>"global"},
                {"family"=>"inet6", "address"=>"fd42:d9e3:83c3:42bc:216:3eff:fe96:3226", "netmask"=>"64", "scope"=>"global"},
                {"family"=>"inet6", "address"=>"fe80::216:3eff:fe96:3226", "netmask"=>"64", "scope"=>"link"}],
              "counters"=>{"bytes_received"=>360694, "bytes_sent"=>37913, "packets_received"=>540, "packets_sent"=>414},
              "hwaddr"=>"00:16:3e:96:32:26",
              "host_name"=>"veth912P74",
              "mtu"=>1500,
              "state"=>"up",
              "type"=>"broadcast"},
            "lo"=>
             {"addresses"=>[{"family"=>"inet", "address"=>"127.0.0.1", "netmask"=>"8", "scope"=>"local"}, {"family"=>"inet6", "address"=>"::1", "netmask"=>"128", "scope"=>"local"}],
              "counters"=>{"bytes_received"=>1792, "bytes_sent"=>1792, "packets_received"=>22, "packets_sent"=>22},
              "hwaddr"=>"",
              "host_name"=>"",
              "mtu"=>65536,
              "state"=>"up",
              "type"=>"loopback"}},
          "pid"=>3060,
          "processes"=>30,
          "cpu"=>{"usage"=>6091368146}}
      end

      before(:each) do
        stub_request(:get, "http://localhost.lxd/1.0/containers/cont-ub18/state").to_return(
          body: response_body, 
          status: response_code
        )
      end

      it "returns the container info" do 
        expect(service.container_state("cont-ub18")).to eq(container_state)
      end
    end
  end

  ############### Operations ###############

  describe "operations" do 
    let(:response_code) { 200 }
    let(:response_body) do
       "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":#{operations.to_json}}" 
    end
    let(:operations) do 
      [
        "/1.0/operations/c0fc0d0d-a997-462b-842b-f8bd0df82507",
        "/1.0/operations/092a8755-fd90-4ce4-bf91-9f87d03fd5bc"
      ]
    end

    before(:each) do
      stub_request(:get, "http://localhost.lxd/1.0/operations").to_return(
        body: response_body, 
        status: response_code
      )
    end
    
    it "returns the operations" do 
      expect(service.operations).to match_array(["c0fc0d0d-a997-462b-842b-f8bd0df82507", "092a8755-fd90-4ce4-bf91-9f87d03fd5bc"])
    end
  end

  describe "operation" do 
    context "Found" do 
      let(:response_code) { 200 }
      let(:response_body) do
        "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":#{operation.to_json}}" 
      end
      let(:operation) do 
        {
          "id" => "b8d84888-1dc2-44fd-b386-7f679e171ba5",
          "class" => "token",                                                                       # One of "task" (background task), "websocket" (set of websockets and crendentials) or "token" (temporary credentials)
          "created_at" => "2016-02-17T16:59:27.237628195-05:00",                                    # Creation timestamp
          "updated_at" => "2016-02-17T16:59:27.237628195-05:00",                                    # Last update timestamp
          "status" => "Running",
          "status_code" => 103,
          "resources" => {                                                                          # List of affected resources
              "images" => [
                  "/1.0/images/54c8caac1f61901ed86c68f24af5f5d3672bdc62c71d04f06df3a59e95684473"
              ]
          },
          "metadata" => {                                                                           # Extra information about the operation (action, target, ...)
              "secret" => "c9209bee6df99315be1660dd215acde4aec89b8e5336039712fc11008d918b0d"
          },
          "may_cancel" => true,                                                                     # Whether it's possible to cancel the operation (DELETE)
          "err" => ""
        }
      end
      
      before(:each) do
        stub_request(:get, "http://localhost.lxd/1.0/operations/b8d84888-1dc2-44fd-b386-7f679e171ba5").to_return(
          body: response_body, 
          status: response_code
        )
      end
      
      it "returns the operation" do 
        expect(service.operation('b8d84888-1dc2-44fd-b386-7f679e171ba5')).to eq(operation)
      end
    end
  end

  ############### Profiles ###############

  describe "profiles" do 
    let(:response_code) { 200 }
    let(:response_body) do
       "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":#{profiles.to_json}}" 
    end
    let(:profiles) do 
      ["/1.0/profiles/basic", "/1.0/profiles/default"]
    end

    before(:each) do
      stub_request(:get, "http://localhost.lxd/1.0/profiles").to_return(
        body: response_body, 
        status: response_code
      )
    end
    
    it "returns the profiles" do 
      expect(service.profiles).to match_array(["basic", "default"])
    end
  end

  describe "profile" do 
    let(:response_code) { 200 }
    let(:response_body) do
       "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":#{profile.to_json}}" 
    end
    let(:profile) do 
      {"config"=>{},
      "description"=>"Default LXD profile",
      "devices"=>{"eth0"=>{"name"=>"eth0", "nictype"=>"bridged", "parent"=>"lxdbr0", "type"=>"nic"}, "root"=>{"path"=>"/", "pool"=>"default", "type"=>"disk"}},
      "name"=>"default",
      "used_by"=>[]}
    end

    before(:each) do
      stub_request(:get, "http://localhost.lxd/1.0/profiles/default").to_return(
        body: response_body, 
        status: response_code
      )
    end
    
    it "returns the profile" do 
      expect(service.profile('default')).to eq(profile)
    end
  end

  describe "profile_create" do 
    context "Profile exists" do 
      let(:response_code) { 400 }
      let(:response_body) do
        "{\"error\":\"The profile already exists\",\"error_code\":400,\"type\":\"error\"}"
      end
      let(:values_hash) do 
        {"config"=>
          {"boot.autostart"=>"false",
           "boot.autostart.priority"=>"100",
           "environment.http_proxy"=>"",
           "limits.cpu"=>"2",
           "limits.memory"=>"700MB"},
         "description"=>"Test LXD profile",
         "name"=>"test",
         "devices"=>
          {"eth0"=>
            {"name"=>"eth0", "nictype"=>"bridged", "parent"=>"lxdbr0", "type"=>"nic"},
           "root"=>{"path"=>"/", "pool"=>"default", "size"=>"2GB", "type"=>"disk"}}}
      end
      
      before(:each) do
        stub_request(:post, "http://localhost.lxd/1.0/profiles").to_return(
          body: response_body, 
          status: response_code
        )
      end

      it "raises an error for 400 bad request" do 
        begin
          service.profile_create(values_hash)
          fail("Should have raised exception")
        rescue LxdClient::Error => e
          expect(e.message).to eq("Received response with error_code 400 : The profile already exists")
        end
      end
    end

    context "Profile does not exists" do 
      let(:response_code) { 201 }
      let(:response_body) do
        "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":null}"
      end
      let(:values_hash) do 
        {"config"=>
          {"boot.autostart"=>"false",
           "boot.autostart.priority"=>"100",
           "environment.http_proxy"=>"",
           "limits.cpu"=>"2",
           "limits.memory"=>"700MB"},
         "description"=>"Test LXD profile",
         "name"=>"test",
         "devices"=>
          {"eth0"=>
            {"name"=>"eth0", "nictype"=>"bridged", "parent"=>"lxdbr0", "type"=>"nic"},
           "root"=>{"path"=>"/", "pool"=>"default", "size"=>"2GB", "type"=>"disk"}}}
      end
      
      before(:each) do
        stub_request(:post, "http://localhost.lxd/1.0/profiles").to_return(
          body: response_body, 
          status: response_code
        )
      end
      
      it "creates the profile" do 
        expect { service.profile_create(values_hash) }.to_not raise_error
      end
    end 
  end

  describe "profile_replace" do 
    context "Profile exists" do 
      let(:response_code) { 200 }
      let(:response_body) do
        "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":{}}"
      end
      let(:values_hash) do 
        {"config"=>
          {"boot.autostart"=>"false",
           "boot.autostart.priority"=>"100",
           "environment.http_proxy"=>"",
           "limits.cpu"=>"2",
           "limits.memory"=>"700MB"},
         "description"=>"Test LXD profile",
         "devices"=>
          {"eth0"=>
            {"name"=>"eth0", "nictype"=>"bridged", "parent"=>"lxdbr0", "type"=>"nic"},
           "root"=>{"path"=>"/", "pool"=>"default", "size"=>"2GB", "type"=>"disk"}}}
      end
      
      before(:each) do
        stub_request(:put, "http://localhost.lxd/1.0/profiles/test").to_return(
          body: response_body, 
          status: response_code
        )
      end

      it "replaces the profile" do 
        expect { service.profile_replace('test', values_hash) }.to_not raise_error
      end
    end

    context "Profile does not exists" do 
      let(:response_code) { 500 }
      let(:response_body) do
        "{\"error\":\"Failed to retrieve profile='unknown'\",\"error_code\":500,\"type\":\"error\"}" 
      end
      let(:values_hash) do 
        {"config"=>
          {"boot.autostart"=>"false",
           "boot.autostart.priority"=>"100",
           "environment.http_proxy"=>"",
           "limits.cpu"=>"2",
           "limits.memory"=>"700MB"},
         "description"=>"Test LXD profile",
         "devices"=>
          {"eth0"=>
            {"name"=>"eth0", "nictype"=>"bridged", "parent"=>"lxdbr0", "type"=>"nic"},
           "root"=>{"path"=>"/", "pool"=>"default", "size"=>"2GB", "type"=>"disk"}}}
      end
      
      before(:each) do
        stub_request(:put, "http://localhost.lxd/1.0/profiles/unknown").to_return(
          body: response_body, 
          status: response_code
        )
      end
      
      it "raises an 500 error for failing to retrieve unknown profile" do 
        begin
          service.profile_replace('unknown', values_hash)
          fail("Should have raised exception")
        rescue LxdClient::Error => e
          expect(e.message).to eq("Received response with error_code 500 : Failed to retrieve profile='unknown'")
        end
      end
    end 
  end

  describe "profile_update" do 
    context "Profile exists" do 
      let(:response_code) { 200 }
      let(:response_body) do
        "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":{}}"
      end
      let(:values_hash) do 
        {"config"=>
          {"boot.autostart"=>"true",
           "boot.autostart.priority"=>"101"}}
      end
      
      before(:each) do
        stub_request(:patch, "http://localhost.lxd/1.0/profiles/test").to_return(
          body: response_body, 
          status: response_code
        )
      end

      it "updates the profile" do 
        expect { service.profile_update('test', values_hash) }.to_not raise_error
      end
    end
  end

  describe "profile_rename" do 
    context "Profile exists" do 
      let(:response_code) { 200 }
      let(:response_body) do
        "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":{}}"
      end
      
      before(:each) do
        stub_request(:post, "http://localhost.lxd/1.0/profiles/test").to_return(
          body: response_body, 
          status: response_code
        )
      end

      it "renames the profile" do 
        expect { service.profile_rename('test', "new-name") }.to_not raise_error
      end
    end
  end

  describe "profile_delete" do 
    context "Found" do 
      let(:response_code) { 200 }
      let(:response_body) do
        "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":{}}"
      end
      
      before(:each) do
        stub_request(:delete, "http://localhost.lxd/1.0/profiles/obsolete_profile").to_return(
          body: response_body, 
          status: response_code
        )
      end
      
      it "deletes the profile" do 
        expect { service.profile_delete('obsolete_profile') }.to_not raise_error 
      end
    end

    context "Not Found" do 
      let(:response_code) { 404 }
      let(:response_body) do
        "{\"error\":\"not found\",\"error_code\":404,\"type\":\"error\"}" 
      end

      before(:each) do
        stub_request(:delete, "http://localhost.lxd/1.0/profiles/unknown").to_return(
          body: response_body, 
          status: response_code
        )
      end

      it "raises an error for 404 not found" do 
        begin
          service.profile_delete("unknown")
          fail("Should have raised exception")
        rescue LxdClient::Error => e
          expect(e.message).to eq("Received response with error_code 404 : not found")
        end
      end
    end
  end
end
