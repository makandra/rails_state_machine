describe RailsStateMachine::StateMachine do

  describe '#state' do
    subject(:parcel) { Parcel.new }

    it 'has an initial state' do
      expect(parcel.state).to eq('empty')
      expect(parcel.empty?).to be(true)
    end

    # it just behalves like assigning any other attribute to an instance
    it 'does not persist a new state assignment' do
      parcel = Parcel.create!
      parcel.state = :filled

      expect { parcel.reload }.to change { parcel.state }.from('filled').to('empty')
    end
  end

  describe '#destroy_content' do
    it 'does not crash while accessing the parcel_content association within a state transition' do
      parcel = Parcel.create!
      parcel.build_parcel_content.save!

      parcel = Parcel.first
      expect { parcel.destroy_content! && parcel.reload.parcel_content }.to_not raise_error
    end
  end

end
