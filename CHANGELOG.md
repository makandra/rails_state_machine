# Changelog
All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased
- Added: State machine can now use the `:prefix` option to avoid name collision if you define multiple state machines 
  on the same model, and use state names more than once

### Compatible changes

- Fix bug where additional inclusions of `RailsStateMachine::Model` would reset previous defined state machines

### Breaking changes


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
