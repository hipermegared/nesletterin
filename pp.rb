#!/usr/bin/env ruby
######################################################################
# Premailer programilla
######################################################################

require 'rubygems'
require 'premailer'

archivo = ARGV.first
premailer = Premailer.new(archivo, :warn_level => Premailer::Warnings::SAFE, :remove_ids => true, :remove_classes => true, :remove_comments => true)

File.open(ARGV[1], "w") do |fout|
  fout.puts premailer.to_inline_css
end

#File.open("ouput.txt", "w") do |fout|
  #fout.puts premailer.to_plain_text
#end

# warnings
premailer.warnings.each do |w|
  puts "#{w[:message]} (#{w[:level]}) may not render properly in #{w[:clients]}"
end
