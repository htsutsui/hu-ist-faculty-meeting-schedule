#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'csv'
require 'yaml'
require 'time'

# https://www.eng.hokudai.ac.jp/event/h_meeting.php

doc = Nokogiri::HTML(File.open(ARGV[0]))
table = doc.xpath('//*[@id="eventTable"]/table')
table = table.empty? && doc.xpath('//table')
raise if table.size != 1

class String
  # a simple version of https://github.com/ikayzo/mojinizer .
  def normalize_zen_han
    tr('０-９Ａ-Ｚ（）', '0-9A-Z()')
  end

  def parse_date(year)
    raise unless self =~ /^(?:令和(\d+)年){0,1}(\d+)月(\d+)日(?:\(.\)){0,1}(?:～(\d+)月(\d+)日(?:\(.\)){0,1}){0,1}$/

    (a = $LAST_MATCH_INFO.to_a)[0..1] = []
    day = a.compact.map(&:to_i)
    year = $1.to_i + 2018 if $1
    date = Date.new(year, *day[0..1])
    end_date = Date.new(year, *day[2..3]) if day.size > 2
    [year, date, end_date]
  end
end

MyDate = Struct.new(:orig, :date, :date_end)
class MyDate
  def to_s
    orig
  end

  def to_google_calendar
    [date, date_end ? date_end + 1 : date]
  end
end

class Hash
  class << self; attr_accessor :prev_time end

  def parse_time
    @end_time = nil
    if (@time = self['時間']) == '引き続き'
      @time = self.class.prev_time
    elsif @time
      self.class.prev_time = @time
    end
    @all_day = @time.nil?
    return unless @time

    @time = Time.parse(@time)
    @end_time = @time + @default_duration
  end

  def google_calendar_parse
    parse_time
    @date, @end_date = self['開催月日'].to_google_calendar
    @description = @header.map do |j| # 開催月日,時間,会議名,主な審議事項,備考
      self[j] && "#{j}: #{self[j]}"
    end.compact.join("\n")
    google_calendar_parse_h
  end

  def google_calendar_parse_h
    { 'Subject' => (self['会議名'] || self['備考']),
      'Start Date' => @date,
      'Start Time' => @time,
      'End Date' => @end_date,
      'End Time' => @end_time,
      'All Day Event' => @all_day ? 'True' : 'False',
      'Description' => @description }
  end

  def to_csv_a_google_calendar(header, default_duration = 3 * 60 * 60)
    @default_duration = default_duration
    @header = header
    google_calendar_parse
  end

  def parse_date(year, date_key = '開催月日')
    year, date, end_date = (i = self[date_key]).parse_date(year)
    self[date_key] = MyDate.new(i, date, end_date)
    year
  end
end

class Date
  # https://support.google.com/calendar/answer/37118
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
    year = nil
    data.map do |v|
      j = header.each_with_index.map { |i, h| [i, v[h].strip] }
      j.delete_if { |i| i[1].empty? or i[1].nil? }
      year = (j = j.to_h).parse_date(year)
      j
    end
  end

  def to_csv_a(header)
    r = [header]
    r + map { |i| header.map { |k| i[k] } }
  end

  # See https://support.google.com/calendar/answer/37118
  # The default duration is 3hrs.
  def to_csv_a_google_calendar(header, default_duration = 3 * 60 * 60)
    d = map do |i|
      i.to_csv_a_google_calendar(header, default_duration)
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

  def check_festival(str)
    str.last =~ %r{^(.*)\((\d+)/(\d+)-(\d+)\)} &&
      ["#{$2}月#{$3}日～#{$2}月#{$4}日", '', '', '', $1]
  end

  def check_delay(data, delay, values)
    if !delay.empty? && values[0][1].zero?
      [data + delay, []]
    else
      [data, delay]
    end
  end

  def to_a
    return @a if @a

    prev = nil
    delay = []
    @a = xpath('.//tr').inject([]) do |a, i|
      prev = values = build_row(i, prev)
      a << (i = values.map { |j| j[0].normalize_zen_han })
      (f = check_festival(i)) && (delay << f)
      a, delay = check_delay(a, delay, values)
      a
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

date_h = {}
date_ist_h = {}
ist = all.map do |i|
  if (j = i['会議名']) =~ /^\((.)\)(.*)/
    k = $1
    name = $2
    date = i['開催月日'].date
    time = i['時間']
    date_h[date] = date_h[date] || time
    if (k == '情' && name =~ /教授会/) || j == '(工)学部教授会'
      if time == '引き続き' && !date_ist_h[date]
        i = i.dup
        i['会議名'] += "(#{time})"
        i['時間'] = date_h[date]
      end
      date_ist_h[date] = date_ist_h[date] || time
      i
    end
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
