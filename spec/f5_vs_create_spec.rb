require_relative 'spec_helper.rb'



Member = Struct.new(:address, :port) do
  def to_hash
    { 'address' => self.address, 'port' => self.port }
  end
end

lb = F5::LoadBalancer.new(hostname, :config_file => 'config-andy.yaml', :connect_timeout => 10)