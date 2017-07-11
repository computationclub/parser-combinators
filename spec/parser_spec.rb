require 'parser_combinators'

Zero = Class.new do
  def inspect
    "0"
  end
end.new
True = Class.new do
  def inspect
    "true"
  end
end.new
False = Class.new do
  def inspect
    "false"
  end
end.new
Succ = Struct.new(:t) do
  def inspect
    "(succ #{t.inspect})"
  end
end
Pred = Struct.new(:t) do
  def inspect
    "(pred #{t.inspect})"
  end
end
IsZero = Struct.new(:t) do
  def inspect
    "(iszero #{t.inspect})"
  end
end
Var = Struct.new(:name) do
  def inspect
    name
  end
end
Abs = Struct.new(:var, :body) do
  def inspect
    "(λ#{var.inspect}.#{body.inspect})"
  end
end
App = Struct.new(:left, :right) do
  def inspect
    "(#{left.inspect} #{right.inspect})"
  end
end
If = Struct.new(:t1, :t2, :t3) do
  def inspect
    "(if #{t1.inspect} then #{t2.inspect} else #{t3.inspect})"
  end
end

class Parser
  include ParserCombinators

  def root
    alt(zero, tru, fals, succ, pred, iszero, iff, app, var, abs)
  end

  def var
    chr('a-z') { |node| Var.new(node.last) }
  end

  def app
    seq(ref(:var), _, alt(ref(:app), ref(:var))) do |node|
      case node[3]
      when App
        App.new(App.new(node[1], node[3].left), node[3].right)
      when Var
        App.new(node[1], node[3])
      end
    end
  end

  def abs
    seq(str('λ'), ref(:var), str('.'), ref(:root)) { |node| Abs.new(node[2], node[4]) }
  end

  def tru
    str('true') { True }
  end

  def fals
    str('false') { False }
  end

  def zero
    str('0') { Zero }
  end

  def iff
    seq(str('if'), _, ref(:root), _, str('then'), _, ref(:root), _, str('else'), _, ref(:root)) { |node|
      # [:seq,                          0
      #  [:str, "if"],                  1
      #  [:rep, [:str, " "]],           2
      #  "(iszero (pred (succ 0)))",    3
      #  [:rep, [:str, " "]],           4
      #  [:str, "then"],                5
      #  [:rep, [:str, " "]],           6
      #  true,                          7
      #  [:rep, [:str, " "]],           8
      #  [:str, "else"],                9
      #  [:rep, [:str, " "]],          10
      #  false]                        11
      If.new(node[3], node[7], node[11])
    }
  end

  def succ
    function_call('succ', Succ)
  end

  def pred
    function_call('pred', Pred)
  end

  def iszero
    function_call('iszero', IsZero)
  end

  def whitespace
    rep(str(' '), 1)
  end

  alias _ whitespace

  def function_call(name, klass)
    seq(str(name), whitespace, ref(:root)) { |node| klass.new(node.last) }
  end
end

RSpec.describe Parser do
  specify do
    expect(parse('0')).to eq(Zero)
  end

  specify do
    expect(parse('true')).to eq(True)
  end

  specify do
    expect(parse('false')).to eq(False)
  end

  specify do
    expect(parse('succ 0')).to eq(Succ.new(Zero))
  end

  specify do
    expect(parse('succ    0')).to eq(Succ.new(Zero))
  end

  specify do
    expect(parse('succ succ succ 0')).to eq(Succ.new(Succ.new(Succ.new(Zero))))
  end

  specify do
    expect(parse('pred 0')).to eq(Pred.new(Zero))
  end

  specify do
    expect(parse('iszero pred 0')).to eq(IsZero.new(Pred.new(Zero)))
  end

  specify do
    expect(parse('if iszero pred succ 0 then true else false'))
      .to eq(
        If.new(
          IsZero.new(Pred.new(Succ.new(Zero))),
          True,
          False
        )
      )
  end

  specify do
    expect(parse('x')).to eq(Var.new('x'))
  end

  specify do
    expect(parse('λx.x')).to eq(Abs.new(Var.new('x'), Var.new('x')))
  end

  specify do
    expect(parse('λx.λy.x')).to eq(Abs.new(Var.new('x'), Abs.new(Var.new('y'), Var.new('x'))))
  end

  specify do
    expect(parse('x y')).to eq(App.new(Var.new('x'), Var.new('y')))
  end

  specify do
    expect(parse('x y z')).to eq(App.new(App.new(Var.new('x'), Var.new('y')), Var.new('z')))
  end

  specify do
    pending
    expect(parse('x y z a')).to eq(App.new(App.new(App.new(Var.new('x'), Var.new('y')), Var.new('z')), Var.new('a')))
  end

  def parse(str)
    parser = Parser.new

    parser.parse(str)
  end
end
