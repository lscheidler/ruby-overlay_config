# Copyright 2018 Lars Eric Scheidler
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
        @config_filenames.each do |config_filename|
          file = File.expand_path(File.join(base_directory, @config_scope, config_filename))
          if File.exist?(file)
            load_config_file file
          elsif not (files = Dir.glob(file).sort).empty?
            files.each do |f|
              load_config_file f
            end
          else
            @log and @log.debug "#{file} not found, ignoring it."
          end
        end
      end
    end

    # load config file
    #
    # @param file [String] filename to load
    # @note supports yaml and json formatted config files at the moment
    # @raise [Psych::SyntaxError] if a config file is found with .yaml or .yml and incorrect yaml syntax
    # @raise [JSON::ParserError] if a config file is found with .json and incorrect json syntax
    def load_config_file file
      if file.end_with? '.yml' or file.end_with? '.yaml' or @default_parser == :yaml
        append file, YAML::load_file(file)
      elsif file.end_with? '.json' or @default_parser == :json
        append file, JSON::parse(File.read(file))
      else
        @log and @log.warn "ignoring #{file}, file extension not known."
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

    # Deletes the config file at the specified index, returning that element, or nil if the index is out of range.
    #
    # @param index [Integer] index
    def delete_at index
      @config.delete_at index
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
    # @return value
    def [] name
      get name
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

    # check, if one of the config files includes key *name*
    #
    # @param name [String,Symbol] key to check
    def has_key? name
      name_str = name.to_s
      name_sym = name.to_sym

      @config.each do |configfile|
        if configfile[:config][name_str] or configfile[:config][name_sym]
          return true
        end
      end
      return false
    end

    # set config value in defaults hash
    #
    # @param name [String] name of config file entry
    # @param value [Object] value of config file entry
    def []= name, value
      set name, value
    end

    # set config value in defaults hash
    #
    # @param name [String] name of config file entry
    # @param value [Object] value of config file entry
    def set name, value
      unless @defaults.is_a? Hash
        @defaults = {}
        append('<defaults>', @defaults)
      end

      @defaults[name.to_sym] = value
    end

    # iterate over all available config files
    #
    # @yield [filename, config]
    # @yieldparam filename [String] filename of config file
    # @yieldparam config [Hash] content of config file
    def each
      @config.each do |configfile|
        yield configfile[:file], configfile[:config]
      end
    end

    # return loaded filenames
    #
    # @returns [Array] list of loaded configfiles
    def get_filenames
      @config.map do |configfile|
        configfile[:file]
      end
    end

    # clone OverlayConfig::Config object
    def clone
      copy = super
      copy.instance_eval do
        @config = @config.clone
      end
      copy
    end

    def method_missing method_name, *args, &block
      if method_name.to_s.end_with? '='
        set method_name.to_s.gsub(/=$/, ''), *args
      else
        get method_name, *args
      end
    end
  end
end
