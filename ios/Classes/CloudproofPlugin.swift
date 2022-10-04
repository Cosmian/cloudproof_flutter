class CloudproofPlugin {
    public func dummyMethodToEnforceBundling() {
        // This will never be executed :PreventTreeShaking
        h_get_encrypted_header_size(nil, 0);
    }
}