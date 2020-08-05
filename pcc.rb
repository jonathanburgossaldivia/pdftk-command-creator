# frozen_string_literal: true

require 'pdf-reader'
require 'pastel'

pastel = Pastel.new
CLEAR = "\e[H\e[2J"

puts CLEAR
puts ''.rjust(40, '-')
puts 'PROGRAM BY: '.rjust(40) + 'Jonathan Burgos Saldivia'
puts ''.rjust(40, '-')
puts

@hashes = {}
my_pdfs = []
commands = []
@count_matches = 0

puts 'INPUT FOLDER ARGV NOT FOUND' unless ARGV[0]
puts 'OUTPUT FOLDER ARGV NOT FOUND' unless ARGV[1]
puts 'REGEX ARGV NOT FOUND' unless ARGV[2]

unless ARGV[0] || ARGV[1] || ARGV[2]
  puts pastel.yellow.bold("\n" + 'USAGE MODE:')
  puts "ruby separador.rb /your/input_folder /your/output_folder 'YOUR REGEX'" + "\n\n"
  exit
end

input_folder = File.expand_path ARGV.first
output_folder = File.expand_path ARGV[1]
regx = Regexp.new ARGV[2]

Dir.foreach(input_folder) do |my_file|
  file_extension = File.extname(my_file)
  my_pdfs.push(input_folder + '/' + my_file) if file_extension == '.pdf'
end

def search_in(a_pdf, reg)
  reader = PDF::Reader.new(a_pdf)
  total_pages = reader.page_count
  previous_match = ''
  reader.pages.each_with_index do |page, page_number|
    page_number += 1
    page = page.to_s
    match = page.match(reg)
    if match && match.to_s != previous_match.to_s
      @hashes[match.to_s] = [page_number] # add first element
      @count_matches += 1
    elsif match && match.to_s == previous_match.to_s
      @hashes[previous_match.to_s].delete_at(1) # remove second element
      @hashes[previous_match.to_s].push(page_number) # add second element
    elsif !match
      begin
        @hashes[previous_match.to_s].delete_at(1)
        @hashes[previous_match.to_s].push(page_number) # add second element
        next
      rescue
      end

    elsif total_pages.to_s == page_number.to_s
      @hashes[previous_match.to_s].delete_at(1) # remove second element
      @hashes[previous_match.to_s].push(page_number) # last page to array
    end
    previous_match = match
  end
end

my_pdfs.each do |pdf|
  search_in(pdf, regx)
  puts pastel.yellow.bold('RESUME: ')
  if !@count_matches.zero?
    file_name = File.basename(pdf)
    puts pastel.blue.bold('FILE NAME: ') + file_name.to_s
    puts pastel.blue.bold('MATCH, [PAGE NUMBERS]: ') + @hashes.to_s
    puts
    @hashes.each .each do |key, value|
      input_file = input_folder + '/' + file_name.to_s
      output_file = output_folder + '/' + key.to_s + '_' + file_name
      commands.push('pdftk ' + '"' + input_file.to_s + '"' + ' cat ' + \
                     value.join('-') + ' output ' + '"' + output_file.to_s + '"')
    end
    @hashes.clear
  else
    puts "NO MATCHES FOUND"
    exit
  end
end

if !@count_matches.zero?
  commands = commands.map { |s| s.gsub(%r{\/\/}, '/') }
  puts pastel.yellow.bold('COMMANDS TO EXECUTE: ')
  commands.each { |info| puts info } unless commands.empty?
end
