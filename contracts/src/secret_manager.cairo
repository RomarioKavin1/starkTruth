use starknet::ContractAddress;

/// Struct to represent secret data
#[derive(Drop, Serde, starknet::Store)]
pub struct SecretData {
    pub creator: ContractAddress,
    pub user: ContractAddress,
    pub post_id: u64,
    pub duration: u256,
    pub is_complete: bool,
}

/// Interface for the SecretManager contract
#[starknet::interface]
pub trait ISecretManager<TContractState> {
    /// Creates a pre-secret and returns a simple secret ID
    fn create_pre_secret(ref self: TContractState, user: ContractAddress) -> u64;
    
    /// Associates post details with an existing secret
    fn associate_post_details(
        ref self: TContractState,
        secret_id: u64,
        post_id: u64,
        duration: u256
    );
    
    /// Verifies a secret and returns the post_id
    fn verify_secret(self: @TContractState, secret_id: u64) -> u64;
    
    /// Gets the current secret counter (number of secrets created)
    fn get_next_secret_id(self: @TContractState) -> u64;
}

/// SecretManager contract implementation
#[starknet::contract]
pub mod SecretManager {
    use core::starknet::{get_caller_address, ContractAddress, get_block_timestamp};
    use core::starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess,
        StoragePointerReadAccess, StoragePointerWriteAccess
    };
    use core::pedersen::pedersen;
    use super::SecretData;

    #[storage]
    struct Storage {
        secrets: Map<u64, SecretData>,
        secret_counter: u64,
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
        pub secret_id: u64,
        #[key]
        pub creator: ContractAddress,
        #[key]
        pub user: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PostDetailsAssociated {
        #[key]
        pub secret_id: u64,
        pub post_id: u64,
    }

    #[abi(embed_v0)]
    impl SecretManagerImpl of super::ISecretManager<ContractState> {
        fn create_pre_secret(ref self: ContractState, user: ContractAddress) -> u64 {
            let caller = get_caller_address();
            
            // Get current counter and increment it
            let counter = self.secret_counter.read();
            self.secret_counter.write(counter + 1);
            
            // Create a pseudo-random but deterministic secret ID using:
            // - caller address
            // - user address  
            // - current timestamp
            // - counter for uniqueness
            let timestamp = get_block_timestamp();
            let hash_input = pedersen(
                pedersen(caller.into(), user.into()),
                pedersen(timestamp.into(), counter.into())
            );
            
            // Convert felt252 to u256 then take lower 64 bits for manageable ID
            let hash_as_u256: u256 = hash_input.into();
            let secret_id: u64 = (hash_as_u256.low & 0xFFFFFFFFFFFFFFFF).try_into().unwrap();

            // Create initial secret data
            let secret_data = SecretData {
                creator: caller,
                user,
                post_id: 0,
                duration: 0,
                is_complete: false,
            };

            // Store the secret
            self.secrets.write(secret_id, secret_data);

            // Emit event
            self.emit(Event::SecretCreated(SecretCreated {
                secret_id,
                creator: caller,
                user,
            }));

            secret_id
        }

        fn associate_post_details(
            ref self: ContractState,
            secret_id: u64,
            post_id: u64,
            duration: u256
        ) {
            let caller = get_caller_address();
            let mut secret_data = self.secrets.read(secret_id);

            // Verify caller is the creator
            assert(secret_data.creator == caller, 'Not creator of secret');
            assert(!secret_data.is_complete, 'Details already associated');

            // Update the secret data
            secret_data.post_id = post_id;
            secret_data.duration = duration;
            secret_data.is_complete = true;

            // Store the updated data
            self.secrets.write(secret_id, secret_data);

            // Emit event
            self.emit(Event::PostDetailsAssociated(PostDetailsAssociated {
                secret_id,
                post_id,
            }));
        }

        fn verify_secret(self: @ContractState, secret_id: u64) -> u64 {
            let secret_data = self.secrets.read(secret_id);
            assert(secret_data.is_complete, 'Secret not fully associated');
            
            secret_data.post_id
        }

        fn get_next_secret_id(self: @ContractState) -> u64 {
            self.secret_counter.read()
        }
    }
} 