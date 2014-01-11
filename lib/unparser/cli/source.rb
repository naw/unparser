# encoding: utf-8

module Unparser
  class CLI
    # Source representation for CLI sources
    class Source
      include AbstractType, Adamantium::Flat, NodeHelpers

      # Test if source could be unparsed successfully
      #
      # @return [true]
      #   if source could be unparsed successfully
      #
      # @return [false]
      #
      # @api private
      #
      def success?
        original_ast && generated_ast && original_ast == generated_ast
      end

      # Return error report
      #
      # @return [String]
      #
      # @api private
      #
      def error_report
        if original_ast && generated_ast
          error_report_with_ast_diff
        else
          error_report_with_parser_error
        end
      end
      memoize :error_report

    private

      # Return generated source
      #
      # @return [String]
      #
      # @api private
      #
      def generated_source
        Unparser.unparse(original_ast)
      end
      memoize :generated_source

      # Return error report with parser error
      #
      # @return [String]
      #
      # @api private
      #
      def error_report_with_parser_error
        if !original_ast
          "Parsing of original source failed:\n#{original_source}"
        elsif !generated_ast
          "Parsing of generated source failed:\n" \
          "Original-AST:\n#{original_ast.inspect}\n" \
          "Source:\n#{generated_source}"
        end
      end

      # Return error report with AST difference
      #
      # @return [String]
      #
      # @api private
      #
      def error_report_with_ast_diff
        diff = Differ.call(
          original_ast.inspect.lines.map(&:chomp),
          generated_ast.inspect.lines.map(&:chomp)
        )
        "#{diff}\n" \
        "Original-Source:\n#{original_source}\n" \
        "Original-AST:\n#{original_ast.inspect}\n" \
        "Generated-Source:\n#{generated_source}\n" \
        "Generated-AST:\n#{generated_ast.inspect}\n"
      end

      # Return generated AST
      #
      # @return [Parser::AST::Node]
      #   if parser was sucessful for generated ast
      #
      # @return [nil]
      #   otherwise
      #
      # @api private
      #
      def generated_ast
        Preprocessor.run(parse(generated_source))
      rescue Parser::SyntaxError
        nil
      end
      memoize :generated_ast

      # Return original AST
      #
      # @return [Parser::AST::Node]
      #
      # @api private
      #
      def original_ast
        Preprocessor.run(parse(original_source))
      rescue Parser::SyntaxError
        nil
      end
      memoize :original_ast

      # Parse source with current ruby
      #
      # @param [String] source
      #
      # @return [Parser::AST::Node]
      #
      # @api private
      #
      def parse(source)
        Parser::CurrentRuby.parse(source)
      end

      # CLI source from string
      class String < self
        include Concord.new(:original_source)

        # Return identification
        #
        # @return [String]
        #
        # @api private
        #
        def identification
          '(string)'
        end

      end # String

      # CLI source from file
      class File < self
        include Concord.new(:file_name)

        # Return identification
        #
        # @return [String]
        #
        # @api private
        #
        def identification
          "(#{file_name})"
        end

      private

        # Return original source
        #
        # @return [String]
        #
        # @api private
        #
        def original_source
          ::File.read(file_name)
        end
        memoize :original_source

      end # File
    end # Source
  end # CLI
end # Unparser
