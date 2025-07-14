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

  it 'does use different state machine objects for duplicated records' do
    parcel = Parcel.create!(weight: 1)
    parcel_dup = parcel.dup
    parcel_dup.save!

    expect(parcel_dup.may_pack?).to be true
    expect(parcel.may_pack?).to be true

    expect { parcel.pack_and_ship! }.to change { parcel.reload.state }.from('empty').to('shipped')
      .and not_change { parcel_dup.reload.state }

    expect(parcel_dup.may_pack?).to be true
    expect(parcel.may_pack?).to be false
  end

end
