#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'csv'
require 'yaml'
require 'time'

# https://www.eng.hokudai.ac.jp/event/h_meeting.php

doc = Nokogiri::HTML(File.open(ARGV[0]))
table = doc.xpath('//*[@id="eventTable"]/table')

class String
  # a simple version of https://github.com/ikayzo/mojinizer .
  def normalize_zen_han
    tr('０-９Ａ-Ｚ', '0-9A-Z')
  end

  def parse_date(year)
    case self
    when /^(?:令和(\d+)年){0,1}(\d+)月(\d+)日\(.\)$/
      day = $LAST_MATCH_INFO[2..3].map(&:to_i)
      year = $1.to_i + 2018 if $1
      end_date = date = Date.new(year, *day)
    when /^(?:令和(\d+)年){0,1}(\d+)月(\d+)日\(.\)～(\d+)月(\d+)日\(.\)$/
      day = $LAST_MATCH_INFO[2..5].map(&:to_i)
      year = $1.to_i + 2018 if $1
      date = Date.new(year, *day[0..1])
      end_date = (Date.new(year, *day[2..3]) + 1)
    else
      raise
    end
    [year, date, end_date]
  end
end

class Date
  def to_s
    strftime('%m/%d/%Y')
  end
end
class Time
  def to_s
    strftime('%H:%M')
  end
end

class Array
  def to_h_a
    header, *data = self
    data.map do |v|
      j = header.each_with_index.map { |i, h| [i, v[h]] }
      j.delete_if { |i| i[1].empty? or i[1].nil? }
      Hash[j]
    end
  end

  def to_csv_a(header)
    r = [header]
    r + map { |i| header.map { |k| i[k] } }
  end

  # See https://support.google.com/calendar/answer/37118
  # The default duration is 3hrs.
  def to_csv_a_google_calendar(header, default_duration = 3 * 60 * 60)
    prev_time = nil
    year = nil
    end_time = nil
    d = map do |i|
      all_day = false
      if (time = i['時間']) == '引き続き'
        time = prev_time
      elsif time
        prev_time = time
      else
        all_day = true
      end
      if time
        time = Time.parse(time)
        end_time = time + default_duration
      end
      year, date, end_date = i['開催月日'].parse_date(year)
      # 開催月日,時間,会議名,主な審議事項,備考
      description = header.map do |j|
        i[j] && "#{j}: #{i[j]}"
      end.compact.join("\n")
      {
        'Subject' => (i['会議名'] || i['備考']),
        'Start Date' => date,
        'Start Time' => time,
        'End Date' => end_date,
        'End Time' => end_time,
        'All Day Event' => all_day ? 'True' : 'False',
        'Description' => description
        # 'Location'=>,
        # 'Private'=>,
      }
    end
    d.to_csv_a(d[0].keys)
  end
end

module Table
  private

  def build_row(tr_node, prev)
    values = tr_node.xpath('.//th|td').map do |j|
      k = j.attributes['rowspan']
      [j.text, k ? k.value.to_i - 1 : 0]
    end
    prev&.each_with_index do |h, k|
      values.insert(k, [h[0], h[1] - 1]) if h[1] != 0
    end
    values
  end

  def to_a
    return @a if @a

    prev = nil
    @a = xpath('.//tr').map do |i|
      prev = values = build_row(i, prev)
      values.map { |j| j[0].normalize_zen_han }
    end
  end

  public

  def to_h_a
    @h || @h = to_a.to_h_a
  end

  def header
    @header || @header = to_a[0]
  end
end
class << table
  include Table
end

header = table.header
all = table.to_h_a

open('meetings.yaml', 'w') { |fp| fp.write(YAML.dump(all)) }
CSV.open('meetings.csv', 'w') { |fp| all.to_csv_a(header).map { |i| fp << i } }
CSV.open('meetings_google_calendar.csv', 'w') { |fp| all.to_csv_a_google_calendar(header).map { |i| fp << i } }

ist = all.map do |i|
  if (j = i['会議名']) =~ /^\((.)\)(.*)/
    k = $1
    name = $2
    i if k == '情' && name =~ /教授会/ || j == '(工)学部教授会'
  else
    i
  end
end.compact

open('meetings_ist.yaml', 'w') { |fp| fp.write(YAML.dump(ist)) }
CSV.open('meetings_ist.csv', 'w') { |fp| ist.to_csv_a(header).map { |i| fp << i } }
CSV.open('meetings_ist_google_calendar.csv', 'w') { |fp| ist.to_csv_a_google_calendar(header).map { |i| fp << i } }

# Local Variables:
# ruby-indent-level: 2
# End:
