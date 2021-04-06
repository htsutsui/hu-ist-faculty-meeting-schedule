all: meetings.csv meetings.yaml meetings_summary.yaml

meetings.html: # Makefile
	wget -O $@ https://www.eng.hokudai.ac.jp/event/h_meeting.php
meetings.yaml meetings_summary.yaml: meetings.csv
meetings.csv: %.csv: %.html parse.rb
	./parse.rb $<
