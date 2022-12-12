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
 * Slower than using a cache but avoids handling the cache creation and
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
// NOTE: Autogenerated file

/**
 * Number of bytes used to hash keywords.
 */
#define KeyWord_HASH_LENGTH 32

/**
 * Use a 256-bit `K`
 */
#define MASTER_KEY_LENGTH 32

/**
 * Use a 128-bit `K_wi`
 */
#define KWI_LENGTH 16

/**
 * Use a 128-bit `K_uid`
 * TODO TBZ: use 256 bits ?
 */
#define KMAC_KEY_LENGTH 16

/**
 * Callback to fetch the lines with the given UIDs from the Entry Table.
 * The values returned are encrypted since they are stored that way. The
 * decryption is performed by Findex.
 *
 * # Serialization
 *
 * The input is serialized as follows:
 *
 * `LEB128(uids.len()) || uid_1 || ...`
 *
 * The output should be serialized as follows:
 *
 * `LEB128(entries.len()) || LEB128(entry_1.len()) || entry_1 || ...`
 *
 * # Parameters
 *
 * - `entries` : (output) Entry Table items
 * - `uids`    : Entry Table UIDs of the lines to fetch
 */
typedef int (*FetchEntryTableCallback)(char *entries_ptr, unsigned int *entries_len, const unsigned char *uids_ptr, unsigned int uids_len);

/**
 * Upserts lines in the Entry Table. The input data should map each Entry
 * Table UID to upsert to the last value known by the client and the value
 * to upsert:
 *
 * `UID <-> (OLD_VALUE, NEW_VALUE)`
 *
 * To allow concurrent upsert operations, this callback should:
 *
 * 1 - for each UID given, perform an *atomic* conditional upsert: if the
 * current value stored in the DB is equal to `OLD_VALUE`, then `NEW_VALUE`
 * should be upserted;
 *
 * 2 - get the current values stored in the DB for all failed upserts from
 * step 1 and send them back to the client.
 *
 * # Serialization
 *
 * The input is serialized as follows:
 *
 * ` LEB128(entries.len()) || LEB128(old_value_1.len()) || old_value_1 ||
 * LEB128(new_value_1.len()) || new_value_1 || ...`
 *
 * The output should be serialized as follows:
 *
 * `LEB128(outputs.len()) || LEB128(output_1.len()) || output_1 || ...`
 *
 * # Parameters
 *
 * - `entries` : entries to be upserted
 * - `outputs` : (output) current value of the lines that failed to be upserted
 */
typedef void (*UpsertEntryTableCallback)(const unsigned char *entries_ptr, unsigned int entries_len, unsigned char *outputs_ptr, unsigned int *outputs_len);

/**
 * Inserts the given lines into the Chain Table. This should return an
 * error if a line with the same UID as one of the lines given already
 * exists.
 *
 * # Serialization
 *
 * The input is serialized as follows:
 *
 * `LEB128(chains.len()) || LEB128(chain_1.len() || chain_1 || ...`
 *
 * # Parameters
 *
 * - `chains`   : Chain Table items to insert
 */
typedef void (*InsertChainTableCallback)(const unsigned char *chains_ptr, unsigned int chains_len);

/**
 * Callback to return progress (partial results) during a search procedure.
 * Stops the search if the returned value is `false`. This can be useful to
 * stop prematurely the search when an intermediate result returned answers
 * the search.
 *
 * # Serialization
 *
 * The serialization of the intermediate results should follow:
 *
 * `LEB128(results.len()) || serialized_result_1 || ...`
 *
 * With the serialization of a result being:
 *
 * `prefix || byte_vector`
 *
 * where `prefix` is `l` (only `Location`s are returned) and the `byte_vector`
 * is the byte representation of the location.
 *
 * # Parameters
 *
 * - `intermediate_results` : search results (graph leaves are ignored)
 */
typedef bool (*ProgressCallback)(const unsigned char *intermediate_results_ptr, unsigned int intermediate_results_len);

/**
 * Callback to fetch the lines with the given UIDs from the Chain Table.
 * The values returned are encrypted since they are stored that way. The
 * decryption is performed by Findex.
 *
 * # Serialization
 *
 * The input is serialized as follows:
 *
 * `LEB128(uids.len()) || uid_1 || ...`
 *
 * The output should be serialized as follows:
 *
 * `LEB128(chains.len()) || LEB128(chain_1.len()) || chain_1 || ...`
 *
 * # Parameters
 *
 * - `chains`   : (output) Chain Table items
 * - `uids`    : Entry Table UIDs of the lines to fetch
 */
typedef int (*FetchChainTableCallback)(char *chains_ptr, unsigned int *chains_len, const unsigned char *uids_ptr, unsigned int uids_len);

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
 * Index the given values for the given keywords. After upserting, any
 * search for such a keyword will result in finding (at least) the
 * corresponding value.
 *
 * # Safety
 *
 * Cannot be safe since using FFI.
 */
int h_upsert(const uint8_t *master_key_ptr,
             int master_key_len,
             const uint8_t *label_ptr,
             int label_len,
             const char *indexed_values_and_keywords_ptr,
             FetchEntryTableCallback fetch_entry,
             UpsertEntryTableCallback upsert_entry,
             InsertChainTableCallback upsert_chain);

/**
 * Recursively searches Findex graphs for values indexed by the given keywords.
 *
 * # Safety
 *
 * Cannot be safe since using FFI.
 */
int h_search(char *indexed_values_ptr,
             int *indexed_values_len,
             const char *key_k_ptr,
             int key_k_len,
             const uint8_t *label_ptr,
             int label_len,
             const char *keywords_ptr,
             int loop_iteration_limit,
             int max_depth,
             ProgressCallback progress_callback,
             FetchEntryTableCallback fetch_entry,
             FetchChainTableCallback fetch_chain);

/**
 * Replaces all the Index Entry Table UIDs and values. New UIDs are derived
 * using the given label and the KMAC key derived from the new master key. The
 * values are dectypted using the DEM key derived from the master key and
 * re-encrypted using the DEM key derived from the new master key.
 *
 * Randomly selects index entries and recompact their associated chains. Chains
 * indexing no existing location are removed. Others are recomputed from a new
 * keying material. This removes unneeded paddings. New UIDs are derived for
 * the chain and values are re-encrypted using a DEM key derived from the new
 * keying material.
 *
 * # Safety
 *
 * Cannot be safe since using FFI.
 */
int h_compact(int num_reindexing_before_full_set,
              const uint8_t *master_key_ptr,
              int master_key_len,
              const uint8_t *new_master_key_ptr,
              int new_master_key_len,
              const uint8_t *label_ptr,
              int label_len,
              FetchEntryTableCallback fetch_entry,
              FetchChainTableCallback fetch_chain,
              FetchAllEntryTableCallback fetch_all_entry,
              UpdateLinesCallback update_lines,
              ListRemovedLocationsCallback list_removed_locations);

/**
 * Get the most recent error as utf-8 bytes, clearing it in the process.
 * # Safety
 * - `error_msg`: must be pre-allocated with a sufficient size
 */
int get_last_error(char *error_msg_ptr, int *error_len);
