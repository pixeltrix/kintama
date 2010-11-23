class Context
  attr_accessor :failures

  def initialize(parent=nil, &block)
    @block = block
    @failures = []
    @subcontexts = []
    @parent = parent
  end
  def run
    instance_eval(&@block)
    @subcontexts.each { |s| s.run }
  end
  def context(name, &block)
    @subcontexts << self.class.new(self, &block)
  end
  def setup(&setup_block)
    @setup_block = setup_block
  end
  def run_setups(environment)
    @parent.run_setups(environment) if @parent
    environment.instance_eval(&@setup_block) if @setup_block
  end
  def should(name, &block)
    environment = TestEnvironment.new(self)
    run_setups(environment)
    environment.instance_eval(&block)
  end
  def passed?
    @failures.empty? && @subcontexts.inject(true) { |result, s| result && s.passed? }
  end

  class TestEnvironment
    def initialize(context)
      @context = context
    end
    def assert(expression, message=nil)
      unless expression
        @context.failures << message
      end
    end
    def assert_equal(expected, actual)
      assert actual == expected, "Expected #{expected.inspect} but got #{actual.inspect}"
    end
  end
end