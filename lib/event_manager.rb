# # contents = File.read('event_attendees.csv')
# # puts contents

# # contents = File.exist? "event_attendees.csv"
# # puts contents

# # Below: to remove the first row but if the content of the header changes it stops working

# # lines = File.readlines('event_attendees.csv')
# # lines.each do |line|
# #   next if line == " ,RegDate,first_Name,last_Name,Email_Address,HomePhone,Street,City,State,Zipcode\n"
# #   columns = line.split(",")
# #   name = columns[2]
# #   p name
# # end

# # Below: solves the problem above by using index instead of string

# # lines = File.readlines('event_attendees.csv')
# # row_index = 0
# # lines.each do |line|
# #   row_index = row_index + 1
# #   next if row_index == 1
# #   columns = line.split(",")
# #   name = columns[2]
# #   p name
# # end

# # Above -> can also use below:

# # lines = File.readlines('event_attendees.csv')
# # lines.each_with_index do |line,index|
# #   next if index == 0
# #   columns = line.split(",")
# #   name = columns[2]
# #   puts name
# # end

# # --------------------------------------------------
# # switching to using csv instead of accessing manually
# require 'csv'
# puts 'EventManager initialized.'

# # contents = CSV.open('event_attendees.csv', headers: true) # ==> opens the document and supports headers, so this informs
# # contents.each do |row|
# #   name = row[2]
# #   puts name
# # end


# # accessing columns by their names, first converting header names to symbols to make more uniform
# # displaying the Zip codes of All attendees, with clean code
# contents = CSV.open(
#   'event_attendees.csv',
#   headers: true,
#   header_converters: :symbol
# )

# contents.each do |row|
#   name = row[:first_name]
#   zipcode = row[:zipcode]

#   if zipcode.nil? # ==> this checks if no postcode is provided ( == nil) so that nil.length does not give error
#     zipcode = '00000'
#   elsif zipcode.length < 5 
#     zipcode = zipcode.rjust(5, '0') # ==> adds a 0 if the zipcode is shorter
#   elsif zipcode.length > 5
#     zipcode = zipcode[0..4] # ==> cuts anything after 5th
#   end
#   puts "#{name} #{zipcode}"
# end


# # moving clean zip codes to a method

# # def clean_zipcode(zipcode) #            ==> def clean_zipcode(zipcode) ==> shorter version, can be applied to all as these methods will not work on strings of 5
#                              #                  zipcode.to_s.rjust(5, '0')[0..4]
#                              #                end
# #   if zipcode.nil?
# #     '00000'
# #   elsif zipcode.length < 5
# #     zipcode.rjust(5, '0')
# #   elsif zipcode.length > 5
# #     zipcode[0..4]
# #   else 
# #     zipcode
# #   end
# # end

# # puts 'EventManager initialized.'

# # contents = CSV.open(
# #   'event_attendees.csv',
# #   headers: true, 
# #   header_converters: :symbol
# # )

# # contents.each do |row|
# #   name = row[:first_name]
# #   zipcode = clean_zipcode(row[:zipcode])
# #   puts "#{name} #{zipcode}"
# # end

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def get_hour(regdate)
  regdate = DateTime.strptime(regdate, "%m/%d/%Y %k:%M")
  regdate.hour
end

def get_wday(regdate)
  regdate = DateTime.strptime(regdate, "%m/%d/%Y %k:%M")
  Date::DAYNAMES[regdate.wday]
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_homephone(homephone)
  homephone = homephone.to_s.gsub(/[^0-9]/, '') # regular expression, '^' anything that is not. '/[]/' anything that is.
  if homephone == ''
    'Invalid/Not provided'
  elsif homephone.length < 10
    'Invalid/Not provided'
  elsif homephone.length > 11
    'Invalid/Not provided'
  elsif homephone.length > 10
    if homephone[0] == '1'
      homephone[1..10]
    else
      'Invalid/Not provided'
    end
  else
    homephone
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

all_hours = []
all_days = []

contents.each do |row|
  id = row[0]
  hour = get_hour(row[:regdate])
  all_hours << hour
  wday = get_wday(row[:regdate])
  all_days << wday
  name = row[:first_name]
  homephone = clean_homephone(row[:homephone])
  # puts "#{row[:homephone]} ---> #{homephone}" to check if it works
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

frequencies = Hash.new(0)
all_hours.each do |hour|
  frequencies[hour] += 1
end

puts frequencies

day_frequencies = Hash.new(0)
all_days.each do |day|
  day_frequencies[day] += 1
end

puts day_frequencies
