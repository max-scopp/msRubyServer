require 'yaml'
require 'sass'
require 'mime-types'

class URLHandler

  #
  # @since 1.0a
  def initialize url
    @url = url
    if is_file? @url
      @path = "#{PATHS[:file_drops]}#{@url}"
      ext = File.extname(@url)
      case ext
      when ".scss"
        file = File.open(@path).read
        Dir.chdir File.dirname @path do
          @output = Sass::Engine.new(file, :syntax => :scss,
                                           :style => :minified)
        end
      else @output = File.open(@path).read
      end
    else
      @template = get_matched_template

      @output = Parser.new(@template, get_template_globals)
    end
  end

  #
  # Searches for a matching url and returns it's Template path
  # relative to PATHS[:template_dir]
  #
  # @return [String, nil]
  # @since 1.0a
  def get_matched_template
    @route_file = YAML.load_file(PATHS[:route_file]) if @route_file == nil
    @route_file.each do |route|
      return route[1]["serve"] if route[1]["match"] == @url
    end
    nil
  end

  #
  # Searches for a matching url and returns it's Template path
  # relative to PATHS[:template_dir]
  #
  # @return [String, nil]
  # @since 1.0a
  def get_template_globals
    @route_file = YAML.load_file(PATHS[:route_file]) if @route_file == nil
    @route_file.each do |route|
      return route[1] if route[1]["match"] == @url
    end
    nil
  end

  #
  # checks if a url can be routed
  # @param url [String] URL to be checked
  #
  # @return [Boolean]
  # @since 1.0a
  def is_file? url
    path = "#{PATHS[:file_drops]}#{url}"
    File.exists?(path) && File.file?(path)
  end

  #
  # checks if a url can be routed
  # @param url [String] URL to be checked
  #
  # @return [Boolean]
  # @since 1.0a
  def self.routable? url
    return true if url.start_with?(CONFIG[:admin_path])
    @route_file = YAML.load_file(PATHS[:route_file]) if @route_file == nil
    @route_file.each do |route|
      return true if route[1]["match"] == url
    end
    return true if File.exists?("#{PATHS[:file_drops]}#{url}")
    false
  end

  #
  # @since 1.0a
  # @return [String] The generated Content
  def get_generated_content
    if is_file? @url
      # what a genius (°ʖ°)
      @output.render rescue @output
    else
      @output.get_content
    end
  end

  #
  # @since 1.0a
  # @return [String] Returns the Mime-Type
  def get_mime_type
    if is_file? @url
      return "text/css" if File.extname(@url) == ".scss"
      MIME::Types.of(@url).first.content_type rescue "application/octet-stream"
    else
      "text/html"
    end
  end

  #
  # @todo Make this more usefull!
  # @since 1.0a
  # @return [String] The Statuscode for the Content
  def get_response_code
    return 200
  end

end
