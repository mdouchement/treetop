dir = File.dirname(__FILE__)
$:.unshift(File.join(dir, *%w[.. lib]))
require File.expand_path(File.join(dir, 'screw', 'unit'))
require 'treetop2'
require 'rubygems'
require 'facet/string/tab'

unless Object.const_defined?(:METAGRAMMAR_2_PATH)
  METAGRAMMAR_2_PATH = File.join(TREETOP_2_ROOT, 'compiler_2', 'metagrammar.treetop')
end

include Treetop2

class CompilerTestCase < Screw::Unit::TestCase
  class << self
    attr_accessor :parser_class_under_test
    
    def testing_expression_2(expression_to_test)
      rule_node = parse_with_metagrammar_2("rule test_expression\n" + expression_to_test + "\nend", :parsing_rule)
      test_parser_code = generate_test_parser_for_expression(rule_node)
      #puts test_parser_code
      class_eval(test_parser_code)
      self.parser_class_under_test = const_get(:TestParser)
    end

    def testing_grammar_2(grammar_to_test)
      grammar_node = parse_with_metagrammar_2(grammar_to_test.strip, :grammar)
      test_parser_code = grammar_node.compile
      # puts test_parser_code
      class_eval(test_parser_code)
      self.parser_class_under_test = const_get(grammar_node.grammar_name.text_value.to_sym)
    end

    def generate_test_parser_for_expression(expression_node)
      builder = Compiler2::RubyBuilder.new
      address = builder.next_address
      expression_node.compile(builder)
      %{
        class TestParser < Treetop2::Parser::CompiledParser
          include Treetop2::Parser
          
          attr_accessor :test_index
          
          def root
            _nt_test_expression
          end
          
          def reset_index
            @index = @test_index || 0
          end
          
          #{builder.ruby.tabrestto(10)}
        end
      }.tabto(0)
    end

    def parse_with_metagrammar_2(input, root)
      parser = Treetop2::Compiler2::Metagrammar.new
      parser.send(:prepare_to_parse, input)
      node = parser.send("_nt_#{root}".to_sym)
      raise "#{input} cannot be parsed by the metagrammar." if node.failure? 
      node
    end

  end
  
  def parse_with_metagrammar_2(input, root)
    self.class.parse_with_metagrammar_2(input, root)
  end
  
  def parser_class_under_test
    self.class.parser_class_under_test
  end
  
  def parse(input, options = {})
    test_parser = parser_class_under_test.new
    test_parser.test_index = options[:at_index] if options[:at_index]
    result = test_parser.parse(input)
    yield result if block_given?
    result
  end
end

class String
  def tabrestto(n)
    self.gsub(/\n^/, "\n" + ' ' * n)
  end
end