GFATools = Module.new

require "gfa"
require_relative "./gfatools/edit.rb"
require_relative "./gfatools/traverse.rb"

#
# Module defining additional methods for the GFA class.
# In the main file is only the method redefinition infrastructure
# (private methods). The public methods are in the included modules.
#
module GFATools

  include GFATools::Edit
  include GFATools::Traverse

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

  ProgramName = "RGFATools"

  def add_program_name_to_header
    set_header_field(:pn, GFATools::ProgramName)
  end

end

# The main class of RGFA. See the RGFA API documentation.
class GFA; include GFATools; end
