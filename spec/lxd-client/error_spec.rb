RSpec.describe LxdClient::Error do
  context "error" do 
    let(:response_code) { "500" }
    let(:response_body) do 
      "{\"error\":\"Failed to retrieve profile='nonexistent_profile'\",\"error_code\":500,\"type\":\"error\"}"
    end
    let(:response) { LxdClient::Response.new(response_code, response_body) }
    let(:error) { LxdClient::Error.new(response) }

    it "is an exception" do 
      expect(error.kind_of?(RuntimeError)).to eq(true)
    end

    it "has the response" do 
      expect(error.response).to eq(response)
    end

    it "displays the error message" do 
      expect(error.message).to eq("Received response with error_code 500 : Failed to retrieve profile='nonexistent_profile'")
    end
  end
end
