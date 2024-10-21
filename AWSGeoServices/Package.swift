// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AWSGeoServices",
    platforms: [
            .macOS(.v10_15),
            .iOS(.v13),
            .tvOS(.v13),
            .watchOS(.v6)
        ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AWSGeoPlaces",
            targets: ["AWSGeoPlaces"]),
        .library(
            name: "AWSGeoRoutes",
            targets: ["AWSGeoRoutes"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "1.0.17"),
        .package(url: "https://github.com/smithy-lang/smithy-swift", from: "0.78.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AWSGeoPlaces",
            dependencies: [
                .product(
                    name: "SmithyHTTPAuthAPI",
                    package: "smithy-swift"
                ),
                .product(
                    name: "Smithy",
                    package: "smithy-swift"
                ),
                .product(
                    name: "ClientRuntime",
                    package: "smithy-swift"
                ),
                .product(
                    name: "SmithyHTTPAPI",
                    package: "smithy-swift"
                ),
                .product(
                    name: "AWSClientRuntime",
                    package: "aws-sdk-swift"
                ),
                .product(
                    name: "SmithyIdentity",
                    package: "smithy-swift"
                ),
                .product(
                    name: "SmithyRetriesAPI",
                    package: "smithy-swift"
                ),
                .product(
                    name: "AWSSDKHTTPAuth",
                    package: "aws-sdk-swift"
                ),
                .product(
                    name: "SmithyJSON",
                    package: "smithy-swift"
                ),
                .product(
                    name: "SmithyReadWrite",
                    package: "smithy-swift"
                ),
                .product(
                    name: "SmithyRetries",
                    package: "smithy-swift"
                )
            ],
            path: "Sources/AWSGeoPlaces/Sources/AWSGeoPlaces"),
        .target(
            name: "AWSGeoRoutes",
            dependencies: [
                .product(
                    name: "SmithyHTTPAuthAPI",
                    package: "smithy-swift"
                ),
                .product(
                    name: "Smithy",
                    package: "smithy-swift"
                ),
                .product(
                    name: "ClientRuntime",
                    package: "smithy-swift"
                ),
                .product(
                    name: "SmithyHTTPAPI",
                    package: "smithy-swift"
                ),
                .product(
                    name: "AWSClientRuntime",
                    package: "aws-sdk-swift"
                ),
                .product(
                    name: "SmithyIdentity",
                    package: "smithy-swift"
                ),
                .product(
                    name: "SmithyRetriesAPI",
                    package: "smithy-swift"
                ),
                .product(
                    name: "AWSSDKHTTPAuth",
                    package: "aws-sdk-swift"
                ),
                .product(
                    name: "SmithyJSON",
                    package: "smithy-swift"
                ),
                .product(
                    name: "SmithyReadWrite",
                    package: "smithy-swift"
                ),
                .product(
                    name: "SmithyRetries",
                    package: "smithy-swift"
                )
            ],
            path: "Sources/AWSGeoRoutes/Sources/AWSGeoRoutes"),
    ]
)
