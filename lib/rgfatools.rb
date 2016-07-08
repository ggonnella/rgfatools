RGFATools = Module.new

require "rgfa"
require_relative "./rgfatools/edit.rb"
require_relative "./rgfatools/traverse.rb"

#
# Module defining additional methods for the RGFA class.
# In the main file is only the method redefinition infrastructure
# (private methods). The public methods are in the included modules.
#
module RGFATools

  include RGFATools::Edit
  include RGFATools::Traverse

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
        alias_method :"#{em}_without_rgfatools", em
        alias_method em, :"#{em}_with_rgfatools"
        if was_private
          private em, :"#{em}_without_rgfatools", :"#{em}_with_rgfatools"
        end
      end
    end
  end

  ProgramName = "RRGFATools"

  def add_program_name_to_header
    set_header_field(:pn, RGFATools::ProgramName)
  end

end

# The main class of RRGFA. See the RRGFA API documentation.
class RGFA; include RGFATools; end
