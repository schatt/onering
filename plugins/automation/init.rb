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

require 'controller'
require 'assets/models/asset'
require 'automation/lib/task'

Automation::Tasks::Task.load_all()

module App
  class Base < Controller
    include Helpers


    namespace '/api/automation' do
      namespace '/tasks' do
        helpers do
          def run_task(name, *args)
            task = Automation::Tasks::Task.as_task(name)
            return 404 unless task

            case params[:priority].to_s.downcase.to_sym
            when :critical
              Automation::Tasks::Task.run_critical(name, *args)
            when :high
              Automation::Tasks::Task.run_high(name, *args)
            when :low
              Automation::Tasks::Task.run_low(name, *args)
            else
              if params[:priority].nil?
                Automation::Tasks::Task.run(name, *args)
              else
                Automation::Tasks::Task.run_priority(name, params[:priority].to_sym, *args)
              end
            end

            return 200
          end
        end

        %w{
          /run/:name/?
          /run/:name/*/?
        }.each do |r|
          get r do
            if params[:splat].first.nil?
              run_task(params[:name])
            else
              run_task(params[:name], *params[:splat].first.split('/'))
            end

          end

          post r do
            run_task(params[:name], MultiJson.load(request.env['rack.input'].read))
          end
        end
      end
    end
  end
end
