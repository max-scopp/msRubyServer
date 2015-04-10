
VERSION   = "0.1b"
BASE_DIR  = File.dirname(__FILE__)
SERVER    = "#{BASE_DIR}/server"
BLACKLIST = "#{BASE_DIR}/blacklist.txt"

CONFIG = {
  :host => "*",
  :port => 8080,
  :admin_path => "/manage", # later use, not yet implemented
  :make_unavailable => false # will always respond with Code 503
}

# my local testserver, be sure to change that!

DB = {
  :host     => "localhost",
  :user     => "blog_server",
  :database => "blog_server",
  :password => "3TaZsHXfYty2M4cZ"
}

# everything below here should not be edited

PATHS = {
  :template_dir => "#{BASE_DIR}/templates",
  :file_drops   => "#{BASE_DIR}/drops",
  :route_file   => "#{BASE_DIR}/route.yaml"
}

MESSAGE = {
  200 => "OK",
  204 => "No Content",
  301 => "Moved Permanently",
  307 => "Temporary Redirect",

  400 => "Bad Request",
  403 => "Forbidden",
  404 => "Not Found",

  500 => "Internal Server Error",
  501	=> "Not Implemented",
  503 => "Service Unavailable"
}
