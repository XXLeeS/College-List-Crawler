require 'nokogiri'
require 'pry-byebug'
require 'rest-client'
require 'csv'
require 'pg'

def integer_rank(text)
	if text.include?("正")
		return text[/\d+/].to_i
	elsif text.include?("備")
		return (0 - text[/\d+/].to_i)
	else
		return 0
	end
end

AREAS = {
	nil		=> 0,
	"台北" 	=> 1,
	"新北"	=> 2,
	"基隆"	=> 3,
	"桃園"	=> 4,
	"中壢"	=> 5,
	"新竹"	=> 6,
	"苗栗"	=> 7,
	"台中"	=> 8,
	"南投"	=> 9,
	"彰化"	=> 10,
	"雲林"	=> 11,
	"嘉義"	=> 12,
	"台南"	=> 13,
	"高雄"	=> 14,
	"屏東"	=> 15,
	"宜蘭"	=> 16,
	"花蓮"	=> 17,
	"台東"	=> 18,
	"澎湖"	=> 19,
	"金門"	=> 20,
	"馬祖"	=> 21
}

conn = PGconn.connect("localhost",5432,"","","college","postgres","1234")
#remember to change table name for different year
conn.prepare('if_exist_statement', 'SELECT EXISTS(SELECT student_no FROM list_105 WHERE student_no = $1)')
conn.prepare('insert_statement', 'INSERT INTO list_105 (student_no, name, area, decision, selection_1, selection_2, selection_3, selection_4, selection_5, selection_6, selection_rank_1, selection_rank_2, selection_rank_3, selection_rank_4, selection_rank_5, selection_rank_6) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)')

year = "105"

links = []

File.open("special_links.txt", "r") do |f|
	f.each_line do |line|
		links << line.strip
	end
end

links.each do |link|
	dep_links = []

	r = RestClient.get(link)
	doc = Nokogiri::HTML(r)
	doc.css('#cross_dept tbody tr').each do |instrument|
		dep_links << ("https://freshman.tw/cross/" + year + "/" + instrument.css('td a').attribute('href').value)
	end

	dep_links.each do |d_link|
		#initialize variable
		student_no, area, name, decision = nil, nil, nil, nil
		selection, selection_rank = [], []
		students = []
		count = 0

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
		this_dep = doc.css('#content-left div:first-child').text[1..6]
		doc.css('#cross_dept tbody tr').each do |row|
			if row.attr('class').nil?
				print "^^^special link!!!^^^\n"
				File.open("special_links.txt", "a") do |f|
					f.puts(d_link)
				end
				break
			end

			if row.attr('class').include? "showPhoto"
				if count > 0
					#BUG: can't save the last row
					student = {
						student_no: 		student_no,
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

					decision = nil
					selection, selection_rank = [], []
				end
				count += 1

				student_no = row.css('td:nth-child(2) .number').text
				area = AREAS[row.css('td:nth-child(2) div').text[3..4]]
				name = row.css('td:nth-child(3)').text[0..-2]

				selection << this_dep
				selection_rank << integer_rank(row.css('td:nth-child(5) span').text)

				if !row.css('.crown').empty?
					decision = selection.last
				end	
			end

			if row.attr('class').include? "dept_other"
				selection << row.css('td:nth-child(1) a').attribute('href').value[0..5]
				selection_rank << integer_rank(row.css('td:nth-child(2) .rank').text)
				if !row.css('.crown').empty?
					decision = selection.last
				end
			end
		end


		students.each do |s|
			#check duplicated primary key
			res = conn.exec_prepared('if_exist_statement', [s[:student_no]])
			if res[0]["exists"] == "f"
				conn.exec_prepared('insert_statement',[s[:student_no], s[:name], s[:area], s[:decision], s[:selection_1], s[:selection_2], s[:selection_3], s[:selection_4], s[:selection_5], s[:selection_6], s[:selection_rank_1], s[:selection_rank_2], s[:selection_rank_3], s[:selection_rank_4], s[:selection_rank_5], s[:selection_rank_6]])
			end
		end
		students = []
	end
end

