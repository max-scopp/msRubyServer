require 'mysql2'

class Database
  #
  # Connects to the Mysql Database as set in the Config
  # @since 1.0a
  def initialize
    @conn = Mysql2::Client.new(
      :host     => DB[:host],
      :username => DB[:user],
      :password => DB[:password],
      :database => DB[:database]
    )
  end

  #
  # Closes the Database Connection
  # @since 1.0a
  def close
    @conn.close
  end

  #
  # Checks if a Table exists in the Database
  # @return [Boolean]
  # @since 0.1b
  def table_exist? table_name
    !@conn.query("SHOW TABLES LIKE '#{table_name}'").each.empty?
  end

  #
  # Selects a Table in the Database and stored everything in the RAM
  #
  # @todo Optimize this somehow, huge Tables saved in the RAM is a bad idea
  # @since 1.0a
  def select_table table_name
    @result = @conn.query("SELECT * FROM #{table_name}")
  end

  #
  # Will retrieve all rows which has been selected with select_table()
  #
  # @return [MysqlResult]
  # @since 1.0a
  def get_rows
    @result rescue nil
  end
end
