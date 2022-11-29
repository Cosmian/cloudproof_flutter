// ignore_for_file: constant_identifier_names, non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
import 'dart:ffi' as ffi;

/// Dart bindings to call CoverCrypt functions
class NativeLibrary {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  NativeLibrary(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NativeLibrary.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  /// Externally set the last error recorded on the Rust side
  ///
  /// # Safety
  /// This function is meant to be called from the Foreign Function
  /// Interface
  int set_error(
    ffi.Pointer<ffi.Char> error_message_ptr,
  ) {
    return _set_error(
      error_message_ptr,
    );
  }

  late final _set_errorPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<ffi.Char>)>>(
          'set_error');
  late final _set_error =
      _set_errorPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  /// Get the most recent error as utf-8 bytes, clearing it in the process.
  /// # Safety
  /// - `error_msg`: must be pre-allocated with a sufficient size
  int get_last_error(
    ffi.Pointer<ffi.Char> error_msg_ptr,
    ffi.Pointer<ffi.Int> error_len,
  ) {
    return _get_last_error(
      error_msg_ptr,
      error_len,
    );
  }

  late final _get_last_errorPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>)>>('get_last_error');
  late final _get_last_error = _get_last_errorPtr
      .asFunction<int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>)>();

  /// Generate the master authority keys for supplied Policy
  ///
  /// - `master_keys_ptr`    : Output buffer containing both master keys
  /// - `master_keys_len`    : Size of the output buffer
  /// - `policy_ptr`         : Policy to use to generate the keys
  /// # Safety
  int h_generate_master_keys(
    ffi.Pointer<ffi.Char> master_keys_ptr,
    ffi.Pointer<ffi.Int> master_keys_len,
    ffi.Pointer<ffi.Char> policy_ptr,
  ) {
    return _h_generate_master_keys(
      master_keys_ptr,
      master_keys_len,
      policy_ptr,
    );
  }

  late final _h_generate_master_keysPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>)>>('h_generate_master_keys');
  late final _h_generate_master_keys = _h_generate_master_keysPtr.asFunction<
      int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>)>();

  /// Generate the user secret key matching the given access policy
  ///
  /// - `usk_ptr`             : Output buffer containing user secret key
  /// - `usk_len`             : Size of the output buffer
  /// - `msk_ptr`             : Master secret key (required for this generation)
  /// - `msk_len`             : Master secret key length
  /// - `access_policy_ptr`   : Access policy of the user secret key (JSON)
  /// - `policy_ptr`          : Policy to use to generate the keys (JSON)
  /// # Safety
  int h_generate_user_secret_key(
    ffi.Pointer<ffi.Char> usk_ptr,
    ffi.Pointer<ffi.Int> usk_len,
    ffi.Pointer<ffi.Char> msk_ptr,
    int msk_len,
    ffi.Pointer<ffi.Char> access_policy_ptr,
    ffi.Pointer<ffi.Char> policy_ptr,
  ) {
    return _h_generate_user_secret_key(
      usk_ptr,
      usk_len,
      msk_ptr,
      msk_len,
      access_policy_ptr,
      policy_ptr,
    );
  }

  late final _h_generate_user_secret_keyPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>)>>('h_generate_user_secret_key');
  late final _h_generate_user_secret_key =
      _h_generate_user_secret_keyPtr.asFunction<
          int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              int,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>)>();

  /// Rotate the attributes of the given policy
  ///
  /// - `updated_policy_ptr`  : Output buffer containing new policy
  /// - `updated_policy_len`  : Size of the output buffer
  /// - `attributes_ptr`      : Attributes to rotate (JSON)
  /// - `policy_ptr`          : Policy to use to generate the keys (JSON)
  /// # Safety
  int h_rotate_attributes(
    ffi.Pointer<ffi.Char> updated_policy_ptr,
    ffi.Pointer<ffi.Int> updated_policy_len,
    ffi.Pointer<ffi.Char> attributes_ptr,
    ffi.Pointer<ffi.Char> policy_ptr,
  ) {
    return _h_rotate_attributes(
      updated_policy_ptr,
      updated_policy_len,
      attributes_ptr,
      policy_ptr,
    );
  }

  late final _h_rotate_attributesPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>)>>('h_rotate_attributes');
  late final _h_rotate_attributes = _h_rotate_attributesPtr.asFunction<
      int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>();

  /// Update the master keys according to this new policy.
  ///
  /// When a partition exists in the new policy but not in the master keys,
  /// a new key pair is added to the master keys for that partition.
  /// When a partition exists on the master keys, but not in the new policy,
  /// it is removed from the master keys.
  ///
  /// - `updated_msk_ptr` : Output buffer containing the updated master secret key
  /// - `updated_msk_len` : Size of the updated master secret key output buffer
  /// - `updated_mpk_ptr` : Output buffer containing the updated master public key
  /// - `updated_mpk_len` : Size of the updated master public key output buffer
  /// - `current_msk_ptr` : current master secret key
  /// - `current_msk_len` : current master secret key length
  /// - `current_mpk_ptr` : current master public key
  /// - `current_mpk_len` : current master public key length
  /// - `policy_ptr`      : Policy to use to update the master keys (JSON)
  /// # Safety
  int h_update_master_keys(
    ffi.Pointer<ffi.Char> updated_msk_ptr,
    ffi.Pointer<ffi.Int> updated_msk_len,
    ffi.Pointer<ffi.Char> updated_mpk_ptr,
    ffi.Pointer<ffi.Int> updated_mpk_len,
    ffi.Pointer<ffi.Char> current_msk_ptr,
    int current_msk_len,
    ffi.Pointer<ffi.Char> current_mpk_ptr,
    int current_mpk_len,
    ffi.Pointer<ffi.Char> policy_ptr,
  ) {
    return _h_update_master_keys(
      updated_msk_ptr,
      updated_msk_len,
      updated_mpk_ptr,
      updated_mpk_len,
      current_msk_ptr,
      current_msk_len,
      current_mpk_ptr,
      current_mpk_len,
      policy_ptr,
    );
  }

  late final _h_update_master_keysPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>)>>('h_update_master_keys');
  late final _h_update_master_keys = _h_update_master_keysPtr.asFunction<
      int Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>)>();

  /// Refresh the user key according to the given master key and access policy.
  ///
  /// The user key will be granted access to the current partitions, as determined by its access policy.
  /// If preserve_old_partitions is set, the user access to rotated partitions will be preserved
  ///
  /// - `updated_usk_ptr`                 : Output buffer containing the updated user secret key
  /// - `updated_usk_len`                 : Size of the updated user secret key output buffer
  /// - `msk_ptr`                         : master secret key
  /// - `msk_len`                         : master secret key length
  /// - `current_usk_ptr`                 : current user secret key
  /// - `current_usk_len`                 : current user secret key length
  /// - `access_policy_ptr`               : Access policy of the user secret key (JSON)
  /// - `policy_ptr`                      : Policy to use to update the master keys (JSON)
  /// - `preserve_old_partitions_access`  : set to 1 to preserve the user access to the rotated partitions
  /// # Safety
  int h_refresh_user_secret_key(
    ffi.Pointer<ffi.Char> updated_usk_ptr,
    ffi.Pointer<ffi.Int> updated_usk_len,
    ffi.Pointer<ffi.Char> msk_ptr,
    int msk_len,
    ffi.Pointer<ffi.Char> current_usk_ptr,
    int current_usk_len,
    ffi.Pointer<ffi.Char> access_policy_ptr,
    ffi.Pointer<ffi.Char> policy_ptr,
    int preserve_old_partitions_access,
  ) {
    return _h_refresh_user_secret_key(
      updated_usk_ptr,
      updated_usk_len,
      msk_ptr,
      msk_len,
      current_usk_ptr,
      current_usk_len,
      access_policy_ptr,
      policy_ptr,
      preserve_old_partitions_access,
    );
  }

  late final _h_refresh_user_secret_keyPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_refresh_user_secret_key');
  late final _h_refresh_user_secret_key =
      _h_refresh_user_secret_keyPtr.asFunction<
          int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              int,
              ffi.Pointer<ffi.Char>,
              int,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              int)>();

  /// Converts a boolean expression containing an access policy
  /// into a JSON access policy which can be used in Vendor Attributes
  ///
  /// Note: the return string is NULL terminated
  ///
  /// - `json_access_policy_ptr`: Output buffer containing a null terminated string with the JSON access policy
  /// - `json_access_policy_len`: Size of the output buffer
  /// - `boolean_access_policy_ptr`: boolean access policy string
  /// # Safety
  int h_parse_boolean_access_policy(
    ffi.Pointer<ffi.Char> json_access_policy_ptr,
    ffi.Pointer<ffi.Int> json_access_policy_len,
    ffi.Pointer<ffi.Char> boolean_access_policy_ptr,
  ) {
    return _h_parse_boolean_access_policy(
      json_access_policy_ptr,
      json_access_policy_len,
      boolean_access_policy_ptr,
    );
  }

  late final _h_parse_boolean_access_policyPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>)>>('h_parse_boolean_access_policy');
  late final _h_parse_boolean_access_policy =
      _h_parse_boolean_access_policyPtr.asFunction<
          int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>)>();

  /// Create a cache of the Public Key and Policy which can be re-used
  /// when encrypting multiple messages. This avoids having to re-instantiate
  /// the public key on the Rust side on every encryption which is costly.
  ///
  /// This method is to be used in conjunction with
  /// h_aes_encrypt_header_using_cache
  ///
  /// WARN: h_aes_destroy_encrypt_cache() should be called
  /// to reclaim the memory of the cache when done
  /// # Safety
  int h_aes_create_encryption_cache(
    ffi.Pointer<ffi.Int> cache_handle,
    ffi.Pointer<ffi.Char> policy_ptr,
    ffi.Pointer<ffi.Char> pk_ptr,
    int pk_len,
  ) {
    return _h_aes_create_encryption_cache(
      cache_handle,
      policy_ptr,
      pk_ptr,
      pk_len,
    );
  }

  late final _h_aes_create_encryption_cachePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_aes_create_encryption_cache');
  late final _h_aes_create_encryption_cache =
      _h_aes_create_encryption_cachePtr.asFunction<
          int Function(ffi.Pointer<ffi.Int>, ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>, int)>();

  /// The function should be called to reclaim memory
  /// of the cache created using h_aes_create_encrypt_cache()
  /// # Safety
  int h_aes_destroy_encryption_cache(
    int cache_handle,
  ) {
    return _h_aes_destroy_encryption_cache(
      cache_handle,
    );
  }

  late final _h_aes_destroy_encryption_cachePtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Int)>>(
          'h_aes_destroy_encryption_cache');
  late final _h_aes_destroy_encryption_cache =
      _h_aes_destroy_encryption_cachePtr.asFunction<int Function(int)>();

  /// Encrypt a header using an encryption cache
  /// The symmetric key and header bytes are returned in the first OUT parameters
  /// # Safety
  int h_aes_encrypt_header_using_cache(
    ffi.Pointer<ffi.Char> symmetric_key_ptr,
    ffi.Pointer<ffi.Int> symmetric_key_len,
    ffi.Pointer<ffi.Char> header_bytes_ptr,
    ffi.Pointer<ffi.Int> header_bytes_len,
    int cache_handle,
    ffi.Pointer<ffi.Char> encryption_policy_ptr,
    ffi.Pointer<ffi.Char> additional_data_ptr,
    int additional_data_len,
    ffi.Pointer<ffi.Char> authentication_data_ptr,
    int authentication_data_len,
  ) {
    return _h_aes_encrypt_header_using_cache(
      symmetric_key_ptr,
      symmetric_key_len,
      header_bytes_ptr,
      header_bytes_len,
      cache_handle,
      encryption_policy_ptr,
      additional_data_ptr,
      additional_data_len,
      authentication_data_ptr,
      authentication_data_len,
    );
  }

  late final _h_aes_encrypt_header_using_cachePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_aes_encrypt_header_using_cache');
  late final _h_aes_encrypt_header_using_cache =
      _h_aes_encrypt_header_using_cachePtr.asFunction<
          int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              int,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              int,
              ffi.Pointer<ffi.Char>,
              int)>();

  /// Encrypt a header without using an encryption cache.
  /// It is slower but does not require destroying any cache when done.
  ///
  /// The symmetric key and header bytes are returned in the first OUT parameters
  /// # Safety
  int h_aes_encrypt_header(
    ffi.Pointer<ffi.Char> symmetric_key_ptr,
    ffi.Pointer<ffi.Int> symmetric_key_len,
    ffi.Pointer<ffi.Char> header_bytes_ptr,
    ffi.Pointer<ffi.Int> header_bytes_len,
    ffi.Pointer<ffi.Char> policy_ptr,
    ffi.Pointer<ffi.Char> pk_ptr,
    int pk_len,
    ffi.Pointer<ffi.Char> encryption_policy_ptr,
    ffi.Pointer<ffi.Char> additional_data_ptr,
    int additional_data_len,
    ffi.Pointer<ffi.Char> authentication_data_ptr,
    int authentication_data_len,
  ) {
    return _h_aes_encrypt_header(
      symmetric_key_ptr,
      symmetric_key_len,
      header_bytes_ptr,
      header_bytes_len,
      policy_ptr,
      pk_ptr,
      pk_len,
      encryption_policy_ptr,
      additional_data_ptr,
      additional_data_len,
      authentication_data_ptr,
      authentication_data_len,
    );
  }

  late final _h_aes_encrypt_headerPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_aes_encrypt_header');
  late final _h_aes_encrypt_header = _h_aes_encrypt_headerPtr.asFunction<
      int Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int)>();

  /// Create a cache of the User Decryption Key which can be re-used
  /// when decrypting multiple messages. This avoids having to re-instantiate
  /// the user key on the Rust side on every decryption which is costly.
  ///
  /// This method is to be used in conjunction with
  /// h_aes_decrypt_header_using_cache()
  ///
  /// WARN: h_aes_destroy_decryption_cache() should be called
  /// to reclaim the memory of the cache when done
  /// # Safety
  int h_aes_create_decryption_cache(
    ffi.Pointer<ffi.Int> cache_handle,
    ffi.Pointer<ffi.Char> usk_ptr,
    int usk_len,
  ) {
    return _h_aes_create_decryption_cache(
      cache_handle,
      usk_ptr,
      usk_len,
    );
  }

  late final _h_aes_create_decryption_cachePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<ffi.Int>, ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_aes_create_decryption_cache');
  late final _h_aes_create_decryption_cache =
      _h_aes_create_decryption_cachePtr.asFunction<
          int Function(ffi.Pointer<ffi.Int>, ffi.Pointer<ffi.Char>, int)>();

  /// The function should be called to reclaim memory
  /// of the cache created using h_aes_create_decryption_cache()
  /// # Safety
  int h_aes_destroy_decryption_cache(
    int cache_handle,
  ) {
    return _h_aes_destroy_decryption_cache(
      cache_handle,
    );
  }

  late final _h_aes_destroy_decryption_cachePtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Int)>>(
          'h_aes_destroy_decryption_cache');
  late final _h_aes_destroy_decryption_cache =
      _h_aes_destroy_decryption_cachePtr.asFunction<int Function(int)>();

  /// Decrypts an encrypted header using a cache.
  /// Returns the symmetric key and additional data if available.
  ///
  /// No additional data will be returned if the `additional_data_ptr` is NULL.
  ///
  /// # Safety
  int h_aes_decrypt_header_using_cache(
    ffi.Pointer<ffi.Char> symmetric_key_ptr,
    ffi.Pointer<ffi.Int> symmetric_key_len,
    ffi.Pointer<ffi.Char> additional_data_ptr,
    ffi.Pointer<ffi.Int> additional_data_len,
    ffi.Pointer<ffi.Char> encrypted_header_ptr,
    int encrypted_header_len,
    ffi.Pointer<ffi.Char> authentication_data_ptr,
    int authentication_data_len,
    int cache_handle,
  ) {
    return _h_aes_decrypt_header_using_cache(
      symmetric_key_ptr,
      symmetric_key_len,
      additional_data_ptr,
      additional_data_len,
      encrypted_header_ptr,
      encrypted_header_len,
      authentication_data_ptr,
      authentication_data_len,
      cache_handle,
    );
  }

  late final _h_aes_decrypt_header_using_cachePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Int)>>('h_aes_decrypt_header_using_cache');
  late final _h_aes_decrypt_header_using_cache =
      _h_aes_decrypt_header_using_cachePtr.asFunction<
          int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              int,
              ffi.Pointer<ffi.Char>,
              int,
              int)>();

  /// Decrypts an encrypted header, returning the symmetric key and additional
  /// data if available.
  ///
  /// Slower than using a cache but avoids handling the cache creation and
  /// destruction.
  ///
  /// No additional data will be returned if the `additional_data_ptr` is NULL.
  ///
  /// # Safety
  int h_aes_decrypt_header(
    ffi.Pointer<ffi.Char> symmetric_key_ptr,
    ffi.Pointer<ffi.Int> symmetric_key_len,
    ffi.Pointer<ffi.Char> additional_data_ptr,
    ffi.Pointer<ffi.Int> additional_data_len,
    ffi.Pointer<ffi.Char> encrypted_header_ptr,
    int encrypted_header_len,
    ffi.Pointer<ffi.Char> authentication_data_ptr,
    int authentication_data_len,
    ffi.Pointer<ffi.Char> usk_ptr,
    int usk_len,
  ) {
    return _h_aes_decrypt_header(
      symmetric_key_ptr,
      symmetric_key_len,
      additional_data_ptr,
      additional_data_len,
      encrypted_header_ptr,
      encrypted_header_len,
      authentication_data_ptr,
      authentication_data_len,
      usk_ptr,
      usk_len,
    );
  }

  late final _h_aes_decrypt_headerPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_aes_decrypt_header');
  late final _h_aes_decrypt_header = _h_aes_decrypt_headerPtr.asFunction<
      int Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int)>();

  /// # Safety
  int h_aes_symmetric_encryption_overhead() {
    return _h_aes_symmetric_encryption_overhead();
  }

  late final _h_aes_symmetric_encryption_overheadPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>(
          'h_aes_symmetric_encryption_overhead');
  late final _h_aes_symmetric_encryption_overhead =
      _h_aes_symmetric_encryption_overheadPtr.asFunction<int Function()>();

  /// # Safety
  int h_aes_encrypt_block(
    ffi.Pointer<ffi.Char> ciphertext_ptr,
    ffi.Pointer<ffi.Int> ciphertext_len,
    ffi.Pointer<ffi.Char> symmetric_key_ptr,
    int symmetric_key_len,
    ffi.Pointer<ffi.Char> authentication_data_ptr,
    int authentication_data_len,
    ffi.Pointer<ffi.Char> plaintext_ptr,
    int plaintext_len,
  ) {
    return _h_aes_encrypt_block(
      ciphertext_ptr,
      ciphertext_len,
      symmetric_key_ptr,
      symmetric_key_len,
      authentication_data_ptr,
      authentication_data_len,
      plaintext_ptr,
      plaintext_len,
    );
  }

  late final _h_aes_encrypt_blockPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_aes_encrypt_block');
  late final _h_aes_encrypt_block = _h_aes_encrypt_blockPtr.asFunction<
      int Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int)>();

  /// # Safety
  int h_aes_decrypt_block(
    ffi.Pointer<ffi.Char> cleartext_ptr,
    ffi.Pointer<ffi.Int> cleartext_len,
    ffi.Pointer<ffi.Char> symmetric_key_ptr,
    int symmetric_key_len,
    ffi.Pointer<ffi.Char> authentication_data_ptr,
    int authentication_data_len,
    ffi.Pointer<ffi.Char> encrypted_bytes_ptr,
    int encrypted_bytes_len,
  ) {
    return _h_aes_decrypt_block(
      cleartext_ptr,
      cleartext_len,
      symmetric_key_ptr,
      symmetric_key_len,
      authentication_data_ptr,
      authentication_data_len,
      encrypted_bytes_ptr,
      encrypted_bytes_len,
    );
  }

  late final _h_aes_decrypt_blockPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_aes_decrypt_block');
  late final _h_aes_decrypt_block = _h_aes_decrypt_blockPtr.asFunction<
      int Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int)>();

  /// Hybrid encrypt some content
  /// # Safety
  int h_aes_encrypt(
    ffi.Pointer<ffi.Char> ciphertext_ptr,
    ffi.Pointer<ffi.Int> ciphertext_len,
    ffi.Pointer<ffi.Char> policy_ptr,
    ffi.Pointer<ffi.Char> pk_ptr,
    int pk_len,
    ffi.Pointer<ffi.Char> encryption_policy_ptr,
    ffi.Pointer<ffi.Char> plaintext_ptr,
    int plaintext_len,
    ffi.Pointer<ffi.Char> additional_data_ptr,
    int additional_data_len,
    ffi.Pointer<ffi.Char> authentication_data_ptr,
    int authentication_data_len,
  ) {
    return _h_aes_encrypt(
      ciphertext_ptr,
      ciphertext_len,
      policy_ptr,
      pk_ptr,
      pk_len,
      encryption_policy_ptr,
      plaintext_ptr,
      plaintext_len,
      additional_data_ptr,
      additional_data_len,
      authentication_data_ptr,
      authentication_data_len,
    );
  }

  late final _h_aes_encryptPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_aes_encrypt');
  late final _h_aes_encrypt = _h_aes_encryptPtr.asFunction<
      int Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int)>();

  /// Hybrid decrypt some content
  ///
  /// # Safety
  int h_aes_decrypt(
    ffi.Pointer<ffi.Char> plaintext_ptr,
    ffi.Pointer<ffi.Int> plaintext_len,
    ffi.Pointer<ffi.Char> additional_data_ptr,
    ffi.Pointer<ffi.Int> additional_data_len,
    ffi.Pointer<ffi.Char> ciphertext_ptr,
    int ciphertext_len,
    ffi.Pointer<ffi.Char> authentication_data_ptr,
    int authentication_data_len,
    ffi.Pointer<ffi.Char> usk_ptr,
    int usk_len,
  ) {
    return _h_aes_decrypt(
      plaintext_ptr,
      plaintext_len,
      additional_data_ptr,
      additional_data_len,
      ciphertext_ptr,
      ciphertext_len,
      authentication_data_ptr,
      authentication_data_len,
      usk_ptr,
      usk_len,
    );
  }

  late final _h_aes_decryptPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('h_aes_decrypt');
  late final _h_aes_decrypt = _h_aes_decryptPtr.asFunction<
      int Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          int)>();

  /// Convert a boolean access policy expression into a
  /// json_expression that can be used to create a key using
  /// the KMIP interface
  ///
  /// Returns
  /// - 0 if success
  /// - 1 in case of unrecoverable error
  /// - n if the return buffer is too small and should be of size n
  /// (including the NULL byte)
  ///
  /// `json_expr_len` contains the length of the JSON string on return
  /// (including the terminating NULL byte)
  ///
  /// # Safety
  int h_access_policy_expression_to_json(
    ffi.Pointer<ffi.Char> json_expr_ptr,
    ffi.Pointer<ffi.Int> json_expr_len,
    ffi.Pointer<ffi.Char> boolean_expression_ptr,
  ) {
    return _h_access_policy_expression_to_json(
      json_expr_ptr,
      json_expr_len,
      boolean_expression_ptr,
    );
  }

  late final _h_access_policy_expression_to_jsonPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>)>>('h_access_policy_expression_to_json');
  late final _h_access_policy_expression_to_json =
      _h_access_policy_expression_to_jsonPtr.asFunction<
          int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>)>();

  void log(
    ffi.Pointer<ffi.Int> s,
  ) {
    return _log(
      s,
    );
  }

  late final _logPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Int>)>>(
          'log');
  late final _log = _logPtr.asFunction<void Function(ffi.Pointer<ffi.Int>)>();

  void alert(
    ffi.Pointer<ffi.Int> s,
  ) {
    return _alert(
      s,
    );
  }

  late final _alertPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Int>)>>(
          'alert');
  late final _alert =
      _alertPtr.asFunction<void Function(ffi.Pointer<ffi.Int>)>();
}

const int MAX_CLEAR_TEXT_SIZE = 1073741824;
