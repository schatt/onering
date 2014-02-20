require "spec_helper"
require "lib/test_model"

describe "App::Model"  do
  describe "Utils" do
    describe "to_h" do
      before :each do
        @m = TestModel.new
      end
      it "new object should only to_h it's id" do
        @m.to_h.should == {"id" => @m.id}
      end
      it "the property _type should not be serializble, but all others should" do
        @m["_type"] = 5
        @m["x"] = 7
        @m.to_h.should == {"id" => @m.id, "x" => 7}
      end
    end
    describe "to_json" do
      before :each do
        @m = TestModel.new
      end
      it "should make a json string" do
        @m["x"] = 7
        @m.to_json.should == {"id" => @m.id, "x" => 7}.to_json
      end
    end
    describe "from_h" do
      before :each do
        @m = TestModel.new
      end
      it "should merge cleanly with empty hash {}" do
        @m.from_h({}).to_h.should == {"id" => @m.id}
      end
      it "should merge new properties onto the object" do
        @m.from_h({:x => 5}).to_h.should == {"id" => @m.id, "x" => 5}
      end
    end
    describe "from_json" do
      before :each do
        @m = TestModel.new
      end
      it "should merge cleanly with empty hash {}" do
        @m.from_json("{}").to_h.should == {"id" => @m.id}
      end
      it "should merge new properties onto the object" do
        @m.from_json('{"x": 5}').to_h.should == {"id" => @m.id, "x" => 5}
      end
    end
    # TODO
    # describe "- (diff)" do
    #   it "diff should be empty when diffing with self" do
    #     m = TestModel.new
    #     m.-(m).should == {}
    #   end
    # end
  end
  describe "Base" do
    # TODO
    # describe "find_or_create" do
    #   it "should create a new object(s) when the object doesn't exist" do
    #     m = TestModel.find_or_create(['111111', '222222'])
    #     m.length.should == 2
    #     m.each do |m|
    #       m.delete
    #     end
    #   end
    # end
  end
end
