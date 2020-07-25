# Concise MVVM for iOS

Concise MVVM makes it quick and easy to create view models for MVVM. In order to make MVVM work well, view models need to be able to publish state changes to 
the view. While there are many tools that help you do this it typically requires a lot of boiler plate and of repetitive work. Concise MVVM allows you to focus on the business 
logic and handles the details for you. Concise MVVM also easily integrates with existing publish/subscribe systems such as Rx and Combine.

Another issue that can complicate MVVM development is publishing chages from the model layer to view models. Concise also presents a low friction toolset for doing this. 

Concise consists of a core library (**Concise**) and several optional integrations:

 - **ConciseRx** - Integration with Reactive Extensions. 
 - **ConciseRealm** - Integration with Realm. Allows Realm objects to function as your model while changes are trasparently published to your View Models, which can, in turn, 
 publish the changes to your views.
 - **ConciseActions** - Concise actions provide a persistent method for performing updates to external systems (such as API's.) Using Actions allows you to make changes locally that are reflected in your application while making the changes to the server in the background. If the app is offline, the action can be persisted until internet access is avaiable.
 
 ## Origins
 
 Concise MVVM was developed by [ProductOps](https://www.productops.com) to speed development of MVVM-based applications for mobile products. ProductOps contributed Concise MVVM to the open source community in July, 2020 to allow wider usage of this platform and encourage community support. This project is licensed under the [MIT License](LICENSE.txt).

## Usage

Concise MVVM supports [Carthage](https://github.com/Carthage/Carthage) for package management. Add the following to your `Cartfile`` file:

    github "https://github.com/ConciseMVVM/concise-ios.git"

After building you will have the following frameworks in `Carthage/Build/iOS` :

- **Concise.framework** - This is the core Concise library. It has no dependencies, except for those built into Swift/iOS (Foundation with some integrations requiring Combine, SwiftUI and Network)
- **ConciseRx** - Integration with Reactive Extensions. Requires **Concise.framework** and **ReactiveX/RxSwift**
- **ConciseRealm** - Integration with Realm.  Requires  **Concise.framework** and **realm/realm-cocoa**
- **ConciseActions** - Suppoort for dirable mutations. Requires **Concise.framework**, **ConciseRealm.framework** and **realm/realm-cocoa**

Integrate these as you would any other Carthage framework.

## Roadmap

There is lots to be done! If you are interested in contributing, please let us know!

- **Documentation.** We need documentation of the libraries themselves, sample apps and a tutorial.
- **CocoaPods & Swift Package Manager Integration.** 
- **Threading support.** Concise currently only supports the main thread. Supporting multiple threads involves binding each AbstractVar to a single thread
  (with an associated `Domain` for each thread) and creating a *proxy* class that can safely move values between threads.
- **UIKit Bindings.** Currently, you can use RX to bind values to UIKit properties, but it would be nice to have a framework that offers native support for this use case.
- **Android/Kotlin port.** The Core Library (Concise) should be pretty portable to Kotlin.
