require 'date'

class FunctionCollection
  #
  # Will Print out the Console the String and returns it for the output
  #
  # @return [String] defined string in function
  # @todo remove this method!
  # @since 0.1b
  def test
    "WORKS!"
  end

  #
  # Returns ("prints") everything that will be given to this method
  #
  # @param [String] Given Arguments will be concatenated and returned
  # @return [String] Every Argument together in one String
  # @todo re-think the usefulness of this method
  # @since 0.1b
  def print(*args)
    args.join()
  end

  #
  # Calculates a given string (or concatenates all arguments to one String)
  # and returns it's result. Will remove everything besides Ruby-Syntax for
  # basic Math. Be aware it will only accept dots as commas and spaces as
  # thousand-sperator.
  #
  # @param [String] string to be stripped and calculated with Ruby-Syntax Math
  # @return [Integer,Float,nil] nil will only be returned if there is an error
  # @since 0.1b
  def calc(*args)
    calculate = args.join().gsub(/[^\d()+\-*\/.]/, '')
    # eval() rescue nil will NOT work, because it only catches subclasses
    # of the StandardError class
    begin
      eval(calculate)
    rescue Exception => exc
      nil
    end
  end

  #
  # Will convert Unix and known Date formats into a standart or given Format.
  # Formats are based on the Ruby Date/Time Formatting
  # @param date_string The String, or Unix-Timestamp String to be converted
  # @param output The Format to output the Date
  # @return [String,nil] The Formated Date as String, nil on error
  # @since 0.1b
  def date(date_string, output = nil)
    if date_string.to_i.to_s == date_string
      date = DateTime.strptime(date_string.to_i.to_s, '%s')
    else
      date = DateTime.parse(date_string)
    end

    return date.strftime("%A, %e %b %Y %H:%M") if !output rescue nil
    date.strftime(output) if !!output rescue nil
  end
end
