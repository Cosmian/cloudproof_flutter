#import <Flutter/Flutter.h>

@interface CloudproofPlugin : NSObject<FlutterPlugin>
@end

#define MAX_CLEAR_TEXT_SIZE (1 << 30)

#define MAX_CLEAR_TEXT_SIZE (1 << 30)

#define MAX_CLEAR_TEXT_SIZE (1 << 30)

/**
 * Externally set the last error recorded on the Rust side
 *
 * # Safety
 * This function is meant to be called from the Foreign Function
 * Interface
 */
int32_t set_error(const char *error_message_ptr);

/**
 * Get the most recent error as utf-8 bytes, clearing it in the process.
 * # Safety
 * - `error_msg`: must be pre-allocated with a sufficient size
 */
int get_last_error(char *error_msg_ptr, int *error_len);

/**
 * Generate the master authority keys for supplied Policy
 *
 *  - `master_keys_ptr`    : Output buffer containing both master keys
 *  - `master_keys_len`    : Size of the output buffer
 *  - `policy_ptr`         : Policy to use to generate the keys
 * # Safety
 */
int h_generate_master_keys(char *master_keys_ptr, int *master_keys_len, const char *policy_ptr);

/**
 * Generate the user private key matching the given access policy
 *
 * - `user_private_key_ptr`: Output buffer containing user private key
 * - `user_private_key_len`: Size of the output buffer
 * - `master_private_key_ptr`: Master private key (required for this
 *   generation)
 * - `master_private_key_len`: Master private key length
 * - `access_policy_ptr`: Access policy of the user private key (JSON)
 * - `policy_ptr`: Policy to use to generate the keys (JSON)
 * # Safety
 */
int h_generate_user_private_key(char *user_private_key_ptr,
                                int *user_private_key_len,
                                const char *master_private_key_ptr,
                                int master_private_key_len,
                                const char *access_policy_ptr,
                                const char *policy_ptr);

/**
 * Rotate the attributes of the given policy
 *
 * - `updated_policy_ptr`: Output buffer containing new policy
 * - `updated_policy_len`: Size of the output buffer
 * - `attributes_ptr`: Attributes to rotate (JSON)
 * - `policy_ptr`: Policy to use to generate the keys (JSON)
 * # Safety
 */
int h_rotate_attributes(char *updated_policy_ptr,
                        int *updated_policy_len,
                        const char *attributes_ptr,
                        const char *policy_ptr);

/**
 * Update the master keys according to this new policy.
 *
 * When a partition exists in the new policy but not in the master keys,
 * a new keypair is added to the master keys for that partition.
 * When a partition exists on the master keys, but not in the new policy,
 * it is removed from the master keys.
 *
 * - `updated_master_private_key_ptr`: Output buffer containing the updated master private key
 * - `updated_master_private_key_len`: Size of the updated master private key output buffer
 * - `updated_master_public_key_ptr`: Output buffer containing the updated master public key
 * - `updated_master_public_key_len`: Size of the updated master public key output buffer
 * - `current_master_private_key_ptr`: current master private key
 * - `current_master_private_key_len`: current master private key length
 * - `current_master_public_key_ptr`: current master public key
 * - `current_master_public_key_len`: current master public key length
 * - `policy_ptr`: Policy to use to update the master keys (JSON)
 * # Safety
 */
int h_update_master_keys(char *updated_master_private_key_ptr,
                         int *updated_master_private_key_len,
                         char *updated_master_public_key_ptr,
                         int *updated_master_public_key_len,
                         const char *current_master_private_key_ptr,
                         int current_master_private_key_len,
                         const char *current_master_public_key_ptr,
                         int current_master_public_key_len,
                         const char *policy_ptr);

/**
 * Refresh the user key according to the given master key and access policy.
 *
 * The user key will be granted access to the current partitions, as determined by its access policy.
 * If preserve_old_partitions is set, the user access to rotated partitions will be preserved
 *
 * - `updated_user_private_key_ptr`: Output buffer containing the updated user private key
 * - `updated_user_private_key_len`: Size of the updated user private key output buffer
 * - `master_private_key_ptr`: master private key
 * - `master_private_key_len`: master private key length
 * - `current_user_private_key_ptr`: current user private key
 * - `current_user_private_key_len`: current user private key length
 * - `access_policy_ptr`: Access policy of the user private key (JSON)
 * - `policy_ptr`: Policy to use to update the master keys (JSON)
 * - `preserve_old_partitions_access`: set to 1 to preserve the user access to the rotated partitions
 * # Safety
 */
int h_refresh_user_private_key(char *updated_user_private_key_ptr,
                               int *updated_user_private_key_len,
                               const char *master_private_key_ptr,
                               int master_private_key_len,
                               const char *current_user_private_key_ptr,
                               int current_user_private_key_len,
                               const char *access_policy_ptr,
                               const char *policy_ptr,
                               int preserve_old_partitions_access);

/**
 * Create a cache of the Public Key and Policy which can be re-used
 * when encrypting multiple messages. This avoids having to re-instantiate
 * the public key on the Rust side on every encryption which is costly.
 *
 * This method is to be used in conjunction with
 *     h_aes_encrypt_header_using_cache
 *
 * WARN: h_aes_destroy_encrypt_cache() should be called
 * to reclaim the memory of the cache when done
 * # Safety
 */
int32_t h_aes_create_encryption_cache(int *cache_handle,
                                      const char *policy_ptr,
                                      const char *public_key_ptr,
                                      int public_key_len);

/**
 * The function should be called to reclaim memory
 * of the cache created using h_aes_create_encrypt_cache()
 * # Safety
 */
int h_aes_destroy_encryption_cache(int cache_handle);

/**
 * Encrypt a header using an encryption cache
 * The symmetric key and header bytes are returned in the first OUT parameters
 * # Safety
 */
int h_aes_encrypt_header_using_cache(char *symmetric_key_ptr,
                                     int *symmetric_key_len,
                                     char *header_bytes_ptr,
                                     int *header_bytes_len,
                                     int cache_handle,
                                     const char *attributes_ptr,
                                     const char *uid_ptr,
                                     int uid_len,
                                     const char *additional_data_ptr,
                                     int additional_data_len);

/**
 * Encrypt a header without using an encryption cache.
 * It is slower but does not require destroying any cache when done.
 *
 * The symmetric key and header bytes are returned in the first OUT parameters
 * # Safety
 */
int h_aes_encrypt_header(char *symmetric_key_ptr,
                         int *symmetric_key_len,
                         char *header_bytes_ptr,
                         int *header_bytes_len,
                         const char *policy_ptr,
                         const char *public_key_ptr,
                         int public_key_len,
                         const char *attributes_ptr,
                         const char *uid_ptr,
                         int uid_len,
                         const char *additional_data_ptr,
                         int additional_data_len);

/**
 * Create a cache of the User Decryption Key which can be re-used
 * when decrypting multiple messages. This avoids having to re-instantiate
 * the user key on the Rust side on every decryption which is costly.
 *
 * This method is to be used in conjunction with
 *     h_aes_decrypt_header_using_cache()
 *
 * WARN: h_aes_destroy_decryption_cache() should be called
 * to reclaim the memory of the cache when done
 * # Safety
 */
int32_t h_aes_create_decryption_cache(int *cache_handle,
                                      const char *user_decryption_key_ptr,
                                      int user_decryption_key_len);

/**
 * The function should be called to reclaim memory
 * of the cache created using h_aes_create_decryption_cache()
 * # Safety
 */
int h_aes_destroy_decryption_cache(int cache_handle);

/**
 * Decrypt an encrypted header using a cache.
 * Returns the symmetric key,
 * the uid and additional data if available.
 *
 * No additional data will be returned if the `additional_data_ptr` is NULL.
 *
 * # Safety
 */
int h_aes_decrypt_header_using_cache(char *symmetric_key_ptr,
                                     int *symmetric_key_len,
                                     char *uid_ptr,
                                     int *uid_len,
                                     char *additional_data_ptr,
                                     int *additional_data_len,
                                     const char *encrypted_header_ptr,
                                     int encrypted_header_len,
                                     int cache_handle);

/**
 * # Safety
 */
int h_get_encrypted_header_size(const char *encrypted_ptr, int encrypted_len);

/**
 * Decrypt an encrypted header returning the symmetric key,
 * the uid and additional data if available.
 *
 * Slower tha using a cache but avoids handling the cache creation and
 * destruction.
 *
 * No additional data will be returned if the `additional_data_ptr` is NULL.
 *
 * # Safety
 */
int h_aes_decrypt_header(char *symmetric_key_ptr,
                         int *symmetric_key_len,
                         char *uid_ptr,
                         int *uid_len,
                         char *additional_data_ptr,
                         int *additional_data_len,
                         const char *encrypted_header_ptr,
                         int encrypted_header_len,
                         const char *user_decryption_key_ptr,
                         int user_decryption_key_len);

/**
 *
 * # Safety
 */
int h_aes_symmetric_encryption_overhead(void);

/**
 *
 * # Safety
 */
int h_aes_encrypt_block(char *encrypted_ptr,
                        int *encrypted_len,
                        const char *symmetric_key_ptr,
                        int symmetric_key_len,
                        const char *uid_ptr,
                        int uid_len,
                        int block_number,
                        const char *data_ptr,
                        int data_len);

/**
 *
 * # Safety
 */
int h_aes_decrypt_block(char *clear_text_ptr,
                        int *clear_text_len,
                        const char *symmetric_key_ptr,
                        int symmetric_key_len,
                        const char *uid_ptr,
                        int uid_len,
                        int block_number,
                        const char *encrypted_bytes_ptr,
                        int encrypted_bytes_len);


//
// FINDEX HERE
//
/**
 * Constant ENTRY_TABLE_UID_SIZE refers to the size of:
 * ```iet_uid = ℋ(𝐾uid, 𝑤𝑖, T)```
 */
#define ENTRY_TABLE_UID_SIZE 32

/**
 * The constant ENTRY_TABLE_VALUE_SIZE is determined by:
 *
 * `iet_value = EncSym(𝐾value, (ict_uid𝑥𝑤𝑖, 𝐾𝑤𝑖 , 𝑤𝑖))`
 *
 * where 𝑤𝑖 can be of almost any size (since this is a word).
 */
#define ENTRY_TABLE_VALUE_SIZE (92 + WORD_MAXIMUM_SIZE)

/**
 * CHAIN_TABLE_VALUE_SIZE constant refers to Findex.pdf paragraph 3.2: Index
 * Chain Table `ict_value = EncSym(𝐾𝑤𝑖 , 𝐿𝑤𝑖,2)`
 */
#define CHAIN_TABLE_VALUE_SIZE 60

typedef int (*FetchEntryTableCallback)(char *entries_ptr, unsigned int *entries_len, const unsigned char *uids_ptr, unsigned int uids_len);

typedef void (*UpdateEntryTableCallback)(const unsigned char *entries_ptr, unsigned int entries_len);

typedef void (*UpdateChainTableCallback)(const unsigned char *chain_ptr, unsigned int chain_len);

typedef bool (*ProgressCallback)(const unsigned char *intermediate_results_ptr, unsigned int intermediate_results_len);

typedef int (*FetchChainTableCallback)(char *chain_ptr, unsigned int *chain_len, const unsigned char *uids_ptr, unsigned int uids_len);

/**
 *
 * # Return
 *
 * - 0: all done
 * - 1: ask again for more entries
 * - _: error
 */
typedef int (*FetchAllEntryTableCallback)(char *entries_ptr, unsigned int *entries_len, unsigned int number_of_entries);

typedef int (*UpdateLinesCallback)(const unsigned char *removed_chain_table_ids_ptr, unsigned int removed_chain_table_ids_len, const unsigned char *new_encrypted_entry_table_items_ptr, unsigned int new_encrypted_entry_table_items_len, const unsigned char *new_encrypted_chain_table_items_ptr, unsigned int new_encrypted_chain_table_items_len);

typedef int (*ListRemovedLocationsCallback)(char *removed_locations_ptr, unsigned int *removed_locations_len, const unsigned char *locations_ptr, unsigned int locations_len);

/**
 * # Safety
 * cannot be safe since using FFI
 */
int h_upsert(const char *master_keys_ptr,
             const uint8_t *label_ptr,
             int label_len,
             const char *indexed_values_and_words_ptr,
             FetchEntryTableCallback fetch_entry,
             UpdateEntryTableCallback upsert_entry,
             UpdateChainTableCallback upsert_chain);

/**
 * Works the same as `h_upsert()` but upserts the graph of all words used in
 * `indexed_values_and_words` too.
 *
 * # Safety
 * cannot be safe since using FFI
 */
int h_graph_upsert(const char *master_keys_ptr,
                   const uint8_t *label_ptr,
                   int label_len,
                   const char *indexed_values_and_words_ptr,
                   FetchEntryTableCallback fetch_entry,
                   UpdateEntryTableCallback upsert_entry,
                   UpdateChainTableCallback upsert_chain);

/**
 * # Safety
 * cannot be safe since using FFI
 */
int h_search(char *indexed_values_ptr,
             int *indexed_values_len,
             const char *key_k_ptr,
             int key_k_len,
             const uint8_t *label_ptr,
             int label_len,
             const char *words_ptr,
             int loop_iteration_limit,
             int max_depth,
             ProgressCallback progress_callback,
             FetchEntryTableCallback fetch_entry,
             FetchChainTableCallback fetch_chain);

/**
 * # Safety
 * cannot be safe since using FFI
 */
int h_compact(int number_of_reindexing_phases_before_full_set,
              const char *master_keys_ptr,
              const uint8_t *label_ptr,
              int label_len,
              FetchEntryTableCallback fetch_entry,
              FetchChainTableCallback fetch_chain,
              FetchAllEntryTableCallback fetch_all_entry,
              UpdateLinesCallback update_lines,
              ListRemovedLocationsCallback list_removed_locations);

// #if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
// /**
//  * Get the most recent error as utf-8 bytes, clearing it in the process.
//  * # Safety
//  * - `error_msg`: must be pre-allocated with a sufficient size
//  */
// int get_last_error(char *error_msg_ptr, int *error_len);
// #endif
