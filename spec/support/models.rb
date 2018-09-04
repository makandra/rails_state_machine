class Parcel < ActiveRecord::Base
  include RailsStateMachine::Model

  before_validation { callbacks.push('before_validation (model)') }
  before_save { callbacks.push('before_save (model)') }
  after_save { callbacks.push('after_save (model)') }
  after_commit { callbacks.push('after_commit (model)') }

  validates :weight, presence: true, if: :filled?

  state_machine do
    state :empty, initial: true
    state :filled
    state :shipped

    event :pack do
      transitions from: :empty, to: :filled

      before_validation { callbacks.push('before_validation for pack (state machine)') }
      before_save { callbacks.push('before_save for pack (state machine)') }
      after_save { callbacks.push('after_save for pack (state machine)') }
      after_commit { callbacks.push('after_commit for pack (state machine)') }
    end

    event :pack_and_ship do
      transitions from: :empty, to: :filled

      after_save do
        callbacks.push('after_save for pack_and_ship (state machine)')
        ship!
      end

      after_commit { callbacks.push('after_commit for pack_and_ship (state machine)') }
    end

    event :ship do
      transitions from: :filled, to: :shipped

      after_save { callbacks.push('after_save for ship (state machine)') }
      after_commit { callbacks.push('after_commit for ship (state machine)') }
    end
  end

  def callbacks
    @callbacks ||= []
  end
end
