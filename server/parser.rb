require 'haml'
require "#{SERVER}/database"
require "#{SERVER}/functionCollection"

class Parser
  #
  # Inits the Parser Class and the required Class-Instance Variables.
  # Will start parsing after it's done.
  #
  # @param template The template that needs to be parsed
  # @param globals A Hash of Global Variables that can occour in the Template
  # @param variables A Hash of Variables that can occour in the Template
  # @since 0.1b
  def initialize(template, globals = Hash.new, variables = Hash.new)
    template.prepend('/') unless template.start_with?('/')
    @output    = File.read("#{PATHS[:template_dir]}#{template}")
    @globals   = globals
    @variables = variables

    parse_scripts
  end

  #
  # Will parse the Template, or the given Snippet
  #
  # @param string_snippet WIP! The Snipped that should be parsed
  # @todo Add the Snipped functionallity
  # @since 0.1b
  def parse_scripts(string_snippet = nil)
    insert_includes
    insert_globals
    insert_variables
    handle_loops
    insert_urls
    execute_functions
  end

  #
  # Will match functions using regex and executes them if their defined in
  # the FunctionCollection Class. Will return the unchanged matched String if
  # the given function doesn't exist
  #
  # @return [String] The Result of the Function, or the unchanged String
  # @since 0.1b
  def execute_functions
    # match functions like func(args);
    @output = @output.gsub(/(\w+)\("?(.*)"?\)\;/) {|row|
      function_name       = Regexp.last_match[1]
      function_parameters = Regexp.last_match[2]

      return_content = ""

      functions = FunctionCollection.new
      args = function_parameters.split(/,/)
      if functions.respond_to? :"#{function_name}"
        functions.send("#{function_name}", *args)
      else
        row
      end
    }
  end

  #
  # Will match loops using regex and handles them
  #
  # @return [String] Returns the generated Loop Content
  # @since 0.1b
  def handle_loops
    @output = @output.gsub(/=# each (.+) do (.+):([^-]*[^}]*)\n.*=# end/i) {
      table_name  = Regexp.last_match[1]
      looper_name = Regexp.last_match[2]
      template    = Regexp.last_match[3]
      database    = Database.new

      generated_loop_content = ""

      if database.table_exist?(table_name)
        database.select_table(table_name)

        database.get_rows.each { |row|
          generated_loop_content << template.gsub(/(.+)\[{3}(\w+)\.(\w+)\]{3}/) {
            loop_intend   = Regexp.last_match[1]
            loop_name     = Regexp.last_match[2]
            loop_variable = Regexp.last_match[3]

            if loop_name == looper_name
              loop_intend + row[loop_variable].to_s.gsub(/[\r\n]+/,
                "\n" + loop_intend) rescue loop_intend
            else
              "invalid looper name \"#{loop_name}\"(#{loop_variable})"
            end
          }
        }
      else
        Log.warn "Not existing Table in Template \"#{table_name}\"".yellow
      end

      database.close
      generated_loop_content
    }
  end

  #
  # Will match includes using regex and inserts the targeted file
  #
  # @return [String] Returns the File-Content of the files looking for
  # @since 0.1b
  def insert_includes
    # match all variables, every variable begins with an at (@).
    # variables can also end with a semicolon to have a safe declaration.
    @output = @output.gsub(/\<(.+)\>/) {
      match = Regexp.last_match[1]
      match.prepend('/') unless match.start_with?('/')
      IO.read("#{PATHS[:template_dir]}#{match}")
    }
  end

  #
  # Will match global Variables using regex and replaces with it's content
  #
  # @return [String] The global Variable, or an empty String if not defined
  # @since 0.1b
  def insert_globals
    # match all global variables, every variable begins with an at (@).
    # variables can also end with a semicolon to have a safe declaration.
    @output = @output.gsub(/\[{3}\@(\w+)\]{3}/).each {
      match = Regexp.last_match[1]
      @globals[match] || ""
    }
  end

  #
  # Will match variables using regex and replaces them with it's content
  #
  # @return [String] The Variable, or an empty String if it's not defined
  # @since 0.1b
  def insert_variables
    # match all variables, every variable begins with an at (@).
    # variables can also end with a semicolon to have a safe declaration.
    @output = @output.gsub(/\[{3}(\w+)\]{3}/) {
      match = Regexp.last_match[1]
      @variables[match] || ""
    }
  end

  #
  # Will match links like self:// and replaces it with the IP and
  # Port (if not 80) that the Client connected to the Server
  #
  # @return [String] The Url
  # @since 0.1b
  def insert_urls
    # match all variables, every variable begins with an at (@).
    # variables can also end with a semicolon to have a safe declaration.
    ip = Thread.current['client'].connect_address.ip_address
    port = Thread.current['client'].connect_address.ip_port
    @output = @output.gsub(/self\:\/\//) {
      "http://#{ip}#{":" + port.to_s if port != 80}/"
    }
  end

  #
  # Parses the generated HAML Code and returns it as String,
  # on an Error, nil is going to be returned
  #
  # @return [String, nil] The Parsed Content
  # @since 0.1b
  def get_content
    begin
      @output = Haml::Engine.new(@output).render
    rescue Exception => e
      line_num = 0
      @output.each_line { |line|
        line_num += 1
        Log << "#{line_num.to_s.rjust(3)}| #{line}"
      }
      Log.error "#{e.message.red} #{e.backtrace.join("\n\t")}"
      nil
    end
  end
end
