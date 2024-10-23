import SwiftUI
import AwsCommonRuntimeKit
import AwsCMqtt
import AmazonLocationiOSAuthSDK

struct Message: Identifiable {
    let id: Int
    let text: String
}

class MqttIoTContext: ObservableObject {
    @Published var messages: [Message] = [Message(id: 0, text: "")]

    public var contextName: String

    public var onPublishReceived: OnPublishReceived?
    public var onLifecycleEventStopped: OnLifecycleEventStopped?
    public var onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect?
    public var onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess?
    public var onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure?
    public var onLifecycleEventDisconnection: OnLifecycleEventDisconnection?
    public var onWebSocketHandshake: OnWebSocketHandshakeIntercept?

    public let semaphorePublishReceived: DispatchSemaphore
    public let semaphoreConnectionSuccess: DispatchSemaphore
    public let semaphoreConnectionFailure: DispatchSemaphore
    public let semaphoreDisconnection: DispatchSemaphore
    public let semaphoreStopped: DispatchSemaphore

    public var lifecycleConnectionFailureData: LifecycleConnectionFailureData?
    public var lifecycleDisconnectionData: LifecycleDisconnectData?
    public var publishCount = 0
    public var client: Mqtt5Client?
    /// Print the text and pending new message to message list
    func printView(_ txt: String) {
        print(txt)
    }

    init(contextName: String = "Client",
         onPublishReceived: OnPublishReceived? = nil,
         onLifecycleEventStopped: OnLifecycleEventStopped? = nil,
         onLifecycleEventAttemptingConnect: OnLifecycleEventAttemptingConnect? = nil,
         onLifecycleEventConnectionSuccess: OnLifecycleEventConnectionSuccess? = nil,
         onLifecycleEventConnectionFailure: OnLifecycleEventConnectionFailure? = nil,
         onLifecycleEventDisconnection: OnLifecycleEventDisconnection? = nil,
         onWebSocketHandshake: OnWebSocketHandshakeIntercept? = nil,
         topicName: String,
         cognitoCredentialsProvider: AmazonLocationCognitoCredentialsProvider, region: String) {
        
        self.contextName = contextName
        self.publishCount = 0

        self.semaphorePublishReceived = DispatchSemaphore(value: 0)
        self.semaphoreConnectionSuccess = DispatchSemaphore(value: 0)
        self.semaphoreConnectionFailure = DispatchSemaphore(value: 0)
        self.semaphoreDisconnection = DispatchSemaphore(value: 0)
        self.semaphoreStopped = DispatchSemaphore(value: 0)

        self.onPublishReceived = onPublishReceived
        self.onLifecycleEventStopped = onLifecycleEventStopped
        self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect
        self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess
        self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure
        self.onLifecycleEventDisconnection = onLifecycleEventDisconnection

        self.onPublishReceived = onPublishReceived ?? { publishData in
            var message = contextName + " Mqtt5ClientTests: onPublishReceived." +
            "Topic:\'\(publishData.publishPacket.topic)\' QoS:\(publishData.publishPacket.qos)"
            if let payloadString = publishData.publishPacket.payloadAsString() {
                message += "payload:\'\(payloadString)\'"
            }
            // Pending received publish to message list
            self.printView(message)
            self.semaphorePublishReceived.signal()
            self.publishCount += 1
        }

        self.onLifecycleEventStopped = onLifecycleEventStopped ?? { _ in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventStopped")
            self.semaphoreStopped.signal()
        }
        self.onLifecycleEventAttemptingConnect = onLifecycleEventAttemptingConnect ?? { _ in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventAttemptingConnect")
        }
        self.onLifecycleEventConnectionSuccess = onLifecycleEventConnectionSuccess ?? { _ in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventConnectionSuccess")
            // Subscribe to test/topic on connection success
            Task {
                async let _ = try await self.client!.subscribe(subscribePacket: SubscribePacket(
                    subscription: Subscription(topicFilter: topicName, qos: QoS.atLeastOnce)))
            }
            self.semaphoreConnectionSuccess.signal()
        }
        self.onLifecycleEventConnectionFailure = onLifecycleEventConnectionFailure ?? { failureData in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventConnectionFailure:w \(failureData.crtError)")
            self.lifecycleConnectionFailureData = failureData
            self.semaphoreConnectionFailure.signal()
        }
        self.onLifecycleEventDisconnection = onLifecycleEventDisconnection ?? { disconnectionData in
            self.printView(contextName + " Mqtt5ClientTests: onLifecycleEventDisconnection")
            self.lifecycleDisconnectionData = disconnectionData
            self.semaphoreDisconnection.signal()
        }
        self.onWebSocketHandshake = onWebSocketHandshake ?? { request, complete in
            do {
                self.printView(contextName + " Mqtt5ClientTests: onWebSocketHandshake")
                if let cognitoCredentials = cognitoCredentialsProvider.getCognitoCredentials() {
                    let credentialsProvider = try CredentialsProvider(source: .static(accessKey: cognitoCredentials.accessKeyId, secret: cognitoCredentials.secretKey, sessionToken: cognitoCredentials.sessionToken))
                    let signingConfig = SigningConfig(algorithm: SigningAlgorithmType.signingV4,
                                                      signatureType: SignatureType.requestQueryParams,
                                                      service: "iotdevicegateway",
                                                      region: region,
                                                      credentialsProvider: credentialsProvider,
                                                      omitSessionToken: true)
                    let returnedRequest = try await Signer.signRequest(request: request, config:signingConfig)
                    complete(returnedRequest, AWS_OP_SUCCESS)
                }
                else {
                    complete(request, AWS_OP_SUCCESS)
                }
            }
            catch
            {
                complete(request, Int32(AWS_ERROR_UNSUPPORTED_OPERATION.rawValue))
            }
        }
    }
}


