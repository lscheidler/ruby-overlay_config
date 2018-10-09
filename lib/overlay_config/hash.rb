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

# add get function to Hash
class Hash
  # return value for key
  #
  # @param key [String,Array] key
  # @param default [Object] default to return, if key doesn't exist
  # @return [Object] corresponding value or default, if key doesn't exist
  def get key, default: nil
    if key.is_a? Array
      get_iter self, key, default: default
    elsif has_key? key.to_s
      self[key.to_s]
    elsif has_key? key.to_sym
      self[key.to_sym]
    else
      default
    end
  end
  
  private
  # iterate over hash and its subhashes
  #
  # @param hash [Hash]
  # @param keys [Array] array with keys to run through the Hash
  # @param default [Object] default to return, if key doesn't exist
  # @return [Object] corresponding value or default, if key doesn't exist
  def get_iter hash, keys, default: nil
    current_key = keys.shift

    if hash.is_a? Hash and (hash.has_key? current_key.to_s or hash.has_key? current_key.to_sym)
      key = ( hash.has_key? current_key.to_s ) ? current_key.to_s : current_key.to_sym

      if keys.empty?
        hash[key]
      else
        get_iter hash[key], keys, default: default
      end
    else
      default
    end
  end
end
