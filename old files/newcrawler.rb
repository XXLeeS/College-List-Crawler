require 'nokogiri'
require 'pry'
require 'json'
require 'iconv'
require 'rest-client'
require 'csv'
require 'redis'
require 'pg'

conn = PGconn.connect("localhost",5432,"","","college","postgres","1234")
conn.prepare('statement1', 'INSERT INTO list (test[0], test[1], haha) values ($1, $2, $3)')
print "SHIT"
binding.pry
print "FUCK"

year = "105"
query_url = "http://www.com.tw/university_list" + year + ".html"

conn = PGconn.connect("localhost",5432,"","","college","postgres","1234")
conn.prepare('statement1', 'INSERT INTO list_105_old (number, name, area, decision, selection_1, selection_2, selection_3, selection_4, selection_5, selection_6, selection_1_rank, selection_2_rank, selection_3_rank, selection_4_rank, selection_5_rank, selection_6_rank) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)')



r = RestClient.get(query_url)
doc = Nokogiri::HTML(r)
doc.css('#table1 tr:not(:first-child)').each do |school_row|
school_row.css('td:nth-child(2n)').each do |school|
	school_link = "http://www.com.tw/" + school.css('a:first-child').attribute('href').value

	r = RestClient.get(school_link)
	doc = Nokogiri::HTML(r)
	doc.css('#table1 tr:nth-child(n+4)').each do |dep|
		dep_link = "http://www.com.tw/" + dep.css('td:nth-child(3) a').attribute('href').value

		students = []
		r = RestClient.get(dep_link)
		doc = Nokogiri::HTML(r)
		doc.css('#mainContent div.homepagetitle + table > tr:nth-child(n+4)').each do |row|

			number = Integer(row.css('td:nth-child(3) div').text[0..7])
			area = row.css('td:nth-child(3) div a').text.strip[5..-1]
			name = row.css('td:nth-child(4)').text.strip

			selection, selection_rank = [], []
			decision = nil
			row.css('td:nth-child(5) table tr:not(:nth-child(2))').each do |sel|
				selection << sel.css('td:nth-child(2) a').text.strip.gsub("\r", " ")
				selection_rank << sel.css('td:nth-child(3)').text.strip

				if !sel.css('td:nth-child(1) img').empty?
					decision = selection.last
				end
			end

			student = {
				number: 			number,
				name: 				name,
				area: 				area,
				decision: 			decision,
				selection_1: 		selection[0],
				selection_2: 		selection[1],
				selection_3: 		selection[2],
				selection_4: 		selection[3],
				selection_5: 		selection[4],
				selection_6: 		selection[5],
				selection_rank_1: 	selection_rank[0],
				selection_rank_2: 	selection_rank[1],
				selection_rank_3: 	selection_rank[2],
				selection_rank_4: 	selection_rank[3],
				selection_rank_5: 	selection_rank[4],
				selection_rank_6: 	selection_rank[5]
			}

			students << student
		end
		#save students to db
		students.each do |s|
			conn.exec_prepared('statement1', [s[:number], s[:name], s[:area], s[:decision], s[:selection_1], s[:selection_2], s[:selection_3], s[:selection_4], s[:selection_5], s[:selection_6], s[:selection_rank_1], s[:selection_rank_2], s[:selection_rank_3], s[:selection_rank_4], s[:selection_rank_5], s[:selection_rank_6]])
		end
	end
end
end

