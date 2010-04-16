require File.expand_path("../spec_helper", __FILE__)

require "active_support/core_ext/hash/indifferent_access"

class FakeBaseController
  attr_accessor :params
end

class ApplicationController < FakeBaseController
  include ParamsMatching
end

describe ParamsMatching, "#params" do
  before(:each) do
    @controller = ApplicationController.new
  end

  def with_params(params_value)
    new_params = params_value.with_indifferent_access.merge(:controller => "application", :action => "fake_action")
    @controller.send(:params=, new_params)
    yield new_params
  ensure
    @controller.send(:params=, nil)
  end

  def params(*args, &block)
    @controller.send(:params, *args, &block)
  end

  it "yields present extracted param with single arg" do
    with_params :foo => 1 do
      params(:foo, &should_yield_with(1))
    end
  end

  it "yields present extracted nested param" do
    with_params :dad => { :son => 1 } do
      params(:dad => :son, &should_yield_with(1))
    end
  end

  it "yields multiple simultaneously present nested params" do
    with_params :family => { :son => 1, :daughter => 2 } do
      params(:family => [ :son, :daughter ], &should_yield_with(1, 2))
    end
  end

  it "yields default empty Array when param is blank and empty Array default is specified" do
    with_params({}) do
      params(:kids => [], &should_yield_with([]))
    end
  end

  it "yields default empty Hash when param is blank and empty Hash default is specified" do
    with_params({}) do
      params(:kids => {}, &should_yield_with({}))
    end
  end

  it "doesn't yield when param is blank" do
    with_params :foo => 1 do
      params(:bar, &should_not_yield)
    end
  end

  it "doesn't yield when nested param is blank" do
    with_params :dad => { :son => 1 } do
      params(:mother => :daughter, &should_not_yield)
    end
  end

  it "doesn't yield when one of multiple nested params is blank" do
    with_params :family => { :son => 1, :daughter => 2 } do
      params(:family => [ :son, :loner ], &should_not_yield)
    end
  end

  it "handles deeply nested present and/or blank params from multiple levels with some defaults" do
    with_params :country => { :state => { :name => "NY" } },
                :kids => [ 1, 2 ],
                :clan => "cosa nostra" do
      params(:kids, :country => { :state => [ :name, :population ] },
             :families => [], :clan => [],
             :secret => { :codes => {} }, :compound => { :molecules => [ :atoms, :particles ]}).should ==
              [ [ 1, 2 ], "NY", nil,
                [], "cosa nostra",
                {}, nil, nil ]
    end
  end

  describe "extraction of" do
    it "single param is just like using good old params[:foo]" do
      with_params :foo => 1 do
        params(:foo).should == 1
      end
    end

    it "single present param when default is specified returns param" do
      with_params(:kids => [ 1, 2 ]) do
        params(:kids => []).should == [ 1, 2 ]
      end
    end

    describe "multiple params when passed multiple args" do
      it "works" do
        with_params :foo => 1, :bar => 2 do |p|
          params(:foo, :bar).should == [ p[:foo], p[:bar] ]
        end
      end

      it "returns nil for missing params" do
        with_params :foo => 1, :bar => 2 do |p|
          params(:foo, :not_in_params, :bar).should == [ p[:foo], nil, p[:bar] ]
        end
      end

      it "returns default empty Array when default is specified and param is missing" do
        with_params({}) do
          params(:kids => []).should == []
        end
      end

      it "returns default empty Hash when default is specified and param is missing" do
        with_params({}) do
          params(:families => {}).should == {}
        end
      end

      it "returns multiple default empty Hashes and Arrays when multiple defaults are specified" do
        with_params({}) do
          params(:families => {}, :clans => {}, :kids => []).should == [ {}, {}, [] ]
        end
      end

      it "returns multiple default empty Hashes and Arrays mixed with present values when multiple defaults are specified" do
        with_params(:kids => [ 1, 2 ]) do
          params(:families => {}, :clans => {}, :kids => []).should == [ {}, {}, [1, 2] ]
        end

        with_params(:families => [ 1, 2 ]) do
          params(:families => {}, :clans => {}, :kids => []).should == [ [1, 2], {}, [] ]
        end

        with_params(:clans => [ 1, 2 ]) do
          params(:families => {}, :clans => {}, :kids => []).should == [ {}, [1, 2], [] ]
        end
      end
    end

    describe "nested params" do
      it "works" do
        with_params :dad => { :son => 1 } do
          params(:dad => :son).should == 1
        end
      end

      it "returns nil for missing params from any level" do
        with_params :dad => { :son => 1 } do
          params(:mom => :daughter).should be_nil
          params(:dad => :kiddie).should be_nil
          params(:grandpa => { :dad => :son }).should be_nil
        end
      end
    end

    describe "nested multiple params" do
      it "works" do
        with_params :family => { :son => 1, :daughter => 2, :cousin => 3 } do
          params(:family => [ :son, :daughter, :cousin ]).should == [ 1, 2, 3]
        end
      end

      it "from different levels simulteneously works" do
        with_params :clan => "cosa nostra",
                    :family => { :son => 1, :daughter => 2 } do
          params(:clan, :family => [ :son, :daughter ]).should == [ "cosa nostra", 1, 2 ]
          params({ :family => [ :son, :daughter ] }, :clan).should == [ 1, 2, "cosa nostra" ]
        end
      end

      it "returns nil for missing params from any level" do
        with_params :family => { :son => 1, :daughter => 2, :cousin => 3 } do
          params(:family => [ :son, :daughter, :cousin, :loner ]).should == [ 1, 2, 3, nil ]
          params(:company => [ :staff, :boss ]).should == [ nil, nil ]
        end
      end

      it "returns nil for deeply nested missing params " do
        with_params({}) do
          params(:university => { :department => [ :professor, :student, :assistant ] }).should == [ nil, nil, nil ]
        end
      end
    end
  end
end