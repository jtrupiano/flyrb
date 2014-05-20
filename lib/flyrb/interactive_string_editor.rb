# Hacktigineered by Scott Gonyea, from interactive_editor.rb -- credit still goes to:
#   Giles Bowkett, Greg Brown, and several audience members from Giles' Ruby East presentation.
require 'tempfile'
require 'flyrb'

Flyrb.equip(:interactive_editor)

class InteractiveStringEditor < InteractiveEditor
  def initialize(editor = :vim)
    @editor = editor.to_s
    @editor = "mate -w" if @editor == "mate"

    @file   = Hash.new do |k_str_obj_id, temp_file|
                k_str_obj_id[temp_file] = Tempfile.new("irb_temp_#{k_str_obj_id.to_s}")
              end
  end
  
  def init_temp_file(str_obj)
    raise ArgumentError unless String === str_obj

    temp_file = @file[str_obj.object_id.to_i]

    temp_file.rewind
    temp_file.truncate(0)
    temp_file.puts str_obj
    temp_file.fsync

    return temp_file
  end
  
  def edit_interactively(str_obj)
    begin
      temp_file = init_temp_file(str_obj)

      system("#{@editor} #{temp_file.path}")

    return `cat #{temp_file.path}`.chomp
    rescue Exception => error
      puts error
    end
  end
end

module InteractiveStringEditing
  include InteractiveEditing

  def edit_interactively(editor = InteractiveStringEditor.sensible_editor)
    unless IRB.conf[:interactive_string_editors] && IRB.conf[:interactive_string_editors][editor]
      IRB.conf[:interactive_string_editors] ||= {}
      IRB.conf[:interactive_string_editors][editor] = InteractiveStringEditor.new(editor)
    end
    IRB.conf[:interactive_string_editors][editor].edit_interactively(self)
  end

  def edit_interactively!(editor = InteractiveStringEditor.sensible_editor)
    self.replace edit_interactively(editor)
  end

  def vi!
    handling_jruby_bug {edit_interactively!(:vim)}
  end

  def mate!
    edit_interactively!(:mate)
  end

  def emacs!
    handling_jruby_bug {edit_interactively!(:emacs)}
  end
end

# Since we only intend to use this from the IRB command line, I see no reason to
# extend the entire Object class with this module when we can just extend the
# IRB main object.
self.extend InteractiveStringEditing if Object.const_defined? :IRB

class String
  include InteractiveStringEditing
end
