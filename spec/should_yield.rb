# http://gist.github.com/246632
module ShouldYield
  class ShouldYieldObject
    def to_proc
      lambda { |*args| yield!(*args) }
    end

    def should_yield
      should_receive(:yield!).at_least(1)
    end

    def should_yield_with(*args)
      should_receive(:yield!).with(*args)
    end

    def should_yield_each(*args)
      args.each do |arg|
        should_receive(:yield!).with(arg).ordered
      end
    end

    def should_not_yield
      should_not_receive(:yield!)
    end
  end

  module Expectations
    # Expects that the method this is passed to will yield with any args
    def should_yield
    end

    # If args are passed, expects the yield with those args
    # If no args are passed, expects the yield with no args
    # If you intend to allow any args, call like so:
    #
    #   object.method(&should_yield_with(any_args))
    #
    # or use should_yield
    def should_yield_with(*args)
    end

    # Expectes each argument as an individual yield in the order passed
    # For example:
    # 
    #   [1,2,3].method(&should_yield_each(1,2,3))
    #
    # or
    #
    #   ary = [1,2,3]
    #   ary.each(&should_yield_each(*ary))
    #
    def should_yield_each(*args)
    end

    # Expects that the method to which this is passed will not yield.
    def should_not_yield
    end

    [:should_yield, :should_yield_with, :should_yield_each, :should_not_yield].each do |meth|
      define_method(meth) do |*args|
        syo = ShouldYieldObject.new
        syo.send(meth, *args)
        syo
      end
    end

  end
end
