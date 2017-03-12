require 'nokogiri'
require 'pry'
require 'rest-client'
require 'csv'
require 'pg'

year = "105"
query_url = "https://freshman.tw/cross/" + year + "/"

conn = PGconn.connect("localhost",5432,"","","college","postgres","1234")
conn.prepare('insert_statement', 'INSERT INTO dep_no_105 (dep_no, dep_name) VALUES ($1, $2)')

r = RestClient.get(query_url)
doc =  Nokogiri::HTML(r)
doc.css('#cross_index li').each do |school|
	if school.css('a').empty?
		next
	end
	school_link = "https://freshman.tw" + school.css('a').attribute('href').value
	school_name = school.css('.college_name').text()[4..-1]
	

	r = RestClient.get(school_link)
	doc = Nokogiri::HTML(r)
	doc.css('#content-left tbody tr').each do |dep|
		if dep.css('td:nth-child(3) a').empty?
			next
		end
		dep_no = dep.css('td:nth-child(3) a').attribute('href').value
		dep_name = school_name + dep.css('td:nth-child(2)').text
		
		conn.exec_prepared('insert_statement', [dep_no, dep_name])
	end
end