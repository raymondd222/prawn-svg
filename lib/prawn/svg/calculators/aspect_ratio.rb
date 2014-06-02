module Prawn::Svg::Calculators
  class AspectRatio
    attr_reader :align, :defer
    attr_reader :width, :height, :x, :y

    def initialize(value, container_dimensions, object_dimensions)
      values = (value || "xMidYMid meet").strip.split(/\s+/)
      @x = @y = 0

      if values.first == "defer"
        @defer = true
        values.shift
      end

      @align, @meet_or_slice = values

      w_container, h_container = container_dimensions
      w_object,    h_object    = object_dimensions

      container_ratio = w_container / h_container
      object_ratio    = w_object / h_object

      case @align
      when /\Ax(Min|Mid|Max)Y(Min|Mid|Max)\z/
        if (container_ratio > object_ratio) == slice?
          @width, @height = [w_container, w_container / object_ratio]
          @y = -case $2
               when "Min" then 0
               when "Mid" then (h_container - w_container/object_ratio)/2
               when "Max" then h_container - w_container/object_ratio
               end
        else
          @width, @height = [h_container * object_ratio, h_container]
          @x = case $1
               when "Min" then 0
               when "Mid" then (w_container - h_container*object_ratio)/2
               when "Max" then w_container - h_container*object_ratio
               end
        end
      when 'none'
        @width, @height = container_dimensions
      else
        raise Error, "unknown preserveAspectRatio align keyword; ignoring tag"
      end
    end

    def slice?
      @meet_or_slice == "slice"
    end

    def meet?
      @meet_or_slice != "slice"
    end

    def inspect
      "[AspectRatio: #{@width},#{@height} offset #{@x},#{@y}]"
    end
  end
end
