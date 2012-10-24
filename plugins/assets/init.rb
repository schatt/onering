require 'controller'
require 'mongo_mapper'
require 'assets/lib/helpers'
require 'assets/models/device'

module App
  class Base < Controller
    include Helpers

    namespace '/devices' do
    # device by id
      get '/:id' do
        device = Device.find(params[:id])
        return 404 if not device
        device.to_json
      end

      %w{
        /?
        /:id
      }.each do |route|
        post route do
          rv = []
          json = JSON.parse(request.env["rack.input"].read)
          json = [json] if json.is_a?(Hash)

          json.each do |o|
            id = (params[:id] || o['id'])

            device = Device.find_or_create(id)
            device.from_json(o)
            device.safe_save

            rv << device
          end

          rv.to_json
        end
      end


    # set device user properties
      get '/:id/set/*' do
        device = Device.find(params[:id])
        return 404 if not device

        if not params[:splat].empty?
          up = device.user_properties
          pairs = params[:splat].first.split('/')

        # set each property
          pairs.evens.zip(pairs.odds).each do |pair|
            up[pair.first] = pair.last
          end

        # set and save
          device.user_properties = up
          device.safe_save
        end

        device.to_json
      end



    # /devices/find
    # search for devices by fields
      get '/find/*' do
        q = (params[:splat].empty? ? {} : params[:splat].first)
        Device.where(urlquerypath_to_mongoquery(q)).to_json
      end


      %w{
        /list/stale/?
        /list/stale/:age
      }.each do |r|
        get r do
          Device.where({
            'updated_at' => {
              '$lte' => (params[:age] || 4).to_i.hours.ago
            }
          }).to_json
        end
      end

    # /devices/list
    # list field values
      %w{
        /list/:field/?
        /list/:field/where/*
      }.each do |r|
        get r do
          q = urlquerypath_to_mongoquery(params[:splat].empty? ? nil : params[:splat].first)
          Device.sort("properties.#{params[:field]}".to_sym.asc)
          Device.collection.distinct("properties.#{params[:field]}", q).compact.to_json
        end
      end


    # /devices/summary
      %w{
        /summary/by-:field/?
        /summary/by-:field/*/?
      }.each do |r|
        get r do
          fields = params[:splat].first || ''
          rv = Device.summarize(params[:field], fields.split('/'))
          rv.to_json
        end
      end
    end
  end
end