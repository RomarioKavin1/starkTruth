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
    
    let secret_hash = secret_manager.create_pre_secret(user);
    assert!(secret_hash != 0, "Secret hash should not be zero");
    
    stop_cheat_caller_address(secret_manager.contract_address);
}

#[test]
fn test_associate_post_details() {
    let secret_manager = deploy_secret_manager();
    let creator: ContractAddress = contract_address_const::<0x123>();
    let user: ContractAddress = contract_address_const::<0x456>();
    
    start_cheat_caller_address(secret_manager.contract_address, creator);
    
    // Create pre-secret
    let secret_hash = secret_manager.create_pre_secret(user);
    
    // Associate post details
    let post_id: ByteArray = "post123";
    let title: ByteArray = "My Secret Title";
    let description: ByteArray = "This is a secret description";
    let duration: u256 = 3600; // 1 hour
    
    secret_manager.associate_post_details(secret_hash, post_id, title, description, duration);
    
    stop_cheat_caller_address(secret_manager.contract_address);
}

#[test]
fn test_verify_secret() {
    let secret_manager = deploy_secret_manager();
    let creator: ContractAddress = contract_address_const::<0x123>();
    let user: ContractAddress = contract_address_const::<0x456>();
    
    start_cheat_caller_address(secret_manager.contract_address, creator);
    
    // Create pre-secret and associate details
    let secret_hash = secret_manager.create_pre_secret(user);
    let post_id: ByteArray = "post123";
    let title: ByteArray = "My Secret Title";
    let description: ByteArray = "This is a secret description";
    let duration: u256 = 3600;
    
    secret_manager.associate_post_details(secret_hash, post_id.clone(), title.clone(), description, duration);
    
    // Verify secret
    let (returned_title, returned_post_id) = secret_manager.verify_secret(secret_hash);
    assert!(returned_title == title, "Title should match");
    assert!(returned_post_id == post_id, "Post ID should match");
    
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
    let secret_hash = secret_manager.create_pre_secret(user);
    stop_cheat_caller_address(secret_manager.contract_address);
    
    // Imposter tries to associate details (should fail)
    start_cheat_caller_address(secret_manager.contract_address, imposter);
    secret_manager.associate_post_details(
        secret_hash, 
        "post123", 
        "Malicious Title", 
        "Malicious Description", 
        3600
    );
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
    let secret_hash = secret_manager.create_pre_secret(user);
    secret_manager.associate_post_details(
        secret_hash, 
        "post123", 
        "Title", 
        "Description", 
        3600
    );
    
    // Try to associate details again (should fail)
    secret_manager.associate_post_details(
        secret_hash, 
        "post456", 
        "New Title", 
        "New Description", 
        7200
    );
    
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
    let secret_hash = secret_manager.create_pre_secret(user);
    
    // Try to verify incomplete secret (should fail)
    secret_manager.verify_secret(secret_hash);
    
    stop_cheat_caller_address(secret_manager.contract_address);
} 