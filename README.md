# HU IST Faculty Meeting Schedule #

[北海道大学 工学系教授会・代議員会等 開催日程](https://www.eng.hokudai.ac.jp/event/h_meeting.php)の HTML のテーブルを CSV および YAML に変換する Script．`rowspan` のみ考慮．

## Requirements ##

-   Ruby
-   [Nokogiri](https://nokogiri.org/)

## Example ##

See `Makefile`. Or do the following.

~~~~
% curl https://www.eng.hokudai.ac.jp/event/h_meeting.php | ./parse.rb /dev/stdin
~~~~
