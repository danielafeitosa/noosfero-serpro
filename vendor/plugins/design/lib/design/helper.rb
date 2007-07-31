module Design

  module Helper

    # proxies calls to controller's design method
    def design
      @controller.send(:design)
    end

    ########################################################
    # Boxes and Blocks related
    ########################################################

    # Displays +content+ inside the design used by the controller. Normally
    # you'll want use this method in your layout view, like this:
    #
    #   <%= design_display(yield) %>
    #
    # +content+ will be put inside all the blocks which return +true+ in the
    # Block.main? method.
    #
    # The number of boxes generated will be no larger than the maximum number
    # supported by the template, which is indicated in its YAML description
    # file.
    #
    # If not blocks are present (e.g. the design holder has no blocks yet),
    # +content+ is returned right away.
    def design_display(content = "")

      # no blocks. nothing to be done
      return content if design.boxes.empty?

      # Generate all boxes of the current profile and considering the defined
      # on template.

      design.boxes.map do |box|
        content_tag(:div, design_display_blocks(box, content) , :id=>"box_#{box.number}")
      end.join("\n")
    end

    # Displays all the blocks in a box.
    #   <ul id="sort#{number of the box}">
    #     <li class="block_item_box_#{number of the box}" id="block_#{id of block}">
    #     </li>
    #   </ul>
    #
    def design_display_blocks(box, content = "")
      blocks = box.blocks_sort_by_position
      content_tag(:div,
        blocks.map { |b|
         content_tag(:div, b.main? ? content : self.send('list_content', b.content), :class =>"block_item_box_#{box.number}" , :id => "block_#{b.id}" )
        }.join("\n"), :id => "frame_#{box.number}"
      )
    end


    ########################################################
    # Template
    ########################################################
    # Load all the javascript files of a existing template with the template_name passed as argument.
    #
    # The files loaded are in the path:
    #
    # 'public/templates/#{template_name}/javascripts/*'
    #
    # If a invalid template it's passed the default template is applied
    def javascript_include_tag_for_template
      template_javascript_dir = Dir.glob("#{RAILS_ROOT}/public/templates/#{@ft_config[:template]}/javascripts/*.js")

      return if template_javascript_dir.blank?

      parse_path(template_javascript_dir).map do |filename|
        javascript_include_tag(filename)
      end
    end

    # Load all the css files of a existing template with the template_name passed as argument.
    #
    # The files loaded are in the path:
    #
    # 'public/templates/#{template_name}/stylesheets/*'
    # If a invalid template it's passed the default template is applied
    def stylesheet_link_tag_for_template
      template_stylesheet_dir = Dir.glob("#{RAILS_ROOT}/public/templates/#{@ft_config[:template]}/stylesheets/*.css")

      if template_stylesheet_dir.blank?
        flash[:notice] = _("There is no stylesheets in directory %s of template %s.") % [ template_stylesheet_dir, @ft_config[:template]]
        return
      end

      parse_path(template_stylesheet_dir).map do |filename|
        stylesheet_link_tag(filename)
      end
    end


    #################################################
    #THEMES 
    #################################################

    # Load all the css files of a existing theme with the @ft_config[:theme] passed as argument in owner object.
    #
    # The files loaded are in the path:
    #
    # 'public/themes/#{theme_name}/*'
    # If a invalid theme it's passed the 'default' theme is applied
    def stylesheet_link_tag_for_theme
      path = "#{RAILS_ROOT}/public/themes/#{@ft_config[:theme]}/"
      theme_dir = Dir.glob(path+"*")

      return if theme_dir.blank?

      parse_path(theme_dir).map do |filename|
        stylesheet_link_tag(filename)
      end

    end


    #Display a given icon passed as argument
    #The icon path should be '/icons/{icon_theme}/{icon_image}'
    def display_icon(icon, options = {})
      image_tag("/icons/#{@ft_config[:icon_theme]}/#{icon}.png", options)
    end

    private
 

    # Check if the current controller is the controller that allows layout editing
    def edit_mode?
      controller.flexible_template_edit_template?
    end 

    def parse_path(files_path = [], remove_until = 'public')
      remove_until = remove_until.gsub(/\//, '\/')
      files_path.map{|f| f.gsub(/.*#{remove_until}/, '')}
    end


  end # END SHOW TEMPLATE HELPER

  module EditTemplateHelper


    # Symbol dictionary used on select when we add or edit a block.
    # This method has the responsability of translate a Block class in a humam name
    # By default the class "MainBlock" has the human name "Main Block". Other classes
    # defined by user are not going to display in a human name format until de method
    # flexible_template_block_dict be redefined in a controller by user

#TODO define the method flexible_template_block_dict if not defined by helper
#    if !self.public_instance_methods.include? "flexible_template_block_dict"
#      define_method('flexible_template_block_dict') do |str|
#        {
#          'MainBlock' => _("Main Block")
#        }[str] || str
#      end
#    end 


    def flexible_template_block_helper_dict(str)
      {
        'plain_content' => _('Plain Content') ,
        'list_content' => _('List Content')
      }[str] || str
    end


    private 

    #################################################
    # TEMPLATES METHODS RELATED
    #################################################

    # Shows the blocks as defined in <tt>show_blocks</tt> adding the sortable and draggable elements.
    # In this case the layout can be manipulated
    def edit_blocks(box, main_content = "")
      blocks = box.blocks_sort_by_position
      [
       content_tag(
        :ul,[ 
        box.name,
        link_to_active_sort(box),
        link_to_add_block(box),
        blocks.map {|b|
          [content_tag(
            :li, 
            b.name + link_to_destroy_block(b),
            :class =>"block_item_box_#{box.number}" , :id => "block_#{b.id}"
          ),
          draggable("block_#{b.id}")].join("\n")
        }.join("\n")].join("\n"), :id => "sort_#{box.number}"
      ), 
      drag_drop_items(box)].join("\n")
    end

    def link_to_active_sort(box)
      link_to_remote(_('Sort'),
        {:update => "sort_#{box.number}", :url => {:action => 'flexible_template_set_sort_mode', :box_id => box.id }},
        :class => 'sort_button') 
    end

    def link_to_add_block(box)
      link_to_remote(_('Add Block'),
        {:update => "sort_#{box.number}", :url => {:action => 'flexible_template_new_block', :box_id => box.id }},
        :class => 'add_block_button')
    end

    def link_to_destroy_block(block)
      link_to_remote(_('Remove'),
        {:update => "sort_#{block.box.number}", :url => {:action => 'flexible_template_destroy_block', :block_id => block.id }},
        :class => 'destroy_block_button')
    end


    # Allows the biven box to have sortable elements
    def sortable_block(box_number)
      sortable_element "sort_#{box_number}",
      :url => {:action => 'flexible_template_sort_box', :box_number => box_number },
      :complete => visual_effect(:highlight, "sort_#{box_number}")
    end

    # Allows an element item to be draggable
    def draggable(item)
      draggable_element(item, :ghosting => true, :revert => true)
    end

    # Allows an draggable element change between diferrents boxes
    def drag_drop_items(box)
      boxes =  @ft_config[:boxes].reject{|b| b.id == box.id}

      boxes.map{ |b|
        drop_receiving_element("box_#{box.number}",
          :accept     => "block_item_box_#{b.number}",
          :complete   => "$('spinner').hide();",
          :before     => "$('spinner').show();",
          :hoverclass => 'hover',
          :with       => "'block=' + encodeURIComponent(element.id.split('_').last())",
          :url        => {:action=>:flexible_template_change_box, :box_id => box.id})
        }.to_s
    end


    # Generate a select option to choose one of the available templates.
    # The available templates are those in 'public/templates'
    def select_template
      available_templates = @ft_config[:available_templates]

      template_options = options_for_select(available_templates.map{|template| [template, template] }, @ft_config[:template])
      [ select_tag('template_name', template_options ),
        change_template].join("\n")
    end

    # Generate a observer to reload a page when a template is selected
    def change_template
      observe_field( 'template_name',
        :url => {:action => 'set_default_template'},
        :with =>"'template_name=' + escape(value) + '&object_id=' + escape(#{@ft_config[:owner].id})",
        :complete => "document.location.reload();"
      )
    end

    def available_blocks
#TODO check if are valids blocks
      h = {
        'MainBlock' => _("Main Block"),
      }
      h.merge!(controller.class::FLEXIBLE_TEMPLATE_AVAILABLE_BLOCKS) if controller.class.constants.include? "FLEXIBLE_TEMPLATE_AVAILABLE_BLOCKS"
      h
    end

    def block_helpers
#TODO check if are valids helpers
      h = {
        'plain_content' => _("Plain Content"),
        'list_content' => _("Simple List Content"),
      }
      h.merge!(controller.class::FLEXIBLE_TEMPLATE_BLOCK_HELPER) if controller.class.constants.include? "FLEXIBLE_TEMPLATE_BLOCK_HELPER"
      h
    end

    def new_block_form(box)
      type_block_options = options_for_select(available_blocks.collect{|k,v| [v,k] })
      type_block_helper_options = options_for_select(block_helpers.collect{|k,v| [v,k] })
      @block = Block.new
      @block.box = box 

      _("Adding block on %s") % box.name +
      [
        form_remote_tag(:url => {:action => 'flexible_template_create_block'}, :update => "sort_#{box.number}"),   
          hidden_field('block', 'box_id'),
          content_tag(
            :p,
            [   
              content_tag(
                :label, _('Name:')
              ),
              text_field('block', 'name')
            ].join("\n")
          ),
          content_tag(
            :p,
            [   
              content_tag(
                :label, _('Title:')
              ),
              text_field('block', 'title')
            ].join("\n")
          ),
          content_tag(
            :p,
            [   
              content_tag(
                :label, _('Type:')
              ),
              select_tag('block[type]', type_block_options)
            ].join("\n")
          ),
          content_tag(
            :p,
            [   
              content_tag(
                :label, _('Visualization Mode:')
              ),
              select_tag('block[helper]', type_block_helper_options)
            ].join("\n")
          ),
          submit_tag( _('Submit')),
        end_form_tag
      ].join("\n")

    end

    # Generate a select option to choose one of the available themes.
    # The available themes are those in 'public/themes'
    def select_theme
      available_themes = @ft_config[:available_themes]
      theme_options = options_for_select(available_themes.map{|theme| [theme, theme] }, @ft_config[:theme])
      [ select_tag('theme_name', theme_options ),
        change_theme].join("\n")
    end

    # Generate a observer to reload a page when a theme is selected
    def change_theme
      observe_field( 'theme_name',
        :url => {:action => 'set_default_theme'},
        :with =>"'theme_name=' + escape(value) + '&object_id=' + escape(#{@ft_config[:owner].id})",
        :complete => "document.location.reload();"
      )
    end


    #################################################
    #ICONS THEMES RELATED
    #################################################

    # Generate a select option to choose one of the available icons themes.
    # The available icons themes are those in 'public/icons'
    def select_icon_theme
      available_icon_themes = @ft_config[:available_icon_themes]
      icon_theme_options = options_for_select(available_icon_themes.map{|icon_theme| [icon_theme, icon_theme] }, @ft_config[:icon_theme])
      [ select_tag('icon_theme_name', icon_theme_options ),
        change_icon_theme].join("\n")
    end

    # Generate a observer to reload a page when a icons theme is selected
    def change_icon_theme
      observe_field( 'icon_theme_name',
        :url => {:action => 'set_default_icon_theme'},
        :with =>"'icon_theme_name=' + escape(value) + '&object_id=' + escape(#{@ft_config[:owner].id})",
        :complete => "document.location.reload();"
      )
    end


  end # END OF module HElper


end #END OF module Design
