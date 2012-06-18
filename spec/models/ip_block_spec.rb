require 'spec_helper'

describe IpBlock do
  describe "validations" do
    it "Should be valid with proper base and mask" do
      IpBlock.new(base_address: 203569230, mask: 10).should be_valid
    end
    it "Should not be valid with IP -1" do
      IpBlock.new(base_address: -1).should_not be_valid
    end
    it "Should not be valid with mask > 32" do
      IpBlock.new(base_address: 203569230, mask: 33).should_not be_valid
    end
  end

  describe "display" do
    it "should display IP 12.34.56.78/32" do
      IpBlock.new(base_address: 203569230, mask: 32).display.should == "12.34.56.78/32"
    end
  end

  describe "parse" do
    it "should parse 127.0.0.1" do
      IpBlock.parse("127.0.0.1").display.should == "127.0.0.1/32"
    end
    it "should parse 127.0.0.0/8" do
      IpBlock.parse("127.0.0.1/8").display.should == "127.0.0.0/8"
    end
  end

  describe "next_free_addresses" do
    describe "When invoked with IP not in range" do
      it "should throw an error" do
        expect{IpBlock.parse("192.168.254.183/24").next_free_addresses("191.0.0.1", 1, [])}.should raise_error
      end
    end
    describe "invoking with an empty used and requesting just one" do
      it "should return one addresses: 192.168.254.180" do
        IpBlock.parse("192.168.254.183/24").next_free_addresses("192.168.254.180", 1, []).should == ["192.168.254.180"]
      end
    end
    describe "invoking with empty used and requesting 50" do
      before :each do
        @addresses = IpBlock.parse("192.168.254.183/24").next_free_addresses("192.168.254.180", 50, [])
      end
      it "should return fifty addresses: [192.168.254.180 ...]" do
        @addresses.size.should == 50
      end
      it "should return the first address [192.168.254.180 ...]" do
        @addresses.first.should == "192.168.254.180"
      end
      it "should return the last address [... 192.168.254.229]" do
        @addresses.last.should == "192.168.254.229"
      end
    end
    describe "invoking with some used IP addresses" do
      before :each do
        @used_addresses = ["192.168.254.180", "192.168.254.182", "192.168.255.3"]
        @addresses = IpBlock.parse("192.168.254.183/24").next_free_addresses("192.168.254.180", 50, @used_addresses)
      end
      it "should return fifty addresses" do
        @addresses.size.should == 50
      end
      it "none of the returned addresses should be already used" do
        (@addresses & @used_addresses).should == []
      end
      it "should return the first address [192.168.254.181 ...]" do
        @addresses.first.should == "192.168.254.181"
      end
    end
  end
end
