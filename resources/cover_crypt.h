// NOTE: Autogenerated file

#define MAX_CLEAR_TEXT_SIZE (1 << 30)

/**
 * # Safety
 */
int h_policy(char *policy_ptr, int *policy_len, int max_attribute_creations);

/**
 * # Safety
 */
int h_add_policy_axis(char *updated_policy_ptr,
                      int *updated_policy_len,
                      const char *current_policy_ptr,
                      int current_policy_len,
                      const char *axis_ptr);

/**
 * # Safety
 */
int h_rotate_attribute(char *updated_policy_ptr,
                       int *updated_policy_len,
                       const char *current_policy_ptr,
                       int current_policy_len,
                       const char *attribute);

/**
 * # Safety
 */
int h_validate_boolean_expression(const char *boolean_expression_ptr);

/**
 * # Safety
 */
int h_validate_attribute(const char *attribute_ptr);

/**
 * Generates the master authority keys for supplied Policy.
 *
 *  - `msk_ptr`    : Output buffer containing the master secret key
 *  - `msk_len`    : Size of the master secret key output buffer
 *  - `mpk_ptr`    : Output buffer containing the master public key
 *  - `mpk_len`    : Size of the master public key output buffer
 *  - `policy_ptr` : Policy to use to generate the keys
 *  - `policy_len` : Size of the `Policy` to use to generate the keys
 *
 * # Safety
 */
int h_generate_master_keys(char *msk_ptr,
                           int *msk_len,
                           char *mpk_ptr,
                           int *mpk_len,
                           const char *policy_ptr,
                           int policy_len);

/**
 * Generates a user secret key for the given access policy
 *
 * - `usk_ptr`             : Output buffer containing user secret key
 * - `usk_len`             : Size of the output buffer
 * - `msk_ptr`             : Master secret key (required for this generation)
 * - `msk_len`             : Master secret key length
 * - `user_policy_ptr`   : null terminated access policy string
 * - `policy_ptr`          : bytes of the policyused to generate the keys
 * - `policy_len`          : length of the policy (in bytes)
 * # Safety
 */
int h_generate_user_secret_key(char *usk_ptr,
                               int *usk_len,
                               const char *msk_ptr,
                               int msk_len,
                               const char *user_policy_ptr,
                               const char *policy_ptr,
                               int policy_len);

/**
 * Updates the master keys according to the given policy.
 *
 * Cf (`CoverCrypt::update_master_keys`)[`CoverCrypt::update_master_keys`].
 *
 * - `updated_msk_ptr` : Output buffer containing the updated master secret key
 * - `updated_msk_len` : Size of the updated master secret key output buffer
 * - `updated_mpk_ptr` : Output buffer containing the updated master public key
 * - `updated_mpk_len` : Size of the updated master public key output buffer
 * - `current_msk_ptr` : current master secret key
 * - `current_msk_len` : current master secret key length
 * - `current_mpk_ptr` : current master public key
 * - `current_mpk_len` : current master public key length
 * - `policy_ptr`      : Policy to use to update the master keys (JSON)
 * # Safety
 */
int h_update_master_keys(char *updated_msk_ptr,
                         int *updated_msk_len,
                         char *updated_mpk_ptr,
                         int *updated_mpk_len,
                         const char *current_msk_ptr,
                         int current_msk_len,
                         const char *current_mpk_ptr,
                         int current_mpk_len,
                         const char *policy_ptr,
                         int policy_len);

/**
 * Refreshes the user secret key according to the given master key and access
 * policy.
 *
 * Cf [`CoverCrypt::refresh_user_secret_key()`](CoverCrypt::refresh_user_secret_key).
 *
 * - `updated_usk_ptr`                 : Output buffer containing the updated
 *   user secret key
 * - `updated_usk_len`                 : Size of the updated user secret key
 *   output buffer
 * - `msk_ptr`                         : master secret key
 * - `msk_len`                         : master secret key length
 * - `current_usk_ptr`                 : current user secret key
 * - `current_usk_len`                 : current user secret key length
 * - `access_policy_ptr`               : Access policy of the user secret key
 *   (JSON)
 * - `policy_ptr`                      : Policy to use to update the master
 *   keys (JSON)
 * - `preserve_old_partitions_access`  : set to 1 to preserve the user access
 *   to the rotated partitions
 * # Safety
 */
int h_refresh_user_secret_key(char *updated_usk_ptr,
                              int *updated_usk_len,
                              const char *msk_ptr,
                              int msk_len,
                              const char *current_usk_ptr,
                              int current_usk_len,
                              const char *user_policy_ptr,
                              const char *policy_ptr,
                              int policy_len,
                              int preserve_old_partitions_access);

/**
 * Creates a cache containing the Public Key and Policy. This cache can be
 * reused when encrypting messages which avoids passing these objects to Rust
 * in each call.
 *
 * WARNING: [`h_destroy_encrypt_cache()`](h_destroy_encryption_cache)
 * should be called to reclaim the cache memory.
 *
 * # Safety
 */
int32_t h_create_encryption_cache(int *cache_handle,
                                  const char *policy_ptr,
                                  int policy_len,
                                  const char *mpk_ptr,
                                  int mpk_len);

/**
 * Reclaims the memory of the cache.
 *
 * Cf [`h_create_encrypt_cache()`](h_create_encryption_cache).
 *
 * # Safety
 */
int h_destroy_encryption_cache(int cache_handle);

/**
 * Encrypts a header using an encryption cache.
 *
 * # Safety
 */
int h_encrypt_header_using_cache(char *symmetric_key_ptr,
                                 int *symmetric_key_len,
                                 char *header_bytes_ptr,
                                 int *header_bytes_len,
                                 int cache_handle,
                                 const char *encryption_policy_ptr,
                                 const char *header_metadata_ptr,
                                 int header_metadata_len,
                                 const char *authentication_data_ptr,
                                 int authentication_data_len);

/**
 * Encrypts a header without using an encryption cache.
 * It is slower but does not require destroying any cache when done.
 *
 * The symmetric key and header bytes are returned in the first OUT parameters
 * # Safety
 */
int h_encrypt_header(char *symmetric_key_ptr,
                     int *symmetric_key_len,
                     char *header_bytes_ptr,
                     int *header_bytes_len,
                     const char *policy_ptr,
                     int policy_len,
                     const char *mpk_ptr,
                     int mpk_len,
                     const char *encryption_policy_ptr,
                     const char *header_metadata_ptr,
                     int header_metadata_len,
                     const char *authentication_data_ptr,
                     int authentication_data_len);

/**
 * Creates a cache containing the user secret key. This cache can be reused
 * when decrypting messages which avoids passing this key to Rust in each call.
 *
 * Cf [`h_decrypt_header_using_cache()`](h_decrypt_header_using_cache).
 *
 * WARNING: [`h_destroy_decryption_cache()`](h_destroy_decryption_cache)
 * should be called to reclaim the cache memory.
 *
 * # Safety
 */
int32_t h_create_decryption_cache(int *cache_handle, const char *usk_ptr, int usk_len);

/**
 * Reclaims decryption cache memory.
 *
 * # Safety
 */
int h_destroy_decryption_cache(int cache_handle);

/**
 * Decrypts an encrypted header using a cache. Returns the symmetric key and
 * header metadata if any.
 *
 * No header metadata is returned if `header_metadata_ptr` is `NULL`.
 *
 * # Safety
 */
int h_decrypt_header_using_cache(char *symmetric_key_ptr,
                                 int *symmetric_key_len,
                                 char *header_metadata_ptr,
                                 int *header_metadata_len,
                                 const char *encrypted_header_ptr,
                                 int encrypted_header_len,
                                 const char *authentication_data_ptr,
                                 int authentication_data_len,
                                 int cache_handle);

/**
 * Decrypts an encrypted header, returning the symmetric key and header
 * metadata if any.
 *
 * No header metadata is returned if `header_metadata_ptr` is `NULL`.
 *
 * # Safety
 */
int h_decrypt_header(char *symmetric_key_ptr,
                     int *symmetric_key_len,
                     char *header_metadata_ptr,
                     int *header_metadata_len,
                     const char *encrypted_header_ptr,
                     int encrypted_header_len,
                     const char *authentication_data_ptr,
                     int authentication_data_len,
                     const char *usk_ptr,
                     int usk_len);

/**
 *
 * # Safety
 */
int h_symmetric_encryption_overhead(void);

/**
 *
 * # Safety
 */
int h_dem_encrypt(char *ciphertext_ptr,
                  int *ciphertext_len,
                  const char *symmetric_key_ptr,
                  int symmetric_key_len,
                  const char *authentication_data_ptr,
                  int authentication_data_len,
                  const char *plaintext_ptr,
                  int plaintext_len);

/**
 *
 * # Safety
 */
int h_dem_decrypt(char *plaintext_ptr,
                  int *plaintext_len,
                  const char *symmetric_key_ptr,
                  int symmetric_key_len,
                  const char *authentication_data_ptr,
                  int authentication_data_len,
                  const char *ciphertext_ptr,
                  int ciphertext_len);

/**
 * Hybrid encrypt some content
 *
 * # Safety
 */
int h_hybrid_encrypt(char *ciphertext_ptr,
                     int *ciphertext_len,
                     const char *policy_ptr,
                     int policy_len,
                     const char *mpk_ptr,
                     int mpk_len,
                     const char *encryption_policy_ptr,
                     const char *plaintext_ptr,
                     int plaintext_len,
                     const char *header_metadata_ptr,
                     int header_metadata_len,
                     const char *authentication_data_ptr,
                     int authentication_data_len);

/**
 * Hybrid decrypt some content.
 *
 * No header metadata is returned if `header_metadata_ptr` is `NULL`.
 *
 * # Safety
 */
int h_hybrid_decrypt(char *plaintext_ptr,
                     int *plaintext_len,
                     char *header_metadata_ptr,
                     int *header_metadata_len,
                     const char *ciphertext_ptr,
                     int ciphertext_len,
                     const char *authentication_data_ptr,
                     int authentication_data_len,
                     const char *usk_ptr,
                     int usk_len);

/**
 * Externally sets the last error recorded on the Rust side.
 *
 * # Safety
 *
 * The pointer must point to a null-terminated string.
 *
 * This function is meant to be called from the Foreign Function
 * Interface.
 *
 * # Parameters
 *
 * - `error_message_ptr`   : pointer to the error message to set
 */
int32_t h_set_error(const char *error_message_ptr);

/**
 * Externally gets the most recent error recorded on the Rust side, clearing
 * it in the process.
 *
 * # Safety
 *
 * The pointer `error_ptr` should point to a buffer which has been allocated
 * `error_len` bytes. If the allocated size is smaller than `error_len`, a
 * call to this function may result in a buffer overflow.
 *
 * # Parameters
 *
 * - `error_ptr`: pointer to the buffer to which to write the error
 * - `error_len`: size of the allocated memory
 */
int h_get_error(char *error_ptr, int *error_len);
