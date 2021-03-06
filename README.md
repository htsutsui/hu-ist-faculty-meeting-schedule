# 2022 HU IST Faculty Meeting Schedule #

[北海道大学 工学系教授会・代議員会等
開催日程](https://www.eng.hokudai.ac.jp/event/h_meeting.php?y=2022)
の HTML のテーブルを CSV および YAML に変換する Script．`rowspan` のみ考慮．

The URL query string, `y=2022`, is only valid at the end of each fiscal year. So old branches other than `main` do not work correctly.

## Requirements ##

- Ruby
- [Nokogiri](https://nokogiri.org/)

## Example ##

See `Makefile`. Or do the following.

~~~~
% curl https://www.eng.hokudai.ac.jp/event/h_meeting.php | ./parse.rb /dev/stdin
~~~~

## For Google Calendar ##

You can use the following files to import the entries into your Google
Calendar. Notice: please check the CSV file before import. The default
meeting duration is 3 hours.

- [IST only](meetings_ist_google_calendar.csv)
- [All Eng.](meetings_google_calendar.csv)
