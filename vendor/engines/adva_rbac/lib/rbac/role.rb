module Rbac
  module Role
    class << self
      def define(name, options = {})
        parent = const_get options[:parent].to_s.camelize if options[:parent]
        require_context = options[:require_context]
        require_context = require_context.role_context_class unless [NilClass, FalseClass, TrueClass].include?(require_context.class)
        
        parent ||= Rbac::Role::Base
        klass = Class.new(parent)
        
        const_set(name.to_s.camelize, klass).class_eval do
          self.require_context = require_context
          self.granter         = options[:grant]
          self.message         = options[:message]
        end
      end
      
      def build(name, options = {})
        const_get(name.to_s.camelize).new options
      end
    end
    
    class Base < ActiveRecord::Base
      self.store_full_sti_class = true
      # instantiates_with_sti
      set_table_name 'roles'
      
      belongs_to :context, :polymorphic => true

      class_inheritable_accessor :granter, :require_context, :message
      self.require_context = false
      
      class << self
        attr_writer :children
        
        def inherited(klass)
          self.children << klass
        end

        def with_children
          [self] + all_children
        end
        
        def children
          @children ||= []
        end
    
        def all_children
          children + children.map(&:all_children).flatten
        end

        def role_name
          @role_name ||= name.demodulize.downcase.to_sym
        end
      end
      
      def initialize(attrs = {})
        super()
        valid_context = attrs[:context] && attrs[:context] != Rbac::Context.root
        self.context = adjust_context attrs[:context] if valid_context
        raise "role #{self.class.name} needs a context" if require_context and !context
      end
      
      def include?(role)
        is_a?(role.class) && (!has_context or !role.has_context or context.role_context.include?(role.context.role_context))
      end

      def ==(role)
        instance_of?(role.class) && (!has_context or !role.has_context or context == role.context)
      end
      
      def has_context
        !!context
      end

      def expand(context)
        self.class.with_children.map do |klass|
          klass.new :context => context
        end.compact
      end
      
      def granted_to?(user, options = {})
        !!case granter
        when true, false
          granter
        when Symbol
          user.send granter
        when Proc
          granter.call context, user
        end || explicitely_granted_to?(user, options)
      end
      
      protected 
        def adjust_context(context)
          context = context.role_context unless context.is_a? Rbac::Context::Base
          bubble = context.class.self_and_parents.include?(require_context)
          begin
            return context.subject if !bubble or require_context == context.class
          end while context = context.parent
        end
      
        def explicitely_granted_to?(user, options = {})
          options[:inherit] = true unless options.has_key?(:inherit)
          !!user.roles.detect{|role| options[:inherit] ? role.include?(self) : role == self }
        end
    end
  end
end