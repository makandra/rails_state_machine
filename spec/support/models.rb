class Parcel < ActiveRecord::Base
  include RailsStateMachine::Model

  has_one :parcel_content, autosave: true

  before_validation { callbacks.push('before_validation (model)') }
  before_save { callbacks.push('before_save (model)') }
  after_save { callbacks.push('after_save (model)') }
  after_commit { callbacks.push('after_commit (model)') }

  validates :weight, presence: true, if: :filled?

  attr_accessor :force_invalid
  validates :force_invalid, inclusion: { in: [nil] } # Set to any non-nil value to force an invalid record

  state_machine do
    state :empty, initial: true
    state :filled
    state :shipped

    event :destroy_content do
      transitions from: :empty, to: :empty

      after_save do
        parcel_content&.destroy!
      end
    end

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

      before_save { weight_was } # trigger deprecation warning in Rails 5.1 without our workaround

      after_save { callbacks.push('after_save for ship (state machine)') }
      after_commit { callbacks.push('after_commit for ship (state machine)') }
    end
  end

  state_machine(:payment_state) do
    state :pending, initial: true
    state :paid
    state :failed

    event :payment_succeeds do
      transitions from: :pending, to: :paid

      before_save do
        callbacks.push('before_save for payment_succeeds (state machine)')
      end

      after_save do
        callbacks.push('after_save for payment_succeeds (state machine)')
        pack_and_ship
      end

      after_commit do
        callbacks.push('after_commit for payment_succeeds (state machine)')
      end
    end

    event :payment_fails do
      transitions from: :pending, to: :failed
    end
  end

  def callbacks
    @callbacks ||= []
  end
end

class ParcelContent < ActiveRecord::Base
  include RailsStateMachine::Model

  belongs_to :parcel

  state_machine do
    state :empty, initial: true
  end
end
