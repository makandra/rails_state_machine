describe RailsStateMachine::Model do

  subject(:parcel_class) { Parcel }

  describe '.states' do
    it 'returns the list of available states' do
      expect(parcel_class.states).to eq([:empty, :filled, :shipped])
    end
  end

  describe '.state_events' do
    it 'returns the list of available state events' do
      expect(parcel_class.state_events).to eq([:destroy_content, :pack, :pack_and_ship, :ship])
    end
  end

end
