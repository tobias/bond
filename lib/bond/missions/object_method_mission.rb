class Bond::Missions::ObjectMethodMission < Bond::Mission
  class<<self
    attr_accessor :method_actions
    def has_method_action?(obj, meth)
      @found = (@method_actions[meth] || {}).find {|k,v| get_class(k) && obj.is_a?(get_class(k)) }
    end

    def add_method_action(meth_klass, &block)
      klass, meth = meth_klass.split(/[.#]/,2)
      (@method_actions[meth] ||= {})[klass] = block 
    end

    def get_method_action(obj, meth)
      @found[1]
    end

    def get_class(klass)
      (@klasses ||= {})[klass] ||= any_const_get(klass)
    end

    # Returns a constant like Module#const_get no matter what namespace it's nested in.
    # Returns nil if the constant is not found.
    def any_const_get(name)
      return name if name.is_a?(Module)
      klass = Object
      name.split('::').each {|e| klass = klass.const_get(e) }
      klass
    rescue
       nil
    end
  end
  self.method_actions = {}
  
  def initialize(options={}) #:nodoc:
    options.delete(:object_method)
    options[:action] = lambda { }
    options[:on] = /FILL_PER_COMPLETION/
    @eval_binding = options[:eval_binding]
    super(options)
  end

  def handle_valid_match(input)
    meths = Regexp.union *self.class.method_actions.keys
    @condition = /(?:^|\s+)([^\s.]+)?\.?(#{meths})(?:\s+|\()(['":])?(.*)$/
    if (match = super) && eval_object(match) &&
      (match = self.class.has_method_action?(@evaled_object, @meth))
      @completion_prefix = @matched[3]
      @input = @matched[-1] || ''
      @input.instance_variable_set("@object", @evaled_object)
      class<<@input; def object; @object; end; end
      @action = self.class.get_method_action(@evaled_object, @matched[2])
    end
    match
  end

  def eval_object(match)
    @matched = match
    @evaled_object = self.class.current_eval(match[1] || 'self', @eval_binding)
    @meth = @matched[2]
    true
  rescue Exception
    false
  end
end