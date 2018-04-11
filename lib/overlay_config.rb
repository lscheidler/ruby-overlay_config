require 'json'
require 'logger'
require 'yaml'

require "overlay_config/version"
require "overlay_config/hash"

# overlay config module
module OverlayConfig
  # Config file class, which loads config files from different locations
  class Config
    # @param config_scope [String]
    # @param config_filenames [Array] filenames of config files
    # @param config_base_directories [Array] config file paths to check for a configfile
    # @param default_parser [Symbol] default parser to use, if file extension is unknown. Supported symbols: :yaml, :json
    # @param defaults [Hash] default config settings
    # @param log [Logger] use *log* for logging output
    # @raise [Psych::SyntaxError] if a config file is found with .yaml or .yml and incorrect yaml syntax
    # @raise [JSON::ParserError] if a config file is found with .json and incorrect json syntax
    def initialize config_scope: 'overlay_config',
                   config_filenames: ['config.json', 'credentials.json'],
                   config_base_directories: ["#{ENV['HOME']}/.config", '/etc'],
                   default_parser: nil,
                   defaults: nil,
                   log: nil
      @config_scope = config_scope
      @config_filenames = config_filenames
      @config_base_directories = config_base_directories
      @default_parser = default_parser
      @defaults = defaults
      @log = log

      load_config_files
      append('<defaults>', @defaults) if @defaults.is_a? Hash
    end

    # load config files
    #
    # @note supports yaml and json formatted config files at the moment
    # @raise [Psych::SyntaxError] if a config file is found with .yaml or .yml and incorrect yaml syntax
    # @raise [JSON::ParserError] if a config file is found with .json and incorrect json syntax
    def load_config_files
      @config = []
      @config_base_directories.each do |base_directory|
        base_directory = base_directory + '/' unless base_directory.end_with? '/'

        @config_filenames.each do |config_filename|
          file = base_directory + @config_scope + '/' + config_filename
          if file and File.exist?(f = File.expand_path(file))
            if f.end_with? '.yml' or f.end_with? '.yaml' or @default_parser == :yaml
              @config << ({file: f, config: YAML::load_file(f)})
            elsif f.end_with? '.json' or @default_parser == :json
              @config << ({file: f, config: JSON::parse(File.read(f))})
            else
              @log and @log.warn "ignoring #{file}, file extension not known."
            end
          else
            @log and @log.debug "#{file} not found, ignoring it."
          end
        end
      end
    end

    # append config file hash
    #
    # @param filename [String] filename of config file
    # @param config [Hash] config hash
    def append filename, config
      @config << ({
        file: filename,
        config: config
      })
    end

    # insert config file hash at index
    #
    # @param index [Integer] position to insert hash
    # @param filename [String] filename of config file
    # @param config [Hash] config hash
    def insert index, filename, config
      @config.insert(index, {
        file: filename,
        config: config
      })
    end

    # return length of config file array
    #
    # @return length of config file array
    def length
      @config.length
    end

    # go through all config files and return first value of name found in config files
    #
    # @param name [String] name of config file entry
    # @param default default value, if config setting isn't found
    # @return value
    def get name, default: nil
      name_str = name.to_s
      name_sym = name.to_sym

      value = nil
      found = false
      @config.each do |configfile|
        if value = configfile[:config][name_str] or value = configfile[:config][name_sym]
          found = true
          break
        end
      end
      value = default if value.nil? and not found
      value
    end
  end
end
