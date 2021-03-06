describe RailsStateMachine::StateMachine do

  describe 'updating an object' do
    subject(:parcel) { Parcel.create(weight: 1) }

    before { parcel.callbacks.clear }

    it 'runs all supported callbacks' do
      expect { parcel.pack! }.to change { parcel.callbacks }.from([]).to([
        'before_validation (model)',
        'before_validation for pack (state machine)',
        'before_save (model)',
        'before_save for pack (state machine)',
        'after_save (model)',
        'after_save for pack (state machine)',
        'after_commit for pack (state machine)',
        'after_commit (model)'
      ])
    end

    context 'when state change is made in an `after_safe` callback' do
      it 'changes the state correctly' do
        expect { parcel.pack_and_ship! }.to change { parcel.reload.state }.from('empty').to('shipped')
      end

      it 'runs the `after_commit` callbacks in the correct order' do
        expect { parcel.pack_and_ship! }.to change { parcel.callbacks }.from([]).to([
          'before_validation (model)',
          'before_save (model)',
          'after_save (model)',
          'after_save for pack_and_ship (state machine)',
          # "pack_and_ship" calls "ship" which saves the model again (and performs validations again)
          'before_validation (model)',
          'before_save (model)',
          'after_save (model)',
          'after_save for ship (state machine)',
          'after_commit for pack_and_ship (state machine)',
          'after_commit for ship (state machine)',
          'after_commit (model)'
        ])
      end

    end

    context 'when `after_save` transitions another state machine' do
      it 'changes the state correctly' do
        expect { parcel.payment_succeeds! }.to change { [parcel.reload.state, parcel.payment_state] }.from(['empty', 'pending']).to(['shipped', 'paid'])
      end

      it 'runs the all callbacks in the correct order' do
        parcel.payment_succeeds!
        expect(parcel.callbacks).to eq [
          'before_validation (model)',
          'before_save (model)',
          'before_save for payment_succeeds (state machine)',
          'after_save (model)',
          'after_save for payment_succeeds (state machine)',
          # transitions other machine
          'before_validation (model)',
          'before_save (model)',
          'after_save (model)',
          'after_save for pack_and_ship (state machine)',
          # transitions again
          'before_validation (model)',
          'before_save (model)',
          'after_save (model)',
          'after_save for ship (state machine)',
          'after_commit for payment_succeeds (state machine)',
          'after_commit for pack_and_ship (state machine)',
          'after_commit for ship (state machine)',
          'after_commit (model)'
        ]
      end
    end

  end

end
