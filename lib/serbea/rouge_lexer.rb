# frozen_string_literal: true

require "rouge"

module Rouge
  module Lexers
    class Serbea < TemplateLexer
      title "Serbea"
      desc "Embedded Ruby Serbea template files"

      tag 'serb'

      filenames '*.serb'

      def initialize(opts={})
        @ruby_lexer = Ruby.new(opts)

        super(opts)
      end

      start do
        parent.reset!
        @ruby_lexer.reset!
      end

      open  = /{%%|{%=|{%#|{%-|{%|{{/
      close = /%%}|-%}|%}|}}/

      state :root do
        rule %r/{%#/, Comment, :comment

        rule open, Comment::Preproc, :ruby

        rule %r/.+?(?=#{open})|.+/m do
          delegate parent
        end
      end

      state :comment do
        rule close, Comment, :pop!
        rule %r/.+?(?=#{close})|.+/m, Comment
      end

      state :ruby do
        rule close, Comment::Preproc, :pop!

        rule %r/.+?(?=#{close})|.+/m do
          delegate @ruby_lexer
        end
      end
    end
  end
end