database = Gemika::Database.new
database.connect

database.rewrite_schema! do

  create_table :parcels do |t|
    t.string :state
    t.string :shipment_tracking
    t.integer :weight
    t.datetime :shipped_at
  end

  create_table :parcel_contents do |t|
    t.integer :parcel_id
    t.string :state
  end

end
