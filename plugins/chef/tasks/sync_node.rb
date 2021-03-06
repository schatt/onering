# Copyright 2012 Outbrain, Inc.
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
#


module Automation
  module Tasks
    module Chef
      require 'ridley'

      class SyncNode < Task
        def self.perform(id, *args)

          config = App::Config.get!('chef.client')
          fail("Malformed Chef client configuration; expected Hash but got #{config.class.name}") unless config.is_a?(Hash)

          keyfield = App::Config.get('chef.nodes.keyfield', 'id')
          debug("Using asset field #{keyfield} to locate associated Chef node")

          asset = Asset.find(id)
          fail("Asset #{id} not found") if asset.nil?
          template = {}

          %w{
            chef_environment
            run_list
            default
            normal
            override
          }.each do |a|
            if not (field = App::Config.get("chef.nodes.template.#{a}")).nil?
              if not (value = asset.get(field)).nil?
                template[a] = value
              end
            end
          end

          if template.reject{|k,v|
            v.nil?
          }.empty?
            warn("Asset #{id} does not contain any Chef data to sync, skipping...")
            return false
          end

          chef = Ridley.new({
            :server_url   => config.get(:server_url),
            :client_name  => config.get(:username),
            :client_key   => config.get(:keyfile)
          })

          key = asset.get(keyfield)
          fail("Asset field #{keyfield} is missing, skipping...") if key.nil?

          chef_node = chef.node.find(key)
          fail("Chef node #{key} could not be found for asset #{id}") if chef_node.nil?

          template.each do |node_key, asset_value|
            current_value = chef_node.send(node_key.to_sym)

            case node_key.to_sym
            when :run_list
              asset_value = [*asset_value]
              asset_value = (asset_value.collect{|r|
                if r =~ /^role\[(.*)\]$/
                # only return roles that exist
                  if chef.role.find($1)
                    r
                  else
                    nil
                  end
                else
                  r
                end
              }).compact()

            else
              if current_value.is_a?(Hash)
                asset_value = current_value.stringify_keys().deep_merge(asset_value)
              end
            end

            chef_node.send(:"#{node_key}=", asset_value)
            debug("-> #{node_key} with #{asset_value.class.name}")
          end

          info("Updating Chef node #{key}...")
          chef_node.save()
        end
      end
    end
  end
end
