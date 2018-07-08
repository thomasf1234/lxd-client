RSpec.describe LxdClient::Service do
  let(:service) { LxdClient::Service.new('http://localhost.lxd') }

  describe "containers" do 
    let(:response_code) { 200 }
    let(:response_body) do
       "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":[\"/1.0/containers/cont-ub18\",\"/1.0/containers/cont-ub16\",\"/1.0/containers/cont-ub14\"]}" 
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
          expect(e.message).to eq("Received response with error_code 404 : 'not found'")
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
end
