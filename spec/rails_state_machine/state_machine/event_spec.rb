describe RailsStateMachine::StateMachine do

  shared_examples 'an invalid record that can not take any transitions' do
    describe '#<event_name>' do
      let(:error_messages) { parcel.errors.messages }

      it 'does not save the record' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_pack?).to be(true)
        expect(parcel.pack).to eq(false)
        expect(error_messages[:weight]).to include("can't be blank")
        expect(parcel.state).to eq('empty')
      end
    end

    describe '#<event_name>!' do
      it 'raises an error' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_pack?).to be(true)
        expect { parcel.pack! }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Weight can't be blank"
        )
        expect(parcel.state).to eq('empty')
      end
    end
  end

  shared_examples 'a valid record that can transition to a new state' do
    describe '#<event_name>' do
      it 'saves the record' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_pack?).to be(true)
        expect(parcel.pack).to eq(true)
        expect(parcel.changes).to eq({})
        expect(parcel.reload.state).to eq('filled')
      end
    end

    describe '#<event_name>!' do
      it 'saves the record' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_pack?).to be(true)
        expect { parcel.pack! }.not_to raise_error
        expect(parcel.reload.state).to eq('filled')
      end
    end
  end

  shared_examples 'a valid record that tries to take an invalid transition' do
    describe '#<event_name>' do
      it 'raises an error' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_ship?).to be(false)
        expect { parcel.ship }.to raise_error(
          RailsStateMachine::Event::TransitionNotFoundError,
          'ship does not transition from empty; defined are [#<struct RailsStateMachine::Event::Transition from=:filled, to=:shipped>]'
        )
        expect(parcel.state).to eq('empty')
      end
    end

    describe '#<event_name>!' do
      it 'raises an error' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_ship?).to be(false)
        expect { parcel.ship! }.to raise_error(
          RailsStateMachine::Event::TransitionNotFoundError,
          'ship does not transition from empty; defined are [#<struct RailsStateMachine::Event::Transition from=:filled, to=:shipped>]'
        )
        expect(parcel.state).to eq('empty')
      end
    end
  end

  context 'with a new record' do
    it_behaves_like 'an invalid record that can not take any transitions' do
      subject(:parcel) { Parcel.new }
    end

    it_behaves_like 'a valid record that can transition to a new state' do
      subject(:parcel) { Parcel.new(weight: 1) }
    end

    it_behaves_like 'a valid record that tries to take an invalid transition' do
      subject(:parcel) { Parcel.new }
    end
  end

  context 'with a persisted record' do
    it_behaves_like 'an invalid record that can not take any transitions' do
      subject(:parcel) { Parcel.create! }
    end

    it_behaves_like 'a valid record that can transition to a new state' do
      subject(:parcel) { Parcel.create!(weight: 1) }
    end

    it_behaves_like 'a valid record that tries to take an invalid transition' do
      subject(:parcel) { Parcel.create! }
    end
  end

end
