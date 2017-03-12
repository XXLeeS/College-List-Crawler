require 'nokogiri'
require 'pry-byebug'
require 'rest-client'
require 'csv'
require 'pg'

require_relative 'database.rb'

#105
# "https://www.caac.ccu.edu.tw/caac105/105_kd5b_Entrance_k/html_entrance_mju/result_html/result_apply/collegeList.htm"
#104

#103


url_base = "https://www.caac.ccu.edu.tw/caac105/105_kd5b_Entrance_k/html_entrance_mju/result_html/result_apply/common/apply/"

#remember to change table name for different year
$conn.prepare('update_statement', 'UPDATE dep_105 SET max_num = $1 WHERE dep_no = $2')

query = conn.exec('SELECT dep_no FROM dep_105')
dep_no = Array.new
query.each do |row|
	dep_no.push(row["dep_no"])
end

dep_no.sort!
dep_no.each do |dep|
	query_url = url_base + dep + ".htm"
	begin
		r = RestClient.get(query_url)
	rescue
		print "Connection reset by peer...\n"
		sleep(5)
		retry
	end
	doc =  Nokogiri::HTML(r)
	doc.css('body > div > span:first-child > span:last-child').each do |row|
		max_num = row.text[7..-17]

		begin
			$conn.exec_prepared('update_statement', [max_num, dep])
		rescue
			print dep + " SUCK!\n"
			next
		end
	end
end
