import Foundation
import AmazonLocationiOSAuthSDK
import AWSLocation

public extension AmazonLocationClient {
    func searchPosition(indexName: String, input: SearchPlaceIndexForPositionInput) async throws -> SearchPlaceIndexForPositionOutput? {
        do {
            if locationProvider.getCognitoProvider() != nil {
                if locationClient == nil {
                    try await initialiseLocationClient()
                }
                let response = try await locationClient!.searchPlaceIndexForPosition(input: input)
                return response
            }
        }
        catch {
            throw error
        }
        return nil
    }
}
