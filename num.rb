require 'nokogiri'
require 'pry-byebug'
require 'rest-client'
require 'csv'
require 'pg'

require_relative 'database.rb'

year = "103"
query_url = "https://freshman.tw/cross/" + year + "/"

$conn.prepare('update_statement', 'UPDATE dep_103 SET max_num = $1, waiting_num = $2, real_num = $3 WHERE dep_no = $4')
$conn.prepare('insert_statement', 'INSERT INTO dep_' + year + ' (dep_no, name, college_no, max_num, waiting_num, real_num, year) VALUES($1, $2, $3, $4, $5, $6, $7)')


#get links of all department
dep_links = []

r = RestClient.get(query_url)
doc =  Nokogiri::HTML(r)

doc.css('.card-columns .card-block').each do |school|
	if school.css('a').empty?
		next
	end
	school_link = "https://freshman.tw" + school.css('a').attribute('href').value

	r = RestClient.get(school_link)
	doc = Nokogiri::HTML(r)
	doc.css('.col-md-9 tbody tr').each do |dep|
		if dep.css('td:nth-child(2) a').empty?
			next
		end
		dep_links << ("https://freshman.tw/cross/" + year + "/" + dep.css('td:nth-child(2) a').attribute('href').value)
	end
end


dep_links.each do |d_link|
	#initialize variable
	plain_text, max_num, waiting_num, real_num = nil, nil, nil, nil

	#deal with 403 forbidden
	begin
		print d_link + "\n"
		r = RestClient.get(d_link)
	rescue
		print "403 Forbidden..."
		sleep(90)
		retry
	end

	doc = Nokogiri::HTML(r)
	dep_no = doc.css('#content-left div:first-child').text[1..6]
	college_no = dep_no[0..2]
	dep_name = doc.css('#content-left div:first-child').text[8..-1].gsub(/\s+/, '')


	if dep_no == "001542"
		next
	end

	plain_text = doc.css('#content-right .right_box:nth-child(3)').text
	max_num = plain_text.scan(/^.*招生名額：(\d*).*\s$/).first.first

	if plain_text.scan(/^.*備取人數：(\d*).*\s$/) == [] || plain_text.scan(/^.*實際錄取：(\d*).*\s$/) == []
		next
	end
	waiting_num = plain_text.scan(/^.*備取人數：(\d*).*\s$/).first.first
	real_num = plain_text.scan(/^.*實際錄取：(\d*).*\s$/).first.first

	begin
		$conn.exec_prepared('insert_statement', [dep_no, dep_name, college_no, max_num, waiting_num, real_num, year])
	rescue
		print dep + " SUCK!\n"
		next
	end
end
