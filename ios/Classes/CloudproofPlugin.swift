class CloudproofPlugin {
    public func dummyMethodToEnforceBundling() {
        // This will never be executed
        h_get_encrypted_header_size(nil, nil);
    }
}