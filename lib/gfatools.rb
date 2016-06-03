GFATools = Module.new
require "gfa"
require_relative "./gfatools/edit.rb"
require_relative "./gfatools/traverse.rb"

module GFATools

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

end

class GFA

  include GFATools
  include GFATools::Edit
  include GFATools::Traverse

end
