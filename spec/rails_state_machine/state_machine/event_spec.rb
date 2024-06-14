describe RailsStateMachine::StateMachine do

  shared_examples 'validation callbacks' do
    it 'will not reset/discard a state on a model that did not try to make a state transition' do
      parcel.force_invalid = true

      expect(parcel.state).to eq('empty')
      expect(parcel.valid?).to eq(false)
      expect(parcel.state).to eq('empty')
    end

    it 'will not revert to an older state that was actually left successfully' do
      expect(parcel.state).to eq('empty')
      parcel.weight = 1
      parcel.pack!
      expect(parcel.state).to eq('filled')

      parcel.force_invalid = true

      expect(parcel.valid?).to eq(false)
      expect(parcel.state).to eq('filled')
    end
  end

  shared_examples 'an invalid record that can not take any transitions' do
    it_behaves_like 'validation callbacks'

    describe '#<event_name>' do
      it 'does not save the record' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_pack?).to be(true)
        expect(parcel.pack).to eq(false)
        expect(parcel.errors[:weight]).to contain_exactly("can't be blank")
        expect(parcel.state_event).to eq('pack')
        expect(parcel.state).to eq('empty')
      end

      context 'with multiple transitions' do
        it 'does not save the record and reverts the model to the last valid state with the next state event' do
          parcel.notes = 'some notes'
          parcel.weight = 1
          expect(parcel.may_pack_and_ship?).to be(true)
          expect(parcel.pack_and_ship).to eq(false)
          expect(parcel.errors[:notes]).to contain_exactly('must be blank')
          expect(parcel.state_event).to eq('ship')
          expect(parcel.state).to eq('filled')
        end
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
        expect(parcel.state_event).to eq('pack')
        expect(parcel.state).to eq('empty')
      end
    end
  end

  shared_examples 'a valid record that can transition to a new state' do
    it_behaves_like 'validation callbacks'

    describe '#<event_name>' do
      it 'saves the record' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_pack?).to be(true)
        expect(parcel.pack).to eq(true)
        expect(parcel.changes).to eq({})
        expect(parcel.state_event).to eq(nil)
        expect(parcel.state).to eq('filled')
        expect(parcel.reload.state).to eq('filled')
      end
    end

    describe '#<event_name>!' do
      it 'saves the record' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_pack?).to be(true)
        expect { parcel.pack! }.not_to raise_error
        expect(parcel.state_event).to eq(nil)
        expect(parcel.state).to eq('filled')
        expect(parcel.reload.state).to eq('filled')
      end
    end

    describe '#state_event=' do
      it 'does not set the state on assignment' do
        parcel.state_event = 'pack'

        expect(parcel.state_event).to eq('pack')
        expect(parcel.state).to eq('empty')
      end

      it 'sets the state before validation' do
        parcel.state_event = 'pack'
        parcel.validate

        expect(parcel.state_event).to eq(nil)
        expect(parcel.state).to eq('filled')
      end

      it 'will transition on save' do
        parcel.state_event = 'pack'
        expect(parcel.save).to eq true
        expect(parcel.state_event).to eq(nil)
        expect(parcel.state).to eq('filled')
        expect(parcel.reload.state).to eq('filled')
      end

      it 'adds an error on the state event if the transition is invalid' do
        parcel.state_event = 'ship'
        parcel.save

        expect(parcel.errors[:state_event]).to contain_exactly('is invalid')
        expect(parcel.state).to eq('empty')
        expect(parcel.state_event).to eq('ship')
      end
    end
  end

  shared_examples 'a valid record that tries to take an invalid transition' do
    describe '#<event_name>' do
      it 'returns false and adds an error to the state event attribute' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_ship?).to be(false)
        expect(parcel.ship).to eq(false)

        expect(parcel.errors[:state_event]).to contain_exactly('is invalid')
        expect(parcel.state_event).to eq('ship')
        expect(parcel.state).to eq('empty')
      end
    end

    describe '#<event_name>!' do
      it 'raises an error and adds an error to the state event attribute' do
        expect(parcel.state).to eq('empty')
        expect(parcel.may_ship?).to be(false)
        expect { parcel.ship! }.to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: State event is invalid'
        )

        expect(parcel.errors[:state_event]).to contain_exactly('is invalid')
        expect(parcel.state_event).to eq('ship')
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

  it 'does not lose unsaved changes on models that have been saved before (BUGFIX)' do
    parcel = Parcel.create!(weight: 1)
    parcel.weight = 2
    parcel.pack!
    expect(parcel.reload.weight).to eq 2
  end

  context 'for multiple machines' do

    it 'transitions states independently' do
      parcel = Parcel.create!(weight: 1)
      expect(parcel.state).to eq 'empty'
      expect(parcel.payment_state).to eq 'pending'

      expect(parcel.payment_fails).to eq true
      expect(parcel.state).to eq 'empty'
      expect(parcel.payment_state).to eq 'failed'

      expect(parcel.pack).to eq true
      expect(parcel.state).to eq 'filled'
      expect(parcel.payment_state).to eq 'failed'
    end

    it 'can transition several machines at the same time' do
      parcel = Parcel.create!(weight: 1)

      parcel.state_event = 'pack'
      parcel.payment_state_event = 'payment_fails'
      expect(parcel.save).to eq true

      expect(parcel.state). to eq 'filled'
      expect(parcel.payment_state).to eq 'failed'
    end

    it 'allows one machine to transition another' do
      parcel = Parcel.create!(weight: 1)

      expect(parcel.payment_succeeds).to eq true
      expect(parcel.payment_state).to eq 'paid'
      expect(parcel.state).to eq 'shipped'
    end

  end

end
