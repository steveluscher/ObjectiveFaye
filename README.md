ObjectiveFaye
=============

There exist a number of Faye/CometD clients for Objective-C, such as Paul Crawford's [FayeObjC](https://github.com/pcrawfor/FayeObjC) and Dave Duncan's [DDComet](https://github.com/ddunkin/cometclient/tree/master/DDComet). ObjectiveFaye is different.

ObjectiveFaye aims to be a _direct_ port of the official Faye client, originally available in Javascript and Ruby versions.

Doing a faithful port of the official Faye client will help to ensure that ObjectiveFaye more closely tracks the feature set of the Javascript/Ruby versions, and will make it easier to correlate updates made to the offical version to updates needed in ObjectiveFaye.

Help bring it to life
---------------------

If you are interested in helping to make ObjectiveFaye the best Faye client on iOS and OS X, check out the `devel` branch now and get to work! Find the commented-out Javascript in the source, and set to work translating it.

Requirements
------------

* The Cocoapods dependency manager (http://cocoapods.org)
* Xcode 4.6
* iOS 6.1 SDK

Development
-----------

1. Check out the `devel` branch
2. Run `pod install` to install ObjectiveFaye's dependencies
3. Compare [faye-browser.js](https://gist.github.com/steveluscher/4969398) to missing parts in ObjectiveFaye, and code until the thing works!