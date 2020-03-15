# CombineExt

<p align="center">
<img src="https://github.com/CombineCommunity/CombineExt/raw/master/Resources/logo.png" width="45%">
<br /><br />
<a href="https://actions-badge.atrox.dev/CombineCommunity/CombineExt/goto" target="_blank" alt="Build Status" title="Build Status"><img src="https://github.com/CombineCommunity/CombineExt/workflows/CombineExt/badge.svg?branch=master" alt="Build Status" title="Build Status"></a>
<a href="https://codecov.io/gh/CombineCommunity/CombineExt" target="_blank" alt="Code Coverage for CombineExt on codecov" title="Code Coverage for CombineExt on codecov"><img src="https://codecov.io/gh/CombineCommunity/CombineExt/branch/master/graph/badge.svg" alt="Code Coverage for CombineExt on codecov" title="Code Coverage for CombineExt on codecov"/></a>
<br />
<img src="https://img.shields.io/badge/platforms-iOS%2013%20%7C%20macOS 10.15%20%7C%20tvOS%2013%20%7C%20watchOS%206-333333.svg" />
<br />
<a href="https://cocoapods.org/pods/CombineExt" target="_blank"><img src="https://img.shields.io/cocoapods/v/CombineExt.svg?1" alt="CombineExt supports CocoaPods"></a>
<a href="https://github.com/apple/swift-package-manager" target="_blank"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="CombineExt supports Swift Package Manager (SPM)"></a>
<a href="https://github.com/Carthage/Carthage" target="_blank"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="CombineExt supports Carthage"></a>
</p>

CombineExt povides a collection of operators, publishers and utilities for Combine, that are not provided by Apple themselves, but are common in other Reactive Frameworks and standards.

The original inspiration for many of these additions came from many missing pieces from the world of ReactiveX and RxSwift.

All operators, utilities and helpers respect the Combine Contract, including backpressure handling:

### Operators
* [withLatestFrom](#withLatestFrom)
* [flatMapLatest](#flatMapLatest)
* [assign](#assign)
* [materialize](#materialize)
* [values](#values)
* [failures](#failures)
* [dematerialize](#dematerialize)

### Publishers
* [AnyPublisher.create](#anypublisher.create)
* [CurrentValueRelay](#CurrentValueRelay)
* [PassthroughRelay](#PassthroughRelay)

> **Note**: This is still a primal version of this, with much more to be desired. I gladly accept PRs, ideas, opinions, or improvements. Thank you ! :)

## Operators

This section outlines some of the custom Combine operators CombineExt provides

### withLatestFrom

Merges two publishers into a single publisher by combining each value from self with the latest value from the second publisher, if any.

```swift
let taps = PassthroughSubject<Void, Never>()
let values = CurrentValueSubject<String, Never>("Hello")

taps
  .withLatestFrom(values)
  .sink(receiveValue: { print("withLatestFrom: \($0)") })

taps.send()
taps.send()
values.send("World!")
taps.send()
```

#### Output:

```none
withLatestFrom: Hello
withLatestFrom: Hello
withLatestFrom: World!
```

------

### flatMapLatest

Transforms an output value into a new publisher, and flattens the stream of events from these multiple upstream publishers to appear as if they were coming from a single stream of events

Mapping to a new publisher will cancel the subscription to the previous one, keeping only a single subscription active along with its event emissions

**Note**: `flatMapLatest` is a combination of `map` and `switchToLatest`

```swift
let trigger = PassthroughSubject<>
trigger
    .flatMapLatest { performNetworkRequest() }

trigger.send()
trigger.send() // cancels previous request
trigger.send() // cancels previous rquest
```

------

### assign

CombineExt provides custom overloads of `assign(to:on:)` that let you bind a publisher to multiple keypath targets simultaneously.

```swift
var label1: UILabel
var label2: UILabel
var text: UITextField

["hey", "there", "friend"]
    .publisher
    .assign(to: \.text, on: label1,
            and: \.text, on: label2,
            and: \.text, on: text)
```

------

### materialize

Convert any publisher to a publisher of its events. Given a `Publisher<Output, MyError>`, this operator will return a `Publisher<Event<Output, MyError>, Never>`, which means your failure will actually be a regular value, which makes handling much simplerin many use-cases.

```swift
let values = PassthroughSubject<String, MyError>()
enum MyError: Swift.Error {
  case ohNo
}

values
  .materialize()
  .sink(receiveCompletion: { print("materialized: completed with \($0)") },
        receiveValue: { print("materialized: \($0)") })

values.send("Hello")
values.send("World")
values.send("What's up?")
values.send(completion: .failure(.ohNo))
```

#### Output:

```none
materialize: .value("Hello")
materialize: .value("World")
materialize: .value("What's up?")
materialize: .failure(.ohNo)
materialize: completed with .finished
```

------

### values

Given a materialized publisher, publish only the emitted upstream values, omitting failures. Given a `Publisher<Event<String, MyError>, Never>`, this operator will return a `Publisher<Srting, Never>`.

**Note**: This operator only works on publishers that were materialized with the `materialize()` operator.

```swift
let values = PassthroughSubject<String, MyError>()
enum MyError: Swift.Error {
  case ohNo
}

values
  .materialize()
  .values()
  .sink(receiveValue: { print("values: \($0)") })

values.send("Hello")
values.send("World")
values.send("What's up?")
values.send(completion: .failure(.ohNo))
```

#### Output:

```none
values: "Hello"
values: "World"
values: "What's up?"
```

------

### failures

Given a materialized publisher, publish only the emitted upstream failure, omitting values. Given a `Publisher<Event<String, MyError>, Never>`, this operator will return a `Publisher<MyError, Never>`.

**Note**: This operator only works on publishers that were materialized with the `materialize()` operator

```swift
let values = PassthroughSubject<String, MyError>()
enum MyError: Swift.Error {
  case ohNo
}

values
  .materialize()
  .failures()
  .sink(receiveValue: { print("failures: \($0)") })

values.send("Hello")
values.send("World")
values.send("What's up?")
values.send(completion: .failure(.ohNo))
```

#### Output:

```none
failure: MyErrror.ohNo
```

------

### dematerialize

Converts a previously-materialized publisher into its original form. Given a `Publisher<Event<String, MyError>, Never>`, this operator will return a `Publisher<String, MyError>`

**Note**: This operator only works on publishers that were materialized with the `materialize()` operator.

## Publishers

This section outlines some of the custom Combine publishers CombineExt provides

### AnyPublisher.create

A publisher which accepts a factory closure to which you can dynamically push value or completion events.

This lets you easily create custom publishers to wrap any non-publisher asynchronous work, while still respecting the downstream consumer's backpressure demand.

```swift
AnyPublisher<String, MyError>.create { subscriber in
  // Values
  subscriber(.value("Hello"))
  subscriber(.value("World!"))
  
  // Complete with error
  subscriber(.failure(MyError.someError))
  
  // Or, complete successfully
  subscriber(.finished)
}
```

You can also use an `AnyPublisher` initializer with the same signature:

```swift
AnyPublisher<String, MyError> { subscriber in 
    /// ...
}
```

------

### CurrentValueRelay

A `CurrentValueRelay` is identical to a `CurrentValueSubject` with two main differences:

* It only accepts values, but not completion events, which means it cannot fail
* It only publishes a `.finished` event upon deallocation

```swift
let relay = CurrentValueRelay<String>("well...")

relay.sink(receiveValue: { print($0) }) // replays current value, e.g. "well..."

relay.accept("values")
relay.accept("only")
relay.accept("provide")
relay.accept("great")
relay.accept("guarantees")
```

#### Output:

```none
well...
values
only
provide
great
guarantees
```

------

### PassthroughRelay

A `PassthroughRelay` is identical to a `PassthroughSubject` with two main differences:

* It only accepts values, but not completion events, which means it cannot fail
* It only publishes a `.finished` event upon deallocation

```swift
let relay = PassthroughRelay<String>()
relay.accept("well...")

relay.sink(receiveValue: { print($0) }) // does not replay past value(s)

relay.accept("values")
relay.accept("only")
relay.accept("provide")
relay.accept("great")
relay.accept("guarantees")
```

#### Output:

```none
values
only
provide
great
guarantees
```

## Installation

### CocoaPods

Add the following line to your **Podfile**:

```rb
pod 'CombineExt'
```

### Swift Package Manager

Add the following dependency to your **Package.swift** file:

```swift
.package(url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.0.0")
```

### Carthage

Carthage support is offered as a prebuilt binary.

Add the following to your **Cartfile**:

```
github "CombineCommunity/CombineExt"
```

## License

MIT, of course ;-) See the [LICENSE](LICENSE) file. 

The Apple logo and the Combine framework are property of Apple Inc.
