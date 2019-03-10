#pragma once

#include <eosiolib/eosio.hpp>
#include <eosiolib/time.hpp>
#include <eosiolib/singleton.hpp>

using namespace std;
using namespace eosio;

CONTRACT eosyield : public contract
{
  public:
    using contract::contract;

    //eosyield(name self) : contract(self), yield(self, self) {}

    /* UPDATE AUTH ARGS */

    struct signup_public_key
    {
        uint8_t type;
        array<unsigned char, 33> data;
    };

    struct permission_level_weight
    {
        permission_level permission;
        uint16_t weight;
    };

    struct key_weight
    {
        signup_public_key key;
        uint16_t weight;
    };

    struct wait_weight
    {
        uint32_t wait_sec;
        uint16_t weight;
    };

    struct authority
    {
        uint32_t threshold;
        vector<key_weight> keys;
        vector<permission_level_weight> accounts;
        vector<wait_weight> waits;
    };

    struct updateauth_args
    {
        name account;
        name permission;
        name parent;
        authority data;
    };

    /* UPDATE AUTH ARGS */

    /// @abi table yieldinfo
    TABLE yieldinfo
    {
        name owner;
        time_point_sec expiration;
    };
    typedef singleton<"yieldinfo"_n, yieldinfo> tbl_yield;
    ///tbl_yield yield;

    /// @abi action
    ACTION setowner(name new_owner);
    /// @abi action
    ACTION yieldcontrol(uint32_t yield_seconds);
    /// @abi action
    ACTION extend(uint32_t new_yield_seconds);
    /// @abi action
    ACTION regain();
};

extern "C"
{
    void apply(uint64_t receiver, uint64_t code, uint64_t action)
    {
        auto self = receiver;
        //eosyield thiscontract(self);
        if (code == self)
        {
            switch (action)
            {
                EOSIO_DISPATCH_HELPER(eosyield, (setowner)(yieldcontrol)(extend)(regain))
            }
        }
    }
}
