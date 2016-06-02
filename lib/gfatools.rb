GFATools = Module.new
require "gfa"
require_relative "./gfatools/edit.rb"
require_relative "./gfatools/traverse.rb"

module GFATools

  include GFATools::Edit
  include GFATools::Traverse

  def gfatools_included?
    true
  end

end

class GFA

  include GFATools

end
