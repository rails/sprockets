require 'set'

module Sprockets
  # `Utils`, we didn't know where else to put it!
  module Utils
    extend self

    # Internal: Check if string has a trailing semicolon.
    #
    # str - String
    #
    # Returns true or false.
    def string_end_with_semicolon?(str)
      i = str.size - 1
      while i >= 0
        c = str[i]
        i -= 1
        if c == "\n" || c == " " || c == "\t"
          next
        elsif c != ";"
          return false
        else
          return true
        end
      end
      true
    end

    # Internal: Accumulate asset source to buffer and append a trailing
    # semicolon if necessary.
    #
    # buf   - String memo
    # asset - Asset
    #
    # Returns appended buffer String.
    def concat_javascript_sources(buf, source)
      if string_end_with_semicolon?(buf)
        buf + source
      else
        buf + ";\n" + source
      end
    end

    # Internal: Prepends a leading "." to an extension if its missing.
    #
    #     normalize_extension("js")
    #     # => ".js"
    #
    #     normalize_extension(".css")
    #     # => ".css"
    #
    def normalize_extension(extension)
      extension = extension.to_s
      if extension[/^\./]
        extension
      else
        ".#{extension}"
      end
    end

    # Internal: Feature detect if UnboundMethods can #bind to any Object or
    # just Objects that share the same super class.
    # Basically if RUBY_VERSION >= 2.
    UNBOUND_METHODS_BIND_TO_ANY_OBJECT = begin
      foo = Module.new { def bar; end }
      foo.instance_method(:bar).bind(Object.new)
      true
    rescue TypeError
      false
    end

    # Internal: Inject into target module for the duration of the block.
    #
    # mod - Module
    #
    # Returns result of block.
    def module_include(base, mod)
      old_methods = {}

      mod.instance_methods.each do |sym|
        old_methods[sym] = base.instance_method(sym) if base.method_defined?(sym)
      end

      unless UNBOUND_METHODS_BIND_TO_ANY_OBJECT
        base.send(:include, mod) unless base < mod
      end

      mod.instance_methods.each do |sym|
        method = mod.instance_method(sym)
        base.send(:define_method, sym, method)
      end

      yield
    ensure
      mod.instance_methods.each do |sym|
        base.send(:undef_method, sym) if base.method_defined?(sym)
      end
      old_methods.each do |sym, method|
        base.send(:define_method, sym, method)
      end
    end

    # Internal: Post-order Depth-First search algorithm.
    #
    # Used for resolving asset dependencies.
    #
    # initial - Initial Array of nodes to traverse.
    # block   -
    #   node  - Current node to get children of
    #
    # Returns a Set of nodes.
    def dfs(initial)
      nodes, seen = Set.new, Set.new
      stack = Array(initial).reverse

      while node = stack.pop
        if seen.include?(node)
          nodes.add(node)
        else
          seen.add(node)
          stack.push(node)
          stack.concat(Array(yield node).reverse)
        end
      end

      nodes
    end

    def benchmark_start
      Time.now.to_f
    end

    def benchmark_end(start_time)
      ((Time.now.to_f - start_time) * 1000).to_i
    end
  end
end
