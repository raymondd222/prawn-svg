class Prawn::Svg::Document
  include Prawn::Measurements

  begin
    require 'css_parser'
    CSS_PARSER_LOADED = true
  rescue LoadError
    CSS_PARSER_LOADED = false
  end

  DEFAULT_FALLBACK_FONT_NAME = "Times-Roman"

  # An +Array+ of warnings that occurred while parsing the SVG data.
  attr_reader :warnings
  attr_writer :url_cache

  attr_reader :root,
    :x_offset, :y_offset, :x_scale, :y_scale,
    :output_width, :output_height,
    :cache_images, :fallback_font_name,
    :css_parser, :elements_by_id

  def initialize(data, bounds, options)
    @css_parser = CssParser::Parser.new if CSS_PARSER_LOADED

    @root = REXML::Document.new(data).root
    @warnings = []
    @options = options
    @elements_by_id = {}
    @cache_images = options[:cache_images]
    @fallback_font_name = options.fetch(:fallback_font_name, DEFAULT_FALLBACK_FONT_NAME)
    @x_offset = @y_offset = 0
    @x_scale = @y_scale = 1

    if viewbox = @root.attributes['viewBox']
      values = viewbox.strip.split(/\s+/)
      @x_offset, @y_offset, @viewport_width, @viewport_height = values.map {|value| value.to_f}
      @x_offset = -@x_offset
    end

    width = points(@root.attributes['width'], bounds[0])
    height = points(@root.attributes['height'], bounds[1])

    defaultPreserveAspectRatio = "x#{width ? "Mid" : "Min"}Y#{height ? "Mid" : "Min"} meet"

    width ||= bounds[0]
    height ||= bounds[1]

    if viewbox
      preserveAspectRatio = @root.attributes['preserveAspectRatio'] || defaultPreserveAspectRatio
      aspect = Prawn::Svg::Calculators::AspectRatio.new(preserveAspectRatio, [width, height], [@viewport_width, @viewport_height])
      @x_scale = aspect.width / @viewport_width
      @y_scale = aspect.height / @viewport_height
      @x_offset -= aspect.x
      @y_offset += aspect.y
    end

    @viewport_width ||= width
    @viewport_height ||= height

    if @options[:width]
      scale = @options[:width] / width
      width = @options[:width]
      height *= scale
      @x_scale *= scale
      @y_scale *= scale

    elsif @options[:height]
      scale = @options[:height] / height
      height = @options[:height]
      width *= scale
      @x_scale *= scale
      @y_scale *= scale
    end

    @output_width = width
    @output_height = height

    yield self if block_given?
  end

  def x(value)
    points(value, :x)
  end

  def y(value)
    @output_height - points(value, :y)
  end

  def distance(value, axis = nil)
    value && points(value, axis)
  end

  def points(value, axis = nil)
    if value.is_a?(String)
      if match = value.match(/\d(cm|dm|ft|in|m|mm|yd)$/)
        send("#{match[1]}2pt", value.to_f)
      elsif match = value.match(/\dpc$/)
        value.to_f * 15 # according to http://www.w3.org/TR/SVG11/coords.html
      elsif value[-1..-1] == "%"
        length = case axis
                 when :x, nil then @viewport_width
                 when :y      then @viewport_height
                 else              axis
                 end

        value.to_f * length / 100.0
      else
        value.to_f
      end
    elsif value
      value.to_f
    end
  end

  def url_loader
    @url_loader ||= Prawn::Svg::UrlLoader.new(:enable_cache => cache_images)
  end
end
