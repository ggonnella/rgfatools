GFATools = Module.new
require "gfa"
require_relative "./gfatools/edit.rb"
require_relative "./gfatools/traverse.rb"

module GFATools

  ProgramName = "RGFATools"

  def gfatools_included?
    true
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

  private

  def add_program_name_to_header
    set_header_field(:pn, GFATools::ProgramName)
  end

end

class GFA

  include GFATools

end
