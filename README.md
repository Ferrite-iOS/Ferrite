# Ferrite

A media search engine for iOS with a plugin API to extend its functionality.

## Disclaimer

This project is developed with a hobbyist/educational purpose and I am not responsible for what happens when you install Ferrite.

Ferrite does not and will never host any content. It is a search engine and will be nothing more.

## Why did I make this?

Finding shows and movies is usually pretty easy because there are many websites out there with the ability to search for the files you want.

However, the main problem is that these websites tend to suck in terms of UI or finding media to watch. Ferrite aims to provide a better UI to search and find the media you want.

I also wanted to support the use of RealDebrid since there aren't any (free) options on iOS that have support for this service.

## What iOS versions are supported?

iOS 14 and up. I was able to successfully backport the app!

## Planned features

- Website API support in sources: This allows for website APIs to be used in Ferrite sources which is quicker than scraping or RSS parsing

## Downloads

Ferrite will only exist as an ipa. There are and will never be any plans to release on TestFlight or the App Store. Ipa builds are automatically built and are provided in Github actions artifacts.

## Building from source

Xcode 14 must be used since Ferrite requires some iOS 16 APIs that are not present in Xcode 13. Please make sure you have the right Xcode or download the beta xip from Apple's developer website.

There is currently one branch in the repository:

- default: The current working branch. This will change in the future once a stable version is released.
- next: The development branch. Nightlies are automatically built here.

## Nightly builds

Nightlies are builds automatically compiled by GitHub actions. These are development builds which may or may not be stable!

It is required to log into GitHub or ask for a [nightly link](https://nightly.link/) to grab a build.

To install a nightly build:

1. Download the artifact from GitHub actions

2. Unzip the file containing the ipa

3. Install the ipa on your device

## Contribution

If you have issues with the app:

- Describe the issue in detail
- If you have a feature request, please indicate it as so. Planned features are in a different section of the README, so be sure to read those before submitting.
- Please join [the discord](https://discord.gg/sYQxnuD7Fj) for more info

## Developers and Permissions

I try to make comments/commits as detailed as possible, but if you don't understand something, please contact me via Discord.

Creator/Developer: kingbri

Developer Website: [kingbri.dev](https://kingbri.dev)

Developer Discord: kingbri#6666

Join the support discord here: [Ferrite Discord](https://discord.gg/sYQxnuD7Fj)
