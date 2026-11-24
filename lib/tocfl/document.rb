# frozen_string_literal: true

require "cgi"
require "digest"
require "fileutils"
require "open3"
require "tmpdir"

require_relative "geometry"

module Tocfl
  class Document
    OUTPUT_DPI = 200
    INK_LEVEL = 235
    SOLID_LEVEL = 210
    WORD = %r{<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>}
    PAGE = /<page width="([\d.]+)" height="([\d.]+)">/

    attr_reader :path, :name

    def initialize(path)
      @path = path
      @name = File.basename(path)
      @ink = {}
      @raster = {}
      @lock = Mutex.new
    end

    def page_count = pages.size

    def page_box(page)
      width, height = pages.fetch(page - 1)[:size]
      Box.new(0, 0, width, height)
    end

    def words(page)
      list = pages.fetch(page - 1)[:words]
      return list if list.any? || page == 1

      @ocr_words ||= {}
      @lock.synchronize { @ocr_words[page] ||= recognize(page) }
    end

    def ocr_line(page, box)
      name = "row-#{page}-#{box.to_a.join("_")}"
      file = File.join(cache_dir, "#{name}.txt")
      unless File.exist?(file)
        scale = 300 / 72.0
        image = File.join(cache_dir, name)
        run(
          "pdftoppm",
          "-r",
          "300",
          "-gray",
          "-png",
          "-f",
          page.to_s,
          "-l",
          page.to_s,
          "-singlefile",
          "-x",
          (box.x0 * scale).floor.to_s,
          "-y",
          (box.y0 * scale).floor.to_s,
          "-W",
          (box.width * scale).ceil.to_s,
          "-H",
          (box.height * scale).ceil.to_s,
          path,
          image
        )
        text = %w[6 7]
          .lazy
          .map { |mode| Open3.capture3("tesseract", "#{image}.png", "-", "-l", "chi_tra", "--psm", mode) }
          .map { |out, _err, status| status.success? ? out : "" }
          .find { |out| !out.strip.empty? }
        File.write(file, text.to_s)
      end

      File.read(file).gsub(/\s+/, "")
    end

    def ocr_page?(page)
      words(page)
      @ocr_words&.key?(page) && @ocr_words[page].any?
    end

    def pages
      @pages ||= begin
        xml = run("pdftotext", "-bbox", path, "-")
        xml
          .split("</page>")
          .filter_map do |chunk|
            size = PAGE.match(chunk)
            next unless size

            number = nil
            list = chunk.scan(WORD).map do |x0, y0, x1, y1, text|
              Word.new(page: number, box: Box.new(x0.to_f, y0.to_f, x1.to_f, y1.to_f), text: CGI.unescapeHTML(text))
            end

            {size: [size[1].to_f, size[2].to_f], words: list}
          end
          .each_with_index
          .map do |page, index|
            {size: page[:size], words: page[:words].map { |word| word.with(page: index + 1) }}
          end
      end
    end

    def cache_dir
      @cache_dir ||= begin
        key = Digest::SHA1.hexdigest("#{path}:#{File.mtime(path).to_i}:#{File.size(path)}")
        File.join(Dir.tmpdir, "tocfl-pages", key).tap { |dir| FileUtils.mkdir_p(dir) }
      end
    end

    def ink(page)
      @lock.synchronize { @ink[page] ||= load_ink(page) }
    end

    def raster(page)
      file = File.join(cache_dir, "p#{page}-#{OUTPUT_DPI}.png")
      unless File.exist?(file)
        run(
          "pdftoppm",
          "-r",
          OUTPUT_DPI.to_s,
          "-png",
          "-f",
          page.to_s,
          "-l",
          page.to_s,
          "-singlefile",
          path,
          file.delete_suffix(".png")
        )
      end

      file
    end

    def ink_box(page, box, masks: [])
      Ink.box(ink(page), box, masks)
    end

    def components(page, box, masks: [], merge: 6)
      Ink.components(ink(page), box, masks, merge)
    end

    private

    def recognize(page)
      blank = Ink.box(load_ink(page), page_box(page), [])
      return [] if blank.nil? || blank.area < 400

      file = File.join(cache_dir, "p#{page}-ocr.tsv")
      unless File.exist?(file)
        image = File.join(cache_dir, "p#{page}-300")
        run("pdftoppm", "-r", "300", "-gray", "-png", "-f", page.to_s, "-l", page.to_s, "-singlefile", path, image)
        tsv, _err, status = Open3.capture3("tesseract", "#{image}.png", "-", "-l", "chi_tra+eng", "--psm", "3", "tsv")
        File.write(file, status.success? ? tsv : "")
      end

      words = tsv_words(page, file, 0)
      margin = File.join(cache_dir, "p#{page}-margin.tsv")
      unless File.exist?(margin)
        strip = File.join(cache_dir, "p#{page}-margin.png")
        run(
          "vips",
          "crop",
          File.join(cache_dir, "p#{page}-300.png"),
          strip,
          "0",
          "0",
          ((page_box(page).width * 0.13) * 300 / 72).round.to_s,
          ((page_box(page).height * 300 / 72) - 1).floor.to_s
        )
        tsv, _err, status = Open3.capture3("tesseract", strip, "-", "-l", "eng", "--psm", "11", "tsv")
        File.write(margin, status.success? ? tsv : "")
      end

      numbers = tsv_words(page, margin, 0).filter_map do |word|
        next unless word.text.match?(/\A\d{1,3}\.?\z/)
        next if words.any? { |other| other.box.intersects?(word.box) && other.text.start_with?(word.text.delete(".")) }

        word.with(text: "#{word.text.delete(".")}.")
      end

      words + numbers
    end

    def tsv_words(page, file, offset)
      scale = 72.0 / 300
      File.readlines(file, chomp: true).drop(1).filter_map do |line|
        level, _p, _b, _par, _l, _w, left, top, width, height, confidence, text = line.split("\t", 12)
        next unless level == "5" && text && !text.strip.empty? && confidence.to_f >= 30

        box = Box.new(
          (left.to_f + offset) * scale,
          top.to_f * scale,
          (left.to_f + offset + width.to_f) * scale,
          (top.to_f + height.to_f) * scale
        )
        Word.new(page: page, box: box, text: text.strip)
      end
    end

    def load_ink(page)
      file = File.join(cache_dir, "p#{page}-72.pgm")
      unless File.exist?(file)
        run(
          "pdftoppm",
          "-r",
          "72",
          "-gray",
          "-f",
          page.to_s,
          "-l",
          page.to_s,
          "-singlefile",
          path,
          file.delete_suffix(".pgm")
        )
      end

      Ink.read(file)
    end

    def run(*command)
      stdout, stderr, status = Open3.capture3(*command)
      raise "#{command.first} failed on #{name}: #{stderr}" unless status.success?

      stdout
    end
  end

  class Ink
    attr_reader :width, :height, :bytes

    def self.read(file)
      data = File.binread(file)
      header = data.match(/\AP5\s+(\d+)\s+(\d+)\s+(\d+)\s/)
      raise "not a PGM: #{file}" unless header

      new(header[1].to_i, header[2].to_i, data.byteslice(header[0].bytesize, header[1].to_i * header[2].to_i))
    end

    def initialize(width, height, bytes)
      @width = width
      @height = height
      @bytes = bytes
    end

    def dark?(x, y) = bytes.getbyte((y * width) + x) < Document::INK_LEVEL

    def self.span(ink, box)
      [
        [box.x0.floor, 0].max,
        [box.y0.floor, 0].max,
        [box.x1.ceil, ink.width].min,
        [box.y1.ceil, ink.height].min
      ]
    end

    def self.masked(masks, x, y)
      masks.any? { |mask| x >= mask.x0 && x < mask.x1 && y >= mask.y0 && y < mask.y1 }
    end

    def self.box(ink, box, masks, level = Document::INK_LEVEL)
      x0, y0, x1, y1 = span(ink, box)
      masks = masks.select { |mask| mask.intersects?(box) }
      found = nil
      (y0...y1).each do |y|
        row = y * ink.width
        (x0...x1).each do |x|
          next unless ink.bytes.getbyte(row + x) < level
          next if masks.any? && masked(masks, x, y)

          found = found ? [[found[0], x].min, [found[1], y].min, [found[2], x + 1].max, [found[3], y + 1].max] : [
            x,
            y,
            x + 1,
            y + 1
          ]
        end
      end

      found && Box.new(*found)
    end

    def self.components(ink, box, masks, merge)
      cell = 3
      x0, y0, x1, y1 = span(ink, box)
      return [] if x1 <= x0 || y1 <= y0

      masks = masks.select { |mask| mask.intersects?(box) }
      columns = ((x1 - x0) / cell.to_f).ceil
      lines = ((y1 - y0) / cell.to_f).ceil
      grid = Array.new(columns * lines, false)
      (y0...y1).each do |y|
        row = y * ink.width
        cy = (y - y0) / cell
        (x0...x1).each do |x|
          index = (cy * columns) + ((x - x0) / cell)
          next if grid[index]
          next unless ink.bytes.getbyte(row + x) < Document::INK_LEVEL
          next if masks.any? && masked(masks, x, y)

          grid[index] = true
        end
      end

      reach = [(merge / cell.to_f).ceil, 1].max
      seen = Array.new(grid.size, false)
      found = []
      grid.each_index do |start|
        next unless grid[start] && !seen[start]

        stack = [start]
        seen[start] = true
        bounds = [columns, lines, 0, 0]
        until stack.empty?
          index = stack.pop
          cx = index % columns
          cy = index / columns
          bounds = [[bounds[0], cx].min, [bounds[1], cy].min, [bounds[2], cx + 1].max, [bounds[3], cy + 1].max]
          ([cy - reach, 0].max..[cy + reach, lines - 1].min).each do |ny|
            ([cx - reach, 0].max..[cx + reach, columns - 1].min).each do |nx|
              neighbor = (ny * columns) + nx
              next if seen[neighbor] || !grid[neighbor]

              seen[neighbor] = true
              stack << neighbor
            end
          end
        end

        rough = Box.new(
          x0 + (bounds[0] * cell),
          y0 + (bounds[1] * cell),
          x0 + (bounds[2] * cell),
          y0 + (bounds[3] * cell)
        )
        found << (box(ink, rough, masks, Document::SOLID_LEVEL) || box(ink, rough, masks) || rough)
      end

      found
    end
  end
end
