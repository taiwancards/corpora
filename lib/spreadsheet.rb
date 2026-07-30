# frozen_string_literal: true

require "zip"
require "stringio"
require "cgi"

module Spreadsheet
  ODS_CONTENT = "content.xml"
  XLSX_SHARED = "xl/sharedStrings.xml"
  XLSX_SHEET = %r{\Axl/worksheets/sheet1\.xml\z}

  ODS_ROW = %r{<table:table-row[^>]*>(.*?)</table:table-row>}m
  ODS_CELL = %r{<table:table-cell([^>]*?)(?:/>|>(.*?)</table:table-cell>)}m
  ODS_TEXT = %r{<text:p[^>]*>(.*?)</text:p>}m
  ODS_REPEAT = /table:number-columns-repeated="(\d+)"/

  XLSX_ROW = %r{<row[^>]*>(.*?)</row>}m
  XLSX_CELL = %r{<c([^>]*?)(?:/>|>(.*?)</c>)}m
  XLSX_VALUE = %r{<v>(.*?)</v>}m
  XLSX_INLINE = %r{<t[^>]*>(.*?)</t>}m
  XLSX_SHARED_ITEM = %r{<si>(.*?)</si>}m
  XLSX_REFERENCE = /r="([A-Z]+)\d+"/
  XLSX_SHARED_TYPE = /t="s"/

  TAG = /<[^>]+>/

  module_function

  def rows(path)
    name = path.to_s
    return ods_rows(File.binread(name)) if name.end_with?(".ods")
    return xlsx_rows(File.binread(name)) if name.end_with?(".xlsx")

    from_archive(name)
  end

  def from_archive(path)
    entry = Zip::File.open(path) { |zip| zip.find { |member| member.name.end_with?(".ods", ".xlsx") } }
    raise "#{path}: no spreadsheet inside" if entry.nil?

    payload = Zip::File.open(path) { |zip| zip.find_entry(entry.name).get_input_stream.read }
    entry.name.end_with?(".ods") ? ods_rows(payload) : xlsx_rows(payload)
  end

  def ods_rows(payload)
    member(payload, ODS_CONTENT).scan(ODS_ROW).filter_map do |(body)|
      values = body.scan(ODS_CELL).flat_map do |(attributes, inner)|
        text = inner.to_s.scan(ODS_TEXT).flatten.map { |chunk| plain(chunk) }.join(" ").strip
        Array.new([attributes[ODS_REPEAT, 1].to_i, 1].max, text)
      end

      values if values.any? { |value| !value.empty? }
    end
  end

  def xlsx_rows(payload)
    shared = shared_strings(payload)

    member(payload, XLSX_SHEET).scan(XLSX_ROW).filter_map do |(body)|
      values = []
      body.scan(XLSX_CELL) do |(attributes, inner)|
        values[column_index(attributes)] = cell_value(attributes, inner.to_s, shared)
      end

      values.map(&:to_s) if values.any? { |value| value && !value.empty? }
    end
  end

  def shared_strings(payload)
    raw = member(payload, XLSX_SHARED, optional: true)
    return [] if raw.nil?

    raw.scan(XLSX_SHARED_ITEM).map { |(body)| body.scan(XLSX_INLINE).flatten.map { |chunk| plain(chunk) }.join }
  end

  def cell_value(attributes, inner, shared)
    return shared[inner[XLSX_VALUE, 1].to_i].to_s if attributes.match?(XLSX_SHARED_TYPE)

    inline = inner.scan(XLSX_INLINE).flatten
    return inline.map { |chunk| plain(chunk) }.join if inline.any?

    plain(inner[XLSX_VALUE, 1].to_s)
  end

  def column_index(attributes)
    letters = attributes[XLSX_REFERENCE, 1].to_s
    return 0 if letters.empty?

    letters.each_char.reduce(0) { |memo, char| (memo * 26) + (char.ord - 64) } - 1
  end

  def plain(chunk) = CGI.unescapeHTML(chunk.gsub(TAG, "")).force_encoding(Encoding::UTF_8)

  def member(payload, name, optional: false)
    Zip::File.open_buffer(StringIO.new(payload)) do |zip|
      entry = zip.find { |candidate| name.is_a?(Regexp) ? candidate.name.match?(name) : candidate.name == name }
      return entry.get_input_stream.read.force_encoding(Encoding::UTF_8) if entry
      raise "member #{name} not found" unless optional

      return nil
    end
  end
end
