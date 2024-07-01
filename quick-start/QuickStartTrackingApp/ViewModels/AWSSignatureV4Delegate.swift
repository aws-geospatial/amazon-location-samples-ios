import MapLibre
import AmazonLocationiOSAuthSDK
 
class AWSSignatureV4Delegate : NSObject, MLNOfflineStorageDelegate {
    private let awsSigner: AWSSignerV4
  
    init(amazonStaticCredentials: AmazonStaticCredentials, region: String) {
        self.awsSigner = AWSSignerV4(credentials: amazonStaticCredentials, serviceName: "geo", region: region)
        super.init()
    }
 
    func offlineStorage(_ storage: MLNOfflineStorage, urlForResourceOf kind: MLNResourceKind, with url: URL) -> URL {
        if url.host?.contains("amazonaws.com") != true {
            return url
        }
        let signedURL = awsSigner.signURL(url: url, expires: .hours(1))
        return signedURL
    }
}
