require 'nokogiri'
require 'pry-byebug'
require 'rest-client'
require 'csv'
require 'pg'

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
url_base = "https://www.caac.ccu.edu.tw/caac105/105_kd5b_Entrance_k/html_entrance_mju/standard_html/"
query_url = url_base + "standard_index.php"

conn = PGconn.connect("localhost",5432,"","","college","postgres","1234")
conn.prepare('insert_statement', 'INSERT INTO college_name (college_no, name) VALUES ($1, $2)')


r = RestClient.get(query_url)
doc =  Nokogiri::HTML(r)
doc.css('table tbody tr:nth-child(n+3) td').each do |school|
	if school.css('a').empty?
		next
	end
	college_no = school.css('u font').text[1..3]
	name = school.css('u font').text[5..-1]

	conn.exec_prepared('insert_statement', [college_no, name])
end
