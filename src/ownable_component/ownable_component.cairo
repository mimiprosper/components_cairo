// Ownable component. 
// This component helps manage ownership of a contract

use core::starknet::ContractAddress;

// interface declaration
#[starknet::interface]  
pub trait IOwnable<TContractState> {
    fn owner(self: @TContractState ) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TContractState);
}

// Errors
mod Errors {
    pub const ZERO_ADDRESS_OWNER: felt252 = 'Owner cannot be address zero';
    pub const ZERO_ADDRESS_CALLER: felt252 = 'Caller cannot be address zero';
    pub const NOT_OWNER: felt252 = 'Caller not owner';
}

// Component implementation
#[starknet::component]
pub mod ownable_component {
    // import modules used for the components
    use core::num::traits::Zero;
    use core::starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess}; //read or write to storage
    use super::Errors; // import the error modules

    // storage 
    #[storage]
    pub struct Storage {
        owner: ContractAddress,
        caller: ContractAddress
    }

    // events
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OwnershipTransferred: OwnershipTransferred
    }

    #[derive(Drop, starknet::Event)]
    pub struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress,
    }

    // Ownable Implementation. This makes it publically accessible to external contracts
    // This makes composibilty work
    #[embeddable_as(Ownable)]  
    impl OwnableImpl<
        TContractState, +HasComponent<TContractState>
    > of super::IOwnable<ComponentState<TContractState>> {
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }

        fn transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner: ContractAddress
        ) {
            assert(!new_owner.is_zero(), Errors::ZERO_ADDRESS_CALLER);
            self.assert_only_owner();
            self._transfer_ownership(new_owner);
        }

        fn renounce_ownership(ref self: ComponentState<TContractState>) {
            self.assert_only_owner();
            self._transfer_ownership(Zero::zero());
        }
    }

    // This is for the internal implementation of the component
    #[generate_trait] 
    pub impl PrivateImpl<
        TContractState, +HasComponent<TContractState>
    > of PrivateTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            self._transfer_ownership(owner);
        }

        fn assert_only_owner(self: @ComponentState<TContractState>) {
            let owner: ContractAddress = self.owner.read();
            let caller: ContractAddress = get_caller_address();
            assert(!caller.is_zero(), Errors::ZERO_ADDRESS_CALLER);
            assert(caller == owner, Errors::NOT_OWNER);
        }

        fn _transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner: ContractAddress
        ) {
            let previous_owner: ContractAddress = self.owner.read();
            self.owner.write(new_owner);
            self
                .emit(
                    OwnershipTransferred { previous_owner: previous_owner, new_owner: new_owner }
                );
        }
    }
}
