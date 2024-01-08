RSpec.describe Roleback do
	it "has a version number" do
		expect(Roleback::VERSION).not_to be nil
	end

	it "defines any as ::Roleback::ANY" do
		expect(Roleback.any).to eq(::Roleback::ANY)
	end

	it "defines allow as ::Roleback::ALLOW" do
		expect(Roleback.allow).to eq(::Roleback::ALLOW)
	end

	it "defines deny as ::Roleback::DENY" do
		expect(Roleback.deny).to eq(::Roleback::DENY)
	end
end
