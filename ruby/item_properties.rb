# Generates new constants as needed to represent properties of objects.
# For instance, a torch's properties may include P::WOODEN, P::BRIGHT, P::HOT,
# or P::WIELDABLE. Each constant is an instance of P::ItemPropertyExpression
# with only one element in its @expression, namely itself.
module P
  # Represents both boolean expressions for testing an item's properties, and
  # the properties themselves.
  class ItemPropertyExpression
    @operators = {:& => 2, :| => 2, :! => 1, :^ => 2}
    class << self
      attr_reader :operators
    end
    attr_reader :expression  # postfix notation

    def initialize *postfix_expression
      if postfix_expression == [:leaf]
        @expression = [self]
      else  # compound statement
        @expression = postfix_expression.collect_concat do |elem|
          (elem.is_a? ItemPropertyExpression) ? elem.expression : elem
        end
      end
    end

    # Checks if this expression matches the given item's properties.
    # eg: (P::HOT & !P::IRON).match? torch
    # => true, a torch is hot and not iron
    #     (!P::WIELDABLE | P::WOODEN).match? sword
    # => false, a sword is not unwieldable or wooden.
    # If the given item is nil the result is also nil.
    def match? item  # TODO: Partial matches, somehow?
      return nil if item.nil?
      stack = []
      @expression.each do |symb|
        ary = self.class.operators[symb]
        if ary.nil?  # property
          stack.push item.property? symb
        else  # operator
          caller, *args = stack.pop ary  # grab the top 'ary' elements from the stack
          stack.push caller.public_send(symb, *args)
        end
      end
      stack.pop
    end

    def & other
      ItemPropertyExpression.new(self, other, :&)
    end

    def | other
      ItemPropertyExpression.new(self, other, :|)
    end

    def !
      ItemPropertyExpression.new(self, :!)
    end

    def ^ other
      ItemPropertyExpression.new(self, other, :^)
    end
    protected :expression
  end
end

# In the event that a constant of the requested name does not exist, this method
# will generate it.
def P.const_missing name
  self.const_set name, P::ItemPropertyExpression.new(:leaf)
end
