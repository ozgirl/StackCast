;; StackCast - Bitcoin-backed Prediction Markets
;; A decentralized prediction market platform built on Stacks

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_MARKET_NOT_FOUND (err u404))
(define-constant ERR_MARKET_EXPIRED (err u400))
(define-constant ERR_MARKET_NOT_EXPIRED (err u401))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_INVALID_OUTCOME (err u403))
(define-constant ERR_MARKET_RESOLVED (err u405))
(define-constant ERR_NO_POSITION (err u406))

;; Data Variables
(define-data-var market-counter uint u0)
(define-data-var platform-fee uint u250) ;; 2.5% fee in basis points

;; Data Maps
(define-map markets
  { market-id: uint }
  {
    title: (string-ascii 256),
    description: (string-ascii 1024),
    creator: principal,
    expiry-block: uint,
    resolution-block: uint,
    outcome: (optional uint), ;; 0 = NO, 1 = YES
    total-yes-pool: uint,
    total-no-pool: uint,
    resolved: bool,
    category: (string-ascii 64)
  }
)

(define-map user-positions
  { market-id: uint, user: principal, outcome: uint }
  { amount: uint }
)

(define-map user-claimed
  { market-id: uint, user: principal }
  { claimed: bool }
)

;; Private Functions
(define-private (calculate-payout (market-id uint) (user principal) (winning-outcome uint))
  (let (
    (market (unwrap! (map-get? markets { market-id: market-id }) u0))
    (user-position (default-to u0 (get amount (map-get? user-positions { market-id: market-id, user: user, outcome: winning-outcome }))))
    (winning-pool (if (is-eq winning-outcome u1) (get total-yes-pool market) (get total-no-pool market)))
    (total-pool (+ (get total-yes-pool market) (get total-no-pool market)))
  )
    (if (is-eq user-position u0)
      u0
      (/ (* user-position total-pool) winning-pool)
    )
  )
)

;; Public Functions

;; Create a new prediction market
(define-public (create-market (title (string-ascii 256)) (description (string-ascii 1024)) (expiry-block uint) (category (string-ascii 64)))
  (let (
    (market-id (+ (var-get market-counter) u1))
  )
    (asserts! (> expiry-block stacks-block-height) ERR_MARKET_EXPIRED)
    (map-set markets
      { market-id: market-id }
      {
        title: title,
        description: description,
        creator: tx-sender,
        expiry-block: expiry-block,
        resolution-block: u0,
        outcome: none,
        total-yes-pool: u0,
        total-no-pool: u0,
        resolved: false,
        category: category
      }
    )
    (var-set market-counter market-id)
    (ok market-id)
  )
)

;; Place a bet on a market outcome
(define-public (place-bet (market-id uint) (outcome uint) (amount uint))
  (let (
    (market (unwrap! (map-get? markets { market-id: market-id }) ERR_MARKET_NOT_FOUND))
    (current-position (default-to u0 (get amount (map-get? user-positions { market-id: market-id, user: tx-sender, outcome: outcome }))))
  )
    (asserts! (< stacks-block-height (get expiry-block market)) ERR_MARKET_EXPIRED)
    (asserts! (not (get resolved market)) ERR_MARKET_RESOLVED)
    (asserts! (or (is-eq outcome u0) (is-eq outcome u1)) ERR_INVALID_OUTCOME)
    (asserts! (> amount u0) ERR_INSUFFICIENT_FUNDS)
    
    ;; Transfer STX from user
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update user position
    (map-set user-positions
      { market-id: market-id, user: tx-sender, outcome: outcome }
      { amount: (+ current-position amount) }
    )
    
    ;; Update market pools
    (if (is-eq outcome u1)
      (map-set markets
        { market-id: market-id }
        (merge market { total-yes-pool: (+ (get total-yes-pool market) amount) })
      )
      (map-set markets
        { market-id: market-id }
        (merge market { total-no-pool: (+ (get total-no-pool market) amount) })
      )
    )
    
    (ok true)
  )
)

;; Resolve a market (only creator can resolve)
(define-public (resolve-market (market-id uint) (winning-outcome uint))
  (let (
    (market (unwrap! (map-get? markets { market-id: market-id }) ERR_MARKET_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get creator market)) ERR_NOT_AUTHORIZED)
    (asserts! (>= stacks-block-height (get expiry-block market)) ERR_MARKET_NOT_EXPIRED)
    (asserts! (not (get resolved market)) ERR_MARKET_RESOLVED)
    (asserts! (or (is-eq winning-outcome u0) (is-eq winning-outcome u1)) ERR_INVALID_OUTCOME)
    
    (map-set markets
      { market-id: market-id }
      (merge market {
        outcome: (some winning-outcome),
        resolved: true,
        resolution-block: stacks-block-height
      })
    )
    
    (ok true)
  )
)

;; Claim winnings from a resolved market
(define-public (claim-winnings (market-id uint))
  (let (
    (market (unwrap! (map-get? markets { market-id: market-id }) ERR_MARKET_NOT_FOUND))
    (winning-outcome (unwrap! (get outcome market) ERR_MARKET_NOT_FOUND))
    (already-claimed (default-to false (get claimed (map-get? user-claimed { market-id: market-id, user: tx-sender }))))
    (user-position (default-to u0 (get amount (map-get? user-positions { market-id: market-id, user: tx-sender, outcome: winning-outcome }))))
    (payout (calculate-payout market-id tx-sender winning-outcome))
    (platform-fee-amount (/ (* payout (var-get platform-fee)) u10000))
    (user-payout (- payout platform-fee-amount))
  )
    (asserts! (get resolved market) ERR_MARKET_NOT_FOUND)
    (asserts! (not already-claimed) ERR_NOT_AUTHORIZED)
    (asserts! (> user-position u0) ERR_NO_POSITION)
    
    ;; Mark as claimed
    (map-set user-claimed
      { market-id: market-id, user: tx-sender }
      { claimed: true }
    )
    
    ;; Transfer winnings to user
    (try! (as-contract (stx-transfer? user-payout tx-sender tx-sender)))
    
    ;; Transfer platform fee to contract owner
    (try! (as-contract (stx-transfer? platform-fee-amount tx-sender CONTRACT_OWNER)))
    
    (ok user-payout)
  )
)

;; Read-only functions

;; Get market details
(define-read-only (get-market (market-id uint))
  (map-get? markets { market-id: market-id })
)

;; Get user position in a market
(define-read-only (get-user-position (market-id uint) (user principal) (outcome uint))
  (map-get? user-positions { market-id: market-id, user: user, outcome: outcome })
)

;; Get current market odds (returns basis points)
(define-read-only (get-market-odds (market-id uint))
  (let (
    (market (unwrap! (map-get? markets { market-id: market-id }) none))
    (yes-pool (get total-yes-pool market))
    (no-pool (get total-no-pool market))
    (total-pool (+ yes-pool no-pool))
  )
    (if (is-eq total-pool u0)
      (some { yes-odds: u5000, no-odds: u5000 }) ;; 50/50 if no bets
      (some {
        yes-odds: (/ (* no-pool u10000) total-pool),
        no-odds: (/ (* yes-pool u10000) total-pool)
      })
    )
  )
)

;; Get total number of markets
(define-read-only (get-market-count)
  (var-get market-counter)
)

;; Check if user has claimed winnings
(define-read-only (has-claimed (market-id uint) (user principal))
  (default-to false (get claimed (map-get? user-claimed { market-id: market-id, user: user })))
)

;; Calculate potential payout for a user
(define-read-only (get-potential-payout (market-id uint) (user principal))
  (let (
    (market (unwrap! (map-get? markets { market-id: market-id }) none))
  )
    (if (get resolved market)
      (match (get outcome market)
        winning-outcome (some (calculate-payout market-id user winning-outcome))
        none
      )
      none
    )
  )
)