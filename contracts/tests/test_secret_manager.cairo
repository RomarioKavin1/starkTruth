use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};
use starknet::{ContractAddress, contract_address_const};
use contracts::secret_manager::{ISecretManagerDispatcher, ISecretManagerDispatcherTrait};

fn deploy_secret_manager() -> ISecretManagerDispatcher {
    let contract = declare("SecretManager").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    ISecretManagerDispatcher { contract_address }
}

#[test]
fn test_create_pre_secret() {
    let secret_manager = deploy_secret_manager();
    let creator: ContractAddress = contract_address_const::<0x123>();
    let user: ContractAddress = contract_address_const::<0x456>();
    
    start_cheat_caller_address(secret_manager.contract_address, creator);
    
    let secret_id = secret_manager.create_pre_secret(user);
    assert!(secret_id != 0, "Secret ID should be non-zero pseudo-random number");
    
    // Test that counter increments
    let counter = secret_manager.get_next_secret_id();
    assert!(counter == 1, "Counter should be 1 after first secret");
    
    stop_cheat_caller_address(secret_manager.contract_address);
}

#[test]
fn test_associate_post_details() {
    let secret_manager = deploy_secret_manager();
    let creator: ContractAddress = contract_address_const::<0x123>();
    let user: ContractAddress = contract_address_const::<0x456>();
    
    start_cheat_caller_address(secret_manager.contract_address, creator);
    
    // Create pre-secret
    let secret_id = secret_manager.create_pre_secret(user);
    
    // Associate post details
    let post_id: u64 = 123;
    let duration: u256 = 3600; // 1 hour
    
    secret_manager.associate_post_details(secret_id, post_id, duration);
    
    stop_cheat_caller_address(secret_manager.contract_address);
}

#[test]
fn test_verify_secret() {
    let secret_manager = deploy_secret_manager();
    let creator: ContractAddress = contract_address_const::<0x123>();
    let user: ContractAddress = contract_address_const::<0x456>();
    
    start_cheat_caller_address(secret_manager.contract_address, creator);
    
    // Create pre-secret and associate details
    let secret_id = secret_manager.create_pre_secret(user);
    let post_id: u64 = 123;
    let duration: u256 = 3600;
    
    secret_manager.associate_post_details(secret_id, post_id, duration);
    
    // Verify secret
    let returned_post_id = secret_manager.verify_secret(secret_id);
    assert!(returned_post_id == post_id, "Post ID should match");
    
    stop_cheat_caller_address(secret_manager.contract_address);
}

#[test]
fn test_multiple_secrets() {
    let secret_manager = deploy_secret_manager();
    let creator: ContractAddress = contract_address_const::<0x123>();
    let user1: ContractAddress = contract_address_const::<0x456>();
    let user2: ContractAddress = contract_address_const::<0x789>();
    
    start_cheat_caller_address(secret_manager.contract_address, creator);
    
    // Create multiple secrets
    let secret_id1 = secret_manager.create_pre_secret(user1);
    let secret_id2 = secret_manager.create_pre_secret(user2);
    
    assert!(secret_id1 != 0, "First secret ID should be non-zero");
    assert!(secret_id2 != 0, "Second secret ID should be non-zero");
    assert!(secret_id1 != secret_id2, "Secret IDs should be different");
    
    // Associate details for both
    secret_manager.associate_post_details(secret_id1, 123, 3600);
    secret_manager.associate_post_details(secret_id2, 456, 7200);
    
    // Verify both secrets
    let post_id1 = secret_manager.verify_secret(secret_id1);
    let post_id2 = secret_manager.verify_secret(secret_id2);
    
    assert!(post_id1 == 123, "First post ID should match");
    assert!(post_id2 == 456, "Second post ID should match");
    
    stop_cheat_caller_address(secret_manager.contract_address);
}

#[test]
#[should_panic(expected: 'Not creator of secret')]
fn test_associate_post_details_not_creator() {
    let secret_manager = deploy_secret_manager();
    let creator: ContractAddress = contract_address_const::<0x123>();
    let user: ContractAddress = contract_address_const::<0x456>();
    let imposter: ContractAddress = contract_address_const::<0x789>();
    
    // Creator creates pre-secret
    start_cheat_caller_address(secret_manager.contract_address, creator);
    let secret_id = secret_manager.create_pre_secret(user);
    stop_cheat_caller_address(secret_manager.contract_address);
    
    // Imposter tries to associate details (should fail)
    start_cheat_caller_address(secret_manager.contract_address, imposter);
    secret_manager.associate_post_details(secret_id, 123, 3600);
    stop_cheat_caller_address(secret_manager.contract_address);
}

#[test]
#[should_panic(expected: 'Details already associated')]
fn test_associate_post_details_already_complete() {
    let secret_manager = deploy_secret_manager();
    let creator: ContractAddress = contract_address_const::<0x123>();
    let user: ContractAddress = contract_address_const::<0x456>();
    
    start_cheat_caller_address(secret_manager.contract_address, creator);
    
    // Create pre-secret and associate details
    let secret_id = secret_manager.create_pre_secret(user);
    secret_manager.associate_post_details(secret_id, 123, 3600);
    
    // Try to associate details again (should fail)
    secret_manager.associate_post_details(secret_id, 456, 7200);
    
    stop_cheat_caller_address(secret_manager.contract_address);
}

#[test]
#[should_panic(expected: 'Secret not fully associated')]
fn test_verify_secret_not_complete() {
    let secret_manager = deploy_secret_manager();
    let creator: ContractAddress = contract_address_const::<0x123>();
    let user: ContractAddress = contract_address_const::<0x456>();
    
    start_cheat_caller_address(secret_manager.contract_address, creator);
    
    // Create pre-secret but don't associate details
    let secret_id = secret_manager.create_pre_secret(user);
    
    // Try to verify incomplete secret (should fail)
    secret_manager.verify_secret(secret_id);
    
    stop_cheat_caller_address(secret_manager.contract_address);
} 