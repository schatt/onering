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

require 'net/ping'
require 'snmp'
require 'ipaddress'
require 'model'
require 'snmp/lib/util'
require 'thread'

class SnmpHost < App::Model::Elasticsearch
  index_name "snmp_hosts"

  field :profile,    :string
  field :properties, :object
  field :failcount,  :integer, :default => 0
  field :created_at, :date,    :default => Time.now
  field :updated_at, :date,    :default => Time.now


  field_prefix :properties

  class<<self
    include App::Helpers::Snmp::Util

    DEFAULT_PING_TIMEOUT = 0.5
    DEFAULT_SNMP_TIMEOUT = 3.5

    def discover(ip_range, options={}, &block)
      mutex = Mutex.new()
      cv = ConditionVariable.new()

      yielder = proc do |response|
        if block_given?
          Onering::Logger.debug("Host #{response[:id]} responded to SNMP query")
          yield response
        end
      end

      addresses = IPAddress.parse(ip_range).to_a

      addresses.each do |address|
        address = address.to_s


        pinger = proc do
        # attempt to ping
          if _ping_host(address, options)
            begin
            # attempt to get SNMP sysName, sysDescr
              SNMP::Manager.open({
                :host      => address,
                :port      => options.get('snmp.port', 161).to_i,
                :timeout   => options.get('snmp.timeout', DEFAULT_SNMP_TIMEOUT).to_f,
                :community => options.get('snmp.community', 'public')
              }) do |snmp|
                properties = {}

                (options.get('snmp.oids', [])+[
                  '1.3.6.1.2.1.1.1.0',
                  '1.3.6.1.2.1.1.5.0'
                ]).uniq.each do |oid|
                  properties[oid] = snmp.get_value(oid).to_s
                end

                yielder.call({
                  :id         => address,
                  :properties => properties
                }) unless properties.empty?
              end
            rescue ::SNMP::RequestTimeout
              nil
            end
          end

          if address == addresses.last.to_s
            mutex.synchronize do
              cv.signal()
            end
          end
        end

        EM.defer(pinger)
      end

      return [mutex, cv]
    end

  private
    def _ping_host(address, options={})
      case options.get('ping.type')
      when 'tcp'
        return Net::Ping::TCP.new(address, options.get('ping.port'), options.get('ping.timeout', DEFAULT_PING_TIMEOUT).to_f).ping?
      when 'udp'
        return Net::Ping::UDP.new(address, options.get('ping.port'), options.get('ping.timeout', DEFAULT_PING_TIMEOUT).to_f).ping?
      else
        return Net::Ping::ICMP.new(address, options.get('ping.port'), options.get('ping.timeout', DEFAULT_PING_TIMEOUT)).ping?
      end
    end
  end
end
