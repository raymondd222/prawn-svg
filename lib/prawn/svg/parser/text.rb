class Prawn::Svg::Parser::Text
  def parse(element)
    element.add_call_and_enter "text_group"
    internal_parse(element, [element.document.x(0)], [element.document.y(0)], false)
  end

  protected
  def internal_parse(element, x_positions, y_positions, relative)
    return if element.state[:display] == "none"

    attrs = element.attributes

    if attrs['x'] || attrs['y']
      relative = false
      x_positions = attrs['x'].split(/[\s,]+/).collect {|n| element.document.x(n)} if attrs['x']
      y_positions = attrs['y'].split(/[\s,]+/).collect {|n| element.document.y(n)} if attrs['y']
    end

    if attrs['dx'] || attrs['dy']
      element.add_call_and_enter "translate", element.document.distance(attrs['dx'] || 0), -element.document.distance(attrs['dy'] || 0)
    end

    opts = {}
    if size = element.state[:font_size]
      opts[:size] = size
    end
    opts[:style] = element.state[:font_subfamily]
    if letter_spacing = element.attributes['letter-spacing']
      opts[:letter_spacing] = letter_spacing.to_i
    else
      opts[:letter_spacing] = 0
    end

    # This is not a prawn option but we can't work out how to render it here -
    # it's handled by Svg#rewrite_call_arguments
    if anchor = attrs['text-anchor']
      opts[:text_anchor] = anchor
    end

    element.element.children.each do |child|
      if child.node_type == :text
        text = child.value

        if letter_spacing && letter_spacing.to_i != 0
          for i in 0..text.length-1
            opts[:at] = [x_positions.first, y_positions.first]
            element.add_call i > 0 ? 'relative_draw_text' : 'draw_text', text[i], opts.dup
          end

        else

          while text != ""
            opts[:at] = [x_positions.first, y_positions.first]

            if x_positions.length > 1 || y_positions.length > 1
              element.add_call 'draw_text', text[0..0], opts.dup
              text = text[1..-1]

              x_positions.shift if x_positions.length > 1
              y_positions.shift if y_positions.length > 1
            else
              element.add_call relative ? 'relative_draw_text' : 'draw_text', text, opts.dup
              relative = true
              break
            end
          end
        end
      elsif child.name == "tspan"
        element.add_call 'save'
        child.attributes['text-anchor'] ||= opts[:text_anchor] if opts[:text_anchor]
        child_element = Prawn::Svg::Element.new(element.document, child, element.calls, element.state.dup)
        internal_parse(child_element, x_positions, y_positions, relative)
        child_element.append_calls_to_parent
        element.add_call 'restore'

      else
        element.warnings << "Unknown tag '#{child.name}' inside text tag; ignoring"
      end
    end
  end
end
