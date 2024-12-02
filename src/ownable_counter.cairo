// defines the inteface with 3 functions
#[starknet::interface]
pub trait IOwnableCounter<TContractState> {
    fn get_count(self: @TContractState) -> u128;
    fn increase_count(ref self: TContractState);
    fn decrease_count(ref self: TContractState);
}

// OwnableCounter contract
#[starknet::contract]
mod OwnableCounter {
    use super::IOwnableCounter; // import the interface
    use ownable_component::PrivateTrait; // imports the private trait from ownable component
    use core::starknet::{ContractAddress}; // impoert contract address
    use intro_to_components::ownable_component::ownable_component::ownable_component; // import the component
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess}; // import StarkNet's storage module: read-only & write-only access

    // component macro/function specifing the path, storage & events.
    // This line is essential in creating a reusable piece of functionality within the contract. 
    component!(path: ownable_component, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)] // instructs compiler how to generate the contract's interface.
    impl OwnableImpl = ownable_component::Ownable<ContractState>; // handles public-facing ownership operations
    impl OwnableInternalImpl = ownable_component::PrivateImpl<ContractState>; // deals with internal ownership checks and modifications.

    #[storage]
    struct Storage {
        counter: u128,
        #[substorage(v0)]
        ownable: ownable_component::Storage // ownable component in storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: ownable_component::Event // ownable component in Events
    }

    // constructor attribute.
    // ref self: ContractState: This takes the entire contract state as a reference. The ref keyword indicates that we're not taking ownership of the state.
    // owner: ContractAddress: This parameter represents the address of the owner when the contract is deployed.
    #[constructor] 
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner); // The constructor initializes the ownership of the contract with the specified owner.
    }

    // Main functionality of the contract
    #[abi(embed_v0)]
    impl OwnableCounterImpl of IOwnableCounter<ContractState> {
        // reads data from the state
        fn get_count(self: @ContractState) -> u128 { 
            self.counter.read()
        }

        fn increase_count(ref self: ContractState) { // writes data to the state
            self.ownable.assert_only_owner(); // checks if the caller is the owner
            let initial_counter = self.counter.read();
            self.counter.write(initial_counter + 1); // 
        }

        fn decrease_count(ref self: ContractState) {
            self.ownable.assert_only_owner();
            let initial_counter = self.counter.read();
            self.counter.write(initial_counter - 1);

        }
    }
}

