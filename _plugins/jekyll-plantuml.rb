require 'open3'
require 'fileutils'

module Jekyll
  module Converters
    class PlantUML < Jekyll::Converter
      attr_accessor :config

      safe true
      priority :normal

      def initialize(config)
        @config = config
      end

      def matches(ext)
        ext =~ /^\.(wsd|pu|puml|plantuml|iuml)$/i
      end

      def output_ext(ext)
        ".#{extension}"
      end

      def convert(content)
        cache.getset(content) do
          cmd = "java -Djava.awt.headless=true #{java_args} -jar #{plantuml_jar} -t#{type} #{plantuml_args} -pipe"
          result, status = Open3.capture2(cmd, :stdin_data=>content, :binmode=>true)
          result
        end
      end

      def plantuml_jar
        File.expand_path(config['plantuml']['plantuml_jar'] || 'plantuml.jar')
      end

      def type
        config['plantuml']['type'] || 'svg'
      end

      def plantuml_args
        config['plantuml']['plantuml_args'] || ''
      end

      def java_args
        config['plantuml']['java_args'] || ''
      end

      # Support all types otlined in "Types of Output File" table
      # https://plantuml.com/command-line 
      def extension
        config['plantuml']['extension'] || begin
          ext = type.split(':', 2).first
          case ext
          when 'braille'
            ext = 'png'
          when 'txt'
            ext = 'atxt'
          end
          ext
        end
      end

      def cache
        @@cache ||= Jekyll::Cache.new("Jekyll::Converters::PlantUML")
      end
    end
  end
end

module Jekyll
  module Generators
    class PlantUML < Jekyll::Generator
      attr_accessor :site

      safe true
      priority :normal

      def initialize(site)
        @site = site
      end

      def generate(site)
        @site = site
        site.pages.concat(pages)
        site.static_files -= plantuml_files
      end

      private

      # An array of potential Jekyll::Pages to add
      def pages
        plantuml_files.map { |static_file| page_from_static_file(static_file) }
      end

      # An array of Jekyll::StaticFile's with a site-defined markdown extension
      def plantuml_files
        site.static_files.select { |file| converter.matches(file.extname) }
      end

      # Given a Jekyll::StaticFile, returns the file as a Jekyll::Page
      def page_from_static_file(static_file)
        base = static_file.instance_variable_get("@base")
        dir  = static_file.instance_variable_get("@dir")
        name = static_file.instance_variable_get("@name")
        page = Jekyll::Page.new(site, base, dir, name)
        page.data["layout"] = nil
        return page
      end

      def converter
        @converter ||= site.find_converter_instance(Jekyll::Converters::PlantUML)
      end
    end
  end
end
