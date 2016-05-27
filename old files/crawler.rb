require 'nokogiri'
require 'pry'
require 'json'
require 'iconv'
require 'rest-client'
require 'csv'

query_url = "https://freshman.tw/cross/104/001512"
ic = Iconv.new('utf-8//IGNORE//translit', 'big5')

r = RestClient.get(query_url)
doc =  Nokogiri::HTML(r)

count = 0
students = []

number, area, name, decision = nil, nil, nil, nil, nil
selection, selection_rank = [], []

doc.css('#cross_dept tbody tr').each do |row|
	if row.attr('class').include? "showPhoto"
		if count > 0
			student = {
				number: 			number,
				area: 				area,
				name: 				name,
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
				selection_rank_6: 	selection_rank[5],
				decision: 			decision
			}
			students << student
		end
		decision = nil
		selection, selection_rank = [], []

		count += 1

		number = row.css('td:nth-child(2) .number').text
		area = row.css('td:nth-child(2) div').text
		name = row.css('td:nth-child(3)').text[0..-2]

		selection << row.css('td:nth-child(4) a').text
		selection_rank << row.css('td:nth-child(5) span').text

		if !row.css('.crown').empty?
			decision = selection.last
		end	
	end

	if row.attr('class').include? "dept_other"
		selection << row.css('td:nth-child(1)').text
		selection_rank << row.css('td:nth-child(2) .rank').text
		if !row.css('.crown').empty?
			decision = selection.last
		end
	end
end


CSV.open("result.csv", "w") do |csv|
	students.each do |s|
		csv << [s[:number], s[:area], s[:name], s[:selection_1], s[:selection_2], s[:selection_3], s[:selection_4], s[:selection_5], s[:selection_6], s[:selection_rank_1], s[:selection_rank_2], s[:selection_rank_3], s[:selection_rank_4], s[:selection_rank_5], s[:selection_rank_6], s[:decision]]
	end
end
