#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'csv'
require 'yaml'

# https://www.eng.hokudai.ac.jp/event/h_meeting.php

doc = Nokogiri::HTML(File.open(ARGV[0]))
table = doc.xpath('//*[@id="eventTable"]/table')

class String
  # a simple version of https://github.com/ikayzo/mojinizer .
  def normalize_zen_han
    tr('０-９Ａ-Ｚ', '0-9A-Z')
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
    r + map { |i| header.map { |k| i[k]==nil ? "" : i[k] } }
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

# Local Variables:
# ruby-indent-level: 2
# End:
