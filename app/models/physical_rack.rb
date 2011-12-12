class PhysicalRack
  include Mongoid::Document
  field :index, :type => Integer
  field :name, :type => String
  has_many :us
  belongs_to :datacenter
end
