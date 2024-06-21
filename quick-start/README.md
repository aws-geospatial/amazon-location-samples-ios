# Quick Start App: Amazon Location Service Integration

This quick start app demonstrates how to integrate Amazon Location Service with an iOS application using Amazon Cognito for authentication and tracking location updates in real-time. It showcases the usage of Amazon Location Service's Tracking and Auth SDKs to authenticate users and track their location on a map.

- **Tracking SDK**: [Amazon Location Service Tracking SDK](https://github.com/aws-geospatial/amazon-location-mobile-tracking-sdk-ios)
- **Auth SDK**: [Amazon Location Service Auth SDK](https://github.com/aws-geospatial/amazon-location-mobile-auth-sdk-ios)

## Installation

1. Clone this repository to your local machine.
2. Open `QuickStartTrackingApp.xcodeproj` project in Xcode.
3. Build and run the app on your iOS device or simulator.
4. Open `ConfigTemplate.xcconfig` file
5. Copy contents to a new file named `Config.xcconfig`
6. Fill in the required values in the `Config.xcconfig` file to configure the AWS credentials. (Refer to the [Configuration](#configuration) section for details)


## Configuration

A configuration file named `Config.xcconfig` is included in the root of the project. To use it:

Fill in the following values in `Config.xcconfig`:
```
REGION = [Your Region] 
INDEX_NAME = [Your Search Index] 
MAP_NAME = [Your Map Resource Name] 
IDENTITY_POOL_ID = [Your Cognito Identity Pool ID] 
TRACKER_NAME = [Your Tracker Name] 
```

IDENTITY_POOL_ID: Your AWS Cognito Identity Pool ID used for authenticating users.
REGION: Your AWS region.
TRACKER_NAME: The name of the tracker resource in Amazon Location Service used for tracking location updates.
PLACE_INDEX: The Amazon Resource Name of your place index in Amazon Location Service.
MAP_NAME: The name of the map resource in the Amazon Location Service you want to use to display the map.

These values are used to configure the app's connection to AWS services. If not provided in the `Config.xcconfig` file, they can be filled out manually in the app's Config tab.

## UI Automated Tests
In order to run the UI tests, you need to provide the AWS credentials in the `TestConfig.xcconfig` file.

Fill in the following values in `TestConfig.xcconfig`:

```
TEST_REGION = [Your Region] 
TEST_INDEX_NAME = [Your Search Index] 
TEST_MAP_NAME = [Your Map Resource Name] 
TEST_IDENTITY_POOL_ID = [Your Cognito Identity Pool ID] 
TEST_TRACKER_NAME = [Your Tracker Name] 
```
1. Run the UI tests by selecting the `QuickStartTrackingAppUITests` target and selecting Product -> Test from the Xcode menu.