require 'test/unit'

class Context
  attr_reader :failures

  def initialize(&block)
    @block = block
    @passed = true
    @failures = []
    @subcontext = nil
  end
  def run
    instance_eval(&@block)
    @subcontext.run if @subcontext
  end
  def context(name, &block)
    @subcontext = self.class.new(&block)
  end
  def setup(&setup_block)
    @setup_block = setup_block
  end
  def should(name, &block)
    instance_eval(&@setup_block) if @setup_block
    instance_eval(&block)
  end
  def assert(expression, message=nil)
    unless expression
      @failures << message
    end
    @passed = @passed && expression
  end
  def assert_equal(expected, actual)
    assert actual == expected, "Expected #{expected.inspect} but got #{actual.inspect}"
  end
  def passed?
    @passed && (@subcontext ? @subcontext.passed? : true)
  end
end

class JTestTest < Test::Unit::TestCase
  def test_should_pass_when_all_tests_pass
    x = context "Given something" do
      should "work" do
        assert true
      end
    end
    x.run
    assert x.passed?
  end

  def test_should_fail_when_all_tests_fail
    x = context "Given something" do
      should "work" do
        assert false
      end
    end
    x.run
    assert !x.passed?
  end

  def test_should_fail_when_any_tests_fail
    x = context "Given something" do
      should "work" do
        assert false
      end
      should "also work" do
        assert true
      end
    end
    x.run
    assert !x.passed?
  end

  def test_should_allow_setup_to_provide_instance_variables
    x = context "Given something" do
      setup do
        @name = "james"
      end
      should "work" do
        assert_equal "james", @name
      end
    end
    x.run
    assert x.passed?
  end

  def test_should_run_setup_before_every_test
    x = context "Given something" do
      setup do
        @name = "james"
      end
      should "work" do
        @name += " is awesome"
        assert_equal "james is awesome", @name
      end
      should "also work" do
        @name += " is the best"
        assert_equal "james is the best", @name
      end
    end
    x.run
    assert x.passed?, x.failures
  end

  def test_should_allow_nesting_of_contexts
    x = context "Given something" do
      context "and another thing" do
        should "work" do
          assert false
        end
      end
    end
    x.run
    assert !x.passed?
  end

  private

  def context(name, &block)
    Context.new(&block)
  end
end