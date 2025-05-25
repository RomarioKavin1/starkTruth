use starknet::ContractAddress;

/// Struct to represent secret data
#[derive(Drop, Serde, starknet::Store)]
pub struct SecretData {
    pub creator: ContractAddress,
    pub user: ContractAddress,
    pub post_id: ByteArray,
    pub title: ByteArray,
    pub description: ByteArray,
    pub duration: u256,
    pub is_complete: bool,
}

/// Interface for the SecretManager contract
#[starknet::interface]
pub trait ISecretManager<TContractState> {
    /// Creates a pre-secret and returns the secret hash
    fn create_pre_secret(ref self: TContractState, user: ContractAddress) -> felt252;
    
    /// Associates post details with an existing secret
    fn associate_post_details(
        ref self: TContractState,
        secret_hash: felt252,
        post_id: ByteArray,
        title: ByteArray,
        description: ByteArray,
        duration: u256
    );
    
    /// Verifies a secret and returns the title and post_id
    fn verify_secret(self: @TContractState, secret_hash: felt252) -> (ByteArray, ByteArray);
}

/// SecretManager contract implementation
#[starknet::contract]
pub mod SecretManager {
    use core::pedersen::pedersen;
    use core::starknet::{get_caller_address, ContractAddress};
    use core::starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use super::SecretData;

    #[storage]
    struct Storage {
        secrets: Map<felt252, SecretData>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        SecretCreated: SecretCreated,
        PostDetailsAssociated: PostDetailsAssociated,
    }

    #[derive(Drop, starknet::Event)]
    pub struct SecretCreated {
        #[key]
        pub secret_hash: felt252,
        #[key]
        pub creator: ContractAddress,
        #[key]
        pub user: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PostDetailsAssociated {
        #[key]
        pub secret_hash: felt252,
        pub post_id: ByteArray,
        pub title: ByteArray,
    }

    // Salt constant (using felt252 instead of string for Cairo)
    const SALT: felt252 = 'SOMERANDOMSECRET';

    #[abi(embed_v0)]
    impl SecretManagerImpl of super::ISecretManager<ContractState> {
        fn create_pre_secret(ref self: ContractState, user: ContractAddress) -> felt252 {
            let caller = get_caller_address();
            
            // Create hash using Pedersen hash (Starknet's native hash function)
            let temp_hash = pedersen(caller.into(), user.into());
            let secret_hash = pedersen(temp_hash, SALT);

            // Create initial secret data
            let secret_data = SecretData {
                creator: caller,
                user,
                post_id: "",
                title: "",
                description: "",
                duration: 0,
                is_complete: false,
            };

            // Store the secret
            self.secrets.write(secret_hash, secret_data);

            // Emit event
            self.emit(Event::SecretCreated(SecretCreated {
                secret_hash,
                creator: caller,
                user,
            }));

            secret_hash
        }

        fn associate_post_details(
            ref self: ContractState,
            secret_hash: felt252,
            post_id: ByteArray,
            title: ByteArray,
            description: ByteArray,
            duration: u256
        ) {
            let caller = get_caller_address();
            let mut secret_data = self.secrets.read(secret_hash);

            // Verify caller is the creator
            assert(secret_data.creator == caller, 'Not creator of secret');
            assert(!secret_data.is_complete, 'Details already associated');

            // Update the secret data
            secret_data.post_id = post_id.clone();
            secret_data.title = title.clone();
            secret_data.description = description;
            secret_data.duration = duration;
            secret_data.is_complete = true;

            // Store the updated data
            self.secrets.write(secret_hash, secret_data);

            // Emit event
            self.emit(Event::PostDetailsAssociated(PostDetailsAssociated {
                secret_hash,
                post_id,
                title,
            }));
        }

        fn verify_secret(self: @ContractState, secret_hash: felt252) -> (ByteArray, ByteArray) {
            let secret_data = self.secrets.read(secret_hash);
            assert(secret_data.is_complete, 'Secret not fully associated');
            
            (secret_data.title, secret_data.post_id)
        }
    }
} 