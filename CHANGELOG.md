# Changelog
All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 1.1.1 2019-03-22

### Compatible changes

- Fix bug where state was set to `nil` by calling `valid?` on invalid records without making a state transition.

## 1.1.0 2019-02-07

### Compatible changes

- Fix bug when accessing autosaved association within transition

## 1.0.0 2018-09-04

### Compatible changes

- First version.
