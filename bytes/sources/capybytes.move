module bytes::capybytes {
    use std::string;

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use capy::capy::Capy;
    
    use nft_protocol::nft;
    use nft_protocol::display;
    use nft_protocol::creators;
    use nft_protocol::collection::{Self, MintCap};

    /// One time witness is only instantiated in the init method
    struct CAPYBYTES has drop {}

    /// Can be used for authorization of other actions post-creation. It is
    /// vital that this struct is not freely given to any contract, because it
    /// serves as an auth token.
    struct Witness has drop {}

    fun init(witness: CAPYBYTES, ctx: &mut TxContext) {
        let (mint_cap, collection) = collection::create(
            &witness, ctx,
        );

        collection::add_domain(
            &mut collection,
            &mut mint_cap,
            creators::from_address(tx_context::sender(ctx))
        );

        // Register custom domains
        display::add_collection_display_domain(
            &mut collection,
            &mut mint_cap,
            string::utf8(b"Capybytes"),
            string::utf8(b"A Collection of Wrapped OriginByte Capys"),
        );

        display::add_collection_url_domain(
            &mut collection,
            &mut mint_cap,
            sui::url::new_unsafe_from_bytes(b"https://originbyte.io/"),
        );

        display::add_collection_symbol_domain(
            &mut collection,
            &mut mint_cap,
            string::utf8(b"OBCAP")
        );

        transfer::transfer(mint_cap, tx_context::sender(ctx));
        transfer::share_object(collection);
    }

    struct DeadBytesDomain has key, store {
        id: UID,
        face: bool,
        weapon_sticker: bool
    }

    public entry fun mint_nft(
        capy: Capy,
        face: bool,
        weapon_sticker: bool,
        _mint_cap: &MintCap<CAPYBYTES>,
        receiver: address,
        ctx: &mut TxContext,
    ) {
        let nft = nft::new<CAPYBYTES, Witness>(
            &Witness {}, tx_context::sender(ctx), ctx
        );

        nft::add_domain(&mut nft, capy, ctx);

        let db_domain = DeadBytesDomain {
            id: object::new(ctx),
            face,
            weapon_sticker,
        };

        nft::add_domain(&mut nft, db_domain, ctx);

        transfer::transfer(nft, receiver);
    }
}
