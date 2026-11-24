# frozen_string_literal: true

require "fileutils"
require "open3"

require_relative "document"

module Tocfl
  class Cropper
    SCALE = Document::OUTPUT_DPI / 72.0
    QUALITY = "78"

    attr_reader :written

    def initialize(document, directory)
      @document = document
      @directory = directory
      @written = {}
      FileUtils.mkdir_p(directory)
    end

    def crop(page, box, name, pad: 3)
      return nil if box.nil?

      raster = @document.raster(page)
      width, height = png_size(raster)
      padded = box.pad(pad)
      x = [(padded.x0 * SCALE).floor, 0].max
      y = [(padded.y0 * SCALE).floor, 0].max
      w = [(padded.x1 * SCALE).ceil, width].min - x
      h = [(padded.y1 * SCALE).ceil, height].min - y
      return nil if w < 4 || h < 4

      file = File.join(@directory, "#{name}.webp")
      _stdout, stderr, status = Open3.capture3(
        "cwebp",
        "-quiet",
        "-q",
        QUALITY,
        "-m",
        "6",
        "-mt",
        "-crop",
        x.to_s,
        y.to_s,
        w.to_s,
        h.to_s,
        raster,
        "-o",
        file
      )
      raise "cwebp failed for #{name}: #{stderr}" unless status.success?

      @written[name] = File.size(file)
      "img/#{name}.webp"
    end

    private

    def png_size(file)
      @sizes ||= {}
      @sizes[file] ||= File.binread(file, 24).byteslice(16, 8).unpack("NN")
    end
  end
end
