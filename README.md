# Rails State Machine [![Tests](https://github.com/makandra/rails_state_machine/workflows/Tests/badge.svg)](https://github.com/makandra/rails_state_machine/actions?query=branch:master)

Rails State Machine is a ActiveRecord-bound state machine.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_state_machine'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_state_machine

## Usage

Your model needs a `state` attribute. You can then simply define your state machine as follows.

```ruby
class YourModel < ApplicationRecord
  include RailsStateMachine::Model

  state_machine do
    state :draft, initial: true
    state :review_pending
    state :approved
    state :rejected

    event :request_review do
      transitions from: [:draft, :rejected], to: :review_pending
    end

    event :approve do
      transitions from: :review_pending, to: :approved
    end

    event :reject do
      transitions from: :review_pending, to: :rejected
    end
  end
end
```

This will define instance methods with the names of those events, and constants like `STATE_DRAFT` on the model.
If a state is configured as `initial: true`, new instances will be assigned this state.

A model instance offers these state machine methods:

- `<state_name>?` to find out if this is the current state.
- `<event_name>` call an event and transition into a new state. The record will be `save`d, if valid.
- `<event_name>!` call an event and transition into a new state. Calls `save!` to save the record.
- `may_<event_name>?` to find out if an event transition could be taken. Note that this will not validate if the model is valid afterwards.
- `state_event=` to take a state event, but not save yet. Commonly used for forms where the controller takes a "state_event" param and saves.
- `state_event` to get the name of the event that will be called

Should you ever need to query the state machine for its states or events, it is accessible via `state_machine` class or instance methods on the model. See [`state_machine.rb`](https://github.com/makandra/rails_state_machine/blob/master/lib/rails_state_machine/state_machine.rb) for a list of available methods. This is mostly helpful in tests.

If you want an event to be available for a different edge in your graph, you may define multiple `transitions` per event:

```ruby
event :request_feedback do
  transitions from: :draft, to: :draft
  transitions from: :review_pending, to: :review_pending
end
```

## Event callbacks

Here is a list with all the available callbacks, listed in the same order in which they will get called during the respective operations. The callbacks are chained with the existing active record callbacks on the model.

* `before_validation`
* `before_save`
* `after_save`
* `after_commit`

Example:

```ruby
event :request_review do
  transitions from: [:draft, :rejected], to: :review_pending

  before_validation do
    # this callback is chained with existing `before_validation` callbacks of the model
  end

  before_save do
    # this callback is chained with existing `before_save` callbacks of the model
  end

  after_save do
    # this callback is chained with existing `after_save` callbacks of the model
  end

  after_commit do
   # this callback is chained with existing `after_commit` callbacks of the model
  end
end
```

## Other state attributes and multiple state machines on the same model

To use a state attribute other than the default `state`, pass it to the `.state_machine` method:

```ruby
state_machine :review_state do
  # ...
end
```

This also allows you to define multiple state machines on the same model. Note that event
and state names still have to be unique for the whole model.

If you define multiple state machines on the same model, and use state names more than once,
you must use a prefix to avoid name collisions.

A prefix may be specified by passing the `:prefix` option when declaring your state machine:

```ruby
state_machine :review_state, prefix: 'some_prefix' do
  # ...
end
```

Note: The `prefix` option is designed to apply only to constants and state methods **defined by the gem**.

**State event names** are manually defined by the developer and thus not altered even if the `prefix` 
option is used. It's advised to review them regarding potential naming collision and clarity when
 introducing the `prefix` method.

## Taking multiple transitions

You can safely take a second transition inside an after_save callback. All relevant
callbacks will be run.

```ruby
state_machine do
  state :draft, initial: true
  state :review_pending
  state :approved

  event :request_review do
    transitions from: [:draft, :rejected], to: :review_pending

    after_save do
      if auto_approve?
        approve
      end
    end
  end

  event :approve do
    transitions from: :review_pending, to: :approved
  end
end
```

## Development

There are tests in `spec`. We only accept PRs with tests. To run tests:

- Install Ruby 2.4.6
- Copy the file `spec/support/database.sample.yml` to `spec/support/database.yml` and enter your PostgreSQL credentials. You can create the database afterwards with `createdb rails_state_machine_test`.
- Run `bin/setup` to install development dependencies.
- Run tests using `bundle exec rspec`

We recommend to test large changes against multiple versions of Ruby and multiple dependency sets. Supported combinations are configured in `.github/workflows/test.yml`. We provide some rake tasks to help with this:

- Install development dependencies using `rake matrix:install`
- Run tests using `rake matrix:spec`

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

If you would like to contribute:

- Fork the repository.
- Push your changes **with passing specs**.
- Send us a pull request.

We want to keep this gem leightweight and on topic. If you are unsure whether a change would make it into the gem, open an issue and discuss.

Note that we have configured GitHub Actions to automatically run tests in all supported Ruby versions and dependency sets after each push. We will only merge pull requests after a green workflow build.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

Arne Hartherz, Emanuel Denzel, Tobias Kraze from [makandra](https://makandra.de/).
