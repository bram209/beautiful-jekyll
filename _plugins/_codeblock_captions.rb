
require 'rouge'

module Jekyll
 
  class CodeBlock < Liquid::Block
    CaptionUrlTitle = /(\S[\S\s]*)\s+(https?:\/\/\S+|\/\S+)\s*(.+)?/i
    Caption = /(\S[\S\s]*)/
    def initialize(tag_name, markup, tokens)
      @title = nil
      @caption = nil
      @filetype = nil
      @highlight = true
      if markup =~ /\s*lang:(\S+)/i
        @filetype = $1
        markup = markup.sub(/\s*lang:(\S+)/i,'')
      end
      if markup =~ CaptionUrlTitle
        @file = $1
        @caption = "<figcaption><span>#{$1}</span><a href='#{$2}'>#{$3 || 'link'}</a></figcaption>"
      elsif markup =~ Caption
        @file = $1
        @caption = "<figcaption><span>#{$1}</span></figcaption>\n"
      end
      if @file =~ /\S[\S\s]*\w+\.(\w+)/ && @filetype.nil?
        @filetype = $1
      end
      super
    end
 
    def render(context)
      output = super
      code = super
      code = code.strip
      source = "<figure class='code'>"
      source += @caption if @caption
      formatter = Rouge::Formatters::HTML.new(css_class: 'highlight')
      lexer = Rouge::Lexer.find(@filetype)
      source += formatter.format(lexer.lex(code))
      source += "</figure>"
      source
    end
  end
end
 
Liquid::Template.register_tag('codeblock', Jekyll::CodeBlock)