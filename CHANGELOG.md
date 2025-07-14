# Changelog
All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

### Compatible changes
-

### Breaking changes
-

## 3.1.1 2025-07-14

### Compatible changes

- Fix duplicated model instances from sharing identical state machine references

## 3.1.0 2025-01-21

### Compatible changes

- Added support for Ruby 3.4

## 3.0.0 2024-06-21

### Breaking changes

- Changed: Setting the `<state_name>_event` to an invalid event adds an error to the attribute instead of raising a `TransitionNotFoundError` error.
- Changed: Calling `<event_name>` with an invalid event adds an error to the `<state_name>_event` attribute instead of raising a `TransitionNotFoundError` error.
- Changed: Calling `<event_name>!` with an invalid event adds an error to the `<state_name>_event` attribute an raises a `ActiveRecord::RecordInvalid` error instead of a `TransitionNotFoundError` error.
- Changed: The `<state_name>_event` type was changed to `ActiveModel::Attributes`.
- Changed: `#find_event` returns `nil` in case the event is missing, previously it raised a `KeyError` error.
- Changed: The transition of a `<state_name>_event` is executed in a prepended `before_validation` callback. If the transition is possible, the `<state_attribute>` is changed and the `<state_name>_event` is set to `nil` afterwards. If the transition is not possible, the `<state_attribute>` is not changed and the `<state_name>_event` keeps the set value.

Before:

```ruby
order.update(state_event: 'finish') # => RailsStateMachine::Event::TransitionNotFoundError
order.finish # => RailsStateMachine::Event::TransitionNotFoundError
order.finish! # => RailsStateMachine::Event::TransitionNotFoundError
```

After:

```ruby
order.update(state_event: 'finish') # => false (state_event has the error :invalid)
order.finish # => false (state_event has the error :invalid)
order.finish! # => ActiveRecord::RecordInvalid (state_event has the error :invalid)
```

Upgrade examples:

```ruby
# Before the upgrade you might have rescued RailsStateMachine::Event::TransitionNotFoundError in e.g. a controller
def update
  build_user
  if @user.save
    flash[:success] = 'User saved!'
    redirect_to @user
  else
    flash.now[:error] = 'User could not be saved!'
    render(:edit, status: :unprocessable_entity)
  end
rescue RailsStateMachine::Event::TransitionNotFoundError
  flash.now[:error] = 'State event not valid anymore, maybe reload the page?'
  render(:edit, status: :unprocessable_entity)
end

# After upgrade you can either show a flash message or show an error message in your view for the <state>_event attribute
def update
  build_user
  if @user.save
    flash[:success] = 'User saved!'
    redirect_to @user
  else
    flash.now[:error] = @user.errors.include?(:state_event) ? 'State event not valid anymore, maybe reload the page?' : 'User could not be saved!'
    render(:edit, status: :unprocessable_entity)
  end
end
```

## 2.2.0 2023-12-06

### Compatible changes

- Added: State machine can now use the `:prefix` option to avoid name collision if you define multiple state machines
  on the same model, and use state names more than once
- Fix bug where additional inclusions of `RailsStateMachine::Model` would reset previous defined state machines

## 2.1.1 2022-03-16

### Compatible changes

- Enabled MFA for RubyGems

## 2.1.0 2021-03-30

### Compatible changes

- Added support for Ruby 3.0.

## 2.0.0 2019-09-30

### Compatible changes

- Added: State machine can now use an attribute other than `state` to represent the machine's state.
- Added: It is now possible to define multiple state machines on the same model. States and event names
  have to differ, though.

### Breaking changes

- Removed: Dropped support for adding a state machine to a model without including `RailsStateMachine::Model`.


## 1.1.3 2019-08-12

### Compatible changes

- Fix a bug sometimes causing unsaved changes to be lost on state transitions.

## 1.1.2 2019-03-22

### Compatible changes

- Fix bug where state was set to an older state when making a record invalid after successfully transitioning to a new state.

## 1.1.1 2019-03-22

### Compatible changes

- Fix bug where state was set to `nil` by calling `valid?` on invalid records without making a state transition.

## 1.1.0 2019-02-07

### Compatible changes

- Fix bug when accessing autosaved association within transition

## 1.0.0 2018-09-04

### Compatible changes

- First version.
