module ParserCombinators
  State = Struct.new(:string, :offset) do
    def peek(n)
      string[offset ... offset + n]
    end

    def read(n)
      State.new(string, offset + n)
    end

    def complete?
      offset == string.size
    end
  end

  def parse(string)
    node, state = root.call(State.new(string, 0))

    if state and state.complete?
      node
    end
  end

  def str(string, &action)
    -> state {
      chunk = state.peek(string.size)

      if chunk == string
        node = [:str, chunk]
        node = action.call(node) if action
        [node, state.read(string.size)]
      end
    }
  end

  def chr(pattern, &action)
    -> state {
      chunk = state.peek(1)

      if chunk =~ %r{[#{pattern}]}
        node =[:chr, chunk] 
        node = action.call(node) if action
        [node, state.read(1)]
      end
    }
  end

  def seq(*parsers, &action)
    -> state {
      matches = []

      parsers.each do |parser|
        node, state = state && parser.call(state)
        matches << node if state
      end

      if state
        node = [:seq, *matches]
        node = action.call(node) if action
        [node, state]
      end
    }
  end

  def rep(parser, n, &action)
    -> state {
      matches = []
      last_state = nil

      while state
        last_state = state
        node, state = parser.call(state)
        matches << node if state
      end

      if matches.size >= n
        node = [:rep, *matches]
        node = action.call(node) if action
        [node, last_state]
      end
    }
  end

  def alt(*parsers, &action)
    -> state {
      parsers.each do |parser|
        node, new_state = parser.call(state)
        if new_state
          node = action.call(node) if action
          return [node, new_state]
        end
      end

      nil
    }
  end

  def ref(name)
    -> state {
      __send__(name).call(state)
    }
  end
end
