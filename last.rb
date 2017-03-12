require 'nokogiri'
require 'pry-byebug'
require 'rest-client'
require 'csv'
require 'pg'

require_relative 'database.rb'

def integer_rank(text)
	if text.include?("正")
		return 1
	elsif text.include?("備")
		return (0 - text[/\d+/].to_i)
	else
		return 0
	end
end

#105
# "https://www.caac.ccu.edu.tw/caac105/105_kd5b_Entrance_k/html_entrance_mju/standard_html/"
#104
# "https://www.caac.ccu.edu.tw/caac104/104_Entrance_sc19/html_entrance_mc/standard_html/"
#103
# "https://www.caac.ccu.edu.tw/caac103/103_Entrance_lz15/html_lz_h8/standard_html/"
url_base = "https://www.caac.ccu.edu.tw/caac103/103_Entrance_lz15/html_lz_h8/standard_html/"
query_url = url_base + "standard_index.php"


#remember to change table name for different year
$conn.prepare('insert_statement', 'INSERT INTO dep_103 (dep_no, name, last) VALUES ($1, $2, $3)')



r = RestClient.get(query_url)
doc =  Nokogiri::HTML(r)
doc.css('table tbody tr:nth-child(n+3) td').each do |school|
	if school.css('a').empty?
		next
	end
	school_link = url_base + school.css('a').attribute('href').value
	school_name = school.css('u font').text[5..-1]

	r = RestClient.get(school_link)
	doc = Nokogiri::HTML(r)
	doc.css('table tr:nth-child(n+3)').each do |row|
		if row.css('td:first-child').text[/\d+/].nil?
			next
		end
		dep_no = row.css('td:nth-child(1)').text
		name = school_name + row.css('td:nth-child(2)').text
		last = integer_rank(row.css('td:nth-child(6)').text)

		$conn.exec_prepared('insert_statement', [dep_no, name, last])

	end
end
