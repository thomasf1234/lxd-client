RSpec.describe LxdClient::Response do
  context "success" do 
    let(:response_code) { "200" }
    let(:response_body) do 
      "{\"type\":\"sync\",\"status\":\"Success\",\"status_code\":200,\"operation\":\"\",\"error_code\":0,\"error\":\"\",\"metadata\":[\"/1.0/containers/cont-ub18\",\"/1.0/containers/cont-ub16\",\"/1.0/containers/cont-ub14\"]}"
    end
    let(:response) { LxdClient::Response.new(response_code, response_body) }

    it "has a 200 HTTP response code" do 
      expect(response.code).to eq('200')
    end

    it "is a successful response" do 
      expect(response.success?).to eq(true)
    end

    it "is not an error response" do 
      expect(response.error?).to eq(false)
    end

    it "is is a synchronous response" do 
      expect(response.sync?).to eq(true)
    end

    it "is is not an asynchronous response" do 
      expect(response.async?).to eq(false)
    end

    it "is has the container list within the meta data" do 
      expect(response.body["metadata"]).to match_array(["/1.0/containers/cont-ub18", "/1.0/containers/cont-ub16", "/1.0/containers/cont-ub14"])
    end
  end

  context "error" do 
    let(:response_code) { "500" }
    let(:response_body) do 
      "{\"error\":\"Failed to retrieve profile='nonexistent_profile'\",\"error_code\":500,\"type\":\"error\"}"
    end
    let(:response) { LxdClient::Response.new(response_code, response_body) }

    it "has a 500 HTTP response code" do 
      expect(response.code).to eq('500')
    end

    it "is not a successful response" do 
      expect(response.success?).to eq(false)
    end

    it "is an error response" do 
      expect(response.error?).to eq(true)
    end

    it "is is not a synchronous response" do 
      expect(response.sync?).to eq(false)
    end

    it "is is not an asynchronous response" do 
      expect(response.async?).to eq(false)
    end

    it "is has the error messages" do 
      expect(response.body["error"]).to eq("Failed to retrieve profile='nonexistent_profile'")
      expect(response.body["error_code"]).to eq(500)
    end
  end
end
