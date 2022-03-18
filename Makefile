targets=meetings.csv meetings.yaml meetings_ist.yaml
year=2022
all: $(targets)

meetings.html: # Makefile
	wget -O $@ 'https://www.eng.hokudai.ac.jp/event/h_meeting.php?y=$(year)'
meetings.yaml meetings_ist.yaml: meetings.csv
meetings.csv: %.csv: %.html parse.rb
	./parse.rb $<

clean:
	rm -f *~ .*~
	rm -f meetings.html Gemfile.lock
realclean distclean: clean
	rm -f $(targets)
