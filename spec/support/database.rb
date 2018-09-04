database = Gemika::Database.new
database.connect

database.rewrite_schema! do

  create_table :parcels do |t|
    t.string :state
    t.string :shipment_tracking
    t.integer :weight
    t.datetime :shipped_at
  end

end
