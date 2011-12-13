# Copyright 2008 Chris Wanstrath
# Taken from defunkt's gist repository: http://github.com/defunkt/gist/tree/master

require 'open-uri'
require 'net/http'

module Gist
  extend self

  @@gist_url = 'http://gist.github.com/%s.txt'
  @@files = []

  def read(gist_id)
    open(@@gist_url % gist_id).read
  end
  
  def add_file(name, content)
    load_files
    @@files << {:name => name, :content => content}
    puts "#{name} added."
    save_files
  end
  
  def write(private_gist)
    load_files
    url = URI.parse('http://gist.github.com/gists')
    req = Net::HTTP.post_form(url, data(private_gist))
    url = copy req['Location']
    puts "Created gist at #{url}. URL copied to clipboard."
    clear
  end
  
  def clear
    @@files = []
    save_files
  end
  
  def process_selection
    selection = nil
    gistname = nil
    if ENV['TM_SELECTED_TEXT']
      selection = ENV['TM_SELECTED_TEXT']
      gistname = "snippet" << "." << get_extension
    else
      selection = STDIN.read
      gistname = ENV['TM_FILEPATH'] ? ENV['TM_FILEPATH'].sub(ENV['TM_PROJECT_DIRECTORY'], '') : "file" << "." << get_extension
    end
    
    add_file(gistname, selection)
  end
  
  # Add extension for supported modes based on TM_SCOPE
  # Cribbed from http://github.com/defunkt/gist.el/tree/master/gist.el
  def get_extension
    scope = ENV["TM_SCOPE"].split[0]
    case scope
    when /source\.actionscript/ then "as"
    when /source\.c/, /source\.objc/ then "c"
    when /source\.c\+\+/, /source\.objc\+\+/ then "cpp"
    # common-lisp-mode then "el"
    when /source\.css/ then "css"
    when /source\.diff/, "meta.diff.range" then "diff"
    # emacs-lisp-mode then "el"
    when /source\.erlang/ then "erl"
    when /source\.haskell/, "text.tex.latex.haskel" then "hs"
    when /text\.html/ then "html"
    when /source\.io/ then "io"
    when /source\.java/ then "java"
    when /source\.js/ then "js"
    # jde-mode then "java"
    # js2-mode then "js"
    when /source\.lua/ then "lua"
    when /source\.ocaml/ then "ml"
    when /source\.objc/, "source.objc++" then "m"
    when /source\.perl/ then "pl"
    when /source\.php/ then "php"
    when /source\.python/ then "sc"
    when /source\.ruby/ then "rb" # Emacs bundle uses rbx
    when /text\.plain/ then "txt"
    when /source\.sql/ then "sql"
    when /source\.scheme/ then "scm"
    when /source\.smalltalk/ then "st"
    when /source\.shell/ then "sh"
    when /source\.tcl/, "text.html.tcl" then "tcl"
    when /source\.lex/ then "tex"
    when /text\.xml/, /text\.xml\.xsl/, /source\.plist/, /text\.xml\.plist/ then "xml"
    else "txt"
    end
  end

private
  def load_files
    path = File.join(File.dirname(__FILE__), 'tmp_gists')
    save_files unless File.exists?(path)
    @@files = Marshal.load(File.read(path))
    @@files ||= []
  end
  
  def save_files
    path = File.join(File.dirname(__FILE__), 'tmp_gists')
    File.open(path, 'w') {|f| f.puts Marshal.dump(@@files) }
  end
  
  def copy(content)
    return content if `which pbcopy`.strip == ''
    IO.popen('pbcopy', 'r+') { |clip| clip.puts content }
  	content
  end

  def data(private_gist)
    params = {}
    @@files.each_with_index do |file, i|
      params.merge!({
        "file_ext[gistfile#{i+1}]"      => nil,
        "file_name[gistfile#{i+1}]"     => file[:name],
        "file_contents[gistfile#{i+1}]" => file[:content]
      })
    end
    params.merge(private_gist ? { 'private' => 'on' } : {}).merge(auth)
  end

  def auth
    user  = `git config --global github.user`.strip
    token = `git config --global github.token`.strip

    user.empty? ? {} : { :login => user, :token => token }
  end
end

