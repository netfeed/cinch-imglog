require 'cinch'
require 'curl'
require 'uri'
require 'mini_magick'
require 'json'
require 'digest/md5'
require 'fileutils'

module Cinch
  module Plugins
    class ImgLog
      include Cinch::Plugin
  
      match /(.*http.*)/, :use_prefix => false
      
      TmpDir = '/tmp/image'

      def execute m, message
        Dir.mkdir TmpDir unless Dir.exists? TmpDir
        Dir.mkdir config["save_dir"] unless Dir.exists? config["save_dir"]

        URI.extract(message, ["http", "https"]) do |uri|
          next unless valid? uri
          next if ignore? uri
          process m.channel, m.prefix, uri
        end
      end

      private

      def valid? uri
        endings = config["download"] || [".jpg$", ".jpeg$", ".gif$", ".png$", ".pjpeg$"]
        endings.each { |re|  return true if uri =~ /#{re}/i }
        return false
      end
      
      def ignore? uri
        patterns = config["ignore"] || []
        patterns.each { |re| return true if uri =~ /#{re}/i }
        return false
      end
      
      def remove image
        FileUtils.remove image if File.exists? image
      end
      
      def process channel, prefix, uri
        filename = File.join(config["save_dir"], Time.now.to_f.to_s.gsub!(/\./, ''))
        content = Curl::Easy.perform(uri).body_str
        file = open(filename, 'w') do |file|
          file.write(content)
        end

        digest = Digest::MD5.hexdigest(File.read(filename))
        image = MiniMagick::Image.open(filename)

        timename = Time.now.to_f.to_s.gsub /\./, ''

        save_image = File.join(TmpDir, timename)
        dir = File.dirname save_image
        FileUtils.mkdir_p dir unless Dir.exists? dir
        FileUtils.copy_file(filename, save_image)

        save_thumb = File.join(TmpDir, "#{timename}t")
        thumb = MiniMagick::Image.open(save_image)
        thumb.resize "145x145"
        thumb.write save_thumb

        save_medium = nil
        if image[:width] > 700
          save_medium = File.join(TmpDir, "#{timename}m")
          medium = MiniMagick::Image.open(save_image)
          medium.thumbnail "700x700"
          medium.write save_medium
        end

        hsh = {
          :url => uri,
          :width => image[:width],
          :height => image[:height],
          :size => image[:size],
          :channel => channel,
          :server => config["network"],
          :user => prefix,
          :md5 => digest,
          :handshake => config["handshake"]
        }

        curl = Curl::Easy.http_post(config["service"], Curl::PostField.content("json", hsh.to_json))
        json = JSON.parse curl.body_str

        if json.has_key? "error"
          raise ArgumentError.new json["error"]
        end

        move_dir = config["save_dir"]
        main = File.dirname(File.join(move_dir, json['image']))
         unless File.exists? main
           FileUtils.mkdir_p main
         end

        FileUtils.move save_image, File.join(move_dir, json['image'])
        FileUtils.move save_thumb, File.join(move_dir, json['thumb'])

        unless save_medium.nil?
          FileUtils.move save_medium, File.join(move_dir, json['medium'])
        end
      rescue StandardError => e
        remove(save_image) unless save_image.nil?
        remove(save_thumb) unless save_thumb.nil?
        remove(save_medium) unless save_medium.nil?
        @bot.debug "Error with for image #{uri}: #{e}"
      ensure
        remove filename
      end
    end
  end
end