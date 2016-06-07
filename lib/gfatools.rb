GFATools = Module.new

require "gfa"
require_relative "./gfatools/edit.rb"
require_relative "./gfatools/traverse.rb"

module GFATools

  include GFATools::Edit
  include GFATools::Traverse

  ProgramName = "RGFATools"

  private

  def self.included(mod)
    included_modules.each do |im|
      self.redefine_methods(eval("#{im}::Redefined"), mod)
    end
  end

  def self.redefine_methods(extended_methods, mod)
    mod.class_eval do
      extended_methods.each do |em|
        was_private = mod.private_instance_methods.include?(em)
        public em
        alias_method :"#{em}_without_gfatools", em
        alias_method em, :"#{em}_with_gfatools"
        if was_private
          private em, :"#{em}_without_gfatools", :"#{em}_with_gfatools"
        end
      end
    end
  end

  def add_program_name_to_header
    set_header_field(:pn, GFATools::ProgramName)
  end

end

class GFA; include GFATools; end
