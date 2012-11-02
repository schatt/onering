require 'mongo_mapper'

module App
  module Model
    module Errors
      class ValidationError < Exception; end
    end

    module Utils
      def to_h
        serializable_hash.reject{|k,v|
          ['_type'].include?(k)
        }
      end

      def to_json
        to_h.to_json
      end


      def from_h(hash, merge=true)
        current = to_h
        current.deeper_merge!(hash, {:merge_hash_arrays => true})
        
        current.each do |k,v|
          send("#{k}=", v)
        end

        self
      end

      def from_json(json, merge=true)
        json = JSON.parse(json) if json.is_a?(String)
        json = [json] if json.is_a?(Hash)

        json.each do |j|
          from_h(j, merge)
        end
        self
      end

      def safe_save
        save or raise Errors::ValidationError, errors.collect{|k,v| v }.join("; ")
      end

      def -(other)
        diff = (serializable_hash - other.serializable_hash)
      end
    end

    class Base
      include MongoMapper::Document
      include Utils

      class<<self
        def find_or_create(ids, init={})
          rv = find(ids)

          if not rv
            [*ids].each do |id|
              i = new({'id' => id})

              i.safe_save
            end

            rv = find(ids)
          end

          rv
        end

        def summarize(group_by, properties=[], query=nil, options={})
          group_by = "properties.#{group_by}"
          group_root = group_by.split('.').last.to_sym
          rv = (options[:root] || {})

          q = {
            '$match' => query
          } if query


          c = []
          c << q if query

          c << {
            '$project' => {
              :_id => "$#{group_by}"
            }
          }

          c << {
            '$group' => {
              :_id => "$_id",
              :count => {'$sum' => 1}
            }
          }

        # do initial query on grouping field
          collection.aggregate(c).collect{|i|
            begin
              rv[i['_id']] = {
                :id => i['_id'],
                :count => i['count'].to_i
              }
            rescue
              return nil
            end
          }


        # ------------------------------------------
        # run subqueries for providing field rollups
          unless properties.empty?
            field = properties.pop

            if field
              field_root = field.gsub('.', '_')

              c = []
              c << q if query

            # project the document down to the group and rollup field
              c << {
                '$project' => {
                  :_id => 0,
                  group_root => "$#{group_by}",
                  field_root => "$properties.#{field}"
                }
              }

              #c << {'$unwind' => {'$cond' => [{'$eq' => ['$type', 4]}, "$#{field_root}", "$#{field_root}"]}}


            # group by both group and rollup field, counting the documents in
            # these groups
              c << {
                '$group' => {
                  :_id => {
                    group_root => "$#{group_root}",
                    field_root => "$#{field_root}"
                  },
                  :count => {'$sum' => 1}
                }
              }

            # group by the group field, breaking the rollup field into a set
            # of value-count pairs
              c << {
                '$group' => {
                  :_id => "$_id.#{group_root}",
                  :count => {'$sum' => '$count'},
                  field_root => {
                    '$addToSet' => {
                      :_id => {'$ifNull' => ["$_id.#{field_root}", nil]},
                      :count => '$count'
                    }
                  }
                }
              }

              collection.aggregate(c).collect{|i|
              # add the current filter to the $match query
                qq = (query.clone rescue {'$and' => []})
                qq['$and'] << {group_by => i['_id']}

                #puts qq.to_json

              # recurse into summarize to next rollup properties
                irv = summarize(field, properties, qq, {
                  :root => rv[i['_id']][field_root.to_s]
                })

              # recursion complete, pop the filter off
                qq['$and'].pop

              # set return value
                rv[i['_id']][field_root.to_s] = irv
              }
            end
          end

        # return only the top-level hash values
          rv.collect{|k,v| v }
        end
      end
    end

    class Embedded
      include MongoMapper::EmbeddedDocument
      include Utils
    end
  end
end