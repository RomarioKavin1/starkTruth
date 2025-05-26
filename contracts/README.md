# SecretManager Contract

This repository contains the Cairo 2 implementation of the SecretManager contract

## Overview

The SecretManager contract allows users to create and manage secrets in a two-step process:

1. **Pre-Secret Creation**: Creates a simple sequential secret ID linking a creator and a user
2. **Post Details Association**: Associates post metadata (post_id, duration) with the secret
3. **Secret Verification**: Allows verification and retrieval of secret details

## Contract Structure

### SecretData Struct

```cairo
struct SecretData {
    creator: ContractAddress,      // Address that created the secret
    user: ContractAddress,         // Address of the intended user
    post_id: u64,                 // Associated post ID (numeric)
    duration: u256,               // Duration in seconds
    is_complete: bool,            // Whether details are associated
}
```

### Main Functions

#### `create_pre_secret(user: ContractAddress) -> u64`

- Creates a pre-secret for a specific user
- Returns a pseudo-random 64-bit secret ID (based on caller, user, timestamp, and counter)
- Emits `SecretCreated` event

#### `associate_post_details(secret_id: u64, post_id: u64, duration: u256)`

- Associates post details with an existing secret
- Only the original creator can call this function
- Can only be called once per secret
- Emits `PostDetailsAssociated` event

#### `verify_secret(secret_id: u64) -> u64`

- Verifies a secret and returns the post_id
- Only works for completed secrets
- Returns the associated post_id

#### `get_next_secret_id() -> u64`

- Returns the current secret counter (number of secrets created)
- Useful for tracking how many secrets have been created

### SecretCreated

Emitted when a pre-secret is created:

```cairo
#[key] secret_id: u64
#[key] creator: ContractAddress
#[key] user: ContractAddress
```

### PostDetailsAssociated

Emitted when post details are associated:

```cairo
#[key] secret_id: u64
post_id: u64
```

## Deployment Information

### Class Hash

0x06c36c4e464c60239929d67b02169342526e9272c1bb8fd01eb8d1ee585f86eb

### Contract Address (Sepolia)

0x01cac254acbcd5c2a68c3a5aa04b58466d6cb0e578a431c0f4a68c2790dff610

### Block Explorer

https://sepolia.starkscan.co/contract/0x01cac254acbcd5c2a68c3a5aa04b58466d6cb0e578a431c0f4a68c2790dff610
