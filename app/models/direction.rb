class Direction < ApplicationRecord
  self.inheritance_column = :_type_disabled
  enum type: { car: 0, bicycle: 1, walk: 2 }
end
