# frozen_string_literal: true

require "open3"

require_relative "document"

module Tocfl
  module Cover
    module_function

    def minutes(document)
      file = File.join(document.cache_dir, "cover.txt")
      unless File.exist?(file)
        image = File.join(document.cache_dir, "cover")
        Open3.capture3(
          "pdftoppm",
          "-r",
          "150",
          "-gray",
          "-png",
          "-f",
          "1",
          "-l",
          "1",
          "-singlefile",
          document.path,
          image
        )
        text, _err, status = Open3.capture3("tesseract", "#{image}.png", "-", "-l", "chi_tra+eng")
        File.write(file, status.success? ? text : "")
      end

      text = File.read(file)
      found = text.scan(/(\d{2,3})\s*minutes/i).flatten + text.scan(/(\d{2,3})\s*分\s*鐘/).flatten
      found.map(&:to_i).find { |value| value.between?(10, 180) }
    end
  end
end
