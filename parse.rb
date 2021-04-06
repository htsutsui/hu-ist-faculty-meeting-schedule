#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'csv'
require 'yaml'

# https://www.eng.hokudai.ac.jp/event/h_meeting.php

doc = Nokogiri::HTML(File.open(ARGV[0]))
table = doc.xpath('//*[@id="eventTable"]/table')

class String
  def normalize_zen_han
    tr('０-９Ａ-Ｚ', '0-9A-Z')
  end
end

module Table
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

  def to_hash
    return @h if @h

    a = to_a.dup
    header = a.shift
    @h = a.map do |v|
      j = header.each_with_index.map { |i, h| [i, v[h]] }
      j.delete_if { |i| i[1].empty? or i[1].nil? }
      Hash[j]
    end
  end

  def summary
    r = to_hash.map do |i|
      if (j = i['会議名']) =~ /^\((.)\)(.*)/
        k = $1
        name = $2
        i if k == '情' && name =~ /教授会/ || j == '(工)学部教授会'
      else
        i
      end
    end
    @summary = r.compact
  end
end
class << table
  include Table
end

CSV.open('meetings.csv', 'w') { |fp| table.to_a.map { |i| fp << i } }
open('meetings.yaml', 'w') { |fp| fp.write(YAML.dump(table.to_hash)) }
open('meetings_ist.yaml', 'w') { |fp| fp.write(YAML.dump(table.summary)) }

# Local Variables:
# ruby-indent-level: 2
# End:
