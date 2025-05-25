## Overview

The SecretManager contract allows users to create and manage secrets in a two-step process:

1. **Pre-Secret Creation**: Creates a secret hash linking a creator and a user
2. **Post Details Association**: Associates post metadata (title, description, etc.) with the secret
3. **Secret Verification**: Allows verification and retrieval of secret details

## Contract Structure

### SecretData Struct

```cairo
struct SecretData {
    creator: ContractAddress,      // Address that created the secret
    user: ContractAddress,         // Address of the intended user
    post_id: ByteArray,           // Associated post ID
    title: ByteArray,             // Secret title
    description: ByteArray,       // Secret description
    duration: u256,               // Duration in seconds
    is_complete: bool,            // Whether details are associated
}
```

### Main Functions

#### `create_pre_secret(user: ContractAddress) -> felt252`

- Creates a pre-secret for a specific user
- Returns a unique secret hash generated using Pedersen hash
- Emits `SecretCreated` event

#### `associate_post_details(secret_hash, post_id, title, description, duration)`

- Associates post details with an existing secret
- Only the original creator can call this function
- Can only be called once per secret
- Emits `PostDetailsAssociated` event

#### `verify_secret(secret_hash) -> (ByteArray, ByteArray)`

- Verifies a secret and returns the title and post_id
- Only works for completed secrets
- Returns tuple of (title, post_id)

## Events

### SecretCreated

Emitted when a pre-secret is created:

```cairo
#[key] secret_hash: felt252
#[key] creator: ContractAddress
#[key] user: ContractAddress
```

### PostDetailsAssociated

Emitted when post details are associated:

```cairo
#[key] secret_hash: felt252
post_id: ByteArray
title: ByteArray
```

### class hash

0x01fd652d2a5af8bed4ea558eadb45cfbf6510362a355549251f94952de00566c

### deployment:

0x027d49de9a9f841cdd36bba64b68736d170bf374b9e8a1c22c826406a17d20fa

https://sepolia.starkscan.co/contract/0x027d49de9a9f841cdd36bba64b68736d170bf374b9e8a1c22c826406a17d20fa#read-write-contract-sub-write
