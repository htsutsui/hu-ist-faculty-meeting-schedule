# HU IST Faculty Meeting Schedule #

[北海道大学 工学系教授会・代議員会等
開催日程](https://www.eng.hokudai.ac.jp/event/h_meeting.php)
の HTML のテーブルを CSV および YAML に変換する Script．`rowspan` のみ考慮．

It seems that the 2023 version of this page is not available.

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

- [IST only](meetings_ist_google_calendar.csv) (2023 version)
- [All Eng.](meetings_google_calendar.csv) (2022 version)

## Notices ##

- No Warranty
